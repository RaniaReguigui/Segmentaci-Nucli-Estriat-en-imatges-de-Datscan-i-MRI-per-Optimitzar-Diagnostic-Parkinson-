
%Autora: Rania Reguigui Kharraz.
%Escola Politécnica Superior. Universitat de Girona.
%Treball Final de Grau
%Segmentació nucli estriat en imatges MRI cerebral amb First FSL.


clear all;
close all;

% Definir la ruta dels executables de FSL
ruta_fsl = '/Users/raniareguigui/fsl/share/fsl/bin/';

% Definir la ruta de les imatges de MRI
ruta_imagenes = '/Users/raniareguigui/Desktop/subset_Rania/PD/156665/MRI';

% Segmentar el nucli estriat dret
[status, output] = system([ruta_fsl, 'run_first_all -i ', fullfile(ruta_imagenes, 'mri_156665.nii.gz'), ' -o ', fullfile(ruta_imagenes, 'Caudat'), ' -s R_Caud']);

% Verificar si l'execució ha estat exitosa
if status == 0
    disp('Segmentació del caudat dret completada exitosamente.');
else
    disp('Error en la segmentació del caudat dret:');
    disp(output); % Muestra la salida de error
end

% Segmentar el nucli estriat esquerre
[status, output] = system([ruta_fsl, 'run_first_all -i ', fullfile(ruta_imagenes, 'mri_156665.nii.gz'), ' -o ', fullfile(ruta_imagenes, 'Caudat'), ' -s L_Caud']);
if status == 0
    disp('Segmentació del caudat esquerre completada exitosamente.');
else
    disp('Error en la segmentació del caudat esquerre:');
    disp(output);
end

% Segmentar el putamen dret
[status, output] = system([ruta_fsl, 'run_first_all -i ', fullfile(ruta_imagenes, 'mri_156665.nii.gz'), ' -o ', fullfile(ruta_imagenes, 'Putamen'), ' -s R_Puta']);
if status == 0
    disp('Segmentació del putamen dret completada exitosamente.');
else
    disp('Error en la segmentació del putamen dret:');
    disp(output);
end

% Segmentar el putamen esquerre
[status, output] = system([ruta_fsl, 'run_first_all -i ', fullfile(ruta_imagenes, 'mri_156665.nii.gz'), ' -o ', fullfile(ruta_imagenes, 'Putamen'), ' -s L_Puta']);
if status == 0
    disp('Segmentació del putamen esquerre completada exitosamente.');
else
    disp('Error en la segmentació del putamen esquerre:');
    disp(output);
end

% Combinar segmentacions del nucli estriat dret i esquerre
[status, output] = system([ruta_fsl, 'fslmaths ', fullfile(ruta_imagenes, 'Caudat-R_Caud_first.nii.gz'), ' -add ', fullfile(ruta_imagenes, 'Putamen-R_Puta_first.nii.gz'), ' ', fullfile(ruta_imagenes, 'estriat_R.nii.gz')]);
if status == 0
    disp('Combinació de segmentacions del nucli estriat dret completada exitosamente.');
else
    disp('Error en la combinació de segmentacions del nucli estriat dret:');
    disp(output);
end

[status, output] = system([ruta_fsl, 'fslmaths ', fullfile(ruta_imagenes, 'Caudat-L_Caud_first.nii.gz'), ' -add ', fullfile(ruta_imagenes, 'Putamen-L_Puta_first.nii.gz'), ' ', fullfile(ruta_imagenes, 'estriat_L.nii.gz')]);
if status == 0
    disp('Combinació de segmentacions del nucli estriat esquerre completada exitosamente.');
else
    disp('Error en la combinació de segmentacions del nucli estriat esquerre:');
    disp(output);
end

% Combinar segmentacions dreta i esquerre per obtenir el nucli estriat complet
[status, output] = system([ruta_fsl, 'fslmaths ', fullfile(ruta_imagenes, 'estriat_R.nii.gz'), ' -add ', fullfile(ruta_imagenes, 'estriat_L.nii.gz'), ' ', fullfile(ruta_imagenes, 'nucli_estriat_156665.nii.gz')]);
if status == 0
    disp('Combinació de segmentacions dreta i esquerre per obtenir el nucli estriat complet completada exitosamente.');
else
    disp('Error en la combinació de segmentacions dreta i esquerre per obtenir el nucli estriat complet:');
    disp(output);
end

disp('Procés de segmentació del nucli estriat completada.');
