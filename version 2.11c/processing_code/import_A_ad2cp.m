
function [aqd] = import_A_ad2cp(filename)
%=========================================================================
% DESCRIPTION:
%    Imports Nortek AD2CP data from unpacked McLane profiler 'A' files.
%
% USAGE:  aqd = import_A_ad2cp(filename)
%
%   INPUT
%     filename = an ASCII text 'A' file created from the profiler raw binary
%                data by using the McLane unpacker software v3.10 or v3.12.
%                the internal structure of the file can be any one of 4
%                possible formats, set by the 2 binary unpacker switches.
%
%                See Notes.
%
%   OUTPUT  
%     aqd = a scalar data structure. the imported data will be placed into a
%           field named 'imported_data' as a 2D array so that the 'aqd_deal_'
%           subroutines can determine whether the data represents a complete
%           (full) dataset or a decimated dataset and deal the variable values
%           to the appropriately named fields (as in the initialization section
%           of the code below).
%
%           this routine is meant to be called once for each profile in a 
%           deployment so that the imported data will be contained in an array
%           of structures, with the index of each element of the structure
%           denoting the profile number. profile number 0 is not processed.
%
% DEPENDENCIES
%   Matlab R2018b
%
% NOTES
%   For McLane profiler version (5.00) using Unpacker V3.12 there are 2 export
%   choices for unpacking that can result in 'A' files with 4 different 
%   internal structures. The choices are:
%     (a) data delimiters: comma separated or space padded columns
%     (b) whether or not to include: header and on and off date\time text rows.
%   This code will work with any of the 4 formats.
%
%   The 'beam' parameter maps the instrument's beam transducer # to the
%   [velocity, for example] data field # in the instrument data output.
%   The standard settings as of July 2019 are:
%      For descending profiles, beam = [2 3 4 0 0].
%      For  ascending profiles, beam = [1 2 4 0 0].
%      For stationary  msrmnts, beam = [1 2 3 4 0].
%   However, for some deployments the beam mapping for ascending and descending
%   profiles were switched; in addition, there is evidence that it would be
%   advantageous to always use beam 1 and never use beam 3, which may at some
%   point be implemented.
%
%   AQDII instruments mounted on (OOI) McLane profilers do not have
%   a 5th transducer, so that 5 beams can never be used and
%   therefore beam(5) will always be 0.
%
%   All (OOI) McLane data consist of profiles so that only 3 beams
%   at a time will ever be used, therefore beam(4) should always be 0.
%   Each unpacked data record of velocity, amplitude, and correlation 
%   will therefore be a 2D array with 3 columns.
%
%      Example: unpacked velocities for beam = [1 2 4 0 0]:
%         velocity(:,1) are the beam velocities for beam1
%         velocity(:,2) are the beam velocities for beam2
%         velocity(:,3) are the beam velocities for beam4 (not beam3)
%
%      * For a given profile all entries for the beam parameter will
%        either be [2 3 4 0 0] or [1 2 4 0 0] as detailed above. If so,
%        then only one row vector will be written out, either [2 3 4]
%        or [1 2 4] respectively.
%
%*************************************************************************
%*************************************************************************
%  McLane Unpacker versions V3.12 and earlier output bogus values for 
%  magnetometer readings. These values are actually the accelerometer 
%  values. Until this is corrected, this code suite will output magnetometer
%  values as NaNs.
%*************************************************************************
%*************************************************************************
%
% REFERENCES
%   "System Integrator's Guide AD2CP" version 2013-02-15. Nortek.
%       This version comes the closest to descibing the functionality
%       of the AD2CP instruments deployed on OOI McLane Profilers.
%       According to Nortek, more recent versions do NOT apply to
%       our instruments (verified for the September 2016 version of
%       the AD2CP Integrator's Guide).
%
%   "Profiler Integrated Sensors & Communications Interface User Manual".
%   version 17.G.25. 2017. McLane Research Laboratories, Inc.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-04: desiderio: 
%..             initialized sensor_field_indices field to the field 
%..             numbers of 2D array variables so that the new function
%..             initialize_unselected_profile_structures will initialize
%..             these variables in unselected profiles (which have not
%..             been imported and so are by default initialized to []
%..             which is dimensioned as 0x0) to the correct empty set
%..             dimensionality for ease of concatenation.
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%=========================================================================

%----------------------
% PRELIMINARY SET-UP
%----------------------
clear C  % make sure this cell array is cleared

%.. initialize all structure field names at the time of structure array
%.. creation to avoid "Subscripted assignment between dissimilar 
%.. structures" exceptions. 

%.. A structure's fields can be accessed by numerically indexing into
%.. the fieldnames. The fieldname indices are determined by the order
%.. of field creation.  

%.. for all-profiles data products, signal the 2nd dimension of data
%.. arrays for profiles with no data by the dimensionality of the empty
%.. set (enables a 2D array of nans to be written out):
%   zeros(0, 1)   has dimensions [0, 1] (for column vectors of data)
%   zeros(0, 3)   has dimensions [0, 3] (for 2D arrays with 3 columns)
%   zeros(0, 4)   has dimensions [0, 4] (for 2D arrays with 4 columns)

aqd.deployment_ID     = '';
aqd.profile_number    = [];    % scalar
aqd.profile_direction = '';  
aqd.data_status       = {''};  % cell can contain multiple status reports
aqd.code_history      = {mfilename};
aqd.header            = '';
aqd.imported_data     = [];
aqd.time              = [];
aqd.pressure          = [];  % from ctd
aqd.dpdt              = [];  % uses ctd pressure
aqd.soundspeed        = [];
aqd.aqd_temperature   = [];  % aqd sensor
aqd.aqd_pressure      = [];  % aqd sensor
aqd.heading           = [];
aqd.pitch             = [];
aqd.roll              = [];
aqd.magnetometer      = zeros(0, 3);
aqd.nbeams            = [];
aqd.ncells            = [];
aqd.beam_mapping      = [];
aqd.velBeam           = zeros(0, 4);
aqd.amplitude         = zeros(0, 4);
aqd.correlation       = zeros(0, 4);
aqd.velXYZ            = zeros(0, 3);
aqd.velENU            = zeros(0, 3);
aqd.magnetic_declination = [];
aqd.correct_velBeam_for_phase_ambiguity = 1;  % overridden by meta value
aqd.correct_velY_for_wag                = 0;  % overridden by meta value
aqd.correct_velXYZ_for_pitch_and_roll   = 0;  % overridden by meta value
aqd.correct_velU_for_dpdt               = 0;  % overridden by meta value
aqd.ambiguity_velocity   = 999;
aqd.ambiguous_points     = [];  % [time uncorrected_value]
aqd.wag_radius           = [];
aqd.wag_signal           = [];  % subtract this data to correct for wag
aqd.profile_mask         = [];  % true values denote good section(s)
aqd.sensor_field_indices = [17 21:25];  % only 2D array variables at start 
aqd.pressure_bin_values  = [];
aqd.binning_parameters   = [];  % [pr_min binsize pr_max]
aqd.acquisition_rate_Hz_calculated = nan;  % derived scalar quantity
aqd.depth_offset_m       = 0;
aqd.on                   = '';
aqd.off                  = '';

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
    aqd.data_status = {'no datafile'};
    %.. parse filename for profile number;
    %.. these could either be *.DEC.TXT or *.TXT files, 
    %.. so use fileparts twice
    [~, name, ~] = fileparts(filename);
    [~, name, ~] = fileparts(name);
    aqd.profile_number = str2double(name(end-6:end));
    return
end

%------
% BEGIN
%------

%.. read in entire file as a cell whose lone element is 
%.. a cell array (column vector) of character vectors.
%.. each character vector represents a row of the input file. 
fid = fopen(filename, 'rt');
C = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
fclose(fid);
C=C{1};
%.. C is now a cell column vector of character vectors.
%.. trim leading and trailing whitespace from all rows. 
C = strtrim(C);
%.. DELETE blank rows
C(cellfun('isempty', C)) = [];
%.. determine whether there are non-data rows.
%..   if so, normal McLane-unpacked AQDII files will have two 'Profile'
%..   rows, one in front and one in back of the data; the second will
%..   not be present if an exception is encountered.
mask_profilerows = strncmpi(C, 'Profile', 7);
n_profilerows = sum(mask_profilerows);
if n_profilerows > 0  % there are rows of text that are not data
    %.. read profile number
    profilerows = C(mask_profilerows);
    aqd.profile_number = sscanf(profilerows{1}(8:end), '%u');
    C(mask_profilerows) = [];  % delete profilerows from the data
    %.. under normal circumstances, the first row is now the header
    %.. (all blank lines were deleted); however, there are cases where
    %.. the entire file consists of only the last 3 footer lines;
    %.. discriminate against this case
    if ~strcmpi(C{1}(1:10), 'MM-DD-YYYY')  % not a header line
        aqd.on = C{end-1};
        aqd.off = C{end};
        disp(['WARNING: No data found in ' filename]);
        aqd.data_status = {'no data'};
        return
    end
    %.. the first row is now the header (all blank lines were deleted)
    aqd.header = C{1};
    C(1) = [];  % delete the header
    %.. for these datafiles, IF an exception is encountered, 
    %.. the on/off date-time text rows will be missing.
    mask_exception = strncmpi(C, 'Exception', 9);  % logical column vector
    if any(mask_exception)
        idx = find(mask_exception);
        idx = idx(1);  % in case there's more than one (not likely)
        aqd.on  = C{idx};  % write the exception message
        aqd.off = C{idx};
        C(idx:end) = [];  % delete everything after first exception
    else
        aqd.on = C{end-1};
        aqd.off = C{end};
        C(end-1:end) = [];  % delete them
    end
else  % no header, footer, no 'Exception Encountered' rows
    %.. because C only contains data lines, 
    %.. try to get profile number from filename.
    [~, name, ~] = fileparts(filename);
    %.. because the AD2CP files can be names as either *.DEC.TXT or *.TXT:
    [~, name, ~] = fileparts(name);
    %.. the unpacker can add a prefix, not a suffix, so the last
    %.. 7 characters of the filename should be conserved.
    %.. if this fails, the result should be an entry of NaN.
    aqd.profile_number = str2double(name(end-6:end));

    %.. a non-standard case to parse: 
    %..    there are some TXT files which have been unpacked and then
    %..    separately edited to have just one header row of column
    %..    labels. this will cause the sscanf statement to throw an
    %..    an error. parse for any such occurrences and fix. 
    mask = ~cellfun('isempty', regexp(C, '[a-zA-Z]'));
    C(mask) = [];  % delete if present
end
%.. at this stage there are only data rows.
%
%.. convert comma delimited data to space-padded.
%.. if C is already space-padded, nothing changes.
C = strrep(C, ',', ' ');
%.. turn into a character array for fast parsing
cc = char(C);

%.. trap out if no data at all found
%.. also check C for last row cc deletion, after conditional block
if isempty(cc) || length(C) < 2 
    disp(['WARNING: No data found in ' filename]);
    aqd.data_status = {'no data'};
    return
end

%.. sometimes the last data row is complete but contains consecutive fill
%.. values of '000'; delete all last rows.
cc(end, :) = [];

%.. copy spaces into delimiter columns in the date time fields;
%.. expected formats: 
%.. .. full dataset: MM-DD-YYYY hh:mm:ss.fff
%.. .. decimated   : MM-DD-YYYY hh:mm:ss
%.. .. there should already be a delimiter after 'fff' or 'ss'
%.. also add a delimiter at the end of each row.
cc(:, [3 6 11 14 17 end+1]) = ' ';

%.. figure out the number of columns of data by doing a generalized
%.. read of the first row. ncol will be used to determine if a partial
%.. data line was imported.
[~, ncol] = sscanf(cc(1,:), '%f');

%.. it appears there can be a variable number of aqdII data columns,
%.. depending on the setup. checking for the normal number of columns
%.. (24 + 6 for date and time) does not work for R00008.
%
% %.. check
% if ncol~=number_of_hardcoded_data_columns + 6
%     str = num2str(number_of_hardcoded_data_columns);
%     msg = ['This code expects files with ' str ' data columns, ' ...
%            'excluding the date and time fields.'];
%     error(msg);
% end
 
%.. now all the data can be simply read in.
%.. sscanf scans down columns, so transpose cc before scanning
[data, nvalues, errmsg] = sscanf(cc', '%f', [ncol Inf]);
%.. now that the diagnostics have been recovered, transpose back.
data = data';

%.. error checking
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
    fprintf('     Deleted this last row of data.\n\n');
    %.. I've seen partial rows for AQD data; they were always the
    %.. last row.
    data(end, :) = [];
end

aqd.imported_data = data;
aqd.data_status  = {'imported'};
