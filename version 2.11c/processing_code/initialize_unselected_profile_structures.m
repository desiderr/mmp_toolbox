function [sss] = initialize_unselected_profile_structures(sss, profilesImported)
%=========================================================================
% DESCRIPTION
%   Initializes key fields of the elements of structure array sss that
%   were not initialized by 'import' code because only a subset of the
%   total number of profiles were selected to be processed.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: profilesImported == profiles that WERE selected to be processed
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% USAGE:  [sss] = initialize_unselected_profile_structures(sss, profilesImported, depID)
%
%   INPUT
%     sss              = an array of structures 
%     profilesImported = vector of profile numbers that *were* selected to be processed
%
%   OUTPUT
%     sss       = an array of structures
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   I want the structure fields to be established in the import functions
%   rather than in stand-alone initialization routines before import.
%
%   When not all the profiles of a deployment are selected to be processed
%   (for example, if only even numbered profiles are processed), then
%   after import the fields of structure array elements corresponding to
%   unselected profiles (eg, odd numbered profiles) will all have a value
%   of [] (0x0 empty set). For convenience and completeness this code
%   initializes key informational and procedural fields to useful
%   default values. In addition, if the fields of sss contain 2D arrays
%   the dimensionality of the empty set needs to be changed so that
%   downstream processing functions will work.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2020-02-04: desiderio: initial code
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%=========================================================================
profilesNotImported = setdiff(1:max(profilesImported), profilesImported);
sssNotImported = sss(profilesNotImported);

%.. .. informational
%.. data_status and code history
[sssNotImported.data_status]   = deal({'notSelectedToBeImported'});
[sssNotImported.code_history]  = deal({mfilename});
%.. profile number
C = num2cell(profilesNotImported);
[sssNotImported.profile_number] = C{:};

%.. .. procedural (used by downstream radMMP processing functions)
sssImported = sss(profilesImported);
%.. sensor field indices
sensor_field_indices = sssImported(1).sensor_field_indices;
[sssNotImported.sensor_field_indices] = deal(sensor_field_indices);
%.. initialize variables corresponding to sensor field indices;
%.. this is essential when the structure array being processed
%.. contains fields with 2D arrays.
allFieldNames = fieldnames(sssImported);
for ii = sensor_field_indices
    %.. for flexibility in concatenating structure array fields,
    %.. set the dimensionality of the empty sets:
    %.. .. for scalars           0x0
    %.. .. for column vectors    0x0 (not 0x1)
    %.. .. for 2D arrays mxn     0xn
    dim2 = size(sssImported(1).(allFieldNames{ii}), 2);
    if dim2 == 1, dim2 = 0; end
    emptyVariable = zeros(0, dim2);
    [sssNotImported.(allFieldNames{ii})] = deal(emptyVariable);
end

sss(profilesNotImported) = sssNotImported;
