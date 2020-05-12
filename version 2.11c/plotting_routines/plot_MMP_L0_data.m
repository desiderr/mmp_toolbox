function plot_MMP_L0_data(MMP, figure0)
%.. desiderio 07-feb-2020
%
%.. creates scatter plots of L0 sensor data
%
%.. NOTE: At the beginning of profiles engineering pressure values 
%..       always start out at 0 regardless of the actual pressure.
%
% MMP is the output of Process_McLane_WFP_Deployment
% figure0 is optional and sets the figure number sequence
if nargin==0
    disp(' ');
    disp('USAGE (needs at least one calling argument):');
    disp('plot_MMP_L0_data(MMP)');
    disp('plot_MMP_L0_data(MMP, figureNumberOffset)');
    disp(' ');
    return
elseif nargin==1
    figure0 = 140;
end

mrkr = '.';
mrkrSize = 2;
mrkrSizePAR = 9;

xaxis_variable = 'profile_index';
disp(['fastscatter x-axis variable is ' xaxis_variable '.']);

%.. CTD plots
%.. .. data variables from MMP data structure

xVar         = MMP.raw_ctd_profile_indices;
pressure     = MMP.rawvec_ctd_pressure;
temperature  = MMP.rawvec_ctd_temperature;
conductivity = MMP.rawvec_ctd_conductivity;
oxygen       = MMP.rawvec_ctd_oxygen;

%.. .. plotting parameters
climTemperature  = [4 14];       % degC
climConductivity = [33 38];      % mS/cm
climOxygen       = [1000 4000];  % frequency

figure(1 + figure0)
fastscatter(xVar, pressure, temperature, mrkr, 'markersize',  mrkrSize);
title('L0 temperature')
axis ij
ylabel('pressure [db]')
hCTD311 = colorbar;
title(hCTD311, '\circC');
caxis(climTemperature)
%
drawnow

figure(2 + figure0)
fastscatter(xVar, pressure, conductivity, mrkr, 'markersize',  mrkrSize);
title('L0 conductivity')
axis ij
ylabel('pressure [db]')
hCTD312 = colorbar;
title(hCTD312, 'mS/cm');
caxis(climConductivity)
%
drawnow

figure(3 + figure0)
fastscatter(xVar, pressure, oxygen, mrkr, 'markersize',  mrkrSize);
title('L0 oxygen')
axis ij
ylabel('pressure [db]')
hCTD313 = colorbar;
title(hCTD313, 'freq');
caxis(climOxygen)
%
drawnow

%.. ECO-TRIPLET plots
%.. .. data variables from MMP data structure
xVar         = MMP.raw_eng_profile_indices;

pressure = MMP.rawvec_eng_pressure;
chl      = MMP.rawvec_eng_chl;
cdom     = MMP.rawvec_eng_cdom;
bback    = MMP.rawvec_eng_bback;
par      = MMP.rawvec_eng_par;
%.. .. plotting parameters
climChl    = [50  150];         % counts
climCDOM   = [60   80];         % counts
climBback  = [100 300];         % counts 
climPAR    = [0   10];          % counts
%
figure(7 + figure0)
fastscatter(xVar, pressure, chl, mrkr, 'markersize',  mrkrSize);
title('L0 chlorophyll')
axis ij
hTriplet311 = colorbar;
title(hTriplet311, 'counts');
caxis(climChl)
%
figure(8 + figure0)
fastscatter(xVar, pressure, cdom, mrkr, 'markersize',  mrkrSize);
title('L0 CDOM')
axis ij
hTriplet312 = colorbar;
title(hTriplet312, 'counts');
caxis(climCDOM)
%
figure(9 + figure0)
fastscatter(xVar, pressure, bback, mrkr, 'markersize',  mrkrSize);
title('L0 backscatter')
axis ij
hTriplet313 = colorbar;
title(hTriplet313, 'counts');
caxis(climBback)
%
figure(10 + figure0)
fastscatter(xVar, pressure, par, mrkr, 'markersize', mrkrSizePAR);
ylim([0 60]);
title('L0 PAR')
axis ij
hPAR = colorbar;
title(hPAR, 'counts');
caxis(climPAR)
set(gca, 'ColorScale', 'log')
drawnow

%..load chelle colormap if it can be found
tf_chelle = false;
if exist('chelle.mat', 'file')
    load('chelle.mat', 'chelle')
    if exist('chelle', 'var'), tf_chelle = true; end
end
%.. reverse figure 'focus' order;
%.. add dateticks if xaxis is time
%.. change colormap if possible
for ii = [10 9 8 7 3 2 1]
    figure(ii + figure0)
    if strcmpi(xaxis_variable, 'time')
        datetick('x', dateFormat, 'keepLimits')
    end
    if tf_chelle
        colormap(chelle);
    end
end

commandwindow
