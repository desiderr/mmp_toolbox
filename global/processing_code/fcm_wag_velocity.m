function [acm] = fcm_wag_velocity(acm)
%=========================================================================
% DESCRIPTION
%   Calculates the theoretical wag correction velocity.
%
% USAGE:  [acm] = fcm_wag_velocity(acm)
%
%   INPUT
%     acm = a scalar structure containing velXYZ and heading data,
%           effective wag radius and data acquisition rate.
%
%   OUTPUT
%     acm = a scalar structure containing wag velocities in the field
%           wag_signal.
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   The magnitude of the wag velocity is Vwag = R * dH/dt where R is
%   the wag radius and H is the heading. The direction of the wag velocity
%   at any point is tangent to the radius drawn from that point to the
%   profiler wire, the axis of rotation. When the profiler spins the water
%   motion relative to the profiler is measured as a signal in velY, the
%   velocity in the instrument axis Y direction.
%
%   The effective radius R can be found by assuming that the profiler is
%   spinning at a constant rate dH/dt = +1 radian/sec and calculating the
%   velocity that would be measured by the 3DMP acoustic currentmeter.
%   The profiler when viewed from above is rotating clockwise; the water 
%   velocity relative to the spinning profiler is moving CCW and in the
%   instrument coordinate system is moving in the +Y direction.
%
%   The raw beam velocity measured from the V1 stinger (port stinger in the
%   horizontal plane) will have contributions from each point in its raw 
%   beam path. The measured velocity at each point i will be the projection
%   of the wag velocity at that point into the raw beam direction which is
%   cos(Ai) * Ri * dH/dt where Ai is the angle between the directions of
%   the wag velocity and the beam path. This value is identical for every
%   point in the beam path as can be shown from a geometric proof. The 
%   result is that the raw beam velocity V1 is measured as 0.43/sqrt(2) m/s,
%   where the distance from the wire to the distal tip of the central post
%   is estimated to be 43 cm.
%
%   The transformation from raw beam velocities to velY is given by
%   velY = (V1-V3)/sqrt(2) where V3 is the starboard stinger in the horizontal
%   plane. From symmetry and the FSI sign convention for raw beam velocities
%   V3 = (-V1) for the case under consideration so that the instrument 
%   measures: velY = (2*V1)/sqrt(2) = V1*sqrt(2). Because V1 = 0.43/sqrt(2) m/s,
%   velY = 0.43 m/s which equals R * dH/dt which gives a theoretical wag
%   radius of 43 cm.
%
%   For the case of a profiler spinning in the CW direction as above the
%   measured wag velocity velY is positive as is the calculation R*dH/dt.
%   Therefore to make the correction for all cases subtract the calculated
%   signal from the measured velY velocity.
%
%   Empirically it has been found that measured velY wag signals do not perfectly
%   correlate with theoretically calculated signals R*dH/dt both in magnitude
%   and phase, although it is found that making these adjustments on a case by
%   case basis can do a very good job of cancelling out wag artifacts. The 
%   default setting for the radMMP code suite is to eliminate the higher
%   frequency wag signals by applying a digital smoothing filter with a 12 
%   second time constant. Longer period artifacts that are not smoothed out
%   have been observed and for this reason the calculated wag signal is 
%   still included as a data product.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2020-10-09: desiderio: acm_wag_correction, initial code
%.. 2020-12-22: desiderio: renamed to acm_wag_velocity, revised documentation
%.. 2021-05-21: desiderio: radMMP version 3.10g (OOI global)
%=========================================================================

%----------------------
% PRELIMINARY SET-UP
%----------------------

acm.code_history(end+1) = {mfilename};
if isempty(acm.heading)
    acm.data_status(end+1) = {'[]: no action taken'};
    return
end

%------
% BEGIN
%------

R = acm.wag_radius;  % [m]
%.. calculate the time derivative of the heading (units of radians):
dH = diff(unwrap(deg2rad(acm.heading)));
%.. calculate the time derivative:
%.. same as using the gradient function but faster
dHa = [dH(1); dH];
dHb = [dH; dH(end)];
dH_dt = (dHa+dHb) * acm.acquisition_rate_Hz_calculated / 2;  % [rad/sec]
Ywag = R * dH_dt;
%
acm.wag_signal  = Ywag;  % [m/sec]

if acm.correct_velY_for_wag
    acm.velXYZ(:, 2) = acm.velXYZ(:, 2) - Ywag;
    acm.data_status(end+1) = {'wag correction applied'};
else
    acm.data_status(end+1) = {'wag correction NOT applied'};
end

end
