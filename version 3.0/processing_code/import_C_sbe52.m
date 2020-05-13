function [ctd] = import_C_sbe52(filename)
%=========================================================================
% DESCRIPTION
%   Imports CTD data into a matlab data structure from an ascii 'C' file
%   unpacked from a binary file acquired from a SBE52 ctd mounted on a 
%   McLane Profiler.  
%
% USAGE:  ctd = import_C_sbe52(filename)
%
%   INPUT
%     filename = an ASCII text 'C' file created from the profiler raw binary
%                data by using the McLane unpacker software v3.10 or v3.12. 
%                the internal structure of the file can be any one of 4
%                possible formats, set by the 2 binary unpacker switches.
%
%                See Notes.
%
%   OUTPUT
%     ctd = a scalar data structure. for structure fieldnames and documentation
%           go to the initialization section in this code. fields containing
%           sensor data will be column vectors. this routine is meant to be 
%           called once for each profile in a deployment so that the imported
%           data will be contained in an array of structures, with the index of
%           each element of the structure denoting the profile number. profile
%           number 0 is not processed.
%
% DEPENDENCIES
%   Matlab R2018b
%
% NOTES
%   For McLane profiler version (5.00) using Unpacker V3.12 there are 2 export
%   choices for unpacking that can result in 'C' files with 4 different 
%   internal structures. The choices are:
%     (a) data delimiters: comma separated or space padded columns
%     (b) whether or not to include: header and on and off date\time text rows.
%   This code will work with any of the 4 formats.
%
%   The ctd structure is also initialized with empty fields which will
%   be populated in later processing steps. Matlab is finicky concerning
%   assignment statements involving array structure elements that don't
%   have identical fields.
%
%   Coastal and global OOI profilers both use SBE52 CTDs, therefore this
%   code is used to import both coastal and global ctd data because the
%   unpacked file formats are the same. The only difference is that the  
%   last column of data contains SBE43F oxygen values for coastal profilers
%   and values of 0 for global profilers which use an Aanderaa oxygen optode
%   with its data appearing in the Engineering data stream.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-04: desiderio: radMMP version 3.0 (OOI coastal and global)
%=========================================================================

%----------------------
% PRELIMINARY SET-UP
%----------------------
clear Z  % make sure this cell array is cleared

number_of_hardcoded_data_columns = 4;

%.. initialize structure before checking input to make sure that when
%.. this code is used inside of a for loop to process all the profiles
%.. of a deployment, all of the elements of the structure array (one
%.. for each profile) have the same set of field names, including those
%.. with no data, to avoid dissimilar structure assignment exceptions.

%.. A structure's fields can be accessed by numerically indexing into
%.. the fieldnames. The fieldname indices are determined by the order
%.. of field creation, set as follows.  

ctd.deployment_ID        = '';
ctd.profile_number       = [];  % scalar
ctd.profile_direction    = '';
ctd.data_status        = {''};  % 'imported' or 'no data' or 'no datafile'
ctd.code_history = {mfilename}; % the name of this program
ctd.header               = '';  % populated if Unpacker header option is enabled
ctd.time                 = [];  % to be determined later in processing 
ctd.pressure             = [];  % [dbar]  
ctd.temperature          = [];  % [Celsius]
ctd.conductivity         = [];  % [mmho/cm]
ctd.salinity             = [];  % to be calculated later in processing
ctd.theta                = [];  % to be calculated later in processing
ctd.sigma_theta          = [];  % to be calculated later in processing
ctd.oxygen               = [];  % [Hz]; SBE43F oxygen frequency
ctd.dpdt                 = [];  % to be calculated later in processing
ctd.profile_mask         = [];  % true values denote good data
ctd.sensor_field_indices = (7:15); % these fields will be binned on pressure
ctd.pressure_bin_values  = [];  % later
ctd.binning_parameters   = [];  % later: [pr_min binsize pr_max]
ctd.acquisition_rate_Hz_calculated = nan;  % to be calculated later
ctd.on                   = '';  % populated if Unpacker header option is enabled
ctd.off                  = '';  % populated if Unpacker header option is enabled

%----------------------
% CHECK INPUT ARGUMENTS
%----------------------
%.. sometimes the functions disp and fprintf, and particularly labels
%.. in figures, don't work well with backslashes, so change them to
%.. forward slashes which works fine in windows paths.
filename = strrep(filename, '\', '/');

check_infile = exist(filename, 'file');
if check_infile ~=2
    disp(['WARNING: Could not find file ', filename]);
    ctd.data_status = {'no datafile'};
    %.. parse filename for profile number
    [~, name, ~] = fileparts(filename);
    ctd.profile_number = str2double(name(end-6:end));
    return
end

%------
% BEGIN
%------

%.. read in entire file as a cell whose lone element is 
%.. a cell array (column vector) of character vectors.
%.. each character vector represents a row of the input file. 
fid = fopen(filename, 'rt');
Z = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
fclose(fid);
Z=Z{1};
%.. Z is now a cell column vector of character vectors.
%.. trim leading and trailing whitespace from all rows. 
Z = strtrim(Z);
%.. DELETE blank rows
Z(cellfun('isempty', Z)) = [];
%.. determine whether there are non-data rows.
%..   if so, normal McLane-unpacked SBE52 files will have two 'Profile'
%..   rows, one in front and one in back of the data; the second will
%..   not be present if an exception is encountered.
mask_profilerows = strncmpi(Z, 'Profile', 7);
n_profilerows = sum(mask_profilerows);
if n_profilerows > 0  % there are rows of text that are not data
    %.. read profile number
    profilerows = Z(mask_profilerows);
    ctd.profile_number = sscanf(profilerows{1}(8:end), '%u');
    Z(mask_profilerows) = [];  % delete profilerows from the data
    %.. the first row is now the header (all blank lines were deleted)
    ctd.header = Z{1};
    Z(1) = [];  % delete the header
    %.. for these datafiles, IF an exception is encountered, 
    %.. the on/off date-time text rows will be missing.
    mask_exception = strncmpi(Z, 'Exception', 9);  % logical column vector
    if any(mask_exception)
        idx = find(mask_exception);
        idx = idx(1);  % in case there's more than one (not likely)
        ctd.on  = Z{idx};  % write the exception message
        ctd.off = Z{idx};
        Z(idx:end) = [];  % delete everything after first exception
    else
        ctd.on = Z{end-1};
        ctd.off = Z{end};
        Z(end-1:end) = [];  % delete them
    end
else  % no header, footer, no 'Exception Encountered' rows
    %.. because Z only contains data lines, 
    %.. try to get profile number from filename.
    [~, name, ~] = fileparts(filename);
    %.. the unpacker can add a prefix, not a suffix, so the last
    %.. 7 characters of the filename should be conserved.
    %.. if this fails, the result should be an entry of NaN.
    ctd.profile_number = str2double(name(end-6:end));

    %.. a non-standard case to parse: 
    %..    there are some TXT files which have been unpacked and then
    %..    separately edited to have just one header row of column
    %..    labels. this will cause the sscanf statement to throw an
    %..    an error. parse for any such occurrences and fix. 
    mask = ~cellfun('isempty', regexp(Z, '[a-zA-Z]'));
    Z(mask) = [];  % delete if present
end
%.. at this stage, there are only data rows.
%.. convert comma delimited data to space-padded.
%.. if Z is already space-padded, nothing changes.
Z = strrep(Z, ',', ' ');
%.. convert Z to the character array cc
cc = char(Z);

%.. trap out if no data at all found
if isempty(cc)
    disp(['WARNING: No data found in ' filename]);
    ctd.data_status = {'no data'};
    return
end

%.. append a delimiter to the end of each row
cc(:, end+1) = ' ';

%.. figure out the number of columns of data.
%..    for CE09OSPM, there should always be 4, even if there wasn't
%..    an oxygen sensor; the MMP manual states that in this case the
%..    4th column would be filled with values of 0.
%.. make a generalized read of the first row. 
[~, ncol] = sscanf(cc(1,:), '%f');
%.. check
if ncol~=number_of_hardcoded_data_columns
    str = num2str(number_of_hardcoded_data_columns);
    error(['This code expects files with ' str 'data columns.']);
end

%.. now all the data can be simply read in.
%.. sscanf scans down columns, so transpose cc before scanning
%.. (may need a try-catch here)
[data, nvalues, errmsg] = sscanf(cc', '%f', [ncol Inf]);
%.. now that the diagnostics have been recovered, transpose back.
data = data';

%.. sscanf error checking
if ~isempty(errmsg)
    fprintf('\nWARNING!\n');
    fprintf('     sscanf operating on %s\n', filename)
    fprintf('     threw the following error message:\n\n');
    fprintf('     %s\n\n', errmsg);
end

if rem(nvalues, ncol) ~= 0
    fprintf('\nWARNING!\n');
    fprintf('     sscanf operating on %s\n', filename)
    fprintf('     read in a partial data line.\n\n');
    fprintf('     Deleted last row of data.\n\n');
    %.. I've seen partial rows for AQD data; they were always the
    %.. last row.
    data(end, :) = [];
end

%.. populate structure fields
ctd.conductivity = data(:,1);  % [mmho/cm]
ctd.temperature  = data(:,2);  % [Celsius]
ctd.pressure     = data(:,3);  % [dbar]
ctd.oxygen       = data(:,4);  % [Hz]
ctd.data_status  = {'imported'};
ctd.profile_mask = logical(ctd.pressure);

return
%--------------------------------------------------------------------
