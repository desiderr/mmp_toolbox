function plot_ad2cp_MPacm_L2(MPacm_L2, figure0)
%.. desiderio 08-feb-2020
%
%.. creates 2D plots of L2 (binned) AD2CP data
%.. xaxis_variable can be either 'time' or 'profile';
%
% MPacm_L2 is the output of Process_McLane_AD2CP_Deployment
% figure0 is optional and sets the figure number sequence

if nargin==0
    disp(' ');
    disp('USAGE (needs at least one calling argument):');
    disp('plot_ad2cp_MPacm_L2(MPacm_L2)');
    disp('plot_ad2cp_MPacm_L2(MPacm_L2, figureNumberOffset)');
    disp(' ');
    return
elseif nargin==1
    figure0 = 6200;
end

xaxis_variable = 'profile';
disp(['pcolor x-axis variable is ' xaxis_variable '.']);

time        = MPacm_L2.datenum;  % one per profile;
profile     = MPacm_L2.profiles_selected;
if strcmpi(xaxis_variable, 'profile')
    xVariable = profile;
else
    xVariable = time;
end

if length(profile)==1
    disp('PCOLOR PLOTS REQUIRE MORE THAN ONE PROFILE.');
    disp('PROGRAM plot_ad2cp_MPacm_L2 TERMINATED.');
    return
end

AP = MPacm_L2.binned_acm_aqd_pressure;
AT = MPacm_L2.binned_acm_aqd_temperature;
H  = MPacm_L2.binned_acm_heading;
E  = MPacm_L2.binned_acm_velENU(:, :, 1);
N  = MPacm_L2.binned_acm_velENU(:, :, 2);
U  = MPacm_L2.binned_acm_velENU(:, :, 3);

APBV  = MPacm_L2.acm_pressure_bin_values;
figure(1 + figure0)
pcolor(xVariable, APBV, U);
shading flat
title('velUP')
ylabel('pressure [db]')
axis ij
hcb = colorbar;
title(hcb, 'm/s')
caxis([-0.3 0.3])

figure(2 + figure0)
pcolor(xVariable, APBV, N);
shading flat
axis ij
ylabel('pressure [db]')
title('velNorth')
hcb = colorbar;
title(hcb, 'm/s')
caxis([-0.3 0.3])

figure(3 + figure0)
pcolor(xVariable, APBV, E);
shading flat
title('velEast')
ylabel('pressure [db]')
axis ij
hcb = colorbar;
title(hcb, 'm/s')
caxis([-0.3 0.3])

figure(4 + figure0)
pcolor(xVariable, APBV, H);
shading flat
title('heading')
ylabel('pressure [db]')
axis ij
colormap(hsv)
colorbar
caxis([0 360])

figure(5 + figure0)
pcolor(xVariable, APBV, AT);
shading flat
title({'AD2CP temperature sensor' ...
    '(Nortek thermistors on Aquadopps have time constants of minutes)'});
ylabel('pressure [db]')
axis ij
hcb = colorbar;
title(hcb, '\circC')
caxis([5 15])

figure(6 + figure0)
pcolor(xVariable, APBV, AP);
shading flat
title('AD2CP pressure (absent or zero in early deployments)')
ylabel('pressure [db]')
axis ij
hcb = colorbar;
title(hcb, 'db')
caxis([20 520])

%..load chelle colormap if it can be found
tf_chelle = false;
if exist('chelle.mat', 'file')
    load('chelle.mat', 'chelle')
    if exist('chelle', 'var'), tf_chelle = true; end
end
%.. reverse figure 'focus' order;
%.. add dateticks if xaxis is time
%.. change colormap if possible
for ii = [6 5 4 3 2 1]
    figure(ii + figure0)
    if strcmpi(xaxis_variable, 'time')
        datetick('x', 'yyyy-mm', 'keepLimits')
    else
        xlabel('profile number');
    end
    if tf_chelle && ii~=4
        colormap(chelle);
    end
end

commandwindow
