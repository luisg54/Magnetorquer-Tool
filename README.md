#Magnetorquer-Tool

MATLAB tool to optimize magnetorquer designs for the WUSAT CubeSat

#Purpose & Methodology

This tool performs a brute-force optimization to find the most efficient air-core magnetorquer design for a given set of constraints.

The script iterates through a range of standard AWG wire gauges and numbers of turns. It calculates the performance (mass, power, moment, size) for each combination and discards any design that violates the user-defined constraints.

From the remaining valid designs, the tool selects the one with the highest moment-to-mass ratio (efficiency) that also meets a minimum required magnetic moment, as specified by the min_required_moment parameter.
