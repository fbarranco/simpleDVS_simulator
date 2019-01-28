
% createDVSEventsFromFrames('C:\Users\Fran\Documents\maya\projects\default\images\', 'brickbox')
% createDVSEventsFromFrames('C:\Users\Fran\Documents\maya\projects\default\images\', 'brickbox2')

% This code generate a sequence of events using the input sequence
function [posx, posy, timeStamp, pol] = createDVSEventsFromFrames(pathfile, namefile)

slice = 1; 
nframes = 2500; %We create frames for slices of 1 us
posx = []; posy = []; timeStamp=[]; pol=[];
threshold = 0.05; %Assuming intensity represented with 8 bits

f=1;
frame_OLD = double(rgb2gray(imread(strcat(pathfile, namefile, sprintf('%04d.png', f)))));
lastEventFrame = frame_OLD;
initialLog = log(frame_OLD);
accumEvents = zeros(size(frame_OLD));
I1 = frame_OLD;

for f=2:nframes
    
    
    frame_NEW = double(rgb2gray(imread(strcat(pathfile, namefile, sprintf('%04d.png', f)))));
        
    timeSlice = f*slice;
    [tmp_posx, tmp_posy, tmp_timeStamp, tmp_pol, newLastEvent, newAccumEvents] = generateEvents(frame_NEW, lastEventFrame, threshold, timeSlice, accumEvents, initialLog);
    % Updating data
    lastEventFrame = newLastEvent;
    accumEvents = newAccumEvents;

    posx = [posx tmp_posx];
    posy = [posy tmp_posy];
    timeStamp = [timeStamp tmp_timeStamp];
    pol = [pol tmp_pol];
    
    if rem(f, 500)==0
        f
    end
end
I2 = frame_NEW;

keyboard
save(strcat(pathfile, 'dvs_', namefile), 'posx', 'posy', 'timeStamp', 'pol', 'I1', 'I2');

end


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

