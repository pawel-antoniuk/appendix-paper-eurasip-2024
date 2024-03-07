function [features, spatResults, spatMetaresults] = generateFeatures(params)

[spatResults,spatMetaresults] = spatializeSong(params.HRTFs, params.Tracks, ...
    params.TrackNames, params.AudioFilename.name, params);
spatResults = posprocessSpatResults(spatResults, params);
spatResults = squeeze(spatResults);

%% Initialize

frameDuration = 0.02;
hopFactor = 0.5; 
nFilterBankChannels = 64;

twoEarsParams = genParStruct(...
	'pp_bRemoveDC', true, ...
	'pp_cutoffHzDC', 20, ...
	'fb_type', 'gammatone', ...
	'fb_nChannels', nFilterBankChannels, ...
	'fb_lowFreqHz', 100, ...
	'fb_highFreqHz', 16000, ...
	'ihc_method', 'dau', ...
	'ild_wSizeSec', frameDuration, ...
	'ild_hSizeSec', hopFactor* frameDuration,...
	'ild_wname', 'hann', ...
	'cc_wSizeSec', frameDuration, ...
	'cc_hSizeSec', hopFactor* frameDuration,...
	'cc_wname', 'hann', ...
	'cc_maxDelaySec', 0.0011,...
	'rm_wSizeSec', frameDuration, ...
	'rm_hSizeSec', hopFactor*frameDuration,...
	'rm_scaling', 'power', ...
	'rm_decaySec', 8E-3, ...
	'rm_wname', 'hann');

params.TwoEarsParams = twoEarsParams;

%% extract

xy = spatResults;
xy = xy - ones(size(xy)) * diag(mean(xy)); % remove DC offset
fs = params.RecordingsExpectedFs;

dataObj = dataObject(xy, fs, length(xy) / fs, 2);    
managerObj = manager(dataObj, {'ild', 'itd', 'ic', 'filterbank'}, params.TwoEarsParams);
managerObj.processSignal();

features = struct();
features.ILD = managerObj.Data.ild{1}.Data(:);
features.ITD = managerObj.Data.itd{1}.Data(:);
features.IC = managerObj.Data.ic{1}.Data(:);
features.filterbankLeft = managerObj.Data.filterbank{1}.Data(:);
features.filterbankRight = managerObj.Data.filterbank{2}.Data(:);
features.cfHz = managerObj.Data.filterbank{1}.cfHz;

dataObj.clearData
managerObj.reset
managerObj.cleanup

end
