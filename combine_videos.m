%concatenate avi files into one long video

filepath_video = '/home/hyr2-office/Documents/Data/Behave/rh11/23-09-20';
list_files = dir_sorted(fullfile(filepath_video,'*.avi'));      % what if the format is not .avi?
list_files = {list_files.name};
num_vids = length(list_files);

% reading first video for extracting key parameters
[fps, X, Y, ~ , bitd] = extract_info_video(fullfile(filepath_video,list_files{1}));

file_output = fullfile(filepath_video,'final_combined.avi');

video = VideoWriter(file_output);
video.FrameRate = fps;
open(video);


for i = 1:num_vids
    v=VideoReader(fullfile(filepath_video,list_files{i}));
    mov=read(v);
    writeVideo(video,mov);
end

close(video);