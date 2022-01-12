function [sss] = pressure_bin_mmp_data(sss, binmin, binsize, binmax)
%=========================================================================
% DESCRIPTION
%   Pressure-bins mmp profile data.
%
% USAGE:  [sss] = pressure_bin_mmp_data(sss, binmin, binsize, binmax)
%
%   INPUT 
%     sss     = a scalar structure of profile data containing the fields:
%               'pressure'            : (hard-coded to bin on pressure)
%               'sensor_field_indices': specifies which fields to bin;
%               the data fields specified by 'sensor_field_indices'
%     binmin  = minimum (centered) bin value
%     binsize = bin width
%     binmax  = maximum (centered) bin value 
%
%   OUTPUT 
%     sss  = a scalar structure with pressure-binned values written into the
%            fields specified by 'sensor_field_indices' (overwriting the 
%            substrate profile data).
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   It is expected that bad data values have been replaced by nans in the
%   sensor fields to be binned. After binning, the structure's data field 
%   values specified by 'sensor_field_indices' are replaced with binned data.
%
%   The binning algorithm uses accumarray which in this application 
%   requires that the first calling argument is a COLUMN VECTOR of
%   positive integers. This argument is prepared by processing the
%   pressure record with the matlab function discretize.
%
%   Accumarray is used to 
%      (1) accumulate bin counts.
%      (2) accumulate bin sums.
%   It is ~ 300 times faster to make 2 accumarray calls as above than
%   to make one accumarray call using '@mean' (R2016a).
%
%   For data fields that are 2D arrays each column is separately binned.
%
%   The python numpy counterpart to accumarray is bincount. 
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-04: desiderio: radMMP version 3.00 (OOI coastal and global)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%.. 2021-05-10: desiderio: radMMP version 2.20c (OOI coastal)
%.. 2021-05-14: desiderio: radMMP version 3.10 (OOI coastal and global)
%.. 2021-05-24: desiderio: radMMP version 4.0
%=========================================================================

sss.code_history(end+1) = {mfilename};

%.. write out binning parameters to the structure
sss.binning_parameters = [binmin binsize binmax];
sss.pressure_bin_values = (binmin:binsize:binmax)';
%.. useful variables
nbin  = numel(sss.pressure_bin_values);
names = fieldnames(sss);

if isempty(sss.pressure)
    %.. keep a one-to-one correspondence between binned structures
    %.. and the indexing of the profiles-to-be-processed by filling
    %.. in the sensor fields with nans so that the field-nan'd structure
    %.. is 'padding'.
    %
    %.. 1D data fields have been initialized to empty set sized as [0 0]
    %.. 2D data fields have been initialized to empty set sized as [0 ncol]
    [~, ndim2] = structfun(@size, sss);
    ndim2(ndim2==0) = 1;
    for jj = sss.sensor_field_indices
        sss.(names{jj}) = nan(nbin, ndim2(jj));
    end
    sss.data_status(end+1) = {'BINNED ENTRIES SET TO NaN'};
return
end

%.. use discretize to assign bin numbers to the pressure values.
%.. .. set up the bin edges;
%.. .. add an extra bin at the end for cases where there are no pressure
%.. .. data in the user specified binmax. the extra bin will be later 
%.. .. deleted and its use will avoid array size mismatches.
edges = (binmin - binsize/2) : binsize : (binmax + binsize + binsize/2);
pr = sss.pressure;
%.. .. add an extra point to the pressure data to set the existence of a
%.. .. bin index into the appended bin when discretize is used.
pr(end+1) = binmax + binsize;
pr = discretize(pr, edges);

for jj = sss.sensor_field_indices
    data = sss.(names{jj});     % can be either a column vector or 2D array
    %.. add dummy point at the end (bottom) of the (possibly 2D) data record
    %.. to match the added pressure point
    data(end+1, :) = nan;  %#ok
    %.. in the general case there could be a different placement of nans in
    %.. the records. create a mask with elements that are true if neither
    %.. the pressure bin indices nor the corresponding column elements in
    %.. the data are NaN.
    mask = ~isnan(pr+data);  % if data is 2D, pr is broadcasted to 2D
    %.. but keep the last points, which set the desired binned+1 endpoint
    mask(end, :) = true;

    %.. iterate over the number of columns of data for this structure field
    ncol = size(data, 2); 
    %.. pre-allocate the structure field array 
    sss.(names{jj}) = nan(nbin, ncol);
    for ii = 1:ncol
        %.. count how many values are in each bin
        bincounts = accumarray(pr(mask(:, ii)), 1);
        %.. determine the sums in each bin
        binsums   = accumarray(pr(mask(:, ii)), data(mask(:, ii), ii));
        %.. before calculating bin means, set empty bins to nan
        bincounts(bincounts==0) = nan;
        binned_means = binsums ./ bincounts;
        %.. delete the artificial endpoint that was used to set bin limit
        binned_means(end) = [];
        sss.(names{jj})(:, ii) = binned_means;  % should be no mismatch here
    end
end
sss.data_status(end+1) = {'binned'};

end

