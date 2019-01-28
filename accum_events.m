function out= accum_events(x_in, y_in, pol_in, t_in, width, height)
% This is an implementation for the backgound noise substraction activity
% For every new event that comes in, the function checks the activity 
% that happened in an area of 'block_size' size surrounding the event
% position. If there is no new activity (nothing within a difference of
% 'deltaT' time, the event is filtered out
% Input: 
%      x_in:        x positions of stream of events 
%      y_in:        y positions of stream of events
%      pol_in:      polarities of stream of events 
%      t_in:        timestamps of stream of events 
% Output:
%      out:         image of accumulated events 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

img_ev_pos = zeros(height, width);
img_ev_neg = zeros(height, width);

for ii=1:numel(x_in)
    if pol_in(ii)==1           
        img_ev_pos(y_in(ii),x_in(ii))=img_ev_pos(y_in(ii),x_in(ii))+1;
    else
        img_ev_neg(y_in(ii),x_in(ii))=img_ev_neg(y_in(ii),x_in(ii))-1;
    end
end

out = img_ev_pos + img_ev_neg;

end