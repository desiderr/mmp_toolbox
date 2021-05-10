function plot_ad2cp_MPacm_L1(MPacm_L1, figure0)
%.. desiderio 08-feb-2020
%
%.. creates 2D plots of L1 (processed, not binned) AD2CP data
%
% MPacm_L1 is the output of Process_McLane_AD2CP_Deployment
% figure0 is optional and sets the figure number sequence

if nargin==0
    disp(' ');
    disp('USAGE (needs at least one calling argument):');
    disp('plot_ad2cp_MPacm_L1(MPacm_L1)');
    disp('plot_ad2cp_MPacm_L1(MPacm_L1, figureNumberOffset)');
    disp(' ');
    return
elseif nargin==1
    figure0 = 7000;
end

cclimVel = [-0.3 0.3];

mrkr = '.';
mrkrSize = 15;

xaxis_variable = 'profile';
disp(['fastscatter x-axis variable is ' xaxis_variable '.']);
profile     = MPacm_L1.profiles_selected;

Pr = MPacm_L1.pressure;  % ctd pressure 

AP = MPacm_L1.aqd_pressure;
AT = MPacm_L1.aqd_temperature;
H  = MPacm_L1.heading;
P  = MPacm_L1.pitch;
R  = MPacm_L1.roll;
W  = MPacm_L1.wag_signal;  % calculated
velX = MPacm_L1.velXYZ(:, :, 1);
velY = MPacm_L1.velXYZ(:, :, 2); 
velZ = MPacm_L1.velXYZ(:, :, 3); 

%.. replicate the profile numbers for each row of the padded arrays
xVariable = repmat(profile, size(H, 1), 1);

figure(1 + figure0)
fastscatter(xVariable, Pr, velX, mrkr, 'markersize',  mrkrSize);
axis ij
title('velX')
ylabel('pressure [db]')
hcb = colorbar;
title(hcb, 'm/s')
caxis(cclimVel)

figure(2 + figure0)
fastscatter(xVariable, Pr, velY, mrkr, 'markersize',  mrkrSize);
axis ij
title('velY')
ylabel('pressure [db]')
hcb = colorbar;
title(hcb, 'm/s')
caxis(cclimVel)

figure(3 + figure0)
fastscatter(xVariable, Pr, velZ, mrkr, 'markersize',  mrkrSize);
axis ij
title('velZ')
ylabel('pressure [db]')
hcb = colorbar;
title(hcb, 'm/s')
caxis(cclimVel)

figure(4 + figure0)
fastscatter(xVariable, Pr, P, mrkr, 'markersize',  mrkrSize);
axis ij
title('pitch')
ylabel('pressure [db]')
hcb = colorbar;
title(hcb, 'deg')
caxis([-5 5])

figure(5 + figure0)
fastscatter(xVariable, Pr, R, mrkr, 'markersize',  mrkrSize);
axis ij
title('roll')
ylabel('pressure [db]')
hcb = colorbar;
title(hcb, 'deg')
caxis([-5 5])

figure(6 + figure0)
fastscatter(xVariable, Pr, W, mrkr, 'markersize',  mrkrSize);
axis ij
title('calculated wag signal')
ylabel('pressure [db]')
hcb = colorbar;
title(hcb, 'm/s')
caxis([-0.05 0.05])

%..load chelle colormap if it can be found
tf_chelle = false;
if exist('chelle.mat', 'file')
    load('chelle.mat', 'chelle')
    if exist('chelle', 'var'), tf_chelle = true; end
end
%.. reverse figure 'focus' order;
%.. add dateticks if xaxis is time
%.. change colormap if possible
for ii = 6:-1:1
    figure(ii + figure0)
    xlabel('profile number');
    if tf_chelle
        colormap(chelle);
    end
end

commandwindow
