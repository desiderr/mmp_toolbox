% import_OOI_calfiles.m
%=========================================================================
% DESCRIPTION
%    Imports instrument calibration coefficients from OOI-style csv calibration
%    files and writes them into the pre-existing structure 'meta'.
%
% USAGE:    import_OOI_calfiles
%
%   Run this program from the working directory with no input or output
%   arguments. The program import_metadata.m must be run before
%   import_OOI_calfiles so that the structure variable 'meta' exists
%   in the base workspace.
%
%   INPUT
%     This program has no formal input arguments. 
%
%   OUTPUT
%     This program has no formal output arguments.
%
% DEPENDENCIES
%   Matlab R2018b
%
% NOTES
%   The structure 'meta' must contain the OOI calibration filenames and the
%   local foldername in which they can be found.
%
%   This code will work on calfiles which have commas inside of double quotes
%   sometimes found in the notes column.
%
%   This code will also work on some types of anomalous formats that have
%   been encountered in the OOI program (eg, rows containing just ").
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%.. 2021-05-10: desiderio: radMMP version 2.20c (OOI coastal)
%=========================================================================
%----------------------
% CHECK INPUT ARGUMENTS
%----------------------
%.. make sure meta structure exists in workspace.
if ~exist('meta', 'var') || ~isstruct(meta)
    fprintf('\n');
    disp('Cannot find the structure ''meta'' in the workspace.');
    disp('(Type ''who'' for a listing of workspace variables.)');
    fprintf('\n');
    disp('To fix, see documentation for, and then run,');
    disp('''import_metadata.m''.');
    return
end

% disp(' ');
% disp('This code processes only OOI-style calfiles.');
% disp(' ');

%---------------------
% SBE43F oxygen sensor
%---------------------
%.. DOFSTK
fid = fopen([meta.calibration_folder meta.oxygen_calfilename]);
if fid<0
    disp(' ');
    disp('No sbe43f (dofstk) calfile found.');
    disp('All of its calcoeffs set to NaN.');
    disp(' ');
    meta.sbe43f_cal.Foffset = NaN;
    meta.sbe43f_cal.Soc_adj = NaN;
    meta.sbe43f_cal.A       = NaN;
    meta.sbe43f_cal.B       = NaN;
    meta.sbe43f_cal.C       = NaN;
    meta.sbe43f_cal.E       = NaN;
else
    clear Z
    Z = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
    fclose(fid);
    Z = Z{1};
    %.. delete header
    Z(strncmpi(Z, 'serial', 6)) = [];
    %.. delete (nonsense) rows with less than 10 characters if present.
    Z(cellfun('length', Z)<10) = [];
    Z = strrep(Z, 'CC_frequency_offset', 'Foffset');
    Z = strrep(Z, 'CC_oxygen_signal_slope', 'Soc_adj');
    Z = strrep(Z, 'CC_residual_temperature_correction_factor_a', 'A');
    Z = strrep(Z, 'CC_residual_temperature_correction_factor_b', 'B');
    Z = strrep(Z, 'CC_residual_temperature_correction_factor_c', 'C');
    %.. despite the OOI name, E is not a temperature factor.
    Z = strrep(Z, 'CC_residual_temperature_correction_factor_e', 'E');
    %.. select name and value
    idx = strfind(Z, ',');
    for ii = 1:length(Z)
        range = idx{ii}(1)+1:idx{ii}(3)-1; 
        Z{ii} = Z{ii}(range);
    end
    %.. write name as structure field and value
    Z = strcat('meta.sbe43f_cal.', Z);
    Z = strrep(Z, ',', '=');
    Z = strcat(Z, ';');
    for ii = 1:length(Z)
        eval(Z{ii});
    end
end

%--------------------
% Wetlabs eco triplet
%--------------------
%.. FLORTK
%.. text correspondences
match = {
    'CC_dark_counts_cdom'                  'cdom_dark'
    'CC_scale_factor_cdom'                 'cdom_scale'
    'CC_dark_counts_chlorophyll_a'         'chl_dark'
    'CC_scale_factor_chlorophyll_a'        'chl_scale'
    'CC_dark_counts_volume_scatter'        'bback_dark'
    'CC_scale_factor_volume_scatter'       'bback_scale'
    'CC_angular_resolution'                'bback_chi_factor'
    'CC_depolarization_ratio'              'bback_depolarization_ratio'
    'CC_measurement_wavelength'            'bback_wavelength'
    'CC_scattering_angle'                  'bback_scattering_angle'
};

fid = fopen([meta.calibration_folder meta.fluorometer_calfilename]);
if fid<0
    disp(' ');
    disp('No eco-triplet (FLORTK) calfile found.');
    disp('All of its calcoeffs set to NaN.');
    disp(' ');
    for ii = 1:size(match, 1)
        meta.triplet_cal.(match{ii, 2}) = NaN;
    end
else
    clear Z
    Z = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
    fclose(fid);
    Z = Z{1};
    %.. delete header
    Z(strncmpi(Z, 'serial', 6)) = [];
    %.. delete (nonsense) rows with less than 10 characters if present.
    Z(cellfun('length', Z)<10) = [];
    %.. replace OOI designation
    for ii = 1:length(match)
        Z = strrep(Z, match{ii, 1}, match{ii, 2});
    end
    %.. if any rows with 'CC_' remain, delete 
    Z(contains(Z, 'CC_')) = []; 
    %.. select name and value
    Z = sort(Z);
    idx = strfind(Z, ',');
    for ii = 1:length(Z)
        range = idx{ii}(1)+1:idx{ii}(3)-1; 
        Z{ii} = Z{ii}(range);
    end
    Z = strcat('meta.triplet_cal.', Z);
    Z = strrep(Z, ',', '=');
    Z = strcat(Z, ';');
    for ii = 1:length(Z)
        eval(Z{ii});
    end
end

%----------------------
% Biospherical QSP-2200
%----------------------
%.. PARADK
fid = fopen([meta.calibration_folder meta.par_calfilename]);
if fid<0
    disp(' ');
    disp('No qsp-2200 (paradk) calfile found.');
    disp('All of its calcoeffs set to NaN.');
    disp(' ');
    meta.qsp2200_cal.par_dark      = NaN;
    meta.qsp2200_cal.par_scale_wet = NaN;
else
    clear Z
    Z = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
    fclose(fid);
    Z = Z{1};
    %.. delete header
    Z(strncmpi(Z, 'serial', 6)) = [];
    %.. delete (nonsense) rows with less than 10 characters if present.
    Z(cellfun('length', Z)<10) = [];
    Z = strrep(Z, 'CC_dark_offset', 'par_dark');  % units: mV
    %.. units of wet scaling factor are [V/(quanta/cm^2-sec)]
    Z = strrep(Z, 'CC_scale_wet', 'par_scale_wet');
    idx = strfind(Z, ',');
    for ii = 1:length(Z)
        range = idx{ii}(1)+1:idx{ii}(3)-1; 
        Z{ii} = Z{ii}(range);
    end
    Z = strcat('meta.qsp2200_cal.', Z);
    Z = strrep(Z, ',', '=');
    Z = strcat(Z, ';');
    for ii = 1:length(Z)
        eval(Z{ii});
    end
end

clear ans fid idx ii match range Z
