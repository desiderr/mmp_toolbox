
function meta = import_OOI_calfiles(meta, profiler_type)
%=========================================================================
% DESCRIPTION
%    Imports instrument calibration coefficients from OOI-style csv calibration
%    files and writes them into the (pre-existing) structure 'meta'.
%
% USAGE:    meta = import_OOI_calfiles(meta, profilerType);
%
%   The program import_metadata.m must be run before import_OOI_calfiles
%   so that the relevant fields specifying profiler type and calfile names
%   and location are populated.
%
%   INPUT
%     meta [a scalar structure] 
%     profiler_type must be set to either 'coastal' or 'global'
%
%   OUTPUT
%     meta
%
% DEPENDENCIES
%   Matlab R2018b
%
% NOTES
%   The structure 'meta' must contain the OOI calibration filenames and the
%   local foldername in which they can be found.
%
%   IF AN INSTRUMENT WHICH IS NORMALLY DEPLOYED IS NOT, THEN THE CORRESPONDING
%   ENTRY IN THE METADATA TEXT FILE SHOULD BE RETAINED AND THE CALFILENAME
%   SPECIFIED AS '' (two single quotes denoting an empty character vector).
%   This will result in an entry of '' in the corresponding field of the
%   structure meta as desired\required.
%
%   This code will work on calfiles which have commas inside of double quotes
%   sometimes found in the notes column.
%
%   This code will also work on some types of anomalous formats that have
%   been encountered in OOI asset management repositories (eg, rows containing
%   just ").
%
%   COASTAL instruments requiring calibration files:
%      SBE\WETLabs ECO triplet fluorometer (flortk; chlflr,bback,cdomflr)
%      SBE43f oxygen sensor                (dofstk)
%      Biospherical QSP-2200 PAR sensor    (paradk)
%
%   GLOBAL instruments requiring calibration files:
%      SBE\WETLabs FLBBRTD fluorometer     (flordj; chlflr,bback)
%      (The Aanderaa oxygen sensor is configured so that it does NOT
%       require calibration files.) 
%
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-03-05: desiderio: (a) updated to handle global fluorometer (flbbrtd)
%..                        (b) changed to function format instead of script
%.. 2020-03-30: desiderio: refactored into cal subfunctions
%.. 2020-04-30: desiderio: added diagnostic output if calfile not found
%.. 2020-05-04: desiderio: radMMP version 3.0 (OOI coastal and global)
%=========================================================================
%----------------------
% CHECK INPUT ARGUMENTS
%----------------------

% disp(' ');
% disp('This code processes only OOI-style calfiles.');
% disp(' ');

if     strcmpi(profiler_type, 'coastal')
    meta = dofstk(meta);
    meta = florxx(meta);
    meta = paradk(meta);
elseif strcmpi(profiler_type, 'global')
    meta = florxx(meta);
else
    error('profilerType must either be ''coastal'' or ''global''.');
end
end  % function import_OOI_calfiles

function meta = dofstk(meta)
%------------------------------------------------------------------------
% SBE43F oxygen sensor (DOFST-K); OOI coastal profilers
%------------------------------------------------------------------------
[fid, errmsg] = fopen([meta.calibration_folder meta.oxygen_calfilename]);
if fid<0
    disp(' ');
    disp('**************************************************************');
    disp( '*****   The sbe43f (DOFSTK) calfile:');
    disp(['*****       ' meta.oxygen_calfilename]);
    disp( '*****   was not found in calfolder:');
    disp(['*****       ' meta.calibration_folder]);
    disp(' ');
    disp('System error message:');
    disp(errmsg);
    disp(' ');
    disp('         ALL OF ITS CALCOEFFS SET TO NaN.');
    disp('**************************************************************');
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
end  % subfunction dofstk

function meta = florxx(meta)
%------------------------------------------------------------------------
% SBE\Wetlabs fluorometers:
%    ECO TRIPLET (FLORT-K); OOI coastal profilers
%    FLBBRTD     (FLORD-L); OOI  global profilers
%------------------------------------------------------------------------
%.. text correspondences
%.. .. FLORT-K has all of these calcoeffs
%.. .. FLORD-L has all but the first two (no cdom fluorescence)
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
[fid, errmsg] = fopen([meta.calibration_folder meta.fluorometer_calfilename]);
if fid<0
    disp(' ');
    disp('**************************************************************');
    disp( '*****   The fluorometer calfile:');
    disp(['*****       ' meta.fluorometer_calfilename]);
    disp( '*****   was not found in calfolder:');
    disp(['*****       ' meta.calibration_folder]);
    disp(' ');
    disp('System error message:');
    disp(errmsg);
    disp(' ');
    disp('         ALL OF ITS CALCOEFFS SET TO NaN.');
    disp('**************************************************************');
    disp(' ');
    %.. it's OK if a non-existent FLORD-L 'cal' has cdom calcoeffs of NaN
    for ii = 1:size(match, 1)
        meta.fluorometer_cal.(match{ii, 2}) = NaN;
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
        %.. FLORD-L case, no cdom match entries in Z signify no cdom calcoeffs
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
    Z = strcat('meta.fluorometer_cal.', Z);
    Z = strrep(Z, ',', '=');
    Z = strcat(Z, ';');
    for ii = 1:length(Z)
        eval(Z{ii});
    end
end
end  % subfunction florxx

function meta = paradk(meta)
%------------------------------------------------------------------------
% Biospherical QSP-2200 PAR sensor (PARAD-K); OOI coastal profilers
%------------------------------------------------------------------------
[fid, errmsg] = fopen([meta.calibration_folder meta.par_calfilename]);
if fid<0
    disp(' ');
    disp('**************************************************************');
    disp( '*****   The qsp-2200 (PARADK) calfile:');
    disp(['*****       ' meta.par_calfilename]);
    disp( '*****   was not found in calfolder:');
    disp(['*****       ' meta.calibration_folder]);
    disp(' ');
    disp('System error message:');
    disp(errmsg);
    disp(' ');
    disp('         ALL OF ITS CALCOEFFS SET TO NaN.');
    disp('**************************************************************');
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
end  % subfunction paradk
