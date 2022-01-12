function acm = fcm_beam2XYZ(acm)
%=========================================================================
% DESCRIPTION
%   Transforms FSI 3DMP raw beam velocities into velocities in the instrument  
%   XYZ coordinate system.
%
% USAGE:  acm = fcm_beam2XYZ(acm)
%
%   INPUT
%     acm       = a scalar structure containing the field:
%                 velBeam [N x 4]; raw beam coordinates
%
%   OUTPUT
%     acm       = a scalar structure with the velXYZ field populated
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   This routine must be run before wag is calculated.
%
%   Velocities expressed in raw beam coordinates are transformed to 
%   instrument coordinates XYZ. Matrices are not used because the 
%   instrument geometry greatly simplifies the calculation.
%
%   The instrument XYZ system is defined as:
%   when *facing* (in front of) the stinger head mounted on a profiling McLane:
%      '+X' is towards observer
%      '+Y' is right
%      '+Z' is up
%
%   The 4 columns of raw beam data velBeam(1:N, 1:4) are defined by the 
%   stinger geometry as:
%
% (Xplus, Yplus, Xminus, Yminus)     (MMP User Manual Rev E, pages G-22,23)
% (va   , vb   , vc    , vd    )     (IDD, VEL3D series A)
% (vp1  , vp2  , vp3   , vp4   )     (IDD, VEL3D series L)
% (right, down , left  , up    )     (spatial orientation as specified here earlier, 
%                                    looking from in front of profiler towards profiler)
% (left , down , right , up    )     (spatial orientation as specified in DPA, 
%                                    looking from behind profiler through profiler)
%
%   This is also the ordering of these parameters in telemetered and recovered data.
%
% REFERENCES
%   "McLane Moored Profiler User Manual" Rev-E (sic) September 2008. Appendix G
%   "Rev C Electronics Board User Interface" (sic) pages G-22,G-23. 
%
%   "Profiler Integrated Sensors & Communications Interface User Manual".
%   version 17.G.25. 2017. McLane Research Laboratories, Inc. Chapter 4.
%
%   The python DPA function fsi_acm_horz_vel at line 1297 (in 2020) in the module at
%   https://github.com/oceanobservatories/ion-functions/blob/master/ion_functions/data/vel_functions.py
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
    acm.data_status(end+1) = {'beam2XYZ NOT APPLIED'};
    return
end

%.. convert from beam coordinates to instrument coordinates, and 
%.. from cm/s to m/s.
Vx = (-acm.velBeam(:, 1) - acm.velBeam(:, 3)) / sqrt(2.0) / 100;
Vy = ( acm.velBeam(:, 1) - acm.velBeam(:, 3)) / sqrt(2.0) / 100;

if strcmpi(acm.profile_direction, 'ascending')
    Vz =  Vx - sqrt(2.0) * acm.velBeam(:, 4) / 100;
elseif strcmpi(acm.profile_direction, 'descending')
    Vz = -Vx + sqrt(2.0) * acm.velBeam(:, 2) / 100;
else
    disp(['Warning: profile ' num2str(acm.profile_number) ...
        ' was neither ascending nor descending.']);
    Vz = Vx * nan;
end

acm.velXYZ = [Vx Vy Vz];
acm.data_status(end+1) = {'beam2XYZ transformation applied'};
