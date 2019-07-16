function [MPall, matfilename] = Process_McLane_WFP_Deployment(metadata_filename)
% radMMP version 2.00c (c = OOI Coastal) 
% RADesiderio, Oregon State University, 2019-07-16
%=========================================================================
% DESCRIPTION:
%    Processes a full deployment of McLane Profiler (version 5.00) CTD and ENG
%    data after the raw binary data have been extracted into 'C' and 'E' ASCII
%    files by the McLane Unpacker software V3.12.
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
%    The 'E' files contain ECO (fluorometer, backscatter) and QSP (PAR) data.
%    The 'A' files contain AD2CP (currentmeter) data.
%
% USAGE:
%
%    [MPall] = Process_McLane_WFP_Deployment('metadata_WFP010.txt');
%
%         No data products are saved in a matfile.
%
%    [MPall, matfilename] = Process_McLane_WFP_Deployment('metadata_WFP010.txt');
%
%         MPall and the other data products are saved in a matfile.
%
%
%    Before running this code from the working directory, prepare the contents
%    of the text file denoted by the calling argument metadata_filename by 
%    changing its entries to contain the processing information required to
%    process data from a deployment of a McLane profiler. Instructions on the
%    format of this text file are included in the sample txt file provided.
%
% INPUT:
%    The name of a metadata text file.
%    Refer to the USAGE section above.
%
% OUTPUT:
%    MPall - mimicking the structure of the same name used by a version
%            of the Toolebox with the GUI removed. different data arrays
%            can be output, however pressure-binned ctd, flr, and par
%            data will always be present as fields within MPall.
%
%            MPall is available via returned argument and may also be saved
%            in a matfile just before program completion.
%
%    matfilename - only if included in the output argument list, matfilename 
%                  will be the name of the saved matfile containing MPall and
%                  the structure arrays described below. the name is constructed
%                  from the 'depID' character string in the meta structure
%                  and the date (and possibly time near completion) of code
%                  execution.
%
%    Structure arrays: each element contains data from one profile.
%    These are available in the saved matfile only.
%
%        ctd_L0, eng_L0 - imported data on which to try different
%                         filtering, lagging, etc to eliminate hysteresis 
%                         in neighboring up-down pairs of profiles.
%
%        ctd_L1, eng_L1, 
%        flr_L1, par_L1 - processed profiles
%
%        ctd_L2, flr_L2, par_L2 - binned processed profile data
%                     
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
%   This code suite was written to provide a framework and tools to allow users
%   to easily import and visualize a WFP data set so that they can apply their
%   own quality control.
%
% NOTES
%    For McLane profiler version (5.00) using Unpacker V3.12 there are 2
%    binary choices for unpacking:
%        (a) data delimiters: comma separated or space padded columns
%        (b) whether to include: header and on and off date\time text rows
%    This code suite will work with any of the 4 possible formats.
%
%
%  The 0th (set-up) mclane profile is not processed. Therefore
%  when all files are processed, index number = profile number
%  (also true if there are missing profiles).
%
% REFERENCES
%
%   celltm.m:  coded by RADesiderio (<= 2005) from:
%   Morison, Andersen, Larson, D'Asaro, and Boyd. 1994. "The Correction
%   for Thermal-Lag Effects in Sea-Bird CTD Data". J. Atm. Oc. Tech. 11: 
%   1151-1164.
%
%   flo_bback_total.m: 
%   Translated into Matlab by RADesiderio from the python function 
%   flo_bback_total.py in the module flo_functions.py available from the OOI
%   repository https://github.com/oceanobservatories/ion-functions/blob/
%   master/ion_functions/data/. The python version was coded by C Wingard with
%   reference to the "Data Product Specification for Optical Backscatter (Red
%   Wavelengths)" Document Control Number 1341-00540 (version 1-05) 2014-05-28
%   at https://alfresco.oceanobservatories.org/ (See: Company Home >> OOI >>
%   Cyberinfrastructure >> Data Product Specifications >> 
%   1341-00540_Data_Product_SPEC_FLUBSCT_OOI.pdf).
%
%   GSW Toolbox (TEOS-10)
%   McDougall, T.J. and P.M. Barker, 2011: "Getting started with TEOS-10 and
%   the Gibbs Seawater (GSW) Oceanographic Toolbox", 28pp., SCOR/IAPSO WG127,
%   ISBN 978-0-646-55621-5.
%
%   oxsat_gg.m:  coded by RADesiderio (2004-12-08) from:
%   Garcia, Hernan E. and Gordon, Louis I. 1992. "Oxygen solubility
%   in seawater: Better fitting equations". Limnology and Oceanography,
%   37: 1307-1312.
%
%   sbefilter.m:  coded by RADesiderio (<= 2005) from an earlier version of: 
%   Seabird Scientific, 09/12/2017. "Seasoft V2: SBE Data Processing" Software
%   Manual revision 7.26.8. pp 101-102. 
%
%   Toolebox_shift.m:  with very slight modification, this routine is the same
%   as MP_shift from MPproc, McLane processing code from Gunnar Voet's GitHub
%   repository: 
%       https://github.com/modscripps/MPproc/blob/master/mpproc/MP_shift.m
%   It may have originally come from McLane processing code used and\or 
%   written by John Toole at Woods Hole.
%
% DEPENDENCIES
%   Matlab 2018b
%   Gibbs Sea Water Oceanographic Toolbox version 3.05
%
%   FUNCTIONS used by main code (alphabetical) with dependencies.
%       subroutines (excluding GSW toolbox routines) called by only
%       one function are appended to that function as noted.
%    
%.. add_ctd_timestamps
%       discard_degeneracy                (appended to add_ctd_timestamps)
%       select_longest_monotonic_run_mask (appended to add_ctd_timestamps)
%.. amalgamate_scalar_structures
%.. assign_profilenumbers_to_indices
%.. cat_sensorfields
%.. determine_binning_parameters 
%.. find_eng_backtrack_sections
%.. flag_eng_backtrack_sections
%.. import_C_sbe52
%.. import_E_mmp
%.. import_metadata
%.. import_OOI_calfiles
%.. nan_bad_profile_sections
%.. partition_eng
%.. pressure_bin_mmp_data
%.. process_bback
%       flo_bback_total                   (appended to process_bback)
%.. process_eng_sensors
%.. process_sbe43f
%       oxsat_gg                          (appended to process_sbe43f)
%       sbefilter
%       Toolebox_shift
%.. process_sbe52
%       TEOS-10 routines from GSW Toolbox
%       celltm                            (appended to process_sbe52)
%       sbefilter 
%       Toolebox_shift 
%.. sync_ctd_eng
%.. void_short_profiles
%.. write_field_arrays_to_new_structure
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%=========================================================================

disp('#################################################');
disp(['     ' mfilename]);
disp('#################################################');
disp(['Working directory is ' pwd]);

%% ******************* IMPORT PROCESSING PARAMETERS ***********************
if nargin~=1
    disp('USAGE: MPall = Process_McLane_WFP_Deployment_Function(metadata_filename)');
    error('This function must be called with one argument.');
end

if nargout<2
    createMatfile = false;
else
    createMatfile = true;
end

fprintf('\n   Processing %s\n\n', metadata_filename);
meta = import_metadata(metadata_filename);
import_OOI_calfiles  % imports sensor calcoeffs into structure meta 

prof2proc = meta.profiles_to_process;  % profile zero is not processed
disp(['Number of profiles to process: ' num2str(length(prof2proc))]); 
depID     = meta.deployment_ID;        % depID is prepended to saved matfilename

%% ******************* IMPORT ENG DATA FROM TEXT FILES ***********************
% backwards should be faster (the first iteration pre-allocates
%.. the array of structures)
disp('Begin importing engineering files.');

for ii = flip(prof2proc)
    Efilename = [meta.unpacked_data_folder 'E' num2str(ii,'%7.7u') '.TXT'];
    eng(ii) = import_E_mmp(Efilename); %#ok<*AGROW,*SAGROW>
    
end

%.. for profiles too short to be meaningful set pressure record to empty
%.. .. 3rd argument references minimum number of data points 
%.. .. 4th argument references minimum range of data
%.. do not use for_loop
eng = void_short_profiles(eng, 'pressure', ...
    meta.eng_pressure_nptsMin, meta.eng_pressure_rangeMin_db);

eng_L0 = eng;

%% ************* FIND BACKTRACK SECTIONS ****************
%.. the McLane profiler sets engineering pressure to 0 when the profiler
%.. is not yet profiling at the start, at the end just before the
%.. profiler stops moving (BUT NOT ALWAYS!) and in between if the
%.. profiler backtracks because it gets stuck.
for ii = flip(prof2proc)
    eng(ii) = find_eng_backtrack_sections(eng(ii), meta.eng_pressure_valueMin_db);
end

%.. list profiles with backtracking;
%.. note, sometimes these have just a slight hiccup at the start 
%.. and then cleanly profile.
idx = contains({eng(prof2proc).backtrack}, 'yes');
idx_backtrack = prof2proc(idx);
if isempty(idx_backtrack)
   text = ' None';
else
    text = num2str(idx_backtrack);
end    
fprintf('Profile numbers with backtracking:  %s\n\n', text);

%.. flag data in backtrack profiles 
%.. 3 options (switch value is set in the metadata.txt file):
%.. (1) flag entire profile as bad (RECOMMENDED unless user has examined data)
%.. (2) flag data good up to 1st backtrack encountered then bad 
%.. (3) flag as bad only backtrack pressure=0 sections.
idx = contains({eng(prof2proc).backtrack}, 'yes');
idx_backtrack = prof2proc(idx);

%.. for loop is not executed if idx_backtrack is empty
for ii = idx_backtrack
    eng(ii) = flag_eng_backtrack_sections(eng(ii), ...
        meta.backtrack_processing_flag);
end

%% *************** PROCESS ENG SENSOR DATA ************************
%.. does not remove any data nor nan out backtracks
for ii = flip(prof2proc)
    eng(ii) = process_eng_sensors(eng(ii), meta);
end

%% ******************* IMPORT CTD DATA FROM TEXT FILES ***********************
disp('Begin importing ctd files.');

for ii = flip(prof2proc)
    Cfilename = [meta.unpacked_data_folder 'C' num2str(ii,'%7.7u') '.TXT'];
    ctd(ii) = import_C_sbe52(Cfilename);
end

%.. for profiles too short to be meaningful set pressure record to empty
ctd = void_short_profiles(ctd, 'pressure', ...
    meta.ctd_pressure_nptsMin, meta.ctd_pressure_rangeMin_db);

%.. the function add_ctd_timestamps MUST BE RUN BEFORE CTD PRESSURE RECORD 
%.. PROCESSING; the eng and ctd pressure records are matched 'digitally'
%.. so that any filtering or shifting will invalidate the pressure
%.. matching algorithm used to determine the ctd timestamps.
disp('Begin adding ctd timestamps.');
%.. this routine can also append diagnostics to a file in the working
%.. directory, overwritten at each loop iteration
for ii = flip(prof2proc)
    ctd(ii) = add_ctd_timestamps(ctd(ii), eng(ii));
end

ctd_L0 = ctd;

%% **************** CLEAN CTD DATA ************************************

%.. THIS SECTION LEFT BLANK


%% *************** PROCESS THE CTD SENSOR DATA ************************
%.. filter, time shift, celltm, calculate derived products.
%.. apply calibrations; calcoeffs were imported into the structure meta
%.. at program top, but they haven't yet been applied.
%
%.. the user-selected binning parameters in meta are written into the 
%.. appropriate structure field

%.. a ctd profile mask is created on basis of ctd pressure record
for ii = prof2proc
    ctd(ii) = process_sbe52(ctd(ii), meta);
end

%.. the sbe43f oxygen sensor values are recorded in the ctd data stream
for ii = prof2proc
    ctd(ii) = process_sbe43f(ctd(ii), meta);
end

%% **** SYNCHRONIZE CTD AND ENG PROFILE MASKS AND PRESSURE RECORDS ****

%.. ctd profile masks were also determined based on the pressure record when
%.. processing the ctd sensor data. meld the eng and ctd masks.
%.. also transfer the processed ctd pressure and dP/dt record to eng.
for ii = flip(prof2proc)
    [ctd_L1(ii), eng(ii)] = sync_ctd_eng(ctd(ii), eng(ii));
end

%% **************** SPLIT OUT FLR AND PAR DATA *************************
%.. this is done after the profile masks have been established. the 
%.. partitioning routine to split out the flr and par data applies pressure
%.. offsets as determined by the distance from each sensor to the ctd pressure
%.. sensor.
[eng_L1, flr, par_L1] = partition_eng(eng);
%.. calculate backscatter coefficients from backscatter sensor measurements
%.. .. L1 in this code indicates that the data are processed but have not
%.. .. yet bin binned. the bback data product contained in flr_L1 is the
%.. .. OOI_L2 data product.
for ii = prof2proc
    flr_L1(ii) = process_bback(flr(ii), ctd_L1(ii), meta);
end

%% **************** CREATE BINNED ARRAYS **************************
%
%.. In this code 'L2' denotes that the structure array contains binned data.
%
%.. apply profile_masks to assign nans to stationary and backtrack data.
for ii = prof2proc
    ctd_L1_NaNd(ii) = nan_bad_profile_sections(ctd_L1(ii));
    flr_L1_NaNd(ii) = nan_bad_profile_sections(flr_L1(ii));
    par_L1_NaNd(ii) = nan_bad_profile_sections(par_L1(ii));
end

%.. ctd binning
[pr_min, binsize, pr_max] = ...
    determine_binning_parameters(ctd_L1_NaNd, 'pressure');
disp('Begin pressure binning ctd profile data');
for ii = prof2proc
    ctd_L2(ii) = pressure_bin_mmp_data(ctd_L1_NaNd(ii), pr_min, binsize, pr_max);
end
%.. save the ctd binning information in a simple scalar structure for
%.. later documentation
MP_aux_ctd.ctd_binning_parameters = [pr_min binsize pr_max];
MP_aux_ctd.ctd_pressure_bin_values = (pr_min:binsize:pr_max)';

%.. par and flr binning
[pr_min, binsize, pr_max] = ...
    determine_binning_parameters(par_L1_NaNd, 'pressure');
disp('Begin pressure binning par profile data');
for ii = prof2proc
    par_L2(ii) = pressure_bin_mmp_data(par_L1_NaNd(ii), pr_min, binsize, pr_max);
end

%.. save the par binning information in simple scalar structure for
%.. later documentation
MP_aux_par.par_binning_parameters = [pr_min binsize pr_max];
MP_aux_par.par_pressure_bin_values = (pr_min:binsize:pr_max)';

%.. use the par binning parameters for the flr data.
disp('Begin pressure binning flr profile data');
for ii = prof2proc
    flr_L2(ii) = pressure_bin_mmp_data(flr_L1_NaNd(ii), pr_min, binsize, pr_max);
end

%.. save the flr binning information in simple scalar structure for
%.. later documentation
MP_aux_flr.flr_binning_parameters = [pr_min binsize pr_max];
MP_aux_flr.flr_pressure_bin_values = (pr_min:binsize:pr_max)';

%*************************************************************
%% ********** CREATE SCALAR STRUCTURES OF RAW ARRAYS ******************

%.. one way of saving the raw data in MPall is to cat each profile variable 
%.. into one long column vector - in this case, no nan padding is needed.
%.. the advantage is that a survey scatter plot can be made. the program
%.. fastscatter, which mimics a scatter plot by using mesh, can be used
%.. to quickly plot (~ 1 sec) very large datasets (vectors of 3,000,000
%.. elements) as long as certain defaults are used.
CV_raw_ctd = cat_sensorfields(ctd_L0, 'vert', 'rawvec_ctd_');

%.. the x-axis for the scatter plots can either be time or the
%.. profile number. the profile numbers associated with each element
%.. of the concatenated column vectors are
CV_raw_ctd_indices.raw_ctd_profile_indices =  ...
    assign_profilenumbers_to_indices(ctd_L0(prof2proc), 'pressure');
%.. these indices are not added as a field to CV_raw_ctd because that 
%.. would put it last in its field ordering; in MPall, I want it to 
%.. come before all the CV_raw_ctd fields.

CV_raw_eng = cat_sensorfields(eng, 'vert', 'rawvec_eng_');
CV_raw_eng_indices.raw_eng_profile_indices =  ...
    assign_profilenumbers_to_indices(eng(prof2proc), 'pressure');

%*************************************************************
%% ****** CREATE SCALAR STRUCTURES OF L1 PROCESSED ARRAYS *****************
%.. create structures of arrays before pressure binning. two sets will be
%.. created, one of which will be written to the final MPall structure;
%.. the end-user can select the other, neither, or both by changing the
%.. calling arguments to the function amalgamate_scalar_structures.
%
%.. the field arrays in both sets will have dimensions of
%.. max(npoints) x nprofiles
%
%.. the 'notNand' designation means that the bad-profiling data sections
%.. have not been Nan'd out.
% % % MP_ctd_notNaNd = write_field_arrays_to_new_structure(ctd_L1, 'processed_ctd_');
% % % MP_flr_notNaNd = write_field_arrays_to_new_structure(flr_L1, 'processed_flr_');
% % % MP_par_notNaNd = write_field_arrays_to_new_structure(par_L1, 'processed_par_');

MP_ctd_Nand = write_field_arrays_to_new_structure(ctd_L1_NaNd, 'nan_processed_ctd_');
MP_flr_Nand = write_field_arrays_to_new_structure(flr_L1_NaNd, 'nan_processed_flr_');
MP_par_Nand = write_field_arrays_to_new_structure(par_L1_NaNd, 'nan_processed_par_');

%% ******* CREATE STRUCTURE OF ARRAYS FOR BINNED DATA ****************
MP_binned_ctd = cat_sensorfields(ctd_L2, 'horz', 'binned_ctd_');
MP_binned_flr = cat_sensorfields(flr_L2, 'horz', 'binned_flr_');
MP_binned_par = cat_sensorfields(par_L2, 'horz', 'binned_par_');

%% **** COMBINE SUBSIDIARY SCALAR STRUCTURES INTO ONE STRUCTURE MPall ****

%.. calculate useful auxiliary parameters and put them into the
%.. lead structure MP_aux.

MP_aux.Deployment_ID = depID;
MP_aux.Date_of_Processing = datestr(now);
%.. assign a time for each processed profile.
%..   the time records in the arrays of structures are still intact.
%..   use the median value found in each ctd profile. absent ctd 
%..   profiles will have entries of nan.
profile_datenumbers = cellfun(@nanmedian,{ctd_L2(prof2proc).time});
%.. to help with deployment identification,
%.. write out first processed profile's number and date and time.
MP_aux.first_selected_profile_number = prof2proc(1);
MP_aux.first_selected_profile_datetime = ... 
    datetime(datevec(profile_datenumbers(1)));
%.. profiles selected for processing and their (median) datenumbers
MP_aux.profiles_selected = prof2proc;
MP_aux.datenum = profile_datenumbers;  % row vector

%.. add headings to separate the sections in MPall;
%.. these lines depend upon the ordering of the calling arguments
%.. to the 'amalgamate' function following. When a new field is added
%.. to a matlab structure, it is appended as the last field.
MP_aux.L2_Section = 'L2: BINNED DATA';
MP_binned_par.L1_Section = 'L1: PROCESSED, NOT BINNED';
MP_par_Nand.L0_Section = 'L0: RAW DATA (use [fast]scatter.m)'; 

MPall = amalgamate_scalar_structures( {MP_aux, ...
    MP_aux_ctd, MP_binned_ctd,                 ...
    MP_aux_flr, MP_binned_flr,                 ... 
    MP_aux_par, MP_binned_par,                 ...
    MP_ctd_Nand,  MP_flr_Nand,  MP_par_Nand,   ...
    CV_raw_ctd_indices, CV_raw_ctd,            ...
    CV_raw_eng_indices, CV_raw_eng});
%.. add the meta structure containing the metadata used in the processing
%.. as the last field
MPall.META = meta;

%% ******************** SAVE DATA PRODUCTS **************************
if (createMatfile)
    fprintf('\nSaving final data products:\n');
    matfilename = [depID 'MMP__' datestr(now, 'yyyymmdd_HHMMSS')];
    %.. save optons:
    %.. .. '-v6'  : fastest;  no compression, variables must be <2GB
    %.. .. '-v7'  : slower; uses compression, variables must be <2GB
    %.. .. '-v7.3': can be get a coffee slow, variables  can be >2GB
    saveVersion = '-v6';
    %.. all the binned data are present in the MPall fields so labelled.
    %.. individual binned profiles are contained in the 'L2' structure arrays.
    %.. the meta structure is also saved as the last field in MPall.
    save(matfilename, 'MPall',  'meta',   ...
        'ctd_L0', 'eng_L0', ...
        'ctd_L1', 'eng_L1', ...
        'flr_L1', 'par_L1', ...
        'ctd_L2', 'flr_L2', 'par_L2', ...
        saveVersion);  

    fprintf('\n%s\n', ['Working directory is ' pwd]);
    fprintf('%s\n', ['Saved MPall and data structures to ' matfilename]);
else
    disp(' ');
    disp('Data products were not saved to a matfile.');
    disp('To activate this feature, rerun this code and include a second');
    disp('output argument which upon code completion will contain the name');
    disp('of the saved matfile.');
end
fprintf('\nNormal termination.\n');

