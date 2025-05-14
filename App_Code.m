classdef Medium_Transmission_Line_Calculator < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        GridLayout                      matlab.ui.container.GridLayout
        EyyphanAKIRLabel                matlab.ui.control.Label
        Image                           matlab.ui.control.Image
        MediumTransmissionLineCalculatorLabel  matlab.ui.control.Label
        CalculateButton                 matlab.ui.control.Button
        UITable                         matlab.ui.control.Table
        SendingendpowerfactorEditField  matlab.ui.control.NumericEditField
        SendingendpowerfactorEditFieldLabel  matlab.ui.control.Label
        TransmissionLineLengthkmEditField  matlab.ui.control.NumericEditField
        TransmissionLineLengthkmEditFieldLabel  matlab.ui.control.Label
        SystemFrequencyHzEditField      matlab.ui.control.NumericEditField
        SystemFrequencyHzEditFieldLabel  matlab.ui.control.Label
        PerunitlenghtconductanceskmEditField  matlab.ui.control.NumericEditField
        PerunitlenghtconductanceskmEditFieldLabel  matlab.ui.control.Label
        PerunitlenghtcapacitanceFkmEditField  matlab.ui.control.NumericEditField
        PerunitlenghtcapacitanceFkmEditFieldLabel  matlab.ui.control.Label
        PerunitlenghtinductancemHkmEditField  matlab.ui.control.NumericEditField
        PerunitlenghtinductancemHkmEditFieldLabel  matlab.ui.control.Label
        PerunitlenghtresistancekmEditField  matlab.ui.control.NumericEditField
        PerunitlenghtresistancekmEditFieldLabel  matlab.ui.control.Label
        SendingendcurrentIEditField     matlab.ui.control.NumericEditField
        SendingendcurrentIEditFieldLabel  matlab.ui.control.Label
        Sendingend3voltagekVEditField   matlab.ui.control.NumericEditField
        Sendingend3voltagekVEditFieldLabel  matlab.ui.control.Label
        AngleModeButtonGroup            matlab.ui.container.ButtonGroup
        currentslagsvoltageButton       matlab.ui.control.RadioButton
        currentsleadsvoltageButton      matlab.ui.control.RadioButton
        UIAxes                          matlab.ui.control.UIAxes
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: CalculateButton
        function CalculateButtonPushed(app, event)
 %% 1) Girdileri Alma Kısmı
    Vs3ph = app.Sendingend3voltagekVEditField.Value;       % kV
    Ism   = app.SendingendcurrentIEditField.Value;         % A
    r_per = app.PerunitlenghtresistancekmEditField.Value;  % Ω/km
    L_per = app.PerunitlenghtinductancemHkmEditField.Value;% mH/km
    C_per = app.PerunitlenghtcapacitanceFkmEditField.Value;% μF/km
    g_per = app.PerunitlenghtconductanceskmEditField.Value;% μS/km
    f     = app.SystemFrequencyHzEditField.Value;          % Hz
    Length= app.TransmissionLineLengthkmEditField.Value;   % km
    pf_s  = app.SendingendpowerfactorEditField.Value;      % güç faktörü

    % Lead/Lag kontrolü
    if app.currentsleadsvoltageButton.Value
        leadlag =  1;
    else
        leadlag = -1;
    end

    %% 2) Ortak Hat Parametreleri Hesabı
    Z = r_per*Length + 1j*2*pi*f*(L_per*1e-3*Length);   % Ω
    Y = g_per*1e-6*Length + 1j*2*pi*f*(C_per*1e-6*Length);% S

    Vs_ph = Vs3ph*1e3/sqrt(3);      % V (faz gerilimi)
    theta = acos(pf_s);
    if leadlag<0
        Is_ph = Ism*(cos(-theta) + 1j*sin(-theta)); % lagging
    else
        Is_ph = Ism*(cos( theta) + 1j*sin( theta)); % leading
    end

    %% 3) T Modeli ABCD ve Kabul
    A_T = 1 + (Y*Z)/2;  B_T = Z*(1 + (Y*Z)/4);  C_T = Y;  D_T = A_T;
    M_T = inv([A_T, B_T; C_T, D_T]);
    Vr_T = M_T(1,1)*Vs_ph + M_T(1,2)*Is_ph;
    Ir_T = M_T(2,1)*Vs_ph + M_T(2,2)*Is_ph;

    %% 4) Π Modeli ABCD ve Kabul
    A_Pi = 1 + (Y/2)*Z;  B_Pi = Z;  C_Pi = Y*(1 + (Y*Z)/4);  D_Pi = A_Pi;
    M_Pi = inv([A_Pi, B_Pi; C_Pi, D_Pi]);
    Vr_Pi = M_Pi(1,1)*Vs_ph + M_Pi(1,2)*Is_ph;
    Ir_Pi = M_Pi(2,1)*Vs_ph + M_Pi(2,2)*Is_ph;

    %% 5) Fazör Bileşenleri (Gerilim Kaybı Segmentleri)
    % T Modeli: iki seri yarısı + toplam şunt
    Vser_T = Is_ph * Z;              
    Vshunt_T = Vs_ph - Vr_T - Vser_T; 
    % Π Modeli: iki shunt yarısı + toplam seri
    Vsh_Pi = Vs_ph * (Y/2);
    Vser_Pi= (Is_ph - Vsh_Pi) * Z;

    %% 6) UIAxes Üzerine Fazör Diyagramı Çizimi
    cla(app.UIAxes); hold(app.UIAxes,'on'); grid(app.UIAxes,'on'); axis(app.UIAxes,'equal');

    % Renk körlüğü dostu palet
    cmap = lines(7);
    % 1: Vs, 2: T_ser, 3: T_shu, 4: Vr_T, 5: Pi_shu, 6: Pi_ser, 7: Vr_Pi

   % VS fazörü
    quiver(app.UIAxes, 0, 0, real(Vs_ph), imag(Vs_ph), 0, ...
        'Color', cmap(1,:), 'LineWidth', 2, 'DisplayName', 'Vs');
    % 1) Kabul gerilimi V_r(T) — orijinden başlatılır
quiver(app.UIAxes, 0, 0, real(Vr_T), imag(Vr_T), 0, ...
    'Color', cmap(4,:), 'LineWidth', 2, 'DisplayName', 'V_r(T)');

% 2) Şönt kayıp V_shunt_T — V_r(T)'nin ucundan başlar
start_shunt = [ real(Vr_T), imag(Vr_T) ];
quiver(app.UIAxes, start_shunt(1), start_shunt(2), ...
    real(Vshunt_T), imag(Vshunt_T), 0, ...
    'Color', cmap(3,:), 'LineStyle', '--', 'LineWidth', 1.5, ...
    'DisplayName', 'V_{sh}(T)');

% 3) Seri kayıp V_ser_T — şöntün ucundan başlar
end_shunt = start_shunt + [ real(Vshunt_T), imag(Vshunt_T) ];
quiver(app.UIAxes, end_shunt(1), end_shunt(2), ...
    real(Vser_T), imag(Vser_T), 0, ...
    'Color', cmap(2,:), 'LineStyle', '--', 'LineWidth', 1.5, ...
    'DisplayName', 'V_{ser}(T)');

    % Π Model şunt kayıp
    quiver(app.UIAxes, real(Vs_ph), imag(Vs_ph), -real(Vsh_Pi), -imag(Vsh_Pi),0,'Color',cmap(5,:),'LineStyle','-.','LineWidth',1.5);
    % Π Model seri kayıp (son şunt noktasından)
    quiver(app.UIAxes, real(Vs_ph)-real(Vsh_Pi), imag(Vs_ph)-imag(Vsh_Pi), -real(Vser_Pi), -imag(Vser_Pi),0,'Color',cmap(6,:),'LineStyle','-.','LineWidth',1.5);
    % Π Model kabul
    quiver(app.UIAxes, 0,0, real(Vr_Pi), imag(Vr_Pi),0,'Color',cmap(7,:),'LineWidth',2);

    % Axes ayarları
    maxV = max([abs(Vs_ph), abs(Vr_T), abs(Vr_Pi)])*1.2;
    axis(app.UIAxes,[-maxV maxV -maxV maxV]);
    title(app.UIAxes,'Fazör Diyagramı');
    xlabel(app.UIAxes,'Real');
    ylabel(app.UIAxes,'Imag');
    legend(app.UIAxes, {'Vs','T-seri','T-shunt','Vr_T','Π-shunt','Π-seri','Vr_Π'}, 'Location','northeastoutside');

    %% 7) Sonuç Tablosu
    % Parametreler
    Parameter = {'VL-L [kV]'; 'V∠ [°]'; 'IL [A]'; 'I∠ [°]'; 'PF'; 'P [MW]'; 'Q [MVAr]'; 'Reg [%]'; 'Eff [%]'};
    % T Modeli değerleri
    vals_T = [ abs(Vr_T)*sqrt(3)/1e3; angle(Vr_T)*180/pi; abs(Ir_T); angle(Ir_T)*180/pi;
               cosd(angle(Vr_T)*180/pi - angle(Ir_T)*180/pi);
               real(3*Vr_T*conj(Ir_T)/1e6); imag(3*Vr_T*conj(Ir_T)/1e6);
               ( (Vs3ph - abs(Vr_T)*sqrt(3)/1e3 ) / (abs(Vr_T)*sqrt(3)/1e3) )*100;
               ( real(3*Vr_T*conj(Ir_T)/1e6) / real(3*Vs_ph*conj(Is_ph)/1e6) )*100 ];
    % Π Modeli değerleri
    vals_Pi = [ abs(Vr_Pi)*sqrt(3)/1e3; angle(Vr_Pi)*180/pi; abs(Ir_Pi); angle(Ir_Pi)*180/pi;
               cosd(angle(Vr_Pi)*180/pi - angle(Ir_Pi)*180/pi);
               real(3*Vr_Pi*conj(Ir_Pi)/1e6); imag(3*Vr_Pi*conj(Ir_Pi)/1e6);
               ( (Vs3ph - abs(Vr_Pi)*sqrt(3)/1e3 ) / (abs(Vr_Pi)*sqrt(3)/1e3) )*100;
               ( real(3*Vr_Pi*conj(Ir_Pi)/1e6) / real(3*Vs_ph*conj(Is_ph)/1e6) )*100 ];

    % Tabloyu oluştur
    app.UITable.Data = table(Parameter, vals_T, vals_Pi, ...
        'VariableNames', {'Parameter','T_Model','Pi_Model'});
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.9294 0.6941 0.1255];
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {147, 51, '3x', '0.7x', '6.62x'};
            app.GridLayout.RowHeight = {'1x', 22, 22, 22, 22, 22, 22, 22, 22, 22, 65, '3.35x'};
            app.GridLayout.BackgroundColor = [0 1 1];

            % Create UIAxes
            app.UIAxes = uiaxes(app.GridLayout);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Layout.Row = [10 12];
            app.UIAxes.Layout.Column = [4 5];

            % Create AngleModeButtonGroup
            app.AngleModeButtonGroup = uibuttongroup(app.GridLayout);
            app.AngleModeButtonGroup.Title = 'Angle Mode';
            app.AngleModeButtonGroup.Layout.Row = 11;
            app.AngleModeButtonGroup.Layout.Column = 1;

            % Create currentsleadsvoltageButton
            app.currentsleadsvoltageButton = uiradiobutton(app.AngleModeButtonGroup);
            app.currentsleadsvoltageButton.Text = 'currents leads voltage ';
            app.currentsleadsvoltageButton.Position = [11 19 143 22];
            app.currentsleadsvoltageButton.Value = true;

            % Create currentslagsvoltageButton
            app.currentslagsvoltageButton = uiradiobutton(app.AngleModeButtonGroup);
            app.currentslagsvoltageButton.Text = 'currents lags voltage';
            app.currentslagsvoltageButton.Position = [11 -3 133 22];

            % Create Sendingend3voltagekVEditFieldLabel
            app.Sendingend3voltagekVEditFieldLabel = uilabel(app.GridLayout);
            app.Sendingend3voltagekVEditFieldLabel.HorizontalAlignment = 'center';
            app.Sendingend3voltagekVEditFieldLabel.Layout.Row = 2;
            app.Sendingend3voltagekVEditFieldLabel.Layout.Column = [1 2];
            app.Sendingend3voltagekVEditFieldLabel.Text = 'Sending end 3ϕ voltage (kV)';

            % Create Sendingend3voltagekVEditField
            app.Sendingend3voltagekVEditField = uieditfield(app.GridLayout, 'numeric');
            app.Sendingend3voltagekVEditField.HorizontalAlignment = 'center';
            app.Sendingend3voltagekVEditField.Layout.Row = 2;
            app.Sendingend3voltagekVEditField.Layout.Column = 3;

            % Create SendingendcurrentIEditFieldLabel
            app.SendingendcurrentIEditFieldLabel = uilabel(app.GridLayout);
            app.SendingendcurrentIEditFieldLabel.HorizontalAlignment = 'center';
            app.SendingendcurrentIEditFieldLabel.Layout.Row = 3;
            app.SendingendcurrentIEditFieldLabel.Layout.Column = [1 2];
            app.SendingendcurrentIEditFieldLabel.Text = 'Sending end current (I)';

            % Create SendingendcurrentIEditField
            app.SendingendcurrentIEditField = uieditfield(app.GridLayout, 'numeric');
            app.SendingendcurrentIEditField.HorizontalAlignment = 'center';
            app.SendingendcurrentIEditField.Layout.Row = 3;
            app.SendingendcurrentIEditField.Layout.Column = 3;

            % Create PerunitlenghtresistancekmEditFieldLabel
            app.PerunitlenghtresistancekmEditFieldLabel = uilabel(app.GridLayout);
            app.PerunitlenghtresistancekmEditFieldLabel.HorizontalAlignment = 'center';
            app.PerunitlenghtresistancekmEditFieldLabel.Layout.Row = 4;
            app.PerunitlenghtresistancekmEditFieldLabel.Layout.Column = [1 2];
            app.PerunitlenghtresistancekmEditFieldLabel.Text = 'Per unit lenght resistance (Ω/km)';

            % Create PerunitlenghtresistancekmEditField
            app.PerunitlenghtresistancekmEditField = uieditfield(app.GridLayout, 'numeric');
            app.PerunitlenghtresistancekmEditField.HorizontalAlignment = 'center';
            app.PerunitlenghtresistancekmEditField.Layout.Row = 4;
            app.PerunitlenghtresistancekmEditField.Layout.Column = 3;

            % Create PerunitlenghtinductancemHkmEditFieldLabel
            app.PerunitlenghtinductancemHkmEditFieldLabel = uilabel(app.GridLayout);
            app.PerunitlenghtinductancemHkmEditFieldLabel.HorizontalAlignment = 'center';
            app.PerunitlenghtinductancemHkmEditFieldLabel.Layout.Row = 5;
            app.PerunitlenghtinductancemHkmEditFieldLabel.Layout.Column = [1 2];
            app.PerunitlenghtinductancemHkmEditFieldLabel.Text = 'Per unit lenght inductance [mH/km)';

            % Create PerunitlenghtinductancemHkmEditField
            app.PerunitlenghtinductancemHkmEditField = uieditfield(app.GridLayout, 'numeric');
            app.PerunitlenghtinductancemHkmEditField.HorizontalAlignment = 'center';
            app.PerunitlenghtinductancemHkmEditField.Layout.Row = 5;
            app.PerunitlenghtinductancemHkmEditField.Layout.Column = 3;

            % Create PerunitlenghtcapacitanceFkmEditFieldLabel
            app.PerunitlenghtcapacitanceFkmEditFieldLabel = uilabel(app.GridLayout);
            app.PerunitlenghtcapacitanceFkmEditFieldLabel.HorizontalAlignment = 'center';
            app.PerunitlenghtcapacitanceFkmEditFieldLabel.Layout.Row = 6;
            app.PerunitlenghtcapacitanceFkmEditFieldLabel.Layout.Column = [1 2];
            app.PerunitlenghtcapacitanceFkmEditFieldLabel.Text = 'Per unit lenght capacitance (μF/km)';

            % Create PerunitlenghtcapacitanceFkmEditField
            app.PerunitlenghtcapacitanceFkmEditField = uieditfield(app.GridLayout, 'numeric');
            app.PerunitlenghtcapacitanceFkmEditField.HorizontalAlignment = 'center';
            app.PerunitlenghtcapacitanceFkmEditField.Layout.Row = 6;
            app.PerunitlenghtcapacitanceFkmEditField.Layout.Column = 3;

            % Create PerunitlenghtconductanceskmEditFieldLabel
            app.PerunitlenghtconductanceskmEditFieldLabel = uilabel(app.GridLayout);
            app.PerunitlenghtconductanceskmEditFieldLabel.HorizontalAlignment = 'center';
            app.PerunitlenghtconductanceskmEditFieldLabel.Layout.Row = 7;
            app.PerunitlenghtconductanceskmEditFieldLabel.Layout.Column = [1 2];
            app.PerunitlenghtconductanceskmEditFieldLabel.Text = 'Per unit lenght conductance (μs/km)';

            % Create PerunitlenghtconductanceskmEditField
            app.PerunitlenghtconductanceskmEditField = uieditfield(app.GridLayout, 'numeric');
            app.PerunitlenghtconductanceskmEditField.HorizontalAlignment = 'center';
            app.PerunitlenghtconductanceskmEditField.Layout.Row = 7;
            app.PerunitlenghtconductanceskmEditField.Layout.Column = 3;

            % Create SystemFrequencyHzEditFieldLabel
            app.SystemFrequencyHzEditFieldLabel = uilabel(app.GridLayout);
            app.SystemFrequencyHzEditFieldLabel.HorizontalAlignment = 'center';
            app.SystemFrequencyHzEditFieldLabel.Layout.Row = 8;
            app.SystemFrequencyHzEditFieldLabel.Layout.Column = [1 2];
            app.SystemFrequencyHzEditFieldLabel.Text = 'System Frequency (Hz)';

            % Create SystemFrequencyHzEditField
            app.SystemFrequencyHzEditField = uieditfield(app.GridLayout, 'numeric');
            app.SystemFrequencyHzEditField.HorizontalAlignment = 'center';
            app.SystemFrequencyHzEditField.Layout.Row = 8;
            app.SystemFrequencyHzEditField.Layout.Column = 3;

            % Create TransmissionLineLengthkmEditFieldLabel
            app.TransmissionLineLengthkmEditFieldLabel = uilabel(app.GridLayout);
            app.TransmissionLineLengthkmEditFieldLabel.HorizontalAlignment = 'center';
            app.TransmissionLineLengthkmEditFieldLabel.Layout.Row = 9;
            app.TransmissionLineLengthkmEditFieldLabel.Layout.Column = [1 2];
            app.TransmissionLineLengthkmEditFieldLabel.Text = 'Transmission Line Length (km)';

            % Create TransmissionLineLengthkmEditField
            app.TransmissionLineLengthkmEditField = uieditfield(app.GridLayout, 'numeric');
            app.TransmissionLineLengthkmEditField.HorizontalAlignment = 'center';
            app.TransmissionLineLengthkmEditField.Layout.Row = 9;
            app.TransmissionLineLengthkmEditField.Layout.Column = 3;

            % Create SendingendpowerfactorEditFieldLabel
            app.SendingendpowerfactorEditFieldLabel = uilabel(app.GridLayout);
            app.SendingendpowerfactorEditFieldLabel.HorizontalAlignment = 'center';
            app.SendingendpowerfactorEditFieldLabel.Layout.Row = 10;
            app.SendingendpowerfactorEditFieldLabel.Layout.Column = [1 2];
            app.SendingendpowerfactorEditFieldLabel.Text = 'Sending end power factor (θ)';

            % Create SendingendpowerfactorEditField
            app.SendingendpowerfactorEditField = uieditfield(app.GridLayout, 'numeric');
            app.SendingendpowerfactorEditField.HorizontalAlignment = 'center';
            app.SendingendpowerfactorEditField.Layout.Row = 10;
            app.SendingendpowerfactorEditField.Layout.Column = 3;

            % Create UITable
            app.UITable = uitable(app.GridLayout);
            app.UITable.ColumnName = {'Parameter'; 'Nominal-T'; 'Nominal-Π'};
            app.UITable.RowName = {};
            app.UITable.Layout.Row = [2 9];
            app.UITable.Layout.Column = [4 5];

            % Create CalculateButton
            app.CalculateButton = uibutton(app.GridLayout, 'push');
            app.CalculateButton.ButtonPushedFcn = createCallbackFcn(app, @CalculateButtonPushed, true);
            app.CalculateButton.Layout.Row = 11;
            app.CalculateButton.Layout.Column = [2 3];
            app.CalculateButton.Text = 'Calculate';

            % Create MediumTransmissionLineCalculatorLabel
            app.MediumTransmissionLineCalculatorLabel = uilabel(app.GridLayout);
            app.MediumTransmissionLineCalculatorLabel.HorizontalAlignment = 'center';
            app.MediumTransmissionLineCalculatorLabel.FontSize = 24;
            app.MediumTransmissionLineCalculatorLabel.FontWeight = 'bold';
            app.MediumTransmissionLineCalculatorLabel.Layout.Row = 1;
            app.MediumTransmissionLineCalculatorLabel.Layout.Column = [1 5];
            app.MediumTransmissionLineCalculatorLabel.Text = 'Medium Transmission Line Calculator';

            % Create Image
            app.Image = uiimage(app.GridLayout);
            app.Image.Layout.Row = 12;
            app.Image.Layout.Column = [1 2];
            app.Image.ImageSource = fullfile(pathToMLAPP, '6cf38b3a-b4a5-406d-87a2-728ff55741d9_removalai_preview.png');

            % Create EyyphanAKIRLabel
            app.EyyphanAKIRLabel = uilabel(app.GridLayout);
            app.EyyphanAKIRLabel.HorizontalAlignment = 'center';
            app.EyyphanAKIRLabel.FontSize = 18;
            app.EyyphanAKIRLabel.FontWeight = 'bold';
            app.EyyphanAKIRLabel.Layout.Row = 12;
            app.EyyphanAKIRLabel.Layout.Column = 3;
            app.EyyphanAKIRLabel.Text = {'242124019'; 'Eyyüphan ÇAKIR'};

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Medium_Transmission_Line_Calculator

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
