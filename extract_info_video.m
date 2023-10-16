function [fps, X, Y, N, bitd] = extract_info_video(filepath_video)
%EXTRACT_INFO_VIDEO Summary of this function goes here
%   Extracting key parameters from the video.
%   X : width of frame
%   Y : Height of frame
%   fps : frames per second of the video
%   N : Number of frames
%   bitd : bit depth

v = VideoReader(filepath_video);
fps = v.FrameRate;
N = v.NumFrames;
X = v.Width;
Y = v.Height;
bitd = v.BitsPerPixel;


end

