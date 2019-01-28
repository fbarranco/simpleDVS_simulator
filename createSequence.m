% This code generate a sequence of events using the input sequence

function createSequence(nameSequence)

% Read a sequence from a set of frames
% I1 = double(imread('ImgFrame00019.pgm'));
I1 = double(imread(strcat('./',nameSequence,'/ImgFrame00000.pgm')));
    
% I1 = imread('diamond.pgm');
% I1(I1~=255)= 40;
% I1(I1==255)= 200;
% I1 = double(I1);

load('ctf_ILK_OF_worksp_newbinarytreeT.mat', 'O_gt');
tmp(:,:,1)=imresize(O_gt(:,:,1), size(I1));
tmp(:,:,2)=imresize(O_gt(:,:,2), size(I1));
O_gt = tmp;

keyboard

% Create the new sequence
nframes = 15;
O_gt = (O_gt*2)/(nframes-1);

frame_OLD=double(I1);
for f=1:nframes-1
    frame_NEW=warp(frame_OLD, O_gt*f);
    
    % Just for the current sequence (for new positions)
    frame_NEW(isnan(frame_NEW))=200;
    
    imwrite(uint8(frame_NEW), strcat('./',nameSequence, sprintf('/ImgFrame%05d.pgm', f)));
end

end

function [newFrame] = warp(frame, groundTruth)

[sy sx] = size(frame);
[X Y] = meshgrid(1:sx,1:sy);

tmp = groundTruth;
tmp(isnan(tmp)) = 0;
Vx = tmp(:,:,1);
Vy = tmp(:,:,2);

Xn = X-Vx;
Yn = Y-Vy;
newFrame = single(bilin_interp(double(frame),Xn,Yn));
% newFrame = interp2(X, Y, double(frame), Xn, Yn, 'linear');
end

