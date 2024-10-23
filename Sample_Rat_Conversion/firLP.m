function Hd = firLP
% FIRLP Returns a discrete-time filter object.

% All frequency values are normalized to 1.

Fpass = 0.45;            % Passband Frequency
Fstop = 0.55;            % Stopband Frequency
Dpass = 0.001;           % Tighter Passband Ripple (set to reduce ripple further)
Dstop = 0.0001;          % Stopband Attenuation (no change)
dens  = 25;              % Increase density factor for better precision

% Calculate the order from the parameters using FIRPMORD.
[N, Fo, Ao, W] = firpmord([Fpass, Fstop], [1 0], [Dpass, Dstop]);

% Substantially increase filter order to ensure smaller ripple
N = N + 20;  % Increase filter order significantly

% Calculate the coefficients using the FIRPM function.
b  = firpm(N, Fo, Ao, W, {dens});
Hd = dfilt.dffir(b);  % Convert to a discrete filter object

% [EOF]
