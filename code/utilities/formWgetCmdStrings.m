function [sss] = formWgetCmdStrings(sss)
%=========================================================================
% DESCRIPTION
%   creates wget command strings for downloading raw binary OOI McLane
%   profiler data files from the OOI Raw DataArchive
%
% USAGE:  [sss] = formWgetCmdStrings(sss)
%
%   INPUT
%     sss  = a scalar structure with appropriately named fields created
%            by getWFPmetadata.m and populated by setUpFolderStructure.m
%
%   OUTPUT
%     sss  = a scalar structure with the following fields populated:
%            wget_cmd_telemetered          [character vector]
%            sss.wget_cmd_recovered_wfp    [character vector]
%
% DEPENDENCIES
%   getWFP_serialNumber_fromNodeUid     (appended below)
%      constructs manufacturer's (McLane) profiler serial number from 
%      OOI uid; required for folder path to data on raw data archive 
%
% NOTES
%   A standardized folder path convention was not followed until several
%   years into the program. This code accounts for the early idiosyncrasies
%   and also flags archives with NO_DATA.
%
%.. There are 2 data delivery sources here tracked:
%.. (a) telemetered; COASTAL ONLY.    currentmeter data are decimated 
%.. (b) recovered_WFP (from the profiler itself).
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2021-11-08: desiderio: initial code
%.. 2022-01-12: desiderio: updated documentation
%=========================================================================

%.. needed for RawDataArchive folder names:
%.. find the manufacturer's profiler serial number from the OOI uid.
sss.profiler_serial_number = getWFP_serialNumber_fromNodeUid(sss.profiler_uid);

%.. the -nH and --cut switches prevent the entire rawdataarchive path 
%.. from being downloaded to local
cmdString  = ['wget_1_19_2_32bit --no-check-certificate -r -np -nH --cut-dirs=9 ' ...
    '-e robots=off -P ' sss.binary_data_folder ' '];

depNumtxt  = num2str(sss.deployment, '%5.5u');
mooring    = sss.mooring;
coverage   = sss.profiler_coverage;
snWFP      = sss.profiler_serial_number;
snWFP      = strrep(snWFP, 'ML', '');
snWFP      = ['sn' snWFP];

baseRDAfolder = 'https://rawdata.oceanobservatories.org/files/';
deploymentD   = [mooring '/D' depNumtxt '/'];  % telemetered
deploymentR   = [mooring '/R' depNumtxt '/'];  % recovered

%.. construct folder paths to the coastal data
if strcmpi(sss.profiler_type, 'coastal')
    %.. telemetered 
    sss.wget_cmd_telemetered = [cmdString baseRDAfolder deploymentD 'imm/mmp/'];
    %.. one naming anomaly
    if strcmpi(mooring, 'CP02PMUO') && strcmpi(depNumtxt, '00001')
        sss.wget_cmd_telemetered = [cmdString baseRDAfolder deploymentD 'imm/mmp_sn12936-01/'];
    end
    %.. instances of no data
    if strcmpi(mooring, 'CP02PMCO') && strcmpi(depNumtxt, '00004')
        sss.wget_cmd_telemetered = 'No telemetered data available';
    elseif strcmpi(mooring, 'CP02PMUI') && strcmpi(depNumtxt, '00004')
        sss.wget_cmd_telemetered = 'No telemetered data available';
    end
    
    %.. recoveredWFP
    %.. .. folder structure naming anomalies on the OOI Raw Data Archive
    %.. .. also, flag occurrences where there were no recovered WFP data
    %.. .. so that the telemetered data pathway can be used instead.
    coastalWFP.CE09OSPM_00006 = 'NO_DATA/';
    
    coastalWFP.CP02PMCI_00001 = 'dcl00/';
    coastalWFP.CP02PMCI_00002 = 'cg_data/dcl00/';
    coastalWFP.CP02PMCI_00003 = 'cg_data/dcl00/';
    coastalWFP.CP02PMCI_00004 = 'cg_data/dcl00/';
    coastalWFP.CP02PMCI_00005 = 'NO_DATA/';
 
    coastalWFP.CP02PMCO_00001 = 'dcl00/';
    coastalWFP.CP02PMCO_00002 = 'cg_data/dcl00/';
    coastalWFP.CP02PMCO_00003 = 'cg_data/dcl00/';
    coastalWFP.CP02PMCO_00004 = 'NO_DATA/';
    coastalWFP.CP02PMCO_00005 = 'cg_data/dcl00/';
    
    coastalWFP.CP02PMUI_00001 = 'dcl00/';
    coastalWFP.CP02PMUI_00002 = 'dcl00/';
    coastalWFP.CP02PMUI_00003 = 'NO_DATA/';
    coastalWFP.CP02PMUI_00004 = 'NO_DATA/';
    coastalWFP.CP02PMUI_00005 = 'cg_data/dcl00/';
    coastalWFP.CP02PMUI_00006 = 'cg_data/dcl00/';
 
    coastalWFP.CP02PMUO_00001 = 'NO_DATA/'; 
    coastalWFP.CP02PMUO_00002 = 'NO_DATA/'; 
    coastalWFP.CP02PMUO_00003 = 'dcl00/';
    coastalWFP.CP02PMUO_00004 = 'cg_data/dcl00/';
    coastalWFP.CP02PMUO_00005 = 'cg_data/dcl00/';
    coastalWFP.CP02PMUO_00006 = 'NO_DATA/'; 
 
    coastalWFP.CP04OSPM_00001 = 'dcl00/';
    coastalWFP.CP04OSPM_00002 = 'cg_data/dcl00/';
    coastalWFP.CP04OSPM_00003 = 'cg_data/dcl00/';
    coastalWFP.CP04OSPM_00004 = 'NO_DATA/';
     
    key = [mooring '_' depNumtxt];
    if isfield(coastalWFP, key)
        %.. folder paths before standardization
        dataBranch = coastalWFP.(key);
    elseif strcmpi(mooring, 'ce09OSPM')
        %.. OSU variant
        dataBranch = 'instrmts/';
    else 
        %.. the naming convention finally adopted: 
        dataBranch = 'instruments/';
    end
    wget = [cmdString baseRDAfolder deploymentR dataBranch 'CWFP_' snWFP '/'];
    %.. after running checks, 3 discrepancies were found; (the profiler serial
    %.. number as given by asset management sn12991-05) is different than the folder name
    %.. denoting it (sn12991-03) on the raw data archive. only 2 of these matter.
    if strcmpi(mooring, 'CP02PMUO') && strcmpi(depNumtxt, '00004')
        wget = [cmdString baseRDAfolder deploymentR dataBranch 'CWFP_sn12991-03/'];
    elseif strcmpi(mooring, 'CP02PMUO') && strcmpi(depNumtxt, '00006')
        % no action; there were no data in the misnamed folder path
    elseif strcmpi(mooring, 'CP02PMUO') && strcmpi(depNumtxt, '00008')
        wget = [cmdString baseRDAfolder deploymentR dataBranch 'CWFP_sn12991-03/'];
    end
    
    if contains(wget, 'NO_DATA')
        wget = 'No recovered-WFP data available.';
    end
    sss.wget_cmd_recovered_wfp = wget;

%.. construct folder paths to the global data
elseif strcmpi(sss.profiler_type, 'global')
    %.. telemetered
    sss.wget_cmd_telemetered   = 'Global data are not telemetered';

    %.. recoveredWFP
    %.. .. folder structure naming anomalies on the OOI Raw Data Archive
    globalWFP.GA_00001_upper = 'cg_data/dcl00/UPPER_sn13104-04/';
    globalWFP.GA_00001_lower = 'cg_data/dcl00/LOWER_sn13104-06/';
    
    globalWFP.GI_00001_whole = 'cg_data/dcl00/GWFP_sn13104-01/';
    globalWFP.GI_00002_whole = 'cg_data/dcl00/GWFP_sn12774-01/';
    
    globalWFP.GP_00001_upper = 'wfp_12936/';
    globalWFP.GP_00001_lower = 'wfp_12774/';
    globalWFP.GP_00002_upper = 'cg_data/dcl00/UPPER_sn12936/';
    globalWFP.GP_00002_lower = 'cg_data/dcl00/LOWER_sn13104-02/';
    globalWFP.GP_00003_upper = 'cg_data/dcl00/GWFP_sn12997-01/';
    globalWFP.GP_00003_lower = 'cg_data/dcl00/GWFP_sn13104-03/';
    
    globalWFP.GS_00001_upper = 'cg_data/dcl00/UPPER_sn13104-05/';
    globalWFP.GS_00001_lower = 'cg_data/dcl00/LOWER_sn13104-07/';
 
    key = [mooring(1:2)  '_' depNumtxt '_' coverage];
    if isfield(globalWFP, key)
        %.. folder paths before standardization
        dataBranch = globalWFP.(key);
    else
        %.. the naming convention finally adopted: 
        dataBranch = ['instruments/GWFP_' snWFP '/'];
    end
    sss.wget_cmd_recovered_wfp = [cmdString baseRDAfolder deploymentR dataBranch];
end

if contains(sss.stop_date, 'AT SEA')
    sss.wget_recovered_wfp = 'AT SEA: use telemetered, if available.';
end

end


function [profilerSerialNumber] = getWFP_serialNumber_fromNodeUid(profilerUID)
%.. 2021-10-22: desiderio: initial code

%.. url needed to access the node Asset Record file in
%.. the OOI Asset Management oceanobservatories GitHub repository
urlForDeployFile = "https://raw.githubusercontent.com/oceanobservatories/asset-management/master/";
urlForNodeAssets = strcat(urlForDeployFile, "bulk/node_bulk_load-AssetRecord.csv");
%.. the nodeAssets file contains the node.uid <-> McLane serial number correspondence.
nodeAssetsFile = strcat([pwd '/'], 'nodeAssetsFile.csv');
websave(nodeAssetsFile, urlForNodeAssets);
%
fid = fopen(nodeAssetsFile);
N = textscan(fid,'%s','whitespace','','delimiter','\n');
N = N{1};  % unwrap 
fclose(fid);
delete(nodeAssetsFile);

%.. N is a cell column vector of character rows.
header = N(1);
tf_SNcolumn = contains(split(header, ','), 'Manufacturer''s Serial');
%
uidRow = N(contains(N, profilerUID));
if isempty(uidRow)
    disp('Warning! Profiler (Node) UID not found in OOI asset management!')
    profilerSerialNumber = '';
    return
end
splitRow = split(uidRow, ',');
profilerSerialNumber = char(splitRow(tf_SNcolumn));

end

