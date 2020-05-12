function [aqd] = aqd_wag_correction(aqd)
%=========================================================================
% DESCRIPTION
%   Calculates the wag correction velocity.
%
% USAGE:  [aqd] = aqd_wag_correction(aqd)
%
%   INPUT
%     aqd = a scalar structure containing velXYZ data
%
%   OUTPUT
%     aqd = a scalar structure containing wag velocities in the field
%           wag_signal; and, velY is corrected for wag if the corresponding
%           switch is set to true.
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   Vwag = R * d(heading)/dt, where R is the moment arm (wag radius). 
%   Transducer beams can measure only the parallel component of the wag
%   motion. If the ad2cp is mounted on the profiler so that the transducer
%   axes of the ad2cp beams in the horizontal plane (2 and 4) lie on wag
%   radii then theoretically, in ideal conditions, no wag signal will be
%   measured and a correction would not be needed. On the McLane the ad2cp
%   is mounted forward of this position; the transducer axes are calculated
%   to be at an angle of 5 degrees to the wag radii. 
%
%   The expected wag signal can be calculated by propagating (sin(5) deg) *
%   Vwag) through the beam to instrument coordinate transformation matrices.
%   As expected the result is the same for [1 2 4] and [2 3 4] profiles:
%
%   Ywag = R * d(heading)/dt * sin(5deg) / sin(25deg)
%
%   SIGN
%
%   When d(heading)/dt is positive (CW profiler rotation) the water velocity
%   motion relative to the profiler is in the CCW direction. The tangential
%   velocity vector decomposes into a component away from the beam 2 transducer
%   (positive radial velocity) and towards the beam 4 transducer (negative
%   radial velocity). When propagated through the beam2xyz matrices the
%   result is a wag signal that is in the negative 'y' direction. When the 
%   xyz2XYZ coordinate transformation is applied the wag signal is in the
%   positive 'Y' direction in the XYZ coordinate system.
%
%   To make the correction subtract the calculated signal from the Y velocity.
%
%   R can be treated as an adjustable parameter to scale the applied wag
%   correction. the theoretical value (0.43 m) is calculated as the distance
%   from the wire to the center of the ad2cp sample cell. 
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%   2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%=========================================================================

%----------------------
% PRELIMINARY SET-UP
%----------------------

aqd.code_history(end+1) = {mfilename};
if isempty(aqd.heading)
    aqd.data_status(end+1) = {'[]: no action taken'};
    return
end

%------
% BEGIN
%------

R = aqd.wag_radius;  % [m]
%.. calculate the time derivative of the heading (units of radians):
dH = diff(unwrap(deg2rad(aqd.heading)));
%.. calculate the time derivative:
%.. same as using the gradient function but faster
dHa = [dH(1); dH];
dHb = [dH; dH(end)];
dH_dt = (dHa+dHb) * aqd.acquisition_rate_Hz_calculated / 2;  % [rad/sec]
Ywag = R * dH_dt * sind(5) / sind(25);
%
aqd.wag_signal  = Ywag;  % [m/sec]

if aqd.correct_velY_for_wag
    aqd.velXYZ(:, 2) = aqd.velXYZ(:, 2) - Ywag;
    aqd.data_status(end+1) = {'wag correction applied'};
else
    aqd.data_status(end+1) = {'wag correction NOT applied'};
end

end
