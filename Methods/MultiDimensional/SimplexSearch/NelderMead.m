function [ fmin, xmin, it, cpuTime, evalNumbers, valuesPerIter ] = NelderMead( functionName, methodParams )
  
    % paper: https://www.researchgate.net/publication/225691623_Implementing_the_Nelder-Mead_simplex_algorithm_with_adaptive_parameters
    % poor performance for high-dimensional problems
    % eg. works for QuadQF2 n=5,10; but inexact for n=50,100 (yet close to xmin)
    
    % hyperparams (not available thorugh the GUI)
    alpha = 1;
    beta = 2;
    gamma = 0.9;
    delta = 0.9;
    
    evalNumbers = EvaluationNumbers(0,0,0);
    n = methodParams.variables_no;
    maxIter = methodParams.max_iteration_no;
    valuesPerIter = PerIteration(maxIter);
    
    %epsilon = methodParams.epsilon; % whichever of these two
    workPrec = methodParams.workPrec;
    
    xmin = methodParams.starting_point;
   
    it = 1;  
    tic; 

    % compute values for first iteration
    % construct n+1 simplex points, 1st method in comments
    
    %simplex_start = [n*eye(n);~~(1:n)+(n+1)^.5];
    %t_old = mean(simplex_start);
    %simplex_new = simplex_start - repelem(t_old, n+1, 1) + repelem(xmin, n+1, 1);
    
    % another way of building initial simplex
    simplex_new = repelem(xmin, n+1, 1) + [zeros(n, 1)'; ones(n)*0.5 + eye(n)];
    
    % initial setup
    fCurr = feval(functionName, xmin, [1 0 0]);           
    evalNumbers.incrementBy([1 0 0]); 
    valuesPerIter.setFunctionVal(it, fCurr);
    it = it + 1;
        
    fPrev = fCurr + 100; % so it enters the first loop iteration
    diff = abs(fCurr - fPrev);
    r = zeros(n+1, 1); % vector of n+1 f-values 
    
    while (it <= maxIter && diff > workPrec) % viable termination conditions   
        fPrev = fCurr;

        % sort
        for i = 1:(n+1)
            ev = feval(functionName, simplex_new(i, :), [1 0 0]);
            r(i) = ev;
        end % do this in parallel if possible, forced reuse of feval
        evalNumbers.incrementBy([n+1 0 0]); 
   
        [val, idx] = sort(r);
        n_best = simplex_new(idx(1:end-1), :); % minimal n out of n+1
        x_bar = mean(n_best);

        fCurr = feval(functionName, x_bar, [1 0 0]);
        xmin = x_bar; % these are chosen as iteration mins
        
        % reflection
        x_r = x_bar + alpha*(x_bar - simplex_new(idx(end), :));
        f_r = feval(functionName, x_r, [1 0 0]);
        evalNumbers.incrementBy([1 0 0]);

        if (val(1) <= f_r) && (f_r < val(n))
            simplex_new(idx(end), :) = x_r;
        end
        
        % expansion
        if (f_r < val(1))
            x_e = x_bar + beta*(x_r - x_bar);
            f_e = feval(functionName, x_e, [1 0 0]);
            evalNumbers.incrementBy([1 0 0]);

            if (f_e < f_r)
                simplex_new(idx(end), :) = x_e;
            else
                simplex_new(idx(end), :) = x_r;
            end
        end

        % outside contraction
        dont_skip = true;
        if (val(n) <= f_r) && (f_r < val(n+1))
            x_oc = x_bar + gamma*(x_r - x_bar);
            f_oc = feval(functionName, x_oc, [1 0 0]);
            evalNumbers.incrementBy([1 0 0]);

            if (f_oc <= f_r)
                simplex_new(idx(end), :) = x_oc;
            else
                dont_skip = false;
            end
        end

        % inside contraction
        if (f_r >= val(n+1)) && dont_skip
            x_ic = x_bar - gamma*(x_r - x_bar);
            f_ic = feval(functionName, x_ic, [1 0 0]);
            evalNumbers.incrementBy([1 0 0]);

            if (f_ic < val(n+1))
                simplex_new(idx(end), :) = x_ic;
            end    
        end

        % shrink
        for i = 2:(n+1)
            simplex_new(idx(i), :) = simplex_new(idx(1), :) ... 
                + delta*(simplex_new(idx(i), :) - simplex_new(idx(1), :));
        end
        
        diff = abs(fCurr - fPrev);
        valuesPerIter.setFunctionVal(it, fCurr);
        it = it + 1;
    end
    
    cpuTime = toc;
    it = it - 1;
    valuesPerIter.trim(it);
    fmin = fCurr;
end

