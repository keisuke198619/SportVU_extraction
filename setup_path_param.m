% setup_path_param

Dir = '.\' ; % directory of main code
dataDir = '.\7z'; % 7zfile (only files that you want to analyze
unzipcmd = '"C:\Program Files\7-Zip\7z.exe"' ; % 7z.exe command
% createMatfile_SportVU.m decompresses .7z files, thus you should install p7z
% (http://p7zip.sourceforge.net) before running it.
% For example, if you use osx, you can install it via brew install p7z.
% Then, if you installed p7z via brew, you should set
% unzipcmd = '[7z.exe directory]/7z'
% [7z.exe directory] = /usr/local/bin/

jsnDir = '.\json\' ; % json Data
matDir = '.\mat\' ; % mat Data
videoDir = '.\video\' ; % Video output
addpath '.\utils'  

if ~exist(jsnDir,'dir')
    mkdir('.\', 'json')
end
if ~exist(matDir,'dir')
    mkdir('.\', 'mat')
end
if ~exist(videoDir,'dir')
    mkdir('.\', 'video')
end

% parameters
Fs = 25 ; % sampling frequency
feet_m = 0.3048 ; 
C = createBasketCourt_NBA_3D ; % court information

