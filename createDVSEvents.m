% This code generate a sequence of events using the input sequence

function [posx, posy, timeStamp, pol] = createDVSEvents(pathfile, namefile, factor)

% Mat files contain two variables:
%     * II(:,:,x) --> sequence of five frames from frame2.pgm to frame6.pgm
%     * O_t(:,:,2) --> Ground-truth

load(strcat(pathfile, namefile));
I1 = II(:,:,3);
O_gt = O_t;


% load('flow2');
% O_gt(:,:,1)=Dx;
% O_gt(:,:,2)=Dy;
% I1 = im;



% load('flow_wooden_planks');
% O_gt(:,:,1)=gt(:,:,1)/10;
% O_gt(:,:,2)=gt(:,:,2)/10;
% I1 = im1;


% I1=double(imread(strcat(pathfile, 'mod_ImgFrame00000.pgm')));
% load('ctf_ILK_OF_worksp_newbinarytreeT', 'O_gt');
% keyboard
% I1_old = I1;
% I1(I1_old==200)=40;
% I1(I1_old==40)=210;
% I1(I1_old==0)=250;
% I1(I1_old==82)=170;
% I1(I1_old==75)=170;
% I1(I1_old==126)=120;



% % Read a sequence from a set of frames
% % I1 = double(imread('ImgFrame00019.pgm'));
% % I1 = double(imread('texturedBar.pgm'));
% I1 = double(imread('frame10.png')); % rubber whale sequence
%     
% % I1 = imread('diamond.pgm');
% % I1(I1~=255)= 40;
% % I1(I1==255)= 200;
% % I1 = double(I1);
% 
% load('ctf_ILK_OF_worksp_RubberWhale.mat');


% Create the new sequence
% We assume that the frame rate is 30 fps
% Create a movie with 1 frame --> 1/30 s 
% framerate = 40.0;
slice = 1; 
% nframes = (1/framerate*1000000)/slice; %We create frames for slices of 1 us
% nframes = (1/framerate*100000)/slice; %We create frames for slices of 1 us
nframes = 2500; %We create frames for slices of 1 us



% Remove NaN values from the ground-truth
Ox = O_gt(:,:,1); Ox(isnan(Ox))=0; Oy = O_gt(:,:,2); Oy(isnan(Oy))=0; 
O_gt(:,:,1)=Ox; O_gt(:,:,2)=Oy; 


motion = factor*O_gt/nframes; % Trying to simulate the movement that we can follow using 3 frames
posx = []; posy = []; timeStamp=[]; pol=[];
threshold = 0.05; %Assuming intensity represented with 8 bits
% threshold = 8; %Assuming intensity represented with 8 bits
% threshold = 0.10; %Assuming intensity represented with 8 bits
% threshold = 0.025; %Assuming intensity represented with 8 bits

frame_OLD=double(I1);
lastEventFrame = frame_OLD;
initialLog = log(frame_OLD);
accumEvents = zeros(size(frame_OLD));
% keyboard

for f=1:nframes
    
    frame_NEW=warp(frame_OLD, motion*f);
    %I don't know any other way of hadling the borders
    frame_NEW(isnan(frame_NEW))=frame_OLD(isnan(frame_NEW));
%     keyboard
    timeSlice = f*slice;
    [tmp_posx, tmp_posy, tmp_timeStamp, tmp_pol, newLastEvent, newAccumEvents] = generateEvents(frame_NEW, lastEventFrame, threshold, timeSlice, accumEvents, initialLog);
    % Updating data
    lastEventFrame = newLastEvent;
    accumEvents = newAccumEvents;
%     frame_OLD = frame_NEW;
    posx = [posx tmp_posx];
    posy = [posy tmp_posy];
    timeStamp = [timeStamp tmp_timeStamp];
    pol = [pol tmp_pol];
    
%     if f == 15000
%         I2 = uint8(frame_NEW);
%         save(strcat(pathfile, 'dvs_50000_interp_', namefile), 'posx', 'posy', 'timeStamp', 'pol', 'O_gt', 'I1', 'I2');
%         keyboard
%     end
    
    if rem(f, 500)==0
        f
    end
end
keyboard
I2 = uint8(frame_NEW);
% save(strcat('dvs_diamond_45_deg'), 'posx', 'posy', 'timeStamp', 'pol', 'O_gt', 'I1', 'I2');



% save('worksp_bar', 'posx', 'posy', 'timeStamp', 'pol', 'O_gt', 'I1', 'I2');
% save('dvs_worksp_diamond_dot', 'posx', 'posy', 'timeStamp', 'pol', 'O_gt', 'I1', 'I2');

% save(strcat(pathfile, 'dvs_5_', namefile), 'posx', 'posy', 'timeStamp', 'pol', 'O_gt', 'I1', 'I2');
save(strcat(pathfile, 'dvs_', namefile), 'posx', 'posy', 'timeStamp', 'pol', 'O_gt', 'I1', 'I2');


% save('worksp_RubberWhale', 'posx', 'posy', 'timeStamp', 'pol', 'O_gt', 'I1', 'I2');
% save('worksp_texturedBar', 'posx', 'posy', 'timeStamp', 'pol', 'O_gt', 'I1', 'I2');
% save('worksp_texturedDiamond', 'posx', 'posy', 'timeStamp', 'pol', 'O_gt', 'I1', 'I2');
% save('worksp_traslationTree', 'posx', 'posy', 'timeStamp', 'pol', 'O_gt', 'I1', 'I2');
% save('worksp_diamond', 'posx', 'posy', 'timeStamp', 'pol', 'O_gt', 'I1', 'I2');

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
% newFrame = single(bilin_interp(double(frame),Xn,Yn));
newFrame = interp2(X, Y, double(frame), Xn, Yn, 'linear');
% newFrame = interp2(X, Y, double(frame), Xn, Yn, 'cubic');

end

% % This function compute the events
% function [col, row, timeStamp, pol, lastEvent] = generateEvents(frame, oldFrame, threshold, timeSlice)
%     
%     [sizey, sizex] = size(frame);
%     lastEvent = oldFrame;
% %     diff = frame-oldFrame;
%     diff = log(frame)-log(oldFrame);
%     
% %     if (abs(diff(68,20))>threshold)
% %        str = sprintf('%f and %f\n', log(frame(68,20)), log(oldFrame(68,20)));
% %        str2 = sprintf('%f and %f\n', frame(68,20), oldFrame(68,20));
% %        disp(str);       
% %        disp(str2);
% %     end
%     
% %     [rowpos, colpos] = find(diff>0 & abs(diff./oldFrame)>=threshold);
% %     [rowneg, colneg] = find(diff<0 & abs(diff./oldFrame)>=threshold);
%      
%     [rowpos, colpos] = find(diff>0 & abs(diff)>=threshold);
%     [rowneg, colneg] = find(diff<0 & abs(diff)>=threshold);
% 
%     
%     
% %     [rowpos, colpos] = find(diff>0 & abs(diff)>=threshold);
% %     [rowneg, colneg] = find(diff<0 & abs(diff)>=threshold);
%     
%     %Pack the events randomly
%     randpositions = randperm(size(rowpos,1)+size(rowneg,1));
%     col = []; row=[]; timeStamp=[]; pol=[];
%     if size(rowpos,1)+size(rowneg,1) > 0
%         cnt = 1;
%         for i=1:size(randpositions,2)
%             
%             m = randpositions(i);
%             
%             if m<=size(rowpos,1)
%                 if colpos(m)>2 && colpos(m)<sizex-1 && rowpos(m)>2 && rowpos(m)<sizey-1
%                     col(cnt)= colpos(m)-1; % The original sensor counts from 0 to 127
%                     row(cnt)= rowpos(m)-1;
%                     timeStamp(cnt) = timeSlice;
%                     pol(cnt)=1;
%                     lastEvent(rowpos(m),colpos(m))=frame(rowpos(m), colpos(m));
%                     cnt = cnt+1;
%                 end
%             else
%                 if colneg(m-size(rowpos,1))>2 && colneg(m-size(rowpos,1))<sizex-1 && rowneg(m-size(rowpos,1))>2 && rowneg(m-size(rowpos,1))<sizey-1
%                     col(cnt)= colneg(m-size(rowpos,1))-1;
%                     row(cnt)= rowneg(m-size(rowpos,1))-1;
%                     timeStamp(cnt) = timeSlice;
%                     pol(cnt)=-1;
%                     lastEvent(rowneg(m-size(rowpos,1)),colneg(m-size(rowpos,1)))=frame(rowneg(m-size(rowpos,1)), colneg(m-size(rowpos,1)));
%                     cnt = cnt+1;
%                 end
%             end            
%         end    
%     end
%     
% end



function [col, row, timeStamp, pol, lastEvent, newAccumEvents] = generateEvents(frame, oldFrame, threshold, timeSlice, accumEvents, initialLog)
    
    [sizey, sizex] = size(frame);
    lastEvent = oldFrame;
    newAccumEvents = accumEvents;
    
%     diff = frame-oldFrame;

%     diff = log(frame) - log(oldFrame);
    
    % Refining the diff because of precision problems (accumulation of
    % errors)
    
    diff = log(frame)-(initialLog+accumEvents*threshold); 
    
    if sum(sum(isinf(diff)))>0
        diff(isinf(diff))=0;
    end
    
    if sum(sum(isnan(diff)))>0
        diff(isnan(diff))=0;
    end
        
     
%     keyboard
    
%     if (abs(diff(68,20))>threshold)
%        str = sprintf('%f and %f\n', log(frame(68,20)), log(oldFrame(68,20)));
%        str2 = sprintf('%f and %f\n', frame(68,20), oldFrame(68,20));
%        disp(str);       
%        disp(str2);
%     end
    
%     [rowpos, colpos] = find(diff>0 & abs(diff./oldFrame)>=threshold);
%     [rowneg, colneg] = find(diff<0 & abs(diff./oldFrame)>=threshold);
     
    [rowpos, colpos] = find(diff>0 & abs(diff)>=threshold);
    [rowneg, colneg] = find(diff<0 & abs(diff)>=threshold);
    
%     [rowpos, colpos] = find(diff>0 & abs(diff)>=threshold);
%     [rowneg, colneg] = find(diff<0 & abs(diff)>=threshold);
    
    %Pack the events randomly
    randpositions = randperm(size(rowpos,1)+size(rowneg,1));
    col = []; row=[]; timeStamp=[]; pol=[];
    if size(rowpos,1)+size(rowneg,1) > 0
        cnt = 1;
        for i=1:size(randpositions,2)
            
            m = randpositions(i);
            
            if m<=size(rowpos,1)
                if colpos(m)>2 && colpos(m)<sizex-1 && rowpos(m)>2 && rowpos(m)<sizey-1
                    col(cnt)= colpos(m)-1; % The original sensor counts from 0 to 127
                    row(cnt)= rowpos(m)-1;
                    timeStamp(cnt) = timeSlice;
                    pol(cnt)=1;
                    lastEvent(rowpos(m),colpos(m))=frame(rowpos(m), colpos(m));                    
%                     oldFrame(rowpos(m),colpos(m))= oldFrame(rowpos(m),colpos(m)) +1;
                    newAccumEvents(rowpos(m),colpos(m))=accumEvents(rowpos(m), colpos(m))+1;
                    cnt = cnt+1;
                end
            else
                if colneg(m-size(rowpos,1))>2 && colneg(m-size(rowpos,1))<sizex-1 && rowneg(m-size(rowpos,1))>2 && rowneg(m-size(rowpos,1))<sizey-1
                    col(cnt)= colneg(m-size(rowpos,1))-1;
                    row(cnt)= rowneg(m-size(rowpos,1))-1;
                    timeStamp(cnt) = timeSlice;
                    pol(cnt)=-1;
                    lastEvent(rowneg(m-size(rowpos,1)),colneg(m-size(rowpos,1)))=frame(rowneg(m-size(rowpos,1)), colneg(m-size(rowpos,1)));
%                     oldFrame(rowneg(m-size(rowpos,1)),colneg(m-size(rowpos,1)))= oldFrame(rowneg(m-size(rowpos,1)),colneg(m-size(rowpos,1))) +1;
                    newAccumEvents(rowneg(m-size(rowpos,1)),colneg(m-size(rowpos,1)))=accumEvents(rowneg(m-size(rowpos,1)),colneg(m-size(rowpos,1)))-1;
                    cnt = cnt+1;
                end
            end            
        end    
    end
    
end

