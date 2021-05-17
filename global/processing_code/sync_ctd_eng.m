function [ctd, eng] = sync_ctd_eng(ctd, eng)
%=========================================================================
% DESCRIPTION
%   Synchronizes ctd and eng profile masks
%   Updates eng pressure and dP/dt to be consistent with the ctd values.
%
% USAGE:  [ctd, eng] = sync_ctd_eng(ctd, eng)
%
%   INPUT
%     ctd  = one element from a structure array created by import_C_sbe52.m 
%     eng  = one element from a structure array created by a variant of
%            import_E_mmp.m 
%
%   OUTPUT
%     ctd  = a scalar structure
%     eng  = a scalar structure
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   The 1 Hz ctd pressure data when processed are more accurate than the
%   unprocessed engineering pressure data.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-04: desiderio: radMMP version 3.0 (OOI coastal and global)
%=========================================================================

ctd.code_history(end+1) = {mfilename};
eng.code_history(end+1) = {mfilename};

if isempty(eng.pressure) || isempty(ctd.pressure)
    ctd.data_status(end+1) = {'NOT SYNC''ED'};
    eng.data_status(end+1) = {'NOT SYNC''ED'};
    return
end

eng.profile_direction = ctd.profile_direction;

%.. when multiple backtracks are recorded within the engineering file,
%.. the ctd and eng pressure records can be valid but not ctd time. 
if isempty(ctd.time) || any(isnan(ctd.time(:))) 
    disp('Warning: no timestamps found while sync''ing:');
    disp(['        Profile flags set to false for profile ' ...
        num2str(ctd.profile_number) '.']);
    ctd.data_status(end+1) = {'ALL FLAGGED BAD'};
    ctd.profile_mask = false(size(ctd.pressure));
    ctd.time = nan(size(ctd.pressure));
    eng.data_status(end+1) = {'NOT SYNC''ED'};
    return
end

%..          SYNCHRONIZE PROFILE MASKS
%.. transfer eng profile mask to ctd timestamps
%
%.. profile_mask values consist of logical ones and zeros; change to single.
%.. make sure extrapolated ctd values (outside of pressure record range)
%.. are 0 by specifying 0 as the last argument in the interp1 call.
ctd_ntrp = interp1(eng.time, single(eng.profile_mask), ctd.time, ...
    'linear', 0);

%.. points between adjacent good and bad values will be fractional, and are 
%.. bad; the only good profile ctd points will be those that lie within
%.. the closed 'true' intervals and therefore will have a value of 1.
ctdmask_basedOnEngMask = ctd_ntrp == 1;

%.. also mask eng data based on ctd profile_mask
eng_ntrp = interp1(ctd.time, single(ctd.profile_mask), eng.time, ...
    'linear', 0);
engmask_basedOnCtdmask = eng_ntrp == 1;

%.. combine masks for each structure; 
%.. keep only the points that are good in both masks
ctd.profile_mask = ctd.profile_mask & ctdmask_basedOnEngMask;
eng.profile_mask = eng.profile_mask & engmask_basedOnCtdmask;


%..          UPDATE ENG P AND DP/DT TO MATCH CTD
eng_pr_data  = interp1(ctd.time, [ctd.pressure ctd.dpdt], eng.time);
eng.pressure = eng_pr_data(:, 1);
eng.dpdt     = eng_pr_data(:, 2);

ctd.data_status(end+1) = {'sync''ed'};
eng.data_status(end+1) = {'sync''ed'};

end

