function tbl = extractFeatures(folder)
% extractFeatures - read all .wav in folder (and subfolders) and compute features
% Returns a table with columns: filename, label, features (1xD vector)
%
% folder: path which contains subfolders 0 1 2 ... 9 OR wav files named like '5_xxx.wav'
% tbl = extractFeatures(folder)

if nargin < 1 || isempty(folder)
    folder = pwd;
end

% get all wavs recursively
files = dir(fullfile(folder, '**', '*.wav'));
n = numel(files);
if n == 0
    error('No wav files found in %s', folder);
end

filenames = cell(n,1);
labels = cell(n,1);
features = cell(n,1);

for i = 1:n
    if isfield(files,'folder')
        fp = fullfile(files(i).folder, files(i).name);
    else
        fp = fullfile(folder, files(i).name);
    end

    [y, Fs] = audioread(fp);
    if size(y,2) > 1
        y = y(:,1);
    end

    % compute MFCC frames
    mfccs = MFCCProcessor(y, Fs); % frames x coeffs

    % aggregate frame-level MFCCs into file-level feature vector:
    % use mean and std of each coefficient -> 2*numCoeffs features
    mu = mean(mfccs, 1);
    sigma = std(mfccs, [], 1);
    feat = [mu, sigma];

    filenames{i} = fp;

    % try to infer label:
    % strategy 1: if parent folder name is a digit (0-9) use it
    [p, name, ext] = fileparts(fp);
    [pp, folderName] = fileparts(p);
    if ~isempty(folderName) && ~isempty(regexp(folderName, '^[0-9]$', 'once'))
        lbl = str2double(folderName);
    else
        % strategy 2: parse digit at start of file name (e.g., '5_george_01.wav')
        tok = regexp(name, '^([0-9])', 'tokens', 'once');
        if ~isempty(tok)
            lbl = str2double(tok{1});
        else
            % unknown -> mark as NaN
            lbl = NaN;
        end
    end
    labels{i} = lbl;
    features{i} = feat;
end

tbl = table(filenames, labels, features, 'VariableNames', {'filename','label','features'});

end
