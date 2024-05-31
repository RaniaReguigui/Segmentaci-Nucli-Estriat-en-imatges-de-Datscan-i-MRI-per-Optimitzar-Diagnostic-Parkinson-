
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

% Inicialitza un array per guardar els resultats
sumaInterseccio = [];

% Inicialitza una casella per guardar etiquetes per el boxplot
labels = [];

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
        datPath = fullfile(groupDir, patientID, 'DAT_resampled', ['segmentacion_k-means_' patientID '.nii']);
        
        % Verificar que els dos arxius existeixin
        if exist(mriPath, 'file') && exist(datPath, 'file')
            % Carregar les imatges
            mascaraMRI = niftiread(mriPath);
            mascaraDATSCAN = niftiread(datPath);

            % Normalitzar usant el percentil 90 per a la imatge DATSCAN
            pct90DATSCAN = prctile(mascaraDATSCAN(:), 90);
            mascaraDATSCAN = double(mascaraDATSCAN) / pct90DATSCAN;

            % Convertir a màscares lògiques
            mask = logical(mascaraMRI);
            mascaraDATSCAN = mascaraDATSCAN > 0.5;

            % Intersecció de Màscares
            interseccio = mask & mascaraDATSCAN;

            % Calcular la suma dels valors en la intersecció
            sumaValores = sum(interseccio(:));

            % Calcular el coeficient de Dice
            totalPxMRI = sum(mask(:));
            totalPxDATSCAN = sum(mascaraDATSCAN(:));
            
            sumaInterseccio = [sumaInterseccio, sumaValores];
   
            labels = [labels, {sprintf('%s %s', groups{g}, patientID)}];

            % Visualitzar la màscara MRI, la màscara Datscan, i la intersecció de les màscares
            figure;
            subplot(1, 3, 1);
            imshow(max(mask, [], 3), []);
            title('Màscara MRI');

            subplot(1, 3, 2);
            imshow(max(mascaraDATSCAN, [], 3), []);
            title('Màscara Datscan');

            subplot(1, 3, 3);
            imshow(max(interseccio, [], 3), []);
            title(sprintf('Intersecció (Suma = %d)', sumaValores, coeficientsDice));

        else
            warning('Un o ambdos archius pel pacient %s no existeixen.', patientID);
        end
    end
end


