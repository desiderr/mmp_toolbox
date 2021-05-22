![Irminger_WFP005_O2_pcolor.jpg](/Irminger_WFP005_O2_pcolor.jpg "WFP Data")

A 1 month global demo dataset (unpacked text files, calfile, metadata file) is provided in the global_implementation section for downloading.

## OOI mmp_toolbox

Version 4.0 of the Matlab mmp_toolbox code processes McLane Moored Profiler (MMP) data acquired at both 'coastal' and 'global' OOI surface mooring sites. 
 
### Coastal OOI MMP sites
* CE09OSPM (**C**oastal **E**ndurance)
* CP01CNPM (**C**oastal **P**ioneer)
* CP02PMCI 
* CP02PMCO
* CP02PMUI 
* CP02PMUO 
* CP03ISPM 
* CP04OSPM 

### Coastal OOI MMP Instrumentation
* Seabird SBE52MP CTD (CTDPF-K)
* Seabird SBE43F oxygen sensor (DOFST-K)
* Seabird\WETLabs eco-Triplet backscatter\fluorometer (FLORT-K)
* Biospherical QSP-2200 PAR sensor (PARAD-K)
* Nortek AD2CP acoustic current meter (custom) (VEL3D-K)

### Global OOI MMP sites
* GA02HYPM (**G**lobal **A**rgentine Basin)
* GI02HYPM (**G**lobal **I**rminger)
* GP02HYPM (**G**lobal Station **P**apa)
* GS02HYPM (**G**lobal **S**outhern Ocean)

### Global OOI MMP Instrumentation
* Seabird SBE52MP CTD (CTDPF-L)
* Aanderaa 4330 oxygen optode (DOSTA-L)
* Seabird\WETLabs FLBBRTD backscatter\fluorometer (FLORD-L)
* Falmouth Scientific profiling acoustic current meter (VEL3D-L)

### Prerequisites  

[Matlab](https://www.mathworks.com/) 2018a or later is required.

The [TEOS-10 Gibbs Sea Water Oceanographic Toolbox](http://www.teos-10.org/software.htm) must be installed.

The raw McLane Profiler data must first be unpacked by [McLane Unpacker version **3.10-3.12**](https://mclanelabs.com/profile-unpacker/); later version(s) use a currently unsupported format for the unpacked coastal AD2CP text files. There are 3 McLane unpacking options provided to the user:  

*   Format - Comma separated or Space padded:  
    *   **Either** choice is compatible with the code.  
*   Header and date/time text inclusion:  
    *   **Either** choice is compatible with the code.
*   Add prefix to output files:  
    *   This must be **LEFT BLANK** for the code to run.  

If coastal AD2CP processing is not required then Unpacker version 3.13.5 and possibly later can be used.  

### Use  

This code suite was written to provide tools and a framework to allow users to easily import and visualize McLane profiler data sets so that they can apply their own quality control. This will be particularly necessary in the validation of ACM data. Sample plotting programs are provided "as is" in the plotting_routines folder.

