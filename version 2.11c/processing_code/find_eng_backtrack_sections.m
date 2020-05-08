function [eng] = find_eng_backtrack_sections(eng, pressureMinimum)
%=========================================================================
% DESCRIPTION
%   Determines backtracking sections from the pressure record;
%   Updates profile mask which identifies backtrack sections;
%   Calculates dP/dt.
%
% USAGE:  [eng] = find_eng_backtrack_sections(eng)
%
%   INPUT 
%     eng: one element from a structure array created by import_E_mmp.m
%     pressureMinimum [db]: engineering pressures below this value are set
%                           to 0 when determining backtrack sections and
%                           when calculating the profile mask
%                         
%
%   OUTPUT 
%     eng  = a scalar structure
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   Sometimes small negative and positive values of pressure appear
%   in the engineering record. The latter can cause minimum bin values
%   of 0 to occur when the deployment data are used to determine binning
%   extrema. In the OOI program, there should never be readings less
%   than 20 db [BUT THERE ARE]. To fix this, set pressureMinimum to a 
%   positive value less than the expected profile pressure minimum for
%   the deployment. 
%
%   This parameter should be put into the metadata file so that it can
%   be easily accessed and changed by users.
%
% REFERENCES
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%=========================================================================

eng.code_history(end+1) = {mfilename};
if isempty(eng.pressure)
    eng.data_status(end+1) = {'not processed'};
    return
end

%.. check for backtracks in the profile (pressure readings of 0).
%.. all profiles start with a number of pressure=0 readings.
%.. .. change nonzero readings to 1, then difference neighboring values.
%.. .. a negative difference indicates a pressure=0 reading occurring
%.. .. after a non-zero value
pr = eng.pressure;
%.. order is important here!
pr(pr<pressureMinimum) = 0;
pr(pr>pressureMinimum) = 1;
if any( diff(pr)<0 )
    eng.backtrack = 'yes';
end
eng.profile_mask = logical(pr);
%.. calculate dpdt; it will be replaced by ctd values after the 
%.. ctd pressure is processed 
%
%.. first nan out unphysical WFP profiling values
pr = eng.pressure;
pr(pr<pressureMinimum) = nan;
%.. same as gradient.m but faster
dP = diff(pr);
dPa = [dP(1); dP];
dPb = [dP; dP(end)];
eng.dpdt = (dPa+dPb) * eng.acquisition_rate_Hz_calculated / 2;  % [db/sec]

eng.data_status(end+1) = {'pressure processed'};

end
