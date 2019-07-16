function [ctd] = add_ctd_timestamps(ctd, eng)
%=========================================================================
% DESCRIPTION
%    Creates a CTD time record by associating its pressure record to the
%    pressure and time records of the corresponding MMP engineering data.
%
% USAGE:  ctd = add_ctd_timestamps(ctd, eng)
%
%   INPUT
%     ctd = one element from a structure array created by import_C_sbe52.m 
%     eng = one element from a structure array created by import_E_mmp.m
%
%   OUTPUT
%     ctd = a scalar structure with a column vector of matlab serial date 
%           numbers in its 'time' field
%
% DEPENDENCIES
%   Matlab R2018b
%   select_longest_monotonic_run_mask  (appended at code end)
%   discard_degeneracy                 (appended at code end)
%
% NOTES
%   If there are no ctd pressure data, then 
%            ctd.time = []; 
%   If there are problems with either the eng data or interpolation, then
%            ctd.time = nan(size(ctd.pressure));
%   Note that nan(size([])) returns [].
%
%   Data from 2 deployments were used in code development. In both, the
%   CTD data frequency was very close to 1 Hz. In one, the engineering
%   data frequency was 1 row of data every 5 seconds; in the other, 6
%   seconds. In both deployments there were many degenerate (repeat)
%   pressure values at the start and end of each ctd profile, as expected.
%
%   All of the engineering pressure records start with several values
%   of 0, during which time the timestamps are irregular, followed by
%   a monotonic (almost, but not all, of the time) pressure record. It
%   was also clear that during the ascent or descent part of the profile,
%   virtually all of the values in the engineering pressure record also
%   appeared in the ctd pressure record (within 0.01 dbar).
%
%   The ctd and engineering data records are synchronized by comparing
%   pressure records. The ctd pressure records are pruned by deleting
%   degenerate values (for example, pruning [1 2 2 3 2 4 5 6 6 5] gives
%   [1 3 4]) and isolating the monotonic part of the profile (just for
%   the purposes of synchronization). Then from the values in common
%   (intersection) the minimum and maximum values are selected. CTD
%   timestamps are obtained by interpolating the ctd data record row
%   numbers into the linear function determined by the times at the
%   two pressure extrema and their ctd row numbers. For ctd row numbers
%   outside of the domain of the pressure extrema timestamps are assigned
%   by linear extrapolation which is valid for normal CTD operation
%   (acquiring data at a constant rate).
%
%   This code should also work with other units of time, as long as they
%   are linearly 'interpolatable'. 
%
%   The file 'ctd_timestamps_diagnostics.txt' can be written out in append
%   mode (for processing all profiles in a deployment) to the matlab
%   working directory by uncommenting suitable blocks of code.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%=========================================================================

%----------------------
% CHECK INPUT ARGUMENTS
%----------------------
ctd.code_history(end+1) = {mfilename};

if isempty(ctd.pressure)
    disp(['Warning, add_ctd_timestamps.m: structure ctd(' ...
        num2str(ctd.profile_number) ') has no pressure data.']);
    ctd.time = [];
    ctd.data_status(end+1) = {'NO TIMESTAMPS ADDED'};
    return
elseif isempty(eng.pressure)
    disp(['Warning, add_ctd_timestamps.m: structure eng(' ...
        num2str(eng.profile_number) ') has no pressure data.']);
    ctd.time = nan(size(ctd.pressure));
    ctd.data_status(end+1) = {'NaN TIMESTAMPS ADDED'};
   return
elseif contains(eng.backtrack, 'yes')
    disp(['Warning, add_ctd_timestamps.m: engineering data for profile ' ...
        num2str(eng.profile_number) ' indicates backtrack.']);
    ctd.time = nan(size(ctd.pressure));
    ctd.data_status(end+1) = {'NaN TIMESTAMPS ADDED'};
    return
end
Pctd = ctd.pressure(:);
Peng = eng.pressure(:);
Teng = eng.time(:);

%------
% BEGIN
%------
%.. the true elements of both masks indicate the elements to keep.
mask_run = select_longest_monotonic_run_mask(Pctd); 
%.. the false elements of mask_dd correspond to the degenerate values
%.. values to be discarded.
[~, mask_dd] = discard_degeneracy(Pctd);
%.. keep a value only if:
%..    it is part of the run, AND,
%..    there are no duplicate values of it outside of the run.
Pctd_run = Pctd(mask_run & mask_dd);

%.. all that is necessary for processing the engineering pressure
%.. record is to, first, select non-zero values 
Peng_run = Peng(Peng~=0);
%.. and, next, to delete the first non-zero value because its 
%.. timestamp is very often out of sync.
if ~isempty(Peng_run)  % the isempty case will be trapped out later 
    Peng_run(1) = [];
end
%.. also get rid of degeneracies in case the code is run without
%.. strict backtrack rejection
Peng_run = discard_degeneracy(Peng_run);

%.. the ordering of values in the run variables is the same as for the
%.. original variables (so, large to small during an ascending profile).
%
%.. the output of intersect is always sorted, low to high
Pcommon = intersect(Pctd_run, Peng_run);  % empty if an input is empty
%.. trap out abbreviated profiles for which an automated interpolation
%.. can't be done.
npts_in_common = length(Pcommon);
if npts_in_common < 4
    %.. not enough points in common to trust the interpolation.
    %.. set ctd time record to empty set
    Tctd = [];

%     %********** BEGIN DIAGNOSTICS (I) *********************************
%     %.. set diagnostic values to nan
%     relrate = nan;
%     dP = nan;
%     dxC = nan;
%     Pmin = nan;
%     Pmax = nan;
%     dEtime = nan;
%     %********** END   DIAGNOSTICS (I) *********************************

else
    Pcommon(1) = [];  % empirically cleans up some instrument jitter cases

    %.. find the extrema of the common pressure values.
    Pmin = min(Pcommon);
    Pmax = max(Pcommon);
    %.. the length of the indices idx are guaranteed to be <=1 because Pcommon
    %.. was calculated as the intersection of Pctd_run and Peng_run after they
    %.. both had degeneracies removed.
    idx_ctd_min = find(Pctd==Pmin);
    idx_ctd_max = find(Pctd==Pmax);
    idx_eng_min = find(Peng==Pmin);
    idx_eng_max = find(Peng==Pmax);

    %.. synchronization of the pressure records establishes the linear
    %.. function into which interpolation of the ctd row indices will
    %.. give the ctd datetimestamps.
    Tctd = interp1([idx_ctd_min; idx_ctd_max],       ...
        [Teng(idx_eng_min); Teng(idx_eng_max)],      ...
        (1:length(Pctd))', 'linear', 'extrap');     %#ok

    %.. calculated ctd acquisition rate
    ctd.acquisition_rate_Hz_calculated = ...
        (length(Tctd) - 1) / (86400 * (Tctd(end) - Tctd(1)));

% % %********** BEGIN DIAGNOSTICS (II) ***********************************
% %     %.. diagnostics
% %     %
% %     %.. check relative data rates by ratioing the number of rows
% %     %.. between extrema; a ratio of 5.0 means that the data rate of
% %     %.. the ctd is 5 times faster than that of the engineering data.
% %     relrate = (idx_ctd_max - idx_ctd_min)/(idx_eng_max - idx_eng_min);
% %     %
% %     dP = Pmax - Pmin;
% %     %.. for a ctd operating at 1 hz, dxC and dEtime both should be a 
% %     %.. multiple of the relative rate (5 or 6).
% %     dxC = abs(idx_ctd_max - idx_ctd_min);
% %     dEtime = Teng(idx_eng_max) - Teng(idx_eng_min);
% % %********** END   DIAGNOSTICS (II) ***********************************

end

ctd.time = Tctd;
if isempty(ctd.time)
    ctd.time = nan(size(ctd.pressure));
    disp(['WARNING: ctd(' num2str(ctd.profile_number) '): ' ...
        'interpolation to find timestamps failed.']);
    ctd.data_status(end+1) = {'NaN TIMESTAMPS ADDED'};
else
    ctd.data_status(end+1) = {'timestamps added'};
end

% %********** BEGIN DIAGNOSTICS (III) **********************************
% 
% %.. write out diagnostics to a text file. 
% %.. append entries from each run of this code.
% 
% %.. this file will be written to the working directory
% workdir = pwd;
% name = mfilename;  % the filename of this code.
% diagnostics_filename = [workdir '\' name '_diagnostics.txt'];
% fid = fopen(diagnostics_filename, 'a');  % append
% fmt = ['\n#%5.5u: relrate = %8.4f;   ' ...
%        'd_idxC: %5.5u;  ' ...
%        'd_Etime: %6.1f;  ' ...
%        'common: %5.5u;   ' ...
%        'dP: %6.1f;   ' ...
%        'Pmin: %8.3f;   ' ...
%        'Pmax:  %8.3f'];
% fprintf(fid, fmt, ctd.profile_number, relrate, dxC, dEtime, ...
%         npts_in_common, dP, Pmin, Pmax);
% fclose(fid);
% 
% % %.. in development, I found 26 cases out of 1122 profiles:
% % if ~isnan(relrate) && (relrate ~= round(relrate))
% %     fprintf('%4.4u   %7.4f   %u\n', ...
% %         ctd.profile_number, relrate, dxC);
% % end
% %.. in all but one of these 26 cases, the relative rate was
% %.. between 5.0025 and 5.0028. In all cases there was 1 more
% %.. ctd data row betrween the common pressure extrema
% %.. than expected; the ctd data rate was very slightly
% %.. faster than 1 Hz IF the engineering timestamps are
% %.. 100% accurate. Seabird CTD clocking is very accurate,
% %.. so that it's possible that the profiler clock is
% %.. slightly slow.
% 
% %********** END   DIAGNOSTICS (III) **********************************

return

end
%--------------------------------------------------------------------
%--------------------------------------------------------------------
function [mask] = select_longest_monotonic_run_mask(vec)
% desiderio  2017-08-09
% desiderio  2019-03-31 improved logic to work with pathological cases
% 
% selects values for the longest monotonic run in the direction of
% predominant travel (that is, if the profiler is predominantly 
% descending so that the pressure values are increasing as a
% function of time, only monotonic runs of increasing pressure
% values are considered.)

%.. determine whether the predominant direction is to ascending
%.. or descending numeric values by first finding the indices of the
%.. minimum and maximum values.
[minn, idxmin] = min(vec);
[maxx, idxmax] = max(vec);
% 
%.. vectors that start out perfectly monotonic or nearly so will crash
%.. this code because the later variables in this code will be empty. 
%.. put some fluctuations at the beginning and end of the data record,
%.. and remove those points at the end of the calculation.
vctr(5:length(vec)+4) = vec;
vctr(1:4) = [minn maxx minn maxx];
vctr(end+1:end+4) = [minn maxx minn maxx];

%.. true if monotonic in the predominant direction, else false.
mask_tf = (sign(idxmax-idxmin) * diff(vctr)) > 0;
%.. runs of trues are sandwiched by falses so that the positions of
%.. the falses denote the length of the monotonic runs.
idx_false = find(mask_tf==0);
%.. npts will give the number of points in the longest run
%.. idx_max will give the start position of the longest run 
[npts, idx_max] = max(diff(idx_false));
%.. indices of the longest monotonic run in the predominant direction
%.. of travel are nominally:
%
%            range =  idx_false(idx_max)+1 : idx_false(idx_max)+npts;
%
%.. if a sequence starts on the last of consecutive identical 
%.. values or terminates on the first of consecutive identical
%.. values, make sure both of those pairs of values are also excluded
%.. by incrementing and decrementing the start and end indices
%.. respectively.

range = (idx_false(idx_max) + 2) : (idx_false(idx_max) + npts - 1);

%.. output mask; omit prepended and appended fluctuations 
mask = vec*0;
mask(range-4) = 1;

end
%--------------------------------------------------------------------
%--------------------------------------------------------------------
function [values, mask] = discard_degeneracy(vec)
% desiderio  2019-06-11 new version using higher level matlab functions
%
% if vec =   [1 3 3 5 6 7 2 6 9 3 9], then
%   mask =   [1 0 0 1 0 1 1 0 0 0 0]
%   values = [1     5   7 2        ] 
% 
% mask applied to the input vec must give an 'UNSORTED' (STABLE) result:
%   vec(mask) = values = [1 5 7 2]. 
% no values of 3, 6, or 9 are kept because each occur more than once.
%
% this function is different than the matlab function unique.m in that
% the unique result retains one copy of degenerate values: 
%     unique(vec, 'stable') = [1 3 5 6 7 2 9]. 
%
% degeneracies are identified by accumarray results ~= 1

[values, ~, ic] = unique(vec, 'stable');
degeneracy = accumarray(ic, 1);
mask_degeneracy = degeneracy~=1;
values(mask_degeneracy) = [];
mask = ismember(vec, values);

end
