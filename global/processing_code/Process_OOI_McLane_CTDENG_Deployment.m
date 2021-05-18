function [MMP, matfilename] = Process_OOI_McLane_CTDENG_Deployment(metadata_filename)
% radMMP version 3.10
% RADesiderio, Oregon State University, 2021-05-14
%=========================================================================
% DESCRIPTION:
%    Processes a full deployment of McLane Profiler (version 5.00) CTD and ENG data
%                FROM BOTH COASTAL AND GLOBAL OOI SURFACE MOORINGS
%    after the raw binary data have been extracted into 'C' and 'E' ASCII files by
%    the McLane Unpacker software using either V3.10 or V3.12. It appears that these
%    files unpacked by V3.13.5 are also compatible.
%
%                   'COASTAL' surface moorings:
%        CE09OSPM    CP01CNPM     CP02PMCI     CP02PMCO
%        CP02PMUI    CP02PMUO     CP03ISPM     CP04OSPM     
%                         Instrumentation
%              CTDPF-K    SBE 52MP    (Seabird)
%              DOFST-K    SBE 43F     (Seabird)
%              FLORT-K    ECO triplet (Seabird\WETLabs)
%              PARAD-K    QSP-2200    (Biospherical)
%
%              VEL3D-K    AD2CP       (Nortek) [not processed by this function]
%
%        The 'C' files contain Seabird SBE52MP (CTD) and SBE43F (oxygen) data.
%        The 'E' files contain ECO (fluorometer, backscatter) and QSP (PAR) data.
%        The 'A' files contain AD2CP (currentmeter) data.
%
%
%                   'GLOBAL' surface moorings:
%        GA02HYPM    GI02HYPM     GP02HYPM     GS02HYPM
%                         Instrumentation
%              CTDPF-L    SBE 52MP    (Seabird)
%              DOSTA-L    4330        (Aanderaa)    
%              FLORD-L    FLBBRTD     (Seabird\WETLabs)
%
%              VEL3D-L    FSI-ACM     (FSI) [not processed by this function]
%
%        The 'C' files contain Seabird SBE52MP (CTD) data.
%        The 'E' files contain FLBBRTD (fluorometer, backscatter) and 4330 (oxygen) data.
%        The 'A' files contain FSI-ACM (currentmeter) data.
%
% USAGE:
%
%    [MMP] = Process_OOI_McLane_CTDENG_Deployment('metadata_WFP010.txt');
%
%         No data products are saved in a matfile.
%
%    [MMP, matfilename] = Process_OOI_McLane_CTDENG_Deployment('metadata_WFP010.txt');
%
%         MMP and the other data products are saved in a matfile.
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
%    MMP - mimics a structure variable called MPall used by a version
%            of the Toolebox with the GUI removed. different data arrays
%            can be output, however pressure-binned ctd, O2, and flr
%            data will always be present as fields within MMP.
%
%            MMP is available via returned argument and may also be saved
%            in a matfile just before program completion.
%
%    matfilename - only if included in the output argument list, matfilename 
%                  will be the name of the saved matfile containing MMP and
%                  the structure arrays described below. the name is constructed
%                  from the 'depID' character string in the meta structure
%                  and the date and time of code execution.
%
%    Structure arrays: each element in a structure array contains data
%    from one profile. These are available in the saved matfile only. The
%    L0, L1, and L2 processing level designations differ from those used
%    by OOI:
%
%        imported data with no processing (except that very short profiles
%        are discarded and timestamps are added to CTD files):
%                ctd_L0, eng_L0 
%
%        L0 profiles processed using default settings are designated L1:
%                ctd_L1, eng_L1, flr_L1
%                par_L1 (coastal only)
%                oxy_L1 (global only)
%
%        binned L1 profile data are designated L2:
%                ctd_L2, flr_L2
%                par_L2 (coastal only)
%                oxy_L2 (global only)
%
%        The coastal oxygen data are acquired on the ctd time base and are
%        therefore in the ctd structure arrays.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
%   This code suite was written to provide a framework and tools to allow users
%   to easily import and visualize a WFP data set so that they can apply their
%   own quality control.
%
% NOTES
%    For McLane profiler version (5.00) using Unpacker V3.10 and V3.12 there
%    are 3 choices for unpacking:
%        (a) add a prefix to unpacked files: DO NOT USE THIS OPTION
%        (b) data delimiters: comma separated or space padded columns
%        (c) whether or not to include header and on\off date\time text rows
%    This code suite will work with files unpacked by any combination of 
%    choices selected for options (b) and (c). 
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
%   do2_salinity_correction.m:
%   Translated into Matlab by RADesiderio from the python function
%   do2_salinity_correction.py in the module do2_functions.py available 
%   from the OOI repository https://github.com/oceanobservatories/
%   ion-functions/blob/master/ion_functions/data/. The python version was
%   coded by S Pearce with reference to "Data Product Specification for
%   Oxygen Concentration from Stable Instruments. Document Control Number
%   1341-00520 at https://alfresco.oceanobservatories.org/ (See: Company
%   Home >> OOI >> Cyberinfrastructure >> Data Product Specifications >>
%   1341-00520_Data_Product_SPEC_DOXYGEN_OOI.pdf)
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
%   Matlab 2018b or later
%   Gibbs Sea Water Oceanographic Toolbox version 3.05
%
%   FUNCTIONS called by main code (alphabetical) with dependencies.
%       subroutines (excluding GSW toolbox routines) that are called 
%       by only one function are appended to that function as noted.
%    
%.. add_ctd_timestamps
%       discard_degeneracy                (appended to add_ctd_timestamps)
%       select_longest_monotonic_run_mask (appended to add_ctd_timestamps)
%       sbefilter                         (stand alone)
%.. amalgamate_scalar_structures
%.. apply_eng_calibrations
%.. assign_profilenumbers_to_indices
%.. cat_sensorfields
%.. determine_binning_parameters 
%.. find_eng_backtrack_sections
%.. flag_eng_backtrack_sections
%.. import_C_sbe52
%.. import_E_mmp_coastal
%.. import_E_mmp_global
%.. import_metadata
%.. import_OOI_calfiles
%.. initialize_unselected_profile_structures
%.. nan_bad_profile_sections
%.. partition_eng
%.. pressure_bin_mmp_data
%.. process_bback
%       flo_bback_total                   (appended to process_bback)
%.. process_eng_aanderaa_optode
%       do2_salinity_correction           (appended to process_eng_aanderaa_optode)
%.. process_sbe43f
%       oxsat_gg                          (appended to process_sbe43f)
%       sbefilter                         (stand alone)
%       Toolebox_shift                    (stand alone)
%.. process_sbe52
%       TEOS-10 routines from GSW Toolbox
%       sbefilter                         (stand alone) 
%       Toolebox_shift                    (stand alone) 
%.. sync_ctd_eng
%.. void_short_profiles
%.. write_field_arrays_to_new_structure
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-01-30: desiderio: 
%..             (a) use eng_L0 to generate MMP rawvec eng data
%..             (b) put sss_L? assignment statements that were previously generated
%..                 index-by-index inside a prof2proc forLoop AFTER the loop
%..                 as sss_L?=sss, so that sss_L? array elements representing profiles 
%..                 not selected would not have their fields re-initialized to [].
%.. 2020-02-04: desiderio: incorporated initialize_unselected_profile_structures.m
%.. 2020-02-08: desiderio: excised profiles not selected to be processed (nan-filled)
%..                        from MMP fields
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-03-04: desiderio: changed the coastal code to work on global data 
%.. 2020-03-31: desiderio: combined coastal and global versions into one; renamed
%..                        it to differentiate it from coastal versions
%.. 2020-05-04: desiderio: radMMP version 3.00 (OOI coastal and global)
%.. 2021-05-12: desiderio: changed how the date of profile values are determined
%.. 2021-05-13: desiderio:
%..             (a) removed profile_mask and sensor_field_indices fields 
%..                 from final L2 structure arrays
%..             (b) added radMMP version info to structure arrays
%..             (c) added radMMP version info to structure of arrays data product
%.. 2021-05-14: desiderio: radMMP version 3.10 (OOI coastal and global)
%=========================================================================
radMMPversion = '3.10';
disp('#################################################');
disp(['     ' mfilename ' ' radMMPversion]);
disp('#################################################');
disp(['Working directory is ' pwd]);

%% ******************* IMPORT PROCESSING PARAMETERS ***********************
if nargin~=1
    disp(['USAGE: MMP = ' mfilename '(metadata_filename)']);
    error('This function must be called with one argument.');
end

if nargout<2
    createMatfile = false;
else
    createMatfile = true;
end

fprintf('\n   Processing %s\n\n', metadata_filename);
meta = import_metadata(metadata_filename);
allowedProfilerTypes = {'coastal' 'global'};
try
    profilerType = lower(meta.profiler_type);
    if ~contains(profilerType, allowedProfilerTypes)
        error('OOI meta.profiler_type must be either ''coastal'' or ''global''.');
    elseif strcmp(profilerType, 'coastal')
        auxSensor = 'par';
        gamma_for_ctd_timestamps = 0.00;
    elseif strcmp(profilerType, 'global')
        auxSensor = 'oxy';
        gamma_for_ctd_timestamps = 0.25;
    end
catch
    error('OOI meta.profiler_type (either ''coastal'' or ''global'') was not specified in input meta_text file.');
end
%.. import sensor calcoeffs into structure meta.
%.. although profiler type information is available in the meta field as above,
%.. expose the function's profiler type dependency with a calling argument 
meta = import_OOI_calfiles(meta, profilerType);

prof2proc = meta.profiles_to_process;  % profile zero is not processed
disp(['Number of profiles to process: ' num2str(length(prof2proc))]); 
depID     = meta.deployment_ID;        % depID is prepended to saved matfilename

%% ******************* IMPORT ENG DATA FROM TEXT FILES ***********************
%.. backwards might be faster (the first iteration pre-allocates
%.. the array of structures)
disp('Begin importing engineering files.');
if     strcmp(profilerType, 'coastal')
    for ii = flip(prof2proc)
        Efilename = [meta.unpacked_data_folder 'E' num2str(ii,'%7.7u') '.TXT'];
        eng(ii) = import_E_mmp_coastal(Efilename); %#ok<*AGROW,*SAGROW>
    end
elseif strcmp(profilerType, 'global')
    for ii = flip(prof2proc)
        Efilename = [meta.unpacked_data_folder 'E' num2str(ii,'%7.7u') '.TXT'];
        eng(ii) = import_E_mmp_global(Efilename);  %#ok<*AGROW,*SAGROW>
    end
else
    error('Unknown profilerType.');
end

eng = initialize_unselected_profile_structures(eng, prof2proc);
%.. set deployment_ID field in each structure array element
[eng.deployment_ID] = deal(depID);

%.. for profiles too short to be meaningful set pressure record to empty
%.. .. 4th argument references minimum number of data points 
%.. .. 5th argument references minimum range of data
%.. do not use for_loop
eng = void_short_profiles(eng, prof2proc, 'pressure', ...
    meta.eng_pressure_nptsMin, meta.eng_pressure_rangeMin_db);

[eng.radMMP_version] = deal(radMMPversion);
eng_L0 = eng;

%% ************* FIND BACKTRACK SECTIONS ****************
%.. the McLane profiler sets engineering pressure to 0 when the profiler
%.. is not yet profiling at the start, at the end just before the
%.. profiler stops moving (BUT NOT ALWAYS!) and in between if the
%.. profiler backtracks because it got stuck.
for ii = prof2proc
    eng(ii) = find_eng_backtrack_sections(eng(ii), meta.eng_pressure_valueMin_db);
end

%.. list profiles with backtracking;
%.. note, sometimes these have just a slight hiccup at the start 
%.. and then cleanly profile.
idx = contains({eng(prof2proc).backtrack}, 'yes');
idx_backtrack = prof2proc(idx);
fprintf('Number of profiles with backtracking:  ');
if isempty(idx_backtrack)
    fprintf('None\n\n');
else
    fprintf('%u\n', length(idx_backtrack));
    
    text = num2str(idx_backtrack);
    fprintf('profile numbers with backtracking:  %s\n\n', text);
end    

%.. flag data in backtrack profiles 
%.. 3 options (switch value is set in the metadata.txt file):
%.. (1) flag entire profile as bad
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
for ii = prof2proc
    eng(ii) = apply_eng_calibrations(eng(ii), meta, profilerType);
end

%% ******************* IMPORT CTD DATA FROM TEXT FILES ***********************
disp('Begin importing ctd files.');

for ii = flip(prof2proc)
    Cfilename = [meta.unpacked_data_folder 'C' num2str(ii,'%7.7u') '.TXT'];
    ctd(ii) = import_C_sbe52(Cfilename);
end
ctd = initialize_unselected_profile_structures(ctd, prof2proc);
%.. set deployment_ID field in each structure array element
[ctd.deployment_ID] = deal(depID);

%.. for global profilers the oxygen data are in the eng data stream, not ctd.
if strcmp(profilerType, 'global')
    ctd = rmfield(ctd, 'oxygen');  % delete oxygen field (all values are 0)
    %.. the sensor fields to be processed are contiguous, so delete last sfi index
    sfi = ctd(1).sensor_field_indices;
    sfi(end) = [];
    [ctd.sensor_field_indices] = deal(sfi);
end

%.. for profiles too short to be meaningful set pressure record to empty.
%.. void_short_profiles uses the sensor field indices values so that for
%.. global profiler data these are set by the preceding conditional block.
ctd = void_short_profiles(ctd, prof2proc, 'pressure', ...
    meta.ctd_pressure_nptsMin, meta.ctd_pressure_rangeMin_db);

%.. the function add_ctd_timestamps MUST BE RUN BEFORE CTD PRESSURE RECORD 
%.. PROCESSING; the eng and ctd pressure records are matched 'digitally'
%.. so that any filtering or shifting will invalidate the pressure
%.. matching algorithm used to determine the ctd timestamps.
disp('Begin adding ctd timestamps.');
%.. this routine has the capability to write diagnostics to a file in the working
%.. directory, appending at each loop iteration, if the appropriate sections in
%.. its source code are uncommented.
for ii = prof2proc
    ctd(ii) = add_ctd_timestamps(ctd(ii), eng(ii), gamma_for_ctd_timestamps);
end
[ctd.radMMP_version] = deal(radMMPversion);
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

%.. a ctd profile mask is created on basis of ctd pressure record;
%.. data points associated with logical true values are good.
for ii = prof2proc
    ctd(ii) = process_sbe52(ctd(ii), meta);
end

%.. for coastal profilers the sbe43f oxygen data are in the ctd data stream
if strcmp(profilerType, 'coastal')
    for ii = prof2proc
        ctd(ii) = process_sbe43f(ctd(ii), meta);
    end
end
%% **** SYNCHRONIZE CTD AND ENG PROFILE MASKS AND PRESSURE RECORDS ****

%.. ctd profile masks were also determined based on the pressure record when
%.. processing the ctd sensor data. meld the eng and ctd masks.
%.. also transfer the processed ctd pressure and dP/dt record to eng.
for ii = prof2proc
    [ctd(ii), eng(ii)] = sync_ctd_eng(ctd(ii), eng(ii));
end

%.. the oxygen data are in the eng data stream on OOI global profilers
ctd_L1 = ctd;
%% **************** SPLIT OUT FLR AND "AUX" DATA *************************
%.................. coastal: aux == par
%..................  global: aux == oxy
%.. this is done after profile masks have been established. the partitioning
%.. routine to split out the flr and aux data applies pressure offsets as
%.. determined by the distance from each sensor to the ctd pressure sensor.
[eng, flr, aux] = partition_eng(eng, profilerType);
%.. calculate backscatter coefficients from backscatter sensor measurements
%.. .. L1 in this code indicates that the data are processed but have not
%.. .. yet bin binned. the bback data product contained in flr_L1 is the
%.. .. OOI_L2 data product.
for ii = prof2proc
    flr(ii) = process_bback(flr(ii), ctd_L1(ii), meta);
end

if strcmp(profilerType, 'global')
    %.. the aanderaa oxygen sensor values are recorded in the eng data stream;
    %.. the oxy data product contained in oxy_L1 is the OOI_L2 data product.
    for ii = prof2proc
        aux(ii) = process_eng_aanderaa_optode(aux(ii), ctd_L1(ii), meta);
    end
end

eng_L1 = eng;
flr_L1 = flr;
aux_L1 = aux;  %#ok
%.. for creating the L1 structure arrays that will be saved to the matfile:
%.. .. coastal: par_L1 = aux;
%.. ..  global: oxy_L1 = aux;
expression = [auxSensor '_L1 = aux;'];
eval(expression);
%% **************** CREATE BINNED ARRAYS **************************
%
%.. In this code 'L2' denotes that the structure array contains binned data.
%
%.. apply profile_masks to assign nans to stationary and backtrack data.
for ii = prof2proc
    ctd(ii) = nan_bad_profile_sections(ctd(ii));
    flr(ii) = nan_bad_profile_sections(flr(ii));
    aux(ii) = nan_bad_profile_sections(aux(ii));
end
ctd_L1_NaNd = ctd;
flr_L1_NaNd = flr;
aux_L1_NaNd = aux;

%.. ctd binning
[pr_min, binsize, pr_max] = ...
    determine_binning_parameters(ctd, 'pressure');
disp('Begin pressure binning ctd profile data');
for ii = prof2proc
    ctd(ii) = pressure_bin_mmp_data(ctd(ii), pr_min, binsize, pr_max);
end
ctd_L2 = ctd;
%.. save the ctd binning information in a simple scalar structure for
%.. later documentation
MP_doc_ctd.ctd_binning_parameters  = [pr_min binsize pr_max];
MP_doc_ctd.ctd_pressure_bin_values = (pr_min:binsize:pr_max)';

%.. flr binning
[pr_min, binsize, pr_max] = ...
    determine_binning_parameters(flr, 'pressure');
disp('Begin pressure binning flr profile data');
for ii = prof2proc
    flr(ii) = pressure_bin_mmp_data(flr(ii), pr_min, binsize, pr_max);
end
flr_L2 = flr;
%.. save the flr binning information in simple scalar structure for
%.. later documentation
MP_doc_flr.flr_binning_parameters  = [pr_min binsize pr_max];
MP_doc_flr.flr_pressure_bin_values = (pr_min:binsize:pr_max)';

%.. aux binning; use the flr binning parameters for the aux data.
disp(['Begin pressure binning aux (' auxSensor ') profile data']);
for ii = prof2proc
    aux(ii) = pressure_bin_mmp_data(aux(ii), pr_min, binsize, pr_max);
end
aux_L2 = aux;
%.. create L2 structure arrays for saving to the matfile:
%.. .. coastal: par_L2 = aux;
%.. ..  global: oxy_L2 = aux;
expression = [auxSensor '_L2 = aux;'];
eval(expression);
%.. save the aux binning information in simple scalar structure for
%.. later documentation
MP_doc_aux.([auxSensor '_binning_parameters'])  = [pr_min binsize pr_max];
MP_doc_aux.([auxSensor '_pressure_bin_values']) = (pr_min:binsize:pr_max)';

%*************************************************************
%% ********** CREATE SCALAR STRUCTURES OF RAW (L0) ARRAYS *****************

%.. one way of saving the raw data in MMP is to cat each profile variable 
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
%.. would put it last in its field ordering; in MMP, I want it to 
%.. come before all the CV_raw_ctd fields.

CV_raw_eng = cat_sensorfields(eng_L0, 'vert', 'rawvec_eng_');
CV_raw_eng_indices.raw_eng_profile_indices =  ...
    assign_profilenumbers_to_indices(eng_L0(prof2proc), 'pressure');

%*************************************************************
%% ****** CREATE SCALAR STRUCTURES OF L1 PROCESSED ARRAYS *****************
%.. create structures of arrays before pressure binning. two sets will be
%.. created, one of which will be written to the final MMP structure;
%.. the end-user can select the other, neither, or both by changing the
%.. calling arguments to the function amalgamate_scalar_structures.
%
%.. the field arrays in both sets will have dimensions of
%.. max(npoints) x nprofiles
%
%.. .. NOTE for coastal and global data processing:
%.. The names of the auxiliary array data products ('par or 'oxy') only
%.. need to be used in the documentation text (2nd calling argument), and
%.. are not needed in the names of the actual data product structures.
%
% % %.. the 'notNand' designation means that the bad-profiling data sections
% % %.. as specified by the profile masks have not been Nan'd out.
% % MP_ctd_notNaNd = write_field_arrays_to_new_structure(ctd_L1, 'processed_ctd_', prof2proc);
% % MP_flr_notNaNd = write_field_arrays_to_new_structure(flr_L1, 'processed_flr_', prof2proc);
% % MP_aux_notNaNd = write_field_arrays_to_new_structure(aux_L1, ['processed_' auxSensor '_'], prof2proc);

MP_ctd_NaNd = write_field_arrays_to_new_structure(ctd_L1_NaNd, 'nan_processed_ctd_', prof2proc);
MP_flr_NaNd = write_field_arrays_to_new_structure(flr_L1_NaNd, 'nan_processed_flr_', prof2proc);
MP_aux_NaNd = write_field_arrays_to_new_structure(aux_L1_NaNd, ['nan_processed_' auxSensor '_'], prof2proc);

%% ******* CREATE STRUCTURE OF ARRAYS FOR BINNED DATA ****************
MP_binned_ctd = cat_sensorfields(ctd_L2, 'horz', 'binned_ctd_');
MP_binned_flr = cat_sensorfields(flr_L2, 'horz', 'binned_flr_');
MP_binned_aux = cat_sensorfields(aux_L2, 'horz', ['binned_' auxSensor '_']);

%% **** COMBINE SUBSIDIARY SCALAR STRUCTURES INTO ONE STRUCTURE MMP ****

%.. calculate useful auxiliary parameters and put them into the
%.. lead structure MP_doc.

MP_doc.Deployment_ID = depID;
MP_doc.Date_of_Processing = datestr(now);
%.. assign a time for each processed profile.
%..   these are derived from the median of the eng record timestamps because 
%..   the latter are present even when there are no valid pressure data and
%..   were transferred to all of the structure arrays.
profile_date = [ctd_L2(prof2proc).profile_date];
%.. to help with deployment identification,
%.. write out first processed profile's number and date and time.
MP_doc.first_selected_profile_number = prof2proc(1);
MP_doc.first_selected_profile_date   = datetime(datevec(profile_date(1)));
%.. profiles selected for processing and their (median) datenumbers
MP_doc.profiles_selected = prof2proc;
MP_doc.profile_date = profile_date;  % row vector

%.. add headings to separate the sections in MMP;
%.. these lines depend upon the ordering of the calling arguments
%.. to the 'amalgamate' function following. When a new field is added
%.. to a matlab structure, it is appended as the last field.
MP_doc.L2_Section        = 'L2: BINNED DATA';
MP_binned_aux.L1_Section = 'L1: PROCESSED, NOT BINNED (use [fast]scatter.m)';
MP_aux_NaNd.L0_Section   = 'L0: RAW DATA (use [fast]scatter.m)'; 

MMP = amalgamate_scalar_structures( {MP_doc;          ...
    MP_doc_ctd; MP_binned_ctd;                        ...
    MP_doc_flr; MP_binned_flr;                        ...
    MP_doc_aux; MP_binned_aux;                        ...                 
    %MP_ctd_notNaNd;  MP_flr_notNaNd;  MP_aux_notNaNd; ...
    MP_ctd_NaNd;  MP_flr_NaNd;  MP_aux_NaNd;          ...
    CV_raw_ctd_indices; CV_raw_ctd;                   ...
    CV_raw_eng_indices; CV_raw_eng});
%.. add the meta structure containing the metadata used in the processing
%.. as the next field
MMP.META = meta;
MMP.radMMP_version = radMMPversion;

%.. remove empty L0 fields (derived products)
MMP = rmfield(MMP, {'rawvec_eng_dpdt' 'rawvec_ctd_dpdt' 'rawvec_ctd_theta' ...
    'rawvec_ctd_sigma_theta' 'rawvec_ctd_salinity'});

ctd_L2 = rmfield(ctd_L2, {'profile_mask' 'sensor_field_indices'});
flr_L2 = rmfield(flr_L2, {'profile_mask' 'sensor_field_indices'});
aux_L2 = rmfield(aux_L2, {'profile_mask' 'sensor_field_indices'});  %#ok
expression = [auxSensor '_L2 = aux_L2;'];
eval(expression);
%% ******************** SAVE DATA PRODUCTS **************************
if (createMatfile)
    fprintf('\nSaving final data products:\n');
    matfilename = [depID 'MMP__' datestr(now, 'yyyymmdd_HHMMSS')];
    %.. save options:
    %.. .. '-v6'  : fastest;  no compression, variables must be <2GB
    %.. .. '-v7'  : slower; uses compression, variables must be <2GB
    %.. .. '-v7.3': can be get a coffee slow, variables  can be >2GB
    saveVersion = '-v6';
    %.. all the binned data are present in the MMP fields so labelled.
    %.. individual binned profiles are contained in the 'L2' structure arrays.
    %.. the meta structure is also saved as the last field in MMP.
    save(matfilename, 'MMP',  'meta',         ...
        'ctd_L0', 'ctd_L1', 'ctd_L2',         ...
        'eng_L0', 'eng_L1',                   ...
        'flr_L1', 'flr_L2',                   ...
        [auxSensor '_L1'], [auxSensor '_L2'], ...
        saveVersion);  

    fprintf('\n%s\n', ['Working directory is ' pwd]);
    fprintf('%s\n', ['Saved MMP and data structures to ' matfilename]);
else
    disp(' ');
    disp('Data products were not saved to a matfile.');
    disp('To activate this feature, rerun this code and include a second');
    disp('output argument which upon code completion will contain the name');
    disp('of the saved matfile.');
end
fprintf('\nNormal termination.\n\n\n');

