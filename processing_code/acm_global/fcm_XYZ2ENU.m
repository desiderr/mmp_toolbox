function acm = fcm_XYZ2ENU(acm)
%=========================================================================
% DESCRIPTION
%   Transforms velocities in the XYZ coordinate system into the ENU
%   coordinate system, corrects for magnetic variation, and corrects velZ
%   for vertical profiler motion if the corresponding switch is set to true.
%
% USAGE:  acm = fcm_XYZ2ENU(acm)
%
%   INPUT
%     acm       = a scalar structure containing velXYZ data
%
%   OUTPUT
%     acm       = a scalar structure containing velENU data
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   As in the python DPA (see References) no correction is made for pitch
%   and roll because they are assumed to be small (Toole 1999).
%
%   There is one applicable switch: correct_velU_for_dpdt. Default code
%   setting is to set this switch to off.
%
%   XYZ: generalized instrument coordinates
%           when *facing* the McLane looking at the installed ACM:
%           '+X' is towards observer
%           '+Y' is right
%           '+Z' is up
%   ENU: compass coordinates, East-North-Up
%
% REFERENCES
%   The python DPA function fsi_acm_horz_vel at line 1297 (in 2020) in the module at
%   https://github.com/oceanobservatories/ion-functions/blob/master/ion_functions/data/vel_functions.py
%
%   "Velocity Measurements from a Moored Profiling Instrument", J.M. Toole,
%   K.W. Doherty, D.E. Frye, and S.P. Liberatore, in Proceedings of the
%   IEEE Sixth Working Conference on Current Measurement, March 1999,
%   San Diego, CA, pp 144-149. ISBN 0-7803-5505-9.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2020-10-06: desiderio: initial code
%.. 2021-05-21: desiderio: radMMP version 3.10g (OOI global)
%.. 2021-05-24: desiderio: radMMP version 4.0
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

%.. (1) XYZ to ENU TRANSFORMATION
%.. follow the DPA, except that angles are in degrees
speed = sqrt(acm.velXYZ(:, 1) .* acm.velXYZ(:, 1) + acm.velXYZ(:, 2) .* acm.velXYZ(:, 2));
magvar = acm.magnetic_declination;
theta_cartesian = atan2d(acm.velXYZ(:, 2), acm.velXYZ(:, 1)) + (90 - acm.heading) - magvar;
velEast    = speed .* cosd(theta_cartesian);
velNorth   = speed .* sind(theta_cartesian);
velUp      = acm.velXYZ(:, 3);  % velUp = velZ
acm.velENU = [velEast velNorth velUp];

%.. (2) CORRECTING velUp FOR VERTICAL PROFILER MOTION
%
%.. if the profiler is descending the measured vertical velocity is
%.. biased towards larger positive values because the motion of the
%.. water relative to the downward moving profiler is up. dp/dt
%.. values are positive when the profiler is descending, so subtract
%.. the dp/dt record to correct the vertical velocity for profiler motion.
if isempty(acm.dpdt) || all(isnan(acm.dpdt))
    disp(['WARNING: velU (Up) for acm profile ' ...
        num2str(acm.profile_number) ' cannot be corrected for dP/dt']);
    % velUp is already set to velZ
    acm.data_status(end+1) = {'velUp CANNOT be corrected'};
elseif acm.correct_velU_for_dpdt
    acm.velENU(:, 3) = velUp - acm.dpdt;
    acm.data_status(end+1) = {'velUp corrected for dp/dt'};
else
    % velUp is already set to velZ
    acm.data_status(end+1) = {'velUp NOT corrected'};    
end
