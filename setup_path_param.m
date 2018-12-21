% setup_path_param

Dir = '.\' ; % directory of main code
dataDir = '.\7z'; % 7zfile (only files that you want to analyze
unzipDir = '"C:\Program Files\7-Zip\7z.exe"' ; % 7z.exe directory
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

