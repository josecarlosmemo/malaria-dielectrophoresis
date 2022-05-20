classdef Malaria < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure matlab.ui.Figure
        GridLayout matlab.ui.container.GridLayout
        LeftPanel matlab.ui.container.Panel
        RightPanel matlab.ui.container.Panel
        Table matlab.ui.control.Table
        AgregarGlobuloButton matlab.ui.control.Button
        LimpiarGlobulosButton matlab.ui.control.Button
        AjustedeTamanosLabel matlab.ui.control.Label
        SimulaciondeMovimientoButton matlab.ui.control.Button
        SimulacionDiagnsticodeMalariaLabel matlab.ui.control.Label
        PlacaNegativaLabel matlab.ui.control.Label
        SliderLargoNegativo matlab.ui.control.Slider
        PlacaPositivaLabel matlab.ui.control.Label
        SliderLargoPositivo matlab.ui.control.Slider
        DistanciaLabel matlab.ui.control.Label
        Distancia matlab.ui.control.Slider
        GlobulosLabel matlab.ui.control.Label
        EliminarGlobuloButton matlab.ui.control.Button
        TotalLabel matlab.ui.control.Label
        InfectadosLabel matlab.ui.control.Label
        ColoresSwitchLabel matlab.ui.control.Label
        ColoresSwitch matlab.ui.control.Switch
        AjustedeTamanosLabel_2 matlab.ui.control.Label
        JosCarlosMartnezNezLabel matlab.ui.control.Label
        RuyGuzmnCamachoLabel matlab.ui.control.Label
        GerardoCortsLealLabel matlab.ui.control.Label
        graph matlab.ui.control.UIAxes
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    properties (Access = private)
        v = 0.5; % Description
        %L  A   L  A
        medidasRejilla = [3 .2; 3 .2] % Medidas de Largo y Ancho, empezando con la placa negativa.

        Qpos = [1 -1.5; -1 -1.5; 1 1.5; -1 1.5; 1 0; -1 0]; % Vectores de Posición de Carga Qn (-) Qp (+). Representan coodenadas cartecianas.

        % Parametros de la Rejilla
        x1
        x2
        y1
        y2

        % Definición del Campo en X y Y
        xn = .2;
        yn = .2;

        ke = 8.987e9; % Constante de la ley de Coulomb
        e0 = 8.854e-12; % Constante Permitividad del Vacio

        Q = [-10 10 -10 10 -10 10]; % Valor de las cargas, empezando con la placa negativa.

        contadorG = 0; % Contador de globulos rojos totales
        contadorGInf = 0; % Contador de globulos rojos infectados

        Globulos = []; % Matriz de Globulos rojos
        % Posx Posy Posz Eg Fg Infectado d

        radioGlobulo = .15;
        radioCarga = .05;
        dGlobulos

    end

    methods (Access = private)

        function [x, y, z] = getCargas(app, Qvec, Q, xgrid, ygrid, zgrid)
            Ex = app.ke * Q .* (xgrid - Qvec(1)) ./ ((xgrid - Qvec(1)).^2 + (ygrid - Qvec(2)).^2).^1.5;
            Ey = app.ke * Q .* (ygrid - Qvec(2)) ./ ((xgrid - Qvec(1)).^2 + (ygrid - Qvec(2)).^2).^1.5;
            Ez = zgrid;

            x = Ex;
            y = Ey;
            z = Ez;
        end

        function vertices = getVertices(~, v, ancho, largo, shiftX)
            vertices = [v * ancho + shiftX -v * largo -v; % Vertice 1
                    -v * ancho + shiftX -v * largo -v; % Vertice 2
                    -v * ancho + shiftX v * largo -v; % Vertice 3
                    v * ancho + shiftX v * largo -v; % Vertice 4
                    v * ancho + shiftX -v * largo v; % Vertice 5
                    -v * ancho + shiftX -v * largo v; % Vertice 6
                    -v * ancho + shiftX v * largo v; % Vertice 7
                    v * ancho + shiftX v * largo v]; % Vertice 8

        end

        function updateGraph(app)
            cla(app.graph)

            app.Table.Data = transpose(app.Globulos(:, 1:end - 1));

            valuate = @(x) (abs(x) + 1);

            app.x1 = valuate(app.Distancia.Value) * -1;
            app.x2 = valuate(app.Distancia.Value);
            app.y1 = -3;
            app.y2 = 3;

            % MeshGrid
            [xgrid, ygrid] = meshgrid(app.x1:app.xn:app.x2, app.y1:app.yn:app.y2);
            zgrid = xgrid * 0;

            Ex = 0;
            Ey = 0;
            Ez = 0;

            % Obtenemos las Componentes del Campo Electrico
            for i = 1:6 % Se repite por el número de cargas
                [x, y, z] = app.getCargas(app.Qpos(i, :), app.Q(i), xgrid, ygrid, zgrid);
                Ex = Ex + x;
                Ey = Ey + y;
                Ez = Ez + z;
            end

            E = sqrt(Ex.^2 + Ey.^2 + Ez.^2);

            %componentes vectoriales
            i = Ex ./ E;
            j = Ey ./ E;
            k = Ez ./ E;

            caras = [1 2 6 5; %cara 1
                2 3 7 6; %cara 2
                3 4 8 7; %cara 3
                1 4 8 5; %cara 4
                5 6 7 8; %cara 5 (arriba)
                1 2 3 4]; %cara 6 (abajo)

            hold(app.graph, 'on');
            % Dibuja Elementos del Campo
            patch(app.graph, 'Faces', caras, 'Vertices', app.getVertices(app.v, app.medidasRejilla(2, 2), app.medidasRejilla(2, 1), app.Qpos(2, 1)), 'FaceColor', 'r');
            patch(app.graph, 'Faces', caras, 'Vertices', app.getVertices(app.v, app.medidasRejilla(1, 2), app.medidasRejilla(1, 1), app.Qpos(1, 1)), 'FaceColor', 'b');
            quiver3(app.graph, xgrid, ygrid, zgrid, i, j, k);
            % Ajuste de Tamaño
            app.graph.XLim = [app.x1, app.x2];
            app.graph.YLim = [-3 3];
            app.graph.ZLim = app.graph.XLim;

            app.updateLabels;

        end

        function updateGlobulos(app)

            for i = 1:app.contadorG
                Posx = transpose(app.Globulos(i, 1));
                Posy = transpose(app.Globulos(i, 2));
                Posz = transpose(app.Globulos(i, 3));
                d = transpose(app.Globulos(i, end));

                hold(app.graph, 'on')
                % Graficar el globulo

                [x, y, z] = sphere(10);
                x = x * app.radioGlobulo;
                y = y * app.radioGlobulo;
                z = z * app.radioGlobulo;

                if (transpose(app.Globulos(i, end - 1)) == 1 && str2double(app.ColoresSwitch.Value) == 1)
                surf(app.graph, x + Posx, y + Posy, z + Posz, 'Facecolor', 'black', 'EdgeColor', 'black', 'FaceAlpha', 0.25);
            else
                surf(app.graph, x + Posx, y + Posy, z + Posz, 'Facecolor', 'r', 'EdgeColor', 'r', 'FaceAlpha', 0.25);

            end

            % Graficar cargas del globulo

            [x, y, z] = sphere(10);
            x = x * app.radioCarga;
            y = y * app.radioCarga;
            z = z * app.radioCarga;
            surf(app.graph, x - d + Posx, y + Posy, z + Posz, 'Facecolor', 'k', 'EdgeColor', 'k');
            surf(app.graph, x + d + Posx, y + Posy, z + Posz, 'Facecolor', 'k', 'EdgeColor', 'k');

            hold(app.graph, 'off')

        end

    end

    function updateLabels(app)
        app.TotalLabel.Text = strcat("Total: ", int2str(app.contadorG));
        app.InfectadosLabel.Text = strcat("Infectados: ", int2str(app.contadorGInf));

    end

    function clearGlobulos(app)
        app.Globulos = [];
        app.Table.Data = [];
        app.Table.ColumnName = ('Globulo 0');
        app.contadorG = 0;
        app.contadorGInf = 0;
        app.updateGraph;

    end

end

% Callbacks that handle component events
methods (Access = private)

    % Code that executes after component creation
    function startupFcn(app)
        app.updateGraph;
    end

    % Changes arrangement of the app based on UIFigure width
    function updateAppLayout(app, ~)
        currentFigureWidth = app.UIFigure.Position(3);

        if (currentFigureWidth <= app.onePanelWidth)
            % Change to a 2x1 grid
            app.GridLayout.RowHeight = {772, 772};
            app.GridLayout.ColumnWidth = {'1x'};
            app.RightPanel.Layout.Row = 2;
            app.RightPanel.Layout.Column = 1;
        else
            % Change to a 1x2 grid
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnWidth = {12, '1x'};
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;
        end

    end

    % Value changing function: SliderLargoNegativo
    function SliderLargoNegativoValueChanged(app, event)
        app.medidasRejilla(1, 1) = event.Value;

        app.Qpos(1, 2) = event.Value / 2;

        app.Qpos(3, 2) = ((event.Value) * -1) / 2;

        app.updateGraph;

        app.clearGlobulos;
    end

    % Value changing function: SliderLargoPositivo
    function SliderLargoPositivoValueChanging(app, event)

        app.medidasRejilla(2, 1) = event.Value;

        app.Qpos(2, 2) = event.Value / 2;

        app.Qpos(4, 2) = ((event.Value) * -1) / 2;

        app.updateGraph;

        app.clearGlobulos;

    end

    % Value changing function: Distancia
    function DistanciaValueChanging(app, event)
        app.Qpos(1, 1) = event.Value;
        app.Qpos(2, 1) = (event.Value) * -1;

        app.Qpos(3, 1) = event.Value;
        app.Qpos(4, 1) = (event.Value) * -1;

        app.Qpos(5, 1) = event.Value;
        app.Qpos(6, 1) = (event.Value) * -1;

        app.Distancia.Value = event.Value;

        app.updateGraph;

        app.clearGlobulos;
    end

    % Button pushed function: AgregarGlobuloButton
    function AgregarGlobuloButtonPushed(app, ~)
        % Distancia Aleatoria
        app.dGlobulos = (rand() * app.radioGlobulo);
        % Contador
        app.contadorG = app.contadorG + 1;

        % Posición del globulo
        %TODO: Variar conforme a distancia
        VarFloat = (randi([-100, 100], 1, 1)) / 100;
        Posx = (randi([-1.0, 1.0], 1, 1)) * VarFloat;

        VarFloat = (randi([-100, 100], 1, 1)) / 100;
        Posy = (randi([-1.0, 1.0], 1, 1)) * VarFloat;

        Posz = 0;

        %             test = (app.Distancia.Value-(-app.Distancia.Value))*rand(1,1)+(-app.Distancia.Value);
        %             disp(test)

        %Calcular fuerza y campo electrico
        cargasC = [-2e-6 2e-6];

        E1 = app.ke * (cargasC(1) / (app.dGlobulos * 2)^2);
        E2 = app.ke * (cargasC(2) / (app.dGlobulos * 2)^2);
        Eg = E2 - E1;
        Qneta = 2e-6;
        Fg = Eg * Qneta;
        Infectado = 0;

        if Eg <= 1.25e+6
            Infectado = 1;
            app.contadorGInf = app.contadorGInf + 1;
        end

        app.Globulos = [app.Globulos; Posx Posy Posz Eg Fg Infectado app.dGlobulos];
        app.Table.ColumnName = [app.Table.ColumnName; strcat("Globulo ", int2str(app.contadorG))];

        app.Table.Data = transpose(app.Globulos(:, 1:end - 1));

        app.updateGlobulos;
        app.updateLabels;

    end

    % Button pushed function: SimulaciondeMovimientoButton
    function SimulaciondeMovimientoButtonPushed(app, ~)
        % Store original button text
        originalButtonText = app.SimulaciondeMovimientoButton.Text;
        % When the function ends, return the original button state
        cleanup = onCleanup(@()set(app.SimulaciondeMovimientoButton, 'Text', originalButtonText, 'Icon', ''));
        % Change button name to "Processing"
        app.SimulaciondeMovimientoButton.Text = 'Procesando...';
        % Put text on top of icon
        app.SimulaciondeMovimientoButton.IconAlignment = 'bottom';
        % Create waitbar with same color as button
        wbar = permute(repmat(app.SimulaciondeMovimientoButton.BackgroundColor, 15, 1, 200), [1, 3, 2]);
        % Black frame around waitbar
        wbar([1, end], :, :) = 0;
        wbar(:, [1, end], :) = 0;
        % Load the empty waitbar to the button
        app.SimulaciondeMovimientoButton.Icon = wbar;

        for i = 1:app.contadorG

            if (transpose(app.Globulos(i, end - 1)) == 1 && transpose(app.Globulos(i, 1)) ~= app.Qpos(1, 1))
            anim = linspace(transpose(app.Globulos(i, 1)), app.Qpos(1, 1), 10);

            for j = anim
                app.Globulos(i, 1) = j;
                app.updateGraph;
                app.updateGlobulos;

                % Update progress bar
                currentProg = min(round((size(wbar, 2) - 2) * (i / app.contadorG)), size(wbar, 2) - 2);
                app.SimulaciondeMovimientoButton.Icon(2:end - 1, 2:currentProg + 1, 1) = 0.25391; % (royalblue)
                app.SimulaciondeMovimientoButton.Icon(2:end - 1, 2:currentProg + 1, 2) = 0.41016;
                app.SimulaciondeMovimientoButton.Icon(2:end - 1, 2:currentProg + 1, 3) = 0.87891;
                pause(.1);

            end

        end

    end

end

% Button pushed function: LimpiarGlobulosButton
function LimpiarGlobulosButtonPushed(app, ~)
    app.clearGlobulos;
end

% Button pushed function: EliminarGlobuloButton
function EliminarGlobuloButtonPushed(app, ~)

    app.contadorG = app.contadorG - 1;
    app.Table.Data = transpose(app.Globulos(:, 1:end - 1));

    if (app.Globulos(end, end - 1) == 1)
    app.contadorGInf = app.contadorGInf - 1;

end

app.Globulos(end, :) = [];
app.updateGraph;
app.updateGlobulos;

end

% Value changed function: ColoresSwitch
function ColoresSwitchValueChanged(app, ~)
    app.updateGraph;
    app.updateGlobulos;
end

end

% Component initialization
methods (Access = private)

    % Create UIFigure and components
    function createComponents(app)

        % Create UIFigure and hide until all components are created
        app.UIFigure = uifigure('Visible', 'off');
        app.UIFigure.AutoResizeChildren = 'off';
        app.UIFigure.Color = [1 1 1];
        app.UIFigure.Position = [100 100 1430 772];
        app.UIFigure.Name = 'MATLAB App';
        app.UIFigure.Resize = 'off';
        app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

        % Create GridLayout
        app.GridLayout = uigridlayout(app.UIFigure);
        app.GridLayout.ColumnWidth = {12, '1x'};
        app.GridLayout.RowHeight = {'1x'};
        app.GridLayout.ColumnSpacing = 0;
        app.GridLayout.RowSpacing = 0;
        app.GridLayout.Padding = [0 0 0 0];
        app.GridLayout.Scrollable = 'on';

        % Create LeftPanel
        app.LeftPanel = uipanel(app.GridLayout);
        app.LeftPanel.BorderType = 'none';
        app.LeftPanel.BackgroundColor = [1 1 1];
        app.LeftPanel.Layout.Row = 1;
        app.LeftPanel.Layout.Column = 1;

        % Create RightPanel
        app.RightPanel = uipanel(app.GridLayout);
        app.RightPanel.BorderType = 'none';
        app.RightPanel.BackgroundColor = [1 1 1];
        app.RightPanel.Layout.Row = 1;
        app.RightPanel.Layout.Column = 2;

        % Create Table
        app.Table = uitable(app.RightPanel);
        app.Table.ColumnName = {'Globulo 0'};
        app.Table.RowName = {'Pos x'; 'Pos y'; 'Pos z'; 'Eg'; 'Fuerza '; 'Infectado'};
        app.Table.Position = [1040 524 356 161];

        % Create AgregarGlobuloButton
        app.AgregarGlobuloButton = uibutton(app.RightPanel, 'push');
        app.AgregarGlobuloButton.ButtonPushedFcn = createCallbackFcn(app, @AgregarGlobuloButtonPushed, true);
        app.AgregarGlobuloButton.FontSize = 15;
        app.AgregarGlobuloButton.Position = [1130 452 188 44];
        app.AgregarGlobuloButton.Text = 'Agregar Glóbulo';

        % Create LimpiarGlobulosButton
        app.LimpiarGlobulosButton = uibutton(app.RightPanel, 'push');
        app.LimpiarGlobulosButton.ButtonPushedFcn = createCallbackFcn(app, @LimpiarGlobulosButtonPushed, true);
        app.LimpiarGlobulosButton.FontSize = 15;
        app.LimpiarGlobulosButton.Position = [1130 209 188 44];
        app.LimpiarGlobulosButton.Text = 'Limpiar Glóbulos';

        % Create AjustedeTamanosLabel
        app.AjustedeTamanosLabel = uilabel(app.RightPanel);
        app.AjustedeTamanosLabel.FontSize = 20;
        app.AjustedeTamanosLabel.FontWeight = 'bold';
        app.AjustedeTamanosLabel.Position = [38 617 186 28];
        app.AjustedeTamanosLabel.Text = 'Ajuste de Tamaños';

        % Create SimulaciondeMovimientoButton
        app.SimulaciondeMovimientoButton = uibutton(app.RightPanel, 'push');
        app.SimulaciondeMovimientoButton.ButtonPushedFcn = createCallbackFcn(app, @SimulaciondeMovimientoButtonPushed, true);
        app.SimulaciondeMovimientoButton.BackgroundColor = [0.1176 0.1059 0.2];
        app.SimulaciondeMovimientoButton.FontSize = 16;
        app.SimulaciondeMovimientoButton.FontWeight = 'bold';
        app.SimulaciondeMovimientoButton.FontColor = [1 1 1];
        app.SimulaciondeMovimientoButton.Position = [33 226 226 74];
        app.SimulaciondeMovimientoButton.Text = 'Simulación de Movimiento';

        % Create SimulacionDiagnsticodeMalariaLabel
        app.SimulacionDiagnsticodeMalariaLabel = uilabel(app.RightPanel);
        app.SimulacionDiagnsticodeMalariaLabel.FontSize = 40;
        app.SimulacionDiagnsticodeMalariaLabel.FontWeight = 'bold';
        app.SimulacionDiagnsticodeMalariaLabel.Position = [8 713 694 54];
        app.SimulacionDiagnsticodeMalariaLabel.Text = 'Simulación: Diagnóstico de Malaria';

        % Create PlacaNegativaLabel
        app.PlacaNegativaLabel = uilabel(app.RightPanel);
        app.PlacaNegativaLabel.HorizontalAlignment = 'center';
        app.PlacaNegativaLabel.FontWeight = 'bold';
        app.PlacaNegativaLabel.Position = [35 403 91 22];
        app.PlacaNegativaLabel.Text = 'Placa Negativa';

        % Create SliderLargoNegativo
        app.SliderLargoNegativo = uislider(app.RightPanel);
        app.SliderLargoNegativo.Limits = [1 5];
        app.SliderLargoNegativo.Orientation = 'vertical';
        app.SliderLargoNegativo.ValueChangingFcn = createCallbackFcn(app, @SliderLargoNegativoValueChanged, true);
        app.SliderLargoNegativo.Position = [79 436 3 150];
        app.SliderLargoNegativo.Value = 3;

        % Create PlacaPositivaLabel
        app.PlacaPositivaLabel = uilabel(app.RightPanel);
        app.PlacaPositivaLabel.HorizontalAlignment = 'center';
        app.PlacaPositivaLabel.FontWeight = 'bold';
        app.PlacaPositivaLabel.Position = [160 407 86 22];
        app.PlacaPositivaLabel.Text = 'Placa Positiva';

        % Create SliderLargoPositivo
        app.SliderLargoPositivo = uislider(app.RightPanel);
        app.SliderLargoPositivo.Limits = [1 5];
        app.SliderLargoPositivo.Orientation = 'vertical';
        app.SliderLargoPositivo.ValueChangingFcn = createCallbackFcn(app, @SliderLargoPositivoValueChanging, true);
        app.SliderLargoPositivo.Position = [191 438 3 150];
        app.SliderLargoPositivo.Value = 3;

        % Create DistanciaLabel
        app.DistanciaLabel = uilabel(app.RightPanel);
        app.DistanciaLabel.HorizontalAlignment = 'center';
        app.DistanciaLabel.FontWeight = 'bold';
        app.DistanciaLabel.Position = [32 357 59 22];
        app.DistanciaLabel.Text = 'Distancia';

        % Create Distancia
        app.Distancia = uislider(app.RightPanel);
        app.Distancia.Limits = [0.5 10];
        app.Distancia.ValueChangingFcn = createCallbackFcn(app, @DistanciaValueChanging, true);
        app.Distancia.Position = [95 366 150 3];
        app.Distancia.Value = 2;

        % Create GlobulosLabel
        app.GlobulosLabel = uilabel(app.RightPanel);
        app.GlobulosLabel.FontSize = 20;
        app.GlobulosLabel.FontWeight = 'bold';
        app.GlobulosLabel.Position = [1040 710 186 28];
        app.GlobulosLabel.Text = 'Glóbulos';

        % Create EliminarGlobuloButton
        app.EliminarGlobuloButton = uibutton(app.RightPanel, 'push');
        app.EliminarGlobuloButton.ButtonPushedFcn = createCallbackFcn(app, @EliminarGlobuloButtonPushed, true);
        app.EliminarGlobuloButton.FontSize = 15;
        app.EliminarGlobuloButton.Position = [1130 330 188 44];
        app.EliminarGlobuloButton.Text = 'Eliminar Glóbulo';

        % Create TotalLabel
        app.TotalLabel = uilabel(app.RightPanel);
        app.TotalLabel.FontSize = 20;
        app.TotalLabel.FontWeight = 'bold';
        app.TotalLabel.Position = [1084 73 186 28];
        app.TotalLabel.Text = 'Total: 0';

        % Create InfectadosLabel
        app.InfectadosLabel = uilabel(app.RightPanel);
        app.InfectadosLabel.FontSize = 20;
        app.InfectadosLabel.FontWeight = 'bold';
        app.InfectadosLabel.Position = [1084 28 186 28];
        app.InfectadosLabel.Text = 'Infectados: 0';

        % Create ColoresSwitchLabel
        app.ColoresSwitchLabel = uilabel(app.RightPanel);
        app.ColoresSwitchLabel.HorizontalAlignment = 'center';
        app.ColoresSwitchLabel.Position = [1194 116 47 22];
        app.ColoresSwitchLabel.Text = 'Colores';

        % Create ColoresSwitch
        app.ColoresSwitch = uiswitch(app.RightPanel, 'slider');
        app.ColoresSwitch.Items = {'Apagado', 'Encendido'};
        app.ColoresSwitch.ItemsData = {'0', '1'};
        app.ColoresSwitch.ValueChangedFcn = createCallbackFcn(app, @ColoresSwitchValueChanged, true);
        app.ColoresSwitch.Position = [1195 153 45 20];
        app.ColoresSwitch.Value = '0';

        % Create AjustedeTamanosLabel_2
        app.AjustedeTamanosLabel_2 = uilabel(app.RightPanel);
        app.AjustedeTamanosLabel_2.FontSize = 20;
        app.AjustedeTamanosLabel_2.FontWeight = 'bold';
        app.AjustedeTamanosLabel_2.Position = [38 153 186 28];
        app.AjustedeTamanosLabel_2.Text = 'Equipo:';

        % Create JosCarlosMartnezNezLabel
        app.JosCarlosMartnezNezLabel = uilabel(app.RightPanel);
        app.JosCarlosMartnezNezLabel.Position = [38 116 156 22];
        app.JosCarlosMartnezNezLabel.Text = 'José Carlos Martínez Núñez';

        % Create RuyGuzmnCamachoLabel
        app.RuyGuzmnCamachoLabel = uilabel(app.RightPanel);
        app.RuyGuzmnCamachoLabel.Position = [38 79 130 22];
        app.RuyGuzmnCamachoLabel.Text = 'Ruy Guzmán Camacho';

        % Create GerardoCortsLealLabel
        app.GerardoCortsLealLabel = uilabel(app.RightPanel);
        app.GerardoCortsLealLabel.Position = [38 42 114 22];
        app.GerardoCortsLealLabel.Text = 'Gerardo Cortés Leal';

        % Create graph
        app.graph = uiaxes(app.RightPanel);
        xlabel(app.graph, 'X')
        ylabel(app.graph, 'Y')
        zlabel(app.graph, 'Z')
        app.graph.View = [30 30];
        app.graph.PlotBoxAspectRatio = [1 1.03259023900133 1.16804722046862];
        app.graph.XLim = [-6 6];
        app.graph.YLim = [-6 6];
        app.graph.ZLim = [-6 6];
        app.graph.XGrid = 'on';
        app.graph.YGrid = 'on';
        app.graph.ZGrid = 'on';
        app.graph.Tag = 'graph';
        app.graph.Position = [252 7 833 699];

        % Show the figure after all components are created
        app.UIFigure.Visible = 'on';
    end

end

% App creation and deletion
methods (Access = public)

    % Construct app
    function app = Malaria

        % Create UIFigure and components
        createComponents(app)

        % Register the app with App Designer
        registerApp(app, app.UIFigure)

        % Execute the startup function
        runStartupFcn(app, @startupFcn)

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
