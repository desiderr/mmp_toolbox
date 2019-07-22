## OOI mmp_toolbox  
### Documentation  
Besides this readme file, there are 3 main sources of documentation for the mmp_toolbox code (radMMP) written to process McLane Moored Profiler data acquired at OOI coastal sites. They are located:  
  
*   at the beginning of function Process_McLane_WFP_Deployment.m  
*   at the beginning of function Process_McLane_AD2CP_Deployment.m  
*   throughout any one of the sample metadata_WFP00?.txt files included in the code folder.  

Process_McLane_WFP_Deployment.m processes CTD and ENG files. Its documentation includes usage, dependencies, instrumentation, and references. It requires installation of the TEOS-10 Gibbs Sea Water Oceanographic Toolbox.

Process_McLane_AD2CP_Deployment.m processes the Nortek Aquadopp II ACM data. Its documentation includes usage, dependencies, and references. The CTD-ENG processing must be done first because the CTD pressure record is used in the AD2CP processing.

The metadata text files contain and document all the processing parameters required for both of the functions above. The user can edit these for their own use. The AD2CP processing parameters are not required if only the CTD-ENG function is executed.

In addition there is supplemental documentation at the beginning of each subroutine.  

### Prerequisites  

[Matlab](https://www.mathworks.com/) 2018a or later is required.

The [TEOS-10 Gibbs Sea Water Oceanographic Toolbox](http://www.teos-10.org/software.htm) must be installed.

The raw McLane Profiler data must first be unpacked by [McLane Unpacker version **3.10-3.12**](https://mclanelabs.com/profile-unpacker/); later versions use a currently unsupported format for the unpacked AD2CP text files. There are 3 McLane unpacking options provided to the user:  

*   Format - Comma separated or Space padded:  
    *   **Either** choice is compatible with the code.  
*   Header and date/time text inclusion:  
    *   **Either** choice is compatible with the code.
*   Add prefix to output files:  
    *   This must be **LEFT BLANK** for the code to run.  

Although not extensively tested, it does appear that if only CTD-ENG processing is desired Unpacker version 3.13.5 can be used.  

### Running the Code  

Arguments in *italics* are optional in the particular processing sequence in which they appear.

*   __CTD-ENG processing only__          
    *   [MMP, *mmpMatFilename*] = Process_McLane_WFP_Deployment('metadata_WFP001.txt');  
        *   The output variable MMP is a structure containing binned processed CTD and auxiliary sensor data which can be plotted in pseudocolor plots against time and pressure.  
        *   If the optional argument mmpMatFilename is used, it will contain the name of a saved matfile containing MMP and additional data products indexed by profile number and 3 levels of processing for each instrument.  

*   __CTD-ENG and AD2CP processing__  
    *   [MMP, mmpMatFilename] = Process_McLane_WFP_Deployment('metadata_WFP001.txt');  
    *   [ACM, _acmMatFilename_] = Process_McLane_AD2CP_Deployment(__'import_and_process'__, mmpMatFilename);  
        *   In this and the following processing sequence the argument mmpMatFilename is required in both function calls as shown.
        *   ACM is a structure containing binned processed velocity data which can be plotted in pseudocolor plots against time and pressure.  
        *   If the optional argument acmMatFilename is used, it will contain the name of a saved matfile containing ACM and data structure arrays indexed by profile number for 3 levels of processing.  

*   __CTD-ENG with Re-entry AD2CP processing__  
    *   [MMP, mmpMatFilename] = Process_McLane_WFP_Deployment('metadata_WFP001.txt');  
    *   [aqd, reentryMatFilename] = Process_McLane_AD2CP_Deployment(__'import'__, mmpMatFilename);  
    *   .  
    *   .  
    *   .  
    *   [ACM, _acmMatFilename_] = Process_McLane_AD2CP_Deployment(__'process'__, reentryMatFilename, *'NEWmetadata_WFP001.txt'*);   
        *   The argument reentryMatFilename is required in both function calls as shown.
        *   Importing AD2CP files can take minutes. This processing sequence runs the AD2CP code first in 'import' mode which saves the imported unprocessed AD2CP data (structure array aqd) and the ctd and meta data required for AD2CP processing in the matfile designated by reentryMatFilename so that they can be later accessed when running the AD2CP code in 'process' mode without having to re-import the AD2CP data. The reentry format also allows the AD2CP processing parameters to be changed at will by including the name of a new suitably modified metadata text file as the (optional) 3rd calling argument.  
### Use  

This code suite was written to provide tools and a framework to allow users to easily import and visualize McLane profiler data sets so that they can apply their own quality control.  



