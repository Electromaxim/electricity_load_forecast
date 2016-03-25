function dynamicDateTicks(axH, link)
% DYNAMICDATETICKS is a wrapper function around DATETICK which creates
% dynamic date tick labels for plots with dates on the X-axis. The date
% ticks intelligently include year/month/day information on specific ticks
% as appropriate. The ticks are dynamic with respect to zooming and
% panning. They update as the timescale changes (from years to seconds).
% Data tips on the plot also show intelligently as dates. 
%
% The function may be used with linked axes as well as with multiple 
% independent date and non-date axes within a plot.
%
% USAGE:
% dynamicDateTicks()
%       makes the current axes a date axes with dynamic properties
%
% dynamicDateTicks(axH)
%       makes all the axes handles in vector axH dynamic date axes
%
% dynamicDateTicks(axH, 'link')
%       additionally specifies that all the axes in axH are linked. This
%       option should be used in conjunction with LINKAXES.
%
% EXAMPLES:
% load integersignal
% dates = datenum('July 1, 2008'):1/24:datenum('May 11, 2009 1:00 PM');
% subplot(2,1,1), plot(dates, Signal1);
% dynamicDateTicks
% subplot(2,1,2), plot(dates, Signal4);
% dynamicDateTicks
% 
% figure
% ax1 = subplot(2,1,1); plot(dates, Signal1);
% ax2 = subplot(2,1,2); plot(dates, Signal4);
% linkaxes([ax1 ax2], 'x');
% dynamicDateTicks([ax1 ax2], 'linked')

if nargin < 1 % If no axes is specified, use the current axes
    axH = gca;
end

% Apply datetick to all axes in axH, and store any linking information
axesInfo.Type = 'dateaxes'; % Information stored in axes userdata indicating that these are date axes
for i = 1:length(axH)
    datetick(axH(i), 'x', 'keeplimits');
    if nargin > 1 % If axes are linked, 
        axesInfo.Linked = axH; % Need to modify all axes at once
    else
        axesInfo.Linked = axH(i); % Need to modify only 1 axes
    end
    set(axH(i), 'UserData', axesInfo); % Store the fact that this is a date axes and its link information in userdata
    updateDateLabel('', struct('Axes', axH(i)), 0); % Call once to ensure proper formatting
end

% Set the zoom, pan and datacursor callbacks
figH = get(axH, 'Parent');
if iscell(figH)
    figH = unique([figH{:}]);
end
if length(figH) > 1
    error('Axes should be part of the same plot (have the same figure parent)');
end

z = zoom(figH);
p = pan(figH);
d = datacursormode(figH);

set(z,'ActionPostCallback',@updateDateLabel);
set(p,'ActionPostCallback',@updateDateLabel);
set(d,'UpdateFcn',@dateTip);

% ------------ End of dynamicDateTicks-----------------------


    function output_txt = dateTip(gar, ev)
        pos = ev.Position;
        axHandle = get(ev.Target, 'Parent'); % Which axes is the data cursor on
        axesInfo = get(axHandle, 'UserData'); % Get the axes info for that axes
        try % If it is a date axes, create a date-friendly data tip
            if strcmp(axesInfo.Type, 'dateaxes')
                output_txt = sprintf('X: %s\nY: %0.4g', datestr(pos(1)), pos(2));
            else
                output_txt = sprintf('X: %0.4g\nY: %0.4g', pos(1), pos(2));
            end
        catch % It's not a date axes, create a generic data tip
            output_txt = sprintf('X: %0.4g\nY: %0.4g', pos(1), pos(2));
        end
    end

    function updateDateLabel(obj, ev, varargin)
        ax1 = ev.Axes; % On which axes has the zoom/pan occurred
        axesInfo = get(ev.Axes, 'UserData');
        % Check if this axes is a date axes. If not, do nothing more (return)
        try
            if ~strcmp(axesInfo.Type, 'dateaxes')
                return;
            end
        catch
            return;   
        end
        
        % Re-apply date ticks, but keep limits (unless called the first time)
        if nargin < 3
            datetick(ax1, 'x', 'keeplimits');
        end
            
        
        % Get the current axes ticks & labels
        ticks  = get(ax1, 'XTick');
        labels = get(ax1, 'XTickLabel');
        
        % Sometimes the first tick can be outside axes limits. If so, remove it & its label
        if all(ticks(1) < get(ax1,'xlim'))
            ticks(1) = [];
            labels(1,:) = [];
        end
        
        [yr, mo, da] = datevec(ticks); % Extract year & day information (necessary for ticks on the boundary)
        newlabels = cell(size(labels,1), 1); % Initialize cell array of new tick label information
        
        if regexpi(labels(1,:), '([a-z]{3})|(\d\d/\d\d)', 'once') % Tick format is either mmm or mm/dd
            
            % Add year information to first tick & ticks where the year changes
            ind = [1 find(diff(yr))+1];
            newlabels(ind) = cellstr(datestr(ticks(ind), '/yy'));
            labels = strcat(labels, newlabels);
            
        elseif any(labels(1,:) == ':') % Tick format is HH:MM
            
            % Add month/day/year information to the first tick and month/day to other ticks where the day changes
            ind = find(diff(da))+1; 
            newlabels{1}   = datestr(ticks(1), 'mm/dd/yy-'); % Add month/day/year to first tick
            newlabels(ind) = cellstr(datestr(ticks(ind), 'mm/dd-')); % Add month/day to ticks where day changes
            labels = strcat(newlabels, labels);
            
        end
        
        set(axesInfo.Linked, 'XTick', ticks, 'XTickLabel', labels);
    end
end
%#ok<*CTCH>
%#ok<*ASGLU>
%#ok<*INUSL>
%#ok<*INUSD>
