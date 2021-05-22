function [aqd] = aqd_deal_ad2cp_OOI_decimated_dataset(aqd)
%=========================================================================
% DESCRIPTION
%   Transfers AD2CP data that was imported as 2D arrays into structure
%   fields. 
%
% USAGE:  [aqd] = aqd_deal_ad2cp_OOI_decimated_dataset(aqd)
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
%   Only OOI-decimated datasets are supported.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-14: desiderio: fixed initialization of correlation to be 1:4
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%.. 2021-05-10: desiderio: radMMP version 2.20c (OOI coastal)
%.. 2021-05-24: desiderio: radMMP version 4.0
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

%.. OOI decimated AD2CP files from the McLane contain 16 columns of data;
%.. breaking out datetime into 6 variables gives 21 columns.
[nrow, ncol] = size(data);
if nrow < nRowMin
    disp(' ');
    disp(['Warning: ********  ' profnum '  ***************']);
    disp(['Less than ' num2str(nRowMin) ' data rows; not processed.']);
    aqd.data_status(end+1) = {'imported data not assigned to variables'};
    return
elseif ncol~=21
    disp(['WARNING: ********  ' profnum '  ***************']);
    disp(['Unexpected number of AD2CP data columns: ' num2str(nrow) ...
        '. Unknown imported data not dealt to structure fields.']); 
    aqd.data_status(end+1) = {'imported data not assigned to variables'};
    return
end
beam_map = data(:, 12:15);  % maps beam# to datafield#; only 4 for decimated
if all(beam_map(:, 4)==0)
    beam_map(:, 4) = [];  % delete column of zeros
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
    disp('Last column of beam mapping not all 0.');
    aqd.data_status(end+1) = {'imported data not assigned to variables'};
    return
end

%.. calculate acquisition rate
time = datenum(data(:, [3 1 2 4 5 6]));     % matlab serial datenumber
aqd.acquisition_rate_Hz_calculated = ...
    (length(time) - 1) / (86400 * (time(end) - time(1)));
%.. decimated dataset time values are truncated to the nearest second.
%.. restore fractional part - early unpacked undecimated 2 Hz datasets 
%.. used 0.375 and 0.875; later datasets unpack using 0.001 and 0.501.
%.. .. 4 Hz datasets have also been observed.
daqRate = round(aqd.acquisition_rate_Hz_calculated);
if daqRate > 1
    %.. convert seconds to datenumber by dividing by #secs in a day
    for ii = 2:daqRate  % no need to start at ii=1, that just adds 0.
        time(ii:daqRate:nrow) = time(ii:daqRate:nrow) + (ii-1)/daqRate/86400;
    end
end
%.. check for monotonicity
if any(diff(time)<=0)
    disp(['WARNING: ********  ' profnum '  ***************']);
    disp('Decimated AD2CP time record is not monotonic.');
    aqd.data_status(end+1) = {'imported data not assigned to variables'};
    return
end    

%.. populate structure fields
aqd.time             = time;         % matlab serial datenumber
aqd.aqd_temperature  = data(:,  7);  % [Celsius]
aqd.heading          = data(:,  8);  % [degrees]
aqd.pitch            = data(:,  9);  % [degrees]
aqd.roll             = data(:, 10);  % [degrees]
aqd.nbeams           = data(:, 11);  % number of beams used
aqd.beam_mapping     = beam_map;     % maps beam# to datafield#

%.. fields to be binned that were decimated and are initialized as empty:
%.. replace with nans. this will prevent complications later.
aqd.aqd_pressure(1:nrow, 1)  = NaN;
aqd.correlation(1:nrow, 1:4) = NaN;

%.. replace column vectors whose entries are expected to be identical
%.. with one value
if all(aqd.nbeams==aqd.nbeams(1))
    aqd.nbeams = aqd.nbeams(1);
end

%.. re-orient velBeam, amplitude, and correlation Nx3 data into
%.. Nx4 arrays keyed to transducer numbering using the beam mapping.
aqd.velBeam(1:nrow, 1:4) = nan;
aqd.velBeam(:, aqd.beam_mapping) = data(:, 16:18);
aqd.amplitude(1:nrow, 1:4) = nan;
aqd.amplitude(:, aqd.beam_mapping) = data(:, 19:21);

%.. initialize profile mask
aqd.profile_mask = logical(aqd.time);

aqd.data_status(end+1) = {'data dealt'};
aqd.imported_data      = [];
end
%--------------------------------------------------------------------
