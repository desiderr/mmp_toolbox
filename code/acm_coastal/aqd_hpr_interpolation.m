function [aqd] = aqd_hpr_interpolation(aqd)
%=========================================================================
% DESCRIPTION
%   Interpolates heading, pitch, and roll data.
%
% USAGE:  [aqd] = aqd_hpr_interpolation(aqd)
%
%   INPUT
%     aqd = a scalar structure containing fields named heading, pitch,
%                 and roll containing corresponding data records. 
%
%   OUTPUT
%     aqd = a scalar structure containing interpolated data in the 
%                 fields specified above.
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   The AD2CP heading, pitch, and roll sensors acquire data at 1 Hz. The
%   AD2CP itself is configured to acquire velocity data at 2 (sometimes 4)
%   Hz. Therefore unpacked 'A' data files have repeated tilt values. For
%   heading this is significant; swivels greater than 60 degrees have been
%   observed in one second.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%.. 2021-05-10: desiderio: radMMP version 2.20c (OOI coastal)
%.. 2021-05-24: desiderio: radMMP version 4.0
%=========================================================================

aqd.code_history(end+1) = {mfilename};
if isempty(aqd.heading)
    aqd.data_status(end+1) = {'[]: no action taken'};
    return
end

hdg = aqd.heading;
npts = length(hdg);
%.. separate the hdg values into those that correspond to 
%.. .. updated readings and
%.. .. those that are repeated values of the last update (fills)
%.. so that the algorithm will work with both 2 and 4 Hz.
idx_diffs = find(diff(hdg));
stride = min(diff(idx_diffs));
idx_first_update = 1 + mod(idx_diffs(1), stride);
idx_updates = idx_first_update:stride:npts;
idx_fills   = setdiff(1:npts, idx_updates);
%.. only heading needs to be 'unwrapped'
hdg = unwrap(deg2rad(hdg));
hdg_fills = interp1(idx_updates, hdg(idx_updates), idx_fills, 'spline');
hdg(idx_fills) = hdg_fills;
aqd.heading = mod(rad2deg(hdg), 360);
%.. pitch
pitch_fills =  interp1(idx_updates, aqd.pitch(idx_updates), idx_fills, 'spline');
aqd.pitch(idx_fills) = pitch_fills;
%.. roll
roll_fills =  interp1(idx_updates, aqd.roll(idx_updates), idx_fills, 'spline');
aqd.roll(idx_fills) = roll_fills;

%.. done
aqd.data_status(end+1) = {'h,p,r interpolated'};

end
%--------------------------------------------------------------------


