%% OPTIMAL AIR-CORE MAGNETORQUER DESIGN SCRIPT
% This script finds the optimal wire gauge and number of turns to maximize
% the magnetic moment-to-mass ratio subject to user-defined constraints.

clear; clc;

%% ========================================================================
%  1. USER-DEFINED INPUTS & CONSTRAINTS
%  ========================================================================

% Maximum allowable mass (kg)
max_mass = 0.2;

% Maximum power consumption (W)
max_power = 3.075;

% Coil inner radius (m)
coil_radius = 0.10;

% Maximum coil length (m) - physical length of wound wire
max_coil_length = 0.05;

% Maximum outer radius (m) - inner radius + maximum radial build-up
max_outer_radius = 0.12;  % 20mm radial build-up allowed

% Minimum required magnetic moment (A·m²)
% Designs below this threshold will be rejected even if efficient
min_required_moment = 0.1;

% System voltage (V)
system_voltage = 12.0;

% Packing factor (accounts for gaps between wires in winding)
% Typical values: 0.85-0.95 for careful winding, 0.7-0.85 for loose winding
packing_factor = 0.90;

% Wire insulation thickness addition per side (m)
% Heavy build magnet wire: ~15-25 µm per side
% Standard build: ~8-15 µm per side
insulation_thickness = 15e-6;  % 15 microns per side

%% ========================================================================
%  2. DESIGN DATA & PHYSICAL CONSTANTS
%  ========================================================================

% Copper density (kg/m³)
copper_density = 8960;

% AWG wire data: [AWG number, diameter (m), resistance (Ω/m)]
% Data source: Standard AWG wire tables - Solaris-shop.com
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
                     'efficiency', 0, ...
                     'current', 0, ...
                     'resistance', 0, ...
                     'wire_length', 0, ...
                     'coil_physical_length', 0, ...
                     'outer_radius', 0);

fprintf('========================================\n');
fprintf('MAGNETORQUER DESIGN OPTIMIZATION\n');
fprintf('========================================\n\n');
fprintf('Constraints:\n');
fprintf('  Max Mass:            %.3f kg\n', max_mass);
fprintf('  Max Power:           %.2f W\n', max_power);
fprintf('  Inner Radius:        %.4f m\n', coil_radius);
fprintf('  Max Outer Radius:    %.4f m\n', max_outer_radius);
fprintf('  Max Coil Length:     %.4f m\n', max_coil_length);
fprintf('  Min Required Moment: %.4f A·m²\n', min_required_moment);
fprintf('  System Voltage:      %.2f V\n\n', system_voltage);
fprintf('Design Parameters:\n');
fprintf('  Packing Factor:   %.2f\n', packing_factor);
fprintf('  Insulation:       %.1f µm per side\n\n', insulation_thickness*1e6);
fprintf('Evaluating designs...\n\n');

%% ========================================================================
%  4. MAIN OPTIMIZATION LOOP
%  ========================================================================

% Counter for valid designs
valid_designs = 0;

% Storage for all designs (for plotting)
all_designs = [];

% Outer loop: iterate through each AWG gauge
for i = 1:length(awg_struct)
    
    % Extract wire properties
    gauge = awg_struct(i).gauge;
    wire_diameter = awg_struct(i).diameter;
    resistance_per_meter = awg_struct(i).resistance_per_meter;
    
    % Calculate wire cross-sectional area (for mass - bare conductor)
    wire_area = pi * (wire_diameter/2)^2;
    
    % Calculate effective wire diameter including insulation
    effective_diameter = wire_diameter + (2 * insulation_thickness);
    
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
        
        % Physical length of wound coil including insulation and packing
        coil_physical_length = (N * effective_diameter) / packing_factor;
        
        % Calculate outer radius (radial build-up from winding)
        % Assuming single-layer winding wrapped around the coil
        radial_buildup = effective_diameter / packing_factor;
        outer_radius = coil_radius + radial_buildup;
        
        % Calculate efficiency ratio
        efficiency_ratio = magnetic_moment / total_mass;
        
        % ================================================================
        % CHECK CONSTRAINTS
        % ================================================================
        
        is_valid = true;
        
        % Check mass constraint
        if total_mass > max_mass
            is_valid = false;
        end
        
        % Check power constraint
        if power_consumed > max_power
            is_valid = false;
        end
        
        % Check physical coil length constraint
        if coil_physical_length > max_coil_length
            is_valid = false;
        end
        
        % Check outer radius constraint
        if outer_radius > max_outer_radius
            is_valid = false;
        end
        
        % Check minimum magnetic moment constraint
        if magnetic_moment < min_required_moment
            is_valid = false;
        end
        
        % Store design data for plotting
        design_data = struct('gauge', gauge, ...
                            'turns', N, ...
                            'mass', total_mass, ...
                            'power', power_consumed, ...
                            'moment', magnetic_moment, ...
                            'efficiency', efficiency_ratio, ...
                            'outer_radius', outer_radius, ...
                            'valid', is_valid);
        all_designs = [all_designs; design_data];
        
        % Skip invalid designs
        if ~is_valid
            continue;
        end
        
        % ================================================================
        % SCORE AND COMPARE
        % ================================================================
        
        % Design is valid - increment counter
        valid_designs = valid_designs + 1;
        
        % Update best design if this efficiency is better
        if efficiency_ratio > best_design.efficiency
            best_design.gauge = gauge;
            best_design.turns = N;
            best_design.mass = total_mass;
            best_design.power = power_consumed;
            best_design.moment = magnetic_moment;
            best_design.efficiency = efficiency_ratio;
            best_design.current = current;
            best_design.resistance = total_resistance;
            best_design.wire_length = wire_length;
            best_design.coil_physical_length = coil_physical_length;
            best_design.outer_radius = outer_radius;
        end
        
    end
end

%% ========================================================================
%  5. OUTPUT RESULTS
%  ========================================================================

fprintf('========================================\n');
fprintf('OPTIMIZATION COMPLETE\n');
fprintf('========================================\n\n');

fprintf('Total designs evaluated: %d\n', length(all_designs));
fprintf('Valid designs found:     %d\n\n', valid_designs);

if best_design.efficiency > 0
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
    fprintf('\n');
    fprintf('PHYSICAL DIMENSIONS:\n');
    fprintf('--------------------\n');
    fprintf('Inner Radius:               %.4f m\n', coil_radius);
    fprintf('Outer Radius:               %.4f m (%.1f%% of limit)\n', ...
            best_design.outer_radius, 100*best_design.outer_radius/max_outer_radius);
    fprintf('Radial Build-up:            %.4f m\n', best_design.outer_radius - coil_radius);
    fprintf('Axial Coil Length:          %.4f m (%.1f%% of limit)\n', ...
            best_design.coil_physical_length, ...
            100*best_design.coil_physical_length/max_coil_length);
    fprintf('\n');
    fprintf('EFFICIENCY:\n');
    fprintf('--------------------\n');
    fprintf('Moment-to-Mass Ratio:       %.2f A·m²/kg\n', best_design.efficiency);
    fprintf('\n');
else
    fprintf('NO VALID DESIGN FOUND!\n');
    fprintf('Consider relaxing constraints or adjusting parameters.\n\n');
end

fprintf('========================================\n\n');

%% ========================================================================
%  6. VISUALIZATION
%  ========================================================================

if best_design.efficiency > 0 && ~isempty(all_designs)
    
    % Extract arrays from struct array
    gauges = [all_designs.gauge];
    turns = [all_designs.turns];
    masses = [all_designs.mass];
    powers = [all_designs.power];
    moments = [all_designs.moment];
    efficiencies = [all_designs.efficiency];
    outer_radii = [all_designs.outer_radius];
    valid_flags = [all_designs.valid];
    
    % ====================================================================
    % FIGURE 1: CONSTRAINT ANALYSIS
    % ====================================================================
    figure('Name', 'Magnetorquer Optimization - Constraint Analysis', ...
           'Position', [50, 100, 1600, 800]);
    
    % PLOT 1: Mass Constraint Analysis
    subplot(2, 2, 1);
    hold on;
    
    % Plot all designs
    scatter(masses, efficiencies, 40, [0.7 0.7 0.7], 'filled', ...
            'MarkerFaceAlpha', 0.4, 'DisplayName', 'All Designs');
    
    % Plot valid designs
    scatter(masses(valid_flags), efficiencies(valid_flags), 50, ...
            [0.3 0.7 0.9], 'filled', 'MarkerEdgeColor', 'k', ...
            'LineWidth', 0.5, 'DisplayName', 'Valid Designs');
    
    % Plot optimal design
    scatter(best_design.mass, best_design.efficiency, 200, 'r', 'p', ...
            'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 2, ...
            'DisplayName', 'Optimal Design');
    
    % Add constraint line
    xline(max_mass, 'r--', 'LineWidth', 2, 'DisplayName', 'Mass Limit');
    
    xlabel('Mass (kg)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Efficiency (A·m²/kg)', 'FontSize', 11, 'FontWeight', 'bold');
    title('Mass Constraint', 'FontSize', 12, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 9);
    grid on;
    xlim([0, max(max_mass*1.2, max(masses)*1.1)]);
    hold off;
    
    % PLOT 2: Power Constraint Analysis
    subplot(2, 2, 2);
    hold on;
    
    scatter(powers, efficiencies, 40, [0.7 0.7 0.7], 'filled', ...
            'MarkerFaceAlpha', 0.4, 'DisplayName', 'All Designs');
    scatter(powers(valid_flags), efficiencies(valid_flags), 50, ...
            [0.3 0.7 0.9], 'filled', 'MarkerEdgeColor', 'k', ...
            'LineWidth', 0.5, 'DisplayName', 'Valid Designs');
    scatter(best_design.power, best_design.efficiency, 200, 'r', 'p', ...
            'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 2, ...
            'DisplayName', 'Optimal Design');
    
    xline(max_power, 'r--', 'LineWidth', 2, 'DisplayName', 'Power Limit');
    
    xlabel('Power (W)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Efficiency (A·m²/kg)', 'FontSize', 11, 'FontWeight', 'bold');
    title('Power Constraint', 'FontSize', 12, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 9);
    grid on;
    xlim([0, max(max_power*1.2, max(powers)*1.1)]);
    hold off;
    
    % PLOT 3: Magnetic Moment Constraint Analysis
    subplot(2, 2, 3);
    hold on;
    
    scatter(moments, efficiencies, 40, [0.7 0.7 0.7], 'filled', ...
            'MarkerFaceAlpha', 0.4, 'DisplayName', 'All Designs');
    scatter(moments(valid_flags), efficiencies(valid_flags), 50, ...
            [0.3 0.7 0.9], 'filled', 'MarkerEdgeColor', 'k', ...
            'LineWidth', 0.5, 'DisplayName', 'Valid Designs');
    scatter(best_design.moment, best_design.efficiency, 200, 'r', 'p', ...
            'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 2, ...
            'DisplayName', 'Optimal Design');
    
    xline(min_required_moment, 'r--', 'LineWidth', 2, ...
          'DisplayName', 'Min Moment Limit');
    
    xlabel('Magnetic Moment (A·m²)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Efficiency (A·m²/kg)', 'FontSize', 11, 'FontWeight', 'bold');
    title('Minimum Moment Constraint', 'FontSize', 12, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 9);
    grid on;
    xlim([0, max(moments)*1.1]);
    hold off;
    
    % PLOT 4: Outer Radius Constraint Analysis
    subplot(2, 2, 4);
    hold on;
    
    scatter(outer_radii*1000, efficiencies, 40, [0.7 0.7 0.7], 'filled', ...
            'MarkerFaceAlpha', 0.4, 'DisplayName', 'All Designs');
    scatter(outer_radii(valid_flags)*1000, efficiencies(valid_flags), 50, ...
            [0.3 0.7 0.9], 'filled', 'MarkerEdgeColor', 'k', ...
            'LineWidth', 0.5, 'DisplayName', 'Valid Designs');
    scatter(best_design.outer_radius*1000, best_design.efficiency, 200, 'r', 'p', ...
            'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 2, ...
            'DisplayName', 'Optimal Design');
    
    xline(max_outer_radius*1000, 'r--', 'LineWidth', 2, ...
          'DisplayName', 'Radius Limit');
    
    xlabel('Outer Radius (mm)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Efficiency (A·m²/kg)', 'FontSize', 11, 'FontWeight', 'bold');
    title('Outer Radius Constraint', 'FontSize', 12, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 9);
    grid on;
    xlim([min(outer_radii)*1000*0.9, max(max_outer_radius*1000*1.2, max(outer_radii)*1000*1.1)]);
    hold off;
    
    % Overall title for Figure 1
    total_designs = length(all_designs);
    sgtitle(sprintf('Constraint Analysis: %d Valid Designs (%.1f%% of %d Total)', ...
                    valid_designs, 100*valid_designs/total_designs, total_designs), ...
            'FontSize', 14, 'FontWeight', 'bold');
    
    fprintf('Figure 1: Constraint Analysis created.\n');
    
    % ====================================================================
    % FIGURE 2: PERFORMANCE TRADE-OFFS
    % ====================================================================
    figure('Name', 'Magnetorquer Optimization - Performance Trade-offs', ...
           'Position', [100, 50, 1600, 800]);
    
    % PLOT 1: Mass vs Power (2D Design Space)
    subplot(2, 2, 1);
    hold on;
    
    scatter(masses, powers, 40, [0.7 0.7 0.7], 'filled', ...
            'MarkerFaceAlpha', 0.4, 'DisplayName', 'All Designs');
    scatter(masses(valid_flags), powers(valid_flags), 50, ...
            [0.3 0.7 0.9], 'filled', 'MarkerEdgeColor', 'k', ...
            'LineWidth', 0.5, 'DisplayName', 'Valid Designs');
    scatter(best_design.mass, best_design.power, 200, 'r', 'p', ...
            'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 2, ...
            'DisplayName', 'Optimal Design');
    
    % Add constraint boundaries
    xline(max_mass, 'r--', 'LineWidth', 2, 'HandleVisibility', 'off');
    yline(max_power, 'r--', 'LineWidth', 2, 'HandleVisibility', 'off');
    
    xlabel('Mass (kg)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Power (W)', 'FontSize', 11, 'FontWeight', 'bold');
    title('Design Space: Mass vs Power', 'FontSize', 12, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 9);
    grid on;
    hold off;
    
    % PLOT 2: Moment vs Mass
    subplot(2, 2, 2);
    hold on;
    
    scatter(masses, moments, 40, [0.7 0.7 0.7], 'filled', ...
            'MarkerFaceAlpha', 0.4, 'DisplayName', 'All Designs');
    scatter(masses(valid_flags), moments(valid_flags), 50, ...
            [0.3 0.7 0.9], 'filled', 'MarkerEdgeColor', 'k', ...
            'LineWidth', 0.5, 'DisplayName', 'Valid Designs');
    scatter(best_design.mass, best_design.moment, 200, 'r', 'p', ...
            'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 2, ...
            'DisplayName', 'Optimal Design');
    
    % Add constraint lines
    xline(max_mass, 'r--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    yline(min_required_moment, 'r--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    
    xlabel('Mass (kg)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Magnetic Moment (A·m²)', 'FontSize', 11, 'FontWeight', 'bold');
    title('Performance: Moment vs Mass', 'FontSize', 12, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 9);
    grid on;
    hold off;
    
    % PLOT 3: Moment vs Power
    subplot(2, 2, 3);
    hold on;
    
    scatter(powers, moments, 40, [0.7 0.7 0.7], 'filled', ...
            'MarkerFaceAlpha', 0.4, 'DisplayName', 'All Designs');
    scatter(powers(valid_flags), moments(valid_flags), 50, ...
            [0.3 0.7 0.9], 'filled', 'MarkerEdgeColor', 'k', ...
            'LineWidth', 0.5, 'DisplayName', 'Valid Designs');
    scatter(best_design.power, best_design.moment, 200, 'r', 'p', ...
            'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 2, ...
            'DisplayName', 'Optimal Design');
    
    % Add constraint lines
    xline(max_power, 'r--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    yline(min_required_moment, 'r--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    
    xlabel('Power (W)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Magnetic Moment (A·m²)', 'FontSize', 11, 'FontWeight', 'bold');
    title('Performance: Moment vs Power', 'FontSize', 12, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 9);
    grid on;
    hold off;
    
    % PLOT 4: Constraint Summary
    subplot(2, 2, 4);
    
    % Calculate constraint violations
    mass_violations = sum(masses > max_mass);
    power_violations = sum(powers > max_power);
    moment_violations = sum(moments < min_required_moment);
    radius_violations = sum(outer_radii > max_outer_radius);
    
    % Note: A design can violate multiple constraints
    violation_data = [mass_violations; power_violations; moment_violations; ...
                     radius_violations; valid_designs];
    violation_labels = {'Mass', 'Power', 'Min Moment', 'Radius', 'Valid'};
    colors = [0.9 0.3 0.3; 0.9 0.5 0.3; 0.9 0.7 0.3; 0.9 0.9 0.3; 0.3 0.9 0.3];
    
    b = bar(violation_data);
    b.FaceColor = 'flat';
    for k = 1:length(violation_data)
        b.CData(k,:) = colors(k,:);
    end
    
    set(gca, 'XTickLabel', violation_labels);
    ylabel('Number of Designs', 'FontSize', 11, 'FontWeight', 'bold');
    title('Constraint Violation Summary', 'FontSize', 12, 'FontWeight', 'bold');
    grid on;
    
    % Add text annotations showing percentages
    for k = 1:length(violation_data)
        text(k, violation_data(k), sprintf('%.1f%%', 100*violation_data(k)/total_designs), ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
             'FontWeight', 'bold', 'FontSize', 10);
    end
    
    % Overall title for Figure 2
    sgtitle(sprintf('Performance Trade-offs: Optimal Design = AWG %d, %d Turns, %.3f A·m²', ...
                    best_design.gauge, best_design.turns, best_design.moment), ...
            'FontSize', 14, 'FontWeight', 'bold');
    
    fprintf('Figure 2: Performance Trade-offs created.\n\n');
end

fprintf('========================================\n');