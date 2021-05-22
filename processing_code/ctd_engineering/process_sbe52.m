function [ctd] = process_sbe52(ctd, meta)
%=========================================================================
% DESCRIPTION
%    Processes CTD sensor data from a SBE52 mounted on a McLane Profiler.
%
% USAGE:  [ctd] = process_sbe52(ctd, meta)
%
%   INPUT
%     ctd  = one element from a structure array created by import_C_sbe52.m 
%     meta = a scalar structure containing all necessary processing parameters
%            created by running import_metadata.m and import_OOI_calfiles.m
%
%   OUTPUT
%     ctd  = a scalar structure with the following fields populated:
%       data fields:
%         salinity
%         theta
%         sigma_theta
%       text fields:
%         data_status
%         code_history
%
% DEPENDENCIES
%   Matlab R2018b
%   TEOS-10 GSW Toolbox
%   celltm.m  (appended to this routine)
%   sbefilter.m
%   Toolebox_shift.m
%
% NOTES
%    Actions (processing sequence advocated by Seabird):
%        low pass filters (no induced lag):
%            conductivity
%            temperature
%            pressure
%        time shifts (positive values shift variables to later time):
%            conductivity: value used should minimize salinity spiking
%            pressure: value used should minimize up-down hysteresis
%                in the temperature record. it is expected that the
%                pressure record will be shifted to earlier time
%                by using a negative value for its shift.
%            temperature: is not shifted.
%        applies a thermal mass correction to conductivity
%        calculates
%            practical salinity
%            potential temperature (theta)
%            density (sigma_theta)
%            time derivative of pressure
%        writes meta fields into appropriate ctd fields
%
%     Deetermines profiling direction.
%     Calculates a profile mask denoting true = good data based on
%     maintaining a minimum profiling speed. 
%
% REFERENCES
%   celltm.m:  coded by RADesiderio (<= 2005) from:
%   Morison, Andersen, Larson, D'Asaro, and Boyd. 1994. "The Correction
%   for Thermal-Lag Effects in Sea-Bird CTD Data". J. Atm. Oc. Tech. 11: 
%   1151-1164.
%
%   GSW Toolbox (TEOS-10)
%   McDougall, T.J. and P.M. Barker, 2011: "Getting started with TEOS-10 and
%   the Gibbs Seawater (GSW) Oceanographic Toolbox", 28pp., SCOR/IAPSO WG127,
%   ISBN 978-0-646-55621-5.
%
% AUTHOR
%   Russ Desiderio, desi@ceoas.oregonstate.edu
%
% REVISION HISTORY
%.. 2019-07-16: desiderio: radMMP version 2.00c (OOI coastal)
%.. 2020-02-17: desiderio: radMMP version 2.10c (OOI coastal)
%.. 2020-05-04: desiderio: radMMP version 3.00 (OOI coastal and global)
%.. 2020-05-08: desiderio: radMMP version 2.11c (OOI coastal)
%.. 2021-05-10: desiderio: radMMP version 2.20c (OOI coastal)
%.. 2021-05-14: desiderio: radMMP version 3.10 (OOI coastal and global)
%.. 2021-05-24: desiderio: radMMP version 4.0
%=========================================================================

ctd.deployment_ID = meta.deployment_ID;
ctd.code_history(end+1) = {mfilename};

if isempty(ctd.pressure)
    ctd.data_status(end+1) = {'CTD not processed'};
    return
end

%.. low-pass filter conductivity, temperature, and pressure.
%..   no lag is introduced because the filter is run in both the 
%..   forwards and backwards directions.
C = sbefilter(ctd.conductivity, meta.ctd_acquisition_rate_Hz, ...
    meta.conductivity_filter_time_constant_sec);
T = sbefilter(ctd.temperature, meta.ctd_acquisition_rate_Hz, ...
    meta.temperature_filter_time_constant_sec);
P = sbefilter(ctd.pressure, meta.ctd_acquisition_rate_Hz, ...
    meta.pressure_filter_time_constant_sec);

%.. apply shifts to align conductivity and pressure data to temperature;
%.. it is assumed that the temperature time constant is significantly 
%.. shorter than that for pressure.
%..   the shift routine shifts with respect to index;
%..   convert shift units from seconds to index number.
C = Toolebox_shift(C, ...
    meta.conductivity_shift_sec * meta.ctd_acquisition_rate_Hz);
P = Toolebox_shift(P, ...
    meta.pressure_shift_sec * meta.ctd_acquisition_rate_Hz);

%.. apply the cell thermal mass correction to conductivity
%..   for now, use previously written routine I wrote
%..   based on primary reference and seabird documentation.
%.. units of C imported from SBE52 are mmho/cm = mS/cm
[C, ~] = celltm(C, T,             ...
    meta.ctd_acquisition_rate_Hz, ...
    meta.thermal_mass_alpha,      ...
    meta.thermal_mass_inverse_beta);

%.. fill in C,T,P structure fields with newly processed values
ctd.conductivity = C;
ctd.temperature = T;
ctd.pressure = P;
%.. calculate pressure time derivative
%.. same as gradient but faster
dP = diff(P);
dPa = [dP(1); dP];
dPb = [dP; dP(end)];
ctd.dpdt = (dPa+dPb) * ctd.acquisition_rate_Hz_calculated / 2;  % [db/sec]

%.. calculate practical salinity, potential temperature, and density
%.. using teos-10 gibbs seawater routines
ctd.salinity    = gsw_SP_from_C(C, T, P);
%
Absolute_Salinity = gsw_SA_from_SP(ctd.salinity, P, ...
    meta.longitude, meta.latitude);
ctd.theta = gsw_pt0_from_t(Absolute_Salinity, T, P);
%
Conservative_Temperature = gsw_CT_from_t(Absolute_Salinity, T, P);
ctd.sigma_theta = gsw_sigma0(Absolute_Salinity, Conservative_Temperature);   

%.. calculate a profile mask (true = 1 denotes good data) based on the
%.. speed of the profiler; some deployments do not excise the very
%.. end of the (descending) profiles when the profiler isn't profiling. 
window    = meta.ctd_speedWindow_npts;
min_speed = meta.ctd_speedMin_db_per_sec;
%
P = ctd.pressure(:);
[minP, idxmin] = min(P);
[maxP, idxmax] = max(P);
%.. speed is positive in the profiling direction when formulated as
profiler_speed = (sign(idxmax-idxmin) * [diff(P); 0]) * ...
    ctd.acquisition_rate_Hz_calculated;
tf = profiler_speed > min_speed;
%.. make mask based on movsum
mvsm = movsum(tf, window);
ctd.profile_mask = mvsm==window;

%.. later add-on - determine profiling direction here; during some deployments,
%.. parity switched (ie, odd numbers became descending) 
idx_dir = idxmax - idxmin;
if maxP-minP <= 5
    ctd.profile_direction = 'stationary';
elseif idx_dir > 0
    ctd.profile_direction = 'descending';
else
    ctd.profile_direction = 'ascending';
end

ctd.binning_parameters = meta.ctd_binning_parameters;

ctd.data_status(end+1) = {'CTD processed'};

end

%=========================================================================
%                SUBROUTINE  celltm
%=========================================================================
function   [ccorr, tcorr] = celltm(c,t,acqrate,alpha,inversebeta)
% function [ccorr tcorr] = celltm(c,t,acqrate,alpha,inversebeta)
% desiderio; oregon state university
% code dates from 2005 or earlier 
%
% celltm calculates both conductivity (ccorr) and temperature (tcorr)
% corrected for the thermal mass effect of the conductivity cell.
% 
% ***********************************************************
% TO CALCULATE SALINITY, USE EITHER:
%    t with (advanced) ccorr, OR
%    tcorr with (advanced) c.
% *********************************************************** 
%
% INPUT VARIABLES: for arrays, time increases as row # increases
% c           (mxn) = conductivity (advanced) [mS/cm] 
% t           (mxn) = temperature [celsius]
% acqrate     (1x1) = acquisition rate of c and t [hertz]
% alpha       (1xn) = thermal anomaly amplitude [unitless]
% inversebeta (1xn) = thermal anomaly time constant [s]
%
% OUTPUT:
% ccorr       (mxn) = corrected conductivity [mS/cm]
% tcorr       (mxn) = corrected temperature [Celsius]
%
% the corresponding columns of t and c will be corrected with
% the corresponding column values of alpha and inversebeta

% because the conductivity cell has thermal mass,
% the temperature of the water in the cell will not be
% the same as that measured by the thermistor. therefore,
% salinity calculated with temperature and (advanced) 
% conductivity will be slightly inaccurate.
% 
% there are two ways of correcting for this effect; see
% "The Correction for Thermal-Lag Effects in Sea-Bird CTD Data"
% Morison, Andersen, Larson, D'Asaro, and Boyd
% J. Atm. Oc. Tech. 11 pp 1151-1164 (1994).
% both methods are implemented in this script.
%
% the first is to correct the (advanced) conductivity record, 
% as is done in the seasoft routine celltm. this script calculates
% that corrected conductivity (ccorr) in the matlab environment.
% to then calculate salinity, use the temperature record as measured 
% by the thermistor with ctm.
% 
% the second way is to correct the thermistor temperature to what
% the temperature was in the conductivity cell [tcorr], and use
% this tcorr with 'uncorrected' (but advanced) conductivity to 
% calculate salinity.


% trap out argin mistakes
if any(acqrate<0)
    error(' acqrate must be positive.');
end
if any(alpha<0)
    error(' alpha must be positive.');
end
if any(inversebeta<0)
    error(' inversebeta must be positive.');
end

% check dimensions of input arguments
if ~isscalar(acqrate)
    error(' acqrate must be a scalar.');
end
[mt, nt] = size(t);
[mc, nc] = size(c);
[ma, na] = size(alpha);
[mi, ni] = size(inversebeta);

if ma~=1 || mi~=1
    error(' alpha and inversebeta must be either scalars or row vectors.');
elseif na~=ni
    error(' alpha and inversebeta must have the same number of elements.');
end

if mc~=mt || nt~=nc
    error(' cond and temp arrays must have the same dimensions.');
end
    
if isscalar(alpha)
    alpharow=repmat(alpha,1,nt);
    inversebetarow=repmat(inversebeta,1,nt);
elseif nt~=na
    error(' column number mismatch between (t and c) v. (alpha and inversebeta).');
else
    alpharow=alpha;
    inversebetarow=inversebeta;
end
if mt<3
    error(' input t and c arrays must have more than 2 rows.');
end

% calculate row coeffs:
A=(2*alpharow)./(2+1./(acqrate*inversebetarow));
B=(1-2*A./alpharow);

% predimension output variables
ccorr=nan(mt,nt);
tcorr=nan(mt,nt);

% take out NaNs before processing! else, output values
% are all NaN; then restore NaNs after processing.

% since each column of x may have a different number of NaNs,
% trying to excise NaNs in a vectorized manner can result in
% a 2-dimensional x collapsing into a column vector - no good.
% alternative - one can knock out a row if one or more of its 
% elements are NaNs, but this throws away good data in the 
% non-NaN-containing column.
% so - process one column at a time.


for jcol=1:nt
    cmask=c(:,jcol);
    tmask=t(:,jcol);
    mask=~( isnan(cmask) | isnan(tmask) );
    cmask=cmask(mask);
    tmask=tmask(mask);
    if isempty(cmask)
        error(' Too many NaNs in input c and t records.');
    end
    last=length(cmask);
% the seasoft implementation has a scaling factor of
% 0.1 in the expression for dc[S/m]/dt; however, this
% script's conductivity units are mS/cm, requiring an
% additional factor of 10, and 10 * 0.1 = 1.
    dcdt=1+0.006*(tmask-20);  
    dt=zeros(last,1);
    dt(2:last)=tmask(2:last)-tmask(1:last-1);
% preallocate the sizes of the incremental corrections
% ctm and ttm, and be sure the first elements are 0.
    ctm=zeros(last,1);
    ttm=zeros(last,1);
    for i=2:last
        ctm(i)=-B(jcol)*ctm(i-1)+A(jcol)*dt(i).*dcdt(i);
        ttm(i)=-B(jcol)*ttm(i-1)+A(jcol)*dt(i);
    end
    cpctm=cmask+ctm; % note difference in the signs of the corrections.
    tmttm=tmask-ttm;
% reconstitute ccorr and tcorr with original placement of NaNs
    crecon=nan(mt,1);
    crecon(mask)=cpctm;
    ccorr(:,jcol)=crecon;
    trecon=nan(mt,1);
    trecon(mask)=tmttm;
    tcorr(:,jcol)=trecon;
    clear cmask tmask last dcdt dt ctm ttm cpctm tmttm crecon trecon
end

end  % celltm
%--------------------------------------------------------------------
