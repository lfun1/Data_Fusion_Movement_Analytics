X1 = load('mobility_data_tensor_matrix.mat');

T1 = X1.tensor; % 7660 x 131 x 10 double
M1 = X1.matrix; % 7660 x 2 int64

T1_tensor = tensor(T1);
M1_tensor = tensor(M1);

export_data(T1_tensor, 'T1_mobility.tensor')
export_data(M1_tensor, 'M1_mobility.tensor')

T = import_data('T1_mobility.tensor');
M = import_data('M1_mobility.tensor');

modes = {[1 2 3], [1 4]};
sz = [T.size(1) T.size(2) T.size(3) M.size(2)];
X_tensor{1, 1} = T;
X_tensor{2, 1} = M;

%% Creating Z struct for cmtf_opt
P = 2;
for p=1:P
    Z.object{p} = X_tensor{p};
    Z.object{p} = Z.object{p}/norm(Z.object{p});    
end
Z.modes = modes;
Z.size = sz;

%% Run cmtf_opt on tensor/matrix for mobility data analysis

init = 'random';
options = ncg('defaults');
options.Display ='final';
options.MaxFuncEvals = 1e3;
options.MaxIters     = 500;
options.StopTol      = 1e-8;
options.RelFuncTol   = 1e-8;
R = 4;

[FacMat, G, out] = cmtf_opt(Z,R,'init',init,'alg_options',options);

%% Save factor matrices
fmat1 = FacMat{1};
fmat2 = FacMat{2};
fmat3 = FacMat{3};
fmat4 = FacMat{4};
lambda = FacMat.lambda;

save('Matlab_lambda.mat', 'lambda')
save('Matlab_fmat1.mat', 'fmat1')
save('Matlab_fmat2.mat', 'fmat2')
save('Matlab_fmat3.mat', 'fmat3')
save('Matlab_fmat4.mat', 'fmat4')

