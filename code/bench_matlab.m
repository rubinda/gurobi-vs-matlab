% Skripta, ki resi probleme napisane v 'mps-problems.txt' s pomocjo
% intlinprog. Pricakuje, da se podatki nahajajo v '../benchmark-data/
% (torej pwd = 'code')
data_dir = '../benchmark_data/';
log_dir = '../benchmark_times/';
problems = 'mps-problems.txt';

% Pripravi csv za shranjevanje runtimes
mkdir(log_dir);
fOut = fopen(strcat(log_dir, 'matlab.csv'), 'wt');
fprintf(fOut, 'mps,run,time\n');

% Odpri datoteko
fid = fopen(problems);
mps_file = fgetl(fid);
% Preberi vsako vrstico -> data_dir + vrstica => pot do problema
while ischar(mps_file)
    fprintf('Resujem "%s"\n', mps_file)
    problem_path = strcat(data_dir, mps_file);
    problem = gunzip(problem_path);
    mps_problem = mpsread(problem{1});
    % Gurobi uporablja 1e-4 za toleranco (MATLAB default = 1e-5)
    mps_problem.options.IntegerTolerance = 1e-4;
    mps_problem.options.Display = 'final';
    tStart = tic;
         [x,fval,exitflag,output] = intlinprog(mps_problem);
    tEnd = toc(tStart);
    
    % Zapisi cas trajanja
    fprintf(fOut, '%s,%d,%.4f\n', mps_file, 1, tEnd); 
    
    % Preberi naslednjo datoteko
    mps_file = fgetl(fid);
end
fclose(fid);
fclose(fOut);