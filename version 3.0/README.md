![Irm_toy.jpg](/version%203.0/toy_data/plots/Irm_WFP003_degC_toy.jpg "WFP Data")

The toy_data folder contains unpacked data text files and the cal file needed to try the version 3.0 processing code out. The provided toy metadata text file will need to be modified by changing the foldernames to the locations of the downloaded unpacked files and cal file on the local machine.

## OOI mmp_toolbox ver 3.0 
### Documentation  
Besides this readme file, there are 3 main sources of documentation for this version of the mmp_toolbox code (radMMP) written to process non-ACM McLane Moored Profiler data acquired at OOI coastal and global sites. They are located:  
  
*   at the beginning of function Process_OOI_McLane_CTDENG_Deployment.m  
*   for **coastal** profiler data processing, throughout any one of the sample metadata_**coastal**_WFP00?.txt files included in the metadata_files folder.  
*   for **global** profiler data processing, throughout any one of the sample metadata_**global**_WFP00?.txt files included in the metadata_files folder.  

Process_OOI_McLane_CTDENG_Deployment.m processes CTD and ENG files. Its documentation includes usage, dependencies, instrumentation, and references. It requires installation of the TEOS-10 Gibbs Sea Water Oceanographic Toolbox.

The version 3.0 coastal and global metadata text files contain and document all the processing parameters required for processing coastal and global profiler data, respectively, using the function above. The user can edit these for their own use. The presence of ACM processing parameters in these files does not affect the processing (unless an entry is illegally formatted). 

Version 3.0 coastal metadata text files differ from those used in version 2.10c in that they require one extra data line:
  
*   profiler_type = 'coastal' 

Therefore metadata text files used in 2.10c processing, and those in 2.11c processing that do not have this line, cannot be used for version 3.0 processing **unless** this line is added.

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

Although not extensively tested, it does appear that if only CTD-ENG processing is desired Unpacker version 3.13.5 can be used.  

### Running the Code  

Arguments in *italics* are optional in the particular processing sequence in which they appear.

*   __CTD-ENG processing__          
    *   [MMP, *mmpMatFilename*] = Process_OOI_McLane_CTDENG_Deployment('metadata_WFP001.txt');  
        *   The output variable MMP is a scalar structure containing pressure binned processed data (L2), unbinned processed data (L1) in nan-padded arrays, and flattened unprocessed data (L0) in column vectors, all of which can be plotted in pseudocolor plots against time and pressure.  
        *   If the optional argument mmpMatFilename is used, it will contain the name of a saved matfile containing MMP and additional data products: structure arrays for each instrument and level of processing indexed by profile number, containing code history and code actions. Therefore the full suite of data products can be made available in the base workspace for plotting and user analysis by executing the command: load(mmpMatFilename).


### Use  

This code suite was written to provide tools and a framework to allow users to easily import and visualize McLane profiler data sets so that they can apply their own quality control. This will be particularly necessary in the validation of AD2CP data. Sample plotting programs are provided "as is" in the plotting_routines folder.
