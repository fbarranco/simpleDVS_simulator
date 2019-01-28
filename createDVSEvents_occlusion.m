% This code generate a sequence of events using the input sequence

function [posx, posy, timeStamp, pol] = createDVSEvents_occlusion(pathfile, namefile, factor)

% Mat files contain two variables:
%     * II(:,:,x) --> sequence of five frames from frame2.pgm to frame6.pgm
%     * O_t(:,:,2) --> Ground-truth

% load(strcat(pathfile, namefile));
% I1 = II(:,:,3);
% O_gt = O_t;



% load('flow2');
% O_gt(:,:,1)=Dx;
% O_gt(:,:,2)=Dy;
% I1 = im;


load('flow_wooden_planks', 'gt');
I1_part1 = double(imread('part1_texture1.pgm'));
O_gt_part1(:,:,1)=gt(:,:,1);
O_gt_part1(:,:,2)=zeros(150,150);

I1_part2 = double(imread('part2_texture1.pgm'));
O_gt_part2(:,:,1)=zeros(150,150);
O_gt_part2(:,:,2)=zeros(150,150); 
O_gt_part2(57:149, 10:149,2)=-5;


keyboard

% I1=double(imread('diamond_dot_1.pgm'));
% load('ctf_ILK_OF_worksp_newbinarytreeT', 'O_gt');
% factor = 2;
% I1_old = I1;
% I1(I1_old==200)=40;
% I1(I1_old==40)=200;



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
nframes = 10000; %We create frames for slices of 1 us


% Remove NaN values from the ground-truth
% Ox = O_gt(:,:,1); Ox(isnan(Ox))=0; Oy = O_gt(:,:,2); Oy(isnan(Oy))=0; 
% O_gt(:,:,1)=Ox; O_gt(:,:,2)=Oy;


% motion = factor*O_gt/nframes; % Trying to simulate the movement that we can follow using 3 frames


motion_part1 = factor*O_gt_part1/nframes; % Trying to simulate the movement that we can follow using 3 frames
motion_part2 = factor*O_gt_part2/nframes; % Trying to simulate the movement that we can follow using 3 frames



posx = []; posy = []; timeStamp=[]; pol=[];
threshold = 0.05; %Assuming intensity represented with 8 bits
% threshold = 8; %Assuming intensity represented with 8 bits
% threshold = 0.10; %Assuming intensity represented with 8 bits
% threshold = 0.025; %Assuming intensity represented with 8 bits


frame_OLD = I1_part2;
frame_OLD(10:149,47:139)=I1_part1(10:149, 47:139);

lastEventFrame = frame_OLD;
initialLog = log(frame_OLD);
accumEvents = zeros(size(frame_OLD));

for f=1:nframes
    
    first = warp(I1_part2, motion_part2*f);
    second = warp(I1_part1, motion_part1*f);
%         if f==1000
%             keyboard
%         end
    if motion_part1(70,94,1)*f <= 1
        frame_NEW = first;
        frame_NEW(10:149,47:139) = second(10:149,47:139);
        
        frame_NEW(57:149,47) = I1_part1(57:149,47)*(1-motion_part1(70,94,1)*f) + I1_part2(57:149,47)*(motion_part1(70,94,1)*f);
        frame_NEW(57:149,139) = I1_part1(57:149,139)*(motion_part1(70,94,1)*f) + I1_part2(57:149,139)*(1-motion_part1(70,94,1)*f);
    else
        if motion_part1(70,94,1)*f <=2 
            frame_NEW = first;
            frame_NEW(10:149,48:140) = second(10:149,48:140);
        
            frame_NEW(57:149,48) = I1_part1(57:149,48)*(1-motion_part1(70,94,1)*f) + I1_part2(57:149,48)*(motion_part1(70,94,1)*f);
            frame_NEW(57:149,140) = I1_part1(57:149,140)*(motion_part1(70,94,1)*f) + I1_part2(57:149,140)*(1-motion_part1(70,94,1)*f);
        else
            % motion*f <=3 Not bigger than that
            frame_NEW = first;
            frame_NEW(10:149,49:141) = second(10:149,49:141);
        
            frame_NEW(57:149,49) = I1_part1(57:149,49)*(1-motion_part1(70,94,1)*f) + I1_part2(57:149,49)*(motion_part1(70,94,1)*f);
            frame_NEW(57:149,141) = I1_part1(57:149,141)*(motion_part1(70,94,1)*f) + I1_part2(57:149,141)*(1-motion_part1(70,94,1)*f);            
        end
    end    
    
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
% save(strcat(pathfile, 'dvs_50000_', namefile), 'posx', 'posy', 'timeStamp', 'pol', 'O_gt', 'I1', 'I2');
save(strcat(pathfile, 'dvs_50000_', namefile), 'posx', 'posy', 'timeStamp', 'pol', 'O_gt_part1', 'O_gt_part2', 'I1_part1', 'I1_part2', 'I2');


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

