function y = find_start_end(x)
% detect starting and ending time  from index vector 
if ~isempty(x)
    y(:,2) = [x(diff(x)>1);x(end)] ;
    y(:,1) = [x(1); x(find(diff(x)>1)+1)] ;
else y = [];
end
