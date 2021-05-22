## OOI mmp_toolbox ver 2.20c  


### Documentation  
Besides this readme file, there are 3 main sources of documentation for this version of the mmp_toolbox code (radMMP) written to process McLane Moored Profiler data acquired at OOI coastal sites. They are located:  
  
*   at the beginning of function Process_McLane_WFP_Deployment.m  
*   at the beginning of function Process_McLane_AD2CP_Deployment.m  
*   throughout any one of the sample metadata_WFP00?.txt files included in the metadata_files folder.  

Process_McLane_WFP_Deployment.m processes CTD and ENG files. Its documentation includes usage, dependencies, instrumentation, and references. It requires installation of the TEOS-10 Gibbs Sea Water Oceanographic Toolbox.

Process_McLane_AD2CP_Deployment.m processes the Nortek Aquadopp II ACM data. Its documentation includes usage, dependencies, and references. The CTD-ENG processing must be done first because the CTD pressure record is used in the AD2CP processing.

The metadata text files contain and document all the processing parameters required for both of the functions above. The user can edit these for their own use. The ACM processing parameters are not required if only the CTD-ENG processing function is executed. 

There is also supplemental documentation at the beginning of each subroutine.  

### Prerequisites  

[Matlab](https://www.mathworks.com/) 2018a or later is required.

The [TEOS-10 Gibbs Sea Water Oceanographic Toolbox](http://www.teos-10.org/software.htm) must be installed.

The raw McLane Profiler data must first be unpacked by [McLane Unpacker version **3.10-3.12**](https://mclanelabs.com/profile-unpacker/); __later__ version(s) use a currently unsupported format for the unpacked AD2CP text files. There are 3 McLane unpacking options provided to the user:  

*   Format - Comma separated or Space padded:  
    *   **Either** choice is compatible with the code.  
*   Header and date/time text inclusion:  
    *   **Either** choice is compatible with the code.
*   Add prefix to output files:  
    *   This must be **LEFT BLANK** for the code to run.  

If only CTD-ENG processing is desired Unpacker version 3.13.5 can be used.  

### Running the Code  

Arguments in *italics* are optional in the particular processing sequence in which they appear.

*   __CTD-ENG processing only__          
    *   [MMP, *mmpMatFilename*] = Process_McLane_WFP_Deployment('metadata_WFP001.txt');  
        *   The output variable MMP is a scalar structure containing pressure binned processed data (L2), unbinned processed data (L1) in nan-padded arrays, and flattened unprocessed data (L0) in column vectors, all of which can be plotted in pseudocolor plots against time and pressure.  
        *   If the optional argument mmpMatFilename is used, it will contain the name of a saved matfile containing MMP and additional data products: structure arrays for each instrument and level of processing indexed by profile number, containing code history and code actions. Therefore the full suite of CTD-ENG data products can be made available in the base workspace for plotting and user analysis by executing the command: load(mmpMatFilename). 

*   __CTD-ENG and AD2CP processing__  
    *   [MMP, mmpMatFilename] = Process_McLane_WFP_Deployment('metadata_WFP001.txt');  
    *   [ACM, _acmMatFilename_] = Process_McLane_AD2CP_Deployment(__'import_and_process'__, mmpMatFilename);  
        *   In this and the following processing sequence the argument mmpMatFilename is required in both function calls as shown.
        *   ACM is a scalar structure containing binned processed velocity data (L2) which can be plotted in pseudocolor plots against time and pressure.  
        *   If the optional argument acmMatFilename is used, it will contain the name of a saved matfile containing 3 scalar data structures (L2: binned processed data; L1: nan-padded arrays of processed data; L0: nan-padded arrays of unprocessed data) and data structure arrays indexed by profile number for 3 levels of processing containing code history and code actions.  

For all processing sequences, the full suite of data products can be made available in the base workspace for plotting and user analysis by executing the following commands:  
  
    load(mmpMatFilename)  
    load(acmMatFilename)  
    who 

### Use  

This code suite was written to provide tools and a framework to allow users to easily import and visualize McLane profiler data sets so that they can apply their own quality control. This will be particularly necessary in the validation of AD2CP data. Sample plotting programs are provided "as is" in the plotting_routines folder.

It is suggested that the first time the code suite is run that the profiles_to_process variable in the metadata.txt file be set to 1:100. The resulting data products will be small enough so that there should be no long waits when saving the AD2CP data products nor for scatter and pseudocolor plotting routines to execute. 