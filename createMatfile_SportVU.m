% createMatfile_SportVU
% Keisuke Fujii & Motokazu Hojo, 2018

% e.g. Tracking data of 2015.10.27-2016.1.23 in NBA regular season
% data is available:
% https://github.com/keisuke198619/BasketballData/tree/master/2016.NBA.Raw.SportVU.Game.Logs
% originally, https://github.com/rajshah4/BasketballData
% It was publicly available via the NBA web site (https://stats.nba.com/), but now the access was removed.

clear ; close all ;

setup_path_param
overwrite = 1 ;
usefilter = 0 ; 

% extract list including only 7z files---------------------------------------------
filelist = dir(dataDir) ;
for f = length(filelist):-1:1
    if contains(filelist(f).name,'.7z') == 0
        filelist(f) = [] ;
    end
end
nfile = size(filelist,1); % number of files to read

% In NBA data, games 98,99,100,149,156 have no data
n = 1 ;
for nn = 1:nfile
    if filelist(nn).bytes > 100000
        file7z{n,1} = filelist(nn).name; %
        Gamename{n,1} = strrep(erase(file7z{n,1},'.7z'),'.','_') ;
        n = n + 1 ;
    end
end
nfile = length(Gamename) ; 
 
save([matDir,'Gamename'],'Gamename');


% load data and create rawdata------------------------------------------------------
for gm = 1:nfile
    if overwrite ==0 && exist([matDir,'GameData_',Gamename{gm,1},'.mat'],'file') == 2
        disp(['Game ',num2str(gm),' ',Gamename{gm,1},' was already created (not overwritten)'])
    else
        clear jsonfile GameData connectdat rawdat
        % find json files
        jsonfile = dir(jsnDir);
        for f = length(jsonfile):-1:1
            if contains(jsonfile(f).name,'.json') == 0 % not json
                jsonfile(f) = [] ;
            else
                % eliminate already unzipped json file
                if contains(jsonfile(f).name, Gamename{gm}) == 1
                    jsonfile = jsonfile(f) ;
                    break
                else jsonfile(f) = [] ;
                end
            end
        end
        
        % execute 7z.exe to decompress 7z into json
        if isempty(jsonfile) %
            [status,cmdout] = ... % see setup_path_param.m
                system([unzipcmd,' x -o',jsnDir,' ',dataDir,'\',file7z{gm,1}]);
            
            jsonfile = dir(jsnDir);
            for f = length(jsonfile):-1:1
                if contains(jsonfile(f).name,'.json') == 0 % not json
                    jsonfile(f) = [] ;
                else
                    % rename json file
                    if sum(isletter([jsonfile(f).name])) == 4 % number+json
                        tmpjson = jsonfile(f) ; % temporal file name (number only)
                        jsonfile = [] ;
                        break
                    else jsonfile(f) = [] ;
                    end
                end
            end
            movefile([jsnDir,tmpjson.name],[jsnDir,Gamename{gm,1},'.json']) ;
            disp([file7z{gm,1},' is decompressed',]);
        else
            disp([file7z{gm,1},' was already decompressed']);
        end
        jsonfile = [Gamename{gm,1},'.json'];
        jsonData = jsondecode(fileread([jsnDir,Gamename{gm,1},'.json']));
        disp('jsonData was read');
        
        % create rawdat
        rawdat.gameid = jsonData.gameid ;
        rawdat.gamedate = jsonData.gamedate ;
        rawdat.home = jsonData.events(1).home ;
        rawdat.visitor = jsonData.events(1).visitor ;
        rawdat.filename = strrep(file7z{gm,1},'.7z','') ;
        
        nn = 1 ;
        for ev = 1:length(jsonData.events)
            skip = 0 ; % if duplicated, delete the latter by skipping
            T = length(jsonData.events(ev).moments);
            if T > 0
                if ev >= 2
                    if ~isempty(jsonData.events(ev-1).moments)
                        tmpmom1 = jsonData.events(ev-1).moments{1}{6};
                        tmpmom2 = jsonData.events(ev).moments{1}{6};
                        if size(tmpmom1,1)==size(tmpmom2,1)
                            if sum(sum(tmpmom1-tmpmom2)) == 0
                                skip = 1 ;
                            end
                        end
                    end
                end
                if skip == 0 % if not duplicated
                    rawdat.events(nn).eventId = jsonData.events(ev).eventId ;
                    rawdat.events(nn).playerid = NaN(T,10) ;
                    rawdat.events(nn).pos = NaN(10,2,T) ;
                    for t = 1:T
                        tmpmom = jsonData.events(ev).moments{t} ;
                        rawdat.events(nn).clock(t,1) = tmpmom{3} ;
                        tmp = tmpmom{4} ; % shotclock
                        if ~isempty(tmp)
                            rawdat.events(nn).shotclock(t,1) = tmp ;
                        else ; rawdat.events(nn).shotclock(t,1) = 0 ;
                        end
                        tmp = tmpmom{6} ; % position info,
                        if size(tmp,1) == 11
                            tmpind = find(tmp(:,1)==-1,1);
                            rawdat.events(nn).ball(t,:) = tmp(tmpind,3:5)*feet_m ;
                            tmp(tmpind,:) =[];
                            rawdat.events(nn).playerid(t,:) = tmp(:,2) ;
                            rawdat.events(nn).pos(:,:,t) = tmp(:,3:4)*feet_m ;
                        else % lack
                            if tmp(1) ~= -1 % if data does not include ball
                                if size(tmp,1) == 10
                                    rawdat.events(nn).ball(t,:) = NaN(1,3) ;
                                    rawdat.events(nn).playerid(t,:) = tmp(:,2) ;
                                    rawdat.events(nn).pos(:,:,t) = tmp(:,3:4)*feet_m ;
                                else
                                    rawdat.events(nn).ball(t,:) = NaN(1,3) ;
                                    rawdat.events(nn).playerid(t,:) = NaN(1,10) ; % tmp(:,2) ;
                                    rawdat.events(nn).pos(:,:,t) = NaN(10,2);
                                end
                            else % include ball
                                rawdat.events(nn).ball(t,:) = tmp(tmpind,3:5)*feet_m ;
                                nopl = size(tmp,1) -1 ;
                                if nopl >= 1
                                    rawdat.events(nn).playerid(t,1:nopl) = tmp(2:end,2) ;
                                    rawdat.events(nn).pos(1:nopl,:,t) = tmp(2:end,3:4)*feet_m ;
                                end
                                %                             rawdat.events(nn).playerid(t,nopl+1:end) = NaN(1,10-nopl) ;
                                %                             rawdat.events(nn).pos(nopl+1:end,:,t) = NaN(10-nopl,2) ;
                                % error('error in reading data')
                            end
                        end
                    end
                    % player
                    rawdat.events(nn).player = -ones(10,T) ;
                    rawdat.events(nn).team = -ones(10,T) ;
                    for pl = 1:10
                        if length(unique(rawdat.events(nn).playerid(:,pl)))==1
                            alleach = 1 ;
                        else ; alleach = 2 ;
                        end
                        tmp = rawdat.events(nn).playerid(:,pl) ;
                        if alleach == 1 ; tmp = tmp(1) ; T2 = 1 ; % always the same
                        else
                            T2 = T ;
                        end
                        for t = 1:T2
                            jrs = -1 ; pp = 1 ;
                            while jrs == -1 && pp <= size(rawdat.home.players,1)
                                tmpind = find(rawdat.home.players(pp).playerid==tmp(t),1);
                                if ~isempty(tmpind)
                                    if ~isempty(rawdat.home.players(pp).jersey) % Game 104
                                        jrs = str2num(rawdat.home.players(pp).jersey); team = 1 ;
                                    end
                                end
                                pp = pp + 1 ;
                            end
                            pp = 1 ;
                            while jrs == -1 && pp <= size(rawdat.visitor.players,1)
                                tmpind = find(rawdat.visitor.players(pp).playerid==tmp(t),1);
                                if ~isempty(tmpind)
                                    if ~isempty(rawdat.visitor.players(pp).jersey) % Game 212
                                        jrs = str2num(rawdat.visitor.players(pp).jersey); team = 2 ;
                                    end
                                end
                                pp = pp + 1 ;
                            end
                            if alleach == 1
                                rawdat.events(nn).player(pl,:) = jrs;
                                rawdat.events(nn).team(pl,:) = team;
                            else ; rawdat.events(nn).player(pl,t) = jrs;
                                rawdat.events(nn).team(pl,t) = team;
                            end
                        end
                    end
                    nn = nn + 1 ;
                end
            end
        end
        N_events = length(rawdat.events) ;
        Evse = NaN(N_events,5) ;
        % col1: clock start, col2: clock end, col3: time length
        % col4: duplication from previous events, col5: duplication
        for ev = 1:N_events
            Evse(ev,1) = rawdat.events(ev).clock(1,1) ;
            Evse(ev,2) = rawdat.events(ev).clock(end,1) ;
            Evse(ev,3) = numel(rawdat.events(ev).clock) ;
            if ev >= 2
                Evse(ev,4) = numel(intersect(rawdat.events(ev-1).clock,rawdat.events(ev).clock)) ;
            end
        end
        for ev = 1:N_events
            if ev <= N_events-1
                if (Evse(ev,3) == Evse(ev,4)) || (Evse(ev,3) == Evse(ev+1,4))
                    Evse(ev,5) = 1 ;
                else
                    Evse(ev,5) = 0 ;
                end
            elseif ev == N_events
                if (Evse(ev,3) == Evse(ev,4))
                    Evse(ev,5) = 1 ;
                else
                    Evse(ev,5) = 0 ;
                end
            end
        end
        % elimination of duplicated events
        for ev = N_events:-1:1
            if Evse(ev,5) == 1
                rawdat.events(ev) = [] ;
            end
        end
        N_events = length(rawdat.events) ;
        
        EventStartEnd = zeros(N_events,6) ;
        for ev = 1:N_events
            EventStartEnd(ev,1) = rawdat.events(ev).clock(1,1) ;
            EventStartEnd(ev,2) = rawdat.events(ev).clock(end,1) ;
        end
        
        % find quarter start
        tmp = diff(EventStartEnd(:,1)) ;
        QuarterStart = find(tmp > 500) ; % [s]
        QuarterStart(tmp(QuarterStart+1)<-100) = [] ; % eliminate error trial
        QuarterStart = [1; QuarterStart] ;

        Quarter = zeros(N_events,1) ;
        NQ = length(QuarterStart) ;
        for ev = 1:N_events
            if (ev >= QuarterStart(1,1)) && (ev < QuarterStart(2,1))
                Quarter(ev,1) = 1 ;
            elseif (ev >= QuarterStart(2,1)) && (ev < QuarterStart(3,1))
                Quarter(ev,1) = 2 ;
            elseif ev >= QuarterStart(3,1)
                if NQ == 3 % there is a game having only 3 quarters
                    Quarter(ev,1) = 3 ;
                elseif (ev >= QuarterStart(3,1)) && (ev < QuarterStart(4,1))
                    Quarter(ev,1) = 3 ;
                else % ev >= QuarterStart(4,1)
                    if NQ == 4
                        Quarter(ev,1) = 4 ;
                    else
                        if (ev >= QuarterStart(4,1)) && (ev < QuarterStart(5,1))
                            Quarter(ev,1) = 4 ;
                        else
                            if NQ == 5
                                Quarter(ev,1) = 5 ;
                            else
                                if (ev >= QuarterStart(5,1)) && (ev < QuarterStart(6,1))
                                    Quarter(ev,1) = 5 ;
                                else
                                    if NQ == 6
                                        Quarter(ev,1) = 6 ;
                                    else
                                        if (ev >= QuarterStart(6,1)) && (ev < QuarterStart(7,1))
                                            Quarter(ev,1) = 6 ;
                                        else
                                            if NQ == 7
                                                Quarter(ev,1) = 7 ;
                                            else
                                                if (ev >= QuarterStart(7,1)) && (ev < QuarterStart(8,1))
                                                    Quarter(ev,1) = 7 ;
                                                else
                                                    Quarter(ev,1) = 8 ;
                                                    % temporally stop in quadruple over time
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        % event classification
        % col1: start, col2: end, col3: none/short/start
        % col4: duplication from previous events, col5: time length, col6: quarter
        for ev = 1:N_events
            if ev >= 2
                if sum(ev == QuarterStart(:,1)) == 1
                    EventStartEnd(ev,3) = 2 ; % Quarter start
                elseif EventStartEnd(ev-1,2)+1/Fs <= EventStartEnd(ev,1)
                    EventStartEnd(ev,3) = 1 ; % sometimes duplicated with the frame before
                else
                    EventStartEnd(ev,3) = 0 ;
                end
            end
            EventStartEnd(ev,6) = Quarter(ev,1) ;
        end
        
        for ev = 1:N_events-1
            EventStartEnd(ev,5) = length(rawdat.events(ev).clock(:,1)) ;
            if EventStartEnd(ev+1,3) == 1
                EventStartEnd(ev,4) = (EventStartEnd(ev+1,1) - EventStartEnd(ev,2))*Fs ; % duplication from previous events
            end
            %         if (EventStartEnd(ev,4) > 0) && (EventStartEnd(ev,3) ~= 2)
            %         end
        end
        for q = 1:NQ
            connectdat.events(q).clock = [] ;
            connectdat.events(q).shotclock = [] ;
            connectdat.events(q).ball = [] ;
            connectdat.events(q).playerid = [] ;
            connectdat.events(q).pos = [] ;
            connectdat.events(q).vel = [] ;
            connectdat.events(q).player = [] ;
            connectdat.events(q).team = [] ;
        end
        for q = 1:NQ
            for ev = 1:N_events%-1
                if (EventStartEnd(ev,6) == q) % && (ev ~= QuarterStart(q,1))
                    if length(rawdat.events(ev).clock) == length(rawdat.events(ev).player)
                        connectdat.events(q).clock = cat(1,connectdat.events(q).clock,rawdat.events(ev).clock) ;
                        connectdat.events(q).shotclock = cat(1,connectdat.events(q).shotclock,rawdat.events(ev).shotclock) ;
                        connectdat.events(q).ball = cat(1,connectdat.events(q).ball,rawdat.events(ev).ball) ;
                        connectdat.events(q).playerid = cat(1,connectdat.events(q).playerid,rawdat.events(ev).playerid) ;
                        % connectdat.events(q).pos = cat(3,connectdat.events(q).pos,rawdat.events(ev).pos) ;
                        tmp = reshape(rawdat.events(ev).pos,20,[])';
                        if usefilter == 1 % confirmed in 2016b with Signal Processing Toolbox 
                            tmp = nanfilt(tmp,b_filt,a_filt,Order) ;
                        end 
                        connectdat.events(q).pos = cat(3,connectdat.events(q).pos, reshape(tmp',10,2,[]));
                        connectdat.events(q).vel = cat(3,connectdat.events(q).vel, reshape(diff3p(tmp,Fs)',10,2,[])) ;
                        
                        connectdat.events(q).player = cat(2,connectdat.events(q).player,rawdat.events(ev).player) ;
                        connectdat.events(q).team = cat(2,connectdat.events(q).team,rawdat.events(ev).team) ;
                    end
                end
            end
        end
        
        % Events
        % 1: clock, 2: shotclock, 3-5: ball xyz (m), 6-15: 10 players' id
        % 16-25: 10 players' xy (m), 36-45: 10 players' jursey number, 46-55: 10  players' team
        % you may use id for analysis, number for visualization.
        
        for q = 1:NQ
            GameData.Events{q} = NaN(length(connectdat.events(q).clock(:,1)),55) ;
            GameData.Events{q}(:,1) = connectdat.events(q).clock(:,1) ; % clock
            GameData.Events{q}(:,2) = connectdat.events(q).shotclock(:,1) ; % shotclock
            GameData.Events{q}(:,3:5) = connectdat.events(q).ball(:,1:3) ; % ball xyz
            GameData.Events{q}(:,6:15) = connectdat.events(q).playerid(:,1:10) ; % 10 players' id
            for pl = 1:10
                GameData.Events{q}(:,15+pl*2-1) = connectdat.events(q).pos(pl,1,:) ; % 10 players' xy
                GameData.Events{q}(:,16+pl*2-1) = connectdat.events(q).pos(pl,2,:) ;
                GameData.Events{q}(:,55+pl*2-1) = connectdat.events(q).vel(pl,1,:) ; % 10 players' xy
                GameData.Events{q}(:,56+pl*2-1) = connectdat.events(q).vel(pl,2,:) ;
            end
            GameData.Events{q}(:,36:45) = connectdat.events(q).player(1:10,:).' ; % 10 players' number
            GameData.Events{q}(:,46:55) = connectdat.events(q).team(1:10,:).' ; % 10  players' team
            GameData.Events{q} = unique(GameData.Events{q},'rows','stable') ;
        end
        GameData.gameid = rawdat.gameid ;
        GameData.gamedate = rawdat.gamedate ;
        GameData.home = rawdat.home ;
        GameData.visitor = rawdat.visitor ;
        GameData.filename = rawdat.filename ;
        save([matDir,'GameData_',Gamename{gm,1}],'GameData');
        disp(['data in game ',num2str(gm), ' ',Gamename{gm,1},' was created']);
        % delete([jsnDir,Gamename{gm,1},'.json'])
    end
end
