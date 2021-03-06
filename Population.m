classdef Population
    % POPULATION  种群模型
    %   种群模型，包含个体的数组与其相应的适应度数组
    %
    %   See also Individuality, Const
    
    properties
        Size;% 种群大小
        Individualities;% 种群中个体的数组
        Fitness;% 种群的适应度数组
    end
    
    methods
        function obj = Population(initiate)
            % Population 初始化过程
            % 1. 创建每个个体
            % 2. 将其适应度存入适应度数组
            
            obj.Size = Const.F.POPULATION_SIZE;
            obj.Individualities = cell(1, obj.Size);
            obj.Fitness = zeros(1, obj.Size);
            
            if initiate
                for i = 1:obj.Size
                    individuality = Individuality(false);
                    obj.Individualities{i} = individuality;
                    obj.Fitness(1, i) = individuality.Fitness;
                end
            end
        end
        
        function ret = bestIndividuality(obj)
            [~, b] = max(obj.Fitness);
            ret = obj.Individualities{b};
        end
        
        function obj = selection(obj)
            % selection  选择过程
            % 1. 计算Fitness数组累积和，归一化至（0，1）
            % 2. 轮盘赌法进行选择
            
            oldIndividualities = obj.Individualities;
            oldFitness = obj.Fitness;
            
            q = mapminmax(cumsum(oldFitness), 0, 1);% 归一化
            
            for i = 1:Const.F.POPULATION_SIZE
                selected = find(q >= rand);
                obj.Individualities{1, i} = oldIndividualities{selected(1)};
                obj.Fitness(1, i) = oldFitness(selected(1));
            end % 轮盘赌法选择个体
        end
        
        function obj = crossover(obj)
            % crossover 交叉过程
                       
            for i=1:2:(Const.F.POPULATION_SIZE - 1)
                parent_1 = obj.Individualities{i};
                parent_2 = obj.Individualities{1 + 1};
                [child_1, child_2] = parent_1.crossoverWith(parent_2);
                
                obj.Individualities{i} = child_1;
                obj.Individualities{i + 1} = child_2;
                obj.Fitness(i) = child_1.Fitness;
                obj.Fitness(i + 1) = child_2.Fitness;
            end
        end
        
        function obj = mutation(obj)
            % mutation 变异过程
            
            for i=1:Const.F.POPULATION_SIZE
                if rand < Const.F.MUTATION_PROBABILITY
                    obj.Individualities{i} = obj.Individualities{i}.mutation;
                    obj.Fitness(i) = obj.Individualities{i}.Fitness;
                end
            end
        end
        
        function obj = learning(obj, p1, p2)
            % learning 学习过程
            
            SDI = obj.getSocialDataset().getStatisticallyBestIndividuality();
            RDI = obj.getRandomDataset().getStatisticallyBestIndividuality();
            
            for i = 1:Const.F.POPULATION_SIZE
                obj.Individualities{i} = obj.Individualities{i}.learning(SDI.Chromosome.Sequence, RDI.Chromosome.Sequence, p1, p2);
                obj.Fitness(i) = obj.Individualities{i}.Fitness;
            end
        end
    end
    
    methods(Access = protected)
        function ret = getSocialDataset(obj)
            % getSocialDataset 获取社会学习对象SD
            %   该函数返回一个新的种群，是依照当前种群构建的社会学习对象
            %   返回的社会学习对象是已排好序的数组，并且取适应度前50%复制一次
            
            ret = obj;
            [~, index] = sort(ret.Fitness, 'descend');
            ret.Individualities = ret.Individualities(index);
            ret.Fitness = ret.Fitness(index);
            
            halfChromosome = ret.Individualities(:, 1:Const.F.POPULATION_SIZE / 2);
            halfFitness = ret.Fitness(:, 1:Const.F.POPULATION_SIZE / 2);
            ret.Individualities = [halfChromosome, halfChromosome];
            ret.Fitness = [halfFitness, halfFitness];
        end
        
        function ret = getRandomDataset(~)
            % getRandomDataset 获取随机学习对象RD
            %   该函数返回一个新的，随机生成的种群，并且按照适应度大小排序
            
            ret = Population(true);
            [~, index] = sort(ret.Fitness, 'descend');
            ret.Individualities = ret.Individualities(index);
            ret.Fitness = ret.Fitness(index);
        end
        
        function ret = getPopulationalGeneMatrix(obj)
            % getPopulationalGeneMatrix 获取种群的基因矩阵
            %   该函数返回一个种群的基因矩阵，包含种群所有个体的基因
            
            ret = zeros(2, Const.F.POPULATION_SIZE * Const.V.JOB_NUMBER);
            for i = 1:Const.F.POPULATION_SIZE
                start = (i - 1) * Const.V.JOB_NUMBER + 1;
                finish = i * Const.V.JOB_NUMBER;
                ret(:, start:finish) = obj.Individualities{i}.Chromosome.Sequence;
            end
        end
        
        function ret =  getStatisticallyBestIndividuality(obj)
            sequence = zeros(2, Const.V.JOB_NUMBER);
            mat = obj.getPopulationalGeneMatrix();
            
            for j = 1:Const.V.JOB_NUMBER
                geneCurrentLocation = mat(:, j:20:end);
                occurredGene = sequence(:, 1:j-1);
                e = histcounts(geneCurrentLocation(1, :), 1:Const.V.JOB_NUMBER + 1);
                e(occurredGene(1, :)) = 0;
                [g, f] = max(e);
                if g == 0
                    f = Const.V.JOB_NUMBER + 1;
                end
                sequence(1, j) = f;
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
            
            sequence(1, :) = firstRow;% 第一行完毕，下面处理第二行
            
            for j = 1:Const.V.JOB_NUMBER
                filter = mat(1, :) == sequence(1, j);% 找到对于该患者最多出现的医院，filter是逻辑数组
                hospitals = mat(2, filter);
                e = histcounts(hospitals, 1:Const.V.FACTORY_NUMBER + 1);
                [~, f] = max(e);
                sequence(2, j) = f;
            end
            
            ret = Individuality(sequence);            
        end
    end
end