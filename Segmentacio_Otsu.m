
%Autora: Rania Reguigui Kharraz.
%Escola Politécnica Superior. Universitat de Girona.
%Treball Final de Grau
%Segmentació nucli estriat en imatge Datscan cerebral, utilitzant mètode Otsu.


clear all;
close all;

% Defineix la ruta base on estan emmagatzemades les carpetes
baseDir = '/Users/raniareguigui/Desktop/subset_Rania';

% Defineix els grups de pacients
groups = {'CN', 'PD'};

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
        nifti_file = fullfile(groupDir, patientID, 'DAT', ['dat_' patientID '.nii.gz']);
        
        % Verificar que l'arxiu existeixi abans de procedir
        if exist(nifti_file, 'file')
            % Carregar la imatge NIfTI
            nii = niftiread(nifti_file);
            info = niftiinfo(nifti_file);

            % Convertir nii a double abans de la normalització
            nii = double(nii);

            % Normalitzar la imatge al rang [0, 1]
            nii_normalized = nii / max(nii(:));

            % Definir la regió d'interés que conté el nucli estriat
            x_start = 50; x_end = 130;
            y_start = 50; y_end = 130;
            z_start = 70; z_end = 100;
            roi = nii_normalized(x_start:x_end, y_start:y_end, z_start:z_end);

            % Calcular l'umbral amb Otsu per la segmentació en la regió d'interés
            threshold = graythresh(roi);

            % Aplicar l'umbral de Otsu per la segmentació en la imatge completa
            segmentacion_otsu = nii_normalized >= threshold;

            % Conservar només el component més gran
            CC = bwconncomp(segmentacion_otsu);
            numPixels = cellfun(@numel, CC.PixelIdxList);
            [~, largestIdx] = max(numPixels);
            segmentacion_otsu = false(size(nii_normalized));
            segmentacion_otsu(CC.PixelIdxList{largestIdx}) = true;

            segmentacion_otsu_uint8 = uint8(segmentacion_otsu);

            % Actualitzar informació de la capçalera per coincidir amb el tipus de dades uint8
            info.Datatype = 'uint8';

            % Guardar la imatge segmentada en format NIfTI
            savePath = fullfile(groupDir, patientID, 'DAT', ['thresholding_otsu_' patientID '.nii']);
            niftiwrite(segmentacion_otsu_uint8, savePath, info);
            disp(['Segmentació Otsu guardada com ', savePath]);
        else
            warning(['Arxiu DAT no trobat pel pacient ', patientID]);
        end
    end
end
