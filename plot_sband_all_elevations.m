%% Alle 2D-Polarschnitte der S-Band-Messung von 0° bis 90°
% Dieses Skript liest die 3D-Messmatrix der S-Band-Messung aus einer
% Excel-Datei ein, normiert alle Werte auf das globale Maximum, richtet
% alle Elevationsschnitte mit derselben festen Rotation aus und stellt sie
% als Kachelansicht von 2D-Polardiagrammen dar.

clear; clc; close all;                  % Workspace, Konsole und geoeffnete Figuren zuruecksetzen

%% Eingabedatei
filename = "S Band 3D.xlsx";            % Name der Excel-Datei mit den Messdaten der S-Band-Antenne

%% Darstellungsparameter
dynRangePolar = 55;                     % Sichtbarer Dynamikbereich der Polarplots in dB
lineSmoothWindow = 5;                   % Fensterbreite fuer die Glaettung entlang des Azimuts

baseFontSize = 12;                      % Standardschriftgroesse fuer Achsen
labelFontSize = 11;                     % Schriftgroesse fuer Untertitel und Hinweise

%% Daten einlesen
P_dB_raw = readmatrix(filename);        % Gesamte Excel-Datei numerisch einlesen
P_dB_raw = rmmissing(P_dB_raw, 1);      % Leere Zeilen entfernen
P_dB_raw = rmmissing(P_dB_raw, 2);      % Leere Spalten entfernen

[nAz, nEl] = size(P_dB_raw);            % Anzahl der Azimut- und Elevationsstuetzstellen bestimmen

%% Winkelachsen aufbauen
azRaw = linspace(0, 360, nAz + 1);      % Gleichverteilte Azimutachse von 0° bis 360° erzeugen
azRaw(end) = [];                        % Letzten Punkt entfernen, damit 0° und 360° nicht doppelt vorkommen
az = azRaw(:);                          % Azimutachse als Spaltenvektor speichern

el = linspace(0, 90, nEl);              % Elevationswerte gleichverteilt von 0° bis 90° annehmen

%% Globale Normierung auf das Maximum der gesamten Datei
P_dB_global_norm = P_dB_raw - max(P_dB_raw(:));
% Das globale Maximum der gesamten Messmatrix wird auf 0 dB gesetzt

P_dB_global_show = max(P_dB_global_norm, -dynRangePolar);
% Alle Werte unterhalb des gewaehlten Dynamikbereichs werden auf -dynRangePolar begrenzt

%% Feste Referenz aus der 0°-Ebene bestimmen
P_ref = P_dB_global_show(:, 1);         % Den ersten Elevationsschnitt, also die 0°-Ebene, holen
P_ref = smoothdata(P_ref, "movmean", lineSmoothWindow);
% Die Referenzkurve leicht glätten, damit die Peak-Bestimmung stabiler wird

[~, idxMainRef] = max(P_ref);           % Index der Hauptkeule in der 0°-Ebene bestimmen
mainAzRef = az(idxMainRef);             % Zugehoerigen Azimutwinkel der Hauptkeule holen

thetaAlignedDeg = mod(az - mainAzRef, 360);
% Alle Azimutwinkel relativ zur Referenzhauptkeule ausdruecken
% Dadurch liegt die Hauptkeule spaeter bei 0°

[thetaAlignedDeg, idxAlign] = sort(thetaAlignedDeg);
% Die relativen Winkel sortieren und die Sortierreihenfolge speichern

thetaPlot = deg2rad(thetaAlignedDeg);   % Sortierte Winkel in Radiant fuer polarplot umrechnen

%% Layout der Kachelansicht bestimmen
nCols = min(5, nEl);                    % Maximal 5 Spalten verwenden
nRows = ceil(nEl / nCols);              % Benoetigte Zeilenanzahl ausrechnen

figure("Color", "w", "Position", [80 60 1650 940]);
% Neue Figur mit weissem Hintergrund und grossem Fenster erzeugen

t = tiledlayout(nRows, nCols, "TileSpacing", "compact", "Padding", "compact");
% Kachel-Layout mit kompakten Abstaenden erzeugen

title(t, "2D-Polarschnitte der S-Band-Antenne für Elevation = 0° bis 90°", ...
    "FontSize", 15, "FontWeight", "bold");
% Gesamttitel ueber der Kachelansicht setzen

%% Alle Elevationsschnitte einzeln plotten
for k = 1:nEl                           % Ueber alle Elevationsspalten der Messmatrix laufen
    nexttile;                           % Naechste Kachel im Layout aktivieren

    P_slice_show = P_dB_global_show(:, k);
    % Den aktuellen Elevationsschnitt aus der global normierten Matrix holen

    P_slice_show = smoothdata(P_slice_show, "movmean", lineSmoothWindow);
    % Aktuellen Schnitt entlang Azimut leicht glätten

    P_centered = P_slice_show(idxAlign);
    % Alle Schnitte mit derselben festen Rotation ausrichten
    % Die Rotation stammt allein aus der Hauptkeule der 0°-Ebene

    R_centered = P_centered + dynRangePolar;
    % dB-Werte in positive Radien fuer den Polarplot verschieben

    R_centered = max(R_centered, 0);
    % Negative Radien vermeiden

    polarplot(thetaPlot, R_centered, ...
        "LineWidth", 1.8, ...
        "Color", [0.00 0.30 0.70]);
    % Den aktuellen Elevationsschnitt als Polarkurve zeichnen

    hold on;                            % Weitere Formatierungen in derselben Kachel erlauben

    pax = gca;                          % Aktuelle Polarachse holen
    pax.ThetaZeroLocation = "top";      % 0° oben platzieren
    pax.ThetaDir = "clockwise";         % Winkel im Uhrzeigersinn laufen lassen
    pax.RAxisLocation = 315;            % Position der radialen Beschriftung setzen
    pax.RAxis.Label.String = "";        % Standard-Radialachsenlabel entfernen

    rTicksPolar = (-dynRangePolar:10:0) + dynRangePolar;
    % Radiale Tick-Positionen im verschobenen Koordinatensystem berechnen

    dbTicksPolar = -dynRangePolar:10:0;
    % Zugehoerige dB-Beschriftungen definieren

    rlim([0 dynRangePolar]);            % Sichtbaren radialen Bereich setzen
    rticks(rTicksPolar);                % Radiale Tick-Positionen setzen
    rticklabels(string(dbTicksPolar));  % Radiale Tick-Beschriftungen in dB setzen
    thetaticks(0:30:330);               % Winkel-Ticks in 30°-Schritten setzen

    set(gca, "FontSize", baseFontSize, "LineWidth", 1.0);
    % Standardschriftgroesse und Linienbreite fuer die Kachel setzen

    title(sprintf("Elevation = %.0f°", el(k)), ...
        "FontSize", labelFontSize, ...
        "FontWeight", "bold");
    % Titel fuer die jeweilige Kachel setzen

    hold off;                           % Zeichnen in dieser Kachel abschliessen
end

%% Hinweis unterhalb der Kachelansicht
annotation("textbox", [0.32 0.01 0.36 0.035], ...
    "String", "Angaben in dB, bezogen auf das globale Maximum.", ...
    "EdgeColor", "none", ...
    "HorizontalAlignment", "center", ...
    "VerticalAlignment", "middle", ...
    "FontSize", 11, ...
    "Color", [0.20 0.20 0.20]);
% Fussnote unter die Gesamtfigur setzen

%% Konsolenausgabe
fprintf("Alle %d Polarschnitte für S Band 3D erstellt.\n", nEl);
% Anzahl der erzeugten Schnitte ausgeben

fprintf("Referenz-Hauptkeule aus der 0°-Ebene: %.2f°.\n", mainAzRef);
% Azimut der verwendeten Referenzhauptkeule ausgeben

fprintf("Alle Angaben in dB sind auf das globale Maximum der gesamten Datei bezogen.\n");
% Hinweis zur Normierung ausgeben

fprintf("HPBW und -3-dB-Kreis wurden bewusst nicht eingezeichnet.\n");
% Hinweis zur Darstellungsentscheidung ausgeben

%% Optionaler Export
% exportgraphics(gcf, 'SBand_All_Elevations.png', 'Resolution', 300);
% Mit dieser Zeile kann die gesamte Kachelansicht als PNG gespeichert werden.
