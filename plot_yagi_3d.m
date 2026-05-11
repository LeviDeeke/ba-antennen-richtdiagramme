%% 3D-Richtdiagramm der Yagi-Antenne
% Dieses Skript liest 3D-Messdaten einer Yagi-Antenne aus einer Excel-Datei ein,
% normiert sie auf das globale Maximum, interpoliert sie auf ein feineres Gitter,
% erzeugt daraus ein 3D-Richtdiagramm und zusaetzlich den 2D-Azimutschnitt
% fuer Elevation = 0°.

clear; clc; close all;                 % Workspace, Konsole und Figuren zuruecksetzen

%% Eingabedatei
filename = "Yagi 3D Pattern Horizontal 2.xlsx";   % Name der Excel-Datei mit den Messdaten

%% Darstellungsparameter
dynRange3D = 45;                       % Dynamikbereich fuer die 3D-Farbskala in dB
dynRangePolar = 45;                    % Dynamikbereich fuer den 2D-Polarschnitt in dB

surfaceSmoothWindowAz = 5;             % Fensterbreite fuer leichte Glaettung in Azimutrichtung
lineSmoothWindow = 5;                  % Fensterbreite fuer Glaettung der 2D-Polarkurve

tiltAxis = "Y";                        % Festlegung, um welche Achse die Elevation modelliert wird
flipTiltDirection = true;              % Dreht die Elevationsrichtung um, falls die Geometrie gespiegelt waere

azStart = 0;                           % Startwert der Azimutachse
azDirection = 1;                       % Richtung der Azimutachse, +1 bedeutet normale Laufrichtung
azOffset = 0;                          % Zusaetzlicher konstanter Offset der Azimutachse

baseFontSize = 13;                     % Standardschriftgroesse fuer Achsen und Titel
labelFontSize = 12;                    % Schriftgroesse fuer kleinere Beschriftungen

camZoomFactor = 1.55;                  % Zoomfaktor der 3D-Kamera
viewAz = 28;                           % Azimutwinkel der 3D-Kameraansicht
viewEl = 24;                           % Elevationswinkel der 3D-Kameraansicht
shapeExponent3D = 1.0;                 % Exponent fuer optionale Formskalierung der 3D-Geometrie

axisLineWidth = 1.4;                   % Linienstaerke der eingezeichneten Koordinatenachsen

%% Daten einlesen
P_dB_raw = readmatrix(filename);       % Gesamte Excel-Datei numerisch einlesen
P_dB_raw = rmmissing(P_dB_raw, 1);     % Leere Zeilen entfernen
P_dB_raw = rmmissing(P_dB_raw, 2);     % Leere Spalten entfernen

[nAz, nEl] = size(P_dB_raw);           % Anzahl der Azimut- und Elevationsstuetzstellen bestimmen

%% Winkelachsen aufbauen
azRaw = linspace(0, 360, nAz + 1);     % Gleichverteilte Azimutachse von 0 bis 360° erzeugen
azRaw(end) = [];                       % Letzten Punkt entfernen, damit 0° und 360° nicht doppelt vorkommen

az = azStart + azOffset + azDirection .* azRaw;   % Start, Richtung und Offset auf Azimutwerte anwenden
az = mod(az, 360);                     % Alle Azimutwerte in den Bereich 0...360° zurueckfalten

[az, sortIdx] = sort(az);              % Azimutwerte sortieren und Sortierreihenfolge merken
P_dB_raw = P_dB_raw(sortIdx, :);       % Messmatrix passend zur sortierten Azimutachse umsortieren

el = linspace(0, 90, nEl);             % Elevationsachse gleichverteilt von 0 bis 90° annehmen

%% Globale Normierung
P_dB_norm = P_dB_raw - max(P_dB_raw(:));   % Globales Maximum der gesamten Datei auf 0 dB setzen

P_dB_show_3D = max(P_dB_norm, -dynRange3D);      % 3D-Darstellung auf den gewuenschten Dynamikbereich begrenzen
P_dB_show_polar = max(P_dB_norm, -dynRangePolar);% 2D-Polardarstellung auf den gewuenschten Dynamikbereich begrenzen

%% Feine Zielgitter fuer die Interpolation
azFine = linspace(0, 360, 721);        % Feines Azimutgitter fuer glattere 3D-Oberflaeche
elFine = linspace(0, 90, 361);         % Feines Elevationsgitter fuer glattere 3D-Oberflaeche

%% Azimut zyklisch schliessen
azClosed = [az(:); az(1) + 360];       % Ersten Azimutpunkt bei 360° nochmals anhaengen fuer zyklische Interpolation
PNormClosed = [P_dB_norm; P_dB_norm(1, :)];          % Erste Azimutzeile fuer normierte Daten nochmals anhaengen
PShow3DClosed = [P_dB_show_3D; P_dB_show_3D(1, :)]; % Erste Azimutzeile fuer Darstellungsdaten nochmals anhaengen

%% Schritt 1: Azimut fein interpolieren
P_azinterp_norm = zeros(numel(azFine), nEl);     % Speicher fuer normierte, azimut-interpolierte Daten
P_azinterp_show = zeros(numel(azFine), nEl);     % Speicher fuer dargestellte, azimut-interpolierte Daten

for j = 1:nEl                                   % Ueber alle Elevationsschnitte laufen
    P_azinterp_norm(:, j) = interp1(azClosed, PNormClosed(:, j), azFine, "makima");
    % Normierte Daten entlang des Azimuts mit makima interpolieren

    P_azinterp_show(:, j) = interp1(azClosed, PShow3DClosed(:, j), azFine, "makima");
    % Fuer die Farbdarstellung dieselbe Azimutinterpolation verwenden
end

%% Schritt 2: Elevation fein interpolieren
Pq_dB_norm = zeros(numel(elFine), numel(azFine));      % Speicher fuer voll interpolierte normierte Daten
Pq_dB_show_3D = zeros(numel(elFine), numel(azFine));   % Speicher fuer voll interpolierte Darstellungsdaten

for i = 1:numel(azFine)                                % Ueber alle feinen Azimutrichtungen laufen
    Pq_dB_norm(:, i) = interp1(el, P_azinterp_norm(i, :), elFine, "pchip");
    % Fuer jeden Azimut entlang der Elevation mit pchip interpolieren

    Pq_dB_show_3D(:, i) = interp1(el, P_azinterp_show(i, :), elFine, "pchip");
    % Dasselbe fuer die Darstellungsdaten tun
end

%% Erste Elevationszeile exakt erhalten
Pq_dB_norm(1, :) = P_azinterp_norm(:, 1).';        % Gemessene 0°-Elevationszeile exakt wieder einsetzen
Pq_dB_show_3D(1, :) = P_azinterp_show(:, 1).';     % Dasselbe fuer die 3D-Darstellungsdaten

%% Leichte Glaettung nur in Azimutrichtung
if surfaceSmoothWindowAz > 1                        % Nur glätten, wenn Fensterbreite groesser 1 ist
    Pq_dB_norm = smoothdata(Pq_dB_norm, 2, "movmean", surfaceSmoothWindowAz);
    % Normierte Daten nur entlang der zweiten Dimension, also Azimut, glätten

    Pq_dB_show_3D = smoothdata(Pq_dB_show_3D, 2, "movmean", surfaceSmoothWindowAz);
    % Auch die Darstellungsdaten nur in Azimutrichtung glätten

    Pq_dB_norm(1, :) = P_azinterp_norm(:, 1).';    % Danach die 0°-Elevationszeile wieder exakt zurücksetzen
    Pq_dB_show_3D(1, :) = P_azinterp_show(:, 1).'; % Dasselbe fuer die Darstellungsdaten
end

%% dB-Werte in lineare Feldamplituden umrechnen
R = 10.^(Pq_dB_norm / 20);             % dB-Werte in lineare Feldamplitude umwandeln
R = R ./ max(R(:));                    % Radien auf 1 normieren
R = R .^ shapeExponent3D;              % Optionale Formanpassung ueber Exponent

%% Winkelgitter fuer Geometrie
[AZq, ELq] = meshgrid(azFine, elFine); % 2D-Gitter aus Azimut- und Elevationswerten erzeugen

%% Kugelkoordinaten in kartesische Koordinaten umrechnen
switch tiltAxis
    case "Y"
        X = R .* cosd(AZq) .* cosd(ELq);   % X-Koordinate fuer Y-basierte Elevationsdefinition
        Y = R .* sind(AZq);                % Y-Koordinate
        Z = R .* cosd(AZq) .* sind(ELq);   % Z-Koordinate
    case "X"
        X = R .* cosd(AZq);                % Alternative X-Koordinate
        Y = R .* sind(AZq) .* cosd(ELq);   % Alternative Y-Koordinate
        Z = R .* sind(AZq) .* sind(ELq);   % Alternative Z-Koordinate
end

if flipTiltDirection
    Z = -Z;                                % Z-Richtung invertieren, falls die Elevation sonst falsch herum waere
end

%% Plot-Koordinaten an gewuenschte Darstellungsachsen anpassen
X_plot = Y;                                % Mess-Y wird Plot-X
Y_plot = X;                                % Mess-X wird Plot-Y
Z_plot = Z;                                % Z bleibt Z

%% Ausrichtung anhand des gemessenen 0°-Schnitts
P0 = P_dB_norm(:, 1);                      % Gemessenen Azimutschnitt bei 0° Elevation holen
[~, idxMain] = max(P0);                    % Index der Hauptkeule im 0°-Schnitt bestimmen

mainAz = az(idxMain);                      % Zugehoerigen Azimutwinkel der Hauptkeule holen
xMain0 = sind(mainAz);                     % X-Anteil der Hauptkeulenrichtung in der Plot-Konvention
yMain0 = cosd(mainAz);                     % Y-Anteil der Hauptkeulenrichtung in der Plot-Konvention
mainAngleDeg = atan2d(yMain0, xMain0);     % Winkel der Hauptkeule in der Plot-Ebene berechnen
rotDeg = -mainAngleDeg;                    % Gegenrotation definieren, um die Keule auf die X-Achse zu drehen

X_rot = X_plot .* cosd(rotDeg) - Y_plot .* sind(rotDeg);   % Rotierte X-Koordinaten berechnen
Y_rot = X_plot .* sind(rotDeg) + Y_plot .* cosd(rotDeg);   % Rotierte Y-Koordinaten berechnen
Z_rot = Z_plot;                                             % Z bleibt unveraendert

%% Datengrenzen bestimmen
minX = min(X_rot(:));                      % Kleinstes X der 3D-Flaeche
maxX = max(X_rot(:));                      % Groesstes X der 3D-Flaeche
minY = min(Y_rot(:));                      % Kleinstes Y der 3D-Flaeche
maxY = max(Y_rot(:));                      % Groesstes Y der 3D-Flaeche
minZ = min(Z_rot(:));                      % Kleinstes Z der 3D-Flaeche
maxZ = max(Z_rot(:));                      % Groesstes Z der 3D-Flaeche

maxExtent = max([abs(minX), abs(maxX), abs(minY), abs(maxY), abs(minZ), abs(maxZ)]);
% Groesste absolute Ausdehnung des 3D-Koerpers bestimmen

xAxisLen = 1.35 * maxExtent;               % Laenge der X-Achse definieren
yAxisLen = 0.59 * maxExtent;               % Laenge der Y-Achse definieren
zAxisLen = 0.59 * maxExtent;               % Laenge der Z-Achse definieren

coneLength = 0.04 * maxExtent;             % Laenge der Pfeilspitzen
coneRadius = 0.0135 * maxExtent;           % Radius der Pfeilspitzen
coneResolution = 32;                       % Aufloesung der Pfeilspitzen

xLabelPos = xAxisLen + 0.10 * maxExtent;   % Position der X-Beschriftung
yLabelPos = yAxisLen + 0.10 * maxExtent;   % Position der Y-Beschriftung
zLabelPos = zAxisLen + 0.10 * maxExtent;   % Position der Z-Beschriftung

axisExtentX = 1.10 * xLabelPos;            % Achsenbereich fuer xlim
axisExtentY = 1.10 * yLabelPos;            % Achsenbereich fuer ylim
axisExtentZ = 1.10 * zLabelPos;            % Achsenbereich fuer zlim

%% Figure 1: 3D-Richtdiagramm
figure("Color", "w", "Position", [100 100 1450 920]);   % Neue 3D-Figur erzeugen
hold on;                                                % Mehrere Objekte in derselben Figur zulassen

axisColor = [0.15 0.15 0.15];                          % Dunkelgraue Farbe fuer Achsen

xAxisVisibleStart = maxX;                               % X-Achse beginnt exakt an der Spitze der Hauptkeule
xAxisVisibleEnd = xAxisLen - coneLength;                % X-Achse endet vor der Pfeilspitze

if xAxisVisibleEnd > xAxisVisibleStart                  % Nur zeichnen, wenn wirklich ein sichtbarer Abschnitt existiert
    plot3([xAxisVisibleStart, xAxisVisibleEnd], [0, 0], [0, 0], ...
        "Color", axisColor, "LineWidth", axisLineWidth);
    % Sichtbaren Rest der X-Achse zeichnen
end

plot3([0, 0], [0, yAxisLen - coneLength], [0, 0], ...
    "Color", axisColor, "LineWidth", axisLineWidth);
% Y-Achse zeichnen

plot3([0, 0], [0, 0], [0, zAxisLen - coneLength], ...
    "Color", axisColor, "LineWidth", axisLineWidth);
% Z-Achse zeichnen

surf(X_rot, Y_rot, Z_rot, Pq_dB_show_3D, ...
    "EdgeColor", "none", ...
    "FaceColor", "interp");
% 3D-Oberflaeche zeichnen, Farbe entsprechend dem Pegel

daspect([1 1 1]);                          % Gleiche Skalierung in allen Raumrichtungen
xlim([-0.95 * maxExtent, axisExtentX]);    % X-Achsenbereich setzen
ylim([-axisExtentY, axisExtentY]);         % Y-Achsenbereich setzen
zlim([-axisExtentZ, axisExtentZ]);         % Z-Achsenbereich setzen

view(viewAz, viewEl);                      % Kameraansicht setzen
camzoom(camZoomFactor);                    % Kamera zoomen

title("3D-Richtdiagramm der Yagi-Antenne"); % Titel der 3D-Figur

cmap = turbo(256);                         % Turbo-Colormap mit 256 Farbstufen erzeugen
cmap = 0.88 * cmap + 0.12 * repmat([0.95 0.95 0.95], 256, 1);
% Colormap leicht aufhellen fuer weichere Optik

colormap(cmap);                            % Colormap aktivieren

cb = colorbar;                             % Farbbalken erzeugen
cb.Label.String = "Normierter Pegel (dB)"; % Beschriftung des Farbbalkens setzen
clim([-dynRange3D 0]);                     % Farbgrenzen fuer die 3D-Darstellung setzen

ax = gca;                                  % Aktuelle Achse holen
ax.Visible = "off";                        % Standardachsen ausblenden

%% Kegelspitzen der Achsen
[xc0, yc0, zc0] = cylinder([coneRadius 0], coneResolution);
% Kegelgrundform fuer Pfeilspitzen erzeugen

Xc = (xAxisLen - coneLength) + coneLength * zc0;   % X-Pfeilspitze in X-Richtung verschieben
Yc = xc0;                                          % Kreisquerschnitt auf Y legen
Zc = yc0;                                          % Kreisquerschnitt auf Z legen
surf(Xc, Yc, Zc, ...
    "FaceColor", axisColor, ...
    "EdgeColor", "none", ...
    "FaceLighting", "gouraud");
% X-Pfeilspitze zeichnen

Xc = xc0;                                          % Kreisquerschnitt auf X legen
Yc = (yAxisLen - coneLength) + coneLength * zc0;   % Y-Pfeilspitze in Y-Richtung verschieben
Zc = yc0;                                          % Kreisquerschnitt auf Z legen
surf(Xc, Yc, Zc, ...
    "FaceColor", axisColor, ...
    "EdgeColor", "none", ...
    "FaceLighting", "gouraud");
% Y-Pfeilspitze zeichnen

Xc = xc0;                                          % Kreisquerschnitt auf X legen
Yc = yc0;                                          % Kreisquerschnitt auf Y legen
Zc = (zAxisLen - coneLength) + coneLength * zc0;   % Z-Pfeilspitze in Z-Richtung verschieben
surf(Xc, Yc, Zc, ...
    "FaceColor", axisColor, ...
    "EdgeColor", "none", ...
    "FaceLighting", "gouraud");
% Z-Pfeilspitze zeichnen

%% Achsenbeschriftungen
text(xLabelPos, 0, 0, "X", ...
    "FontSize", baseFontSize, ...
    "FontWeight", "bold", ...
    "HorizontalAlignment", "center", ...
    "VerticalAlignment", "middle", ...
    "Color", axisColor);
% X-Label setzen

text(0, yLabelPos, 0, "Y", ...
    "FontSize", baseFontSize, ...
    "FontWeight", "bold", ...
    "HorizontalAlignment", "center", ...
    "VerticalAlignment", "middle", ...
    "Color", axisColor);
% Y-Label setzen

text(0, 0, zLabelPos, "Z", ...
    "FontSize", baseFontSize, ...
    "FontWeight", "bold", ...
    "HorizontalAlignment", "center", ...
    "VerticalAlignment", "middle", ...
    "Color", axisColor);
% Z-Label setzen

camlight headlight;                        % Frontales Licht setzen
camlight right;                            % Licht von rechts setzen
camlight left;                             % Licht von links setzen
lighting gouraud;                          % Weiche Gouraud-Beleuchtung aktivieren
material([0.24 0.82 0.08 10 1.0]);        % Materialeigenschaften der Oberflaeche setzen

hold off;                                  % Mehrfachzeichnen fuer diese Figur beenden

%% Figure 2: 0°-Azimutschnitt
figure("Color", "w", "Position", [220 180 900 780]);  % Neue Figur fuer Polarschnitt erzeugen

P0_show = P_dB_show_polar(:, 1);           % 0°-Elevationsschnitt holen
P0_show = smoothdata(P0_show, "movmean", lineSmoothWindow);
% 2D-Kurve leicht glätten

alpha = mod(az - mainAz + 360, 360);       % Azimut relativ zur Hauptkeule berechnen
[alpha, idxAlpha] = sort(alpha);           % Sortieren, damit die Kurve geschlossen und geordnet ist

P0_centered = P0_show(idxAlpha);           % Passend sortierte Pegelwerte erzeugen
R0_centered = max(P0_centered + dynRangePolar, 0);
% dB-Werte auf positive Polarradien verschieben

thetaPlot = deg2rad(alpha);                % Winkel in Radiant umrechnen

polarplot(thetaPlot, R0_centered, ...
    "LineWidth", 2.2, ...
    "Color", [0.00 0.30 0.70]);
% Polarkurve zeichnen

hold on;                                   % Weitere Annotationen erlauben

title("Richtdiagramm der Yagi-Antenne (Elevation = 0°)");
% Titel der 2D-Figur setzen

rTicksPolar = (-dynRangePolar:5:0) + dynRangePolar;   % Radiale Tick-Positionen berechnen
dbTicksPolar = -dynRangePolar:5:0;                    % Zugehoerige dB-Beschriftungen definieren

rlim([0 dynRangePolar]);                   % Radialen Bereich setzen
rticks(rTicksPolar);                       % Radiale Tick-Positionen setzen
rticklabels(string(dbTicksPolar));         % Radiale dB-Beschriftungen setzen
thetaticks(0:10:350);                      % Winkel-Ticks setzen

pax = gca;                                 % Aktuelle Polarachse holen
pax.ThetaZeroLocation = "top";             % 0° oben anordnen
pax.ThetaDir = "clockwise";                % Winkel im Uhrzeigersinn laufen lassen
pax.RAxisLocation = 315;                   % Position der radialen Achsenbeschriftung festlegen
pax.RAxis.Label.String = "";               % Standard-Radialachsenlabel entfernen

set(gca, "FontSize", baseFontSize, "LineWidth", 1.0);
% Schriftgroesse und Linienbreite setzen

text(deg2rad(300), dynRangePolar - 15, "Normierter Pegel (dB)", ...
    "HorizontalAlignment", "center", ...
    "VerticalAlignment", "middle", ...
    "FontSize", labelFontSize, ...
    "Color", [0.20 0.20 0.20], ...
    "Clipping", "off");
% Freie Textbeschriftung fuer die Pegelachse setzen

annotation("textbox", [0.61 0.125 0.16 0.035], ...
    "String", "Winkel(°)", ...
    "EdgeColor", "none", ...
    "HorizontalAlignment", "right", ...
    "VerticalAlignment", "middle", ...
    "FontSize", labelFontSize, ...
    "Color", [0.20 0.20 0.20]);
% Zusaetzliche Winkelbeschriftung als Textbox setzen

hold off;                                  % Mehrfachzeichnen beenden

%% Konsolenausgabe
fprintf("Yagi 3D Pattern Horizontal 2 verarbeitet.\n");  % Statusmeldung ausgeben
fprintf("Ausrichtung wurde nur aus der gemessenen 0°-Ebene bestimmt.\n");
% Hinweis zur Ausrichtungslogik ausgeben

fprintf("Elevation wurde mit pchip interpoliert, um die Form runder zu machen.\n");
% Hinweis zur Elevationsinterpolation ausgeben

fprintf("Die 0°-Elevationszeile bleibt exakt erhalten.\n");
% Hinweis ausgeben, dass die Maximalebene unverfaelscht blieb

fprintf("Azimut-Glaettung: Fenster = %d.\n", surfaceSmoothWindowAz);
% Verwendete Glaettungsbreite ausgeben

fprintf("X-Achse beginnt exakt an der Spitze der Hauptkeule.\n");
% Hinweis zur X-Achsen-Darstellung ausgeben

%% Optionaler Export
% exportgraphics(gcf, 'Yagi_0deg_cut.png', 'Resolution', 300);
% Mit dieser Zeile kann die aktuell aktive Figur als PNG gespeichert werden.
