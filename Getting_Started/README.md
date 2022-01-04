![O2_shift_demo.bmp](/Getting_Started\O2_shift_demo.bmp)
# Getting Started

## Introduction

mmp_toolbox (informally radMMP) is a code suite written to process profile data from McLane profilers deployed in the Ocean Observatories Initiative program. While these data are provided to the research community in near real-time at [OOINet](https://ooinet.oceanobservatories.org) and also from the [OOI Data Explorer](https://ooinet.oceanobservatories.org), the OOI does not provide profile data processed into integrated datasets taking into account the different instruments' time lags and depth offsets and containing all the instrument data binned to a common depth record as would be required for fully featured physical and biogeochemical models as well as for synoptic visualization of the data in time and depth for data survey and quality assessment. Use of mmp_toolbox described here will result in easier access to the ever-increasing number of OOI MMP data sets, making them more available to a broader swath of the marine research community. For more about the OOI program, see the [Ocean Observatories](https://oceanobservatories.org) website. For mooring sites and instrumentation see https://bitbucket.org/ooicgsn/mmp_toolbox/src/master/.

## Dependencies

### Getting the binary OOI data
- [wget.exe, version 1.19.2, 32-bit:]( http://wget.addictivecode.org/FrequentlyAskedQuestions.html#download) or equivalent for use in Windows 10. Note that this wget version for Windows seems to be the most recent that successfully downloads all the raw profiler data without skipping files when used to request data from the [OOI Raw Data Archive]( https://oceanobservatories.org/data/raw-data-archive). This version can be downloaded as the binary wget.exe courtesy of Jernej Simončič and renamed to wget_1_19_2_32bit.exe to differentiate it from other versions.

### Converting the binary OOI data into text for import into the mmp_toolbox
- [McLane Unpacker ver 3.10-3.12](https://mclanelabs.com/profile-unpacker). The binary 'C\*.DAT' (CTD), 'E\*.DAT' (engineering plus auxiliary sensors), and 'A\*.DAT' (currentmeter) data files downloaded in the wget call must be unpacked into text files for import into mmp_toolbox. Later Unpacker versions use a different output format when converting coastal 'A' files to text which are incompatible with the toolbox.

### Processing the OOI data
- [Matlab](https://www.mathworks.com/) version 2019b for Windows or later, plus the Statistics and Machine Learning Toolbox
- The Gibbs SeaWater (GSW) Oceanographic [TEOS-10 toolbox](https://www.teos-10.org/software.htm) for Matlab, version 3.06, which also uses the Statistics and Machine Learning Toolbox

## Installation

1. Install Matlab 2019b or later and the Statistics and Machine Learning Toolbox for Windows.

2. Install the GSW TEOS-10 toolbox for Matlab and follow its instructions which will:  
- (a) add its folder to the Matlab PATH  
- (b) run the GSW check function test
    
3. Download mmp_toolbox from the Bitbucket repo:  
- (a) mmp_toolbox + subfolders  
- (b) set the Matlab PATH to include mmp_toolbox and its subfolders

4. Install [wget_1_19_2_32bit.exe](https://eternallybored.org/misc/wget/):  
- (a) set the operating system PATH to include the folder containing it  
- (b) check OS path by running `wget_1_19_2_32bit.exe -h` at a Windows command prompt  
- (c) check by running in Matlab the system command: `system('wget_1_19_2_32bit.exe -h')`;
    
5. Install McLane Unpacker ver 3.10-3.12:  
- (a) set the operating system PATH to include the folder containing unpacker.exe  
- (b) check OS PATH by running `unpacker.exe` at a Windows command prompt. Verify version.  
- (c) check by running in Matlab the system command: `system('unpacker')`; Verify version.  
    
## Demonstration

6. Select the dataset to be downloaded and processed and download the corresponding metadata needed for processing. This requires knowledge of the 8-character site code name and deployment number which can be accessed on various OOI web pages, or, by running the toolbox utility getWFPmetadata.m as follows:  
- `getWFPmetadata` with no arguments outputs a table of site codes, mooring names, and site locations (latitude and longitude)  
- `getWFPmetadata` with one argument, a sitecode name, lists the temporal coverages of each deployment number at the given site  
- `getWFPmetadata` with two [or three] arguments (sitecode name, deployment number, [profiler location in water column]) will create a Matlab structure whose fields are populated with relevant metadata. At the deeper global sites (GA02HYPM, GP02HYPM, and GS02HYPM) two profilers are deployed to sample the 'upper' and 'lower' parts of the water column, thereby requiring the third input.    
      
    To continue the demonstration, run from the Matlab command line:
    
- (a) `getWFPmetadata;`   &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;  % to see (all) OOI WFP sites and locations
- (b) `getWFPmetadata('CE09OSPM');`&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;% to see the time coverage of each deployment at the coastal WA site  
- (c) `info = getWFPmetadata('CE09OSPM', 4);` &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;  % after execution type `info `(return) to see structure's field values  
    
    In this sequence the data from the 4th deployment at the coastal WA site has been selected. The field values of info are required for further processing. Note that the mmp_toolbox code uses a hard-coded structure variable named 'meta', so that to avoid confusion 'meta' should not be used in the getWFPmetadata utility call.
    
7. If desired change the local Matlab working directory. The next utility in this demonstration will create a folder named 'OOI_WFP' underneath the working directory for file organization and path standardization based on the sitecode and deployment number so that this demonstration sequence can be run as often as desired with all OOI datasets without having to deal with ambiguous folder names. An added feature is that the OOI_WFP folder  will contain all the dataset folders so that the entire folder tree can be moved as a unit to another location.

8. Run the setUpFolderStructure.m utility to construct a folder tree to organize files. The names of the folders created can be seen by typing `info` (return) after running the utility.  
- `info = setUpFolderStructure(info);`

9. Retrieve the appropriate calibration files for the instruments that require them:  
- `info = getWFPcalfiles(info);`

10. Construct the command strings to retrieve binary profiler data from the OOI Raw Data Archive:  
- `info = formWgetCmdStrings(info)`;

11. Downloading data considerations. OOI data are delivered via 3 different streams - (i) telemetered from the profiler during deployment (coastal profilers only), (ii) recovered from the mooring data logger after deployment, and (iii) recovered from the profiler also after deployment. All streams, if available, contain identical CTD and Engineering data; the Currentmeter data in the first 2 streams are decimated, whereas these files are unabridged in the 3rd stream. It is preferred to use stream 3 to get the entire dataset. If a coastal profiler was deployed and not recovered, then the telemetered stream can be used. Therefore the wget command lines for the 1st and 3rd streams are contained in the structure fields of info.  
To download the test/demo dataset, execute from the Matlab command line:  
- `system(info.wget_cmd_recovered_wfp, '-echo');`

    This will automatically download the raw data into a local folder named 'binary' underneath folders codenamed according to the site and deployment.  

12. To unpack the data using the McLane Unpacker installed in step 5:   
- (a) type `info, return` in the command window to display the info fields containing the names of the binary and unpacked data folders.   
- (b) `system('unpacker');` The unpacker screen will be spawned. Change the settings to:  
- (c) Source Folder: browse to the folder specified by info.binary_data_folder, highlight it and click OK.  
- (d) Destination Folder: browse to the folder specified by info.unpacked_data_folder, highlight it and click OK.  
- (e) No Unpack Options need be set.  
- (f) Output Options: select either comma separated or space padded columns; Do include header and date/time text; do **not** add a prefix to output files.  
- (g) Files to Unpack: make sure the Engineering, CTD, and ACM file boxes are checked. If checked, uncheck Motion Pack and Wetlabs C-Star.  
- (h) Click on Unpack; a progress window will be spawned.  
- (i) When Unpacking is complete, view files or log to note missing file or error messages if desired then close the progress window. Dismiss unpacker GUI (click on 'X' in upper right hand corner of its window) so that control will be returned to the Matlab command window.  
    
13. Run the utility:  
- `info = getNumberOfProfiles(info);`

14. Run the xferMetadataToFile.m utility to write the info metadata into a metadata.txt file (to be used by the mmp_toolbox code). The output file will reside in the deployment folder.  
- `[info, metafilename] = xferMetadataToFile(info)`;

15. Change the working directory to the deployment folder by executing:  
- `cd(info.deployment_folder_path)`

    The processing output files will reside in this directory.  
    
16. Use mmp_toolbox to: Process the CTD and ENG profiler data  
- `[MMP, mmpMatFilename] = Process_OOI_McLane_CTDENG_Deployment(metafilename);`

17. Use mmp_toolbox utilities to: Run plotting routines to visualize the data  
- `bbplot_MMP_L2_data(MMP, 'time');`  
- `bbplot_MMP_L1_data(MMP, 'time');`  
- `bbplot_MMP_L0_data(MMP, 'time');`  

18. Process the ACM profiler data:  
    For coastal deployments (for example, the demo):  
- `[ACM, acmMatFilename] = Process_McLane_AD2CP_Deployment('import_and_process', mmpMatFilename);`  
    For global deployments:  
- `[ACM, acmMatFilename] = Process_McLane_FSIACM_Deployment('import_and_process', mmpMatFilename);`

19. Load the supplementary data products into the workspace:  
- `load(mmpMatFilename)`  
- `load(acmMatFilename)`  
- `who`

## Tests

(1) The values calculated in the MMP demonstration can be verified by checking against reference values by running:  
- bbcheck_MMP_L2_data(MMP)
- bbcheck_MMP_L1_data(MMP)
- bbcheck_MMP_L0_data(MMP)

The values to be checked are plotted as blue 'x' characters, the check values are over-plotted as red circles.

## Documentation

## Support / Bug Report

## Contribute

## To Cite

