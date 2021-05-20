function [acm] = fcm_import_A_3dmp(filename)
%=========================================================================
% DESCRIPTION:
%    Imports Falmouth Scientific 3DMP acoustic currentmeter data from 
%    unpacked McLane profiler 'A' files.
%
% USAGE:  acm = fcm_import_A_3dmp(filename)
%
%   INPUT
%     filename = an ASCII text 'A' file created from the profiler raw binary
%                data by using the McLane unpacker software v3.10 or v3.12
%                or later. the internal structure of the file can be any one
%                of 4 possible formats, set by the 2 binary unpacker switches.
%
%                See Notes.
%
%   OUTPUT  
%     acm = a scalar data structure. for structure fieldnames and documentation
%           go to the initialization section in this code. this routine is meant 
%           to be called once for each profile in a deployment so that the
%           imported data will be contained in an array of structures, with the
%           index of each element of the structure denoting the profile number.
%           profile number 0 is not processed.
%
% DEPENDENCIES
%   Matlab R2019b
%
% NOTES
%   For McLane profiler version (5.00) using Unpacker V3.12 there are 2 export
%   choices for unpacking that can result in 'A' files with 4 different 
%   internal structures. The choices are:
%     (a) data delimiters: comma separated or space padded columns
%     (b) whether or not to include: header and on and off date\time text rows.
%   This code will work with any of the 4 formats.
%
% REFERENCES
%   "Profiler Integrated Sensors & Communications Interface User Manual".
%   version 17.G.25. 2017. McLane Research Laboratories, Inc. Chapter 4.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2020-09-22: desiderio: initial code
%.. 2020-11-04: desiderio: first data point discarded
%.. 2021-03-05: desiderio: init of sensor_field_indices corrected to 7:17
%.. 2021-03-08: desiderio: renamed
%.. 2021-05-19: desiderio
%..             (a) added profile_date (init as nan) and backtrack fields
%..             (b) adjusted sensor_field_indices vector to 9:19
%.. 2021-05-21: desiderio: radMMP version 3.10g (OOI global)
%=========================================================================

%----------------------
% PRELIMINARY SET-UP
%----------------------
clearvars C  % make sure this cell array is cleared

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

acm.deployment_ID     = '';
acm.profile_number    = [];    % scalar
acm.profile_date      = nan;
acm.profile_direction = '';  
acm.data_status       = {''};  % cell can contain multiple status reports
acm.code_history      = {mfilename};
acm.header            = '';  % McLane file header, not FSI ACM+ header
acm.backtrack         = '';
acm.time              = [];  % serial datenumber
acm.pressure          = [];  % from ctd
acm.dpdt              = [];  % uses ctd pressure
acm.soundspeed        = [];  % provided for user-scaling of velocity data
acm.heading           = [];
acm.TX                = [];
acm.TY                = [];
acm.magnetometer      = zeros(0, 3);  % HX HY HZ
acm.velBeam           = zeros(0, 4);  % VPAB VPCD VPEF VPGH
acm.velXYZ            = zeros(0, 3);
acm.velENU            = zeros(0, 3);
acm.magnetic_declination  = [];
acm.correct_velY_for_wag  = 0;   % overridden by meta value
acm.correct_velU_for_dpdt = 0;   % overridden by meta value
acm.wag_radius            = [];
acm.wag_signal            = [];  % subtract this data to correct for wag
acm.profile_mask          = [];  % true values denote good section(s)
acm.sensor_field_indices  = 9:19;  % for 'init_unsel' and 'void_short' functions 
acm.pressure_bin_values   = [];
acm.binning_parameters    = [];  % [pr_min binsize pr_max]
acm.acquisition_rate_Hz_calculated = nan;  % derived scalar quantity
acm.depth_offset_m        = 0;   % to be replaced by meta value
acm.on                    = '';
acm.off                   = '';

%----------------------
% CHECK INPUT ARGUMENTS
%----------------------
%.. sometimes the functions disp and fprintf, and particularly labels
%.. in figures, don't work well with backslashes, so change them to
%.. forward slashes which works fine in windows paths.
filename = strrep(filename, '\', '/');

%.. .. enter a profile number into the structure here so that they will be
%.. .. present if there are premature returns; these will be overwritten
%.. .. by those in the header if present.
%.. parse filename for profile number;
%.. these could either be *.DEC.TXT or *.TXT files,
%.. so use fileparts twice
[~, name, ~] = fileparts(filename);
[~, name, ~] = fileparts(name);
acm.profile_number = str2double(name(end-6:end));

check_infile = exist(filename, 'file');
if check_infile ~=2
    disp(['WARNING: Could not find file ', filename]);
    acm.data_status = {'no datafile'};
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
%.. C is now a cell column vector of character vector rows.
%
%.. for a given deployment each extracted fsi acm text file ends with
%.. the same ACM+ header text which is saved elsewhere in the 
%.. processing. Discard.
idx = find(contains(C, 'ACM+ Header Contents:'));
if isempty(idx)
    disp('Notice: no ACM+ header found in infile.');
    disp('Proceeding with data import.');
else
    C(idx(1):end) = [];  % delete
end

%.. FSI ACM+ files start with a row which gives the data acquisition rate,
%.. 'Sample rate: N.0000 Hz', followed by two blank rows.
if contains(C{1}, 'Sample rate') && contains(C{1}, 'Hz')
    %.. read in data acquisition rate from header for comparison with data
    tmp = str2double(split(C{1}));
    daqFromFileHeader = tmp(~isnan(tmp));
end

%.. finish run if there are no data as signified by the daq value.
if daqFromFileHeader==0
    acm.data_status = {'no data'};
    return
end

C(1) = [];
%.. trim leading and trailing whitespace from all rows. 
C = strtrim(C);
%.. DELETE blank rows
C(cellfun('isempty', C)) = [];
%.. determine whether there are non-data rows.
%..   if so, normal McLane-unpacked fsi-acm files will have two 'Profile'
%..   rows, one in front and one in back of the data; the second will
%..   not be present if an exception is encountered.
mask_profilerows = strncmpi(C, 'Profile', 7);
n_profilerows = sum(mask_profilerows);
if n_profilerows > 0  % there are rows of text that are not data
    %.. read profile number
    profilerows = C(mask_profilerows);
    acm.profile_number = sscanf(profilerows{1}(8:end), '%u');
    C(mask_profilerows) = [];  % delete profilerows from the data
    %.. under normal circumstances, the first row is now the header
    %.. (all blank lines were deleted). one observed exception is that
    %.. there are no data in which case there will be (always?) an
    %.. 'End of file reached' row.
    if contains(C{1}, 'End of file reached', 'ignoreCase', true)
        acm.data_status = {'no data'};
        return
    %.. there may also be cases where the entire file consists of only the
    %.. last 3 footer lines as is true for the nortek ad2cp; process 
    %.. this case too.
    elseif ~strcmpi(C{1}(1:10), 'MM-DD-YYYY')  % not a header line
        acm.on = C{end-1};
        acm.off = C{end};
        acm.data_status = {'no data'};
        return
    end
    %.. the first row is now the header (all blank lines were deleted)
    acm.header = C{1};
    C(1) = [];  % delete the header
    %.. for these datafiles, IF an exception is encountered, 
    %.. the on/off date-time text rows will be missing.
    mask_exception = strncmpi(C, 'Exception', 9);  % logical column vector
    if any(mask_exception)
        idx = find(mask_exception);
        idx = idx(1);  % in case there's more than one (not likely)
        acm.on  = C{idx};  % write the exception message
        acm.off = C{idx};
        C(idx:end) = [];  % delete everything after first exception
    else
        acm.on = C{end-1};
        acm.off = C{end};
        C(end-1:end) = [];  % delete them
    end
else  % no header, footer, no 'Exception Encountered' rows
    %.. because C only contains data lines, 
    %.. try to get profile number from filename.
    [~, name, ~] = fileparts(filename);
    %.. because the ACM files can be names as either *.DEC.TXT or *.TXT:
    [~, name, ~] = fileparts(name);
    %.. the unpacker can add a prefix, not a suffix, so the last
    %.. 7 characters of the filename should be conserved.
    %.. if this fails, the result should be an entry of NaN.
    acm.profile_number = str2double(name(end-6:end));

    %.. a non-standard case to parse: 
    %..    there are some TXT files which have been unpacked and then
    %..    separately edited to have just one header row of column
    %..    labels. this will cause the sscanf statement to throw an
    %..    an error. parse for any such occurrences and fix. 
    mask = ~cellfun('isempty', regexp(C, '[a-zA-Z]'));
    C(mask) = [];  % delete if present
end

%.. at this stage there are only data rows.

%.. convert comma delimited data to space-padded.
%.. if C is already space-padded, nothing changes.
C = strrep(C, ',', ' ');
%.. turn into a character array for fast parsing
cc = char(C);

%.. trap out if no data at all found
%.. .. the fsi acm data often start with aliased values in the first
%.. .. data point, particularly heading. this will be discarded.
if isempty(cc) || length(C) < 2 
    disp(['WARNING: No data found in ' filename]);
    acm.data_status = {'no data'};
    return
end
cc(1, :) = [];
%*************************************************
% IF the last row of McLane 3DMP data is always normal, it does not need
% to be deleted as it is in the Nortek AD2CP case. If it is to be deleted
% bunp the length(C) check above to < 3.
% % % % %.. delete all last rows.
% % % % cc(end, :) = [];
%*************************************************

%.. copy spaces into delimiter columns in the date time fields;
%.. expected format is the same for full v. decimated datasets: 
%.. ..  MM-DD-YYYY hh:mm:ss
%.. .. there should already be a delimiter after 'ss'
%.. also add a delimiter at the end of each row.
cc(:, [3 6 11 14 17 end+1]) = ' ';

%.. figure out the number of columns of data by doing a generalized
%.. read of the first row. ncol will be used to determine if a partial
%.. data line was imported.
[~, ncol] = sscanf(cc(1,:), '%f');

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
    %.. I've seen partial rows for acm data; they were always the
    %.. last row.
    data(end, :) = [];
end

%.. calculate acquisition rate
time = datenum(data(:, [3 1 2 4 5 6]));     % matlab serial datenumber
daqCalculated = (length(time) - 1) / (86400 * (time(end) - time(1)));
acm.acquisition_rate_Hz_calculated = daqCalculated;
%.. check daq calculated from data vs. that read in from extracted file
daqCalculated = round(10 * daqCalculated) / 10;
daqDiff = abs(daqFromFileHeader-daqCalculated);
if mod(daqDiff, 1)~=0
    disp(' ');
    disp('**************************************************************');
    disp([filename ': Warning, stated and actual daq rate are not equal']);
    disp(['stated: ' num2str(daqFromFileHeader)]);
    disp(['actual: ' num2str(daqCalculated)]);
    disp('**************************************************************');
    disp(' ');
end 

%*********************************************************************
%.. it might be more robust to adjust the time record after short
%.. profiles have been thrown away.
%*********************************************************************

%.. populate structure fields
acm.time         = time;            % matlab serial datenumber
acm.heading      = data(:, 7);      % [degrees]
acm.TX           = data(:, 8);      % "pitch"; see MMP User Manual Rev E page D-4
acm.TY           = data(:, 9);      % "roll" ; see MMP User Manual Rev E page D-4
acm.magnetometer = data(:, 10:12);  % HX,HY,HZ; direction cosines
acm.velBeam      = data(:, 13:16);  % VPAB, VPCD, VPEF, VPGH

%.. initialize profile mask
acm.profile_mask = logical(acm.time);
acm.data_status  = {'imported'};

end
