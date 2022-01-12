function [calFileName] = getMcLaneCalFiles(mooring, deployment, localFolder)
%.. desiderio: 18-nov-2019: original code
%.. desiderio: 09-apr-2020: updated URLs to 'oceanobservatories'
%.. desiderio: 15-may-2021: added diagnostics when no caldate before deployment date.
%..                         (error found in OOI Asset Management).
%.. desiderio: 29-may-2021: combined coastal and global versions.
%
%.. For a given mooring site and deployment number, this code downloads the
%.. applicable calfiles from OOI Asset Management to a user-specified local
%.. folder.
%
%.. INPUT
%..   mooring    : character vector or string (eg 'GP02HYPM' or "GP02HYPM")
%..   deployment : character vector, string, or numeric (eg '00003' "00003" or 3) 
%..   localFolder: character vector or string (eg 'C:\data\Papa\2015')
%..
%.. OUTPUT
%..   calFileName: string array of the calfilenames denoting which calfiles
%..                have been downloaded to the localFolder
%..
%.. USAGE
%..      clist = getMcLaneCalFiles('GP02HYPM', 3, 'C:\data\Papa\2015');
%
%.. NOTE: as of 29-May-2021, there is still an error in OOI Asset 
%..       Management which will cause this code to through a Warning:
%..       CP02PMUO, deployment 4, DOFSTK problem, the only calfile
%..       on asset management for DOFSTK SN 2500 has a caldate AFTER
%..       the startDate of this deployment.

%.. coastal instrumentation requiring calfiles: DOFSTK, FLORTK, PARADK 
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

%.. global instrumentation requiring calfiles: FLORDL 
globalSites = [
    "ga02hypm" 
    "gi02hypm" 
    "gp02hypm" 
    "gs02hypm"
    ];

%.. figure out sensor suite
if ismember(strtrim(lower(mooring)), coastalSites)
    refDes = [
        "WFP01-02-DOFSTK"
        "WFP01-04-FLORTK"
        "WFP01-05-PARADK"
        ];
elseif ismember(strtrim(lower(mooring)), "gi02hypm")
    %.. Irminger has only one profiler
    refDes = "WFP02-01-FLORDL";
elseif ismember(strtrim(lower(mooring)), globalSites)
    %.. all other global sites have two profilers;
    %.. WFP02 is upper profiler, WFP03 is lower
    refDes = [
        "WFP02-01-FLORDL"
        "WFP03-01-FLORDL"
        ];
else
    fprintf('\n\n');
    disp([char(mooring) ' is neither a costal nor a global MMP site.'])
    error('Check inputs.');
end

%.. add a delimiter to the end of input localFolder in case one wasn't entered
localFolder = char(localFolder);  % in case it's a string or cell
if localFolder(end)~='/' && localFolder(end)~='\'
    if ispc
        localFolder(end+1) = '\';
    else
        localFolder(end+1) = '/';
    end
end
localFolder = string(localFolder);

%.. set deployment number
deployment = str2num(string(deployment));  %#ok

%.. urls needed to access html file(s) (to get a folder's file listing) and
%.. the files themselves in the 'calibration' and\or 'deployment' folders in
%.. the OOI Asset Management oceanobservatories GitHub repository
urlForHTML = "https://github.com/oceanobservatories/asset-management/tree/master/";
urlForFile = "https://raw.githubusercontent.com/oceanobservatories/asset-management/master/";

%.. download the deployment's deploy.csv file so that the instrument serial
%.. numbers and date of deployment can be determined.
deployCSVname = strcat(upper(mooring), '_Deploy.csv');
deployCSV = strcat(localFolder, deployCSVname);
websave(deployCSV, (strcat(urlForFile, 'deployment/', deployCSVname)) );
%
fid = fopen(deployCSV);
D = textscan(fid,'%s','whitespace','','delimiter','\n');
fclose(fid);
%.. delete downloaded file from localFolder
delete(deployCSV);

D = D{1};                      % unwrap 
D = split(string(D), ',', 2);  % D is a 2D string array 

%.. get a deployment's information by parsing the header for its deployment number
tf_deploymentColumn = contains(D(1, :), 'deploymentNumber');
deploymentNumbers = str2double(D(:, tf_deploymentColumn));
tf_deploymentRow = deploymentNumbers==deployment;
DeploymentData = D(tf_deploymentRow, :); 

%.. get deployment date
tf_startDateTime = contains(D(1, :), 'startDateTime');  % parse the header
startDateTime = DeploymentData(1, tf_startDateTime);  
%.. convert to 'yyyymmdd'; use {} to get at string scalar's characters
startDate = startDateTime{1}([1:4 6:7 9:10]);

%.. get the reference designator column
tf_referenceDesignatorColumn = contains(D(1, :), 'Reference Designator');
allRefDes = DeploymentData(:, tf_referenceDesignatorColumn);

%.. get sensor uids for this particular deployment
tf_sensorUIDColumn = contains(D(1, :), 'sensor.uid');
allSensors = DeploymentData(:, tf_sensorUIDColumn);  % from just the one deployment
%.. pre-allocate
calFileName(1:length(refDes), 1) = "";  % in case instrument not deployed

%.. find and download the calfiles for the specified deployment
for ii = 1:length(refDes)
    
    sensor = refDes{ii}(end-5:end);
    sensorHTML = strcat(localFolder, sensor, '.html');

    tf_sensor = contains(allSensors, sensor);
    tf_refDes = contains(allRefDes,  refDes(ii));
    if sum(tf_sensor & tf_refDes)==0
        calFileName(ii) = strcat(sensor, ":  Not Deployed");
        continue 
    end
    
    sensorUID = allSensors(tf_sensor & tf_refDes);  % UID for the iith instrument
    
    %.. get calfile listing from the html for the directory containing cals
    websave(sensorHTML, strcat(urlForHTML, 'calibration/', sensor) );
    fid = fopen(sensorHTML);
    C = textscan(fid,'%s','whitespace','','delimiter','\n');
    fclose(fid);
    C = C{1};  % unwrap
    
    %.. select rows that have the sensorUID in them
    tf_serialNumber = contains(C, sensorUID);
    C = C(tf_serialNumber);
    %.. the calfilenames generally show up 3 times in each row. parse for the
    %.. second one (the href entry), because it is the filename on the server.
    C = split(C, 'href="', 2);
    C = C(:, 2);  % the second piece of the above split contains the href entry
    C = split(C, '"', 2);
    C = C(:, 1);  % first piece of the above split contains the href entry
    C = split(C, {'/' '\'}, 2);
    C = sort(C(:, end));  % do a sort to be sure they are in chronological order
    %.. C now has all the calfilenames for this sensor in a cell array
    
    %.. get the relevant cal - the latest cal before the startDate
    calDates = cellfun(@(x)x(21:28), C, 'uni', false);
    %.. all calfiles should have been renamed with the vendor caldate;
    %.. just in case some survived with the deployment date, use >=
    idx_cal = find(startDate >= string(calDates), 1, 'last');
    if isempty(idx_cal)
        disp(' ')
        disp('WARNING: ***********************************************')
        disp(['There are no cals for ' char(sensorUID)  ...
            ' before the deployment date ' char(startDate) '.'])
        disp('Caldates:')
        disp(string(calDates));
        disp('WARNING: ***********************************************')
        disp(' ')
        error('See warning diagnostics.')
    end
    calFileName(ii) = string(C(idx_cal));
    %.. and download file to folder specified in argument list
    websave(strcat(localFolder, calFileName(ii)), ...
            strcat(urlForFile,  'calibration/', sensor, '/', calFileName(ii)) );
    %.. delete html file on localFolder
    delete(sensorHTML);
end
%.. write out checks 
disp(strcat(upper(mooring), '_', num2str(deployment, '%5.5u'), ":  startDate ", ...
    startDateTime));

if numel(calFileName)==2
    disp([calFileName ["upper"; "lower"]]);
else
    disp(calFileName);
    disp(' ')
end
