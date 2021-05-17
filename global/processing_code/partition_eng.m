function [eng, flr, sss] = partition_eng(eng, profilerType)
%=========================================================================
% DESCRIPTION
%   Splits apart the data originally contained in the mmp engineering
%   files into engineering only, fluorescence, and either par (coastal)
%   or oxy (global) structure arrays.
%
%   Applies pressure offsets to the flr and (par or oxy) data.
%
% USAGE
%       coastal:  [eng, flr, par] = partition_eng(eng, profilerType)
%        global:  [eng, flr, oxy] = partition_eng(eng, profilerType)
%
%   INPUT
%     eng  = a structure array containing mmp engineering and sensor data 
%     profilerType = either 'coastal' or 'global'
%
%   OUTPUT
%     eng = a structure array containing only engineering data
%     flr = a structure array containing flr and associated data
%     par = a structure array containing par and associated data
%     oxy = a structure array containing oxygen optode and associated data
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   FOR OOI DEPLOYMENTS, the array of structures eng initially 
%   contains 3 types of data:
%   (1) profiler operation and metadata
%   (2) fluorometer data
%   (3) par (coastal) or oxygen optode (global) data
%
%   Binning the fluorometer and par data require different pressure
%   offsets because these sensors are not co-located in depth with
%   respect to the ctd pressure sensor. However, the Aanderaa optode
%   measuring oxygen on global profilers is very close; its pressure 
%   offset could be set to 0.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-03-06: desiderio: updated to include global profiler processing
%.. 2020-05-04: desiderio: radMMP version 3.0 (OOI coastal and global)
%=========================================================================

if strcmp(profilerType, 'coastal')
    sensor                 = 'par';
    fields_to_keep_for_eng = [1:11 16 21:29];
    fields_to_keep_for_flr = [1:5 8 11:14 17:21];
    fields_to_keep_for_sss = [1:5 8 11 15 17:21];
    flr_sfi                = 6:10;
    sss_sfi                = 6:8;
elseif strcmp(profilerType, 'global')
    sensor                 = 'optode';  % (Aanderaa oxygen)
    fields_to_keep_for_eng = [1:11 17 22:30];
    fields_to_keep_for_flr = [1:5 8 11 14:16 18:22];
    fields_to_keep_for_sss = [1:5 8 11 12:13 18:22];
    flr_sfi                = 6:10;
    sss_sfi                = 6:9;
else
    error('Unrecognized or no profilerType.');
end

n_struct = length(eng);
%.. find the offsets from the eng fields. empty set entries are omitted 
%.. from the bracketed output of the structure field; nanmedian of []
%.. is nan.
sss_depth_offset_m = nanmedian([eng.([sensor '_depth_offset_m'])]);
if isnan(sss_depth_offset_m)
    disp(['Warning: parsed ' sensor ' pressure offset = Nan; set to 0.']);
    sss_depth_offset_m = 0;
end
flr_depth_offset_m = nanmedian([eng.fluorometer_depth_offset_m]);
if isnan(flr_depth_offset_m)
    disp('Warning: parsed fluorometer pressure offset = Nan; set to 0.');
    flr_depth_offset_m = 0;
end

%.. create the output structure arrays
engFields = fieldnames(eng);
E = squeeze(struct2cell(eng));
%.. flr
idx = fields_to_keep_for_flr;
flr = cell2struct(E(idx, :), engFields(idx), 1);
%.. reset sensor indices for binning code
[flr.sensor_field_indices] = deal(flr_sfi);
%.. sss (par or oxy)
idx = fields_to_keep_for_sss;
sss = cell2struct(E(idx, :), engFields(idx), 1);
%.. reset sensor indices for binning code
[sss.sensor_field_indices] = deal(sss_sfi);
%.. eng
clear eng
idx = fields_to_keep_for_eng;
eng = cell2struct(E(idx, :), engFields(idx), 1);

%.. apply pressure offsets
for ii = 1:n_struct
    flr(ii).pressure = flr(ii).pressure + flr_depth_offset_m;
    sss(ii).pressure = sss(ii).pressure + sss_depth_offset_m;
end

if strcmp(sensor, 'optode'), sensor = 'oxy'; end
%.. write status out to each new structure
for ii = 1:n_struct
    eng(ii).code_history(end+1) = {mfilename};
    flr(ii).code_history(end+1) = {mfilename};
    sss(ii).code_history(end+1) = {mfilename};
    eng(ii).data_status(end+1) = {'pruned'};
    flr(ii).data_status(end+1) = {'flr created'};
    sss(ii).data_status(end+1) = {[sensor ' created']};
end
