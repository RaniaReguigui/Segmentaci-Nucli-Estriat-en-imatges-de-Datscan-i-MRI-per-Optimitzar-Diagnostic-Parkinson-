
%Autora: Rania Reguigui Kharraz.
%Escola Politécnica Superior. Universitat de Girona.
%Treball Final de Grau
%Intersecció entre les màscares de MRI i Datscan (Otsu)

clear all;
close all;

% Defineix la ruta base on estan emmagatzemades les carpetes
baseDir = '/Users/raniareguigui/Desktop/subset_Rania';

% Defineix els grups de pacients
groups = {'CN', 'PD'};

% Inicialitza un array per emmagatzemar els resultats
sumesInterseccio = [];

% Inicialitza una cel·la per guardar etiquetes per al boxplot
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
        datPath = fullfile(groupDir, patientID, 'DAT_resampled', ['thresholding_otsu_' patientID '.nii']);
        
        % Verificar que ambdós arxius existeixin abans de procedir
        if exist(mriPath, 'file') && exist(datPath, 'file')

            % Carregar les imatges
            mascaraMRI = niftiread(mriPath);
            mascaraDATSCAN = niftiread(datPath);

            % Normalitzar usant el percentil 90 només per a DATSCAN
            pct90DATSCAN = prctile(mascaraDATSCAN(:), 90);
            mascaraDATSCAN = double(mascaraDATSCAN) / pct90DATSCAN;

            % Convertir a màscares lògiques
            mascaraMRI = mascaraMRI > mean(mascaraMRI(:));
            mascaraDATSCAN = mascaraDATSCAN > 0.5;  % Llindar per convertir en màscara lògica

            % Intersecció de Màscares
            interseccio = mascaraMRI & mascaraDATSCAN;

            % Calcular la suma dels valors en la intersecció
            sumaValores = sum(interseccio(:));

            totalPxMRI = sum(mascaraMRI(:));
            totalPxDATSCAN = sum(mascaraDATSCAN(:));
            
            % Emmagatzemar els resultats
            sumesInterseccio = [sumesInterseccio, sumaValores];
           
            labels = [labels, {sprintf('%s %s', groups{g}, patientID)}];

            % Visualitzar la màscara MRI, la màscara Datscan, i la intersecció de les màscares
            figure;
            subplot(1, 3, 1);
            imshow(max(mascaraMRI, [], 3), []);
            title('Màscara MRI');

            subplot(1, 3, 2);
            imshow(max(mascaraDATSCAN, [], 3), []);
            title('Màscara Datscan');

            subplot(1, 3, 3);
            imshow(max(interseccio, [], 3), []);
            title(sprintf('Intersecció (Suma = %d)', sumaValores));

        else
            warning('Un o ambdós arxius per al pacient %s no existeixen.', patientID);
        end
    end
end

