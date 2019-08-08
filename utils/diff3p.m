function y = diff3p(x,fs)

% three point differentiation
% x: data matrix (time*dim)
% fs: sampling frequency
 
y = x ; % initialize
y(1,:) = (-3*x(1,:) + 4*x(2,:) - x(3,:))/(2/fs)  ;         % first
y(2:end-1,:) = (-x(1:end-2,:) + x(3:end,:))/(2/fs) ;       % middle
y(end,:) = (x(end-2,:) - 4*x(end-1,:) +3*x(end,:))/(2/fs) ; % last


