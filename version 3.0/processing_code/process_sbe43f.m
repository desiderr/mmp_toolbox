function [ctd] = process_sbe43f(ctd, meta)
%=========================================================================
% DESCRIPTION
%   Processes raw oxygen data from a SBE43F instrument.
%   Coastal OOI Deployments only.
%
% USAGE:  [ctd] = process_sbe43f(ctd, meta)
%
%   INPUT: 
%     ctd  = one element from a structure array created by import_C_sbe52.m 
%     meta = a scalar structure containing all necessary processing parameters
%            created by running import_metadata.m and import_OOI_calfiles.m
%   OUTPUT: 
%     ctd  = a scalar structure with the raw oxygen frequency data replaced
%            with oxygen concentration [umole/kg].
%
% DEPENDENCIES
%   Matlab 2018b
%   oxsat_gg.m        (appended at the end of this code)
%   sbefilter.m
%   Toolebox_shift.m
%
% NOTES
%   The oxygen sensor response time is not corrected for ('tau' and its 
%   associated calibration coefficients are not applied).
%
% REFERENCES
%   oxsat_gg.m:  coded by RADesiderio (2004-12-08) from:
%   Garcia, Hernan E. and Gordon, Louis I. 1992. "Oxygen solubility
%   in seawater: Better fitting equations". Limnology and Oceanography,
%   37: 1307-1312.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-04: desiderio: radMMP version 3.0 (OOI coastal and global)
%=========================================================================
 
ctd.code_history(end+1) = {mfilename};

if isempty(ctd.pressure) || isempty(ctd.oxygen)
    ctd.data_status(end+1) = {'oxygen not processed'};
    return
end

%.. low-pass filter
oxygen = sbefilter(ctd.oxygen, meta.ctd_acquisition_rate_Hz, ...
    meta.oxygen_filter_time_constant_sec);

%.. apply shift to align oxygen data to temperature;
%.. it is assumed that the temperature time constant is significantly 
%.. shorter than that for pressure.
%..   the shift routine shifts with respect to index;
%..   convert shift units from seconds to index number.
oxygen = Toolebox_shift(oxygen, ...
    meta.oxygen_shift_sec * meta.ctd_acquisition_rate_Hz);

%.. apply SBE43 calibration equation using calcoefs stored in meta
Foffset = meta.sbe43f_cal.Foffset;
%.. use Seabird-adjusted Soc instead of Soc
Soc_adj = meta.sbe43f_cal.Soc_adj;
A = meta.sbe43f_cal.A;
B = meta.sbe43f_cal.B;
C = meta.sbe43f_cal.C;
E = meta.sbe43f_cal.E;
%
S = ctd.salinity;
T = ctd.temperature;  % Celsius
P = ctd.pressure;
%.. units [ml/l]
oxygen = Soc_adj * (oxygen + Foffset) .* ...
    (1.0 + T .* (A + T .* (B + T .* C))) .* ...
    oxsat_gg(S, T) .* exp(E * P ./ (T + 273.15));
%.. convert to units of umole/kg (OOI units for processed O2);
%.. this formulation agrees with the SBEDataProcessing documentation.
ctd.oxygen = 44660.0 * oxygen ./ (ctd.sigma_theta + 1000); 

ctd.data_status(end+1) = {'oxygen processed [umole/kg]'};

end

function [oxsol] = oxsat_gg(S,T)

% Saturation (Solubility) of O2 in sea water: Garcia and Gordon formula
%=========================================================================
%
% USAGE:  oxsol = oxsat_gg(S,T)
%
% DESCRIPTION:
%    Solubility (saturation) of Oxygen (O2) in sea water: 
%    Garcia and Gordon, 1992,  Equation (8).
%    Coefficients from column 1 of Table 1.
%
% INPUT:  (the matrices S and T must have the same dimensions)
%   S = salinity    [psu      (PSS-78)]
%   T = temperature [degree C (ITS-90)]
%       T is converted to ITS-68 before using the GG equation.
%
%   Valid input range: Tf < T < 40;  0 < S < 42.
%
%   There is currently disagreement whether temperature or
%   potential temperature should be used when this equation
%   is used to convert an in situ oxygen sensor reading to an
%   in situ oxygen concentration.
%
% OUTPUT:
%   oxsol = solubility of O2  [ml/l]
%
%   oxsol [ml(02 gas at STP)/liter(seawater)]
%   This oxygen solubility refers to the volume of oxygen that would
%   be occupied at standard temperature and pressure, dissolved in 
%   each liter of seawater at a given salinity and temperature, when 
%   the seawater is in equilibrium with humidity-saturated air of 
%   standard composition at a total pressure of one atmosphere.
%
% AUTHOR: Russell Desiderio, Oregon State University, 2004-12-08  
%
% REFERENCES:
%    Garcia, Hernan E. and Gordon, Louis I. 1992. "Oxygen solubility
%    in seawater: Better fitting equations". Limnology and Oceanography,
%    37: 1307-1312.
%=========================================================================

%----------------------
% CHECK INPUT ARGUMENTS
%----------------------
if nargin ~=2
   error('oxsat_gg.m: Must pass 2 parameters')
end %if

% CHECK S,T dimensions and verify consistent
[ms,ns] = size(S);
[mt,nt] = size(T);


% CHECK THAT S & T HAVE SAME SHAPE
if (ms~=mt) || (ns~=nt)
   error('oxsat.gg: S & T must have same dimensions')
end %if

%------
% BEGIN
%------

% the factor 1.00024 converts T90(Celsius) to T68(Celsius)
T = T * 1.00024;
% scale as per GG
x = log( (298.15-T)./(273.15+T) );
% constants for Eqn (8) of Garcia and Gordon 1992; Table 1, column 1
a0 =  2.00907;
a1 =  3.22014;
a2 =  4.05010;
a3 =  4.94457;
a4 =  -2.56847e-1;
a5 =  3.88767;
b0 = -6.24523e-3;
b1 = -7.37614e-3;
b2 = -1.03410e-2;
b3 = -8.17083e-3;
c0 = -4.88682e-7;

% Eqn (8) of Garcia and Gordon 1992
lnC = a0 + a1*x + a2*(x.^2) + a3*(x.^3) + a4*(x.^4) + a5*(x.^5) + ...
      S.*( b0 + b1*x + b2*(x.^2) + b3*(x.^3) ) + c0*(S.^2);

oxsol = exp(lnC);
end
