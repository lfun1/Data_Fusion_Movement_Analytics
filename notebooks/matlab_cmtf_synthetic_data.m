%% Measuring speed and accuracy of MATLAB's CMTF Toolbox on Synthetic Data
% Requires CMTF Toolbox, Tensor Toolbox, Poblano Toolbox, Tensorlab

% Rank and size
rankArr = [3:10];
numR = 8;
sizeI = [10 25 50 75];
itr = 5;

for idx = 1:length(sizeI)
    szI = sizeI(idx);

    % Store 4 measurements
    wallTimeArr = zeros(numR, itr+1);
    cpuTimeArr = zeros(numR, itr+1);
    TreconErrorArr = zeros(numR, itr+1);
    MreconErrorArr = zeros(numR, itr+1);

    for r = rankArr

        for i = 1:itr      
            %% Parameters (one tensor, one matrix)
            lambdas     = {[1 1 1], [1 1 1]};
            modes       = {[1 2 3], [1 4]};
            sz          = [szI szI szI szI];
            init        = 'random';
            flag_sparse = [0 0];
        
            %% Check parameters
            if length(lambdas)~=length(modes)
                error('There should be weights for each data set');
            end
            P = length(modes);
            for p=1:P
                l(p) = length(lambdas{p});
            end
            if length(unique(l))>1
                error('There should be the same number of weights for each data set');
            end
            if length(flag_sparse)<p
               error('flag_sparse should be specified for each data set');
            end
            
            %% Form coupled data
            if any(flag_sparse)
                % construct sparse data sets in the dense or sptensor format based on flag_sparse
                [Xcont{i}, Atrue] = create_coupled_sparse('size',sz,'modes',modes,'lambdas',lambdas,'flag_sparse',flag_sparse);
            else
                % construct data sets in the dense format
                [Xcont{i}, Atrue] = create_coupled('size', sz, 'modes', modes, 'lambdas', lambdas);
            end
            
            for p=1:2
                Z.object{p} = Xcont{i}{p};
                Z.object{p} = Z.object{p}/norm(Z.object{p});    
            end
        
            Z.modes = modes;
            Z.size  = sz;
        
            %% Fit CMTF using one of the first-order optimization algorithms 
            options = ncg('defaults');
            options.Display ='final';
            options.MaxFuncEvals = 100;
            options.MaxIters     = 100;
            options.StopTol      = 1e-8;
            options.RelFuncTol   = 1e-8;
        
            %% CMTF and Timing
            cStart = cputime; % CPU time
            wStart = tic; % Wall time
            [Fac,G,out] = cmtf_opt(Z,r,'init',init,'alg_options',options); 
            wEnd = toc(wStart); % Wall time = wEnd
            cEnd = cputime - cStart; % CPU time = cEnd
        
            %% Reconstruction error
            % tensor
            origT = Xcont{i}{1};
            reconT = cpdgen({Fac{1}, Fac{2}, Fac{3}});
            diffT = origT - reconT;
            reconErrorT = norm(diffT);
            
            % matrix
            origM = Xcont{i}{2};
            reconM = cpdgen({Fac{1}, Fac{4}});
            diffM = origM - reconM;
            reconErrorM = norm(diffM);
        
            %% Store measurements
            wallTimeArr(r-2, i) = wEnd;
            cpuTimeArr(r-2, i) = cEnd;
            TreconErrorArr(r-2, i) = reconErrorT;
            MreconErrorArr(r-2, i) = reconErrorM;
        
            TcontArrI{i} = double(Xcont{i}{1});
            McontArrI{i} = double(Xcont{i}{2});
        
        end
        
        wallTimeArr(r-2, itr+1) = mean(wallTimeArr(r-2,:));
        cpuTimeArr(r-2, itr+1) = mean(cpuTimeArr(r-2,:));
        TreconErrorArr(r-2, itr+1) = mean(TreconErrorArr(r-2,:));
        MreconErrorArr(r-2, itr+1) = mean(MreconErrorArr(r-2,:));
        
        TcontArrR{r-2} = TcontArrI;
        McontArrR{r-2} = McontArrI;

    end

    % Store 4 measurements and tensor/matrix
    wallTime{idx} = wallTimeArr;
    cpuTime{idx} = cpuTimeArr;
    Trecon{idx} = TreconErrorArr;
    Mrecon{idx} = MreconErrorArr;
    Tcont{idx} = TcontArrR;
    Mcont{idx} = McontArrR;
    
end

%% Saving rank, 4 measurements, tensor/matrix

save('MAT_ranks', 'rankArr')
save('MAT_wallTime', 'wallTime')
save('MAT_cpuTime', 'cpuTime')
save('MAT_Trecon', 'Trecon')
save('MAT_Mrecon', 'Mrecon')

save('MAT_Tcont', 'Tcont')
save('MAT_Mcont', 'Mcont')