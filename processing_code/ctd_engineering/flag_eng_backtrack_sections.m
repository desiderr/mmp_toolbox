function [eng] = flag_eng_backtrack_sections(eng, code)
%=========================================================================
% DESCRIPTION
%   Flags backtrack sections of a profile by updating values in the
%   profile mask (false denotes bad values, true denotes good values)
%
% USAGE:  [eng] = flag_eng_backtrack_sections(eng, code)
%
%   INPUT 
%     eng  = one element from a structure array created by import_E_mmp.m 
%     code = an integer denoting flagging treatment:
%            1 -> flag entire profile as bad (logical 0).
%            2 -> flag data good from 1st non-zero pressure up to about 1
%                 minute before 1st backtrack signalled, then bad after that.
%            3 -> flag as bad only pressure=0 sections.
%      not 1:3 -> any other value, no flagging done at all.
%
%   OUTPUT
%     eng  = a scalar structure with an updated profile mask
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   Code = 1 should be used if the data have not been examined.
%
%   Backtrack or no backtrack, the eng pressure record always starts with
%   pressure=0 readings.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-04: desiderio: radMMP version 3.00 (OOI coastal and global)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%.. 2021-02-24: desiderio: fixed case when backtrack occurs within timeshift_sec
%..                        of profile start to prevent negative array index.
%.. 2021-04-29: desiderio: improved status messages. 
%.. 2021-05-10: desiderio: radMMP version 2.20c (OOI coastal)
%.. 2021-05-14: desiderio: radMMP version 3.10 (OOI coastal and global)
%.. 2021-05-24: desiderio: radMMP version 4.0
%=========================================================================

%.. for backtrack code 2 processing; minimum value would be 60 seconds
timeshift_sec = 75;

eng.code_history(end+1) = {mfilename};

if isempty(eng.pressure)
    eng.data_status(end+1) = {'no pressure data'};
    return
end

if     code==1  % flag entire profile as bad
    eng.profile_mask = false(size(eng.pressure));    
elseif code==2  % flag as bad after 1st backtrack detected
    idx = find(diff(eng.profile_mask)<0, 1) + 1;
    %.. this is the index where the eng pressure record went to 0,
    %.. signalling the occurrence of the 1st backtrack. this seems to occur
    %.. about 1 minute after the ctd pressure record has started to plateau.
    %.. therefore, shift the index to earlier time.
    idx = idx - ceil(eng.acquisition_rate_Hz_calculated * timeshift_sec);
    %.. if the backtrack was signalled within timeshfit_sec seconds after
    %.. the start of the profile, idx will be <=0, so:
    idx = max(idx, 1);
    eng.profile_mask(idx:end) = false;
elseif code==3  % flag as bad just backtrack portions
    %.. should have been done on import. no performance hit, though, so
    eng.profile_mask = ~eng.pressure==0;
else
    eng.data_status(end+1) = {'backtrack NOT FLAGGED'};
    return
end

eng.data_status(end+1) = {['backtrack FLAGGED: code ' num2str(code)]};

end

