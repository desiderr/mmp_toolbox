function aqd = aqd_beam2XYZ(aqd)
%=========================================================================
% DESCRIPTION
%   Transforms AD2CP raw beam velocities into velocities in the instrument  
%   XYZ coordinate system.
%
% USAGE:  aqd = aqd_beam2XYZ(aqd)
%
%   INPUT
%     aqd       = a scalar structure containing the following fields:
%                 velBeam [N x 4]; radial beam coordinates
%                 beam_mapping [1 x 3]: either [1 2 4] or [2 3 4]
%
%   OUTPUT
%     aqd       = a scalar structure with the velXYZ field populated
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   This routine must be run before wag is corrected.
%
%   Nortek defines 2 instrument cartesian coordinate systems for the ad2cp;
%   to distinguish them I use the terms 'specific' and 'generalized'.
%
%   Velocities expressed in radial beam (spherical) coordinates are
%   transformed to xyz (specific instrument) coordinates by multiplying
%   by T_beam2xyz:
%      when facing the transducer head mounted on a profiling McLane:
%      '+x' is up (as is marked on the instrument)
%      '+y' is left
%      '+z' is towards observer
%   Velocities expressed in xyz coordinates are 'reoriented' to XYZ
%   (generalized instrument) coordinates because instrument attitudes
%   (heading, pitch, roll) are defined with respect to the XYZ axes:
%      when facing the transducer head mounted on a profiling McLane:
%      '+X' is towards observer
%      '+Y' is right
%      '+Z' is up
%
% REFERENCES
%   Correspondence with Nortek. Nortek supplied the T_beam2xyz matrices
%   with entries accurate to 3 or 4 decimal places. I derived these
%   matrices with exact values by inverting the T_xyz2beam matrices 
%   determined from the known transducer beam geometry.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%=========================================================================

%----------------------
% PRELIMINARY SET-UP
%----------------------

aqd.code_history(end+1) = {mfilename};
if isempty(aqd.heading)
    aqd.data_status(end+1) = {'beam2XYZ NOT APPLIED'};
    return
end

%------
% BEGIN
%------

%.. angle 'A' is the zenith angle for (horizontal) transducers 2 and 4
angleA = 25.0;
ca = cosd(angleA);
sa = sind(angleA);
%.. angle 'B' is the zenith angle for transducers 1 and 3
angleB = 47.5;
cb = cosd(angleB);
sb = sind(angleB);
%.. this matrix element occurs numerous times:
qq = cb /sb / ca / 2.0;

if all(aqd.beam_mapping == [2 3 4])      % (usually descending McLane profiles)
    T_beam2xyz = [    qq      -1.0/sb        qq;
                   -0.5/sa       0       0.5/sa;
                    0.5/ca       0       0.5/ca];
elseif all(aqd.beam_mapping == [1 2 4])  % (usually  ascending McLane profiles)
    T_beam2xyz = [  1.0/sb      -qq         -qq;
                      0       -0.5/sa    0.5/sa;
                      0        0.5/ca    0.5/ca];
else
    error('Beam configuration not supported.' )
end

%.. Reorientation transformation matrix:
%.. .. X =  z
%.. .. Y = -y 
%.. .. Z =  x
T_xyz2XYZ = [0   0   1;
             0  -1   0;
             1   0   0];
T_beam2XYZ = T_xyz2XYZ * T_beam2xyz;

%.. the T_beam2XYZ matrix is invariant for all beam velocity measurements in
%.. a given profile; transformation to XYZ coordinates can be done with one
%.. matrix multiplication.
%.. .. size of velBeam is [Nx4]; transpose the beams defined by the mapping
%.. .. to do the matrix multiplication, then transpose back to column vectors.
aqd.velXYZ = (T_beam2XYZ * aqd.velBeam(:, aqd.beam_mapping)')';

aqd.data_status(end+1) = {'beam2XYZ transformation applied'};
