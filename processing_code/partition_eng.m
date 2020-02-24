function [eng, flr, par] = partition_eng(eng)
%=========================================================================
% DESCRIPTION
%   Splits apart the data originally contained in the mmp engineering files
%   into engineering only, fluorescence, and par structure arrays.
%
%   Applies pressure offsets to the flr and par data.
%
% USAGE:  [eng, flr, par] = partition_eng(eng)
%
%   INPUT
%     eng  = a structure array containing mmp engineering and sensor data 
%
%   OUTPUT
%     eng = a structure array containing only engineering data
%     flr = a structure array containing flr and associated data
%     par = a structure array containing par and associated data
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   FOR OOI COASTAL DEPLOYMENTS, the array of structures eng initially 
%   contains 3 types of data:
%   (1) profiler operation and metadata
%   (2) fluorometer (eco triplet) data
%   (3) par data
%
%   Binning the fluorometer and par data require different pressure
%   offsets because these sensors are not co-located in depth with
%   respect to the ctd pressure sensor.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%=========================================================================

fields_to_keep_for_flr = [1:5 8 11:14 17:21];
fields_to_keep_for_par = [1:5 8 11 15 17:21];
fields_to_keep_for_eng = [1:11 16 21:29];

n_struct = length(eng);
%.. find the offsets from the eng fields. empty set entries are omitted 
%.. from the bracketed output of the structure field; nanmedian of []
%.. is nan.
par_depth_offset_m = nanmedian([eng.par_depth_offset_m]);
if isnan(par_depth_offset_m)
    disp('Warning: parsed par pressure offset = Nan; set to 0.');
    par_depth_offset_m = 0;
end
fluorometer_depth_offset_m = nanmedian([eng.par_depth_offset_m]);
if isnan(fluorometer_depth_offset_m)
    disp('Warning: parsed fluorometer pressure offset = Nan; set to 0.');
    fluorometer_depth_offset_m = 0;
end

%.. create the output structure arrays
E = squeeze(struct2cell(eng));
names = fieldnames(eng);  % so that fields can be indexed
%.. flr
idx = fields_to_keep_for_flr;
flr = cell2struct(E(idx, :), names(idx), 1);
%.. reset sensor indices for binning code
[flr.sensor_field_indices] = deal(6:10);
%.. par
idx = fields_to_keep_for_par;
par = cell2struct(E(idx, :), names(idx), 1);
%.. reset sensor indices for binning code
[par.sensor_field_indices] = deal(6:8);
%.. eng
clear eng
idx = fields_to_keep_for_eng;
eng = cell2struct(E(idx, :), names(idx), 1);

%.. apply pressure offsets
for ii = 1:n_struct
    flr(ii).pressure = flr(ii).pressure + fluorometer_depth_offset_m;
    par(ii).pressure = par(ii).pressure + par_depth_offset_m;
end

%.. write status out to each new structure
for ii = 1:n_struct
    eng(ii).code_history(end+1) = {mfilename};
    flr(ii).code_history(end+1) = {mfilename};
    par(ii).code_history(end+1) = {mfilename};
    eng(ii).data_status(end+1) = {'pruned'};
    flr(ii).data_status(end+1) = {'flr created'};
    par(ii).data_status(end+1) = {'par created'};
end
