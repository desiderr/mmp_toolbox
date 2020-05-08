function [sss] = nan_bad_profile_sections(sss)
%=========================================================================
% DESCRIPTION
%   Sets profile data marked as bad by a profile mask to NaNs.
%
% USAGE:  [sss] = nan_bad_profile_sections(sss)
%
%   INPUT 
%     sss = a scalar structure containing fields named 'profile_mask' and 
%           'sensor_field_indices' that also contains the fields specified
%           by 'sensor_field_indices'.
%
%   OUTPUT 
%     sss = a scalar structure whose data in the fields specified by 
%           'sensor_field_indices' have been NaN'd at the positions 
%           coded for in profile_mask.
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   Can operate on ctd, eng, aqd (acm), par, flr scalar data structures.
%
%   Unexpected results will occur if the field to be nan'd is empty.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-04: desiderio: radMMP version 3.0 (OOI coastal and global)
%=========================================================================

sss.code_history(end+1) = {mfilename};

if isempty(sss.pressure)
    sss.data_status(end+1) = {'pressure empty, no action taken'};
    return
end

%.. need fieldnames so that the field indices can be used
names_field = fieldnames(sss);
for jj = sss.sensor_field_indices
    sss.(names_field{jj})(~sss.profile_mask, :) = nan;
end

sss.data_status(end+1) = {'sections nan''d'};

end

