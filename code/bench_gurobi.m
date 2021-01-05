% Skripta za primerjavo Gurobi in intlinprog hitrost resevanja
% Uporablja testne podatke iz MIPLIB2017 (http://miplib.zib.de/)
%
% @author David Rubin (david.rubin@student.um.si)
% Optimizacijske metode, FERI, Maribor, 2020
N = 3;              % faktor ponovitev merjenja za vsak primer
TIMEOUT = 1800;     % cas preden obupamo nad iskanjem resitve (30min)

%% Pripravi testne primere
% URL za prenos posameznega primera - osnova
miplib_base = 'http://miplib.zib.de/WebData/instances/';
% Mapa kamor se shranijo testni primeri
data_dir = 'benchmark_data/';
if ~exist(data_dir, 'dir')
    mkdir(data_dir)
end
% Imena primerov so znotraj tekstovne datoteke in vsebujejo koncnice .mps.gz (!)
mps_problem_list = 'mps-problems.txt';
if ~exist(mps_problem_list, 'file')
    error('Napaka! Datoteka z imeni problemov "%s" ne obstaja', mps_problem_list);
end
mps_problems = readlines(mps_problem_list).transpose;
% Polne poti do datotek
mps_paths = strings( mps_problems.length, 1);
disp(mps_problems.length);

% Prenesi samo posamezne probleme (celoten Benchmark set je 300MB+)
for i = 1:mps_problems.length
    problem = mps_problems(i);
    fprintf('Downloading %s ...', problem);
    % Shrani v datoteko
    file_path = websave(sprintf('%s%s', data_dir, problem), sprintf('%s%s', miplib_base, problem));
    fprintf(' done.\n Extracting & cleanup ...');
    % Ekstrahiraj arhiv in ga zbrisi (ostanejo samo .mps datoteke)
    gunzip(file_path);
    delete(file_path);
    fprintf(' done.\n');
    mps_paths(i) = file_path(1:end-3); % Odstrani '.gz' iz imena
end

%% Izmeri cas resevanja problemov pri MATLAB: intlinprog
% Ustvari .csv datoteko s petimi stolpci:
%  mps  ... ime problema ki ga resujemo
%  run  ... zaporedna stevilka zagona (ponavljamo meritve)
%  time ... pretekli cas v sekundah za najdeno resitev 
%  fail ... ali program ni uspel najti resitve v dolocenem casu (1/0)
%  threads ... stevilo uporabljenih jeder (pri intlingprog vedno 1, gre se za skladnost z Gurobi rezultati)
results_dir = 'runtimes/';
if ~exist('mps_paths', 'var') || mps_paths.length == 0
    error('Napaka! Nimam problemov, a ste pognali sekcijo "Pripravi testne primere"?');
end
if ~exist('N', 'var') || ~exist('TIMEOUT', 'var')
    error('Napaka! Konstante ne obstajajo, ste pognali sekcijo v glavi datoteke?');
end
% Ustvari mapo za rezultate
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end
% Ustvari datoteko z rezultati
fOut = fopen(strcat(results_dir, 'matlab.csv'), 'wt');
fprintf(fOut, 'mps,run,time,fail,threads\n');
% Ponovi meritve N-krat
for i = 1:mps_paths.length
    mps_name = mps_problems(i).split('.'); % Vzemi ime brez koncnice
    % Preberi problem in nastavi custom timeout (default = 2h)
    problem = mpsread(mps_paths(i));
    problem.options.MaxTime = TIMEOUT;
    % Meri cas resevanja
    for n = 1:N
        fprintf('Resujem: %s (%d/%d\n)', mps_name(1), n, N);
        tStart = tic;
         [x,fval,exitflag,output] = intlinprog(problem);
        tDuration = toc(tStart);
        stopped = 0;
        if exitflag == 0 || exitflag == 2
            % Solver stopped prematurely - verjetno zaradi timeout
            stopped = 1;
        end
        % Zapisi cas trajanja v novo vrstico
        fprintf(fOut, '%s,%d,%.4f,%d, 1\n', mps_name(1), n, tDuration, stopped);  
    end
end
fclose(fOut);

%% Izmeri cas resevanja v Gurobi
% Ustvari .csv datoteko s petimi stolpci:
%  mps  ... ime problema ki ga resujemo
%  run  ... zaporedna stevilka zagona (ponavljamo meritve)
%  time ... pretekli cas v sekundah za najdeno resitev 
%  fail ... ali program ni uspel najti resitve v dolocenem casu (1/0)
%  threads ... stevilo uporabljenih jeder
results_dir = 'runtimes/';
if ~exist('mps_paths', 'var') || mps_paths.length == 0
    error('Napaka! Nimam problemov, a ste pognali sekcijo "Pripravi testne primere"?');
end
if ~exist('N', 'var') || ~exist('TIMEOUT', 'var')
    error('Napaka! Konstante ne obstajajo, ste pognali sekcijo v glavi datoteke?');
end
if ~exist('gurobi_read', 'file') || ~exist('gurobi', 'file') % Ukaz vraca 3 -> MEX-file on your MATLAB search path
    error('Napaka! Gurobi ukazi ne obstajajo, ste pognali gurobi_setup?')
end
% Ustvari mapo za rezultate
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end
% Ustvari datoteko z rezultati
fOut = fopen(strcat(results_dir, 'gurobi.csv'), 'wt');
fprintf(fOut, 'mps,run,time,fail,threads\n');
% Ponovi meritve N-krat
for i = 1:mps_paths.length
    mps_name = mps_problems(i).split('.'); % Vzemi ime brez koncnice
    % Preberi problem in nastavi custom time limit (default = inf)
    model = gurobi_read(convertStringsToChars(mps_paths(i))); % gurobi_read hoce char array kot parameter
    params.TimeLimit = TIMEOUT;
    for t = [1, 2, 4, 8]  % Predvidevamo, da je procesor zmozen uporabiti 8 niti
        params.Threads = t; % Stevilo niti, ki se naj uporabijo
        for n = 1:N
            % Gurobi v result.runtime shrani cas resevanja
            result = gurobi(model, params); % Pozeni optimizacijo
            stopped = 0;
            % Izhodni status pove zakaj se je optimizacija ustavila ('OPTIMAL', 'INFEASIBLE', 'ITERATION_LIMIT etc.)
            if strcmp(result.status, 'TIME_LIMIT')  
                stopped = 1;
            end
            disp(result);
            % Zapisi cas trajanja v novo vrstico
            fprintf(fOut, '%s,%d,%.4f,%d,%d\n', mps_name(1), n, result.runtime, stopped, params.Threads);
            break
        end
        break
    end
    break
end

