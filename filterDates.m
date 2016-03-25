function dates = filterDates(startDate, endDate, N, X, Y)
% FILTERDATES returns a list of dates between the start and end dates that
% satisfy certain criteria. These criteria are specified as the following
% rule: "Nth X of Y" where N is the occurrence, X is the day type and Y is 
% a month or year. This enables you to filter dates that match rules such as
% "Last business day of the month",  "Third Friday in April", 
% "All Mondays, Wednesdays and Fridays in June and July",
% "Second last business day in July", "Second through Fourth business days
% of June through December"
%
% USAGE:
% 
% dates = filterDates(startDate, endDate, N, X, Y)
%
% startDate and endDate are specify the start and end dates of the date
% range. They can be either scalar date numbers, or scalar date strings.
% N, X and Y can take the following values:
% 
% N: A (vector of) integers, positive specifying the Nth occurence, negative specifying
%    the Nth last occurence. For example N = -1 implies "last", -2 "second
%    to last", 3 "third" and so on. N = 0 implies "all". Note: The N vector
%    must either be ALL POSITIVE, ALL NEGATIVE or SCALAR 0. Combinations
%    cannot be used. Use multiple calls to filterDates to achieve this.
% 
% X: Day of the week (specified by integers 1 through 7 with 1
%    corresponding to Sunday), business day (specified by "B"), weekday ("W"),
%    holiday ("H") or any day ("D"). Note: options 'B' or 'H' require Financial Toolbox.
% 
% Y: "The month" ("M"), a specific month of the year (integers 1 through 12), or 
%    "The year" ("Y")
% 
% For example, 
% (1, 5, 7) "First Thursday of July"
% (3, 'B', 4) "Third business day of April"
% (-1, 'W', 'M') "Last weekday of the month" (equivalent to (-1, 2:6, 'M'))
% (-3:-1, 'H', 'Y') "Last three holidays of the year (Labor day, thanksgiving, Christmas)"
% (0, 2, 'M') "All mondays of the month" (equivalent to (0, 1, 'Y'))
%
% Example:
% % Last business days of the months between June 2008 and July 2011
% dates = filterDates('2008-06-04','2011-07-31',-1,'B','M');
% datestr(dates)

% 0. Check inputs
assert(all(N>0) || all(N<0) || isscalar(N)&&N==0, 'N must be all positive integers, all negative integers or scalar 0');
assert(isnumeric(X) && all(X>=1) && all(X<=7) || ischar(X) && ~isempty(X) && any(lower(X(1))=='bwhd'), 'X must be an integer between 1 & 7 or character B, W, H or D');
assert(isnumeric(Y) && all(Y>=1) && all(Y<=12)|| ischar(Y) && ~isempty(Y) && any(lower(Y(1))=='ym'), 'Y must be an integer between 1 & 12 or character Y or M');

% 1. Convert startDate and endDate into their numeric representations
startDate = datenum(startDate);
endDate = datenum(endDate);

% 2. Adjust actual startDate and endDate to accomodate all rules. A safety
% buffer (of around 7 days) is added to accommodate edge cases. A
% sufficiently large safety buffer should not completely get filtered out
% when filters such as "business days" or "month of June" are applied.
[yr1,mo1] = datevec(startDate);
[yr2,mo2] = datevec(endDate);
if ischar(Y) && lower(Y(1)) == 'y' 
    % If looking for "Nth X of the year" we should start from the last day
    % of the year before startDate (minus safety buffer) to first day of
    % year after endDate (plus safety buffer).
    sd = datenum([yr1,1,1])-1-max(abs(N))-7;
    ed = datenum([yr2+1,1,1])+max(abs(N))+7;
else
    % If looking for "Nth X of a month" we should start from the last day
    % of the month before startDate (minus safety buffer) to first day of
    % month after endDate (plus safety buffer).
    sd = datenum([yr1,mo1,1])-1-max(abs(N))-7; 
    ed = datenum([yr2,mo2+1,1])+max(abs(N))+7;
end
allDates = sd:ed;

% 3. Filter by day type. For example, if we are requesting mondays, keep
% only mondays. If requesting business days or holidays, keep only business
% days or holidays.
if isnumeric(X)
    ind = ismember(weekday(allDates), X);
elseif lower(X) == 'b'
    ind = isbusday(allDates);
elseif lower(X) == 'w'
    ind = ismember(weekday(allDates), 2:6);
elseif lower(X) == 'h'
    ind = ismember(allDates,holidays);
else
    ind = true(size(allDates));
end
allDates = allDates(ind);
[yr,mo] = datevec(allDates);

% 4.a. If the set class is a specific month of the year (eg. June), filter
% out all dates outside June. Then calculate the index of the first day in
% the month (where there is a change in the month). Also remember the
% first or last+1 index of the data to accomodate rules that filter the
% dates to match only a certain day or month when the date range also only
% spans days of that month. Eg. "5th Day of June" between June 4 and June 26
% In this case there is no "change in month" as any dates outside June have
% been filtered out.
if isnumeric(Y)
    allDates = allDates(ismember(mo, Y));
    [yr,mo] = datevec(allDates);
    ind = find(diff(mo)~=0 | diff(yr)~=0)+1; % Find the index of date where the month changes (this is the first of that month)
    if all(N < 0)
        ind = union(ind, length(allDates)+1); % Tack on last+1 index
    elseif all(N > 0)
        ind = union(ind, 1); % Tack on first index
    end
end

% 4.b. If the set class is simply "any month" or "any year", just find the
% index of the first day of each month or year respectively.
if ischar(Y) && lower(Y) == 'y'
    ind = find(diff(yr)~=0)+1;
elseif ischar(Y) && lower(Y) == 'm'
    ind = find(diff(mo)~=0 | diff(yr)~=0)+1;
end
 
% 5. Compute final index vector. The vector IND should now correspond to
% the "first" X of Y or "all" X of Y. Add N (or N-1) to compute the Nth X of Y as required.
% Note, this code is vectorized to handle vectors of N.
if all(N == 0)
    finalInd = 1:length(allDates); % Return all matching dates
else
    finalInd = bsxfun(@plus, ind, N(:)); % Really just ind + N for different sizes of ind and N
    finalInd = finalInd(:);
    if all(N > 0)
        finalInd = finalInd - 1; % Offset because of 1 based indexing
    end
end
finalInd = finalInd(finalInd>0 & finalInd<=length(allDates)); % Remove invalid indices (this is okay because of the safety buffer)

% 6. Filter dates & return
allDates = allDates(finalInd);
dates = allDates(allDates>=startDate & allDates<=endDate);
