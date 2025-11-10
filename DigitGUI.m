function DigitGUI_File()
% DigitGUI_File - Simple, attractive file-based GUI for Spoken Digit Recognition
% Features:
% - Choose single WAV file (case-insensitive)
% - Show waveform, play audio
% - Load / Train / Save model
% - Predict selected file (big display)
% - Batch Predict folder + Evaluate (confusion matrix + metrics CSV)
%
% Requirements: place this file in same folder as:
% - MFCCProcessor.m
% - extractFeatures.m
% - trainClassifier.m
% (All provided earlier)

%% Config
defaultDataFolder = fullfile('C:','Users','arvind','Documents','MATLAB','recordings');
defaultModelPath = fullfile(pwd,'model.mat');
winColor = [0.06 0.08 0.12];
panelColor = [0.11 0.13 0.18];
accent = [0.18 0.65 0.95]; % blue
okGreen = [0.2 0.9 0.3];

%% Create figure
screenSize = get(0,'ScreenSize');
W = min(1100, screenSize(3)-200);
H = min(700, screenSize(4)-150);
left = round((screenSize(3)-W)/2);
bottom = round((screenSize(4)-H)/2);
hFig = figure('Name','Spoken Digit — File UI','NumberTitle','off','Color',winColor,...
    'Position',[left bottom W H],'MenuBar','none','ToolBar','none');

% Layout sizes
pad = 16;
leftW = round(W*0.35);
rightW = W - leftW - 3*pad;

% Left control panel
hLeft = uipanel(hFig,'Title','Controls','FontSize',11,'BackgroundColor',panelColor,...
    'Position',[pad/W pad/H leftW/W (H-2*pad)/H]);

% Right display panel
hRight = uipanel(hFig,'Title','Prediction & Waveform','FontSize',11,'BackgroundColor',panelColor,...
    'Position',[(leftW+2*pad)/W pad/H rightW/W (H-2*pad)/H]);

%% Left panel components
% Data folder
uicontrol(hLeft,'Style','text','String','Data folder:','Units','normalized','Position',[0.02 0.94 0.4 0.05],...
    'BackgroundColor',panelColor,'ForegroundColor',[0.9 0.9 0.9],'FontSize',10,'HorizontalAlignment','left');
hFolder = uicontrol(hLeft,'Style','edit','String',defaultDataFolder,'Units','normalized','Position',[0.02 0.88 0.74 0.06],...
    'BackgroundColor','white','FontSize',9,'HorizontalAlignment','left');
uicontrol(hLeft,'Style','pushbutton','String','Browse','Units','normalized','Position',[0.78 0.88 0.20 0.06],...
    'Callback',@(s,e) browseFolder());

% Single file selection
uicontrol(hLeft,'Style','text','String','Select file:','Units','normalized','Position',[0.02 0.80 0.4 0.05],...
    'BackgroundColor',panelColor,'ForegroundColor',[0.9 0.9 0.9],'FontSize',10,'HorizontalAlignment','left');
hFile = uicontrol(hLeft,'Style','edit','String','', 'Units','normalized','Position',[0.02 0.74 0.74 0.06],...
    'BackgroundColor','white','FontSize',9,'HorizontalAlignment','left');
uicontrol(hLeft,'Style','pushbutton','String','Browse File','Units','normalized','Position',[0.78 0.74 0.20 0.06],...
    'Callback',@(s,e) browseFile());

% Play / Show waveform
uicontrol(hLeft,'Style','pushbutton','String','Show Waveform','Units','normalized','Position',[0.02 0.64 0.46 0.06],...
    'Callback',@(s,e) showWave());
uicontrol(hLeft,'Style','pushbutton','String','Play File','Units','normalized','Position',[0.52 0.64 0.46 0.06],...
    'Callback',@(s,e) playFile());

% Model operations
uicontrol(hLeft,'Style','text','String','Model:','Units','normalized','Position',[0.02 0.56 0.4 0.05],...
    'BackgroundColor',panelColor,'ForegroundColor',[0.9 0.9 0.9],'FontSize',10,'HorizontalAlignment','left');
hModel = uicontrol(hLeft,'Style','edit','String',defaultModelPath,'Units','normalized','Position',[0.02 0.50 0.74 0.06],...
    'BackgroundColor','white','FontSize',9,'HorizontalAlignment','left');
uicontrol(hLeft,'Style','pushbutton','String','Load Model','Units','normalized','Position',[0.78 0.50 0.20 0.06],...
    'Callback',@(s,e) loadModel());
uicontrol(hLeft,'Style','pushbutton','String','Train Model','Units','normalized','Position',[0.02 0.42 0.46 0.06],...
    'Callback',@(s,e) trainModel());
uicontrol(hLeft,'Style','pushbutton','String','Save Model As','Units','normalized','Position',[0.52 0.42 0.46 0.06],...
    'Callback',@(s,e) saveModel());

% Predict controls
uicontrol(hLeft,'Style','pushbutton','String','Predict Selected File','Units','normalized','Position',[0.02 0.32 0.96 0.08],...
    'BackgroundColor',accent,'ForegroundColor','white','FontSize',12,'FontWeight','bold','Callback',@(s,e) predictSelected());

uicontrol(hLeft,'Style','pushbutton','String','Batch Predict Folder','Units','normalized','Position',[0.02 0.22 0.46 0.06],...
    'Callback',@(s,e) batchPredict());
uicontrol(hLeft,'Style','pushbutton','String','Evaluate Predictions','Units','normalized','Position',[0.52 0.22 0.46 0.06],...
    'Callback',@(s,e) evaluatePredictions());

% Status box
uicontrol(hLeft,'Style','text','String','Status:','Units','normalized','Position',[0.02 0.14 0.4 0.05],...
    'BackgroundColor',panelColor,'ForegroundColor',[0.9 0.9 0.9],'FontSize',10,'HorizontalAlignment','left');
hStatus = uicontrol(hLeft,'Style','listbox','String',{'Ready'},'Units','normalized','Position',[0.02 0.02 0.96 0.12],...
    'BackgroundColor','white','FontSize',9);

%% Right panel: waveform axes + big prediction display
% axes for waveform (top half)
axWave = axes('Parent',hRight,'Position',[0.06 0.55 0.88 0.40],'Color',[0.02 0.02 0.03]);
title(axWave,'Waveform','Color',[0.9 0.9 0.9]);
xlabel(axWave,'Time (s)','Color',[0.8 0.8 0.8]);
ylabel(axWave,'Amplitude','Color',[0.8 0.8 0.8]);
set(axWave,'XColor',[0.8 0.8 0.8],'YColor',[0.8 0.8 0.8]);

% big prediction display (bottom)
hBigPanel = uipanel(hRight,'BackgroundColor',panelColor,'Position',[0.02 0.02 0.96 0.48]);
hBigText = uicontrol(hBigPanel,'Style','text','String','--','FontSize',120,'FontWeight','bold','ForegroundColor',okGreen,...
    'Units','normalized','Position',[0.05 0.25 0.9 0.6],'BackgroundColor',hBigPanel.BackgroundColor);
hInfoText = uicontrol(hBigPanel,'Style','text','String','No file selected','FontSize',14,'Units','normalized','Position',[0.05 0.06 0.9 0.15],'BackgroundColor',hBigPanel.BackgroundColor,'ForegroundColor',[0.9 0.9 0.9]);

%% App state
app.model = [];
app.modelPath = '';
app.currentFile = '';
app.currentAudio = [];
app.currentFs = [];
setappdata(hFig,'app',app);

%% Helper functions

    function addStatus(msg)
        ts = datestr(now,'HH:MM:SS');
        cur = get(hStatus,'String');
        cur = [{[ts ' - ' msg]}; cur];
        if numel(cur) > 200, cur = cur(1:200); end
        set(hStatus,'String',cur);
        drawnow;
    end

    function browseFolder()
        p = uigetdir(defaultDataFolder, 'Select folder with WAVs');
        if p==0, return; end
        set(hFolder,'String',p);
        addStatus(['Folder set: ' p]);
    end

    function browseFile()
        [f,p] = uigetfile({'*.wav;*.WAV;*.waw;*.WAw','Audio files (*.wav,*)'}, 'Select audio file', defaultDataFolder);
        if f==0, return; end
        full = fullfile(p,f);
        set(hFile,'String',full);
        addStatus(['Selected file: ' f]);
        % auto preview
        showWave();
    end

    function resolved = resolveAudioFile(pathInput)
        % Accept exact file, or try different case extensions
        if isempty(pathInput)
            error('No file specified.');
        end
        if isfile(pathInput), resolved = pathInput; return; end
        [fld, nm, ext] = fileparts(pathInput);
        if isempty(fld), fld = get(hFolder,'String'); end
        exts = {'.wav','.WAV','.waw','.WAw','.WaV'};
        for k=1:numel(exts)
            cand = fullfile(fld, [nm exts{k}]);
            if isfile(cand), resolved = cand; return; end
        end
        error('Audio file not found: %s', pathInput);
    end

    function showWave()
        try
            f = char(get(hFile,'String'));
            if isempty(f), addStatus('No file selected.'); return; end
            full = resolveAudioFile(f);
            [y, Fs] = audioread(full);
            if size(y,2)>1, y = y(:,1); end
            t = (0:numel(y)-1)/Fs;
            cla(axWave);
            plot(axWave,t, y,'Color',accent,'LineWidth',0.8);
            xlabel(axWave,'Time (s)');
            title(axWave, ['Waveform — ' char(get(hFile,'String'))],'Color',[0.9 0.9 0.9]);
            set(axWave,'XColor',[0.9 0.9 0.9],'YColor',[0.9 0.9 0.9]);
            grid(axWave,'on');
            app = getappdata(hFig,'app');
            app.currentFile = full;
            app.currentAudio = y;
            app.currentFs = Fs;
            setappdata(hFig,'app',app);
            set(hInfoText,'String',sprintf('File: %s  |  Fs: %d Hz', getShortName(full), Fs));
            addStatus(['Waveform shown: ' getShortName(full)]);
        catch ME
            addStatus(['Show waveform failed: ' ME.message]);
        end
    end

    function playFile()
        try
            app = getappdata(hFig,'app');
            if isempty(app.currentAudio)
                % try to load from edit
                f = char(get(hFile,'String'));
                if isempty(f), addStatus('No file selected.'); return; end
                full = resolveAudioFile(f);
                [y, Fs] = audioread(full);
            else
                y = app.currentAudio; Fs = app.currentFs;
            end
            if isempty(y), addStatus('No audio to play.'); return; end
            player = audioplayer(y, Fs);
            play(player);
            addStatus('Playing audio...');
        catch ME
            addStatus(['Play failed: ' ME.message]);
        end
    end

    function getShortName(p)
        [~,nm,ext] = fileparts(p);
        getShortName = [nm ext]; %#ok<NASGU>
    end

    function loadModel()
        [f,p] = uigetfile('*.mat','Select model.mat', pwd);
        if f==0, return; end
        S = load(fullfile(p,f));
        if isfield(S,'model')
            app = getappdata(hFig,'app');
            app.model = S.model;
            app.modelPath = fullfile(p,f);
            setappdata(hFig,'app',app);
            set(hModel,'String',app.modelPath);
            addStatus(['Model loaded: ' app.modelPath]);
        else
            errordlg('Selected file does not contain variable ''model''','Load model');
            addStatus('Model load failed.');
        end
    end

    function saveModel()
        app = getappdata(hFig,'app');
        if isempty(app.model), addStatus('No model in memory to save.'); return; end
        [f,p] = uiputfile('model.mat','Save model as', pwd);
        if f==0, return; end
        save(fullfile(p,f),'model','-v7.3'); %#ok<NASGU>
        addStatus(['Model saved to ' fullfile(p,f)]);
    end

    function trainModel()
        folder = char(get(hFolder,'String'));
        if ~isfolder(folder)
            errordlg('Select a valid data folder first','Train model');
            return;
        end
        addStatus('Extracting features and training (this may take time)...');
        drawnow;
        try
            tbl = extractFeatures(folder);
        catch ME
            errordlg(['Feature extraction failed: ' ME.message],'Error');
            addStatus('Feature extraction failed.');
            return;
        end
        addStatus(['Extracted ' num2str(height(tbl)) ' files. Training...']);
        drawnow;
        try
            model = trainClassifier(tbl, fullfile(pwd,'model.mat'));
            app = getappdata(hFig,'app');
            app.model = model;
            app.modelPath = fullfile(pwd,'model.mat');
            setappdata(hFig,'app',app);
            set(hModel,'String',app.modelPath);
            addStatus('Training completed and model saved.');
        catch ME
            errordlg(['Training failed: ' ME.message],'Error');
            addStatus('Training failed.');
        end
    end

    function predictSelected()
        try
            app = getappdata(hFig,'app');
            if isempty(app.model)
                addStatus('No model loaded. Load or train a model first.');
                return;
            end
            f = char(get(hFile,'String'));
            if isempty(f)
                addStatus('No file selected.');
                return;
            end
            full = resolveAudioFile(f);
            [y, Fs] = audioread(full);
            if size(y,2)>1, y = y(:,1); end
            mfccs = MFCCProcessor(y, Fs);
            feat = [mean(mfccs,1), std(mfccs,[],1)];
            if numel(feat) ~= app.model.featDim
                errordlg('Feature dimension mismatch. Retrain model or adjust MFCCProcessor settings.','Predict error');
                addStatus('Feature dim mismatch.');
                return;
            end
            [pred, scores] = predict(app.model.classifier, feat);
            set(hBigText,'String',num2str(pred));
            set(hBigText,'ForegroundColor',accent);
            set(hInfoText,'String',sprintf('Predicted: %d (top score %.3f) — File: %s', pred, max(scores), getShortName(full)));
            addStatus(sprintf('Predicted %d for %s', pred, getShortName(full)));
        catch ME
            addStatus(['Prediction failed: ' ME.message]);
        end
    end

    function batchPredict()
        folder = char(get(hFolder,'String'));
        if ~isfolder(folder)
            addStatus('Select valid folder first.');
            return;
        end
        app = getappdata(hFig,'app');
        if isempty(app.model)
            addStatus('No model loaded. Load/train model first.');
            return;
        end
        addStatus('Running batch prediction...');
        filesAll = dir(fullfile(folder,'*.*'));
        isAudio = contains(lower({filesAll.name}), {'.wav','.waw'});
        files = filesAll(isAudio);
        n = numel(files);
        if n==0, addStatus('No audio files found in folder.'); return; end
        T = table('Size',[n,3],'VariableTypes',{'string','double','double'},'VariableNames',{'filename','pred','scoreMax'});
        for i=1:n
            fp = fullfile(files(i).folder, files(i).name);
            T.filename(i) = string(files(i).name);
            try
                [y, Fs] = audioread(fp);
                if size(y,2)>1, y=y(:,1); end
                mfccs = MFCCProcessor(y, Fs);
                feat = [mean(mfccs,1), std(mfccs,[],1)];
                [p, sc] = predict(app.model.classifier, feat);
                T.pred(i) = p;
                T.scoreMax(i) = max(sc);
            catch ME
                T.pred(i) = -1;
                T.scoreMax(i) = NaN;
                addStatus(['Error: ' files(i).name ' - ' ME.message]);
            end
            if mod(i,100)==0, addStatus(sprintf('Processed %d/%d', i, n)); drawnow; end
        end
        outCSV = fullfile(pwd,'predictions.csv');
        writetable(T,outCSV);
        addStatus(['Batch predictions saved to ' outCSV]);
    end

    function evaluatePredictions()
        outCSV = fullfile(pwd,'predictions.csv');
        if ~isfile(outCSV)
            addStatus('predictions.csv not found. Run Batch Predict first.');
            return;
        end
        P = readtable(outCSV);
        n = height(P);
        trueLabel = nan(n,1);
        for i=1:n
            fn = char(P.filename(i));
            tok = regexp(fn,'^([0-9])','tokens','once');
            if ~isempty(tok), trueLabel(i)=str2double(tok{1}); end
        end
        Ypred = P.pred;
        valid = ~isnan(trueLabel) & (Ypred~=-1);
        Ytrue = trueLabel(valid);
        Ypredv = Ypred(valid);
        addStatus(sprintf('Evaluating on %d/%d files', sum(valid), n));
        if isempty(Ytrue)
            addStatus('No valid true labels found.');
            return;
        end
        acc = mean(Ypredv==Ytrue);
        addStatus(sprintf('Overall accuracy = %.2f%%', acc*100));
        cm = confusionmat(Ytrue, Ypredv);
        figure('Name','Confusion Matrix'); confusionchart(cm);
        % per-class metrics
        TP = diag(cm); FN = sum(cm,2)-TP; FP = sum(cm,1)'-TP;
        precision = TP./(TP+FP); precision(isnan(precision))=0;
        recall = TP./(TP+FN); recall(isnan(recall))=0;
        f1 = 2.*(precision.*recall)./(precision+recall); f1(isnan(f1))=0;
        metrics = table((0:size(cm,1)-1)', TP, precision, recall, f1, 'VariableNames',{'Digit','TP','Precision','Recall','F1'});
        writetable(metrics, fullfile(pwd,'metrics_per_class.csv'));
        writetable(P(valid,:), fullfile(pwd,'predictions_with_true.csv'));
        addStatus('Saved metrics_per_class.csv and predictions_with_true.csv');
    end

%% End of GUI
end
