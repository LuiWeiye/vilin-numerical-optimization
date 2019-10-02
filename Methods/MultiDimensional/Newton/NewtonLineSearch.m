function [ fmin, xmin, it, cpuTime, evalNumbers, valuesPerIter ] = NewtonLineSearch( functionName, methodParams )

%   ------------------      *******************        ------------------
%   *                                                                   *
%   *               *************************************               *
%   *               *                                   *               *
%   *               *        Newton Line Search         *               *
%   *               *                                   *               *
%   *               *************************************               *
%   *                                                                   *
%   ------------------      *******************        ------------------

%   The Newton line search method is classical Newton method. This is 
%   second order method (use Hessain and it's inverse) and is one of 
%   the oldest and most famous method in numerical optimization.
%   Originally, fixed line search method is applied.

%   ------------------      *******************        ------------------

    % set initial values
    tic;
    evalNumbers = EvaluationNumbers(0, 0, 0);
    maxIter = methodParams.max_iteration_no;
    valuesPerIter = PerIteration(maxIter);
    epsilon = methodParams.epsilon;
    xmin = methodParams.starting_point;
    t = methodParams.startingPoint;
    it = 1; 
        
    [fCurr, grad, hes] = feval(functionName, xmin, [1 1 1]);
    evalNumbers.incrementBy([1 1 1]);
    % Added values for first iteration in graphic
    valuesPerIter.setFunctionVal(it, fCurr);
    valuesPerIter.setGradientVal(it, norm(grad));
    % add values for plot
    if (size(xmin, 2) == 2)
        valuesPerIter.setXVal(it, xmin);
    end
    workPrec = methodParams.workPrec;
    fPrev = fCurr + 1;

    % process
    while (it < maxIter && norm(grad) > epsilon && abs(fPrev - fCurr)/(1 + abs(fCurr)) > workPrec)
        
        % Computes Newton search direction
        dk = -hes\grad;
        fValues = valuesPerIter.functionPerIteration(1:it); % take vector of function values after first 'it' iteration
        params = LineSearchParams(methodParams, fValues, grad, dk', xmin, t, it);
        fPrev = fCurr; % update value
        
        % Computes xmin and step-size according to the line search method rule
        [t, xmin, fCurr, grad, lineSearchEvalNumbers ] = feval(methodParams.lineSearchMethod, functionName, params);
        evalNumbers = evalNumbers + lineSearchEvalNumbers;
                
        [~, ~, hes] = feval(functionName, xmin, [0 0 1]);
        evalNumbers.incrementBy([0 0 1]);

        it = it + 1;
        
        valuesPerIter.setFunctionVal(it, fCurr);
        valuesPerIter.setGradientVal(it, norm(grad));
        valuesPerIter.setStepVal(it, t);
        % add values for plot
        if (size(xmin, 2) == 2)
            valuesPerIter.setXVal(it, xmin);
            valuesPerIter.setDirVal(it, dk);
        end
    end

    cpuTime = toc;
    fmin = fCurr;
    valuesPerIter.trim(it);
    it = it - 1;
end

