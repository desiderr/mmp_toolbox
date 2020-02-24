function meta = import_metadata(metadata_filename)
%=========================================================================
% DESCRIPTION
%    Imports: (a) location of McLane profiler rawdata and calibration files
%             (b) instrument and deployment information
%    Creates: the structure variable 'meta' which contains this information
%             in an accessible format for retrieval by the processing code.
%
% USAGE:     meta = import_metadata('ce09ospm_00008_metadata.txt');
%
%   Run this code from the working directory or a directory in the
%   Matlab path.
%
%   INPUT
%     'metadata_filename' is a formatted text file. See Notes. 
%
%   OUTPUT
%     When processing deployment data using the radMMP code suite, the 
%     output variable must be named 'meta'.
%
% DEPENDENCIES
%   Matlab R2018b
%
% NOTES
%    Reads in metadata contained in a text file named in the calling
%    argument which must be located in either the matlab path or working
%    directory. Rows starting with % are comment lines and may be output to
%    the screen if that section in this program is uncommented; information
%    in the comment lines is not conveyed to the profiler processing. All
%    other (non-empty) rows must contain one and only one equal sign.
%
%    Foldernames and filenames can either be entered with or without
%    quotes but space(s) cannot be part of the names. If there is no
%    calfile, that row can be terminated by a pair of single quotes after
%    the equal sign. 
%
%    Numerical values: Numeric values (neither NaNs nor []) must be 
%    entered with one exception noted below. The null entry for the values
%    for filter time constants and shifts is 0.
%
%    profiles_to_process: Entries for profiles_to_process can be a scalar
%    or any matlab row vector expression. An entry of empty set [] denotes
%    that profile numbers from 1 to the number_of_profiles value will be
%    processed.
%
%    Entry examples:
%
%    % rows starting with % are ignored
%    unpacked_binary_data_folder = 'D:\temp'
%    oxygen_calfilename = ''
%    number_of_profiles = 1023
%    profiles_to_process = [0:9 500:509 1000:1009]
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%=========================================================================
if nargin ==0
    filename = 'metadata.txt';  % default filename
else
    filename = metadata_filename;
end

clear Z  % make sure this cell is cleared
clear meta
fid = fopen(filename);
if fid<0
    disp(' ');
    disp(['The file named ' filename ' was not found.']);
    disp(['It must be located in either the Matlab path or current ' ...
        'working directory.']); 
    disp('The current working directory is:');
    disp(pwd);
    disp(' ');
    return
end
Z = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
fclose(fid);
Z=Z{1};  % 'unwrap' cell array

%.. find comment lines
idx = find(strncmpi(Z, '%', 1));

% %.. print the comment lines out to the screen
% fprintf('\n');
% idx = idx(:)';  % make sure idx is a row vector
% for ii=idx
%     disp(Z{ii});
% end

Z(idx) = [];                    %#ok delete these rows from Z
Z = strtrim(Z);                 % delete leading and trailing whitespace
Z(cellfun('isempty', Z)) = [];  % delete empty cells

if any(~contains(Z, '='))
    disp(' ');
    disp('Incompatible entry in the metadata.txt file:');
    disp('***ALL NON-COMMENT LINES MUST CONTAIN ONE EQUAL SIGN***');
    error('WFP processing terminated.');
end

%.. make a copy of the profiles_to_process row for special processing;
%.. it won't survive the ersatz entry processing intact
prof2proc = Z(strncmpi(Z, 'profiles_to_process', 19));
%.. however, reserve its field placement in the structure output
%.. with a placeholder; this will be overwritten in last section
Z(strncmpi(Z, 'profiles_to_process', 19)) = {'profiles_to_process=[-99]'};

%.. process Z to make it more robust to ersatz entries
Z = strrep(Z, '''', '');  % remove single quotes if present
%.. remove spaces from all entries except for 
tf = contains(Z, 'binning_parameters');
Z(~tf) = strrep(Z(~tf), ' ', '');

%.. figure out which rows contain text information,
%.. so that they can be turned into executable statements.
%
%.. folders
tf_folder   = contains(Z, 'folder');
%.. .. insert a single quote after '='
Z(tf_folder) = strrep(Z(tf_folder), '=', '=''');
%.. .. append a forwardslash and single quote
Z(tf_folder) = strcat(Z(tf_folder), '\''');
%.. .. in case termination was already a '\':
Z = strrep(Z, '\\', '\');
%
%.. filenames
tf_filename = contains(Z, 'filename');
Z(tf_filename) = strrep(Z(tf_filename), '=', '=''');  % , to ,'
Z(tf_filename) = strcat(Z(tf_filename), '''');  % append '
%
%.. deployment_ID
tf_depID = contains(Z, 'deployment_ID');
Z(tf_depID) = strrep(Z(tf_depID), '=', '=''');  % , to ,'
Z(tf_depID) = strcat(Z(tf_depID), '''');  % append '

%.. import variables into the fields of the workspace structure meta ...
Z = strcat('meta.', Z);
Z = strcat(Z, ';');  % (to suppress screen output)
Z = strrep(Z, '=;', '=0;');  % if no entry
%.. and evaluating the expressions
for ii = 1:length(Z)
    %disp(Z{ii});  % diagnostics
    eval(Z{ii});
end

%.. parse profiles_to_process row and overwrite placeholder
if isempty(prof2proc)  % if this entry was missing, do all profiles
    meta.profiles_to_process = 1:meta.number_of_profiles;  %#ok
else
    %.. remove extra spaces if present (more robust)
    prof2proc = regexprep(prof2proc, 'process[ ]*,' , 'process =');
    prof2proc = strcat('meta.', prof2proc);
    if strcmpi(prof2proc{1}(end), '=')  % do all if no value entered
        prof2proc = strrep(prof2proc, '=', '=[]');
    end
    prof2proc = strcat(prof2proc, ';');
    eval(prof2proc{1});
end
if isempty(meta.profiles_to_process)  % from strrep '=[]' expression above
    meta.profiles_to_process = 1:meta.number_of_profiles;
end
%.. delete out-of-range profile numbers if present
tf_outOfRange = meta.profiles_to_process > meta.number_of_profiles ...
                                         |                         ...
                meta.profiles_to_process <= 0;
if any(tf_outOfRange)
    disp('Warning: out-of-range profile number(s) deleted:');
    disp(meta.profiles_to_process(tf_outOfRange));
    meta.profiles_to_process(tf_outOfRange) = [];
end
if isempty(meta.profiles_to_process)
    error('No profiles to process.')
end

clear ans fid filename idx ii tf_folder tf_filename Z
