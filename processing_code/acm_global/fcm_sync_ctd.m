function [acm] = fcm_sync_ctd(acm, ctd)
%=========================================================================
% DESCRIPTION
%   Adds pressure and dPressure/dt records to acm profiles.
%   Transfers ctd profile_mask and 'profile_direction' to acm.
%   Transfers ctd profile_date and backtrack to acm.
%
% USAGE:  [out] = fcm_sync_ctd(acm, ctd)     (general case)
% USAGE:  [acm] = fcm_sync_ctd(acm, ctd)
%
%   INPUT
%     acm = a scalar structure of acm data representing a profile.
%     ctd = a scalar structure of 'L1' processed ctd data corresponding 
%           to the acm profile data.
%
%   OUTPUT
%     out = a scalar structure with newly created pressure and dP/dt records.
%          (a) If there are no acm timestamps, then acm.pressure = [];
%          (b) If there are problems with either the ctd data or interpolation,
%              then acm.pressure = nan(size(acm.time)).
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
%.. 2020-10-XX: desiderio: global version created by modifying coastal version
%.. 2021-05-19: desiderio: revised input argument checks.
%..                        transfers profile_date from ctd to aqd
%.. 2021-05-21: desiderio: radMMP version 3.10g (OOI global)
%.. 2021-05-24: desiderio: radMMP version 4.0
%=========================================================================

%----------------------
% CHECK INPUT ARGUMENTS
%----------------------
if nargin==2
    if ~isstruct(acm) || ~isstruct(ctd)
        error('Both inputs must be structures.');
    end
    if acm.profile_number ~= ctd.profile_number
        error('acm and ctd structures have different profile numbers.')
    end
    
    acm.code_history(end+1) = {mfilename};
    %.. do this for all cases; even when the structure element time fields
    %.. contain no data the ctd.profile_date value can be real. 
    acm.profile_date = ctd.profile_date;
    acm.backtrack    = ctd.backtrack;
    
    if isempty(acm.time)
       disp(['Warning: structure acm(' ...
           num2str(acm.profile_number) ') has no time data.']);
       acm.pressure = [];
       acm.dpdt = [];
       acm.data_status(end+1) = {'no pressure record added'};
       return              
    elseif isempty(ctd.time) || all(isnan(ctd.time))
       disp(['Warning, fcm_sync_ctd.m: structure ctd(' ...
            num2str(ctd.profile_number) ') does not have interpolatable time data.']);
       acm.pressure = nan(size(acm.time));
       acm.dpdt = nan(size(acm.time));
       acm.data_status(end+1) = {'NaN PRESSURE RECORD ADDED'};
       return
    elseif isempty(ctd.pressure)
       disp(['Warning, fcm_sync_ctd.m: structure ctd(' ...
            num2str(ctd.profile_number) ') has no pressure data.']);
       acm.pressure = nan(size(acm.time));
       acm.dpdt = nan(size(acm.time));
       acm.data_status(end+1) = {'NaN PRESSURE RECORD ADDED'};
       return
    end
    Tacm = acm.time(:);
    Tctd = ctd.time(:);
    Pctd = ctd.pressure(:);
else
    disp(' ');
    error('USAGE:  [acm] = fcm_sync_ctd(acm, ctd)');
end

%------
% BEGIN
%------
if length(Tctd) < 10 || length(Tacm) < 10
    %.. not enough points to deal with
    Pacm = [];
    dpdt = [];
elseif max(Tacm) < min(Tctd) || min(Tacm) > max(Tctd)
    %.. data do not overlap in time
    Pacm = [];
    dpdt = [];
else
    Pacm = interp1(Tctd, Pctd, Tacm, 'makima', 'extrap');
    %.. pressure derivative with respect to time; this
    %.. code is identical to using gradient, but faster.
    %.. may want to smooth pressure record first ...
    dP = diff(Pacm);
    dPa = [dP(1); dP];
    dPb = [dP; dP(end)];
    % %.. average time step; serial date number is in units of days,
    % %.. so multiply the time difference by 86400 to convert to seconds
    % %.. and divide by the number of time intervals
    % dt = 86400 * (Tacm(end)-Tacm(1))/(numel(Tacm)-1);
    %
    %.. reciprocal of the data rate in Hz is the time step dt
    dt = 1.0 / acm.acquisition_rate_Hz_calculated;
    %.. each (interior) element dy(i)/dt is
    %.. ( (y(i+1)-y(i)) + (y(i)-y(i-1)) ) / (2*dt)
    dpdt = (dPa+dPb)/2/dt;  % units of db/sec
    
    %.. transfer ctd profile mask: in this version of the code (1.03c) the ctd
    %.. profile mask is based on engineering backtrack data and ctd vertical
    %.. velocity, and not on whether sensor readings (other than pressure) are
    %.. valid.
    acm_ntrp = interp1(ctd.time, single(ctd.profile_mask), acm.time, ...
        'linear', 0);
    acmmask_basedOnCtdmask = acm_ntrp == 1;
    %.. combine masks for each structure in case the current acm mask flags out
    %.. bad data (not available in ver 1.03c, in which the acm mask has been
    %.. initalized to all true.)
    %
    %.. keep only the points that are good in both masks
    acm.profile_mask = acm.profile_mask & acmmask_basedOnCtdmask;
    
    %.. transfer profile direction
    acm.profile_direction = ctd.profile_direction;
end

%.. apply instrument offset
acm.pressure = Pacm + acm.depth_offset_m;
acm.dpdt = dpdt;

if isempty(acm.pressure)
    acm.pressure = nan(size(acm.time));
    acm.dpdt     = nan(size(acm.time));
    disp(['WARNING: acm(' num2str(acm.profile_number) '): ' ...
        'interpolation to find ctd pressure failed.']);
    acm.data_status(end+1) = {'NaN PRESSURE RECORD ADDED'};
else
    acm.data_status(end+1) = {'pressure record added'};
end

return

end
