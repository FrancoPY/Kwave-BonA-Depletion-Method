sample = 'Phantom_homo_BA6_v3';
probe = 'L14-5u';
f0 = 7e6;
freqStr = sprintf('%dMHz', round(f0/1e6));

densityDir   = fullfile(pwd, 'densityMaps', sample);
outputBaseDir = fullfile(pwd, 'TAREA_v3', sample, probe, freqStr, 'rf');
if ~exist(outputBaseDir, 'dir'); mkdir(outputBaseDir); end

nFrames = 4;
dataCast = 'gpuArray-single';

% Grid
pmlXSize = 25;
pmlYSize = 25;

nx = 2000;
ny = 2000;

dx = 0.02e-3;
dy = dx;

kgrid = kWaveGrid(nx, dx, ny, dy);

% Medium
c0   = 1500.0;
rho0 = 1000;

medium.BonA            = 6.00;
medium.sound_speed     = c0;
medium.sound_speed_ref = c0;
medium.alpha_coeff     = 0.10;   % 0.1*f^2
medium.alpha_power     = 2.00;
medium.alpha_mode      = 'no_dispersion';

% Time grid
tEnd = 2.3 * (nx * dx) / c0;
kgrid.makeTime(c0, [], tEnd);

% Pulse
toneBurstCycles = 10;
toneBurstFreq   = f0;

% ángulos de steering: -15 a 15 grados, paso 1 grado
steeringAngles = -15:1:15;

% Probe
numElem   = 128;
elemWidth = round(0.3e-3 / dx);
kerf      = round(0 / dx);
pitch     = elemWidth + kerf;
apWidth   = numElem * elemWidth + (numElem - 1) * kerf;

y0 = floor((ny - apWidth) / 2) + 1;

x_ap  = 5;
x_rcv = 5;

% Índice de elementos centrado en cero
element_index = -(numElem-1)/2 : (numElem-1)/2;
elementSpacing = 0.3e-3;

sourceStrengths = [80e3, 400e3];

src_mask = false(kgrid.Nx, kgrid.Ny);
for e = 0:numElem-1
    ys = y0 + e * pitch;
    ye = ys + elemWidth - 1;
    src_mask(x_ap, ys:ye) = true;
end

rcv_mask = false(kgrid.Nx, kgrid.Ny);
elem_label = zeros(kgrid.Nx, kgrid.Ny);
for e = 0:numElem-1
    ys = y0 + e * pitch;
    ye = ys + elemWidth - 1;
    rcv_mask(x_rcv, ys:ye) = true;
    elem_label(x_rcv, ys:ye) = e + 1;
end

% Sensor
sensor.mask = rcv_mask;
sensor.directivity_angle = zeros(size(sensor.mask));
sensor.directivity_size = 10 * kgrid.dx;
sensor.record = {'p'};

% k-Wave
inputArgs = { ...
    'PMLInside',  false, ...
    'PMLSize',    [pmlXSize, pmlYSize], ...
    'DataCast',   dataCast, ...
    'DataRecast', true, ...
    'PlotSim',    false ...
};

labels = elem_label(sensor.mask);
fs = 1 / kgrid.dt;

% Barrido de ángulos
for steering_angle = steeringAngles

    fprintf('=== Ángulo de steering: %d grados ===\n', steering_angle);

    % Offset base y retardo por elemento (dependen del ángulo)
    max_offset = elementSpacing * max(abs(element_index)) * ...
                 abs(sin(steering_angle * pi/180)) / (c0 * kgrid.dt);
    offset_base = ceil(max_offset) + 20;

    tone_burst_offset = offset_base + elementSpacing * element_index * ...
        sin(steering_angle * pi/180) / (c0 * kgrid.dt);

    pulseNorm = toneBurst(1/kgrid.dt, toneBurstFreq, toneBurstCycles, ...
        'SignalOffset', tone_burst_offset);

    nPtsPerElem = elemWidth;
    pulseNormExpanded = zeros(numElem * nPtsPerElem, size(pulseNorm, 2));
    for e = 1:numElem
        rows = (e-1)*nPtsPerElem + 1 : e*nPtsPerElem;
        pulseNormExpanded(rows, :) = repmat(pulseNorm(e,:), nPtsPerElem, 1);
    end

    angleDir = fullfile(outputBaseDir, sprintf('Angle_%d', steering_angle));
    if ~exist(angleDir, 'dir'); mkdir(angleDir); end

    % Frames
    for frame = 1:nFrames

        densityFile = sprintf('frame%d', frame);
        load(fullfile(densityDir, densityFile));

        medium.density = single(density);

        % Pressure loop
        for sourceStrength = sourceStrengths

            fprintf('  [angulo %d][frame %d] %dkPa\n', steering_angle, frame, round(sourceStrength / 1e3));

            vdrive = single((sourceStrength / (c0 * rho0)) * pulseNormExpanded);

            source.ux = vdrive;
            source.u_mask = src_mask;

            sensorData = kspaceFirstOrder2D(kgrid, medium, source, sensor, inputArgs{:});

            rf_allpts = gather(sensorData.p);

            rfElem = zeros(numElem, size(rf_allpts, 2), 'like', rf_allpts);
            for e = 1:numElem
                rfElem(e, :) = mean(rf_allpts(labels == e, :), 1);
            end

            rfPrebf = rfElem.';
            outName = fullfile(angleDir, ...
                sprintf('%s_f%d_%dkPa.mat', sample, frame, round(sourceStrength / 1e3)));

            save(outName, 'rfPrebf', 'fs', 'c0', 'offset_base', 'steering_angle');

            source = struct();
            clear sensorData rf_allpts rfElem rfPrebf

        end

        clear density

    end

end
