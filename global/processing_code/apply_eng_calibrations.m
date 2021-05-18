function [eng] = apply_eng_calibrations(eng, meta, profiler_type)
%=========================================================================
% DESCRIPTION
%   Applies calibrations to instrument data in the engineering data stream.
%   Transfers instrument depth offsets to the eng data structure.
%   Transfers binning parameters to the eng data structure.
%
% USAGE:  [eng] = apply_eng_calibrations(eng, meta, profiler_type)
%
%   INPUT
%     eng  = one element from a structure array created by an import_E_mmp
%            function containing unprocessed flr and par (if used) data.
%
%     meta = a scalar structure containing all necessary processing parameters
%            created by running import_metadata.m and import_OOI_calfiles.m
%
%     profiler_type = either 'coastal' or 'global'
%
%   OUTPUT
%     eng  = a scalar structure with the flr and par (if used) raw data
%            replaced with data with calibrations applied.
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   Engineering data from OOI coastal deployments contain PAR and eco triplet
%   (Seabird\WETLabs) fluorescence (chl and CDOM) and backscatter data. Oxygen
%   data acquired from a SBE43f instrument are found in the ctd data stream;
%   SBE43f calibrations are applied in a different function.
%
%   Engineering data from OOI global deployments contain FLBBRTD (Seabird\
%   WETLabs) chl fluorescence and backscatter data. Aanderaa optode (oxygen)
%   data are also acquired in the engineering data stream but the optode
%   output is configured such that its calibrations are applied internally.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-03-06: desiderio: (a) updated to handle coastal and global cases
%..                        (b) changed name from process_eng_sensors.m to
%..                            apply_eng_calibrations.m
%.. 2020-05-04: desiderio: radMMP version 3.00 (OOI coastal and global)
%.. 2021-05-14: desiderio: radMMP version 3.10 (OOI coastal and global)
%=========================================================================
%.. for clarity, and in case sensor suites are changed in the future,
%.. the code is split into coastal and global sections even though there
%.. is significant overlap in the processing.

if strcmpi(profiler_type, 'coastal')
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
    %.. .. the conversion of bback(L1) to the OOI_L2 backscattering coefficient
    %.. .. will be done after eco (flr) data have been extracted from the
    %.. .. eng and par data.
    eng.cdom  = meta.fluorometer_cal.cdom_scale * ...
        (eng.cdom - meta.fluorometer_cal.cdom_dark);    % [ppb]
    eng.chl   = meta.fluorometer_cal.chl_scale *  ...
        (eng.chl - meta.fluorometer_cal.chl_dark);      % [ug/l]
    eng.bback = meta.fluorometer_cal.bback_scale * ...
        (eng.bback - meta.fluorometer_cal.bback_dark);  % [m^-1 sr^-1]
    
    eng.binning_parameters = meta.eng_binning_parameters;
    eng.data_status(end+1) = {'sensors processed'};
    return
end

if strcmpi(profiler_type, 'global')    
    eng.deployment_ID = meta.deployment_ID;
    eng.code_history(end+1) = {mfilename};
    
    %.. the fluorometer sensor is offset from the location of the
    %.. pressure sensor by a known distance (note that there are two profiler
    %.. body sizes; see documentation in metadata.txt). these offsets will
    %.. be applied in a downstream program after the flr  data have
    %.. been split out of the eng record and before pressure gridding.
    eng.fluorometer_depth_offset_m = meta.fluorometer_depth_offset_m;
    eng.optode_depth_offset_m = meta.optode_depth_offset_m;
    
    if isempty(eng.pressure)
        eng.data_status(end+1) = {'not processed'};
        return
    end
    
    %.. eco doublet (FLBBRTD)
    %.. these derived quantities correspond to the OOI_L1 data products.
    %.. .. the conversion of bback(L1) to the OOI_L2 backscattering coefficient
    %.. .. will be done after teh flr data have been extracted from the
    %.. .. eng data.
    eng.chl   = meta.fluorometer_cal.chl_scale *  ...
        (eng.chl - meta.fluorometer_cal.chl_dark);      % [ug/l]
    eng.bback = meta.fluorometer_cal.bback_scale * ...
        (eng.bback - meta.fluorometer_cal.bback_dark);  % [m^-1 sr^-1]
    
    eng.binning_parameters = meta.eng_binning_parameters;    
    eng.data_status(end+1) = {'sensors processed'};
    return
end
