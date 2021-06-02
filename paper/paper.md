---
title: 'mmp_toolbox: A MATLAB® toolbox for processing ocean data collected by McLane Moored Profilers'
tags:
  - Ocean Observatories Initiative
  - Wire Following Profiler Mooring
  - McLane Moored Profiler
authors:
  - name: Russell A. Desiderio^[corresponding author]
    orcid: 0000-0001-7786-9140
    affiliation: "1"
  - name: Craig M. Risien
    orcid: 0000-0002-2826-9488
    affiliation: "1"
affiliations:
 - name: Oregon State University, College of Earth, Ocean, and Atmospheric Sciences, Corvallis, Oregon, 97331
   index: 1
date: 01 June 2021
bibliography: paper.bib
---

## Summary
Since 2013 the National Science Foundation funded Ocean Observatories Initiative (OOI) has operated and maintained a vast, integrated network of oceanographic platforms and sensors that measure biological, chemical, geological, and physical properties across a range of spatial and temporal scales [@Trowbridge:2019]. This network includes four high-latitude, “global scale” arrays deployed southwest of Chile at 55oS, in the Argentine Basin, central north Pacific at Station Papa, and the Irminger Sea off Greenland. The “coastal scale” Endurance and Pioneer arrays are situated in the northeast Pacific off Oregon and Washington, and off the coast of New England about 140 km south of Martha’s Vineyard, respectively. All coastal and global arrays include moorings, mobile platforms (gliders or autonomous underwater vehicles), and profilers. Wire-Following Profiler (WFP) moorings (Table 1) include at least one McLane® Moored Profiler (MMP) [@Morrison:2000]. Traveling vertically along a section of jacketed wire rope at approximately 25 cm/s, MMPs carry low-power instruments that measure physical (temperature, salinity, pressure, and velocity) and biochemical (photosynthetically active radiation [coastal only], chlorophyll and colored dissolved organic matter fluorescence [the latter for coastal MMPs only], optical backscatter, and dissolved oxygen) variables. To date, the OOI has deployed more than thirty global WFP moorings, about 100 coastal WFP moorings, and collected over 150,000 profiles. While these data are provided to investigators and research communities in near real-time at https://ooinet.oceanobservatories.org, the OOI does not provide post-processed profile data that have, for example, been adjusted for thermal-lag, flow, and sensor time constant effects and binned to a common depth record.

## Statement of Need
_mmp_toolbox_ is a MATLAB® toolbox that imports unpacked MMP data files, applies the necessary calibration coefficients and data corrections that can be specified by the user, and produces a final, binned data set that allows users to more easily visualize and investigate MMP data; its modular architecture is structured to encourage users to apply their own processing tools if desired or, with minor modification, process non-OOI MMP data sets [@Desiderio:2021].

Raw OOI MMP binary data files are available at https://rawdata.oceanobservatories.org/files/ (Table 1). Files can be downloaded using the free command-line utility `Wget`. Using a terminal window, the command might look as follows:

>wget --no-check-certificate -r -np -e robots=off  https://rawdata.oceanobservatories.org/files/CE09OSPM/R00013/cg_data/imm/mmp/

which will download all Endurance Array Washington Offshore Profiler Mooring (CE09OSPM; Figure 1) data files for deployment number 13. These files can be unpacked using McLane’s freely available [_Profile Unpacker_](https://mclanelabs.com/profile-unpacker/) software.

The _mmp_toolbox_ code was inspired by a MMP processing toolbox created by John Toole (Woods Hole Oceanographic Institution). It uses [OOI data production algorithms](https://github.com/oceanobservatories/ion-functions/tree/master/ion_functions/data)  and the Gibbs-SeaWater (GSW) Oceanographic Toolbox [@McDougall:2011] to calculate certain data products, as well as one function (`Toolebox_shift.m`) derived from the https://github.com/modscripps/MPproc repository; however, it consists mostly of novel code in a newly designed and written toolbox that rapidly loads and processes large amounts of MMP data in parallel rather than in series, allowing users to quickly visualize and analyze the results.

To run the toolbox users should download and unpack MMP data for a particular deployment. A metadata ASCII text file must be updated to include the path to the local data directory and the local directory that contains the deployment specific OOI calibration CSV files. The calibration files are available at https://github.com/oceanobservatories/asset-management/tree/master/calibration, and can be downloaded using `getMcLaneCalFiles.m`, a function that is included in _mmp_toolbox_. Once the _metadata.txt_ file has been updated to include the above information and information such as “profiler_type”, “deployment_ID”, the deployment latitude and longitude, and the total number of profiles collected during that deployment, users are able to process coastal array data using the following two functions:

    [MMP, mmpMatFilename] = Process_OOI_McLane_CTDENG_Deployment('metadata.txt');
    [ACM, acmMatFilename] = Process_McLane_AD2CP_Deployment('import_and_process', mmpMatFilename);

The two functions below will process global array data:

    [MMP, mmpMatFilename] = Process_OOI_McLane_CTDENG_Deployment('metadata.txt');
    [ACM, acmMatFilename] = Process_McLane_FSIACM_Deployment('import_and_process', mmpMatFilename);

The resulting structured array _MMP_ contains the original, unprocessed data (level 0), processed data that have had, for example, calibration coefficients applied, and been adjusted for thermal-lag, flow, and sensor time constant effects (level 1), and final, level 2 data sets where level 1 data have been binned on pressure. The structured array _ACM_ contains only level 2 data, level 0 and level 1 structured array data are saved in the MAT-File designated by acmMatFilename. Additional data products can be accessed by loading the saved MAT-Files created as named in the second output arguments. These include arrays of structures for each instrument and processing level indexed by profile number. Level 2 data can be plotted (Figure 1) using functions such as `pcolor.m` and the following example code snippet: 

    %Plot temperature data
    subplot(211)
    pcolor(MMP.binned_ctd_time,MMP.ctd_pressure_bin_values,MMP.binned_ctd_temperature)
    shading flat
    caxis([5 10])
    set(gca, 'YDir', 'reverse' )
    datetick('x',20)
    ylabel('pressure (dbar)')
    cb=colorbar;
    title(cb,'^oC')
    title('Washington Offshore Profiler Mooring (CE09OSPM): Deployment 13','fontweight','normal')
    %Plot dissolved oxygen data
    subplot(212)
    pcolor(MMP.binned_ctd_time,MMP.ctd_pressure_bin_values,MMP.binned_ctd_oxygen)
    shading flat
    caxis([0 300])
    set(gca, 'YDir', 'reverse' )
    datetick('x',20)
    ylabel('pressure (dbar)')
    cb=colorbar;
    title(cb,'umol/kg')

## Conclusion
The Ocean Observatories Initiative (OOI) is an integrated network of oceanographic platforms and sensors measuring biological, chemical, geological, and physical properties across a range of spatial and temporal scales that was designed to operate for 25 years. Since operations began in 2013, McLane Moored Profilers (MMP) have collected physical and biochemical data during more than 150,000 profiles. Use of _mmp_toolbox_ described here will result in easier access to the ever-increasing OOI MMP data sets, making them more available to a broader swath of the marine research community and enabling investigations of processes such as increasing ocean heat content [@Abraham:2013], deep convection variability in the Irminger Sea [@de Jong:2018], and increased hypoxia in coastal environments [@Chan:2008], which could profoundly impact the Earth system as the climate continues to change over the coming decades.

## Figure

![Example figure.](figure.png)
**Figure 1:** Washington Offshore Profiler Mooring (CE09OSPM) temperature (top left) and dissolved oxygen (bottom left) data collected during deployment 13 (July 2020 – March 2021) and processed using _mmp_toolbox_. The right panel shows a diagram of the Washington Offshore Profiler Mooring, including the McLane Moored Profiler that travels along a section of jacketed wire rope between approximately 40 and 500 meters depth.

## Table

| **OOI Mooring Name<br>(Site Code)** | **Site Location** | **Water Depth<br>(meters)**     | **Temporal Coverage**      | **Raw Data Archive Directory Structure<br>https://rawdata.oceanobservatories.org/files/** |
| :---        | :----       | :---          | :---        | :----       |
| **Global Arrays**         |
| Argentine Basin Profiler Mooring (GA02HYPM)   | 42.9781°S, 42.4957°W        | 5,200      | Mar 2015 – Jan 2018   | GA02HYPM/R000**/cg_data/imm/mmp/        |
| Southern Ocean Profiler Mooring (GS02HYPM)      | 54.4693°S, 89.3191°W       | 4,800   | Feb 2015 - Dec 2017      | GS02HYPM/R000**/cg_data/imm/mmp/       |
| Irminger Sea Profiler Mooring (GI02HYPM)   | 59.9695°N, 39.4886°W        | 2,800      | Sep 2014 - Present   |   GI02HYPM/R000**/cg_data/imm/mmp/      |
| Station Papa Profiler Mooring (GP02HYPM)      | 50.0796°N, 144.806°W       | 4,219   | Jul 2013 - Present      | GP02HYPM/R000**/cg_data/imm/mmp/       |
|    |         |       |    |         |
| **Coastal Endurance Array**      |        |    |       |        |
| Washington Offshore Profiler Mooring (CE09OSPM)   | 46.8517°N, 124.982°W        | 540      | Apr 2014 - Present   | CE09OSPM/R000**/cg_data/imm/mmp/        |
|       |        |  |       |        |
| **Coastal Pioneer Array**   |         |       |    |         |
| Central Profiler Mooring (CP01CNPM)      | 40.1340°N, 70.7708°W       | 130   | Nov 2017 - Present      | CP01CNPM/R000**/cg_data/imm/mmp/       |
| Central Inshore Profiler Mooring (CP02PMCI)   | 40.2267°N, 70.8782°W        | 127      | Apr 2014 - Present   | CP02PMCI/R000**/cg_data/imm/mmp/        |
| Central Offshore Profiler Mooring (CP02PMCO)      | 40.0963°N, 70.8789°W       | 148   | Apr 2014 - Present      | CP02PMCO/R000**/cg_data/imm/mmp/       |
| Upstream Inshore Profiler Mooring (CP02PMUI)   | 40.3649°N, 70.7700°W        | 95      | Nov 2013 - Present   | CP02PMUI/R000**/cg_data/imm/mmp/        |
| Upstream Offshore Profiler Mooring (CP02PMUO)      | 39.9394°N, 70.7708°W       | 452   | Nov 2013 - Present      | CP02PMUO/R000**/cg_data/imm/mmp/       |
| Inshore Profiler Mooring (CP03ISPM)   | 40.36202°N, 70.8785°W        | 90      | Nov 2017 - Present   | CP03ISPM/R000**/cg_data/imm/mmp/        |
| Offshore Profiler Mooring (CP04OSPM)      | 39.9365°N, 70.8802°W       | 453   | Apr 2014 - Present      | CP04OSPM/R000**/cg_data/imm/mmp/       |

**Table 1:** OOI Wire-Following Profiler names, site codes, mooring locations, water depths, temporal coverage and the raw data archive directory structures for downloading MMP binary data files.<br>
** is the deployment number starting at 01.

# Acknowledgements

We thank the National Science Foundation for funding OOI.

# References
