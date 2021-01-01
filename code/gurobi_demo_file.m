function gurobi_demo_file()
    % Prebere problem iz LP datoteke in ga resi
    model = gurobi_read('coins.lp'); % Deluje tudi s *.mps
    params.outputflag = 0; % Prepreci izpis med optimizacijo
    
    result = gurobi(model, params); % Pozeni optimizacijo
    % Izpisi rezultate
    disp(result)
    fprintf('Resitev: %e\n', result.objval);
    for v=1:length(result.x)
        fprintf('%s = %d\n',model.varnames{v}, result.x(v));
    end
end