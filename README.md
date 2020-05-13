## OOI mmp_toolbox

There are currently two versions of Matlab code available to process McLane Moored Profiler (MMP) data acquired at OOI surface mooring sites. **Version 2.11c** is an improved version of 2.10c and processes data from all of the instruments mounted on 'coastal' MMPs including its acoustic current meter (ACM). The next version was originally intended to process data acquired from instruments mounted on 'global' MMPs only, excluding ACM data. **Version 3.0** presented here has been modified to contain one main routine which can process both non-ACM coastal and non-ACM global data. A future release is planned which will integrate global ACM data processing and version 2.11c coastal ACM processing with the code revisions in version 3.0.
 
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

Although not extensively tested, it does appear that if coastal AD2CP processing is not required then Unpacker version 3.13.5 can be used.  

### Use  

This code suite was written to provide tools and a framework to allow users to easily import and visualize McLane profiler data sets so that they can apply their own quality control. This will be particularly necessary in the validation of ACM data. Sample plotting programs are provided "as is" in the plotting_routines folder.

