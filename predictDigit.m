function [pred, scores] = predictDigit(modelPath, wavfile)
% predictDigit - load model and predict digit for given wav file
% [pred, scores] = predictDigit('model.mat', 'test.wav')

if nargin < 2
    error('Usage: [pred, scores] = predictDigit(modelPath, wavfile)');
end

S = load(modelPath);
model = S.model;

[y, Fs] = audioread(wavfile);
if size(y,2) > 1
    y = y(:,1);
end

mfccs = MFCCProcessor(y, Fs);
feat = [mean(mfccs,1), std(mfccs,[],1)];

% ensure correct dimension
if numel(feat) ~= model.featDim
    error('Feature dimension mismatch: expected %d, got %d', model.featDim, numel(feat));
end

[pred, score] = predict(model.classifier, feat);
scores = score; % per-class score

fprintf('Predicted digit: %d\n', pred);
end
