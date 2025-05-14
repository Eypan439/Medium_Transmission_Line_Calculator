clc; clear all; close all;

%% Kullanıcı Girdileri
Vs3ph = input('Sending end 3ϕ voltage (kV): ');      % kV
Ism    = input('Sending end current (A): ');         % A
r_per  = input('Per-unit length resistance (Ω/km): ');
L_per  = input('Per-unit length inductance (mH/km): ');
C_per  = input('Per-unit length capacitance (µF/km): ');
g_per  = input('Per-unit length conductance (µS/km): ');
f      = input('System Frequency (Hz): ');
Length = input('Transmission Line Length (km): ');
pf_s   = input('Sending end power factor (θ, lagging positive): ');
leadlag= input('Angle mode -> enter +1 if current leads voltage, -1 if lags: ');

%% Ortak Hesaplamalar
Z = ( r_per*Length ) + 1j*2*pi*f*(L_per*1e-3*Length);     % Ω
Y = ( g_per*1e-6*Length ) + 1j*2*pi*f*(C_per*1e-6*Length);% S

Vs_ph = (Vs3ph*1e3)/sqrt(3);        % V (faz)
theta = acos(pf_s);
if leadlag == -1
    Is_ph = Ism * (cos(-theta) + 1j*sin(-theta));  % lagging
else
    Is_ph = Ism * (cos(theta)  + 1j*sin(theta));   % leading
end

%% --- T Modeli ---
A_T = 1 + (Y*Z)/2;
B_T = Z * (1 + (Y*Z)/4);
C_T = Y;
D_T = A_T;
ABCD_T = [A_T, B_T; C_T, D_T];

M_T = inv(ABCD_T);
Vr_T = M_T(1,1)*Vs_ph + M_T(1,2)*Is_ph;
Ir_T = M_T(2,1)*Vs_ph + M_T(2,2)*Is_ph;
Vr3ph_T = abs(Vr_T)*sqrt(3)/1e3;
IrA_T = abs(Ir_T);
angVr_T = angle(Vr_T)*180/pi;
angIr_T = angle(Ir_T)*180/pi;
theta_r_T = angVr_T - angIr_T;
pf_r_T = cosd(theta_r_T);
if theta_r_T > 0, pf_lbl_T='lagging'; else pf_lbl_T='leading'; end
S_r_T = 3 * Vr_T * conj(Ir_T) / 1e6; P_r_T = real(S_r_T); Q_r_T = imag(S_r_T);
VrNL_T = Vs_ph / A_T; VR_T = (abs(VrNL_T)*sqrt(3)/1e3 - Vr3ph_T)/Vr3ph_T*100;
S_s = 3 * Vs_ph * conj(Is_ph) / 1e6; P_s = real(S_s);
eff_T = (P_r_T / P_s)*100;

%% --- Pi Modeli ---
A_Pi = 1 + (Y/2)*Z;
B_Pi = Z;
C_Pi = Y * (1 + (Y/4)*Z);
D_Pi = A_Pi;
ABCD_Pi = [A_Pi, B_Pi; C_Pi, D_Pi];

M_Pi = inv(ABCD_Pi);
Vr_Pi = M_Pi(1,1)*Vs_ph + M_Pi(1,2)*Is_ph;
Ir_Pi = M_Pi(2,1)*Vs_ph + M_Pi(2,2)*Is_ph;
Vr3ph_Pi = abs(Vr_Pi)*sqrt(3)/1e3;
IrA_Pi = abs(Ir_Pi);
angVr_Pi = angle(Vr_Pi)*180/pi;
angIr_Pi = angle(Ir_Pi)*180/pi;
theta_r_Pi = angVr_Pi - angIr_Pi;
pf_r_Pi = cosd(theta_r_Pi);
if theta_r_Pi > 0, pf_lbl_Pi='lagging'; else pf_lbl_Pi='leading'; end
S_r_Pi = 3 * Vr_Pi * conj(Ir_Pi) / 1e6; P_r_Pi = real(S_r_Pi); Q_r_Pi = imag(S_r_Pi);
VrNL_Pi = Vs_ph / A_Pi; VR_Pi = (abs(VrNL_Pi)*sqrt(3)/1e3 - Vr3ph_Pi)/Vr3ph_Pi*100;
eff_Pi = (P_r_Pi / P_s)*100;

%% --- Sonuç Tablosu Oluştur ve Excel'e Yazdır ---
% Verileri bir tabloda topla
Parameter = {
    'Receiving End L-L Voltage (kV)';
    'Voltage Angle (°)';
    'Receiving End Current (A)';
    'Current Angle (°)';
    'Power Factor';
    'Active Power (MW)';
    'Reactive Power (MVAr)';
    'Voltage Regulation (%)';
    'Efficiency (%)'
    };

T_Model = [
    Vr3ph_T;
    angVr_T;
    IrA_T;
    angIr_T;
    pf_r_T;
    P_r_T;
    Q_r_T;
    VR_T;
    eff_T
    ];

Pi_Model = [
    Vr3ph_Pi;
    angVr_Pi;
    IrA_Pi;
    angIr_Pi;
    pf_r_Pi;
    P_r_Pi;
    Q_r_Pi;
    VR_Pi;
    eff_Pi
    ];

% Tabloyu oluştur
resultsTable = table(Parameter, T_Model, Pi_Model, ...
    'VariableNames', {'Parameter', 'T_Model', 'Pi_Model'});

%% Konsol Çıktısı
fprintf('\n--------- Karşılaştırmalı Orta Mesafe Hat Sonuçları (T ve Π Modeli) ---------\n');
disp(resultsTable);
fprintf('-----------------------------------------------------------------------------\n');
