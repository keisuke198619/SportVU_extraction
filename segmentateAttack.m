% segmentateAttack.m
% create attack-segement and detect ball hold, pass and shot
% Keisuke Fujii 2019

% e.g. Tracking data of 2015.10.27-2016.1.23 in NBA regular season
% data is available:
% https://github.com/keisuke198619/BasketballData/tree/master/2016.NBA.Raw.SportVU.Game.Logs
% originally, https://github.com/rajshah4/BasketballData
% It was publicly available via the NBA web site (https://stats.nba.com/), but now the access was removed.

clear ; close all ;
% dbstop if error
setup_path_param
load([matDir,'Gamename']);
overwrite = 1;

% create attacking segments ---------------------------------------------------------------------
Th_ball_hold = 1 ; % detection threshold of ball holding [m]
Th_ball_height = 2.8 ; % detection threshold of ball catch (vertical; in the air) [m]
Th_ball_catch = -5 ; % detection threshold of ball catch [m/s^2]
Th_ball_pass = 5 ; % detection threshold of pass [m/s^2]
Th_ball_mov = 1 ; % detection threshold of moving with ball [m]
Th_ball_mov_v = 1 ; % accurate detection threshold of moving [m/2]

for gm = 1:length(Gamename)
    if overwrite ==0 && exist([matDir,'Table_Game_',Gamename{gm,1},'.mat'],'file') == 2
        disp(['Game ',num2str(gm),' ',Gamename{gm,1},' was already segmented (not overwritten)'])
    else
        load([matDir,'GameData_',Gamename{gm,1}]) ;
        for q = 1:length(GameData.Events)
            clear Ball_OF Ball_DF Ball_OF_p Ball_DF_p hl_ps_sh Ball_Hold_team...
                Ball_Hold Pass_Start_End Ph_Trs
            Clock = GameData.Events{q}(:,1) ;
            ShotClock =  GameData.Events{q}(:,2) ;
            pos_b =  GameData.Events{q}(:,3:5) ;
            pos =  GameData.Events{q}(:,16:35) ;
            vel =  GameData.Events{q}(:,55:74) ;
            player_ID =  GameData.Events{q}(:,6:15) ;
            FrameNo = size(pos_b,1);
            jersey_No = GameData.Events{q}(:,36:45) ;
            
            % 2-D distance between players and ball (and ring)
            for t = 1:FrameNo
                for pl = 1:10
                    Distance.Player_Ball(t,pl) = sqrt((pos(t,2*pl-1)-pos_b(t,1)).^2+(pos(t,2*pl)-pos_b(t,2)).^2) ;
                    Distance.Player_Ring{1}(t,pl) = sqrt((pos(t,2*pl-1)-C.Ring_LC(1,1)).^2+(pos(t,2*pl)-C.Ring_LC(1,2)).^2) ; % ついでに選手－左リング距離も
                    Distance.Player_Ring{2}(t,pl) = sqrt((pos(t,2*pl-1)-C.Ring_RC(1,1)).^2+(pos(t,2*pl)-C.Ring_RC(1,2)).^2) ; % 右リング距離
                end
            end
            
            % define a baller
            for t = 1:FrameNo
                % define a baller as the nerarest player to the ball
                [val,Ball_OF(t,1)] = min(Distance.Player_Ball(t,:),[],2) ;
                % temporally detection of ball holding based on the positions
                Ball_Hold(t,1) = (Distance.Player_Ball(t,Ball_OF(t,1))<Th_ball_hold);
                Ball_Hold_team(t,1) = floor(mod(Ball_OF(t,1)+4.9,5)) ;
                % taking the ball height into consideration
                if pos_b(t,3) > Th_ball_height
                    Ball_Hold(t,1) = 0 ;
                end
            end
            
            % hold/pass detection
            vel_b = diff3p(pos_b,Fs) ;
            vel_h_b = sqrt(sum(vel_b.^2,2));
            acc_h_b = diff3p(vel_h_b,Fs);
            Ph_Trs = cat(1,1,find(Ball_Hold(1:end-1,1)+Ball_Hold(2:end)==1)+1,FrameNo); % add the first and last frames
            % find misdetection
            for ph = 1:length(Ph_Trs)/2-1 % first: ball holding, last: ball holding / not
                if isempty(find(acc_h_b(Ph_Trs(ph*2+1):Ph_Trs(ph*2+2),1)<Th_ball_catch,1)) % Catch detection
                    Ball_Hold(Ph_Trs(ph*2+1):Ph_Trs(ph*2+2),1) = zeros(Ph_Trs(ph*2+2)-Ph_Trs(ph*2+1)+1,1) ;
                end
            end
            
            % exceptional procedure in the case of only one frame detection
            for rep = 1:3 % this has no exact basis
                tmp = find(diff(Ph_Trs)==1); % make it the same as the posterior frame
                if Ph_Trs(tmp) ~= FrameNo
                    Ball_Hold(Ph_Trs(tmp)) = Ball_Hold(Ph_Trs(tmp)+1) ;
                else Ball_Hold(Ph_Trs(tmp)) = Ball_Hold(Ph_Trs(tmp)-1) ;
                end
                Ph_Trs = cat(1,1,find(Ball_Hold(1:end-1,1)+Ball_Hold(2:end)==1)+1,FrameNo); % re-definition
            end
            
            Ball_OF(Ball_Hold==0)=0; % re-definition
            tmp = Ball_Hold==1 ;
            hl_ps_sh(tmp,1) = 1; % transform into number
            hl_ps_sh(hl_ps_sh==0,1) = 2 ; % hold/pass/shoot = 1-3
            Ball_Team = Ball_OF ;
            Ball_Team(and(Ball_Team>=1,Ball_Team<=5)) = 1 ; Ball_Team(Ball_Team>5) = 2 ;
            Ball_Team_p = Ball_Team ;
            
            % detection of shot and ball receiver after pass
            Ball_OF_p = Ball_OF ;
            T2Catch = zeros(FrameNo,1) ;
            FutureBOP = NaN(FrameNo,2) ;
            for t = 1:FrameNo
                if Ball_OF(t) ~= 0
                    FutureBOP(t,:) = pos(t,Ball_OF(t)*2-1:Ball_OF(t)*2) ;
                end
            end
            
            % Detection of Ballstart, HomeRight (Team 1:home  2:Away)
            BallStart(1,1) = find(Ball_Team ~= 0,1,'first') ;
            BallStart(1,2) = Ball_Team(BallStart(1,1)) ;
            BSM = find(diff(Ball_Team) ~= 0,1,'first') ;
            BallStartMove = mean(diff(pos_b(1:BSM,1)))>0 ; % 1: attacking rightward　2: attacking leftward
            for  tm = 1:2
                for ph = 2:length(Ph_Trs)-1 %
                    if Ball_Hold(Ph_Trs(ph),1) == 0 && Ball_Team(Ph_Trs(ph)-1,1) == tm % team holding ball
                        clear tmpInt tmpVec tmpDist
                        % shot detection
                        tmpInt = Ph_Trs(ph):Ph_Trs(ph+1) ;
                        for td = 1:length(tmpInt)
                            distRR = sqrt((pos_b(tmpInt(td),1)-C.Ring_RC(1,1))^2+(pos_b(tmpInt(td),2)-C.Ring_RC(1,2))^2) ;
                            distLR = sqrt((pos_b(tmpInt(td),1)-C.Ring_LC(1,1))^2+(pos_b(tmpInt(td),2)-C.Ring_LC(1,2))^2) ;
                            tmpDist(td,1) = min(distRR,distLR) ;
                        end
                        
                        if max(pos_b(tmpInt,3)) >= 3.05 && ... % ball is over the ring
                                min(tmpDist) < 1 % ball approaches the ring
                            hl_ps_sh(Ph_Trs(ph):Ph_Trs(ph+1)) = 3 ;
                        else
                            if ph == length(Ph_Trs)-1
                                hl_ps_sh(Ph_Trs(ph):Ph_Trs(ph+1)) = 4 ; % end without baller
                            end
                        end
                        % pass receiver
                        if ph ~= length(Ph_Trs)-1 && hl_ps_sh(Ph_Trs(ph))~=3 % not last and not shot
                            if length(Ball_OF)+1 <= Ph_Trs(ph+1)
                                if (Ball_OF(Ph_Trs(ph+1)) <= 5  && Ball_OF(Ph_Trs(ph+1)+1) <= 5) ||...
                                        (Ball_OF(Ph_Trs(ph+1)) >= 6  && Ball_OF(Ph_Trs(ph+1)+1) >= 6) % to teammate
                                    Ball_OF_p(Ph_Trs(ph):Ph_Trs(ph+1)) = Ball_OF(Ph_Trs(ph+1)+1) ;
                                    Ball_Team_p(Ph_Trs(ph):Ph_Trs(ph+1)) = Ball_Team_p(Ph_Trs(ph+1)+1) ;
                                else % transition
                                    Ball_OF_p(Ph_Trs(ph):Ph_Trs(ph+1)) = Ball_OF(Ph_Trs(ph+1)) ;
                                    Ball_Team_p(Ph_Trs(ph):Ph_Trs(ph+1)) = Ball_Team_p(Ph_Trs(ph+1)) ;
                                end
                                T2Catch(Ph_Trs(ph):Ph_Trs(ph+1)) = (Ph_Trs(ph+1)-Ph_Trs(ph):-1:0)/Fs ;
                                for t = Ph_Trs(ph):Ph_Trs(ph+1)
                                    FutureBOP(t,:) = pos(Ph_Trs(ph+1)+1,Ball_OF_p(t,1)*2-1:Ball_OF_p(t,1)*2) ;
                                end
                                
                            end
                        end
                    end
                end
            end
            % Ball_OF_p(predicted) idx 1-5 regardless of team
            Ball_OF_p(Ball_OF_p>5) = Ball_OF_p(Ball_OF_p>5)-5;
            % shot time detection
            clear ShotTime ResetTime Offense_End
            ShotTime = find(hl_ps_sh>=3) ;
            ShotEnd = ShotTime ;
            if ~isempty(ShotEnd)
                ShotEnd(diff(ShotEnd)==1,:) = [] ;
            end
            Play_End = find(Ball_Hold==1,1,'last') ;
            tmp = Ball_Team(ShotTime-1) ;
            ShotTime = [ShotTime,tmp] ;
            if ~isempty(ShotTime)
                ShotTime(diff(cat(1,1,ShotTime(:,1)))==1,:) = [] ;
            end
            tmp_tab{6} = [] ; resVec = []; vecHalfOF = [];
            
            % segmentate attacking segment (half court for all players)
            ind_lr{1} = find((sum(pos(:,1:2:19)<= 14,2)==10)); % Left for all players
            ind_lr{2} = find((sum(pos(:,1:2:19)>= 14,2)==10)); % Right
            ind_lr{3} = union(ind_lr{1},ind_lr{2}); %
            ClockStop = find(diff(Clock)==0) ; %
            ind_lr{4} = setdiff(ind_lr{3},ClockStop); % all players are in half court during clock runs
            HalfOF = find_start_end(ind_lr{4}); % compute start and end
            
            % Homeright
            clear tmp
            for h = 1:size(HalfOF,1)
                interv = HalfOF(h,1):HalfOF(h,2) ;
                tmp(h,1) = mean(mean(pos(interv,1:2:9)-pos(interv,11:2:19),2),1) ; % if < 0, HomeRight
            end
            if sum(tmp<0) > sum(tmp>0) % if < 0, HomeRight
                HomeRight = 1 ;
            elseif sum(tmp<0) < sum(tmp>0)
                HomeRight = 2 ;
            else
                error('data should be confirmed')
            end
            
            % TeamHOF (attacking team)
            for h = 1:size(HalfOF,1)
                if sum(ind_lr{1}==HalfOF(h,1))==1 ; LR = 1 ; % attacking leftward
                else LR = 2 ; % attacking rightward
                end
                if (LR==2 && HomeRight==1)||(LR==1 && HomeRight==0)
                    TeamHOF(h,1) = 1 ; %
                else TeamHOF(h,1) = 2 ;
                end
            end
            
            % devide segment if HalfOF has multiple ShotTime
            % if length(HalfOF(:,1)) > 1
            for hf1 = length(HalfOF(:,1)):-1:1 % inverse direction
                clear STinHalfOF insert insertT
                STinHalfOF = ShotTime(and(HalfOF(hf1,1)<=ShotTime(:,1),HalfOF(hf1,2)>=ShotTime(:,1)),1);
                % STinHalfOF: ShotTime in HalfOF
                if length(STinHalfOF) >= 1
                    insert = zeros(length(STinHalfOF),2) ; % devide
                    insertT = ones(length(STinHalfOF),1)*TeamHOF(hf1) ; % team
                    insert(1,1) = HalfOF(hf1,1) ;
                    insert(1,2) = STinHalfOF(1) ;
                    if length(STinHalfOF) >= 2 % multiple ShotTime
                        for hf2 = 2:length(STinHalfOF)
                            insert(hf2,1) = STinHalfOF(hf2-1)+1 ;
                            insert(hf2,2) = STinHalfOF(hf2) ;
                        end
                    end
                    HalfOF = cat(1,HalfOF(1:hf1-1,:),insert,HalfOF(hf1+1:end,:)) ;
                    TeamHOF = cat(1,TeamHOF(1:hf1-1),insertT,TeamHOF(hf1+1:end)) ;
                end
                
            end
            % neglect instant NaN (merge)
            if length(HalfOF(:,1)) >2
                for h = length(HalfOF(:,1)):-1:2
                    if TeamHOF(h,1)==TeamHOF(h-1,1) && HalfOF(h,1)-HalfOF(h-1,2) <= 10 &&... % same offense team within 10 frames
                            sum(ismember(ClockStop,HalfOF(h-1,2):HalfOF(h,1)))==0 &&... % without clock stop
                            sum(ismember(ShotTime(:,1),HalfOF(h,1):HalfOF(h,2)))==0 % without time change
                        HalfOF(h-1,2) = HalfOF(h,2) ; % connect segment
                        HalfOF(h,:) = [];
                        TeamHOF(h,:) = [] ;
                    end
                end
            end
            
            th_halfoff = 3*Fs ; % important threshold-------------------------------
            HalfOF = HalfOF((HalfOF(:,2)-HalfOF(:,1))>=th_halfoff,:);
            TeamHOF = TeamHOF((HalfOF(:,2)-HalfOF(:,1))>=th_halfoff,:);
            
            % Transition = 0 ;
            % if Transition == 1
            %  detectTransition % incomplete
            % else
            clear tmp_tab Table_Poss1 Shot t_Shot
            
            
            % make Table
            n = length(HalfOF(:,1));
            No = (1:n)' ; % 1: # of HalfOF
            tmp = Clock(HalfOF(:,2)) ; % GameClock(Count down)
            Game = repmat(gm,n,1); Quarter = repmat(q,n,1) ; % 2,3: Game and Quarter
            % 4-7: start, end, type (all 1), and duration of HalfOF
            Start = HalfOF(:,1); End = HalfOF(:,2);
            Type = ones(n,1);
            Duration = (HalfOF(:,2) - HalfOF(:,1))/Fs  ; % time length of offense
            
            Min = floor(tmp/60) ; % 8: min
            Sec = mod(floor(tmp),60) ; % 9: sec
            Team = TeamHOF ; % 10 :team
            
            for nn = 1:n
                ind_shot = and(Start(nn) <= ShotTime(:,1),End(nn) >= ShotTime(:,1)) ;
                if sum(ind_shot) > 0
                    Shot(nn,1) = 1 ; % 11: shot
                    t_Shot(nn,1) = ShotTime(find(ind_shot,1)) ; % 12: shot time
                else
                    Shot(nn,1) = 0 ;
                    t_Shot(nn,1) = 0 ;
                    
                end
            end
            
            Table_Poss1 = table(No,Game,Quarter,Start,End,Type,Duration,Min,Sec,Team,Shot,t_Shot);
            
            if q >= 2
                Table_Poss = cat(1,Table_Poss,Table_Poss1) ;
            elseif q == 1
                Table_Poss = Table_Poss1 ;
            end
            % end
            
            Result.pos = pos ;
            Result.vel = vel ;
            Result.pos_b = pos_b ;
            Result.Ball_Hold_team = Ball_Hold_team ;
            Result.HomeRight = HomeRight ;
            Result.BallStart = BallStart ;
            Result.Ball_Hold = Ball_Hold ;
            Result.Ball_Team = Ball_Team ;
            Result.Ball_Team_p = Ball_Team_p ;
            Result.hl_ps_sh = hl_ps_sh ;
            Result.player_ID = player_ID ;
            Result.Fs = Fs ;
            Result.Ball_OF = Ball_OF ;
            Result.Ball_OF_p = Ball_OF_p ;
            Result.FutureBOP = FutureBOP ;
            Result.T2Catch = T2Catch ;
            Result.ShotTime = ShotTime ;
            Result.Ph_Trs = Ph_Trs ;
            Result.jersey_No = jersey_No ;
            Result.Clock = Clock ;
            Result.ShotClock = ShotClock ;
            
            save([matDir,'AttackSeg_',Gamename{gm,1},'_',num2str(q)],'Result');
        end
        
        % for each game
        Table_Poss.No = [1:size(Table_Poss,1)]' ; % update offense #
        save([matDir,'Table_Game_',Gamename{gm,1}],'Table_Poss');
        
        %         save([matDir,'Analyze_Game_',Gamename{gm,1}],'Table_Poss');
        disp(['Segmentate Game',num2str(gm),' ',Gamename{gm,1}]);
    end
end

