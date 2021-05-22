function [sss] = aqd_set_sensor_field_indices(sss, level)
%=========================================================================
% DESCRIPTION
%   Determines variables to be processed by setting the index numbers
%   of the variables' corresponding structure fields.
%
% USAGE:  [sss] = aqd_set_sensor_field_indices(sss, level)
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
%     write_field_arrays_to_new_structure,m
%
% DEPENDENCIES
%   Matlab 2018b
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-12: desiderio: added aqd_temperature and aqd_pressure to L0
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%.. 2021-05-10: desiderio: radMMP version 2.20c (OOI coastal)
%.. 2021-05-24: desiderio: radMMP version 4.0
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
        'aqd_temperature'
        'aqd_pressure'
        'heading'
        'pitch'
        'roll'
        'magnetometer'
        'velBeam'
        'amplitude'
        'correlation'
        };
elseif strcmpi(level, 'L1')
    fields_to_process = {
        'time'
        'pressure'
        'dpdt'
        'aqd_temperature'
        'aqd_pressure'
        'heading'
        'pitch'
        'roll'
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
        'aqd_temperature'
        'aqd_pressure'
        'heading'
        'velENU'
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
