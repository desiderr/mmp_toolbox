function [para] = getWFPmetadata(mooring, deploymentNumber, profilerCoverage)
%=========================================================================
% DESCRIPTION
% (0,1) Provides OOI McLane profiler deployment metadata to the screen
% (2,3) Downloads OOI asset management metadata for the mmp_toolbox
%
% USAGE
%
%   0 input arguments:    getWFPmetadata
%      The mooring sites, their code names (eg, 'ce09ospm'), and locations are output to the screen.
%
%   1 input argument:     getWFPmetadata(sitecodename)
%      The start and stop dates of all the deployments at the sitecodename are output to screen.
%
%   2 input arguments:    para = getWFPmetadata(sitecodename, dep#)
%      If the specified mooring is at a one-profiler site, metadata from OOI asset
%      management required to run the profile-processing software are downloaded into the output 
%      structure para. If the specified site is a two-profiler one, use 3 input arguments as below.
% 
%   3 input arguments:    para = getWFPmetadata(sitecodename, dep#, profiler)
%      some sites have 2 profilers, one above the other. for these sites, use either profiler = 'upper' 
%      or 'lower' to specify which set of metadata are required.
%
% NOTES
%   The radMMP toolbox uses 'meta' as the name of the structure containing
%   the information imported from the metadata.txt file, so to avoid confusion
%   the name 'meta' should not be used for the output of getWFPmetadata.m, 
%   which will be used to populate the entries in the metadata.txt file.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2021-10-21: desiderio: original code
%.. 2021-11-04: desiderio:
%..             added nargout/nargin spec (code top) to prevent output for nargin == 0 or 1
%..             added nargout check for nargin == 2 or 3 in that section             
%.. 2021-12-02: desiderio: assigned para to be empty for 0 or 1 inputs
%.. 2022-01-12: desiderio: updated documentation
%=========================================================================

%%
if (nargout > 0  &&  nargin > 1) || (nargin < 2)
    para = struct.empty;
end

siteTable = [
""
"(Site Code)		OOI Mooring Name					Site Location"
""
"Global Arrays"
"(GA02HYPM)	Argentine Basin Profiler Mooring		42.9781°S, 42.4957°W"
"(GI02HYPM)	Irminger Sea Profiler Mooring			59.9695°N, 39.4886°W"
"(GP02HYPM)	Station Papa Profiler Mooring			50.0796°N, 144.806°W"
"(GS02HYPM)	Southern Ocean Profiler Mooring			54.4693°S, 89.3191°W"
""
"Coastal Endurance Array"
"(CE09OSPM)	Washington Offshore Profiler Mooring	46.8517°N, 124.982°W"
""
"Coastal Pioneer Array"
"(CP01CNPM)	Central Profiler Mooring				40.1340°N, 70.7708°W"
"(CP02PMCI)	Central Inshore Profiler Mooring		40.2267°N, 70.8782°W"
"(CP02PMCO)	Central Offshore Profiler Mooring		40.0963°N, 70.8789°W"
"(CP02PMUI)	Upstream Inshore Profiler Mooring		40.3649°N, 70.7700°W"
"(CP02PMUO)	Upstream Offshore Profiler Mooring		39.9394°N, 70.7708°W"
"(CP03ISPM)	Inshore Profiler Mooring				40.3620°N, 70.8785°W"
"(CP04OSPM)	Offshore Profiler Mooring				39.9365°N, 70.8802°W"
""
];

if nargin==0
    disp(char(siteTable));
    oneArgumentUsage = [
        ""
        "To see a listing of deployment dates as a function of deployment"
        "number at a particular site, run this code with one argument as:"
        ""
        "getWFPmetadata('CE09OSPM');"
        ""
        ];
    disp(char(oneArgumentUsage));
    return
end

%% code common to both nargin==1 and nargin==2,3
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

twoProfilerSites = [
    "ga02hypm" 
    "gp02hypm" 
    "gs02hypm"
    ];

oneProfilerSites = [
    "ce09ospm"
    "cp01cnpm"
    "cp02pmci"
    "cp02pmco"
    "cp02pmui"
    "cp02pmuo"
    "cp03ispm"
    "cp04ospm"
    "gi02hypm" 
    ];

mooring = lower(mooring);

if ~ismember(mooring, union(coastalSites, globalSites))
    disp(' ');
    disp(['Input "' mooring '" is not the (Site Code) name of an OOI WFP mooring.']);
    fprintf('Choose one from:\n\n\n');
    disp(char(siteTable));
    return
end

%.. url needed to access the _deploy.csv files in the OOI
%.. Asset Management oceanobservatories GitHub repository
urlForDeployFile = "https://raw.githubusercontent.com/oceanobservatories/asset-management/master/";

%.. for websaving
localFolder = [pwd '/'];

%.. download the deployment's deploy.csv file containing the metadata
deployCSVname = strcat(upper(mooring), '_Deploy.csv');
deployCSV = strcat(localFolder, deployCSVname);
websave(deployCSV, (strcat(urlForDeployFile, 'deployment/', deployCSVname)) );
%
fid = fopen(deployCSV);
D = textscan(fid,'%s','whitespace','','delimiter','\n');
fclose(fid);
%.. delete downloaded file from localFolder
delete(deployCSV);
D = D{1};  % unwrap
D = split(string(D), ',', 2);  % D is a 2D string array
%.. the rows    of D represent various instruments in the various deployments
%.. the columns of D represent various metadata variables (lat, lon, startDateTime, deploymentNumber, etc)

%% nargin==1 section
if nargin == 1
    
    %.. get the deployment dates for each deployment number by tracking profiler reference
    %.. designator row entries in the deploy.csv files. profiler rows are designated by 
    %.. entries containing 'WFP0x-00-WFPENG000', where
    %.. .. x = 1 for coastal profilers
    %.. .. x = 2 for the one single-profiler global site (irminger)
    %.. .. x = 2 and 3 for the double profiler (one upper, one lower) global sites
    match = {'WFP01-00-WFPENG000' 'WFP02-00-WFPENG000'};
    %.. find the reference designator column. first row is a header.
    tf_referenceDesignatorColumn = contains(D(1, :), 'Reference Designator');
    allRefDes = D(:, tf_referenceDesignatorColumn);
    tf_profilerRefDes = contains(allRefDes, match);
    %.. for global sites with 2 profilers, only the upper one is parsed for dates.
    profilerRows = D(tf_profilerRefDes, :);
    %.. now sort by deployment number in case file didn't start off sorted
    tf_deploymentColumn = contains(D(1, :), 'deploymentNumber');
    [~, idx] = sort(str2double(profilerRows(:, tf_deploymentColumn)));
    profilerRows = profilerRows(idx, :);
    
    deploymentNumbers = profilerRows(:, tf_deploymentColumn);
    %.. prepend a space to numbers < 10 to line up columns on output
    deploymentNumbers = " " + deploymentNumbers;
    deploymentNumbers = cellfun(@(x)x(end-1:end), deploymentNumbers, 'UniformOutput', false);
    
    startDateTime    = profilerRows(:, contains(D(1, :), 'startDateTime'));
    startDate        = cellfun(@(x)x(1:10), startDateTime, 'uni', 0);
    stopDateTime     = profilerRows(:, contains(D(1, :), 'stopDateTime'));
    
    tf_stillAtSea    =   strlength(stopDateTime) == 0;
    if any(tf_stillAtSea)
        stopDateTime(tf_stillAtSea) = "  AT SEA  ";
        messageAtSea = 'Recovered data are not available for deployments still at sea.';
    else
        messageAtSea = '';
    end

    stopDate         = cellfun(@(x)x(1:10), stopDateTime, 'uni', 0);
    
    disp(' ');
    disp(['Mooring: ' upper(mooring)]);
    disp('deployment   startDate    stopDate');
    
    for jj = 1:numel(deploymentNumbers)
        fprintf('    %s       %s   %s\n', ...
            deploymentNumbers{jj}, startDate{jj}, stopDate{jj});
    end
    fprintf('%s\n\n', messageAtSea);
    
    if ismember(mooring, twoProfilerSites)
        twoProfilerMessage = [
            "This mooring site deploys 2 profilers at the same time and location,"
            "one above the other. The user will need to request metadata from one of"
            "these profilers, either the 'upper' profiler or the 'lower' profiler"
            "(case-insensitive)."
            ""
            "For example, for the profilers for deployment # 3, use one of:"
            ""
            "info = getWFPmetadata('placeholder', 3, 'upper')"
            "info = getWFPmetadata('placeholder', 3, 'lower')"
            ""
            ];
        twoProfilerMessage = strrep(twoProfilerMessage, 'placeholder', upper(mooring));
        disp(char(twoProfilerMessage));
    elseif ismember(mooring, oneProfilerSites)
        oneProfilerMessage = [
            ""
            "To download the metadata into structure info for deployment number 4, use:"
            ""
            "info = getWFPmetadata('placeholder', 4)"
            ""
            ];
        oneProfilerMessage = strrep(oneProfilerMessage, 'placeholder', upper(mooring));
        disp(char(oneProfilerMessage));
    end
    return
end
%% nargin==2 and nargin==3 section
%.. structure's fieldnames
fieldName = {
    'profiler_type'
    'mooring'
    'deployment'
    'profiler_coverage'
    'latitude'
    'longitude'
    'start_date'
    'stop_date'
    'deployment_depth'
    'bottom_depth'
    'profiler_uid'
    'sensor_uid'
    'profiler_serial_number'
    'calfiles'
    'number_of_profiles'
    'working_directory'
    'tent_directory'
    'sitecode_folder_path'
    'deployment_folder_path'
    'binary_data_folder'
    'calibration_folder'
    'unpacked_data_folder'
    'wget_cmd_telemetered'
    'wget_cmd_recovered_wfp'
    };
nFields = length(fieldName);
%.. set fieldname order and initialize
for ii = 1:nFields
    para(1).(fieldName{ii}) = '';  % subscript is required when para is init as empty
end
%.. the structure's fieldName values will be populated by the entries 
%.. in cell array fieldValue using a for loop.
fieldValue(1:nFields, 1) = {''};

%.. the check for valid site code name has already been done.

%.. check that deployment number is valid.
%.. accept both text and numbers for deployment number; use numeric
deploymentNumber = str2double(num2str(deploymentNumber));
%.. parse the header for the deploymentNumber column
tf_deploymentColumn = contains(D(1, :), 'deploymentNumber');
deploymentNumbers = str2double(D(:, tf_deploymentColumn));
tf_deploymentRow = deploymentNumbers==deploymentNumber;
DeploymentData = D(tf_deploymentRow, :);
if isempty(DeploymentData)
    disp('Selected deployment number is out of range.');
    return
end

%.. check profilerCoverage settings as a function of user interaction
if nargin==2
    if ~ismember(mooring, oneProfilerSites)
        error('The input mooring requires selection of either the ''upper'' or ''lower'' profiler.')
    else
        profilerCoverage = 'whole';
    end
end
profilerCoverage = lower(profilerCoverage);
if ~ismember(profilerCoverage, {'upper' 'lower' 'whole'})
    disp('Valid inputs for 3rd argument (profilerCoverage) are ''upper'', ''lower'', and ''whole''.');
    disp('If 3rd argument is omitted, profilerCoverage is set to ''whole'' valid for single profiler sites.');
    error('Invalid value for the 3rd calling argument.');
end
%.. with those cases trapped out, do the general cases
if ismember(mooring, oneProfilerSites) && ~strcmpi(profilerCoverage, 'whole')
    error('oneProfilerSite moorings require selection of the default profilerCoverage value = ''whole''.');
elseif ismember(mooring, twoProfilerSites) && ~contains(profilerCoverage, {'upper' 'lower'})
    error('twoProfilerSite moorings require selection of either the ''upper'' or ''lower'' profiler.')
end

%.. select profiler reference designator keyed to mooring site
if ismember(mooring, coastalSites)
    refDesCoverage = 'WFP01';
    profiler_type  = 'coastal';
elseif strcmpi(mooring, 'gi02hypm')
    refDesCoverage = 'WFP02';
    profiler_type  = 'global';
elseif strcmpi(profilerCoverage, 'upper')
    refDesCoverage = 'WFP02';
    profiler_type  = 'global';
elseif strcmpi(profilerCoverage, 'lower')
    refDesCoverage = 'WFP03';
    profiler_type  = 'global';
else
    error('Could not determine appropriate profiler reference designator.');
end
%.. now that error checks are done, check that output argument was specified
if nargout == 0
    disp('WARNING! This routine must be run with an output argument during SetUp!')
end

fieldValue{1} = profiler_type;
fieldValue{2} = upper(mooring);
fieldValue{3} = deploymentNumber;
fieldValue{4} = profilerCoverage;

%.. narrow down DeploymentData by filtering against refDesCoverage
tf_referenceDesignatorColumn = contains(D(1, :), 'Reference Designator');
allRefDes = DeploymentData(:, tf_referenceDesignatorColumn);
tf_refDesCoverage = contains(allRefDes, refDesCoverage);
DeploymentData = DeploymentData(tf_refDesCoverage, :);

%.. find the lat and lon for this mooring's deployment
tf_latColumn = strcmpi(D(1, :), 'lat');
latitude  = DeploymentData{1, tf_latColumn};   % all row entries have lat
tf_lonColumn = strcmpi(D(1, :), 'lon');
longitude = DeploymentData{1, tf_lonColumn};
fieldValue{5} = latitude;
fieldValue{6} = longitude;

%.. start and stop dates
startDateTime    = DeploymentData(1, contains(D(1, :), 'startDateTime'));
startDate        = startDateTime{1}(1:10);
stopDateTime     = DeploymentData(1, contains(D(1, :), 'stopDateTime'));
if strlength(stopDateTime) == 0
    stopDate = '  AT SEA  ';
else
    stopDate     = stopDateTime{1}(1:10);
end
fieldValue{7} = startDate;
fieldValue{8} = stopDate;

%.. deployment and water depths
tf_Column = strcmpi(D(1, :), 'deployment_depth');
deployment_depth  = DeploymentData{1, tf_Column};
tf_Column = strcmpi(D(1, :), 'water_depth');
water_depth = DeploymentData{1, tf_Column};
fieldValue{9} = str2double(deployment_depth);
fieldValue{10} = str2double(water_depth);

%.. profiler (node) uid (OOI unique ID) column
tf_uidColumn = strcmpi(D(1, :), 'node.uid');
tf_profilerUID = contains(DeploymentData(:, tf_referenceDesignatorColumn), 'WFPENG');
profiler_uid = DeploymentData{tf_profilerUID, tf_uidColumn};
fieldValue{11} = profiler_uid;

%.. instrument (ctd, fluorescence, oxygen, etc) uids
tf_uidColumn = strcmpi(D(1, :), 'sensor.uid');
tf_sensorUID = contains(DeploymentData(:, tf_uidColumn), 'CGINS');
sensor_uid = DeploymentData(tf_sensorUID, tf_uidColumn);
fieldValue{12} = sensor_uid';

for jj = 1:nFields
    para.(fieldName{jj}) = fieldValue{jj};
end

end
