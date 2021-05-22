function [sss] = fcm_nan_velENU_extreme_tilt(sss)
%=========================================================================
% DESCRIPTION
%   Sets velENU values to Nan when extreme values of pitch and roll occur.
%
% USAGE:  [sss] = fcm_nan_velENU_extreme_tilt(sss)
%
%   INPUT 
%     sss = a scalar structure containing fields named 'TX', 'TY', velENU 
%
%   OUTPUT 
%     sss = a scalar structure whose data values in the velENU fields have 
%           been set NaN if concurrent with extreme tilt values.
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   The criterion for extreme tilt is hardcoded as: 
%          sqrt(TX^2 + TY^2) > 10 degrees.
%   As per Toole (1999) the pitch and roll of the FSI ACM mounted on a
%   McLane profiler are usually negligible, much less than 10 degrees.
%   For this reason the OOI Data Product Algorithms do not correct FSI
%   ACM velocities for pitch and roll. However, intense mesoscale events
%   can cause profiler 'blowdown' which is one cause of extreme tilts. 
%   Because pitch and roll are not used to transform the XYZ data into
%   the ENU basis the corresponding velENU values are set to Nan.

% REFERENCES
%   "Velocity Measurements from a Moored Profiling Instrument", J.M. Toole,
%   K.W. Doherty, D.E. Frye, and S.P. Liberatore, in Proceedings of the
%   IEEE Sixth Working Conference on Current Measurement, March 1999,
%   San Diego, CA, pp 144-149. ISBN 0-7803-5505-9.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2020-12-03: desiderio: initial code
%.. 2021-05-21: desiderio: radMMP version 3.10g (OOI global)
%.. 2021-05-24: desiderio: radMMP version 4.0
%=========================================================================

sss.code_history(end+1) = {mfilename};
if isempty(sss.heading)
    sss.data_status(end+1) = {'[]: no action taken'};
    return
end

extremeTiltThreshold = 10;  % degrees
tilt = sqrt(sss.TX .* sss.TX  +  sss.TY .* sss.TY);
tf_extremeTilt = tilt>extremeTiltThreshold;
sss.velENU(tf_extremeTilt, :) = nan;
sss.data_status(end+1) = {'extreme tilt velENU nan''d'};

end

