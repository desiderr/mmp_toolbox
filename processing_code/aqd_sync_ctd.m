function [out] = aqd_sync_ctd(aqd, ctd)
%=========================================================================
% DESCRIPTION
%   Adds pressure and dPressure/dt records to aqd profiles.
%   Transfers ctd profile_mask and 'profile_direction' to aqd.
%
% USAGE:  [out] = aqd_sync_ctd(aqd, ctd)
%
%   INPUT
%     aqd = a scalar structure of aqd data representing a profile.
%     ctd = a scalar structure of 'L1' processed ctd data corresponding 
%           to the aqd profile data.
%
%   OUTPUT
%     out = a scalar structure with newly created pressure and dP/dt records.
%          (a) If there are no aqd timestamps, then aqd.pressure = [];
%          (b) If there are problems with either the ctd data or interpolation,
%              then aqd.pressure = nan(size(aqd.time)).
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   The CTD time record must be calculated first by running the program
%   add_ctd_timestamps.m on the ctd and eng data. In addition, it is
%   recommended that CTD processing has been completed before running
%   this program.
%
%   nan(size([])) = []
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-12: desiderio: put in test for ctd-aqd time overlap
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%=========================================================================

%----------------------
% CHECK INPUT ARGUMENTS
%----------------------
out = [];
if nargin==2
    if ~isstruct(aqd) || ~isstruct(ctd)
        error('Both inputs must be structures.');
    end
    if aqd.profile_number ~= ctd.profile_number
        error('aqd and ctd structures have different profile numbers.')
    end
    aqd.code_history(end+1) = {mfilename};
    if strncmpi(aqd.data_status{1}, 'no data', 7) || isempty(aqd.time)
       disp(['Warning: structure aqd(' ...
           num2str(aqd.profile_number) ') has no time data.']);
       aqd.pressure = [];
       aqd.dpdt = [];
       aqd.data_status(end+1) = {'no pressure record added'};
       out = aqd;
       return              
    elseif strncmpi(ctd.data_status{1}, 'no data', 7) || any(isnan(ctd.time))
       disp(['Warning, aqd_sync_ctd.m: structure ctd(' ...
            num2str(ctd.profile_number) ') has NaN(s) in time data.']);
       aqd.pressure = nan(size(aqd.time));
       aqd.dpdt = nan(size(aqd.time));
       aqd.data_status(end+1) = {'NaN PRESSURE RECORD ADDED'};
       out = aqd;
       return
    end
    Taqd = aqd.time(:);
    Tctd = ctd.time(:);
    Pctd = ctd.pressure(:);
else
    disp(' ');
    disp('Warning: there must be 2 calling arguments:');
    disp('USAGE: all inputs and outputs are structures:')
    disp('           aqdP = aqd_sync_ctd(aqd, ctd)');
    disp(' ');
    return
end

if isempty(Taqd) || isempty(Tctd) || isempty(Pctd)
    disp(['Warning: at least one of the necessary input variables ' ...
        'has no data.']);
    return
end

%------
% BEGIN
%------
if length(Tctd) < 10 || length(Taqd) < 10
    %.. not enough points to deal with
    Paqd = [];
    dpdt = [];
elseif max(Taqd) < min(Tctd) || min(Taqd) > max(Tctd)
    %.. data do not overlap in time
    Paqd = [];
    dpdt = [];
else
    Paqd = interp1(Tctd, Pctd, Taqd, 'makima', 'extrap');
    %.. pressure derivative with respect to time; this
    %.. code is identical to using gradient, but faster.
    %.. may want to smooth pressure record first ...
    dP = diff(Paqd);
    dPa = [dP(1); dP];
    dPb = [dP; dP(end)];
    % %.. average time step; serial date number is in units of days,
    % %.. so multiply the time difference by 86400 to convert to seconds
    % %.. and divide by the number of time intervals
    % dt = 86400 * (Taqd(end)-Taqd(1))/(numel(Taqd)-1);
    %
    %.. reciprocal of the data rate in Hz is the time step dt
    dt = 1.0 / aqd.acquisition_rate_Hz_calculated;
    %.. each (interior) element dy(i)/dt is
    %.. ( (y(i+1)-y(i)) + (y(i)-y(i-1)) ) / (2*dt)
    dpdt = (dPa+dPb)/2/dt;  % units of db/sec
    
    %.. transfer ctd profile mask: in this version of the code (1.03c) the ctd
    %.. profile mask is based on engineering backtrack data and ctd vertical
    %.. velocity, and not on whether sensor readings (other than pressure) are
    %.. valid.
    aqd_ntrp = interp1(ctd.time, single(ctd.profile_mask), aqd.time, ...
        'linear', 0);
    aqdmask_basedOnCtdmask = aqd_ntrp == 1;
    %.. combine masks for each structure in case the current aqd mask flags out
    %.. bad data (not available in ver 1.03c, in which the aqd mask has been
    %.. initalized to all true.)
    %
    %.. keep only the points that are good in both masks
    aqd.profile_mask = aqd.profile_mask & aqdmask_basedOnCtdmask;
    
    %.. transfer profile direction
    aqd.profile_direction = ctd.profile_direction;
end

%.. apply instrument offset
aqd.pressure = Paqd + aqd.depth_offset_m;
aqd.dpdt = dpdt;

if isempty(aqd.pressure)
    aqd.pressure = nan(size(aqd.time));
    aqd.dpdt     = nan(size(aqd.time));
    disp(['WARNING: aqd(' num2str(aqd.profile_number) '): ' ...
        'interpolation to find ctd pressure failed.']);
    aqd.data_status(end+1) = {'NaN PRESSURE RECORD ADDED'};
else
    aqd.data_status(end+1) = {'pressure record added'};
end
out = aqd;

return

end
