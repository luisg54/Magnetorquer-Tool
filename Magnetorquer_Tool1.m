%% OPTIMAL AIR-CORE MAGNETORQUER DESIGN SCRIPT
% This script finds the optimal wire gauge and number of turns to maximize
% the magnetic moment-to-mass ratio subject to user-defined constraints.

clear; clc;

%% ========================================================================
%  1. USER-DEFINED INPUTS & CONSTRAINTS
%  ========================================================================

% Arbitray values

% Maximum allowable mass (kg)
max_mass = 0.2;

% Maximum power consumption (W)
max_power = 3.075;

% Coil radius (m)
coil_radius = 0.10;

% Maximum coil length (m) - physical length of wound wire
max_coil_length = 0.05;

% System voltage (V)
system_voltage = 12.0;

%% ========================================================================
%  2. DESIGN DATA & PHYSICAL CONSTANTS
%  ========================================================================

% Copper density (kg/m³)
copper_density = 8960;

% AWG wire data: [AWG number, diameter (m), resistance (Ω/m)]
% Data source: Standard AWG wire tables
awg_data = [
    10, 2.588e-3, 3.277e-3;
    12, 2.053e-3, 5.211e-3;
    14, 1.628e-3, 8.286e-3;
    16, 1.291e-3, 1.318e-2;
    18, 1.024e-3, 2.096e-2;
    20, 8.128e-4, 3.329e-2;
    22, 6.438e-4, 5.315e-2;
    24, 5.106e-4, 8.415e-2;
    26, 4.049e-4, 1.339e-1;
    28, 3.211e-4, 2.129e-1;
    30, 2.546e-4, 3.386e-1;
    32, 2.019e-4, 5.385e-1;
    34, 1.601e-4, 8.571e-1;
    36, 1.270e-4, 1.361;
    38, 1.007e-4, 2.167;
    40, 7.988e-5, 3.441
];

% Convert AWG data to struct for easier access
awg_struct = struct('gauge', num2cell(awg_data(:,1)), ...
                    'diameter', num2cell(awg_data(:,2)), ...
                    'resistance_per_meter', num2cell(awg_data(:,3)));

% Range of turns to evaluate
turns_range = 100:50:5000;

%% ========================================================================
%  3. INITIALIZATION
%  ========================================================================

% Initialize best design struct with placeholder values
best_design = struct('gauge', 0, ...
                     'turns', 0, ...
                     'mass', 0, ...
                     'power', 0, ...
                     'moment', 0, ...
                     'score', 0, ...
                     'current', 0, ...
                     'resistance', 0, ...
                     'wire_length', 0, ...
                     'coil_physical_length', 0);

fprintf('========================================\n');
fprintf('MAGNETORQUER DESIGN OPTIMIZATION\n');
fprintf('========================================\n\n');
fprintf('Constraints:\n');
fprintf('  Max Mass:        %.3f kg\n', max_mass);
fprintf('  Max Power:       %.2f W\n', max_power);
fprintf('  Coil Radius:     %.4f m\n', coil_radius);
fprintf('  Max Coil Length: %.4f m\n', max_coil_length);
fprintf('  System Voltage:  %.2f V\n\n', system_voltage);
fprintf('Evaluating designs...\n\n');

%% ========================================================================
%  4. MAIN OPTIMIZATION LOOP
%  ========================================================================

% Counter for valid designs
valid_designs = 0;

% Outer loop: iterate through each AWG gauge
for i = 1:length(awg_struct)
    
    % Extract wire properties
    gauge = awg_struct(i).gauge;
    wire_diameter = awg_struct(i).diameter;
    resistance_per_meter = awg_struct(i).resistance_per_meter;
    
    % Calculate wire cross-sectional area
    wire_area = pi * (wire_diameter/2)^2;
    
    % Inner loop: iterate through number of turns
    for N = turns_range
        
        % ================================================================
        % CALCULATE DESIGN PROPERTIES
        % ================================================================
        
        % Total wire length (mean turn circumference * number of turns)
        wire_length = N * (2 * pi * coil_radius);
        
        % Total electrical resistance
        total_resistance = wire_length * resistance_per_meter;
        
        % Total mass of copper wire
        total_mass = wire_length * wire_area * copper_density;
        
        % Current drawn at system voltage
        current = system_voltage / total_resistance;
        
        % Power consumed
        power_consumed = system_voltage * current;
        
        % Magnetic moment (A·m²)
        magnetic_moment = N * current * (pi * coil_radius^2);
        
        % Physical length of wound coil (assumes single layer)
        coil_physical_length = N * wire_diameter;
        
        % ================================================================
        % CHECK CONSTRAINTS
        % ================================================================
        
        % Check mass constraint
        if total_mass > max_mass
            continue;
        end
        
        % Check power constraint
        if power_consumed > max_power
            continue;
        end
        
        % Check physical coil length constraint
        if coil_physical_length > max_coil_length
            continue;
        end
        
        % ================================================================
        % SCORE AND COMPARE
        % ================================================================
        
        % Design is valid - increment counter
        valid_designs = valid_designs + 1;
        
        % Calculate efficiency score (moment-to-mass ratio)
        score = magnetic_moment / total_mass;
        
        % Update best design if this score is better
        if score > best_design.score
            best_design.gauge = gauge;
            best_design.turns = N;
            best_design.mass = total_mass;
            best_design.power = power_consumed;
            best_design.moment = magnetic_moment;
            best_design.score = score;
            best_design.current = current;
            best_design.resistance = total_resistance;
            best_design.wire_length = wire_length;
            best_design.coil_physical_length = coil_physical_length;
        end
        
    end
end

%% ========================================================================
%  5. OUTPUT RESULTS
%  ========================================================================

fprintf('========================================\n');
fprintf('OPTIMIZATION COMPLETE\n');
fprintf('========================================\n\n');

fprintf('Valid designs evaluated: %d\n\n', valid_designs);

if best_design.score > 0
    fprintf('OPTIMAL DESIGN FOUND:\n');
    fprintf('--------------------\n');
    fprintf('Wire Gauge (AWG):           %d\n', best_design.gauge);
    fprintf('Number of Turns:            %d\n', best_design.turns);
    fprintf('\n');
    fprintf('PERFORMANCE METRICS:\n');
    fprintf('--------------------\n');
    fprintf('Magnetic Moment:            %.4f A·m²\n', best_design.moment);
    fprintf('Total Mass:                 %.4f kg (%.1f%% of limit)\n', ...
            best_design.mass, 100*best_design.mass/max_mass);
    fprintf('Power Consumption:          %.4f W (%.1f%% of limit)\n', ...
            best_design.power, 100*best_design.power/max_power);
    fprintf('Operating Current:          %.4f A\n', best_design.current);
    fprintf('Total Resistance:           %.2f Ω\n', best_design.resistance);
    fprintf('Wire Length:                %.2f m\n', best_design.wire_length);
    fprintf('Physical Coil Length:       %.4f m (%.1f%% of limit)\n', ...
            best_design.coil_physical_length, ...
            100*best_design.coil_physical_length/max_coil_length);
    fprintf('\n');
    fprintf('EFFICIENCY:\n');
    fprintf('--------------------\n');
    fprintf('Moment-to-Mass Ratio:       %.2f A·m²/kg\n', best_design.score);
    fprintf('\n');
else
    fprintf('NO VALID DESIGN FOUND!\n');
    fprintf('Consider relaxing constraints or adjusting parameters.\n\n');
end

fprintf('========================================\n');