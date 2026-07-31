baseDir = 'C:\Users\FRANCO PERALTA\Documents\MATLAB\LIM\TAREA_v2';
probe   = 'L14-5u';
freqStr = '7MHz';

nFrames = 6;
fNumber = 3;
steeringAngle = 5;
c0_bf = 1500;   % velocidad de sonido

% Lista de phantoms a procesar
phantomNames = { ...
    'Phantom_inc_BA11_Steering5_v2', ...
    'Phantom_homo_BA11_Steering5_v2', ...
};

for p = 1:numel(phantomNames)

    sample = phantomNames{p};

    rawDir = fullfile(baseDir, sample, probe, freqStr, 'rf');
    bfDir  = fullfile(baseDir, sample, probe, freqStr, 'bf');
    if ~exist(bfDir, 'dir'); mkdir(bfDir); end

    fprintf('--- Procesando %s ---\n', sample);

    for i = 1:nFrames

        fileL = fullfile(rawDir,sprintf('%s_f%d_80kPa.mat', sample, i));
        fileH = fullfile(rawDir, sprintf('%s_f%d_400kPa.mat', sample, i));

        sL = load(fileL);
        sH = load(fileH);

        fs = sL.fs;
        c0 = sL.c0;

        if isfield(sL, 'offset_base')
            offsetBaseL = sL.offset_base;
        else
            offsetBaseL = 0;
        end
        if isfield(sH, 'offset_base')
            offsetBaseH = sH.offset_base;
        else
            offsetBaseH = 0;
        end

        rfLp = bfPlaneWaveSimu(sL.rfPrebf', fs, fNumber, steeringAngle, c0_bf, offsetBaseL);
        rfHp = bfPlaneWaveSimu(sH.rfPrebf', fs, fNumber, steeringAngle, c0_bf, offsetBaseH);

        nSamples = size(rfLp, 1);
        nLines = size(rfLp, 2);
        zAxis = (1:nSamples)' * (c0_bf / fs) / 2;
        xAxis = (0:nLines-1) * 0.3e-3;
        xAxis = xAxis - mean(xAxis);

        save(fullfile(bfDir, sprintf('%s_f%d_LP.mat', sample, i)), 'rfLp', 'xAxis', 'zAxis', 'fs');
        save(fullfile(bfDir, sprintf('%s_f%d_HP.mat', sample, i)), 'rfHp', 'xAxis', 'zAxis', 'fs');

        fprintf('  Frame %d beamformeado y guardado en bf/\n', i);

    end

end

fprintf('\nListo. Carpetas "bf" generadas para cada phantom.\n');
