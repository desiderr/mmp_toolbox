function struct_out = cat_sensorfields(array_of_structures, direction, prefix)
%=========================================================================
% DESCRIPTION
%   Concatenates the data found in designated fields of an array of structures
%   and writes these out to a new structure sss using fieldnames formed by
%   prepending a prefix to the original fieldnames.
%
% USAGE:  sss = cat_sensorfields(structArray, direction, prefix)
%
%   INPUT
%     structArray = an array of structures which MUST HAVE A FIELD NAMED AS
%                   sensor_field_indices, which designates which fields are
%                   to be processed.  
%     direction   = either 'vert' or 'horz'
%     prefix      = a character row vector to be prepended to all of the 
%                   fieldnames designated by sensor_field_indices. optional.
%
%   OUTPUT
%     sss  = a scalar structure of arrays whose fields are formed from the
%            concatenation of the fields designated by the sensor_field_indices
%            in the input structArray variable.
%
% DEPENDENCIES 
%   Matlab 2018b
%
% NOTES
%   This code is used on structure arrays with pre-defined field shapes, 
%   therefore THE FIELD ENTRIES' DIMENSIONS ARE NOT CHECKED BY THIS CODE. 
%   Obviously they must be compatible with the choice of concatenation
%   direction else an execution error will result.  
%
%   This code differs from write_field_arrays_to_new_structure.m in that the
%   latter was written to use nan padding to horzcat fields if the number of  
%   rows varied in the fields to be catted; such fields will cause an execution
%   error if cat_sensorfields.m is used.
%
%   For the case of catting fields of uniform shape [m x 3] from a
%   structure array of 400 elements (m is constant):
%
%      cat_sensorfields.m 'vert' gives an array sized at  [400m x 3]
%      cat_sensorfields.m 'horz' gives an array sized at  [m x 1200]
%      write_field_arrays_to_new_structure.m gives        [m x 400 x 3]
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
%.. 2020-02-05: desiderio: sensor_field_indices: deleted check for nans
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-04: desiderio: radMMP version 3.0 (OOI coastal and global)
%=========================================================================

if nargin==2
    prefix = '';
end

if strcmpi(direction, 'horz')
    direction = 2;
elseif strcmpi(direction, 'vert')
    direction = 1;
else
    error('second argument must be either ''horz'' or ''vert''.');
end

%.. get the sensor field indices without assuming that the value in the
%.. first element of the structure array is not empty.
tf_isempty = cellfun('isempty', ...
    {array_of_structures.sensor_field_indices});
xtruct = array_of_structures(~tf_isempty);
fields_to_process = xtruct(1).sensor_field_indices;
%.. need fieldnames in order to index into the fields of the input
%.. structure array
old_name = fieldnames(array_of_structures);
%.. the new fieldnames to be written out to struct_out
new_name = strcat(prefix, old_name);
%.. loop through each field
for ii = fields_to_process
    struct_out.(new_name{ii}) = ...
        cat(direction, array_of_structures.(old_name{ii}));
end
