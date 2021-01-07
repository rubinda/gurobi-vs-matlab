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
        fprintf(fOut, '%s,%d,%.4f,%d,1\n', mps_name(1), n, tDuration, stopped);  
        if stopped == 1
            break; % Preskoci ponovno klicanje funkcij, ki so bile ustavljene (mala verjetnost da bojo naslednjih zakljucile v casu)
        end
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
        end
    end
end

%% Poracunaj rezultate za Gurobi in MATLAB (pricakuje datoteko z rezultati)
% V kolikor ste poganjali zgornje primere so se vam datoteke prepisale,
% uporabite lahko kopijo iz github repozozitorija.

% Odkomentiraj to kodo v primeru, da nimas rezultatov:
% websave('runtimes/matlab.web.csv', 'https://raw.githubusercontent.com/rubinda/gurobi-vs-matlab/main/code/runtimes/matlab.csv');
% websave('runtimes/gurobi.web.csv', 'https://raw.githubusercontent.com/rubinda/gurobi-vs-matlab/main/code/runtimes/gurobi.csv');

if ~exist('runtimes/gurobi.csv', 'file') || ~exist('runtimes/gurobi.csv', 'file')
    error('Datoteki z rezultati ne obstajata, odkomentiraj kodo za prenos iz Github');
end

gurobi_results = readtable('runtimes/gurobi.csv');
matlab_results = readtable('runtimes/matlab.csv');

bar_data = [];
problems = transpose(unique(gurobi_results.mps));
% Imena problemov so v obeh ista -> prva zanka tece cez obe
for name = problems
    mps_runtimes = [];
    for t = transpose(unique(gurobi_results.threads))
        % Zdruzi vrstice za podan problem v stolpce (MATLAB ima podatke
        % samo za thread=1, zato ga preskoci ce so prazne vrstice
        if (t == 1)
            ml_rows = strcmp(matlab_results.mps, name) & matlab_results.threads == t;
            ml_mps_records = matlab_results(ml_rows,:);
            
            mps_runtimes = [mps_runtimes, mean(ml_mps_records.time)];
            % TODO: dodaj vrstico z tekst (if fail dodaj fail)
        end
        % Vedno dodaj zapis za Gurobi
        gr_rows = strcmp(gurobi_results.mps, name) & gurobi_results.threads == t;
        gr_mps_records = gurobi_results(gr_rows,:);
        
        mps_runtimes = [mps_runtimes, mean(gr_mps_records.time)];
    end
    bar_data = [mps_runtimes; bar_data];
end
% Izrise bar plot
x = categorical(flip(problems));
h = bar(x, bar_data);
set(h, {'DisplayName'}, {'MATLAB', 'Gurobi, T=1', 'Gurobi, T=2', 'Gurobi, T=4', 'Gurobi, T=8'}');
l = legend();
set(l,'FontSize',14);
set(gcf,'position',[100,100,1024,768]);
xlabel('Ime problema', 'FontSize', 18);
ylabel('Čas v sekundah', 'FontSize', 18);

% Izpisi pohitritve za posamezne primere
i = 1; % Prikaz problemov
p = flip(problems'); % Seznam imen problemov je treba obrniti za pravilen vrstni red (zgoraj appendamo vrednosti)
speedups1_2 = [];   % Pohitritve Gurobi za 1->2 niti
speedups2_4 = [];   % Pohitritve Gurobi za 2->4 niti
speedups4_8 = [];   % Pohitritve Gurobi za 4->8 niti
speedups1_4 = [];   % Pohitritve Gurobi za 1->4 niti
speedups1_8 = [];   % Pohitritve Gurobi za 1->8 niti
speedups2_8 = [];   % Pohitritve Gurobi za 2->8 niti
speedupsM_1 = [];   % Pohitritve Matlab-> Gurobi z 1 nit
speedupsM_2 = [];   % Pohitritve Matlab-> Gurobi z 2 nitma
speedupsM_4 = [];   % Pohitritve Matlab-> Gurobi s 4 niti
speedupsM_8 = [];   % Pohitritve Matlab-> Gurobi z 8 niti
fprintf('\n---- SPREMEBE PRI POSAMEZNIH PROBLEMAH -----\n');
for avg_times = bar_data'
    p_name = p(i);
    % Povprecni casi resevanja za vsak problem (baseline = MATLAB)
    baseline = avg_times(1);
    gurobi1 = avg_times(2);
    gurobi2 = avg_times(3);
    gurobi4 = avg_times(4);
    gurobi8 = avg_times(5);
    % Pohitritev racunamo po principu speedup = (new-old)/old * 100%
    speedup1_2 = (gurobi2 - gurobi1) / gurobi1 * 100;
    speedups1_2 = [speedups1_2; speedup1_2];
    speedup2_4 = (gurobi4 - gurobi2) / gurobi2 * 100;
    speedups2_4 = [speedups2_4; speedup2_4];
    speedup4_8 = (gurobi8 - gurobi4) / gurobi4 * 100;
    speedups4_8 = [speedups4_8; speedup4_8];
    speedup1_4 = (gurobi4 - gurobi1) / gurobi1 * 100;
    speedups1_4 = [speedups1_4; speedup1_4];
    speedup1_8 = (gurobi8 - gurobi1) / gurobi1 * 100;
    speedups1_8 = [speedups1_8; speedup1_8];
    speedup2_8 = (gurobi8 - gurobi2) / gurobi2 * 100;
    speedups2_8 = [speedups2_8; speedup2_8];
    speedupM_1 = (gurobi1 - baseline) / baseline * 100;
    speedupsM_1 = [speedupsM_1; speedupM_1];
    speedupM_2 = (gurobi2 - baseline) / baseline * 100;
    speedupsM_2 = [speedupsM_2; speedupM_2];
    speedupM_4 = (gurobi4 - baseline) / baseline * 100;
    speedupsM_4 = [speedupsM_4; speedupM_4];
    speedupM_8 = (gurobi8 - baseline) / baseline * 100;
    speedupsM_8 = [speedupsM_8; speedupM_8];
    % Lepsi prikaz, kadar je sprememba upocasnitev (doda +)
    if speedup1_2 > 0 sign2 = '+'; else sign2 = ''; end
    if speedup2_4 > 0 sign4 = '+'; else sign4 = ''; end
    if speedup4_8 > 0 sign8 = '+'; else sign8 = ''; end
    if speedupM_1 > 0 signM1 = '+'; else signM1 = ''; end
    if speedupM_2 > 0 signM2 = '+'; else signM2 = ''; end
    if speedupM_4 > 0 signM4 = '+'; else signM4 = ''; end
    if speedupM_8 > 0 signM8 = '+'; else signM8 = ''; end
    
    fprintf('Problem: "%s"\n', p_name{1});
    fprintf('  MATLAB (M):\t %.2fs\n', baseline);
    fprintf('  Gurobi (t=1):\t %.2fs\t\t(=> MATLAB %s%.2f%%)\n', avg_times(2), signM1, speedupM_1);
    fprintf('  Gurobi (t=2):\t %.2fs (%s%.2f%%)   (=> MATLAB %s%.2f%%)\n', avg_times(3), sign2, speedup1_2, signM2, speedupM_2);
    fprintf('  Gurobi (t=4):\t %.2fs (%s%.2f%%)   (=> MATLAB %s%.2f%%)\n', avg_times(4), sign4, speedup2_4, signM4, speedupM_4);
    fprintf('  Gurobi (t=8):\t %.2fs (%s%.2f%%)   (=> MATLAB %s%.2f%%)\n\n', avg_times(5), sign8, speedup4_8, signM8, speedupM_8);
    
    i = i+1;
end
fprintf('\n---- POVPRECNI CASI -----\n');
fprintf('Povprecna pohitritve/upocasnitve pri spremembi stevila niti:\n');
fprintf('  Gurobi 1->2 niti: %.2f%%\n', mean(speedups1_2));
fprintf('  Gurobi 2->4 niti: %.2f%%\n', mean(speedups2_4));
fprintf('  Gurobi 4->8 niti: %.2f%%\n', mean(speedups4_8));
fprintf('  Gurobi 1->4 niti: %.2f%%\n', mean(speedups1_4));
fprintf('  Gurobi 1->8 niti: %.2f%%\n', mean(speedups1_8));
fprintf('  Gurobi 2->8 niti: %.2f%%\n', mean(speedups2_8));

fprintf('  MATLAB ->Gurobi 1 nit: %.2f%%\n', mean(speedupsM_1));
fprintf('  MATLAB ->Gurobi 2 niti: %.2f%%\n', mean(speedupsM_2));
fprintf('  MATLAB ->Gurobi 4 niti: %.2f%%\n', mean(speedupsM_4));
fprintf('  MATLAB ->Gurobi 8 niti: %.2f%%\n', mean(speedupsM_8));
