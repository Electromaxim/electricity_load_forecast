function [holidays, holidayIndicator, weightedIndicator] = createHolidayDates(startDate, endDate)

if nargin < 2 && ~isscalar(startDate)
    %[dates, sortInd] = sort(startDate);
    dates = floor(startDate);
    startDate = min(dates);
    endDate = max(dates);
end
    


 %3,   2, 1;  ... Martin Luther King Day, 3rd Monday of Jan
 %3,   2, 2;  ... President's day, 
 %2,   2, 10; ... Columbus day, second Monday in October

holidays = {};
hweights = {};

% New Years Day
holidays{end+1} = filterDates(startDate, endDate, 1, 'D', 1)';
hweights{end+1} = 1 * ones(size(holidays{end}));

% Memorial day, last Monday in May
holidays{end+1} = filterDates(startDate, endDate, -1, 2, 5)';
hweights{end+1} = 1 * ones(size(holidays{end}));

% 4th July
holidays{end+1} = filterDates(startDate, endDate, 4, 'D', 7)';
hweights{end+1} = 1 * ones(size(holidays{end}));

% Labor day
holidays{end+1} = filterDates(startDate, endDate, 1, 2, 9)';
hweights{end+1} = 1 * ones(size(holidays{end}));

% Thanksgiving & Day after thanksgiving
th = filterDates(startDate, endDate, 4, 5, 11)';
holidays{end+1} = [th; th+1];
hweights{end+1} = [2 * ones(size(th)); .5 * ones(size(th))];

% Christmas
xmas = filterDates(startDate, endDate, 25, 'D', 12)';
holidays{end+1} = [xmas-1; xmas; xmas+1];
hweights{end+1} = [.5 * ones(size(xmas)); 1 * ones(size(xmas)); .5 * ones(size(xmas))];

holidays = vertcat(holidays{:});
hweights = vertcat(hweights{:});
[holidays, index] = sort(holidays);
hweights = hweights(index);

% holidayIndicator = false(size(dates));
if nargout > 1
    [holidayIndicator, index] = matchAny(dates, holidays);
end
if nargout > 2
    weightedIndicator = zeros(size(holidayIndicator));
    weightedIndicator(holidayIndicator) = hweights(index(holidayIndicator));
end
