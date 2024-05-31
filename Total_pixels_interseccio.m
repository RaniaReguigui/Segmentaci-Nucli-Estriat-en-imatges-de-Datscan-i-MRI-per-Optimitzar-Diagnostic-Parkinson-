
%Autora: Rania Reguigui Kharraz.
%Escola Politécnica Superior. Universitat de Girona.
%Treball Final de Grau
%Càlcul del total de píxels que hi ha en la intersecció de les màscares

clear all;
close all;

% Defineix la ruta base on estan emmagatzemades les carpetes
baseDir = '/Users/raniareguigui/Desktop/subset_Rania';

% Defineix els grups de pacients
groups = {'CN', 'PD'};

% Inicialitza matrius per emmagatzemar els resultats de cada tipus de
% segmentació i t-test
totalPxelsInterseccioLlindar_CN = [];
totalPxelsInterseccioLlindar_PD = [];
totalPxelsInterseccioOtsu_CN = [];
totalPxelsInterseccioOtsu_PD = [];
totalPxelsInterseccioKmeans_CN = [];
totalPxelsInterseccioKmeans_PD = [];

% Bucle sobre cada grup
for g = 1:length(groups)
    groupDir = fullfile(baseDir, groups{g});
    patientFolders = dir(fullfile(groupDir, '*'));

    % Filtrar per eliminar qualsevol entrada que no sigui un directori
    patientFolders = patientFolders([patientFolders.isdir]);

    % Bucle sobre cada pacient en el grup
    for p = 1:length(patientFolders)
        if startsWith(patientFolders(p).name, '.')
            continue; 
        end
        
        patientID = patientFolders(p).name;
        mriPath = fullfile(groupDir, patientID, 'MRI', ['nucleo_estriado_' patientID '.nii.gz']);
        datPaths = { ...
            fullfile(groupDir, patientID, 'DAT_resampled', ['threshold_manual_' patientID '.nii']), ...
            fullfile(groupDir, patientID, 'DAT_resampled', ['thresholding_otsu_' patientID '.nii']), ...
            fullfile(groupDir, patientID, 'DAT_resampled', ['segmentacion_k-means_' patientID '.nii'])
        };

        % Carregar la màscara MRI i normalitzar
        if exist(mriPath, 'file')
            mascaraMRI = niftiread(mriPath);
            mascaraMRI = mascaraMRI > mean(mascaraMRI(:));

            % Calcular el percentil 90 per totes les imatges DATSCAN d'un pacient
            allDATImages = [];
            for datPath = datPaths
                if exist(datPath{1}, 'file')
                    datImage = niftiread(datPath{1});
                    allDATImages = [allDATImages; datImage(:)];
                end
            end
            pct90 = prctile(allDATImages, 90);

            % Inicialitzar acumuladors de píxels de intersecció per pacient
            sumaPxelsLlindar = 0;
            sumaPxelsOtsu = 0;
            sumaPxelsKmeans = 0;

            % Processar cada tipus de segmentació DATSCAN
            for j = 1:numel(datPaths)
                if exist(datPaths{j}, 'file')
                    mascaraDATSCAN = niftiread(datPaths{j});
                    % Normalitzar fent servir el percentil 90 comú
                    mascaraDATSCAN = double(mascaraDATSCAN) / pct90;
                    mascaraDATSCAN = mascaraDATSCAN > 0.5;  % Aplicar llindar per convertir en màscara lógica

                    interseccion = mascaraMRI & mascaraDATSCAN;
                    numPxeles = sum(interseccion(:));  % Comptar píxels en la intersecció

                    % Acumular píxels de la intersecció segons el mètode de segmentació
                    if j == 1
                        sumaPxelsLlindar = sumaPxelsLlindar + numPxeles;
                    elseif j == 2
                        sumaPxelsOtsu = sumaPxelsOtsu + numPxeles;
                    elseif j == 3
                        sumaPxelsKmeans = sumaPxelsKmeans + numPxeles;
                    end
                end
            end

            % Emmagatzemar els resultats acumulats segons el grup de pacients
            if strcmp(groups{g}, 'CN')
                totalPxelsInterseccioLlindar_CN(end+1) = sumaPxelsLlindar;
                totalPxelsInterseccioOtsu_CN(end+1) = sumaPxelsOtsu;
                totalPxelsInterseccioKmeans_CN(end+1) = sumaPxelsKmeans;
            elseif strcmp(groups{g}, 'PD')
                totalPxelsInterseccioLlindar_PD(end+1) = sumaPxelsLlindar;
                totalPxelsInterseccioOtsu_PD(end+1) = sumaPxelsOtsu;
                totalPxelsInterseccioKmeans_PD(end+1) = sumaPxelsKmeans;
            end
        end
    end
end

% Crear els boxplots comparatius
figure;
subplot(1, 3, 1);
boxplot([totalPxelsInterseccioLlindar_CN, totalPxelsInterseccioLlindar_PD], ...
        [repmat({'CN'}, length(totalPxelsInterseccioLlindar_CN), 1); repmat({'PD'}, length(totalPxelsInterseccioLlindar_PD), 1)]);
title('Llindar');
ylabel('Nombre de Píxels en Intersecció');
xlabel('Grup de Pacients');
xtickangle(45);

subplot(1, 3, 2);
boxplot([totalPxelsInterseccioOtsu_CN, totalPxelsInterseccioOtsu_PD], ...
        [repmat({'CN'}, length(totalPxelsInterseccioOtsu_CN), 1); repmat({'PD'}, length(totalPxelsInterseccioOtsu_PD), 1)]);
title('Otsu');
xlabel('Grup de Pacients');
xtickangle(45);

subplot(1, 3, 3);
boxplot([totalPxelsInterseccioKmeans_CN, totalPxelsInterseccioKmeans_PD], ...
        [repmat({'CN'}, length(totalPxelsInterseccioKmeans_CN), 1); repmat({'PD'}, length(totalPxelsInterseccioKmeans_PD), 1)]);
title('K-means');
xlabel('Grup de Pacients');
xtickangle(45);

% Emmagatzemar les dades en una matriu per facilitar l'accés en un bucle
data = {
    totalPxelsInterseccioLlindar_CN, totalPxelsInterseccioLlindar_PD;
    totalPxelsInterseccioOtsu_CN, totalPxelsInterseccioOtsu_PD;
    totalPxelsInterseccioKmeans_CN, totalPxelsInterseccioKmeans_PD
};

% Inicialitzar una taula per guardar els resultats dels p-valors
pValuesTable = table();

% Realitzar el t-test per cada conjunt de dades
for i = 1:size(data, 1)
    [h, p] = ttest2(data{i, 1}, data{i, 2});
    pValuesTable{i, 'pValue'} = p;  % Emmagatzemar el p-valor en la taula
end

% Assignar noms a les files segons el tipus de segmentació
pValuesTable.Properties.RowNames = {'Llindar', 'Otsu', 'K-means'};

% Mostrar la taula de p-valors
disp(pValuesTable);

