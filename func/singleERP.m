% Function called by SubplotCallback. Plots single channel ERP with
% statistics when clicked on a subplot.
%
% Copyright (c) 2013 Martin Reiche, Carl-von-Ossietzky-University Oldenburg
% Author: Martin Reiche, martin.reiche@uni-oldnburg.de

% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.

% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

function singleERP(spData)

% create subplot for ERP curve
subplot(2,1,1)

if spData.plotPar.singleScaleAuto
    spData.plotPar.yScale(1) = floor(min(min(spData.chanData)));
    spData.plotPar.yScale(2) = ceil(max(max(spData.chanData)));
end
    

% plot clicked ERP
if spData.plotPar.singleGrid
    grid on;
end

subPlotHandle = subplotERP('single','channel data',spData.chanData,'plot par',spData.plotPar,'analysis',spData.analysis);
h = legend(subPlotHandle,spData.labels{spData.currInd});
set(h, 'Location', 'southwest');

% create subplot for statistics
subplot(2,1,2)

hold on;

for iWin = 1:size(spData.plotPar.compWin,1)
    
    statWin = [round(((spData.plotPar.compWin(iWin,1)+abs(spData.plotPar.xScale(1)))*spData.analysis.sampRate)/1000) ...
               round(((spData.plotPar.compWin(iWin,2)+abs(spData.plotPar.xScale(1)))*spData.analysis.sampRate)/1000)];
    
    % % get data for each wave
    % for iWave = 1:size(spData.chanData,2)
    %     erpMean(iWin,iWave) = mean(spData.chanData(statWin(1):statWin(2),iWave));
    %     spData.erpErr(iWin,iWave) = std(spData.chanData(statWin(1):statWin(2),iWave))/sqrt(numel(spData.analysis.subjects));
    % end
end 



% plot histogram
if size(spData.plotPar.comps,1) == 1
    % plot each bar separately if the there is only one component window
    % (otherwise there will be problems with the bar
    % coloring)
    for iBar = 1:size(spData.erpMean,2)
        bar(iBar,spData.erpMean(iBar),'facecolor',spData.plotPar.currColor(iBar,:));
    end
else
    hB = bar(spData.erpMean);
end
% color the bars according to the waves in the plots
if size(spData.plotPar.comps,1) > 1
    for iWave = 1:size(spData.erpMean,2)
        set(hB(iWave),'facecolor',spData.plotPar.currColor(iWave,:));
    end
end

numgroups = size(spData.erpMean, 1);
numbars = size(spData.erpMean, 2);

groupwidth = min(0.8, numbars/(numbars+1.5));

% Based on barweb.m by Bolu Ajiboye from MATLAB File Exchange
xVec = [];
for iBar = 1:numbars
    if size(spData.plotPar.comps,1) == 1
        x = iBar;
        xVec = [xVec x];
    else                        
        x = (1:numgroups) - groupwidth/2 + (2*iBar-1) * groupwidth / (2*numbars); % Aligning error bar with individual bar
        xVec = [xVec x];
    end
    errorbar(x, spData.erpMean(:,iBar), spData.erpErr(:,iBar), 'k', 'linestyle', 'none');
end
% reshape the bar positions according to the component windows
if size(spData.erpMean,1) > 1
    xVec = reshape(xVec,size(spData.erpMean,1),size(spData.erpMean,2));
else
    set(gca,'XLim',[(xVec(1) - 1) (xVec(end) + 1)]);
end
% get the central position (centarl bar) of each component windows
xTickPos = zeros(1,size(xVec,1));
for iWin = 1:size(xVec,1)
    xTickPos(1,iWin) = median(xVec(iWin,:));
end

% determine Y Axis scaling automaticaly or take from whole figure
if spData.plotPar.singleScaleAuto 
    % get min and max of bar chart data range
    meanMaxValues = [];
    for iWave = 1:numel(spData.erpMean)
        meanMaxValues = [meanMaxValues spData.erpMean(iWave) - spData.erpErr(iWave)];
        meanMaxValues = [meanMaxValues spData.erpMean(iWave) + spData.erpErr(iWave)];
    end
    % get minimal and maximal value for current figure
    meanMin = min(meanMaxValues);
    meanMax = max(meanMaxValues);
else
    meanMin = spData.plotPar.yScaleMean(1);
    meanMax = spData.plotPar.yScaleMean(2);
end

set(gca,'XTick',xTickPos);
set(gca,'XTickLabel',spData.plotPar.winNames);
set(gca,'YLim',[(meanMin - spData.plotPar.yOverhead)  (meanMax + spData.plotPar.yOverhead)]);
set(get(gca,'YLabel'),'String','Voltage (micro Volts)');

UIbtn = uicontrol(gcf,'Style', 'pushbutton', 'String', 'Save Data',...
                  'Position', [10 10 100 40]);

% Assigning relevant data for UI UserData
set(UIbtn,'UserData',spData);
set(UIbtn,'Callback',{@saveRes,UIbtn});
end

function saveRes(src,evnt,UIbtn)
    
% retrieve UserData
    spData = get(UIbtn,'UserData');
    % open save Dialog
    [fileName,pathName] = uiputfile([spData.paths.resDir spData.paths.taskLabel{spData.taskType} '.txt']);
    
    % save the data
    fid = [pathName fileName];
    % the engine
    txt=sprintf('%s\t',spData.resHead{:});
    txt(end)='';
    disp(':: Saving Data.');
    dlmwrite(fid,txt,'');
    dlmwrite(fid,spData.resAll,'-append','delimiter','\t');

end
    