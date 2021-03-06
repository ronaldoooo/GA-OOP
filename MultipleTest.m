% 构建测试矩阵
F = [2, 3, 4];
M1 = [4, 6, 8];
M2 = [3, 4, 6];
N = [50, 75, 100];

LF = length(F);
LM = length(M1);
LN = length(N);
TM = zeros(LF * LM * LN, 35);% test matrix

for i = 1:LF
    for j = 1:LM
        for k = 1:LN
            row = (i - 1) * LM * LN + (j - 1) * LN + k;
            TM(row, 1:4) = [F(i), M1(j), M2(j), N(k)];
        end
    end
end

% 测试开始
for i = 1:length(TM(:, 1))
    % 更新变量
    V = Const.V;
    V.update(TM(i, :));

    tic;% 做一次SPT
    SPT = zeros(1, 1);
    SPT(1, 1) = 10000 / Strategy.SPT(false);
    tSPT = toc;
    
    tic;% 做10次GA
    GA = zeros(1, 10);
    for j = 1:10
        GA(1, j) = 10000 / Strategy.GA(false);
    end
    tGA = toc;
    
    tic;% 做10次LBGA
    LBGA = zeros(1, 10);
    for j = 1:10
        LBGA(1, j) = 10000 / Strategy.LBGA(false);
    end
    tLBGA = toc;
    
    tic;% 做10次ALBGA
    ALBGA = zeros(1, 10);
    for j = 1:10
        ALBGA(1, j) = 10000 / Strategy.ALBGA(false);
    end
    tALBGA = toc;
    
    TM(i, 5) = SPT;
    TM(i, 6:15) = GA;
    TM(i, 16:25) = LBGA;
    TM(i, 26:35) = ALBGA;
end

TM = [(1:length(TM(:, 1)))' TM];

table = array2table(TM, 'VariableNames', {...
    'No', 'F', 'M1', 'M2', 'N', 'SPT',...
    'GA01', 'GA02', 'GA03', 'GA04', 'GA05', 'GA06', 'GA07', 'GA08', 'GA09', 'GA10', ...
    'LBGA01', 'LBGA02', 'LBGA03', 'LBGA04', 'LBGA05', 'LBGA06', 'LBGA07', 'LBGA08', 'LBGA09', 'LBGA10', ...
    'ALBGA01', 'ALBGA02', 'ALBGA03', 'ALBGA04', 'ALBGA05', 'ALBGA06', 'ALBGA07', 'ALBGA08', 'ALBGA09', 'ALBGA10' ...
});
writetable(table, 'MultipleTest.xlsx', 'WriteRowNames', true);
