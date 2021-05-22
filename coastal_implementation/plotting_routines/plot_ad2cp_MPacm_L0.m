function plot_ad2cp_MPacm_L0(MPacm_L0, figure0)
%.. desiderio 08-feb-2020
%
%.. creates 2D plots of L0 (unprocessed) AD2CP transducer data
%
% MPacm_L0 is the output of Process_McLane_AD2CP_Deployment
% figure0 is optional and sets the figure number sequence

if nargin==0
    disp(' ');
    disp('USAGE (needs at least one calling argument):');
    disp('plot_ad2cp_MPacm_L0(MPacm_L0)');
    disp('plot_ad2cp_MPacm_L0(MPacm_L0, figureNumberOffset)');
    disp(' ');
    return
elseif nargin==1
    figure0 = 6000;
end

cclimVel = [-0.3 0.3];

mrkr = '.';
mrkrSize = 15;

xaxis_variable = 'profile';
disp(['fastscatter x-axis variable is ' xaxis_variable '.']);
profile     = MPacm_L0.profiles_selected;

Pr = MPacm_L0.pressure;  % ctd pressure 

% AP = MPacm_L0.aqd_pressure;
% AT = MPacm_L0.aqd_temperature;
% H  = MPacm_L0.heading;
% P  = MPacm_L0.pitch;
% R  = MPacm_L0.roll;
% %.. McLane unpacker v3.12 and earlier output bogus magnetometer values
% %.. M  = MPacm_L0.magnetometer; 
beamMapping = MPacm_L0.beam_mapping;  %
[m, n, p] = size(MPacm_L0.velBeam);
%.. the 3 variables velBeam, amplitude, and correlation have dimensions
%.. of m x n x p where m is the number of points in a (nan-padded) profile,
%.. n is the number of profiles selected to be processed, and p is 4
%.. representing the 4 transducers of the Nortek AD2CP instrument. When 
%.. the instrument is operating as intended transducer 1 is in operation
%.. during ascending profiles and transducer 3 during descending profiles;
%.. transducers 2 and 4 are always used. the beam_mapping vectors denote
%.. which transducers were used for each profile and therefore the location
%.. of the corresponding data in the m x n x p data variables; [1 2 4] for 
%.. ascending profiles and [2 3 4] for descending profiles. Because all 4
%.. beams are never supposed to be in operation at the same time for OOI
%.. McLane Profilers, each m x 1 x p slice (each representing one profile)  
%.. should contain one m x 1 x 1 vector of Nan values positioned at either
%.. p=3 or p=1 depending on whether the profiler is ascending or descending.
%
%.. I will re-orient the data in these variables so that all data from
%.. transducer 2 will be shown in one pcolor plot, ditto for 4, and
%.. the data for transducers 1 and 3 will both be in the same plot in 
%.. (usually) alternating columns (unless there is a mechanical snafu).
%
%.. combine the data extraction and permutation operations by resetting
%.. the beam mapping designations: 
%.. .. convert [1 2 4] to [2 4 1] 
%.. .. convert [2 3 4] to [2 4 3]
%.. first need to make sure thare are no empty sets.
tf = cellfun('isempty', beamMapping);
beamMapping(tf) = {[3 2 1]};  % data for these profiles will be all Nans
tf_124 = cellfun(@(x) all(x==[1 2 4]), beamMapping);
beamMapping(tf_124) = {[2 4 1]};
tf_234 = cellfun(@(x) all(x==[2 3 4]), beamMapping);
beamMapping(tf_234) = {[2 4 3]};
%.. convert each variable to a cell vector using mat2cell, one m x 1 x p
%.. element per profile, so that cellfun can be used to apply the 
%.. appropriate beamMapping to each profile, then use cell2mat to convert
%.. back to m x n x 3 data arrays.
Vel = cell2mat(...
          cellfun(@(x, y) x(:, :, y), ...
              mat2cell(MPacm_L0.velBeam, m, ones(1, n), p), ...
              beamMapping, 'UniformOutput', 0) );
Amp = cell2mat(...
          cellfun(@(x, y) x(:, :, y), ...
              mat2cell(MPacm_L0.amplitude, m, ones(1, n), p), ...
              beamMapping, 'UniformOutput', 0) );
Cor = cell2mat(...
          cellfun(@(x, y) x(:, :, y), ...
              mat2cell(MPacm_L0.correlation, m, ones(1, n), p), ...
              beamMapping, 'UniformOutput', 0) );

xVariable = repmat(profile, m, 1);


figure(1 + figure0)
fastscatter(xVariable, Pr, Vel(:, :, 1), mrkr, 'markersize',  mrkrSize);
axis ij
title('transducer 2 velBeam')
ylabel('pressure [db]')
hcb = colorbar;
title(hcb, 'm/s')
caxis(cclimVel)

figure(2 + figure0)
fastscatter(xVariable, Pr, Amp(:, :, 1), mrkr, 'markersize',  mrkrSize);
axis ij
title('transducer 2 Amplitude')
ylabel('pressure [db]')
hcb = colorbar;
title(hcb, 'test')
%caxis([0 200])

figure(3 + figure0)
if all(isnan(Cor(:)))
    title({'transducer 2 correlation' 'DECIMATED DATASET; NOT AVAILABLE'})
else
    fastscatter(xVariable, Pr, Cor(:, :, 1), mrkr, 'markersize',  mrkrSize);
    axis ij
    title('transducer 2 Correlation')
    ylabel('pressure [db]')
    hcb = colorbar;
    title(hcb, '%')
    %caxis([0 100])
end

figure(4 + figure0)
fastscatter(xVariable, Pr, Vel(:, :, 2), mrkr, 'markersize',  mrkrSize);
axis ij
title('transducer 4 velBeam')
ylabel('pressure [db]')
hcb = colorbar;
title(hcb, 'm/s')
caxis(cclimVel)

figure(5 + figure0)
fastscatter(xVariable, Pr, Amp(:, :, 2), mrkr, 'markersize',  mrkrSize);
axis ij
title('transducer 4 Amplitude')
ylabel('pressure [db]')
hcb = colorbar;
title(hcb, 'counts')
%caxis([0 200])

figure(6 + figure0)
if all(isnan(Cor(:)))
    title({'transducer 4 correlation' 'DECIMATED DATASET; NOT AVAILABLE'})
else
    fastscatter(xVariable, Pr, Cor(:, :, 2), mrkr, 'markersize',  mrkrSize);
    axis ij
    title('transducer 4 Correlation')
    ylabel('pressure [db]')
    hcb = colorbar;
    title(hcb, '%')
    %caxis([0 100])
end

figure(7 + figure0)
fastscatter(xVariable, Pr, Vel(:, :, 3), mrkr, 'markersize',  mrkrSize);
axis ij
title('transducers 1 and 3: velBeam')
ylabel('pressure [db]')
hcb = colorbar;
title(hcb, 'm/s')
caxis(cclimVel)

figure(8 + figure0)
fastscatter(xVariable, Pr, Amp(:, :, 3), mrkr, 'markersize',  mrkrSize);
axis ij
title('transducers 1 and 3: Amplitude')
ylabel('pressure [db]')
hcb = colorbar;
title(hcb, 'counts')
%caxis([0 200])

figure(9 + figure0)
if all(isnan(Cor(:)))
    title({'transducer 1 and 3 correlation' 'DECIMATED DATASET; NOT AVAILABLE'})
else
    fastscatter(xVariable, Pr, Cor(:, :, 3), mrkr, 'markersize',  mrkrSize);
    axis ij
    title('transducers 1 and 3: Correlation')
    ylabel('pressure [db]')
    hcb = colorbar;
    title(hcb, '%')
    %caxis([0 100])
end

%..load chelle colormap if it can be found
tf_chelle = false;
if exist('chelle.mat', 'file')
    load('chelle.mat', 'chelle')
    if exist('chelle', 'var'), tf_chelle = true; end
end
%.. reverse figure 'focus' order;
%.. add dateticks if xaxis is time
%.. change colormap if possible
for ii = 9:-1:1
    figure(ii + figure0)
    xlabel('profile number');
    if tf_chelle
        colormap(chelle);
    end
end

commandwindow
