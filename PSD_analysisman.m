
function PSD_analysisman()

% add toolbox to the path.
addpath(genpath('Nex5RDR'));  
addpath(genpath('chronux_2_12'));
addpath(genpath('weirdname'));
addpath(genpath('other_code'));
% execute function.
code_de_merde()

%%%%%%%%%%%%%%%%%%

function code_de_merde()
% how_many_file = inputdlg('How many files wish to process:','ready',[1 40],{'1'}); % dialogbox for getting how many loops (how many files) 
% how_many_file = str2double(how_many_file{1})

% pop up for nex5 files accquire(path and file name)
[fn_get, path_get] = uigetfile('*.nex5', 'Select .nex5 NeuroExplorer file', ...
    'C:\Users\311\Documents\MATLAB\', ...
    'MultiSelect', 'on');

% pop up for PSD save path (directory, need to add '\')
[path_out] = uigetdir('C:\Users\311\Documents\MATLAB\','PSD output path select');

file_chan = [1 2 3 4]; % default channel selected(FD)
file_get = fullfile(path_get,fn_get); % assign path and file to fullfile in order to input Nex5reader
input_sheet = 1; % convert string into number

if iscell(file_get) % if the file selected are multiple
    file_col = width(fn_get); % how many file
    fn_show = erase(fn_get,".nex5")'; % show all the names(can be deleted)

else 
    file_col = 1;
    fn_show = erase(fn_get,".nex5");
    
end

% PRE-LOOP for timtable select
exl = struct([]);
for fc = 1:file_col % for each nex5 file

    exlttl = strcat('Select a Excel File:',file_get(fc)); % put the nex5 file you select in the title

    [exl(fc).file,exl(fc).path] = uigetfile( ... % input excel file
    {...
    '*.xlsx','Excel (*.xlsx)'; ...
    '*.xls','Excel (*.xls)'; ...
    '*.*',  'All Files (*.*)'                                                                            
    }, ...                  % filter
    exlttl{1,1},...     % title
    'MultiSelect', 'off'...  % multiselect
    );
end


% MAIN LOOP HERE    
 for fc = 1:file_col % for each nex5 file
     disp([fc, file_get(fc)])
     for fcc = 1:width(file_chan) % for each channel
        poop_select() % perform analysis
     end
 end

 pooplete = msgbox('data analysis complete :D');


%%%%%%%%%%%%%%%%%%

function poop_select()

    % use if statment to separate one file process and multiple files process

if iscell(file_get) % if the file selected are multiple
    file = readNex5File(file_get{fc}); % note: file_get are structs, so use{} to select different structure
    fn_output = fn_show(fc);
else
    file = readNex5File(file_get);
    fn_output = fn_show;
end

list = file.contvars; % assign variable "list" to contvars of file
StringList = [""]; 
for i = 1:length(list)
    StringList = [StringList;list{i,1}.name]; % transpose list?? I dont get it
end
StringList = StringList(2:end); %wtf

% channel = listdlg('ListString',StringList) % open a lialogbox to select channel
fs = list{file_chan(fcc),1}.ADFrequency ;
FP = list{file_chan(fcc),1}.data; % a looooong coloum vector

%power spectrum save (default nex5 file name)
% filename_temp = inputdlg({'filename_ps(1,2,...):'},'filename'); 
filename_ps = strcat(fn_output,'.xlsx'); % use <strcat> to link the name you jut type and .xlsx to make it a file

%accqiure timestamps 
fullpath = strcat(exl(fc).path,exl(fc).file)
time_table = xlsread(fullpath, input_sheet, 'B2:C1000'); % read excel from a certain area
num_timeset = size(time_table,1); % number of timesets by counting how many rows in the first column

[~,ind] = max(time_table(:, 2) - time_table(:, 1)); %still havent figure out

for i = 1:num_timeset % num_subdata段数据，即循环次数！
    %%截取数据
    s_t = time_table(i,1); % 起始时间
    e_t = time_table(i,2); % 终止时间
    fward=s_t*fs+1;
    bward=e_t*fs;
    sig=FP(fward:bward,1); % 读取s_t-s_t秒、1个通道的数据，FP是一列
    Fs =fs; % 采样频率
 
    %%preprocessing
    sig = detrend(sig);
    sig = sig - mean(sig);
    params.Fs=Fs;
    sig = rmlinesc(sig,params,1.5,'n',50);% pad = 1.5, f0 set to default
    sig=highpassfilter_jie(sig,Fs,1);
    
    % using filter for 49 to 51 fre
    d = designfilt('bandstopiir','FilterOrder',2, ...
               'HalfPowerFrequency1',49,'HalfPowerFrequency2',51, ...
               'DesignMethod','butter','SampleRate',Fs);
    sig = filtfilt(d, sig);

    %%power spectrum
     %###########################
    params.tapers=[3 5];
     %###########################
    [Sps,fps] = mtspectrumc(sig,params); % power spectrum ：params.tapers=[1 1];默认值是[3,5]
    
    %%power
%     figure
%     plot_vector(Sps,fps);%%plot_vector 取了对数,此处仅为展示用，没有统一长度
%     axis([0 120 0 80])
    Sps_to_write{i} = Sps;
    fps_to_write{i} = fps;

    %%spectrogram(热图)
    %###########################
    movingwin=[1000/Fs, 1/Fs]; % 单位：S(这里200表示窗函数的宽度（点数），2表示步长（点数）)
    %###########################
    [Ssg,tsg,fsg] = mtspecgramc(sig, movingwin, params);
%     plot_mtspecgram(Ssg./(sum(sum(Ssg))),tsg,fsg,[0,80]);%
    
end

%%统一长度，转换成psd
 %###########################################
band_Fre = [4,8;8,12;12,30;30,50;50,80;39,41]; % Target Frequency Band 
 %############################################
band_power = zeros(num_timeset,size(band_Fre,1)); % 存bandpower
for i = 1:num_timeset 
    Sps_temp = interp1(fps_to_write{i},Sps_to_write{i},fps_to_write{ind});%%统一长度
    Spsd_to_calc{i}= Sps_temp/(0.5*Fs/(length(fps_to_write{ind})-1));%转换成psd（除以df）
end

%%calcu band power
for i = 1:num_timeset
    for j = 1:size(band_power,2)
        fmin = band_Fre(j,1); 
        fmax = band_Fre(j,2); % 上下边界， 如delta波1-3Hz
        band_power(i,j)=bandpower(Spsd_to_calc{i},fps_to_write{ind},[fmin fmax], 'psd');%%用psd求bandpower
    end
end
band_power=band_power./sum(band_power(:,1:5),2);                                 

% ouput the band power data to differnet sheets of one excel(number of sheet = number of channel)
xlswrite(fullpath,band_power,fcc,'D2');

% 4.保存power spectrum（统一长度并取log后）
%统一长度，取对数，除以标准
for i = 1:num_timeset 
    Sps_to_excel{i} = interp1(fps_to_write{i},10*log10(Sps_to_write{i}),fps_to_write{ind});
    Sps_to_excel{i} = interp1(fps_to_write{i},Sps_to_write{i},fps_to_write{ind});
end

%norm 
[~,aa]=min(abs(fps_to_write{ind}-90));
for i = 1:num_timeset   
    Sps_to_excel{i} =  80 + 10*log10(Sps_to_excel{i}(1:aa)/sum(Sps_to_excel{i}(1:aa)));
end

%写入Excel
data_to_write=[];
for i = 1:num_timeset+1 
    if i == 1               % honestly wtf is this?
        data_to_write(:,i) = change_row_to_column(fps_to_write{ind}(1:aa));  
%         data_to_write(:,i) = change_row_to_column(fps_to_write{ind});
    else
        data_to_write(:,i) = change_row_to_column(Sps_to_excel{i-1});   
    end
end

fullpath_ps=strcat(path_out,'\',filename_ps); % fullpath is the PSD output dir you selected in the beginning.

if iscell(file_get) % if the file selected are multiple
    xlswrite(fullpath_ps{1},data_to_write,fcc);   % output excel file
else
    xlswrite(fullpath_ps,data_to_write,fcc);
end

% first check in matlab(can be deleted)
% num_timeset
% figure() % create a new figure 
% for num_event = 2:num_timeset+1
%     plot (data_to_write(:,1),data_to_write(:,num_event),'DisplayName', string(num_event - 1)) % plot that bitch
%     hold on
% end
% [t,s] = title('Power spectrum ',[fn_output, StringList(fcc)],...
%     'Color','black');
% 
% legend

end

end

end