function [para, metafilename] = xferMetadataToFile(para, identifyingText)
%=========================================================================
% DESCRIPTION
%   Transfers metadata downloaded from OOI Asset Management residing in
%   a scalar structure to a metadata text file for mmp_toolbox processing.
%
% USAGE:  [para, metafilename] = xferMetadataToFile(para, identifyingText)
%
%   INPUT
%     para = a scalar structure created by getWFPmetadata.m and further
%            added to by running programs in a getting started sequence.
%     identifyingText [optional] = is copied to the deployment_ID setting in the
%                                  created metadata text file named metafilename,
%                                  and is also used in naming this file. See 
%                                  NOTES section.
%
%   OUTPUT
%     para  = a scalar structure with additional fields populated to facilitate
%             transfer of the metadata to the metadata text file.
%     metafilename = name of the metadata text file containing information from a
%                    metadata file template and from para. This is a calling
%                    argument of the MAIN mmp_toolbox processing functions. 
%                    See NOTES section.
%
% NOTES
%   If xferMetadataToFile is called with identifyingText set to '' (empty) then:
%      metafilename   = 'metadata.txt'
%      CE matfilename = 'MMP__yyyymmdd_hhmmss.mat'  (CE MAIN processing output)
%      A  matfilename = 'ACM__yyyymmdd_hhmmss.mat'  (A  MAIN processing output)
%         where yyyymmdd_hhmmss is the execution date_time of the corresponding MAIN
%
%   If xferMetadataToFile is called with only one argument, para, then:
%      identifyingText is set equal to 'WFP_xxxc_' where:  
%         xxx = %3.3u denoting deployment number
%         c   = profiler coverage, which will be
%         'A' for above (upper water column global profilers) 
%         'B' for below (lower water column global profilers)
%         ''  (empty, no character) for all others.
%      
%   In all cases the value for identifyingText will be prepended to the 3 filenames above. 
%
%   It is expected that deployments from different mooring sites will be processed in
%   separate folder structures underneath the "tent" folder. Deployments from the same
%   mooring site are often processed together and concatenated to provide a long time
%   series of data at that site. This is the rationale for including the deployment number
%   but not the mooring site in the default settings for identifyingText.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2021-11-09: desiderio: initial code
%.. 2022-01-12: desiderio: added documentation
%=========================================================================

outfilePath = para.deployment_folder_path;

mutableSetting = {
    'profiler_type'
    'deployment_ID'            % prepended to saved data matfilenames
    'latitude'
    'longitude'
    'unpacked_data_folder'
    'calibration_folder'
    'fluorometer_calfilename'  % coastal and global
    'oxygen_calfilename'       % coastal only
    'par_calfilename'          % coastal only
    'number_of_profiles'
    };

globalSites = [
    "ga02hypm" 
    "gi02hypm" 
    "gp02hypm" 
    "gs02hypm"
    ];
coastalSites = [
    "ce09ospm"
    "cp01cnpm"
    "cp02pmci"
    "cp02pmco"
    "cp02pmui"
    "cp02pmuo"
    "cp03ispm"
    "cp04ospm"
    ];
sitecode = [globalSites; coastalSites];

if ~contains(para.mooring, sitecode, 'IgnoreCase', true)
    error('Input structure does not contain valid mooring sitecode.');
else
    templateFilename = ['metadata_template_' upper(para.mooring) '.txt'];
    templateFile = which(templateFilename);
    if isempty(templateFile)
        msg = ['Could not find ' templateFilename ', can''t create metadata.txt file.'];
        error(msg);
    end
end

if nargin==1  % construct
    coverage = '';
    if strcmpi(para.profiler_coverage, 'upper'), coverage = 'A'; end
    if strcmpi(para.profiler_coverage, 'lower'), coverage = 'B'; end
    identifyingText = ['WFP_' num2str(para.deployment, '%3.3u') coverage '_'];
end
metafilename = 'metadata.txt';
metafilename = [identifyingText metafilename];
para.deployment_ID = identifyingText;


% PREP SECTION FOR CALFILES
% 
%.. add calfilename fields to input structure to fit in with xfer forloop scheme
%.. .. initialize as empty in case a scheduled instrument was not deployed
para.fluorometer_calfilename = '';
para.oxygen_calfilename      = '';
para.par_calfilename         = '';
%
tf_flrCal = contains(para.calfiles, 'flor', 'ignorecase', true);
if any(tf_flrCal)
    para.fluorometer_calfilename = char(para.calfiles(tf_flrCal));
end
tf_oxyCal = contains(para.calfiles, 'dofst', 'ignorecase', true);
if any(tf_oxyCal)
    para.oxygen_calfilename = char(para.calfiles(tf_oxyCal));
end
tf_parCal = contains(para.calfiles, 'parad', 'ignorecase', true);
if any(tf_parCal)
    para.par_calfilename = char(para.calfiles(tf_parCal));
end

% PREP SECTION FOR INTERNAL SITE-DEPENDENT ENTRIES
%.. ce09ospm: sensor offset depths changed in 2017
if strcmpi(para.mooring, 'ce09ospm')
%.. auxiliary instrument pressure offsets changed for the ce09ospm mooring only
%     Spring 2017 and earlier used the shorter body.
%     Fall   2017 and later   used the longer body.
    mutableSetting = [mutableSetting;                  ...
                      {'currentmeter_depth_offset_m'}; ...
                      {'fluorometer_depth_offset_m'};  ...
                      {'par_depth_offset_m'};          ...
                      ];
    changeover = "2017-07-15";
    if string(para.start_date) < changeover
        para.currentmeter_depth_offset_m = -0.34;
        para.fluorometer_depth_offset_m  = -0.22;
        para.par_depth_offset_m          = -0.84;
    else
        para.currentmeter_depth_offset_m = -0.46;
        para.fluorometer_depth_offset_m  = -0.34;
        para.par_depth_offset_m          = -0.96;
    end
end
%
%.. ga02hypm, gp02hypm, gs02hypm: 
%.. pressure binning limits for upper and lower profilers 
if strcmpi(para.profiler_coverage, 'upper')
    mutableSetting = [mutableSetting;               ...
                      {'ctd_binning_parameters'};   ...
                      {'eng_binning_parameters'};   ...
                      {'acm_binning_parameters'};   ...
                      ];
    binmin = '0';
    binmax = num2str(ceil(0.01 * para.deployment_depth) * 100);    % round up to nearest 100
    para.ctd_binning_parameters = ['[' binmin '  2 ' binmax ']'];  %  2 db (meter) bins
    para.eng_binning_parameters = ['[' binmin ' 10 ' binmax ']'];  % 10 db (meter) bins
    para.acm_binning_parameters = ['[' binmin '  5 ' binmax ']'];  %  5 db (meter) bins
elseif strcmpi(para.profiler_coverage, 'lower')
    mutableSetting = [mutableSetting;               ...
                      {'ctd_binning_parameters'};   ...
                      {'eng_binning_parameters'};   ...
                      {'acm_binning_parameters'};   ...
                      ];
    binmin = num2str(ceil(0.01 * (para.deployment_depth-5)/2) * 100);
    binmax = num2str(ceil(0.01 * para.deployment_depth) * 100);
    para.ctd_binning_parameters = ['[' binmin '  2 ' binmax ']'];  %  2 db (meter) bins
    para.eng_binning_parameters = ['[' binmin ' 10 ' binmax ']'];  % 10 db (meter) bins
    para.acm_binning_parameters = ['[' binmin '  5 ' binmax ']'];  %  5 db (meter) bins
end


fid = fopen(templateFile, 'rt');
if fid < 0
    msg = ['Open failed on ' templateFile ', can''t create metadata.txt file.'];
    error(msg);
end
C = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
fclose(fid);
C=strtrim(C{1});

%.. step through each line of the template text file.
%.. .. global file templates should have neither oxygen nor par calfilename entries
%.. .. even if they do, the toolbox global processing code will ignore them.
for ii = 1:numel(C)
    if isempty(C{ii}) || strncmp(C{ii}, '%', 1)
        continue
    end
    match = C{ii}(1:strfind(C{ii}, '='));
    %.. get rid of insignificant white space before the equal sign
    match = strtrim(match(1:end-1));
    if contains(match, mutableSetting)
        if isempty(para.(match))        % for calfilename entries when sensor not deployed
            C{ii} = [match ' = '''''];  % writes out ... = ''
        else
            C{ii} = [match ' = ' num2str(para.(match))];
        end
    else
        continue
    end
end
 
%.. write out
metafilename = [outfilePath metafilename];
fid = fopen(metafilename, 'w');
for jj = 1:numel(C)
    fprintf(fid, '%s\r\n', C{jj});
end
fclose(fid);
