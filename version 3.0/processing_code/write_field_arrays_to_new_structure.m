function struct_out = write_field_arrays_to_new_structure(array_of_structures, prefix, profiles)
%=========================================================================
% DESCRIPTION
%   Horizontally concatenates 2D arrays with the same number of columns found
%   in designated fields of a structure array by padding rows with NaNs when
%   necessary and writes these out to a new structure struct_out using fieldnames
%   formed by prepending a prefix to the original fieldnames.
%
% USAGE:  sss = write_field_arrays_to_new_structure(structArray, prefix, profiles) 
%
%   INPUT
%     structArray = an array of structures which MUST HAVE A FIELD NAMED AS
%                   sensor_field_indices, which designates which fields are
%                   to be processed.  
%     prefix      = a character row vector to be prepended to all of the 
%                   fieldnames designated by sensor_field_indices. OPTIONAL.
%                   Default: '' (empty character vector)
%     profiles    = a row vector designating which profiles are to be processed.
%                   if all profiles as denoted by the number of elements of 
%                   structArray are to be used either omit this argument or
%                   use Inf. OPTIONAL.
%                   Default: Inf
%   OUTPUT
%     sss  = a scalar structure of arrays whose fields are formed from the
%            concatenation of the fields designated by the sensor_field_indices
%            in the input structArray variable.
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   Each catted array is written into a field to struct_out. For an input field
%   whose elements all consist of column vectors the catted array will be 
%   dimensioned as [npoints-in-longest-profile x nprofiles] using nans as
%   padding as needed. For 2D array fields with n columns they will be 
%   dimensioned as [npoints-in-longest-profile x nprofiles x n].
%
%   For the case of an array of structures containing fields each consisting 
%   of 2D arrays with the same number of rows, cat_sensorfields.m (using 
%   'horz') and this code will give different results. If one of the fields
%   has arrays sized as [m x 4] and the structure array has 500 elements: 
%
%      write_field_arrays_to_new_structure.m gives a       [m x 500 x 4] array
%      cat_sensorfields.m ('horz') gives an array sized at [m x 2000]
%
%   The optional calling argument 'prefix' has been included so that if this
%   code is run multiple times to make multiple struct_out scalar structures,
%   these structures can then be combined into one overall structure without 
%   failing due to a redundancy in fieldnames.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-01-29: desiderio: improved documentation
%.. 2020-02-05: desiderio: sensor_field_indices: deleted check for nans
%.. 2020-02-08: desiderio: added calling argument profiles
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-04: desiderio: radMMP version 3.0 (OOI coastal and global)
%=========================================================================

%.. set defaults
if nargin==1
    prefix = '';
    profiles = Inf;
elseif nargin==2
    profiles = Inf;
end
%..
if isfinite(profiles)
    array_of_structures = array_of_structures(profiles);
end

%.. get the sensor field indices without assuming that the value in the
%.. first element of the structure array is not empty.
tf_isempty = cellfun('isempty', ...
    {array_of_structures.sensor_field_indices});
xtruct = array_of_structures(~tf_isempty);
rows_to_keep = xtruct(1).sensor_field_indices;
%.. convert the array of structures to a cell array
C = squeeze(struct2cell(array_of_structures));
%.. keep rows of C that contain sensor data
C = C(rows_to_keep, :);
%.. find the numbers of points in the elements of the 2D cell array C.
elementC_lengths = cellfun('size', C, 1);
%.. for each row of C, find the longest length of its elements
rowC_maxlengths = max(elementC_lengths, [], 2);  % column vector
%.. find the number of data points in the longest profile
npts_max = max(rowC_maxlengths);
%.. get the fieldnames of the input structure and delete those that
%.. will not be written to the output structure
names = fieldnames(array_of_structures);
names = names(rows_to_keep, :);
names = strcat(prefix, names);
%.. all the elements of C should now be either column vectors or [].
%.. pad each element to have the same length
[nrowC, ncolC] = size(C);
for ii=1:nrowC
    for jj=1:ncolC
        %.. specify both row and col indices to guarantee [] -> column vector
        %.. use ':' as the col index for 2D arrays (else autofill uses 0)
        C{ii, jj}(end+1:npts_max, :) = nan; 
    end
end
%.. convert each row of C to an array and write it to the output structure
%.. .. if elements of C are 1D column vectors so that ndim2 = 1, then for
%.. ..    arr = cell2mat(C(ii, :)) resulting in shapes of [m x n],  
%.. ..    permute(reshape(arr, [m 1 n]), [1 3 2]) leaves arr unchanged.
%..
%.. .. if elements of C are 2D arrays so that ndim2 = p, then
%.. ..    permute(reshape(arr, [m p n]), [1 3 2]) gives a [m x n x p] array.
ndim2 = cellfun('size', C(:, 1), 2);
for ii=1:nrowC
    %disp([ii size(cell2mat(C(ii, :)))])  % diagnostic
    %disp([npts_max ndim2(ii) ncolC])     % diagnostic
    struct_out.(names{ii}) = permute( ...
        reshape(cell2mat(C(ii, :)), [npts_max ndim2(ii) ncolC]), [1 3 2]);
end
