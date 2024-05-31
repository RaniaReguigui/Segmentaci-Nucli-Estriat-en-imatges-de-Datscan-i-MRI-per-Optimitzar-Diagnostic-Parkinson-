
%Autora: Rania Reguigui Kharraz.
%Escola Politécnica Superior. Universitat de Girona.
%Treball Final de Grau
%Càlcul de l'especificitat i la sensibilitat per la intersecció de les
%màscares

clear all;
close all;

% Definir la ruta base on s'emmagatzemen les carpetes
baseDir = '/Users/raniareguigui/Desktop/subset_Rania';

% Definir l'estructura de resultats ampliada
results = struct();
methods = {'Llindar', 'Otsu', 'Kmeans'};
groups = {'CN', 'PD'};
for m = 1:numel(methods)
    for g = 1:numel(groups)
        results.(methods{m}).(groups{g}) = struct('sensibilitat', [], 'especificitat', [], 'VP', [], 'VN', [], 'FP', [], 'FN', []);
    end
end

% Bucle sobre cada grup i cada pacient
for g = 1:length(groups)
    groupDir = fullfile(baseDir, groups{g});
    patientFolders = dir(fullfile(groupDir, '*'));
    patientFolders = patientFolders([patientFolders.isdir]);

    for p = 1:length(patientFolders)
        if startsWith(patientFolders(p).name, '.')
            continue;
        end

        patientID = patientFolders(p).name;
        mriPath = fullfile(groupDir, patientID, 'MRI', ['nucleo_estriado_' patientID '.nii.gz']);
        datPaths = {...
            fullfile(groupDir, patientID, 'DAT_resampled', ['threshold_manual_' patientID '.nii']),...
            fullfile(groupDir, patientID, 'DAT_resampled', ['thresholding_otsu_' patientID '.nii']),...
            fullfile(groupDir, patientID, 'DAT_resampled', ['segmentacion_k-means_' patientID '.nii'])
        };

        if exist(mriPath, 'file')
            mascaraMRI = niftiread(mriPath);
            mascaraMRI = mascaraMRI > mean(mascaraMRI(:));

            for j = 1:numel(datPaths)
                if exist(datPaths{j}, 'file')
                    imagenDATSCAN = niftiread(datPaths{j});
                    imagenDATSCANNormalizada = imagenDATSCAN / prctile(imagenDATSCAN(:), 90);
                    mascaraDATSCAN = imagenDATSCANNormalizada > 0.5;

                    % Calcular TP, TN, FP, FN
                    TP = sum(mascaraMRI(:) & mascaraDATSCAN(:));
                    FN = sum(mascaraMRI(:) & ~mascaraDATSCAN(:));
                    TN = sum(~mascaraMRI(:) & ~mascaraDATSCAN(:));
                    FP = sum(~mascaraMRI(:) & mascaraDATSCAN(:));

                    % Calcular sensibilitat i especificitat
                    sens = TP / (TP + FN);
                    espec = TN / (TN + FP);

                    % Acumular resultats
                    method = methods{j};
                    results.(method).(groups{g}).sensibilitat = [results.(method).(groups{g}).sensibilitat; sens];
                    results.(method).(groups{g}).especificitat = [results.(method).(groups{g}).especificitat; espec];
                    results.(method).(groups{g}).VP = [results.(method).(groups{g}).VP; TP];
                    results.(method).(groups{g}).VN = [results.(method).(groups{g}).VN; TN];
                    results.(method).(groups{g}).FP = [results.(method).(groups{g}).FP; FP];
                    results.(method).(groups{g}).FN = [results.(method).(groups{g}).FN; FN];
                end
            end
        end
    end
end

% Crear taula amb els resultats
rowNames = {};
dataTable = [];
for m = 1:numel(methods)
    for g = 1:numel(groups)
        data = results.(methods{m}).(groups{g});
        dataTable = [dataTable; mean(data.sensibilitat), mean(data.especificitat), sum(data.VP), sum(data.VN), sum(data.FP), sum(data.FN)];
        rowNames{end+1} = [methods{m} ' - ' groups{g}];
    end
end

resultTable = array2table(dataTable, 'VariableNames', {'Mitjana_Sensibilitat', 'Mitjana_Especificitat', 'Suma_VP', 'Suma_VN', 'Suma_FP', 'Suma_FN'}, 'RowNames', rowNames);
disp(resultTable);

% Generar boxplots específics per cada mètode en figures separades
for i = 1:length(methods)
    figure; % Crea una nova figura per cada mètode
    subplot(1,2,1); % Sensibilitat
    sensData = [results.(methods{i}).CN.sensibilitat; results.(methods{i}).PD.sensibilitat];
    sensLabels = [repmat({'CN'}, length(results.(methods{i}).CN.sensibilitat), 1); ...
                  repmat({'PD'}, length(results.(methods{i}).PD.sensibilitat), 1)];
    boxplot(sensData, sensLabels);
    title(['Sensibilitat - ' methods{i}]);
    ylabel('Sensibilitat');
    %ylim([0 1]);

    subplot(1,2,2); % Especificitat
    specData = [results.(methods{i}).CN.especificitat; results.(methods{i}).PD.especificitat];
    specLabels = [repmat({'CN'}, length(results.(methods{i}).CN.especificitat), 1); ...
                  repmat({'PD'}, length(results.(methods{i}).PD.especificitat), 1)];
    boxplot(specData, specLabels);
    title(['Especificitat - ' methods{i}]);
    ylabel('Especificitat');
    %ylim([0 1]);
end
