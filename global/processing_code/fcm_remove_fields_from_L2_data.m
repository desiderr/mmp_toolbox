function [sss] = fcm_remove_fields_from_L2_data(sss)
%=========================================================================
% DESCRIPTION
%   Cleans up L2 structure of arrays (not L2 array-of-structures) data product. 
%
% USAGE:  [sss] = fcm_remove_fields_from_L2_data(sss)
%
%   INPUT
%     sss       = a structure of arrays with appropriately named fields
%
%   OUTPUT
%     sss       = a structure of arrays with these extraneous fields deleted.
%
% DEPENDENCIES
%   Matlab 2018b
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2020-10-13: desiderio: initial code
%.. 2021-05-21: desiderio: radMMP version 3.10g (OOI global)
%=========================================================================

%.. append mfilename to all sss.code_history elements
Q = {sss.code_history}';  % extract
QQ = cellfun(@(x) [x {mfilename}], Q, 'uni', 0);  % append to each element
[sss.code_history] = QQ{:};
clearvars Q QQ

fields_to_remove = {
    'velBeam'
    'velXYZ'
%    'wag_signal'
    'profile_mask'
    'sensor_field_indices'
    };

sss = rmfield(sss, fields_to_remove);

%.. append data status to all sss elements
Q = {sss.data_status}';
QQ = cellfun(@(x) [x {'unbinned fields removed'}], Q, 'uni', 0);
[sss.data_status] = QQ{:};
end
