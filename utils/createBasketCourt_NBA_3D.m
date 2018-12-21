function C = createBasketCourt_NBA_3D
feet_m = 0.3048 ; % 1 feet = 12 inch
inch_m = 0.3048/12 ;
[cy(1:2,:),cy(3:4,:),cy(5:6,:)] = cylinder(1,100) ; Circle = cat(2,cy(1:2:3,:).',zeros(101,1)) ;

c(1,:) = [0 25-8 0]; c(2,:) = [19 25-8 0] ; c(3,:) = [19 25+8 0] ; c(4,:) = [0 25+8 0] ; % Left (feet)
C.RECT_L = [c(1:4,:);c(1,:)]*feet_m  ;
C.RECT_R = [94*feet_m-C.RECT_L(:,1) C.RECT_L(:,2:3)]; % right
c(5,:) = [0 0 0] ; c(6,:) = [94 0 0] ; c(9,:) = [50 0 0] ; % half, all court
c([8 7 10],:) = [c([5 6 9],1) repmat(50,3,1) zeros(3,1)];
C.Court = [c(5:8,:);c(5,:)]*feet_m ;
C.HalfLine = c(9:10,:)*feet_m ;
C.CenterCircle = (Circle*6 + repmat([49 25 0],101,1))*feet_m ;
c(11,:) = [4*feet_m 22*feet_m 2.9+1.05]; c(12,:) = [4*feet_m 28*feet_m 2.9+1.05];
c(14,:) = [4*feet_m 22*feet_m 2.9     ]; c(13,:) = [4*feet_m 28*feet_m 2.9];
C.Board_L = cat(1,c(11:14,:),c(11,:)) ;
c(15,:) = [4 25 10]; c(16,:) = [4+0.15/feet_m 25 10];
C.Root_L = c(15:16,:)*feet_m ;
C.Ring_LC = [4*feet_m+9*inch_m 25*feet_m 10*feet_m] ;
C.Ring_L = (Circle*9*inch_m + repmat(C.Ring_LC,101,1)) ;

C.Board_R = [94*feet_m-C.Board_L(:,1) C.Board_L(:,2:3)] ; % right
C.Root_R = [94*feet_m-C.Root_L(:,1) C.Root_L(:,2:3)] ; % right
C.Ring_RC = [94*feet_m-C.Ring_LC(:,1) C.Ring_LC(:,2:3)] ; % right
C.Ring_R = [94*feet_m-C.Ring_L(:,1) C.Ring_L(:,2:3)] ; % right
C.Line3p_Circle = Circle([81:101 1:20],:,:)*(23*feet_m+9*inch_m) + repmat([4*feet_m+9*inch_m 25*feet_m 0],41,1) ;
C.Line3p_Line = [0 3*feet_m 0; 14*feet_m 3*feet_m 0] ;
C.Line3p_L = [C.Line3p_Line; C.Line3p_Circle;  [14*feet_m 47*feet_m 0; 0 47*feet_m 0] ] ;
C.Line3p_R = [94*feet_m-C.Line3p_L(:,1) C.Line3p_L(:,2:3)] ; % right

C.Circle = Circle;

