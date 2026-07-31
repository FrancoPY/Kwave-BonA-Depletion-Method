%startup;

sample = 'Phantom_inc_BA11_Steering15_v2';
probe = 'L14-5u';
f0 = 7e6;
freqStr = sprintf('%dMHz', round(f0/1e6));

densityDir = fullfile(pwd, 'densityMaps', sample);
outputDir  = fullfile(pwd, 'TAREA_v2', sample, probe, freqStr, 'rf');
if ~exist(outputDir, 'dir'); mkdir(outputDir); end

nFrames = 6;
dataCast = 'gpuArray-single';

% Grid
pmlXSize = 25;
pmlYSize = 25;

nx = 2000;
ny = 2000;

dx = 0.02e-3;
dy = dx;

kgrid = kWaveGrid(nx, dx, ny, dy);

% Inclusion parameters
centerDepth = 22.5e-3;  % [m]
radius = 7.5e-3;        % [m]
inclusion = makeDisc(nx, ny, round(centerDepth/dx), ny/2, round(radius/dx));

% Medium
c0   = 1500.0;
rho0 = 1000;

a_bg  = 0.10;   y_bg  = 2.00;
a_inc = 0.10;   y_inc = 2.00;

f_ref_MHz = f0 / 1e6;

y_ref = 2.00;

a_bg_eff  = a_bg  * f_ref_MHz^(y_bg  - y_ref);
a_inc_eff = a_inc * f_ref_MHz^(y_inc - y_ref);

medium.BonA            = 6.00 * ones(nx, ny);
medium.sound_speed     = c0   * ones(nx, ny);
medium.sound_speed_ref = c0;

medium.alpha_power     = y_ref;
medium.alpha_coeff     = a_bg_eff * ones(nx, ny);
medium.alpha_coeff(inclusion > 0) = a_inc_eff;

medium.BonA        = medium.BonA + (11.00 - 6.00) * inclusion;
medium.sound_speed = medium.sound_speed + (1500.0 - c0) * inclusion;

medium.alpha_mode  = 'no_dispersion';

% Time grid
tEnd = 2.3 * (nx * dx) / c0;
kgrid.makeTime(c0, [], tEnd);

% Probe
numElem   = 128;
elemWidth = round(0.3e-3 / dx);
kerf      = round(0 / dx);
pitch     = elemWidth + kerf;
apWidth   = numElem * elemWidth + (numElem - 1) * kerf;

y0 = floor((ny - apWidth) / 2) + 1;

x_ap  = 5;
x_rcv = 5;

sourceStrengths = [80e3, 400e3];

% Pulse con steering
toneBurstFreq   = f0;
toneBurstCycles = 10;
steering_angle  = 15;

% Índice de elementos (centrado en cero)
element_index = -(numElem-1)/2 : (numElem-1)/2;

% Offset base
elementSpacing = 0.3e-3;
max_offset = elementSpacing * max(abs(element_index)) * ...
             abs(sin(steering_angle * pi/180)) / (c0 * kgrid.dt);
offset_base = ceil(max_offset) + 20;

% Delay para cada elemento
tone_burst_offset = offset_base + elementSpacing * element_index * ...
    sin(steering_angle * pi/180) / (c0 * kgrid.dt);

% Pulso con retardo
pulseNorm = toneBurst(1/kgrid.dt, toneBurstFreq, toneBurstCycles, ...
    'SignalOffset', tone_burst_offset);

% Expandir para todos los puntos del grid
nPtsPerElem = elemWidth;
pulseNormExpanded = zeros(numElem * nPtsPerElem, size(pulseNorm, 2));
for e = 1:numElem
    rows = (e-1)*nPtsPerElem + 1 : e*nPtsPerElem;
    pulseNormExpanded(rows, :) = repmat(pulseNorm(e,:), nPtsPerElem, 1);
end

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

% Frames
for frame = 1:nFrames

    densityFile = sprintf('frame%d', frame);
    load(fullfile(densityDir, densityFile));

    medium.density = single(density);

    % Pressure loop
    for sourceStrength = sourceStrengths

        fprintf('[frame %d] %dkPa\n', frame, round(sourceStrength / 1e3));

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
        outName = fullfile(outputDir, ...
             sprintf('%s_f%d_%dkPa.mat', sample, frame, round(sourceStrength/1e3)));

        save(outName, 'rfPrebf', 'fs', 'c0', 'offset_base');

        source = struct();
        clear sensorData rf_allpts rfElem rfPrebf

    end

    clear density

end