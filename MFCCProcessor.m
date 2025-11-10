function mfccs = MFCCProcessor(x, Fs)
% MFCCProcessor - return MFCCs for a signal
% Uses builtin mfcc if available otherwise a simple fallback.
% x : audio vector (mono)
% Fs: sampling frequency
%
% Output:
% mfccs : NxM matrix (N = numFrames, M = numCoeffs)

if size(x,2) > 1
    x = x(:,1);
end

% prefer builtin if available (Audio Toolbox)
if exist('mfcc','file') == 2
    % builtin: returns coeffs per frame in rows
    % use typical params: 13 coeffs
    coeffs = mfcc(x, Fs, 'LogEnergy','Ignore');
    mfccs = coeffs; % frames x coeffs
    return;
end

% ----------------- fallback simple MFCC implementation -----------------
% parameters
frameLen = round(0.025 * Fs);  % 25 ms
frameShift = round(0.010 * Fs); % 10 ms
nfft = 512;
numFilters = 26;
numCoeffs = 13;

% pre-emphasis
x = filter([1 -0.97], 1, x);

% framing
frames = buffer(x, frameLen, frameLen-frameShift, 'nodelay');
win = hamming(frameLen);
frames = frames .* repmat(win,1,size(frames,2));

% magnitude spectrum
magSpec = abs(fft(frames, nfft, 1));
magSpec = magSpec(1:floor(nfft/2)+1, :); % freqBins x frames

% power spectrum
powSpec = (1/nfft) * (magSpec.^2);

% mel filterbank
fmin = 0;
fmax = Fs/2;
mels = linspace(hz2mel(fmin), hz2mel(fmax), numFilters+2);
hz = mel2hz(mels);
bins = floor((nfft+1) * hz / Fs);

filterBank = zeros(numFilters, size(powSpec,1));
for m = 1:numFilters
    f_m_left = bins(m);
    f_m = bins(m+1);
    f_m_right = bins(m+2);
    for k = f_m_left:f_m
        filterBank(m, k+1) = (k - bins(m)) / (bins(m+1)-bins(m));
    end
    for k = f_m:f_m_right
        if bins(m+2)-bins(m+1) ~= 0
            filterBank(m, k+1) = (bins(m+2) - k) / (bins(m+2)-bins(m+1));
        end
    end
end

% apply filterbank -> energies
filterE = filterBank * powSpec;
filterE(filterE<=0) = 1e-12; % avoid log(0)
logE = log(filterE);

% DCT to get MFCCs
dctCoefs = dct(logE);
mfccs = dctCoefs(1:numCoeffs, :)'; % frames x numCoeffs

end

% helper functions
function m = hz2mel(h)
m = 2595 * log10(1 + h/700);
end

function h = mel2hz(m)
h = 700 * (10.^(m/2595) - 1);
end
