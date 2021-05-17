function [aqd] = aqd_phase_ambiguity_correction(aqd)
%=========================================================================
% DESCRIPTION
%   Finds aliased values for raw beam vertical velocities caused by
%   phase ambiguity; corrects beam velocties if switch is so set.
%
% USAGE:  [aqd] = aqd_phase_ambiguity_correction(aqd)
%
%   INPUT
%     aqd = a scalar structure containing ad2cp raw beam velocities
%
%   OUTPUT
%     aqd = a scalar structure containing the time and velocity values
%           of ambiguous points in the field so named and its beam 
%           velocity values corrected if the switch 
%           'correct_velBeam_for_phase_ambiguity' is set to true.
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   The ad2cp instruments in the OOI program are configured to function in
%   'extended range' mode: velocities greater than those associated with
%   relative phases within the [-pi pi] range can be measured if the phases
%   can be correctly assigned to a higher (phase) ambiguity wrap. Nortek's
%   extended range algorithm uses coherence to make these assignments and
%   can give erroneous values when the sensor sample volume is subjected
%   to turbulence (eg, if it's in the wake of a CTD). Therefore correcting
%   'extended range' ad2cp data for phase ambiguity can be tricky because
%   it is possible that raw beam velocities associated with phases outside
%   of [-pi pi] are not artifactual.
%
%   The Nortek definition of ambiguity velocity envelops the full 2(pi)
%   range; the other convention uses [0 pi], ie half that of Nortek's.
%
%   This code corrects only vertical AD2CP beams (b1 or b3).
%
% REFERENCES
%   Correspondence with Nortek.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%.. 2021-05-10: desiderio: radMMP version 2.20c (OOI coastal)
%=========================================================================

aqd.code_history(end+1) = {mfilename};
if isempty(aqd.heading)
    aqd.data_status(end+1) = {'[]: no action taken'};
    return
end

% the ambiguity velocity (m/sec) is a field value in the input structure 
%
% select vertical transducer used in this profile (1 or 3)
bvert = setdiff(aqd.beam_mapping, [2 4]);
rawbeam = aqd.velBeam(:, bvert);
tf_cumulative = false([length(aqd.time) 1]);  % track corrected points
nwraps = 5;
for jj = nwraps:-1:1
    %.. if all velocities associated with phases outside of [-pi pi] are to
    %.. be wrapped back into this interval then frctn=0.5 should be used.
    %.. However,velocities corresponding to phases between -pi and -1.3pi are
    %.. observed which should not be wrapped; therefore a frctn value of 0.25
    %.. is used which guarantees that velocities with phases [-1.5pi 1.5pi]
    %.. will not be wrapped.
    frctn = 0.25;
    ii = jj - frctn;  
    tf_lo = rawbeam < -ii*aqd.ambiguity_velocity;
    rawbeam(tf_lo) = rawbeam(tf_lo) + jj * aqd.ambiguity_velocity;
    tf_hi = rawbeam >  ii*aqd.ambiguity_velocity;
    rawbeam(tf_hi) = rawbeam(tf_hi) - jj * aqd.ambiguity_velocity;
    tf_cumulative = tf_cumulative | tf_lo | tf_hi;
end

aqd.ambiguous_points = ...
    [aqd.time(tf_cumulative) aqd.velBeam(tf_cumulative, bvert)];

if aqd.correct_velBeam_for_phase_ambiguity
    aqd.velBeam(:, bvert) = rawbeam;  % rawbeam has been corrected
    aqd.data_status(end+1) = {'phase ambiguity correction applied'};
else
    aqd.data_status(end+1) = {'phase ambiguity NOT corrected'};    
end
