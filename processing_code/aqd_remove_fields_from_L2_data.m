function [sss] = aqd_remove_fields_from_L2_data(sss)
%=========================================================================
% DESCRIPTION
%   Cleans up L2 structure array (not L2 array-of-structures) data product. 
%
% USAGE:  [sss] = aqd_remove_fields_from_L2_data(sss)
%
%   INPUT
%     sss       = a structure array with appropriately named fields
%
%   OUTPUT
%     sss       = a structure array with extraneous fields deleted.
%
% DEPENDENCIES
%   Matlab 2018b
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-01-30: desiderio: added velXYZ to fields_to_remove
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%=========================================================================

%.. append mfilename to all sss.code_history elements
Q = {sss.code_history}';  % extract
QQ = cellfun(@(x) [x {mfilename}], Q, 'uni', 0);  % append to each element
[sss.code_history] = QQ{:};
clearvars Q QQ

fields_to_remove = {
    'imported_data'
    'pitch'
    'roll'
    'nbeams'
    'ncells'
    'magnetometer'
    'velBeam'
    'amplitude'
    'correlation'
    'velXYZ'
    'ambiguous_points'
    'wag_signal'
    'profile_mask'
    'sensor_field_indices'
    };

sss = rmfield(sss, fields_to_remove);

%.. append data status to all sss elements
Q = {sss.data_status}';
QQ = cellfun(@(x) [x {'unbinned fields removed'}], Q, 'uni', 0);
[sss.data_status] = QQ{:};
end
