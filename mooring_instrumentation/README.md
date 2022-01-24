## Figure

![Example figure.](figure.png)
**Figure 1:** Washington Offshore Profiler Mooring (CE09OSPM) temperature (top left) and dissolved oxygen (bottom left) data collected during deployment 13 (July 2020 – March 2021) and processed using _mmp_toolbox_. The right panel shows a diagram of the Washington Offshore Profiler Mooring, including the McLane Moored Profiler that travels along a section of jacketed wire rope between approximately 40 and 500 meters depth.


## Summary
Since 2013 the National Science Foundation funded Ocean Observatories Initiative (OOI) has operated and maintained a vast, integrated network of oceanographic platforms and sensors that measure biological, chemical, geological, and physical properties across a range of spatial and temporal scales [@Trowbridge:2019]. This network includes four high-latitude, “global scale” arrays deployed southwest of Chile at 55oS, in the Argentine Basin, central north Pacific at Station Papa, and the Irminger Sea off Greenland. The “coastal scale” Endurance and Pioneer arrays are situated in the northeast Pacific off Oregon and Washington, and off the coast of New England about 140 km south of Martha’s Vineyard, respectively. All coastal and global arrays include moorings, mobile platforms (gliders or autonomous underwater vehicles), and profilers. Wire-Following Profiler (WFP) moorings (Table 1) include at least one McLane® Moored Profiler (MMP) [@Morrison:2000]. Traveling vertically along a section of jacketed wire rope at approximately 25 cm/s, MMPs carry low-power instruments that measure physical (temperature, salinity, pressure, and velocity) and biochemical (photosynthetically active radiation [coastal only], chlorophyll and colored dissolved organic matter fluorescence [the latter for coastal MMPs only], optical backscatter, and dissolved oxygen) variables. To date, the OOI has deployed more than thirty global WFP moorings, about 100 coastal WFP moorings, and collected over 150,000 profiles. While these data are provided to investigators and research communities in near real-time at https://ooinet.oceanobservatories.org, the OOI does not provide post-processed profile data that have, for example, been adjusted for thermal-lag, flow, and sensor time constant effects and binned to a common depth record.

### Conclusion
The Ocean Observatories Initiative (OOI) is an integrated network of oceanographic platforms and sensors measuring biological, chemical, geological, and physical properties across a range of spatial and temporal scales that was designed to operate for 25 years. Since operations began in 2013, McLane Moored Profilers (MMP) have collected physical and biochemical data during more than 150,000 profiles. Use of _mmp_toolbox_ described here will result in easier access to the ever-increasing OOI MMP data sets, making them more available to a broader swath of the marine research community and enabling investigations of processes such as increasing ocean heat content [@Abraham:2013], deep convection variability in the Irminger Sea [@deJong:2018], and increased hypoxia in coastal environments [@Chan:2008], which could profoundly impact the Earth system as the climate continues to change over the coming decades.

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

 
![MclaneProfilers.](McLaneProfilers.jpg)
**Figure 2:** Washington Offshore Profiler Mooring (CE09OSPM) temperature (top left) and dissolved oxygen (bottom left) data collected during deployment 13 (July 2020 – March 2021) and processed using _mmp_toolbox_. The right panel shows a diagram of the Washington Offshore Profiler Mooring, including the McLane Moored Profiler that travels along a section of jacketed wire rope between approximately 40 and 500 meters depth.




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

