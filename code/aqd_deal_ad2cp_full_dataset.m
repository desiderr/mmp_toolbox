function [aqd] = aqd_deal_ad2cp_full_dataset(aqd)
%=========================================================================
% DESCRIPTION
%   Transfers AD2CP data that was imported as 2D arrays into structure
%   fields. 
%
% USAGE:  [aqd] = aqd_deal_ad2cp_full_dataset(aqd)
%
%   INPUT
%     aqd       = a scalar structure whose imported_data field contains 
%                 the imported data
%
%   OUTPUT
%     aqd       = a scalar structure with the variable data copied to the
%                 appropriately named fields
%
% DEPENDENCIES
%   Matlab 2018b
%
% NOTES
%   Full datasets with either 25 or 26 columns are dealt (30 and 31 when
%   the 1 date-time column is considered as 6 columns). Early datasets
%   do not unpack with a pressure column.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%=========================================================================


nRowMin = 5;  % if less than this number of data rows, don't process

%.. 1st version of ad2cp code - problem profiles will be denoted by 
%.. aqd.heading = [] (as was initialized).
aqd.code_history(end+1) = {mfilename};
if isempty(aqd.imported_data)
    aqd.data_status(end+1) = {'NO DATA'};
    return
end

%------
% BEGIN
%------
profnum = [' profile number ' num2str(aqd.profile_number) ' '];

%.. do some error checking before writing data into the structure fields
%.. so that if the file being processed contains suspect data, these data
%.. remain in the 'imported_data' field and the other fields will contain
%.. default 'null' values as assigned by the import_A_ad2cp function.
data = aqd.imported_data;

%.. AD2CP files from the McLane contain either 25 or 26 columns of data
%.. depending on whether there is a pressure column for the ad2cp pressure
%.. sensor. Determine which so that the beam mapping data description 
%.. integers can be found and checked for uniformity within the profile.
[nrow, ncol] = size(data);
if nrow < nRowMin
    disp(' ');
    disp(['Warning: ********  ' profnum '  ***************']);
    disp(['Less than ' num2str(nRowMin) ' data rows; not processed.']);
    aqd.data_status(end+1) = {'imported data not assigned to variables'};
    return
elseif ncol==30  % 24 + 6 for date and time
    xcol = 0;  % number of extra columns
elseif ncol==31
    xcol = 1;  %.. extra column is for aqd_pressure in column 9
else
    disp(['WARNING: ********  ' profnum '  ***************']);
    disp(['Unexpected number of AD2CP data columns: ' ...
        'unknown imported data not dealt to structure fields.']); 
    aqd.data_status(end+1) = {'imported data not assigned to variables'};
    return
end
beam_map = data(:, xcol+(17:21));  % maps beam# to datafield#
if ( all(beam_map(:, 4)==0) && all(beam_map(:, 5)==0) )
    beam_map(:, 4:5) = [];  % delete last 2 columns of zeros
    %.. check to see if all row entries are the same.
    if (  all(beam_map(:, 1) == beam_map(1, 1))          ...
                             &&                          ... 
          all(beam_map(:, 2) == beam_map(1, 2))          ...
                             &&                          ...
          all(beam_map(:, 3) == beam_map(1, 3))  )
        beam_map = beam_map(1, :);
    else
        disp(['WARNING: ********  ' profnum '  ***************']);
        disp('Beam mapping changes within profile.');
        aqd.data_status(end+1) = {'imported data not assigned to variables'};
        return
    end
else
    disp(['WARNING: ********  ' profnum '  ***************']);
    disp('Last two columns of beam mapping are not all 0.');
    aqd.data_status(end+1) = {'imported data not assigned to variables'};
    return
end

%.. calculate acquisition rate
time = datenum(data(:, [3 1 2 4 5 6]));     % matlab serial datenumber
aqd.acquisition_rate_Hz_calculated = ...
    (length(time) - 1) / (86400 * (time(end) - time(1)));
%.. populate structure fields
aqd.time         = time;                    % matlab serial datenumber
aqd.soundspeed   = data(:, 7);              % [m/s]
aqd.aqd_temperature  = data(:, 8);          % [Celsius]

%.. aqd_pressure data are ad2cp pressure sensor readings, not ctd.
if xcol==0
    aqd.aqd_pressure(1:nrow, 1) = NaN;
else
    if all(data(:, 9)==0)  % don't combine this branch with "if xcol==0" !
        aqd.aqd_pressure(1:nrow, 1) = NaN;
    else
        aqd.aqd_pressure = data(:, 9);
    end
end    
aqd.heading      = data(:,  xcol+9);       % [degrees]
aqd.pitch        = data(:, xcol+10);       % [degrees]
aqd.roll         = data(:, xcol+11);       % [degrees]
aqd.magnetometer = data(:, xcol+(12:14));  % relative xyz values
%*************************************************************************
% see NOTES
aqd.magnetometer = aqd.magnetometer + nan;
%*************************************************************************
aqd.nbeams       = data(:,      xcol+15);  % number of beams used
aqd.ncells       = data(:,      xcol+16);  % #cells/beam
aqd.beam_mapping = beam_map;               % maps beam# to datafield#

%.. replace column vectors whose entries are expected to be identical
%.. with one value
if all(aqd.soundspeed==aqd.soundspeed(1))
    aqd.soundspeed = aqd.soundspeed(1);
end
if all(aqd.nbeams==aqd.nbeams(1))
    aqd.nbeams = aqd.nbeams(1);
end
if all(aqd.ncells==aqd.ncells(1))
    aqd.ncells = aqd.ncells(1);
end

%.. re-orient velBeam, amplitude, and correlation Nx3 data into
%.. Nx4 arrays keyed to transducer numbering using the beam mapping.
%.. .. (note, 3D magnetometer values are not associated with transducers).
aqd.velBeam(1:nrow, 1:4) = nan;
aqd.velBeam(:, aqd.beam_mapping) = data(:, xcol+(22:24));
aqd.amplitude(1:nrow, 1:4) = nan;
aqd.amplitude(:, aqd.beam_mapping) = data(:, xcol+(25:27));
aqd.correlation(1:nrow, 1:4) = nan;
aqd.correlation(:, aqd.beam_mapping) = data(:, xcol+(28:30));

%.. initialize profile mask
aqd.profile_mask = logical(aqd.time);

aqd.data_status(end+1) = {'data dealt'};
aqd.imported_data = [];
end
%--------------------------------------------------------------------
