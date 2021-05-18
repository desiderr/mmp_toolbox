function [sss] = process_eng_aanderaa_optode(sss, ctd, meta)
%=========================================================================
% DESCRIPTION
%   Processes Aanderaa oxygen optode data in the engineering data stream;
%   Global OOI profiler deployments only.
%
% USAGE:  [sss] = process_eng_aanderaa_optode(sss, ctd, meta)
%
%   INPUT: 
%     sss  = a scalar structure which has fields named 'oxygen' containing
%            Aanderaa optode data and 'pressure'.
%     ctd  = one element from a structure array created by import_C_sbe52.m 
%     meta = a scalar structure containing all necessary processing parameters
%            created by running import_metadata.m and import_OOI_calfiles.m
%   OUTPUT: 
%     sss  = a scalar structure with uncorrected oxygen data [uM] replaced
%            with oxygen concentration [umole/kg] corrected for pressure
%            and temperature-dependent salinity.
%
% DEPENDENCIES
%   Matlab 2018b
%   do2_salinity_correction.m        (appended at the end of this code)
%
% NOTES
%   The oxygen sensor response time is not corrected for ('tau' and its 
%   associated calibration coefficients are not applied).
%
% REFERENCES
%   The code for do2_salinity_correction has been translated from the OOI
%   python DPA of the same name. See documentation in the appended subroutine.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2020-03-02: desiderio: initial code
%.. 2020-05-04: desiderio: radMMP version 3.00 (OOI coastal and global)
%.. 2021-05-14: desiderio: radMMP version 3.10 (OOI coastal and global)
%=========================================================================
 
ctd.code_history(end+1) = {mfilename};

if isempty(ctd.pressure) || isempty(sss.oxygen)
    ctd.data_status(end+1) = {'oxygen not processed'};
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

referencePressure = 0;  % OOI setting
DO = sss.oxygen;  % units [uM]
DO_corrected = do2_salinity_correction(DO, sss.pressure, T, S, ...
    meta.latitude, meta.longitude, referencePressure);
sss.oxygen = DO_corrected;  % units [umole/kg]

ctd.data_status(end+1) = {'oxygen processed [umole/kg]'};

end

function DO_corr = do2_salinity_correction(DO, P, T, SP, lat, lon, pref)
%{
    Description:

        Calculates the data product DOXYGEN_L2 (renamed from DOCONCS_L2) from DOSTA
        (Aanderaa) instruments by correcting the the DOCONCS_L1 data product for
        salinity and pressure effects and changing units.

    Usage:

        DOc = do2_salinity_correction(DO,P,T,SP,lat,lon, pref=0)

            where

        DOc = corrected dissolved oxygen [micro-mole/kg], DOXYGEN_L2
        DO = uncorrected dissolved oxygen [micro-mole/L], DOCONCS_L1
        P = PRESWAT water pressure [dbar]. (see
            1341-00020_Data_Product_Spec_PRESWAT). Interpolated to the
            same timestamp as DO.
        T = TEMPWAT water temperature [deg C]. (see
            1341-00010_Data_Product_Spec_TEMPWAT). Interpolated to the
            same timestamp as DO.
        SP = PRACSAL practical salinity [unitless]. (see
            1341-00040_Data_Product_Spec_PRACSAL)
        lat, lon = latitude and longitude of the instrument [degrees].
        pref = pressure reference level for potential density [dbar].
            The default is 0 dbar.

    Example:
        DO = 433.88488978325478
        do_t = 1.97
        P = 5.4000000000000004
        T = 1.97
        SP = 33.716000000000001
        lat,lon = -52.82, 87.64

        DOc = do2_salinity_correction(DO,P,T,SP,lat,lon, pref=0)
        print DO
        > 335.967894709

    Implemented by:
        2013-04-26: Stuart Pearce. Initial Code.
        2015-08-04: Russell Desiderio. Added Garcia-Gordon reference.

    References:
        OOI (2012). Data Product Specification for Oxygen Concentration
            from "Stable" Instruments. Document Control Number
            1341-00520. https://alfresco.oceanobservatories.org/ (See:
            Company Home >> OOI >> Controlled >> 1000 System Level
            >> 1341-00520_Data_Product_SPEC_DOCONCS_OOI.pdf)

        "Oxygen solubility in seawater: Better fitting equations", 1992,
        Garcia, H.E. and Gordon, L.I. Limnol. Oceanogr. 37(6) 1307-1312.
        Table 1, 5th column.
%}

% density calculation from GSW toolbox
SA = gsw_SA_from_SP(SP, P, lon, lat);
CT = gsw_CT_from_t(SA, T, P);
pdens = gsw_rho(SA, CT, pref);

% Convert from volume to mass units:
DO = 1000 * DO ./ pdens;

% Pressure correction:
DO = (1 + (0.032*P)/1000) .* DO;

% Salinity correction (Garcia and Gordon, 1992, combined fit):
S0 = 0;
ts = log((298.15-T) ./ (273.15+T));
B0 = -6.24097e-3;
B1 = -6.93498e-3;
B2 = -6.90358e-3;
B3 = -4.29155e-3;
C0 = -3.11680e-7;
Bts = B0 + B1 .* ts + B2 .* ts.^2 + B3 .* ts.^3;
DO_corr = exp((SP-S0) .* Bts + C0 * (SP.^2 - S0.^2)) .* DO;

end
