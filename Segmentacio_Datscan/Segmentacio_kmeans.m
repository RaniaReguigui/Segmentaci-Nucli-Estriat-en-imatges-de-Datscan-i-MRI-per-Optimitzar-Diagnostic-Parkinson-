
%Autora: Rania Reguigui Kharraz.
%Escola Politécnica Superior. Universitat de Girona.
%Treball Final de Grau
%Segmentació nucli estriat en imatge Datscan cerebral, utilitzant K-means.

clear all; 
close all;

% Nom de l'arxiu NIfTI
nifti_file = '/Users/raniareguigui/Desktop/subset_Rania/CN/3235/DAT/dat_3235.nii.gz';

% Sol·licitar a l'usuari que introdueixi el factor d'ajust per l'umbral
prompt = 'Introduce 0.9 para imágenes "normals" o 1.6 para imágenes "difícils": ';
adjustment_factor = input(prompt);

% Validar l'entrada de l'usuari
if adjustment_factor ~= 0.9 && adjustment_factor ~= 1.6
    error('Factor ajust no vàlid. Ha de ser 0.9 o 1.6.');
end

% Carregar imatge NIfTI
nii = niftiread(nifti_file);
info = niftiinfo(nifti_file);

% Preparar dades per K-means
data = double(reshape(nii, [], 1));

% Executar K-means amb 3 clústers: fons, cervell i nucli estriat
[labels, centers] = kmeans(data, 3, 'Distance', 'sqEuclidean', 'MaxIter', 150, 'Replicates', 15);

% Reorganitzar les etiquetes a la forma original de la imatge
clustered_img = reshape(labels, size(nii));

% Identificar el clúster del nucli estriat
[~, striatum_cluster] = max(centers);

% Crear màscara del nucli estriat
striatum_mask = clustered_img == striatum_cluster;

% Calculant la intensitat mitja del clúster seleccionat
striatum_mean_intensity = mean(data(clustered_img == striatum_cluster));

% Aplicar un umbral addicional utilitzant la intensidad mitja i el factor d'ajust
intensity_threshold = striatum_mean_intensity * adjustment_factor;

% Refinar màscara del nucli estriat utilitzant l'umbral de intensitat
refined_mask = striatum_mask & (nii > intensity_threshold);

% Etiquetar regions connectades en la màscara refinada
labelled_mask = bwlabeln(refined_mask);

% Propietats de les regions
regions = regionprops3(labelled_mask, 'Volume');

% Trobar la regió amb el volum més gran
[~, largest_region_index] = max(regions.Volume);

% Crear màscara final només amb la regió més gran
final_mask = labelled_mask == largest_region_index;

% Post-processament
se = strel('sphere', 2);
cleaned_mask = imopen(final_mask, se);
filled_mask = imclose(cleaned_mask, se);

% Convertir la màscara a uint8
filled_mask_uint8 = uint8(filled_mask);

% Actualitzar informació de la capçalera per coincidir amb el tipus de dades uint8
info.Datatype = 'uint8';

% Visualització 3D de la segmentació del nucli estriat
figure;
volshow(filled_mask_uint8);
title('Segmentació 3D del nucli estriat');

% Guardar la màscara segmentada com arxiu NIfTI
niftiwrite(filled_mask_uint8, '/Users/raniareguigui/Desktop/subset_Rania/PD/156665/DAT/segmentacio_k-means_156665.nii', info);
disp('Segmentació guardada com segmentacio_k-means.nii');
