function [sss] = fcm_set_sensor_field_indices(sss, level)
%=========================================================================
% DESCRIPTION
%   Determines variables to be processed by setting the index numbers
%   of the variables' corresponding structure fields.
%
% USAGE:  [sss] = fcm_set_sensor_field_indices(sss, level)
%
%   INPUT
%     sss   = a structure array with appropriately named fields
%     level = either 'L0', 'L1', or 'L2' 
%
%   OUTPUT
%     sss   = a structure array with all of its elements' 
%             'sensor_field_indices' fields set.
% NOTES
%   The sensor_field_indices values are used "behind the scenes" by
%     cat_sensor_fields.m
%     nan_bad_profile_sections.m
%     pressure_bin_mmp_data.m
%     write_field_arrays_to_new_structure.m
%
%   TX and TY are retained in L2 for making pseudocolor plots; extreme 
%   values may correlate with mesoscale profiler 'blow down' events.
%
%   The theoretical wag signal calculation is also kept in L2. The wag 
%   oscillations that are observed on shorter time scales are smoothed
%   out in the processing by using a 12 second filter. There does seem 
%   to be longer time scale behavior which can be visualized in the L2
%   wag signal data product, when it occurs.
%
% DEPENDENCIES
%   Matlab 2018b
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2020-10-02: desiderio: global version created by modifying coastal version
%.. 2021-05-21: desiderio: radMMP version 3.10g (OOI global)
%=========================================================================

%.. append mfilename to all sss.code_history elements
Q = {sss.code_history}';  % extract
QQ = cellfun(@(x) [x {mfilename}], Q, 'uni', 0);  % append to each element
[sss.code_history] = QQ{:};
clearvars Q QQ

if     strcmpi(level, 'L0')
    fields_to_process = {
        'time'
        'pressure'
        'heading'
        'TX'
        'TY'
        'magnetometer'
        'velBeam'
        };
elseif strcmpi(level, 'L1')
    fields_to_process = {
        'time'
        'pressure'
        'dpdt'
        'heading'
        'TX'
        'TY'
        'velBeam'
        'velXYZ'
        'velENU'
        'wag_signal'
        };
elseif strcmpi(level, 'L2')
    fields_to_process = {
        'time'
        'pressure'
        'dpdt'
        'heading'
        'TX'
        'TY'
        'velENU'
        'wag_signal'
        };
end

all_fields = fieldnames(sss);
idx_fields_to_process = find(ismember(all_fields, fields_to_process))';
[sss.sensor_field_indices] = deal(idx_fields_to_process);

action = [level ' fields set'];
%.. append to all sss elements
Q = {sss.data_status}';
QQ = cellfun(@(x) [x {action}], Q, 'uni', 0);
[sss.data_status] = QQ{:};
end
