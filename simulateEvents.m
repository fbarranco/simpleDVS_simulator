function [x, y, ts, pol] = simulateEvents(pathfile, namefile, factor)
% This code generate a sequence of events using the input sequence
% Input: 
%      pathfile:    path to the mat file
%      namefile:    name of the mat file
%                       Mat files contain two variables:
%                           * II(:,:,x)  --> sequence of five frames (e.g.
%                                            from frame2.pgm to frame6.pgm in Middlebury)
%                           * O_t(:,:,2) --> Ground-truth
% Output:
%      x:           x positions of stream of simulated events 
%      y:           y positions of stream of simulated events
%      pol:         polarities of stream of simulated events 
%      ts:          timestamps of stream of simulated events  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% loading data from mat files
load(fullfile(pathfile, namefile));
I1 = II(:,:,3); O_gt = O_t;

% We assume that the frame rate is 25 fps (between frames 1/25 s)
%num_slices = 800; 25 fps means 1 frame every 40000 us. If the latency is
%50 us, then 40000 / 50 == 800
num_slices = 800;
min_latency = 50; % We assume 1 unit of time for the latency (it is with the current data (1/(25frame/sec))/(2500 slices/frame)))

% Remove NaN values from the ground-truth
Ox = O_gt(:,:,1); Ox(isnan(Ox))=0; Oy = O_gt(:,:,2); Oy(isnan(Oy))=0; 
O_gt(:,:,1)=Ox; O_gt(:,:,2)=Oy; 

% Compute the step size (slice step time) according to the GT
max_events = 1e8; % 100 M events, just for preallocating (speed!!)
motion = factor*O_gt/num_slices; % Trying to simulate the movement that we can follow using 3 frames
x = zeros(max_events,1); y = zeros(max_events,1); 
ts = zeros(max_events,1); pol = zeros(max_events,1);

threshold = 0.15; %Assuming intensity represented with 8 bits

frame_OLD=double(I1);
lastEventFrame = frame_OLD;
initialLog = log(frame_OLD);
accumEvents = zeros(size(frame_OLD));

event_counter = 1;

for ff=1:num_slices
    
    frame_NEW=warp(frame_OLD, motion*ff);

    %TODO: Find another way of hadling the borders
    frame_NEW(isnan(frame_NEW))=frame_OLD(isnan(frame_NEW));
    timeSlice = ff*min_latency;
    [list_posx, list_posy, list_timeStamp, list_pol, newLastEvent, newAccumEvents] = generateEvents(frame_NEW, lastEventFrame, threshold, timeSlice, accumEvents, initialLog);
    
    % Updating data
    lastEventFrame = newLastEvent;
    accumEvents = newAccumEvents;

    pack_events = numel(list_posx);
    x(event_counter:event_counter+pack_events-1)=list_posx;
    y(event_counter:event_counter+pack_events-1) = list_posy;
    ts(event_counter:event_counter+pack_events-1) = list_timeStamp;
    pol(event_counter:event_counter+pack_events-1) = list_pol;
    
    %Updating the number of events
    event_counter = event_counter + numel(list_posx);
     
    if rem(ff, 100)==0
        ff
    end
end

% Get rid of extra space allocated in initialization
x(event_counter:end)=[]; y(event_counter:end)=[]; 
ts(event_counter:end)=[]; pol(event_counter:end)=[];

I2 = uint8(frame_NEW);
% Save all the data and 'reconstructed' I2
save(fullfile(pathfile, strcat('dvs_', namefile)), 'x', 'y', 'ts', 'pol', 'O_gt', 'I1', 'I2', 'II');
keyboard
end

% This function warps the image in frame with the motion in groundTruth 
function [newFrame] = warp(frame, groundTruth)

    [sy, sx] = size(frame);
    [X, Y] = meshgrid(1:sx,1:sy);

    tmp = groundTruth; tmp(isnan(tmp)) = 0;
    Vx = tmp(:,:,1); Vy = tmp(:,:,2);

    Xn = X-Vx; Yn = Y-Vy;
    newFrame = interp2(X, Y, double(frame), Xn, Yn, 'linear');
end

% This function compute the events
function [col, row, timeStamp, pol, lastEvent, newAccumEvents] = generateEvents(frame, oldFrame, threshold, timeSlice, accumEvents, initialLog)
    
    [sizey, sizex] = size(frame);
    lastEvent = oldFrame;
    newAccumEvents = accumEvents;
    
    % Refining the diff because of precision problems (accumulation of errors)
    diff = log(frame)-(initialLog+accumEvents*threshold); 
    
    if sum(sum(isinf(diff)))>0
        diff(isinf(diff))=0;
    end
    
    if sum(sum(isnan(diff)))>0
        diff(isnan(diff))=0;
    end
        
    % Positions where changes happened
    [rowpos, colpos] = find(diff>0 & abs(diff)>=threshold);
    [rowneg, colneg] = find(diff<0 & abs(diff)>=threshold);
    
    %Pack the events randomly
    randpositions = randperm(size(rowpos,1)+size(rowneg,1));
    max_events = 1e7;
    col = zeros(max_events,1); row = zeros(max_events,1); 
    timeStamp = zeros(max_events,1); pol = zeros(max_events,1);
    cnt = 1;
    if size(rowpos,1)+size(rowneg,1) > 0        
        for ii=1:size(randpositions,2)
            
            m = randpositions(ii);
            
            if m<=size(rowpos,1) %TODO: I guess this is for checking limits! Try to change it            
                if colpos(m)>2 && colpos(m)<sizex-1 && rowpos(m)>2 && rowpos(m)<sizey-1
                    col(cnt)= colpos(m)-1; % The original sensor counts from 0 to 127
                    row(cnt)= rowpos(m)-1;
                    timeStamp(cnt) = timeSlice;
                    pol(cnt)=1;
                    lastEvent(rowpos(m),colpos(m))=frame(rowpos(m), colpos(m));                    
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
                    newAccumEvents(rowneg(m-size(rowpos,1)),colneg(m-size(rowpos,1)))=accumEvents(rowneg(m-size(rowpos,1)),colneg(m-size(rowpos,1)))-1;
                    cnt = cnt+1;
                end
            end
        end
    end
    % Get rid of extra space allocated in initialization
    col(cnt:end)=[]; row(cnt:end)=[];
    timeStamp(cnt:end)=[]; pol(cnt:end)=[];
end
