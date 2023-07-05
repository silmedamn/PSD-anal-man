% note:this script/function is for calculating mean of 4 channel and put it
% into a new xls table, with first column(x) missing.(which is why its called presentman,
% can be pasted straight up into graphpad)

function PSD_presentman()

% select file for input
[csv_file, csv_path] = uigetfile({'*.xlsx';'*.csv'}, ...
    'Select file for presentman input', ...
    "MultiSelect","on");

% select path for output
[out_path] = uigetdir


readfile = fullfile(csv_path, csv_file) % while multiselected, readfile is a 1xn cell.
% readfile = 'C:\Users\311\Documents\MATLAB\data\PV-LFPresult\PSD_out\40Hz\C57-A2646-40Hz.xlsx'

% multiple file check statement
if iscell(csv_file)
    file_count = width(csv_file)
    
else
    file_count = 1
    out_name = csv_file; % name of ouput file
end


for mi = 1:file_count
    for ei = 2:11 % event loop* first event start from B
        % read the celltable
        Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        for si = 1:4 % 4 sheets
            sheet = si;
            xlrange = strcat(Alphabet(ei),'1:',Alphabet(ei),'738');

            if file_count == 1
                event_data(:,si) = xlsread(readfile,sheet,xlrange)
            else
                event_data(:,si) = xlsread(readfile{1,mi},sheet,xlrange)
                out_name = csv_file{1,mi};
            end        

        m_data = mean(event_data,2) % calculate the mean
    
        out_fullpath = strcat(out_path,'\',out_name)

        out_datarange = strcat(Alphabet(ei),'1');
        
        writematrix(m_data,out_fullpath,'Range',out_datarange) % write the data
        end
    end
end

end