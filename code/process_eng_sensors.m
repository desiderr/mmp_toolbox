function [eng] = process_eng_sensors(eng, meta)
%=========================================================================
% DESCRIPTION
%   Applies calibration coefficients to par and flr data.
%   Transfers binning parameters to the eng data structure.
%
% USAGE:  [eng] = process_eng_sensors(eng, meta)
%
%   INPUT
%     eng  = one element from a structure array created by import_E_mmp.m 
%            containing unprocessed ('L0') par and flr data.
%     meta = a scalar structure containing all necessary processing parameters
%            created by running import_metadata.m and import_OOI_calfiles.m
%   OUTPUT
%     eng  = a scalar structure with the par and flr L0 data replaced with
%            'L1' data.
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   Engineering data from OOI coastal deployments contain PAR and eco triplet
%   (Seabird\WETLabs) fluorescence and backscatter data.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%=========================================================================
eng.deployment_ID = meta.deployment_ID;
eng.code_history(end+1) = {mfilename};

%.. the fluorometer and par sensors are offset from the location of the
%.. pressure sensor by known distances (note that there are two profiler
%.. body sizes; see documentation in metadata.txt). these offsets will
%.. be applied in a downstream program after the flr and par data have
%.. been split out of the eng record and before pressure gridding.
eng.fluorometer_depth_offset_m = meta.fluorometer_depth_offset_m;
eng.par_depth_offset_m         = meta.par_depth_offset_m;

if isempty(eng.pressure)
    eng.data_status(end+1) = {'not processed'};
    return
end

%.. apply the par calibration equation using calcoefs stored in meta.
%
%.. the raw data and dark offset are both in mV.
%.. the units of the (OOI) data product are [uEinsteins/(m^2*s)]. 
%
%.. the calibration divisor specified by OOI in the calfile has units of
%.. V/(quanta/(cm^2*sec)); if the one with units of V/(uE/(m^2*s))
%.. had been used by OOI instead, the unit conversion below would not
%.. be necessary.
%
%.. convert units:
%.. ..  1  micro           Einstein       /     m^2    / s 
%.. ..  = (10^-6) * {6.02 * 10^23 quanta} / (10^4cm^2) / s
%.. ..  =            6.02 * 10^13 quanta  /    cm^2    / s
par_volts = (eng.par - meta.qsp2200_cal.par_dark) / 1000;
eng.par = par_volts / meta.qsp2200_cal.par_scale_wet / (6.02 * 10^13);

%.. eco triplet
%.. these derived quantities correspond to the OOI_L1 data products.
%.. .. the conversion of bback(L1) to the L2 backscattering coefficient
%.. .. will be done after eco (flr) data have been extracted from the
%.. .. eng and par data.
eng.cdom  = meta.triplet_cal.cdom_scale * ...
    (eng.cdom - meta.triplet_cal.cdom_dark);    % [ppb]
eng.chl   = meta.triplet_cal.chl_scale *  ...
    (eng.chl - meta.triplet_cal.chl_dark);      % [ug/l]
eng.bback = meta.triplet_cal.bback_scale * ...
    (eng.bback - meta.triplet_cal.bback_dark);  % [m^-1 sr^-1]

eng.binning_parameters = meta.eng_binning_parameters;

eng.data_status(end+1) = {'sensors processed'};

end
