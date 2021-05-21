function [data, outfile] = Process_McLane_FSIACM_Deployment(mode, infile, newMetaFile)
% radMMP version 3.10g (g = OOI Global) 
% RADesiderio, Oregon State University, 2021-05-21
%=========================================================================
% DESCRIPTION
%    Processes McLane Profiler (version 5.00) FSI ACM (3DMP) data after the
%    raw binary data have been extracted into 'A' ASCII files by the McLane 
%    Unpacker software V3.12. Only full dataset formats have been tested
%    and processed; it is likely that OOI-decimated file formats can also
%    be processed because these have the same file format but fewer data
%    points (one every 25 seconds; full dataset files have 2 per second).
%
%    Process_OOI_McLane_CTDENG_Deployment (ver 3.10) must be run first so 
%    that its processed CTD data can be used to add a CTD pressure record
%    to the 3DMP data.
%
%    radMMP version 3.10g specifically processes OOI data
%    from the following 'Global' surface moorings:
%
%    GA02HYPM    GI02HYPM     GP02HYPM     GS02HYPM
%
%    Instrumentation
%        CTDPF-L    SBE 52MP     (Seabird)
%        DOSTA-L    Optode 4330  (Aanderaa)
%        FLORD-L    FLBBRTD      (Seabird\WETLabs)
%        VEL3D-L    3DMP (ACM+)  (Falmouth Scientific)
%
%    The 'C' files contain SBE52MP (CTD) data.
%    The 'E' files contain FLBBRTD (chl fluorescence, red backscatter) and 4330 (oxygen) data.
%    The 'A' files contain 3DMP    (currentmeter) data.
%
% USAGE:  Also, see NOTES for typical processing sequences.
%
%  [data, <outfile>] = Process_McLane_FSIACM_Deployment(mode, infile, <newMetaFile>);
%
%    There are 3 usage modes. The last input argument and the last output 
%    argument are <optional> for all 3 modes and function similarly in each
%    of them.
%
%       The last input argument newMetaFile, if present, provides new metadata
%       (processing parameters) to override those contained in the old metadata
%       file saved in the input matfile (whose name is specified by the second
%       input argument). This provides a convenient mechanism for re-processing
%       the currentmeter data. 
%
%       If the last output argument outfile is present then the full suite of
%       associated data products will be saved to a matfile whose name is
%       specified by this output argument. If not, the only accessible data
%       product is provided by the first output argument.
%
%    MODE (1): 'import_and_process'
%
%       [data, <acm_matfilename>] = Process_McLane_FSIACM_Deployment('import_and_process', mmp_matfilename, <newMetaFile>)
%
%       INPUT:
%          mode = 'import_and_process' 
%          mmp_matfilename must come from the 2nd output argument from a run of Process_OOI_McLane_CTDENG_Deployment and
%              contain the structure array ctd_L1 and a scalar structure meta containing the processing parameters used
%              in that code run.
%          newMetaFile, if present, must be a valid metadata text file with the same general format as used to calculate
%              the data products saved in mmp_matfilename but may have different acm settings.
%
%       OUTPUT:
%          data = MPacm_L2, a scalar structure whose fields are 2D arrays of binned acm data suitable for 'pcolor' viewing.
%          acm_matfilename, if present, would contain the name of the saved matfile containing all of the acm data products:
%              acm_L0, acm_L1, acm_L2 are structure arrays of L0, L1, and L2 data, each array element contains data from one profile:
%                  acm_L0 contains unprocessed and processed data, not smoothed;
%                  acm_L1 contains the smoothed L0 data with some QC applied, just before binning; 
%                  acm_L2 contains binned data.
%              MPacm_L0, a scalar structure of NaN-padded ragged 2D arrays of L0 data (number of columns = number of profiles).           
%              MPacm_L1, a scalar structure of NaN-padded ragged 2D arrays of L1 data.          
%              MPacm_L2, the scalar structure of binned acm data as described above.           
%
%
%    MODE (2): 'import'  (note that the 'import' INPUT arguments are identical to those for mode 'import_and_process')
%
%       [data, <acm_matfilename>] = Process_McLane_FSIACM_Deployment('import', mmp_matfilename, <newMetaFile>)
%
%       INPUT:
%          mode = 'import' 
%          mmp_matfilename must come from the 2nd output argument from a run of Process_McLane_WFP_Deployment and contain
%              the structure array ctd_L1 and a scalar structure meta containing the processing parameters used in that code run.
%          newMetaFile, if present, must be a valid metadata text file with the same general format as used to calculate
%              the data products saved in mmp_matfilename but may have different acm settings.
%
%       OUTPUT:
%          data = acm, a structure array containing imported data.
%          acm_matfilename, if present, would contain the name of the saved matfile containing all of the variables necessary
%                           (acm, ctd_L1, meta) to process the data by running this code in 'process' mode.
%
%
%    MODE (3): 'process'  (note that the 'process' OUTPUT arguments are identical to those for mode 'import_and_process')
%
%       [data, <acm_matfilename>] = Process_McLane_FSIACM_Deployment('process', acm_matfilename_A, <newMetaFile>)
%
%       INPUT:
%          mode = 'process' 
%          acm_matfilename_A must come from the 2nd output argument from a previous run of this code in 'import' mode which will
%              contain the structure arrays acm and ctd_L1 and a scalar structure meta containing the processing parameters
%              used in that code run.
%          newMetaFile, if present, must be a valid metadata text file with the same general format as used to calculate the
%              data products saved in acm_matfilename but may have different acm settings.
%
%       OUTPUT:
%          data = MPacm_L2, a scalar structure whose fields are 2D arrays of binned acm data suitable for 'pcolor' viewing.
%          acm_matfilename, if present, would contain the name of the saved matfile containing all of the acm data products
%              acm_L0, acm_L1, acm_L2, MPacm_L0, MPacm_L1, and MPacm_L2 and meta;
%              See Mode (1) documentation.
%
%                     
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
%   This code suite was written to provide a framework and tools to allow users
%   to easily import and visualize a WFP data set so that they can apply their
%   own quality control.
%
% NOTES
%   The deployment's CTD and ENG data must be processed before the 3DMP. A
%   typical sequence of code calls is therefore:
%
%      [MPall, MMPX_matfilename] = Process_OOI_McLane_CTDENG_Deployment('metadata.txt');
%      [MPacm_L2, <acmDataFileName>] = Process_McLane_FSIACM_Deployment('import_and_process', MMPX_matfilename, <'newMetadata.txt'>);   
%
%      The 'newMetadata.txt' file, if included, could tell the code to look in a different folder for
%      the unpacked 'A' files than specified in 'metadata.txt', or, could contain different acm processing
%      parameters.
%
%   Importing 'A' files can take many minutes. In addition, to QC the 3DMP data may require much user
%   intervention and re-processing. For these reasons the 'import' and 'process' modes were implemented.
%   In this scenario the 3DMP data are imported and saved along with the supplementary data needed to
%   finish its processing (ctd_L1 and meta):
%
%      [MPall, MMPX_matfilename] = Process_OOI_McLane_CTDENG_Deployment('metadata.txt');
%      [acm, mportdName] = Process_McLane_FSIACM_Deployment('import', MMPX_matfilename, <'newMetadata.txt'>);   
%
%      Now that the imported data are contained in the acm structure array saved in mportdName
%      (along with ctd_L1 and meta), re-processing (with old or new metadata files as desired)
%      can proceed with any number of runs without having to re-import the data:
%
%      [MPacm_L2, <acmDataFileName>] = Process_McLane_FSIACM_Deployment('process', mportdName);   
%                                    and/or        
%      [MPacm_L2, <acmDataFileName>] = Process_McLane_FSIACM_Deployment('process', mportdName, 'newMetadata01.txt');   
%                                    and/or        
%      [MPacm_L2, <acmDataFileName>] = Process_McLane_FSIACM_Deployment('process', mportdName, 'newMetadata02.txt'));   
%
%
%   For McLane profiler version (5.00) using Unpacker V3.12 there are 2
%   binary choices for unpacking:
%       (a) data delimiters: comma separated or space padded columns
%       (b) whether to include: header and on and off date\time text rows
%   This code suite will work with any of these 4 possible formats.
%
%  The 0th (set-up) mclane profile is not processed. Therefore
%  when all files are processed, index number = profile number
%  (also true if there are missing profiles).
%
%
%    For large datasets most of the execution time is taken by saving
%    the data products. It is possible that the MPacm_L? variables can
%    be larger than 2 GB. Three versions have been tested:
%      '-v6': Fastest. No compression. Cannot save variables > 2GB. On the 
%             plus side, when that happens a warning is given and code
%             execution proceeds.
%
%      '-v7': Significantly slower. Compresses. Cannot save variables > 2GB.
%
%    '-v7.3': With large scalar structures and structure arrays of 1000s of
%             elements, extremely slow, possibly because of the HDF5 format
%             it uses. On 64-bit machines can save variables > 2GB.
%
%   To avoid MPacm_L? variables sized at greater than 2 GB the processing can
%   be broken up into multiple runs. For example, for 2000 profiles 2 runs can
%   be made using 2 metadata.txt files differing only in their setting for the
%   profiles_to_process vector: [1:1000] for the 1st, [1001:2000] for the second.
%
% DEPENDENCIES
%   Matlab 2018b
%
%   FUNCTIONS used by main code (alphabetical) with dependencies.
%    
%.. fcm_assign_fractional_seconds
%.. fcm_beam2XYZ
%.. fcm_import_A_3dmp
%.. fcm_nan_velENU_extreme_tilt
%.. fcm_remove_fields_from_L2_data
%.. fcm_set_processing_fields
%.. fcm_set_sensor_field_indices
%.. fcm_smooth
%       sbefilter
%.. fcm_sync_ctd
%.. fcm_wag_velocity
%.. fcm_write_3dmp_header_to_struct
%.. fcm_XYZ2ENU
%.. amalgamate_scalar_structures
%.. determine_binning_parameters
%.. import_metadata
%.. initialize_unselected_profile_structures
%.. nan_bad_profile_sections
%.. pressure_bin_mmp_data
%.. void_short_profiles
%.. write_field_arrays_to_new_structure
%
% REFERENCES
%   "McLane Moored Profiler User Manual" Rev-E (sic) September 2008. Appendix G
%   "Rev C Electronics Board User Interface" (sic) pages G-22,G-23. 
%
%   "Profiler Integrated Sensors & Communications Interface User Manual".
%   version 17.G.25. 2017. McLane Research Laboratories, Inc. Chapter 4.
%
%   The python DPA function fsi_acm_horz_vel at line 1297 (in 2020) in the module at
%   https://github.com/oceanobservatories/ion-functions/blob/master/ion_functions/data/vel_functions.py
%
%   "Velocity Measurements from a Moored Profiling Instrument", J.M. Toole,
%   K.W. Doherty, D.E. Frye, and S.P. Liberatore, in Proceedings of the
%   IEEE Sixth Working Conference on Current Measurement, March 1999,
%   San Diego, CA, pp 144-149. ISBN 0-7803-5505-9.
%
% REVISION HISTORY:
%.. 2020-10-XX: desiderio: initial code
%.. 2021-03-02: desiderio: in-house version 3.05g (OOI global), not released
%.. 2021-05-18: desiderio: changed how the date of profile values are determined
%.. 2021-05-19: desiderio: trapped out case of no FSI-ACM (3DMP) data header
%.. 2021-05-21: desiderio: radMMP version 3.10g (OOI global)
%=========================================================================
%%
radMMPversion = '3.10g';
disp('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&');
disp(['     ' mfilename ' ' radMMPversion]);
disp('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&');
%% ****** DETERMINE SETTINGS AFFECTED BY OPTIONAL FUNCTION ARGUMENTS ***********
if ~exist('newMetaFile', 'var') || isempty(newMetaFile)
    %.. if the optional 3rd input argument is not included:
    newMeta = [];
else
    %.. if it is:
    newMeta = import_metadata(newMetaFile);
end

%.. if the optional 2nd output argument is not included, don't create a matfile
%.. so that if only plots using MPacm_L2 are desired won't have to wait for the
%.. save operation to complete.
if nargout < 2
    createMatfile = false;
else
    createMatfile = true;
end

%% ************************* IMPORT AND RE-ENTRY *******************************
if contains(mode, 'import')
    fprintf('\nLoading ctd data from %s\n\n', infile); 
    load(infile, 'ctd_L1', 'meta');
    if ~isempty(newMeta), meta = newMeta; end
    %.. first determine whether these are full dataset (*.TXT) or decimated
    %.. (*.DEC.TXT) files
    listing = cellstr(ls([meta.unpacked_data_folder '\*A0*.TXT']));
    nListing = length(listing);
    if nListing == 0
        %.. 2021-05-20: does not work as intended. if the data folder does
        %.. not contain A files, then the one element of listing contains
        %.. an empty set, so that nListing=1. Fix here and in the AD2CP
        %.. code in a future version.
        error('NO A-FILES FOUND IN UNPACKED DATA FOLDER.');
    end
    nDECTXT  = sum(contains(listing, 'DEC'));
    nFullSet = nListing - nDECTXT;
    if nDECTXT > 0
        disp(['There are ' num2str(nDECTXT) ' unpacked decimated files.']);
    end
    if nFullSet > 0
        disp(['There are ' num2str(nFullSet) ' unpacked full dataset files.']); 
    end
    %.. if both decimated and full dataset files are present, process 
    %.. decimated if there are significantly more of them:
    if nDECTXT > 2 * nFullSet
        file_suffix = '.DEC.TXT';
    else
        file_suffix = '.TXT';
    end
    %.. if both full dataset and decimated files are in the same folder,
    %.. and the above default choice of which to process is not acceptable,
    %.. either move or suitably rename the offending files or
    %..    (a) force the processing of the full dataset files by inserting 
    %.. ..     file_suffix = '.TXT'; after this comment; or, 
    %.. .. (b) force the processing of the decimated files by inserting
    %.. ..     file_suffix = '.DEC.TXT'; after this comment.   

    disp(' ');
    if strcmpi(file_suffix, '.DEC.TXT')
        disp('Begin importing $$$DECIMATED$$$ 3DMP files ...');
    else
        disp('Begin importing $$$FULL DATASET$$$ 3DMP files ...');
    end
    disp(' ');
    tic
    for ii = meta.profiles_to_process
        Afilename = [meta.unpacked_data_folder 'A' num2str(ii,'%7.7u') file_suffix];
        acm(ii) = fcm_import_A_3dmp(Afilename); %#ok<*AGROW,*SAGROW>
    end
    disp('... import done.');
    toc
else  % re-entry processing (mode = 'process')
    %.. load variables saved from a previous run of this code 
    %.. when mode was set to 'import'
    fprintf('\nLoading variables from re-entry file %s ...\n', infile); 
    load(infile, 'acm', 'ctd_L1', 'meta');
    disp('... load done');
    if ~isempty(newMeta), meta = newMeta; end
end

if ~contains(mode, 'process')
    data = acm;       % return data
    if createMatfile  % save data for re-entry processing
        outfile = [meta.deployment_ID 'imported_acm__' ...
            datestr(now, 'yyyymmdd_HHMMSS')];
        disp(['Saving data into re-entry file ' outfile ' ...']);
        save(outfile, 'acm', 'ctd_L1', 'meta', '-v6');
        disp('... save done');
    end
    return
end

%% **************************** PROCESSING ***********************************
prof2proc = meta.profiles_to_process;
disp(['Number of profiles to process: ' num2str(length(prof2proc))]); 

acm = initialize_unselected_profile_structures(acm, prof2proc);
acm = void_short_profiles(acm, prof2proc, 'heading', meta.acm_nptsMin, -1);
acm = fcm_set_sensor_field_indices(acm, 'L0');
acm = fcm_set_processing_fields(acm, meta);  % also sets depID

%.. there are 3 like-named fields with confusion potential.
%.. .. acm.heading  DATA: contains profile heading data in units of degrees.
%.. ..              for null profiles not to be processed the field entry is
%.. ..              set to the empty set [].
%.. .. acm.header   MCLANE HEADER: contains text from the unpacked imported ascii
%.. ..              file identifying the variables in each column of data.
%.. .. meta.fcm_3dmp_header  FSI ACM HEADER: Unpacked fsi 3dmp files have the
%.. ..              3dmp informational file header appended to the data columns.
%
%.. copy fsi acm instrument header into the metadata file;
%.. it is identical for all profiles which do have actual acm data,
%.. therefore need to find such a file.
headingData = {acm.heading};  % profile heading data are elements of the cell array
tf_noData = cellfun('isempty', headingData);
idxData = find(~tf_noData, 1);
if isempty(idxData)
    error('FSI-ACM instrument header not found in any ''A'' files.');
end
inFilename = [meta.unpacked_data_folder 'A' num2str(idxData,'%7.7u') file_suffix];
meta = fcm_write_3dmp_header_to_struct(inFilename, meta);

for ii = prof2proc; acm(ii) = fcm_assign_fractional_seconds(acm(ii)); end

disp('SYNC:')
for ii = prof2proc; acm(ii) = fcm_sync_ctd(acm(ii), ctd_L1(ii)); end
disp('... sync done');
disp(' ');

disp('Begin mainstream processing 3DMP files.');
for ii = prof2proc; acm(ii) = fcm_beam2XYZ(acm(ii)); end
for ii = prof2proc; acm(ii) = fcm_wag_velocity(acm(ii)); end
for ii = prof2proc; acm(ii) = fcm_XYZ2ENU(acm(ii)); end
acm_L0 = acm;
disp('acm_L0 created.')

%.. NOW smooth to form L1 product.
for ii = prof2proc; acm(ii) = fcm_smooth(acm(ii), meta); end

%.. set L1 sensor_field_indices:
%.. .. (a) for processing with nan_bad_profile_sections
%.. .. (b) for making MPacm_L1 data product
acm = fcm_set_sensor_field_indices(acm, 'L1');
%.. this code suite assumes that pitch and roll are negligible:
for ii = prof2proc; acm(ii) = fcm_nan_velENU_extreme_tilt(acm(ii)); end
acm_L1 = acm;
for ii = prof2proc; acm(ii) = nan_bad_profile_sections(acm(ii)); end
acm_L1_Nand = acm;
[pr_min, binsize, pr_max] = determine_binning_parameters(acm, 'pressure');
%.. set L2 sensor_field_indices:
%.. .. (a) to determine which fields to bin
%.. .. (b) for making MPacm_L2 data product
acm = fcm_set_sensor_field_indices(acm, 'L2');
disp('  begin pressure binning acm profile data ...');
for ii = prof2proc
    acm(ii).heading = unwrap(deg2rad(acm(ii).heading));
    acm(ii) = pressure_bin_mmp_data(acm(ii), pr_min, binsize, pr_max);
    acm(ii).heading = mod(rad2deg(acm(ii).heading), 360);
end
disp('... processing done.');
acm_L2 = acm;
clear acm

%% ********* CREATE STRUCTURE-OF-ARRAYS DATA PRODUCTS' HEADER ******************
%.. calculate useful auxiliary parameters and put them into the
%.. lead structure MP_aux. Used in L0, L1, and L2 MPacm products.
MP_aux.Deployment_ID =  meta.deployment_ID;
MP_aux.Date_of_Processing = datestr(now);
%.. assign a time for each processed profile.
%..   these are derived from the median of the eng record timestamps because 
%..   the latter are present even when there are no valid pressure data and
%..   were transferred to all of the structure arrays.
profile_date = [acm_L2(prof2proc).profile_date];
%.. to help with deployment identification,
%.. write out first processed profile's number and date and time.
MP_aux.first_selected_profile_number = prof2proc(1);
MP_aux.first_selected_profile_date   =  datetime(datevec(profile_date(1)));
%.. profiles selected for processing and their (median) datenumbers
MP_aux.profiles_selected = prof2proc;
MP_aux.profile_date = profile_date;  % row vector

%% ********* CREATE SCALAR STRUCTURE-OF-ARRAYS L2 DATA PRODUCT *****************
%.. first output argument; the other structure-of-arrays data products will be
%.. constructed only if requested (code called with a second output argument). 
disp('Creating structure-of-arrays L2 data product.');
%.. save the acm binning information in simple scalar structure;
%.. start with section heading
MP_aux_acm.L2_Section = 'L2: BINNED DATA';
MP_aux_acm.acm_binning_parameters = [pr_min binsize pr_max];
MP_aux_acm.acm_pressure_bin_values = (pr_min:binsize:pr_max)';
MP_binned_acm = write_field_arrays_to_new_structure(acm_L2, 'binned_acm_', prof2proc);

MPacm_L2 = amalgamate_scalar_structures({MP_aux, MP_aux_acm, MP_binned_acm});
MPacm_L2.META = meta;
%.. all the binned data are present in the MPacm_L2 fields so labelled
%.. so that they can be plotted with a 'pcolor' variant;
%.. individual binned profile data are contained in the 'L2' structure array
%.. and it and the other data products are only available if a second output
%.. argument is given to trigger the saving of all data products.

%.. MP_binned_acm was constructed above *before* unbinned fields from the acm_L2
%.. structure array were removed so that the sensor field indices remained in 
%.. registration for the write_field_arrays_to_new structure call. 
%.. now get rid of extraneous fields in the L2 structure array.
acm_L2 = fcm_remove_fields_from_L2_data(acm_L2);
%%
if createMatfile
    %% ********** CREATE SCALAR STRUCTURE OF L1 ARRAYS ******************
    %.. create structures of NaN-padded ragged arrays before pressure binning.
    %.. the field arrays will have dimensions of max(npoints) x nprofiles
    disp('Creating structure-of-arrays L1 data product.');
    MP_L1_header.L1_Section = 'L1: PROCESSED, NOT BINNED';
    MP_acm_L1_Nand = write_field_arrays_to_new_structure(acm_L1_Nand, '', prof2proc);
%    MP_beam_mapping.beam_mapping = {acm_L1(prof2proc).beam_mapping};
    MPacm_L1 = amalgamate_scalar_structures({MP_aux, MP_L1_header, MP_acm_L1_Nand});
    MPacm_L1.META = meta;
    %% ********** CREATE SCALAR STRUCTURE OF L0 ARRAYS ******************
    disp('Creating structure-of-arrays L0 data product.');
    MP_L0_header.L0_Section = 'L0: UNPROCESSED DATA';
    MP_acm_L0_data = write_field_arrays_to_new_structure(acm_L0, '', prof2proc);
%    MP_beam_mapping.beam_mapping = {acm_L0(prof2proc).beam_mapping};
    MPacm_L0 = amalgamate_scalar_structures({MP_aux, MP_L0_header, MP_acm_L0_data});
    MPacm_L0.META = meta;   
    %% ******************** SAVE DATA PRODUCTS **************************
    fprintf('\nSaving final data products (could be minutes):\n');
    fprintf('%s\n', ['  Working directory is ' pwd]);

    %.. save options:
    %.. .. '-v6'  : fastest;  no compression, variables must be <2GB
    %.. .. '-v7'  : slower; uses compression, variables must be <2GB
    %.. .. '-v7.3': can be get a coffee slow, variables  can be >2GB
    saveVersion = '-v7.3';
    
    tic
    acm_matfilename = [meta.deployment_ID 'ACM__' datestr(now, 'yyyymmdd_HHMMSS') '.mat'];
    save(acm_matfilename,  'MPacm_L0', 'MPacm_L1', 'MPacm_L2',    ...
        'acm_L0',   'acm_L1',   'acm_L2',    ...
        'meta',                            ...
        saveVersion);
    fprintf('%s\n\n', ['  Saved to ' acm_matfilename]);
    timeS = toc;
    disp(['Elapsed time for ' saveVersion ' save operation: ' num2str(timeS) ' seconds.']);
    outfile = acm_matfilename;
end
data = MPacm_L2;
fprintf('\nNormal termination.\n\n\n\n\n');

