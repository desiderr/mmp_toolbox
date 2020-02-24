function [sss] = process_bback(sss, ctd, meta)
%=========================================================================
% DESCRIPTION
%   Calculates the [seawater + particulate] backscatter coefficient (OOI_L2
%   data product) from OOI_L1 eco triplet backscatter data 
%
% USAGE:  [sss] = process_bback(sss, ctd, meta)
%
%   INPUT
%     sss  = a scalar structure which has fields named 'bback', containing
%            OOI L1 backscatter data, and 'pressure'.
%     ctd  = a scalar structure containing 'pressure', 'temperature', and
%            'salinity' fields and values. 
%     meta = the metadata text file for the deployment being processed. 
%
%   OUTPUT
%     sss  = a scalar structure with L2 backscatter coefficient values written
%            into the 'bback' field replacing the L1 values.
%
% DEPENDENCIES
%   Matlab 2018b
%   flo_bback_total.m                   (appended below)
%       flo_zhang_scatter_coeffs.m      (appended below)
%           flo_refractive_index.m      (appended below)
%           flo_isotherm_compress.m     (appended below)
%           flo_density_seawater.m      (appended below)
%
% REFERENCES
%   The code for flo_bback_total and its subroutines have been translated
%   from the OOI python DPA of the same names. See documentation in the
%   appended subroutines.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%=========================================================================

sss.code_history(end+1) = {mfilename};

if    isempty(sss.pressure) || isempty(ctd.pressure) ...
                            ||                       ...
   all(isnan(sss.pressure(:))) || all(isnan(ctd.pressure(:)))

    sss.bback = nan(size(sss.bback));
    sss.data_status(end+1) = {'BBACK SET TO NAN'};
    return
end

%.. calculate the formal OOI L2 data product 
%.. which requires temperature and salinity.
%
%.. remove nans in ctd pressure record before interpolation
tf_keep = ~isnan(ctd.pressure);

P = ctd.pressure(tf_keep);
T = ctd.temperature(tf_keep);
S = ctd.salinity(tf_keep);

%.. get rid of degeneracies
[PP, ia, ~] = unique(P, 'stable');
TT = T(ia);
SS = S(ia);

T = interp1(PP, TT, sss.pressure);
S = interp1(PP, SS, sss.pressure);

theta  = meta.triplet_cal.bback_scattering_angle;
lambda = meta.triplet_cal.bback_wavelength;
chi    = meta.triplet_cal.bback_chi_factor;
sss.bback = flo_bback_total(sss.bback, T, S, theta, lambda, chi);

sss.data_status(end+1) = {'bback processed'};

end

%********************** SUBROUTINES *******************************

function [bback_L2] = flo_bback_total(bback_L1, T, S, theta, lambda, chi)
%.. desiderio 2018-03-29 oregon state university
%
%.. this code is the python 'DPA' function flo_bback_total 
%.. (along with the 4 subfunctions it calls: 
%..           flo_zhang_scatter_coeffs
%..               flo_refractive_index
%..               flo_isotherm_compress
%..               flo_density_seawater 
%..                                 which are among the first functions
%.. listed in the module flo_functions.py) directly converted to matlab. 
%.. only the python formatting and syntax have been altered to those of
%.. matlab (and the names of the arguments, above, to the main routine).
%
%.. See  
%.. https://github.com/oceanobservatories/ion-functions/blob/master/ion_functions/data/flo_functions.py
%.. for more extensive documentation. 
%
% bback_L2 = total (seawater + particulate) optical backscatter coefficient
%            at wavelength lambda (FLUBSCT_L2) [m-1].
% 
% bback_L1 = value of the volume scattering function (seawater + particulate) measured
%            at angle theta and at wavelength lambda (FLUBSCT_L1) [m-1 sr-1].
% T        = in situ water temperature from co-located CTD [deg_C].
% S        = in situ salinity from co-located CTD [psu].
% theta    = effective (centroid) optical backscatter scattering angle [degrees] which
%            is a function of the sensor geometry of the measuring instrument.
% lambda   = optical backscatter measurement wavelength [nm].
% chi      = factor which scales the particulate (no seawater contribution) scattering 
%            value at a particular backwards angle to the total particulate (no seawater
%            contribution) backscattering coefficient integrated over all backwards angles.
% 
% Depending on context within the documentation the word 'total' can have several meanings:
% (1) seawater + particulate scattering
% (2) forward + backward scattering
% (3) backscatter integrated over all backwards wavelengths.


% calculate:
%    betasw, the theoretical value of the volume scattering function for seawater only
%        at the measurement angle theta and wavelength lambda [m-1 sr-1], and,
%    bsw, the theoretical value for the total (in this case meaning forward + backward)
%         scattering coefficient for seawater (also with no particulate contribution)
%         at wavelength lambda [m-1].
% Values below are computed using provided code from Zhang et al 2009.
depolarization_ratio = 0.039;
[betasw, bsw] = flo_zhang_scatter_coeffs(T, S, theta, lambda, depolarization_ratio);

% calculate the volume scattering at angle theta of particles only, betap.
%     beta = scattering measured at angle theta for seawater + particulates
%     betasw = theoretical seawater only value calculated at angle theta
betap = bback_L1 - betasw;

% calculate the particulate backscatter coefficient bbackp [m-1] which is effectively
% the particulate scattering function integrated over all backwards angles. The factor
% of 2*pi arises from the integration over the (implicit) polar angle variable.
bbackp = chi * 2.0 * pi * betap;

% calculate the backscatter coefficient due to seawater from the total (forward + backward)
% scattering coefficient bsw. because the effective scattering centers in pure seawater are
% much smaller than the wavelength, the shape of the scattering function is symmetrical in
% the forward and backward directions.
bbsw = bsw / 2;

% calculate the total (particulates + seawater) backscatter coefficient.
bback_L2 = bbackp + bbsw;

end

function [betasw, bsw] = flo_zhang_scatter_coeffs(degC, psu, theta, wlngth, delta)
%
%         Computes scattering coefficients for seawater (both the volume scattering at
%         a given angle theta and the total scattering coefficient integrated over all
%         scattering angles) at a given wavelength wlngth based on the computation of
%         Zhang et al 2009 as presented in the DPS for Optical Backscatter.
%
%         The original Matlab code was developed and made available
%         online by:
%             Dr. Xiaodong Zhang
%             Associate Professor
%             Department of Earth Systems Science and Policy
%             University of North Dakota
%             http://www.und.edu/instruct/zhang/
%
%         python implementation by:
%             2013-07-15: Christopher Wingard. Initial Code
%       
%         python converted back to Matlab by RDesiderio 2019-03-29

% values of the constants
Na = 6.0221417930e23;    % Avogadro's constant
Kbz = 1.3806503e-23;     % Boltzmann constant
degK = degC + 273.15;    % Absolute temperature
M0 = 0.018;              % Molecular weight of water in kg/mol

% convert the scattering angle from degrees to radians
rad = deg2rad(theta);

% calculate the absolute refractive index of seawater and the partial
% derivative of seawater refractive index with regards to salinity.
[nsw, dnds] = flo_refractive_index(wlngth, degC, psu);

% isothermal compressibility is from Lepple & Millero (1971,Deep
% Sea-Research), pages 10-11 The error ~ +/-0.004e-6 bar^-1
icomp = flo_isotherm_compress(degC, psu);

% density of seawater from UNESCO 38 (1981).
rho = flo_density_seawater(degC, psu);

% water activity data of seawater is from Millero and Leung (1976, American
% Journal of Science, 276, 1035-1077). Table 19 was reproduced using
% Eq.(14,22,23,88,107) that were fitted to polynominal equation. dlnawds is
% a partial derivative of the natural logarithm of water activity with
% regards to salinity.
dlnawds = (-5.58651e-4 + 2.40452e-7 * degC - 3.12165e-9 * degC.^2 + 2.40808e-11 * degC.^3) + ...
    1.5 * (1.79613e-5 - 9.9422e-8 * degC + 2.08919e-9 * degC.^2 - 1.39872e-11 * degC.^3) .* ...
    psu.^0.5 + 2 * (-2.31065e-6 - 1.37674e-9 * degC - 1.93316e-11 * degC.^2) .* psu;

% density derivative of refractive index from PMH model
dfri = (nsw.^2 - 1.0) .* (1.0 + 2.0/3.0 * (nsw.^2 + 2.0) ...
    .* (nsw/3.0 - 1.0/3.0 ./ nsw).^2);

% volume scattering at 90 degrees due to the density fluctuation
beta_df = pi.^2 ./ 2.0 * (wlngth*1e-9).^-4 * Kbz * degK .* icomp ...
    .* dfri.^2 * (6.0 + 6.0 * delta) / (6.0 - 7.0 * delta);

% volume scattering at 90 degree due to the concentration fluctuation
flu_con = psu * M0 .* dnds.^2 ./ rho ./ -dlnawds / Na;
beta_cf = 2.0 * pi.^2 * (wlngth * 1e-9).^-4 * nsw.^2 .* flu_con ...
    * (6.0 + 6.0 * delta) / (6.0 - 7.0 * delta);

% total volume scattering at 90 degree
beta90sw = beta_df + beta_cf;

% total scattering coefficient of seawater (m-1)
bsw = 8.0 * pi / 3.0 * beta90sw * ((2.0 + delta) / (1.0 + delta));

% total volume scattering coefficient of seawater (m-1 sr-1)
betasw = beta90sw * (1.0 + ((1.0 - delta) ./ (1.0 + delta)) * cos(rad).^2);

end

function  [nsw, dnds] = flo_refractive_index(wlngth, degC, psu)
% nsw absolute refractive index of seawater
% dnds partial derivative of seawater refractive index wrt salinity

% refractive index of air is from Ciddor (1996, Applied Optics).
n_air = 1.0 + (5792105.0 / (238.0185 - 1 / (wlngth/1e3).^2) ...
    + 167917.0 / (57.362 - 1 / (wlngth/1e3).^2)) / 1e8;

% refractive index of seawater is from Quan and Fry (1994, Applied Optics)
n0 = 1.31405;
n1 = 1.779e-4;
n2 = -1.05e-6;
n3 = 1.6e-8;
n4 = -2.02e-6;
n5 = 15.868;
n6 = 0.01155;
n7 = -0.00423;
n8 = -4382.0;
n9 = 1.1455e6;
nsw = n0 + (n1 + n2 * degC + n3 * degC.^2) .* psu + n4 * degC.^2 ...
    + (n5 + n6 * psu + n7 * degC) / wlngth + n8 / wlngth.^2 ...
    + n9 / wlngth.^3;

% pure seawater
nsw = nsw .* n_air;
dnds = (n1 + n2 * degC + n3 * degC.^2 + n6 / wlngth) .* n_air;

end

function [iso_comp] = flo_isotherm_compress(degC, psu)
% iso_comp seawater isothermal compressibility
%
% pure water secant bulk Millero (1980, Deep-sea Research)
kw = 19652.21 + 148.4206 * degC - 2.327105 * degC.^2 ...
    + 1.360477e-2 * degC.^3 - 5.155288e-5 * degC.^4;

% seawater secant bulk
a0 = 54.6746 - 0.603459 * degC + 1.09987e-2 * degC.^2 ...
    - 6.167e-5 * degC.^3;
b0 = 7.944e-2 + 1.6483e-2 * degC - 5.3009e-4 * degC.^2;
ks = kw + a0 .* psu + b0 .* psu.^1.5;

% calculate seawater isothermal compressibility from the secant bulk
iso_comp = 1 ./ ks * 1e-5;  % unit is Pa
end

function [rho_sw] = flo_density_seawater(degC, psu)
% density of water and seawater,unit is Kg/m^3, from UNESCO,38,1981
a0 = 8.24493e-1;
a1 = -4.0899e-3;
a2 = 7.6438e-5;
a3 = -8.2467e-7;
a4 = 5.3875e-9;
a5 = -5.72466e-3;
a6 = 1.0227e-4;
a7 = -1.6546e-6;
a8 = 4.8314e-4;
b0 = 999.842594;
b1 = 6.793952e-2;
b2 = -9.09529e-3;
b3 = 1.001685e-4;
b4 = -1.120083e-6;
b5 = 6.536332e-9;

% density for pure water
rho_w = b0 + b1 * degC + b2 * degC.^2 + b3 * degC.^3 ...
    + b4 * degC.^4 + b5 * degC.^5;

% density for pure seawater
rho_sw = rho_w + ((a0 + a1 * degC + a2 * degC.^2 ...
    + a3 * degC.^3 + a4 * degC.^4) .* psu ...
    + (a5 + a6 * degC + a7 * degC.^2) .* psu.^1.5 + a8 * psu.^2);

end
