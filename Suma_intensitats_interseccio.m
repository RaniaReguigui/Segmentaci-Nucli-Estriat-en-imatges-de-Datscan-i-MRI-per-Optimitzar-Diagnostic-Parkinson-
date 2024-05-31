
%Autora: Rania Reguigui Kharraz.
%Escola Politécnica Superior. Universitat de Girona.
%Treball Final de Grau
%Càlcul la suma de intensitats en la intersecció de les màscares i t-test

clear all;
close all;

% Defineix la ruta base on estan emmagatzemades les carpetes
baseDir = '/Users/raniareguigui/Desktop/subset_Rania';

% Defineix els grups de pacients
groups = {'CN', 'PD'};

% Inicialitza matrius per emmagatzemar els resultats de cada tipus de segmentació
sumaIntensitatInterseccioMRI_CN = [];
sumaIntensitatInterseccioMRI_PD = [];
sumaIntensitatInterseccioLlindar_CN = [];
sumaIntensitatInterseccioLlindar_PD = [];
sumaIntensitatInterseccioOtsu_CN = [];
sumaIntensitatInterseccioOtsu_PD = [];
sumaIntensitatInterseccioKmeans_CN = [];
sumaIntensitatInterseccioKmeans_PD = [];
sumaIntensitatInterseccioTots_CN = [];
sumaIntensitatInterseccioTots_PD = [];

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

        datScanPath = fullfile(groupDir, patientID, 'DAT_resampled', ['dat_' patientID '.nii.gz']);

        if exist(mriPath, 'file') && exist(datScanPath, 'file')
            imatgeMRI = niftiread(mriPath);
            imatgeDAT = niftiread(datScanPath);
            pct = prctile(imatgeDAT(:), 90);
            imatgeDATNormalitzada = double(imatgeDAT) / pct;

            % Extreure intensitats en la intersecció fent servir la imatge normalitzada
            mascaraMRI = imatgeMRI > mean(imatgeMRI(:));
            intensitatsInterseccio = imatgeDATNormalitzada(mascaraMRI);
            sumaIntensitats = sum(intensitatsInterseccio(intensitatsInterseccio > 0));

            if strcmp(groups{g}, 'CN')
                sumaIntensitatInterseccioMRI_CN(end+1) = sumaIntensitats;
            elseif strcmp(groups{g}, 'PD')
                sumaIntensitatInterseccioMRI_PD(end+1) = sumaIntensitats;
            end
            
            % Processar cada tipus de segmentació DATSCAN i calcular la suma combinada
            mascaraComb = false(size(mascaraMRI)); 
            for j = 1:numel(datPaths)
                if exist(datPaths{j}, 'file')
                    segmentacio = niftiread(datPaths{j});
                    mascaraSegmentacio = segmentacio > mean(segmentacio(:));
                    mascaraComb = mascaraComb | mascaraSegmentacio; % Combinar les màscares utilitzant l'operador OR

                    if strcmp(groups{g}, 'CN')
                        if j == 1
                            sumaIntensitatInterseccioLlindar_CN(end+1) = sum(imatgeDATNormalitzada(mascaraSegmentacio));
                        elseif j == 2
                            sumaIntensitatInterseccioOtsu_CN(end+1) = sum(imatgeDATNormalitzada(mascaraSegmentacio));
                        elseif j == 3
                            sumaIntensitatInterseccioKmeans_CN(end+1) = sum(imatgeDATNormalitzada(mascaraSegmentacio));
                        end
                    elseif strcmp(groups{g}, 'PD')
                        if j == 1
                            sumaIntensitatInterseccioLlindar_PD(end+1) = sum(imatgeDATNormalitzada(mascaraSegmentacio));
                        elseif j == 2
                            sumaIntensitatInterseccioOtsu_PD(end+1) = sum(imatgeDATNormalitzada(mascaraSegmentacio));
                        elseif j == 3
                            sumaIntensitatInterseccioKmeans_PD(end+1) = sum(imatgeDATNormalitzada(mascaraSegmentacio));
                        end
                    end
                end
            end
            % Intersecció de la màscara combinada amb la màscara de MRI
            mascaraComb = mascaraComb & mascaraMRI;
            sumaIntensitats = sum(imatgeDATNormalitzada(mascaraComb));

            if strcmp(groups{g}, 'CN')
                sumaIntensitatInterseccioTots_CN(end+1) = sumaIntensitats;
            elseif strcmp(groups{g}, 'PD')
                sumaIntensitatInterseccioTots_PD(end+1) = sumaIntensitats;
            end
        end
    end
end


% Crear els boxplots comparatius per les sumes de intensitats
figure;
subplotTitles = {'Llindar', 'Otsu', 'K-means', 'Màscara MRI', 'Totes les Màscares'};
dataArrays = {
    sumaIntensitatInterseccioLlindar_CN, sumaIntensitatInterseccioLlindar_PD,
    sumaIntensitatInterseccioOtsu_CN, sumaIntensitatInterseccioOtsu_PD,
    sumaIntensitatInterseccioKmeans_CN, sumaIntensitatInterseccioKmeans_PD,
    sumaIntensitatInterseccioMRI_CN, sumaIntensitatInterseccioMRI_PD,
    sumaIntensitatInterseccioTots_CN, sumaIntensitatInterseccioTots_PD
};

for i = 1:5
    subplot(3, 2, i);
    groupLabels = [repmat({'CN'}, length(dataArrays{2*i-1}), 1); repmat({'PD'}, length(dataArrays{2*i}), 1)];
    boxplot([dataArrays{2*i-1}; dataArrays{2*i}], groupLabels);
    title(subplotTitles{i});
    ylabel('Suma de Intensitat Normalitzada');
    xlabel('Grup de Pacients');
    xtickangle(45);

end

% Emmagatzemar les dades en una matriu per facilitar l'accés en un bucle
data = {
    sumaIntensitatInterseccioLlindar_CN, sumaIntensitatInterseccioLlindar_PD;
    sumaIntensitatInterseccioOtsu_CN, sumaIntensitatInterseccioOtsu_PD;
    sumaIntensitatInterseccioKmeans_CN, sumaIntensitatInterseccioKmeans_PD;
    sumaIntensitatInterseccioMRI_CN, sumaIntensitatInterseccioMRI_PD;
    sumaIntensitatInterseccioTots_CN, sumaIntensitatInterseccioTots_PD
};

% Inicialitzar una taula per guardar els resultats dels p-valors
pValuesTable = table();

% Realitzar el t-test per cada conjunt de dades
for i = 1:size(data, 1)
    [h, p] = ttest2(data{i, 1}, data{i, 2});
    pValuesTable{i, 'pValue'} = p;  % Emmagatzemar el p-valor en la taula
end

% Assignar noms a les files segons el tipus de segmentació
pValuesTable.Properties.RowNames = {'Llindar', 'Otsu', 'K-means', 'Màscara MRI', 'Totes les Màscares'};

% Mostrar la taula de p-valors
disp(pValuesTable);






