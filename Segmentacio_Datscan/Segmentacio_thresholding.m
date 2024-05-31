
%Autora: Rania Reguigui Kharraz.
%Escola Politécnica Superior. Universitat de Girona.
%Treball Final de Grau
%Segmentació nucli estriat en imatge Datscan cerebral, utilitzant Thresholding.


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
        datPath = fullfile(groupDir, patientID, 'DAT', ['dat_' patientID '.nii.gz']);
        
        % Verifica que l'arxiu existeixi abans de seguir
        if exist(datPath, 'file')
            % Carregar la imatge NIfTI
            nii = niftiread(datPath);
            info = niftiinfo(datPath);

            % Convertir la imatge a tipus double abans de la normalització
            nii = double(nii);

            % Normalitzar la imatge al rang [0, 1]
            nii_normalized = nii / max(nii(:));

            %Calcular l'umbral basat en un percentil ajustable de laimatge
            percentil = 99; 
            threshold = prctile(nii_normalized(:), percentil);

            % Aplicar una umbralizació manual
            segmentacion_threshold = nii_normalized >= threshold;

            % Conservar només el component més gran
            CC = bwconncomp(segmentacion_threshold);
            numPixels = cellfun(@numel, CC.PixelIdxList);
            [~, largestIdx] = max(numPixels);
            segmentacion_threshold = false(size(nii_normalized));
            segmentacion_threshold(CC.PixelIdxList{largestIdx}) = true;

            segmentacion_threshold_uint8 = uint8(segmentacion_threshold);

            % Ajustar la informació de l'arxiu NIfTI per afegir les noves
            % dades
            info.Datatype = 'uint8';

            % Guardar la imatge segmentada en format NIfTI
            savePath = fullfile(groupDir, patientID, 'DAT', ['threshold_manual_' patientID '.nii']);
            niftiwrite(segmentacion_threshold_uint8, savePath, info);

           
            disp(['Segmentació guardada com ', savePath]);
        else
            warning(['Arxiu DAT no trobat pel pacient ', patientID]);
        end
    end
end
