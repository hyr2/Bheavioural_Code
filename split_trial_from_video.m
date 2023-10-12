% Splitting into individual trials based on intensity thresholding of the
% video. Then splits into trials

%% File reading
output_filepath = '/home/hyr2-office/Documents/Data/Behave/rh11/23-09-20';
input_filepath = fullfile(output_filepath,"final_combined.avi");
v = VideoReader(input_filepath);

% ctmp = read(v, [600 900]); % 20~30 seconds, assuming 30Hz camera freq
% ctmp = mean(ctmp, 4);

%%  Settings threshold for intensity
ctmp = read(v,[1000,2500]);
ctmp = mean(ctmp,[3,4]);
% ctmp = mean(ctmp,[1,2,3]);
% vid_time = reshape(ctmp,[1,2500]);
% i_thresh = mean(vid_time) - 0.5 * std(vid_time);
%% Add cropping factor (select a region of light for trial detection)
[TRIAL_CROP_COL_MIN, TRIAL_CROP_COL_MAX, TRIAL_CROP_ROW_MIN, TRIAL_CROP_ROW_MAX] = drawRectangleROI(ctmp);
tmp = read(v,[500,3000]);
tmp = squeeze(tmp(TRIAL_CROP_ROW_MIN:TRIAL_CROP_ROW_MAX, TRIAL_CROP_COL_MIN:TRIAL_CROP_COL_MAX, 1, :));
tmp = mean(tmp,[1,2]);
tmp = squeeze(tmp);
i_thresh = (max(tmp) - min(tmp))/5 + min(tmp);
%% Variables
fps = v.FrameRate;
n_frames = v.NumFrames;
batch_size = 1500;
n_batches_full = floor(n_frames/batch_size);
fprintf("#total batches: %d\n", n_batches_full + 1);
trial_indicator = int16(zeros(n_frames, 1));
% trial_indicator_tmp = int16(zeros(n_batches_full, batch_size));
%% Main loop for video extraction
% parpool(3)
for i = 0:(n_batches_full-1)
    fprintf("Processing batch: %d/%d\n", i+1, n_batches_full+1);
    tmp = read(v,[i*batch_size+1 (i+1)*batch_size]);
    tmp1 = squeeze(tmp(TRIAL_CROP_ROW_MIN:TRIAL_CROP_ROW_MAX, TRIAL_CROP_COL_MIN:TRIAL_CROP_COL_MAX, 1, :));
    % tmp1 = squeeze(tmp(1:end, 1:end, 1, :));
    tmp_val = int16(squeeze(mean(tmp1, [1 2])));
    trial_indicator(i*batch_size+1:(i+1)*batch_size) = tmp_val;
    % trial_indicator_tmp(i+1, :) = tmp_val;
end
fprintf("Processing batch: %d/%d\n", n_batches_full+1, n_batches_full+1);
% tmp = read(v, [n_batches_full*batch_size+1 Inf]);
% tmp1 = squeeze(tmp(TRIAL_CROP_ROW_MIN:TRIAL_CROP_ROW_MAX, TRIAL_CROP_COL_MIN:TRIAL_CROP_COL_MAX, 1, :));
% tmp1 = squeeze(tmp(1:end, 1:end, 1, :));
% tmp_val = int16(squeeze(mean(tmp1, [1 2])));
% trial_indicator((n_batches_full*batch_size+1):end) = tmp_val;
%% Applying threshold + separating trials
trial_indicator_bool = trial_indicator > i_thresh;
switches = diff(double(trial_indicator_bool));
trial_start_stamp_indices = find(switches==1) + 1;
trial_end_stamp_indices = find(switches==-1);
%% Saving
save(fullfile(output_filepath,'trial_indicator.mat'), 'i_thresh', 'trial_start_stamp_indices', 'trial_end_stamp_indices', 'fps');
%% Printing
try
    trial_durations = trial_end_stamp_indices - trial_start_stamp_indices; 
catch
    error('Error in finding the correct number of trials from the video data.\n')
end
fprintf("Duration in sec: %f +/- %f\n", mean(trial_durations)/fps, std(trial_durations)/fps);
fprintf("    Min=%f, Max=%f\n", min(trial_durations)/fps, max(trial_durations)/fps);

%% Create Single Trial Videos

% file_input = fullfile(filepath_video,'final_combined.avi');
% load(fullfile(filepath_video,'trial_indicator.mat'));
output_folder = fullfile(output_filepath,'all_trials');
if ~exist(output_folder,'dir')
    mkdir(output_folder)
end

num_of_trials = length(trial_start_stamp_indices);

for i = 1:num_of_trials
    local_filename = fullfile(output_folder,['trial_',num2str(i,'%04.f'),'.avi']);
    video = VideoWriter(local_filename);
    video.FrameRate = v.FrameRate;
    open(video);
    thisFrame = read(v, [trial_start_stamp_indices(i,1) , trial_end_stamp_indices(i,1)]);
    for j = 1:trial_end_stamp_indices(i,1)-trial_start_stamp_indices(i,1)+1
        frame = thisFrame(:,:,:,j);
        writeVideo(video,frame);
    end
    close(video);
end