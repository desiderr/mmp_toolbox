function vec = assign_profilenumbers_to_indices(array_of_structures, fieldname)
%=========================================================================
% DESCRIPTION
%   Assigns profile numbers to a deployment's worth of data when the latter
%   are vertically concatenated into column vectors.
%
% USAGE:  [vec] = assign_profilenumbers_to_indices(structArray, 'pressure')
%
%   INPUT 
%     structArray = a structure array whose fields include 'profile_number'
%                   and (in this case) fieldname = 'pressure'
%     fieldname   = a fieldname of the structure array whose values are
%                   shaped as column vectors
%  
%   OUTPUT
%     vec = a column vector whose values denote the profile numbers associated
%           with each element in a column vector of values vertically
%           concatenated from the fieldname of structArray.
%           
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   example:
%     sss is a 4 element structure array with a field named 'pressure' such
%     that the lengths of the 4 pressure fields, which are all column vectors,
%     are 5, 2, 3, and 1 respectively. in addition, the 4 sss.profile_number
%     fields (each is a scalar) happen to be 9, 15, 26, and 111, respectively:
%
%     vec = assign_profilenumbers_to_indices(sss, 'pressure')
%  
%     vec = [9; 9; 9; 9; 9; 15; 15; 26; 26; 26; 111]
%
% REFERENCES
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-04: desiderio: radMMP version 3.0 (OOI coastal and global)
%=========================================================================

%.. find field index of the fieldname record.
idx_fieldname = find(strcmpi(fieldnames(array_of_structures), fieldname));
if isempty(idx_fieldname)
    error(['Could not find ' fieldname ' field in input structure.']);
end

%.. find the lengths of all the fieldname fields.
all_field_lengths = cellfun('length', ...
    squeeze(struct2cell(array_of_structures)));
fieldname_lengths = all_field_lengths(idx_fieldname, :);

%.. find which profiles were processed
profiles_processed = [array_of_structures.profile_number];

%.. make sure these last two variables are compatible
if length(fieldname_lengths) ~= length(profiles_processed)
    error('Unexpected(!!!) mismatch in field lengths.');
end

n_struct = length(profiles_processed);
v{n_struct, 1} = [];  % pre-allocate using a column vector
for ii = 1:n_struct
    v{ii} = profiles_processed(ii) + zeros(fieldname_lengths(ii), 1);
end

vec = cat(1, v{:});
