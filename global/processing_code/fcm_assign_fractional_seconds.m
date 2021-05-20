function [acm] = fcm_assign_fractional_seconds(acm)
%=========================================================================
% DESCRIPTION
%   Assigns fractional seconds to 3DMP timestamps.
%
% USAGE:  [acm] = fcm_assign_fractional_seconds(acm)
%
%   INPUT
%     acm = a scalar structure containing 3DMP acm data with a time record. 
%
%   OUTPUT
%     acm = a scalar structure with a monotonic time record.
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   The data acquisition rate of FSI 3DMP time records as acquired by McLane
%   profilers in the OOI program is set to 2 Hz (sometimes 4 Hz data are
%   encountered). The time record is not monotonic because fractional
%   seconds are not stored in the binary data files. For normal 2hz data the
%   time record is usually comprised of pairs of identical timestamps 
%   although sometimes singletons are encountered. With 4 Hz data triplet
%   and quintuplet groupings occur interspersed among the quadruplet
%   groupings.
%
%   If the input file has no neighboring degeneracies then it will pass
%   through without change.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2020-10-05: desiderio: initial code
%.. 2021-05-21: desiderio: radMMP version 3.10g (OOI global)
%=========================================================================

acm.code_history(end+1) = {mfilename};
if isempty(acm.heading)
    acm.data_status(end+1) = {'[]: no action taken'};
    return
end

dtime = diff(acm.time);
%.. find the start index of each grouping.
%.. differencing moves forward, so prepend 1 element to move back
idxStart = [0; find(dtime)] + 1;
%.. find the number of points in each grouping
jpts = [diff(idxStart); length(acm.time)-idxStart(end)+1];
%.. and fill in fractional seconds based on each jpts value
%.. idxStart and jpts should have the same number of elements
timeTrial = acm.time;
for ii = 1:length(idxStart)
    for jj = 1:jpts(ii)
        indexIJ = idxStart(ii) + (jj - 1);
        timeTrial(indexIJ) = timeTrial(indexIJ) + (jj-1)/jpts(ii)/86400;
    end
end
if (any(diff(timeTrial)<=0))
    disp(' ');
    disp('************************* WARNING **************************');
    disp('FAILED TO ASSIGN FRACTIONAL SECONDS TO DEGENERATE TIMESTAMPS');
    disp('************************* WARNING **************************');
    disp(' ');
    acm.heading = [];  % to disable further processing
    acm.data_status(end+1) = {'FrctSecFail: heading set to []'};
else
    %.. done
    acm.time = timeTrial;
    acm.data_status(end+1) = {'monotonicTime'};
end

end

