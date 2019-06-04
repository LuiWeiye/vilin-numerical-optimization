function [ fmin, xmin, it, cpuTime, evalNumbers, valuesPerIter ] = BFGS( functionName, methodParams )

%   ------------------      *******************        ------------------
%   *                                                                   *
%   *               *************************************               *
%   *               *                                   *               *
%   *               *            BFGS Method            *               *
%   *               *                                   *               *
%   *               *************************************               *
%   *                                                                   *
%   ------------------      *******************        ------------------

%   The BFGS is quasi Newton method discovered independently by Broyden 
%   Fletcher, Goldfarb and Shanno (shortly BFGS). This method is one of 
%   the most popular members of this class. In order to maintain good 
%   search directions the Wolfe or strong Wolfe line search should 
%   be applied.

%   C.G. Broyden,
%   The convergence of a class of double-rank minimization algorithms, 
%   Journal of the Institute of Mathematics and Its Applications, 
%   6 (1970) 76�90.

%   R. Fletcher,
%   A new approach to variable metric algorithms, 
%   Computer Journal 13 (1970) 317�322.

%   D. Goldfarb,
%   A family of variable metric methods derived by variation mean, 
%    Mathematics of Computation 23 (1970) 23�26.

%   D.F. Shanno,
%   Conditioning of quasi-Newton methods for function minimization, 
%   Mathematics of Computation, 24 (1970) 647-656.

%   ------------------      *******************        ------------------

    % set initial values
    evalNumbers = EvaluationNumbers(0,0,0);
    x1 = methodParams.starting_point;
    maxIter = methodParams.max_iteration_no;
    valuesPerIter = PerIteration(maxIter);
    eps = methodParams.epsilon;
    t = methodParams.startingPoint;
    tic;                                    % to compute CPU time
    it = 1;                                 % number of iteration
    dim = length(x1);
    H = eye(dim);                           % define approx matrix
    
    [fCurr, gr1, ~] = feval(functionName, x1, [1 1 0]);
    evalNumbers.incrementBy([1 1 0]);
    grNorm = double(norm(gr1));
    % Added values for first iteration in graphic
    valuesPerIter.setFunctionVal(it, fCurr);
    valuesPerIter.setGradientVal(it, grNorm);
    % add values for plot
    if (size(x1, 2) == 2)
        valuesPerIter.setXVal(it, x1);
    end
    workPrec = methodParams.workPrec;
    fPrev = fCurr + 1;
        
    % process
    while (grNorm > eps && it < maxIter && abs(fPrev - fCurr)/(1 + abs(fCurr)) > workPrec)
        
        dir = (-H*gr1)'; % computes direction
        
        fValues = valuesPerIter.functionPerIteration(1:it); % take vector of function values after first 'it' iteration
        params = LineSearchParams(methodParams, fValues, gr1, dir, x1, t, it);
        % update values
        fPrev = fCurr; 
        x0 = x1; gr0 = gr1;
        
        % Computes x1 and step-size according to the line search method rule
        [t, x1, fCurr, gr1, lineSearchEvalNumbers ] = feval(methodParams.lineSearchMethod, functionName, params);
        evalNumbers = evalNumbers + lineSearchEvalNumbers;
        grNorm = double(norm(gr1));
        
        % compute vectors s and y
        s = (x1 - x0)';
        y = gr1 - gr0;
        
        % update inverse Hessian approximation
        auxSc = s'*y; % auxiliary variable 
        % practical and fast expression for update
        H = H + (auxSc + y'*(H*y))*(s*s')/auxSc^2 - ((H*y)*s' + s*(y'*H))/auxSc;
              
        it = it + 1;
        
        valuesPerIter.setFunctionVal(it, fCurr);
        valuesPerIter.setGradientVal(it, grNorm);
        valuesPerIter.setStepVal(it, t);
        % add values for plot
        if (size(x1, 2) == 2)
            valuesPerIter.setXVal(it, x1);
            valuesPerIter.setDirVal(it, dir);
        end
    end
    
    cpuTime = toc;
    valuesPerIter.trim(it);
    xmin = x1; 
    fmin = fCurr;
    it = it - 1;
end
