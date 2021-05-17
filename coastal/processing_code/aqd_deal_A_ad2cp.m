function [aqd] = aqd_deal_A_ad2cp(aqd, prof2proc)
%=========================================================================
% DESCRIPTION
%   Determines the number of columns of imported data so that the appropriate
%   subroutine to deal the data to appropriately named structure fields can
%   be selected.
%
% USAGE:  [aqd] = aqd_deal_A_ad2cp(aqd, prof2proc)
%
%   INPUT
%     aqd       = a structure array which contains imported data as 2D arrays
%     prof2proc = a vector denoting the profile numbers to process 
%
%   OUTPUT
%     aqd       = a structure array with the variable data copied to the
%                 appropriately named fields
%
% DEPENDENCIES
%   Matlab 2018b
%   aqd_deal_ad2cp_full_dataset
%   aqd_deal_ad2cp_OOI_decimated_dataset
%
% NOTES
%   Full datasets and OOI-decimated datasets are supported.
%
%   Dataset formats (number of data columns) are checked for all of the profiles
%   selected as specified by prof2proc. 
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%.. 2021-05-04: desiderio: clarified documentation and warning and error messages.
%.. 2021-05-10: desiderio: radMMP version 2.20c (OOI coastal)
%=========================================================================

%.. determine the number of imported data columns
data = {aqd.imported_data};  % this gets the imported data from all profiles
data(cellfun('isempty', data)) = [];  %  discard empties
if isempty(data)    % if there is now no data left,
    error('NO AD2CP DATA WAS IMPORTED; CHECK PATHS, FOLDERS, AND FILES.');
end
ncol = cellfun(@(x) size(x, 2), data);  % ncolumn values for non-empty profiles 
ncol = unique(ncol);
if ~isscalar(ncol)
    disp('MORE THAN ONE FORMAT OF AD2CP DATASET DETECTED IN SELECTED PROFILES.');
    disp(['Number of data columns found: ' num2str(ncol-5)]); 
    disp('For those formats supported by this code, make separate')
    disp('processing runs and in each run specify profiles that have')
    disp('the SAME FORMAT [SAME NUMBER OF DATA COLUMNS] in the')
    disp('profiles_to_process metadata value.')
    error('MORE THAN ONE FORMAT OF AD2CP DATASET DETECTED IN SELECTED PROFILES.');
end

%.. the imported data have 6 columns instead of just one representing 
%.. DateTime (mm-dd-yyyy HH:MM:SS), the difference is 5.
number_of_delimited_data_columns = ncol - 5;
fprintf('  AD2CP data has %u columns:\n', number_of_delimited_data_columns);

switch number_of_delimited_data_columns
    case 11
        disp('********************************************************');
        disp('THIS FORMAT OF DECIMATED AD2CP DATASET IS NOT SUPPORTED.');
        disp('********************************************************');
        error('Number of data columns is same as for faulty OOI decimated (lacks beam mapping).');
    case 12
        disp('********************************************************');
        disp('THIS FORMAT OF DECIMATED AD2CP DATASET IS NOT SUPPORTED.');
        disp('********************************************************');
        error('Number of data columns is same as for default McLane setting, not an OOI configuration.');
    case 16
        fprintf('  Assumed to be ''decimated OOI-style'' with these variables:\n');
        fprintf('  datetime,  tmpC, hdng, pitch, roll, beams, beam1, beam2\n');
        fprintf('     beam3, beam4, vel1,  vel2, vel3,  amp1,  amp2,  amp3\n');
        for ii = prof2proc
            aqd(ii) = aqd_deal_ad2cp_OOI_decimated_dataset(aqd(ii));
        end
    case 25
        disp(['  Assumed to be full dataset BEFORE ad2cp pressure sensor ' ...
            'values started appearing in unpacked data.']);
        for ii = prof2proc
            aqd(ii) = aqd_deal_ad2cp_full_dataset(aqd(ii));
        end
    case 26
        disp(['  Assumed to be full dataset AFTER ad2cp pressure sensor ' ...
            'values started appearing in unpacked data.']);
        for ii = prof2proc
            aqd(ii) = aqd_deal_ad2cp_full_dataset(aqd(ii));
        end
    otherwise
        disp('*********************************************************');
        disp('THIS NUMBER OF COLUMNS IN AD2CP DATASET IS NOT SUPPORTED.');
        disp('*********************************************************');
        error('CHECK THE NUMBER OF COLUMNS IN THE UNPACKED A-FILES.');       
end
