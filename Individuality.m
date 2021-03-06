classdef Individuality
    % Individuality 个体类
    %   个体定义为种群中每一个独立的单位，每个个体包含其染色体，以及其适应度值
    %
    %   See also Chromosome.m
    
    properties
        Chromosome;% 个体的染色体
        Fitness;% 个体的适应度
        MachineStop;
    end
    
    methods
        function obj = Individuality(param)
            % Individuality 个体初始化过程
            %   1. 初始化个体的染色体
            %   2. 计算该个体的适应度值
            
            if isa(param, 'Chromosome')
                obj.Chromosome = chromosome;
            elseif isa(param, 'numeric') % 根据提供的基因序列构造个体，注意此处会执行自动修复过程
                obj.Chromosome = Chromosome(param);
            else
                obj.Chromosome = Chromosome(false);
            end
            
            obj = obj.calculateFitness;
        end
        
        function ret = mutation(obj)
            % mutation 变异过程
            %   该函数不会改变个体本身值，会返回一个新的Individuality实例

            p1 = ceil((Const.V.JOB_NUMBER - 1) * rand);
            p2 = p1 + ceil((Const.V.JOB_NUMBER - p1) * rand);

            mutated = obj.Chromosome.Sequence;
            mutated(1, [p1, p2]) = mutated(1, [p2, p1]);
            
            ret = Individuality(mutated);% 构造变异后的个体
        end
        
        function [child_1, child_2] = crossoverWith(parent_1, parent_2)
            % crossoverWith 与另外一个个体交叉，产生两个子代
            %   该函数不会对自身进行修改，会返回两个子代的Individuality实例
            
            child_1 = parent_2;% 子代1初始化为父代2的复制
            child_2 = parent_1;% 子代2初始化为父代1的复制
            
            cc_1 = child_1.Chromosome.Sequence;% 子代染色体1
            cc_2 = child_2.Chromosome.Sequence;% 子代染色体2
            pc_1 = parent_1.Chromosome.Sequence;% 父代染色体1, 自身染色体
            pc_2 = parent_2.Chromosome.Sequence;% 父代染色体2
            
            cr=rand;% 产生(0,1)的随机数
            jobNumber = Const.V.JOB_NUMBER;
            if cr < Const.F.CROSSOVER_PROBABILITY
                p1 = ceil((jobNumber - 1) * rand);
                p2 = p1 + ceil((jobNumber - p1) * rand);
                for j = 1:jobNumber
                    if j <= p1 || j > p2
                        cc_1(1, j) = 0;                    %%子代中未交叉段（第一个切割点之前，第二个切割点之后）的基因赋值为0，便于后续重排
                        cc_2(1, j) = 0;
                    end
                end
                position = 1;
                for j = 1:p1% 该循环对子代第一个切割点之前的基因挨个赋值填充
                    for r = position:jobNumber% 遍历交叉前原序列（父代）各个基因
                        flag = true;% 设定标志，判断原序列挨个基因是否与交叉得来的子段中的基因相同（重复），未重复取true
                        for l = 1:jobNumber% 遍历交叉得来的子段中的基因
                            if pc_1(1, r) == cc_1(1, l)% 如果原序列中该基因与交叉后子段中某基因重复，
                                flag = false;% 则舍弃原序列中该基因
                                break;
                            end
                        end
                        if flag% 将原序列中未与交叉后子段重复的基因依次填充到子代第一个切割点前的未交叉段（即之前赋值为0的基因段）
                            cc_1(1, j) = pc_1(1, r);
                            cc_1(2, j) = pc_1(2, r);% 改变相应的医院 以原医院为准 以防出现非可行解
                            position = r + 1;
                            break;
                        end
                    end
                end
                if p2 < jobNumber% 如果第二个切割点的位置在最后一个基因之前，即双切点交叉
                    for j = p2 + 1:jobNumber% 同理填充第二个切割点后的未交叉段
                        for r = position:jobNumber
                            flag = true;
                            for l = 1:jobNumber
                                if pc_1(1, r) == cc_1(1, l)
                                    flag = false;
                                    break;
                                end
                            end
                            if flag
                                cc_1(1, j) = pc_1(1, r);
                                cc_1(2, j) = pc_1(2, r);
                                position = r + 1;
                                break;
                            end
                        end
                    end
                end
                
                %%以上得到子代一，子代二同理如下：
                position = 1;
                for j = 1:p1
                    for r = position:jobNumber
                        flag = true;
                        for l = 1:jobNumber
                            if pc_2(1, r) == cc_2(1, l)
                                flag = false;
                                break;
                            end
                        end
                        if flag
                            cc_2(1, j) = pc_2(1, r);
                            cc_2(2, j) = pc_2(2, r);
                            position = r + 1;
                            break;
                        end
                    end
                end
                if p2 < jobNumber
                    for j = p2 + 1:jobNumber
                        for r = position:jobNumber
                            flag = true;
                            for l = 1:jobNumber
                                if pc_2(1, r) == cc_2(1, l)
                                    flag = false;
                                    break;
                                end
                            end
                            if flag
                                cc_2(1, j) = pc_2(1, r);
                                cc_2(2, j) = pc_2(2, r);
                                position = r + 1;
                                break;
                            end
                        end
                    end
                end
            end
            
            child_1 = Individuality(cc_1);
            child_2 = Individuality(cc_2);
        end
        
        function ret = calculateFitness(obj)
            % calculateFitness 计算该个体的适应度值
            %   个体的适应度值取值为该个体表示的处理模型所消耗时间的倒数。
            obj = obj.calculateMakespan;
            ret = obj;
        end
        
        function ret = calculateMakespan(obj)
            % calculateMakespan 计算该个体表示的处理模型所消耗的时间
            %   1. 初始化每个工厂和机器
            %   2. 将每个工件按照基因顺序推入指定的工厂和机器中
            %   3. 重复 2 步骤直至所有工件都处理完毕，记下机器最后停止的时间，就是该个体表示的处理模型所消耗的时间
            
            sequence = obj.Chromosome.Sequence;
            
            jobFactory = ones(Const.V.JOB_NUMBER, 1);% n维列向量，长度为患者数量。标记患者到哪个医院就诊
            processMachine = ones(Const.V.JOB_NUMBER, 2);% 标记到第几号病床
            processStart = zeros(Const.V.JOB_NUMBER, 2);% n * 2 矩阵，n是患者数量。标记该患者两个过程的开始时间
            processStop = zeros(Const.V.JOB_NUMBER, 2);% n * 2 矩阵，n是患者数量。标记该患者两个过程的结束时间
            
            processStart(1, 1) = 0;
            processStop(1, 1) = Const.V.PROCESS_TIME(sequence(1, 1), 1);
            
            machineStop = cell(2, Const.V.FACTORY_NUMBER);% 2 * n 矩阵，2表示两个阶段，n是医院数量
            for i = 1:Const.V.FACTORY_NUMBER
                machineStop{1, i} = zeros(1, Const.V.FACTORY_MACHINE_NUMBER(i, 1));% 每个元素初始化为一个长度为n的行向量，n等于该医院用于该阶段的病床数量
                machineStop{2, i} = zeros(1, Const.V.FACTORY_MACHINE_NUMBER(i, 2));
            end     % 初始化病床
            
            for i = 1:Const.V.JOB_NUMBER
                possibleHospitalArray = Const.V.JOB_SPECIFIC_FACTORIES{sequence(1, i)};
                
                if ~isempty(possibleHospitalArray)                    
                    hospitalFlag = 0;
                    minStartTime = 0;
                    for j = 1:length(possibleHospitalArray)
                        nHospitalNumber = possibleHospitalArray(j);
                        if min(machineStop{1, nHospitalNumber}) + Const.V.PROCESS_TIME(sequence(1, i), 1) < min(machineStop{2, nHospitalNumber})
                            currentMinStartTime = min(machineStop{2, nHospitalNumber}) - Const.V.PROCESS_TIME(sequence(1, i), 1);
                        else
                            currentMinStartTime = min(machineStop{1, nHospitalNumber});
                        end
                        
                        if hospitalFlag == 0 || currentMinStartTime < minStartTime
                            hospitalFlag = nHospitalNumber;
                            minStartTime = currentMinStartTime;
                        end
                    end
                    
                    sequence(2, i) = hospitalFlag;
                end     % 如果该患者指定了特定的医院，则依照能最先进行治疗的医院调整
                
                jobFactory(i, 1) = sequence(2, i);   % 为该患者安排的医院编号
                [soonest1, soonestIndex1] = min(machineStop{1, sequence(2, i)});    % 该医院内第一阶段最早开始的时间和病床编号
                processMachine(i, 1) = soonestIndex1;
                processStart(i, 1) = soonest1;
                processStop(i, 1) = processStart(i, 1) + Const.V.PROCESS_TIME(sequence(1, i), 1);
                machineStop{1, sequence(2, i)}(1, soonestIndex1) = processStop(i, 1);
                %第一阶段分配完毕，PS：未考虑NO-WAIT%
                
                %考虑第二阶段nO-WAIT约束，对开工时间进行调整%
                [soonest2, soonestindex2] = min(machineStop{2, sequence(2, i)});
                processMachine(i, 2) = soonestindex2;
                if processStop(i, 1) < soonest2
                    processStop(i, 1) = soonest2;
                    processStart(i, 1) = processStop(i, 1) - Const.V.PROCESS_TIME(sequence(1, i), 1);
                    machineStop{1,sequence(2, i)}(1,soonestIndex1) = processStop(i, 1);
                    processStart(i, 2) = processStop(i, 1);
                    processStop(i, 2) = processStart(i, 2) + Const.V.PROCESS_TIME(sequence(1, i), 2);
                    machineStop{2, sequence(2, i)}(1, soonestindex2) = processStop(i, 2);
                else
                    processStart(i, 2) = processStop(i, 1);
                    processStop(i, 2) = processStart(i, 2) + Const.V.PROCESS_TIME(sequence(1, i), 2);
                    machineStop{2, sequence(2, i)}(1, soonestindex2) = processStop(i, 2);
                end
            end
            
            Cmax1 = max(cell2mat(machineStop(1, :)));
            Cmax2 = max(cell2mat(machineStop(2, :)));
            obj.MachineStop = machineStop;
            
            if Const.MAKESPAN_CALCULATION_TYPE == 1
                obj.Fitness = 10000 / max([Cmax1, Cmax2]);
            else 
               obj.Fitness = 10000 / obj.calculateMakespanByMachineStop(machineStop);
            end
            
            ret = obj;
        end
        
        function ret = learning(obj, SD, RD, p1, p2)
            sequence = obj.Chromosome.Sequence;
            for j = 1:Const.V.JOB_NUMBER
                r = rand;% 生成学习随机数
                if r <= p1% 如果小于p1，则不变
                    continue;
                elseif r <= p2% 如果在p1和p2之间，则向社会学习对象学习
                    gene = SD(:, j);
                    occurredGene = sequence(:, 1:j - 1);
                    if ismember(gene(1), occurredGene)
                        sequence(:, j) = [0; -1];% 从SD学习标记为-1
                    else
                        sequence(:, j) = gene;
                    end
                else
                    gene = SD(:, j);
                    occurredGene = sequence(:, 1:j - 1);
                    if ismember(gene(1), occurredGene)
                        sequence(:, j) = [0; -2];% 从RD学习标记为-2
                    else
                        sequence(:, j) = gene;
                    end
                end
            end

            firstRow = sequence(1, :);

            % 将第一行重复的位，以及标记为special的位置0
            [~, index, ~] = unique(firstRow, 'stable');
            temp = firstRow;
            temp(index) = 0;% 不重复的位置0，剩下的就是重复位
            firstRow(temp > 0 | firstRow == Const.V.JOB_NUMBER + 1) = 0;
            
            % 将所有标记为0的填入数字
            have = firstRow(firstRow > 0);
            lost = setdiff(1:Const.V.JOB_NUMBER, have);
            firstRow(firstRow == 0) = lost;
            
            sequence(1, :) = firstRow;
            
            for i = 1:Const.V.JOB_NUMBER
                if sequence(2, i) == -1
                    pos = SD(1, :) == sequence(1, i);
                    sequence(2, i) = SD(2, pos);
                elseif sequence(2, i) == -2
                    pos = SD(1, :) == sequence(1, i);
                    sequence(2, i) = RD(2, pos);
                end
            end
            
            temp = Individuality(sequence);
            
            if temp.Fitness > obj.Fitness
                ret = temp;
            else
                ret = obj;
            end
        end
    end
    
    methods(Access = protected)
        function ret = calculateMakespanByMachineStop(~, ms)
            ret = 0;
            a = Const.MAKESPAN_FACTOR_ALPHA;
            b = Const.MAKESPAN_FACTOR_BETA;
            w = Const.MAKESPAN_FACTOR_WORKTIME;
            
            for i = 1:length(ms)% 遍历所有工厂
                p1 = ms{1, i};
                p2 = ms{2, i};
                for j = 1:length(ms{1, i})% 遍历工厂中的所有手术台
                    if p1(j) >= Const.MAKESPAN_FACTOR_WORKTIME
                        ret = ret + (p1(j) - w) * a + w;% 超出的工作时间，超出部分要乘以系数
                    else
                        ret = ret + p1(j);
                    end
                end% 计算手术室的makespan
                
                ret = ret + max(p2) * b * length(p2);% 计算恢复室的makespan
            end
        end
    end
end

