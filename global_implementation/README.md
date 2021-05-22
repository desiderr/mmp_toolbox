![Irm_toy.jpg](/global/demo_data/plots/Irm_WFP003_degC_toy.jpg "WFP Data")

The demo_data folder contains unpacked data text files, cal file, and demo metadata text file needed to try the version 3.10 processing code out.

## OOI mmp_toolbox ver 3.10g  


### Documentation  
Besides this readme file, there are 3 main sources of documentation for this version of the mmp_toolbox code (radMMP) written to process McLane Moored Profiler data acquired at OOI global sites. They are located:  
  
*   at the beginning of function Process_OOI_McLane_CTDENG_Deployment.m  
*   at the beginning of function Process_McLane_FSIACM_Deployment.m  
*   throughout any one of the sample metadata_**global**_*.txt files included in the metadata_files folder.  

Process_OOI_McLane_CTDENG_Deployment.m processes CTD and ENG files. Its documentation includes usage, dependencies, instrumentation, and references. It requires installation of the TEOS-10 Gibbs Sea Water Oceanographic Toolbox.

Process_McLane_FSIACM_Deployment.m processes the Falmmouth Scientific 3DMP ACM data. Its documentation includes usage, dependencies, and references. The CTD-ENG processing must be done first because the CTD pressure record is used in the ACM processing.

The metadata text files contain and document all the processing parameters required for both of the functions above. The user can edit these for their own use. The ACM processing parameters are not required if only the CTD-ENG processing function is executed. 

There is also supplemental documentation at the beginning of each subroutine.  

### Prerequisites  

[Matlab](https://www.mathworks.com/) 2018a or later is required.

The [TEOS-10 Gibbs Sea Water Oceanographic Toolbox](http://www.teos-10.org/software.htm) must be installed.

The raw McLane Profiler data must first be unpacked by [McLane Unpacker version **3.10-3.12**](https://mclanelabs.com/profile-unpacker/) or later. There are 3 McLane unpacking options provided to the user:  

*   Format - Comma separated or Space padded:  
    *   **Either** choice is compatible with the code.  
*   Header and date/time text inclusion:  
    *   **Either** choice is compatible with the code.
*   Add prefix to output files:  
    *   This must be **LEFT BLANK** for the code to run.  

### Running the Code  

Arguments in *italics* are optional in the particular processing sequence in which they appear.

*   __CTD-ENG processing__          
    *   [MMP, *mmpMatFilename*] = Process_OOI_McLane_CTDENG_Deployment('metadata_WFP001.txt');  
        *   The output variable MMP is a scalar structure containing pressure binned processed data (L2), unbinned processed data (L1) in nan-padded arrays, and flattened unprocessed data (L0) in column vectors, all of which can be plotted in pseudocolor plots against time and pressure.  
        *   If the optional argument mmpMatFilename is used, it will contain the name of a saved matfile containing MMP and additional data products: structure arrays for each instrument and level of processing indexed by profile number, containing code history and code actions. Therefore the full suite of CTD-ENG data products can be made available in the base workspace for plotting and user analysis by executing the command: load(mmpMatFilename).

*   __CTD-ENG and 3DMP processing__  
    *   [MMP, mmpMatFilename] = Process_OOI_McLane_CTDENG_Deployment('metadata_WFP001.txt');  
    *   [ACM, _acmMatFilename_] = Process_McLane_FSIACM_Deployment(__'import_and_process'__, mmpMatFilename);  
        *   In this and the following processing sequence the argument mmpMatFilename is required in both function calls as shown.
        *   ACM is a scalar structure containing binned processed velocity data (L2) which can be plotted in pseudocolor plots against time and pressure.  
        *   If the optional argument acmMatFilename is used, it will contain the name of a saved matfile containing 3 scalar data structures (L2: binned smoothed processed data; L1: nan-padded arrays of smoothed processed and unprocessed data; L0: nan-padded arrays of unsmoothed processed and unprocessed data) and data structure arrays indexed by profile number for the 3 levels of processing containing code history and code actions.  

For all processing sequences, the full suite of data products can be made available in the base workspace for plotting and user analysis by executing the following commands:  
  
    load(mmpMatFilename)  
    load(acmMatFilename)  
    who 

### Use  

This code suite was written to provide tools and a framework to allow users to easily import and visualize McLane profiler data sets so that they can apply their own quality control. This will be particularly necessary in the validation of AD2CP data. Sample plotting programs are provided "as is" in the plotting_routines folder.

It is suggested that the first time the code suite is run that the profiles_to_process variable in the metadata.txt file be set to 1:100. The resulting data products will be small enough so that there should be no long waits when saving the AD2CP data products nor for scatter and pseudocolor plotting routines to execute. 