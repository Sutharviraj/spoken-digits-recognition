function model = trainClassifier(featureTable, savePath)
% trainClassifier - train multiclass classifier from feature table
% featureTable: table as returned by extractFeatures
% savePath: optional path to save model (default 'model.mat')
%
% Returns trained model struct with fields: classifier, classes, featDim

if nargin < 2 || isempty(savePath)
    savePath = fullfile(pwd, 'model.mat');
end

% ===== FIX START: Convert labels to numeric =====
if iscell(featureTable.label)
    featureTable.label = cellfun(@(x) str2double(string(x)), featureTable.label);
elseif isstring(featureTable.label)
    featureTable.label = str2double(featureTable.label);
end
% Remove rows with missing/invalid labels
validIdx = ~isnan(featureTable.label);
featureTable = featureTable(validIdx, :);
% ===== FIX END =====

% build feature matrix and labels
n = height(featureTable);
featDim = numel(featureTable.features{1});
X = zeros(n, featDim);
Y = zeros(n,1);
for i = 1:n
    X(i,:) = featureTable.features{i};
    Y(i) = featureTable.label(i);
end

% shuffle data
rng(0);
idx = randperm(n);
X = X(idx,:);
Y = Y(idx);

% train a multiclass SVM using one-vs-one (fitcecoc)
t = templateSVM('KernelFunction','rbf','Standardize',true);
Mdl = fitcecoc(X, Y, 'Learners', t, 'Coding', 'onevsone', 'Verbose',2);

% wrap model
model.classifier = Mdl;
model.classes = unique(Y);
model.featDim = featDim;

% save model
save(savePath, 'model');
fprintf('Model trained and saved to %s\n', savePath);
end
