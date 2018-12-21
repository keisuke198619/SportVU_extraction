function plotBasketCourt_Full(C,dim)
if dim == 2
    plot(C.RECT_R(:,1),C.RECT_R(:,2),'k') ; hold on;
    plot(C.RECT_L(:,1),C.RECT_L(:,2),'k') ;
    plot(C.Court(:,1),C.Court(:,2),'k') ;
    plot(C.HalfLine(:,1),C.HalfLine(:,2),'k') ;
    plot(C.CenterCircle(:,1),C.CenterCircle(:,2),'k') ;
    plot(C.Board_R(:,1),C.Board_R(:,2),'k') ;
    plot(C.Board_L(:,1),C.Board_L(:,2),'k') ;
    plot(C.Root_R(:,1),C.Root_R(:,2),'k') ;
    plot(C.Root_L(:,1),C.Root_L(:,2),'k') ;
    plot(C.Ring_R(:,1),C.Ring_R(:,2),'k') ;
    plot(C.Ring_L(:,1),C.Ring_L(:,2),'k') ;
    plot(C.Line3p_L(:,1),C.Line3p_L(:,2),'k') ;
    plot(C.Line3p_R(:,1),C.Line3p_R(:,2),'k') ;
elseif dim == 3 
    plot3(C.RECT_R(:,1),C.RECT_R(:,2),C.RECT_R(:,3),'k') ; hold on;
    plot3(C.RECT_L(:,1),C.RECT_L(:,2),C.RECT_L(:,3),'k') ;
    plot3(C.Court(:,1),C.Court(:,2),C.Court(:,3),'k') ;
    plot3(C.HalfLine(:,1),C.HalfLine(:,2),C.HalfLine(:,3),'k') ;
    plot3(C.CenterCircle(:,1),C.CenterCircle(:,2),C.CenterCircle(:,3),'k') ;
    plot3(C.Board_R(:,1),C.Board_R(:,2),C.Board_R(:,3),'k') ;
    plot3(C.Board_L(:,1),C.Board_L(:,2),C.Board_L(:,3),'k') ;
    plot3(C.Root_R(:,1),C.Root_R(:,2),C.Root_R(:,3),'k') ;
    plot3(C.Root_L(:,1),C.Root_L(:,2),C.Root_L(:,3),'k') ;
    plot3(C.Ring_R(:,1),C.Ring_R(:,2),C.Ring_R(:,3),'k') ;
    plot3(C.Ring_L(:,1),C.Ring_L(:,2),C.Ring_L(:,3),'k') ;
    plot3(C.Line3p_L(:,1),C.Line3p_L(:,2),C.Line3p_L(:,3),'k') ;
    plot3(C.Line3p_R(:,1),C.Line3p_R(:,2),C.Line3p_L(:,3),'k') ;    
end