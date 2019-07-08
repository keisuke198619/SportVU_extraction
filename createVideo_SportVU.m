% createVideo_SportVU
% Keisuke Fujii & Motokazu Hojo, 2018

% e.g. Tracking data of 2015.10.27-2016.1.23 in NBA regular season
% data is available:
% https://github.com/keisuke198619/BasketballData/tree/master/2016.NBA.Raw.SportVU.Game.Logs
% originally, https://github.com/rajshah4/BasketballData
% It was publicly available via the NBA web site (https://stats.nba.com/), but now the access was removed.

clear ; close all ;
dbstop if error

setup_path_param
load([matDir,'Gamename']);
nfile = length(Gamename) ;

% movie ----------------------------------------------------------
skip = 5 ;
for gm = 1:nfile
    load([matDir,'GameData_',Gamename{gm,1}]) ;
   
    for q = 1:length(GameData.Events)
        filename = [GameData.filename,'_Q',num2str(q)];
        PosStr = {'Poss','Shot'} ; TeamStr = {GameData.home.abbreviation,GameData.visitor.abbreviation};
        
        Start = 1 ; 
        End = size(GameData.Events{q},1);% 2000 ; % should change
        
        eval(['v = VideoWriter(''',videoDir,'Q_Game',Gamename{gm,1},'_',num2str(q),'Q','_',num2str(Start),'-',num2str(End),'.mp4'',''MPEG-4'');']);
        open(v)
        figure(1); % faster if figure('visible','off');
        set(gcf,'color',[1 1 1],'visible','off') ;
        for t = Start:skip:End
            % Court
            plotBasketCourt_Full(C,3) ;
            % Ball
            xy = GameData.Events{q}(t,3:5) ;
            clr = [0.6 0.3 0];
            plot3(xy(1,1),xy(1,2),xy(1,3),'o','markersize',6,'color',clr,'markerfacecolor',clr); hold on
            for pl = 1:10
                if GameData.Events{q}(t,45+pl) == 1; clr = 'r';% home
                elseif GameData.Events{q}(t,45+pl) == 2;  clr = 'b';% visitor
                end
                No = num2str(GameData.Events{q}(t,35+pl));
                xy = GameData.Events{q}(t,15+2*pl-1:15+2*pl) ;
                xy = [xy 2];
                plot3(xy(1,1),xy(1,2),xy(1,3),'o','markersize',6,'color',clr,'markerfacecolor',clr); hold on
                plot3(xy(1)+C.Circle(:,1)*0.5,xy(2)+C.Circle(:,2)*0.5,zeros(101,1),'--','color',clr) ;
                plot3([xy(1) xy(1)],[xy(2) xy(2)],[xy(3) 0],'-','color',clr) ;
                text(xy(1,1),xy(1,2),0,No);
            end

            cl = GameData.Events{q}(t,1);
            sc = GameData.Events{q}(t,2);
            hom = GameData.home.abbreviation ;
            vis = GameData.visitor.abbreviation ;
            title([hom,'(red) vs.',vis,'(blue) ',sprintf('clock: %0.2f sec, shot: %0.2f sec (%d frame),  ',cl,sc,t)] )
            axis equal
            set(gca,'xlim',[-1 29],'ylim',[-1 16],'zlim',[0 4]) ;
            set(gca,'CameraPosition',[-136 -38 74],'CameraTarget',[14 7.5 1.975],'CameraViewAngle',5.63295) ;
            box off
            hold off
            mov= getframe(gcf);
            drawnow
            writeVideo(v,mov);
        end
        close(v);
    end
end
