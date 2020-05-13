function aqd = aqd_XYZ2ENU(aqd)
%=========================================================================
% DESCRIPTION
%   Transforms velocities in the XYZ coordinate system into the ENU
%   coordinate system, corrects for magnetic variation, and corrects velZ
%   for vertical profiler motion if the corresponding switch is set to true.
%
% USAGE:  aqd = aqd_XYZ2ENU(aqd)
%
%   INPUT
%     aqd       = a scalar structure containing velXYZ data
%
%   OUTPUT
%     aqd       = a scalar structure containing velENU data
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   There are two applicable switches:
%   (a) correct_velXYZ_for_pitch_and_roll
%   (b) correct_velU_for_dpdt
%
%   XYZ: generalized instrument coordinates
%           when looking at the transducer head when mounted on a McLane:
%           '+X' is towards observer
%           '+Y' is right
%           '+Z' is up
%   ENU: compass coordinates, East-North-Up
%
%   See also documentation in the main body of the code.
%
% REFERENCES
%   Correspondence with Nortek.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-01-31: desiderio: clarified warning message to screen: velU (UP)
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
%.. (0) determine whether pitch and roll corrections should be applied;
%..     correct_velXYZ_for_pitch_and_roll value is either 0 or 1.
%..         multiplying by 0 results in all pitch and roll values of 0,
%..         resulting in the identity matrix for pitch and roll.
pitch = aqd.pitch * aqd.correct_velXYZ_for_pitch_and_roll;
roll  = aqd.roll  * aqd.correct_velXYZ_for_pitch_and_roll;

%.. (1) XYZ to ENU TRANSFORMATION
%
%.. formulate the tilt arrays as column vectors so that each
%.. horizontal slice represents one time point.
cp = cosd(pitch);  sp = sind(pitch);
cr = cosd(roll);   sr = sind(roll);
%.. because in this instrument heading is measured as the projection of 
%.. the X-axis (as opposed to the 'Y' axis) on the horizontal plane, 
%.. 90 degrees must be subtracted from the instrument heading values:
ch = cosd(aqd.heading-90.0);  sh = sind(aqd.heading-90.0);

% GUIDE
%     %.. heading matrix
%     H = [ ch   sh    0;
%          -sh   ch    0;
%            0    0    1];
%     %.. pitch matrix
%     P = [ cp    0  -sp;
%            0    1    0;
%           sp    0   cp];
%     %.. roll matrix
%     R = [  1    0    0;
%            0   cr  -sr;
%            0   sr   cr];
%
%     velENU = H * P * R * velXYZ
%
%.. for speed multiply out the matrix multiplication and hardcode it.

vX = aqd.velXYZ(:, 1);
vY = aqd.velXYZ(:, 2);
vZ = aqd.velXYZ(:, 3);

%.. here, velU is not 'Up'.
velU = vX .*  ch .* cp                     +  ...
       vY .* (sh .* cr - ch .* sp .* sr)   -  ...
       vZ .* (sh .* sr + ch .* sp .* cr);

velV = vX .* -sh .* cp                     +  ...
       vY .* (ch .* cr + sh .* sp .* sr)   +  ...
       vZ .* (-ch .* sr + sh .* sp .* cr);

velW = vX .* sp  +  vY .* cp .* sr  +  vZ .* cp .* cr;

%.. (2) CORRECT FOR MAGNETIC DECLINATION
theta = aqd.magnetic_declination;  % [degrees]
%.. corrects uncorrected east and north velocities U and V for the effects of
%.. magnetic declination to give velocities EN in the true (geographic) East
%.. and North directions.
%
%.. Algorithm check values:
%..       Suppose that the magnetic declination = positive 45 degrees,
%..       so that magnetic north is pointing to geographic Northeast.
%..       A 'UV' velocity of U = 1 and V = 1 points northeast in the 
%..       magnetic coordinate system and has a magnitude of R = sqrt(2).
%..       In the geographic coordinate system this velocity is pointing
%..       due East with the same magnitude. Therefore:
%
%            E | N                                 U | V
%..       -----|----                            -----|-----       
%..       (  R,  0 ) = magnetic_correction( 45, (  1,  1) )
%..       (  0, -R ) = magnetic_correction( 45, (  1, -1) )
%..       ( -R,  0 ) = magnetic_correction( 45, ( -1, -1) )
%..       (  0,  R ) = magnetic_correction( 45, ( -1,  1) )
%
%..       (  0,  R ) = magnetic_correction(-45, (  1,  1) )
%..       (  R,  0 ) = magnetic_correction(-45, (  1, -1) )
%..       (  0, -R ) = magnetic_correction(-45, ( -1, -1) )
%..       ( -R,  0 ) = magnetic_correction(-45, ( -1,  1) )

%.. when aqd.velENU is initialized as a multi-dimensional empty set for binning
%.. purposes (enabling correct nan-dimensioning for missing data for pcolor
%.. plots), one cannot assign a column vector into the structure field - 
%.. the following does not work:
%
% aqd.velENU(:, 1) =  cosd(theta) .* velU   +   sind(theta) .* velV;
% aqd.velENU(:, 2) = -sind(theta) .* velU   +   cosd(theta) .* velV;

velENU(:, 1) =  cosd(theta) .* velU   +   sind(theta) .* velV;
velENU(:, 2) = -sind(theta) .* velU   +   cosd(theta) .* velV;

if aqd.correct_velXYZ_for_pitch_and_roll
    pr_status = 'corrected for pitch and roll; ';
else
    pr_status = 'NOT corrected for pitch and roll; ';
end

%.. (2) CORRECTING velW FOR VERTICAL PROFILER MOTION
%..     (here, velU is from velENU and is vel UP == velW).
%
%.. if the profiler is descending the measured vertical velocity is
%.. biased towards larger positive values because the motion of the
%.. water relative to the downward moving profiler is up. dp/dt
%.. values are positive when the profiler is descending, so subtract
%.. the dp/dt record to correct the vertical velocity for profiler motion.
if isempty(aqd.dpdt) || all(isnan(aqd.dpdt))
    disp(['WARNING: velU (UP) for aqd profile ' ...
        num2str(aqd.profile_number) ' cannot be corrected for dP/dt']);
    velENU(:, 3) = velW;
    aqd.data_status(end+1) = {[pr_status 'velU CANNOT be corrected']};
elseif aqd.correct_velU_for_dpdt
    velENU(:, 3) = velW - aqd.dpdt;
    aqd.data_status(end+1) = {[pr_status 'velU corrected for dp/dt']};
else
    velENU(:, 3) = velW;
    aqd.data_status(end+1) = {[pr_status 'velU NOT corrected']};    
end

aqd.velENU = velENU;
