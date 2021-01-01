function gurobi_demo()
    % Povzeto po Gurobi Quickstart vodicu
    names = {'x'; 'y'; 'z'}; % Imena spremenljivk
    model.A = sparse([1 2 3; 1 1 0]); % Redka matrika A
    model.obj = [1 1 2]; % Cenitvena funkcija
    model.rhs = [4; 1]; % b (Right-hand side)
    model.vtype = 'B'; % tip spremenljivk (B - binarne)
    model.modelsense = 'max'; % maksimiziraj
    model.varnames = names;
    
    gurobi_write(model, 'gurobi_demo.lp'); % Zapisi problem v LP
    params.outputflag = 0; % Prepreci Gurobi izpis med optimizacijo
    
    result = gurobi(model, params); % Pozeni optimizacijo
    % Izpisi resitve
    disp(result);
    for v=1:length(names)
        fprintf('%s %d\n', names{v}, result.x(v));
    end
    fprintf('Resitev: %e\n', result.objval);
end