function [data, outfile] = Process_McLane_AD2CP_Deployment(mode, infile, newMetaFile)
% radMMP version 2.20c (c = OOI Coastal) 
% RADesiderio, Oregon State University, 2021-05-10
%=========================================================================
% DESCRIPTION
%    Processes McLane Profiler (version 5.00) AD2CP data after the raw
%    binary data have been extracted into 'A' ASCII files by the McLane 
%    Unpacker software V3.12. Both full dataset and OOI-decimated file
%    formats can be processed.
%
%    Process_McLane_WFP_Deployment.m must be run first so that its processed
%    CTD data can be used to add a CTD pressure record to the AD2CP data.
%
%    radMMP version 2.00c specifically processes OOI data
%    from the following 'Coastal' surface moorings:
%
%    CE09OSPM    CP01CNPM     CP02PMCI     CP02PMCO
%    CP02PMUI    CP02PMUO     CP03ISPM     CP04OSPM     
%
%    Instrumentation
%        CTDPF-K    SBE 52MP    (Seabird)
%        DOFST-K    SBE 43F     (Seabird)
%        FLORT-K    ECO triplet (Seabird\WETLabs)
%        PARAD-K    QSP-2200    (Biospherical)
%        VEL3D-K    AD2CP       (Nortek)
%
%    The 'C' files contain SBE52MP (CTD) and SBE43F (oxygen) data.
%    The 'E' files contain ECO (fluorescence, backscatter) and QSP (PAR) data.
%    The 'A' files contain AD2CP (currentmeter) data.
%
% USAGE:  Also, see NOTES for typical processing sequences.
%
%  [data, <outfile>] = Process_McLane_AD2CP_Deployment(mode, infile, <newMetaFile>);
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
%       [data, <acm_matfilename>] = Process_McLane_AD2CP_Deployment('import_and_process', mmp_matfilename, <newMetaFile>)
%
%       INPUT:
%          mode = 'import_and_process' 
%          mmp_matfilename must come from the 2nd output argument from a run of Process_McLane_WFP_Deployment and contain
%              the structure array ctd_L1 and a scalar structure meta containing the processing parameters used in that
%              code run.
%          newMetaFile, if present, must be a valid metadata text file with the same general format as used to calculate
%              the data products saved in mmp_matfilename but may have different acm settings.
%
%       OUTPUT:
%          data = MPacm_L2, a scalar structure whose fields are 2D arrays of binned acm data suitable for 'pcolor' viewing.
%          acm_matfilename, if present, would contain the name of the saved matfile containing all of the acm data products:
%              acm_L0, acm_L1, acm_L2 are structure arrays of L0, L1, and L2 data, one array element for each profile:
%                  acm_L0 contains unprocessed but 'dealt' data (ie, data are contained in descriptively named structure fields);
%                  acm_L1 contains the data just before binning; 
%                  acm_L2 contains binned data.
%              MPacm_L0, a scalar structure of NaN-padded ragged 2D arrays of L0 data (number of columns = number of profiles).           
%              MPacm_L1, a scalar structure of NaN-padded ragged 2D arrays of L1 data.          
%              MPacm_L2, the scalar structure of binned acm data as described above.           
%
%
%    MODE (2): 'import'  (note that the 'import' INPUT arguments are identical to those for mode 'import_and_process')
%
%       [data, <aqd_matfilename>] = Process_McLane_AD2CP_Deployment('import', mmp_matfilename, <newMetaFile>)
%
%       INPUT:
%          mode = 'import' 
%          mmp_matfilename must come from the 2nd output argument from a run of Process_McLane_WFP_Deployment and contain
%              the structure array ctd_L1 and a scalar structure meta containing the processing parameters used in that code run.
%          newMetaFile, if present, must be a valid metadata text file with the same general format as used to calculate
%              the data products saved in mmp_matfilename but may have different acm settings.
%
%       OUTPUT:
%          data = aqd, a structure array containing undealt imported data in the 'imported_data' fields.
%          aqd_matfilename, if present, would contain the name of the saved matfile containing all of the variables necessary
%                           (aqd, ctd_L1, meta) to process the data by running this code in 'process' mode.
%
%
%    MODE (3): 'process'  (note that the 'process' OUTPUT arguments are identical to those for mode 'import_and_process')
%
%       [data, <acm_matfilename>] = Process_McLane_AD2CP_Deployment('process', aqd_matfilename, <newMetaFile>)
%
%       INPUT:
%          mode = 'process' 
%          aqd_matfilename must come from the 2nd output argument from a run of this code in 'import' mode which will contain
%              the structure arrays aqd and ctd_L1 and a scalar structure meta containing the processing parameters used in
%              that code run.
%          newMetaFile, if present, must be a valid metadata text file with the same general format as used to calculate the
%              data products saved in aqd_matfilename but may have different acm settings.
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
%   The deployment's CTD and ENG data must be processed before the AD2CP. A
%   typical sequence of code calls is therefore:
%
%      [MPall, MMPX_matfilename] = Process_McLane_WFP_Deployment('metadata.txt');
%      [MPacm_L2, <acmDataFileName>] = Process_McLane_AD2CP_Deployment('import_and_process', MMPX_matfilename, <'newMetadata.txt'>);   
%
%      The 'newMetadata.txt' file, if included, could tell the code to look in a different folder for
%      the unpacked 'A' files than specified in 'metadata.txt', or, could contain different aqd processing
%      parameters.
%
%   Importing 'A' files can take many minutes. In addition, to QC the AD2CP data will require much user
%   intervention and re-processing. For these reasons the 'import' and 'process' modes were implemented.
%   In this scenario the AD2CP data are imported and saved along with the supplementary data needed to
%   finish its processing (ctd_L1 and meta):
%
%      [MPall, MMPX_matfilename] = Process_McLane_WFP_Deployment('metadata.txt');
%      [aqd, mportdName] = Process_McLane_AD2CP_Deployment('import', MMPX_matfilename, <'newMetadata.txt'>);   
%
%      Now that the imported (but not 'dealt') data are contained in the aqd structure array saved in
%      mportdName (along with ctd_L1 and meta), re-processing (with old or new metadata files as desired)
%      can proceed with any number of runs without having to re-import the data:
%
%      [MPacm_L2, <acmDataFileName>] = Process_McLane_AD2CP_Deployment('process', mportdName);   
%                                    and/or        
%      [MPacm_L2, <acmDataFileName>] = Process_McLane_AD2CP_Deployment('process', mportdName, 'newMetadata01.txt');   
%                                    and/or        
%      [MPacm_L2, <acmDataFileName>] = Process_McLane_AD2CP_Deployment('process', mportdName, 'newMetadata02.txt'));   
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
%    the data products. Three versions have been tested:
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
%   Depending on the size of the dataset, I do not recommend using '-v7.3'
%   unless running overnight. The alternative is to process the deployment
%   in smaller chunks as can be done by setting the profiles_to_process
%   vector in the metadata.txt file to a lower number of profiles.
%
% DEPENDENCIES
%   Matlab 2018b
%
%   FUNCTIONS used by main code (alphabetical) with dependencies.
%    
%.. amalgamate_scalar_structures
%.. aqd_beam2XYZ
%.. aqd_deal_A_ad2cp
%       aqd_deal_ad2cp_full_dataset
%       aqd_deal_ad2cp_OOI_decimated_dataset
%.. aqd_hpr_interpolation
%.. aqd_import_A_ad2cp
%.. aqd_phase_ambiguity_correction
%.. aqd_remove_fields_from_L2_data
%.. aqd_set_processing_fields
%.. aqd_set_sensor_field_indices
%.. aqd_sync_ctd
%.. aqd_wag_velocity
%.. aqd_XYZ2ENU
%.. determine_binning_parameters
%.. import_metadata
%.. initialize_unselected_profile_structures
%.. nan_bad_profile_sections
%.. pressure_bin_mmp_data
%.. void_short_profiles
%.. write_field_arrays_to_new_structure
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
% REVISION HISTORY:
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-01-30: desiderio:
%..             (a) set L0 sensor_field_indices before void_short_profiles
%..             (b) re-did assignment statements so that structure array 
%..                 elements corresponding to profiles not to be processed
%..                 retain initialized field values created by
%..                 void_short_profiles
%.. 2020-02-08: desiderio:
%..             excised profiles not selected to be processed (nan-filled) from MPacm fields
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%.. 2021-05-08: desiderio: changed how the date of profile values are determined
%.. 2021-05-21: desiderio:
%..             (a) fixed case of no 'A' files found
%..             (b) added radMMP version info to structure arrays
%..             (c) added radMMP version info to structure of arrays data product
%.. 2021-05-10: desiderio: radMMP version 2.20c (OOI coastal)
%=========================================================================
%%
radMMPversion = '2.20c';
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
%.. so that if only plots using MPacm_l2 are desired won't have to wait for the
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
    if isempty(listing{1})
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
        disp('Begin importing $$$DECIMATED$$$ ad2cp files ...');
    else
        disp('Begin importing $$$FULL DATASET$$$ ad2cp files ...');
    end
    disp(' ');
    tic
    for ii = meta.profiles_to_process
        Afilename = [meta.unpacked_data_folder 'A' num2str(ii,'%7.7u') file_suffix];
        aqd(ii) = aqd_import_A_ad2cp(Afilename); %#ok<*AGROW,*SAGROW>
    end
    disp('... import done.');
    toc
else  % re-entry processing (mode = 'process')
    %.. load variables saved from a previous run of this code 
    %.. when mode was set to 'import'
    fprintf('\nLoading variables from re-entry file %s ...\n', infile); 
    load(infile, 'aqd', 'ctd_L1', 'meta');
    disp('... load done');
    if ~isempty(newMeta), meta = newMeta; end
end

if ~contains(mode, 'process')
    data = aqd;       % return data (not dealt into field names)
    if createMatfile  % save data for re-entry processing
        outfile = [meta.deployment_ID 'imported_acm__' ...
            datestr(now, 'yyyymmdd_HHMMSS')];
        disp(['Saving data into re-entry file ' outfile ' ...']);
        save(outfile, 'aqd', 'ctd_L1', 'meta', '-v6');
        disp('... save done');
    end
    return
end

%% **************************** PROCESSING ***********************************
prof2proc = meta.profiles_to_process;
disp(['Number of profiles to process: ' num2str(length(prof2proc))]); 
disp('DEAL:');
aqd = aqd_deal_A_ad2cp(aqd, prof2proc);
disp('... deal done');

aqd = initialize_unselected_profile_structures(aqd, prof2proc);
aqd = void_short_profiles(aqd, prof2proc, 'heading', meta.acm_nptsMin, -1);
aqd = aqd_set_sensor_field_indices(aqd, 'L0');
aqd = aqd_set_processing_fields(aqd, meta);  % also sets depID

disp('SYNC:')
for ii = prof2proc; aqd(ii) = aqd_sync_ctd(aqd(ii), ctd_L1(ii)); end
disp('... sync done');
disp(' ');

[aqd.radMMP_version] = deal(radMMPversion);
acm_L0 = aqd;
disp('acm_L0 created.')

disp('Begin mainstream processing AD2CP files.');
%.. heading is unwrapped before interpolation then wrapped afterwards
for ii = prof2proc; aqd(ii) = aqd_hpr_interpolation(aqd(ii)); end
for ii = prof2proc; aqd(ii) = aqd_phase_ambiguity_correction(aqd(ii)); end
for ii = prof2proc; aqd(ii) = aqd_beam2XYZ(aqd(ii)); end
for ii = prof2proc; aqd(ii) = aqd_wag_velocity(aqd(ii)); end
for ii = prof2proc; aqd(ii) = aqd_XYZ2ENU(aqd(ii)); end

%.. set L1 sensor_field_indices:
%.. .. (a) for processing with nan_bad_profile_sections
%.. .. (b) for making MPacm_L1 data product
aqd = aqd_set_sensor_field_indices(aqd, 'L1');
acm_L1 = aqd;
for ii = prof2proc; aqd(ii) = nan_bad_profile_sections(aqd(ii)); end
acm_L1_Nand = aqd;
[pr_min, binsize, pr_max] = determine_binning_parameters(aqd, 'pressure');
%.. set L2 sensor_field_indices:
%.. .. (a) to determine which fields to bin
%.. .. (b) for making MPacm_L2 data product
aqd = aqd_set_sensor_field_indices(aqd, 'L2');
disp('  begin pressure binning aqd profile data ...');
for ii = prof2proc
    aqd(ii).heading = unwrap(deg2rad(aqd(ii).heading));
    aqd(ii) = pressure_bin_mmp_data(aqd(ii), pr_min, binsize, pr_max);
    aqd(ii).heading = mod(rad2deg(aqd(ii).heading), 360);
end
disp('... processing done.');
acm_L2 = aqd;
clear aqd

%% ********* CREATE STRUCTURE-OF-ARRAYS DATA PRODUCTS' HEADER ******************
MP_aux.radMMP_version = radMMPversion;
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
MP_aux.first_selected_profile_date   = datetime(datevec(profile_date(1)));
%.. profiles selected for processing and their (median) datenumbers
MP_aux.profiles_selected = prof2proc;
MP_aux.profile_date = profile_date;  % row vector

%% ********* CREATE SCALAR STRUCTURE-OF-ARRAYS L2 DATA PRODUCT *****************
%.. first output argument; the other structure-of-arrays data products will be
%.. constructed only if requested (code called with a second output argument). 
disp('Creating structure-of-arrays L2 data product.');
%.. save the aqd binning information in simple scalar structure;
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
acm_L2 = aqd_remove_fields_from_L2_data(acm_L2);
%%
if createMatfile
    %% ********** CREATE SCALAR STRUCTURE OF L1 ARRAYS ******************
    %.. create structures of NaN-padded ragged arrays before pressure binning.
    %.. the field arrays will have dimensions of max(npoints) x nprofiles
    disp('Creating structure-of-arrays L1 data product.');
    MP_L1_header.L1_Section = 'L1: PROCESSED, NOT BINNED';
    MP_acm_L1_Nand = write_field_arrays_to_new_structure(acm_L1_Nand, '', prof2proc);
    MP_beam_mapping.beam_mapping = {acm_L1(prof2proc).beam_mapping};
    MPacm_L1 = amalgamate_scalar_structures({MP_aux, MP_L1_header, MP_acm_L1_Nand, MP_beam_mapping});
    MPacm_L1.META = meta;
    %% ********** CREATE SCALAR STRUCTURE OF L0 ARRAYS ******************
    disp('Creating structure-of-arrays L0 data product.');
    MP_L0_header.L0_Section = 'L0: UNPROCESSED DATA';
    MP_acm_L0_data = write_field_arrays_to_new_structure(acm_L0, '', prof2proc);
    MP_beam_mapping.beam_mapping = {acm_L0(prof2proc).beam_mapping};
    MPacm_L0 = amalgamate_scalar_structures({MP_aux, MP_L0_header, MP_acm_L0_data, MP_beam_mapping});
    MPacm_L0.META = meta;   
    %% ******************** SAVE DATA PRODUCTS **************************
    fprintf('\nSaving final data products (could be minutes):\n');
    fprintf('%s\n', ['  Working directory is ' pwd]);

    %.. save options:
    %.. .. '-v6'  : fastest;  no compression, variables must be <2GB
    %.. .. '-v7'  : slower; uses compression, variables must be <2GB
    %.. .. '-v7.3': can be get a coffee slow, variables  can be >2GB
    saveVersion = '-v7';
    
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

