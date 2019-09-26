function [ outT, outX, outVal, outGr, evalNumbers ] = NonMonotone( functionName, params )

%   ------------------      *******************        ------------------
%   *                                                                   *
%   *               *************************************               *
%   *               *                                   *               *
%   *               *      Nonmonotone line search      *               *
%   *               *                                   *               *
%   *               *************************************               *
%   *                                                                   *
%   ------------------      *******************        ------------------

%   Nonmonotone line search is a line search procedure for computing 
%   step-size parameter t. The nonmonotone rule can be viewed as a 
%   generalization of Armijo’s rule. The authors claim that 
%   the proposed technique may allow a considerable saving both in 
%   the number of line searches and in the number of function 
%   evaluations. This implementation uses cubic interpolation for 
%   finding a step-size parameter. Method is originally developed 
%   by L. Grippo, F. Lampariello and S. Lucidi.

%   L. Grippo, F. Lampariello, S. Lucidi,
%   A Nonmonotone Line Search Technique for Newton's Method,
%   SIAM J. Numer. Anal. 23 (1986) 707–716.

%   ------------------      *******************        ------------------

    % set initial values
    evalNumbers = EvaluationNumbers(0,0,0);
    x0 = params.startingPoint;
    vals = params.vals;
    val = vals(end); % take last (current) function value
    gr = params.grad;
    dir = params.dir;
    rho = params.rho;
    M = params.m; % parameter which determine the size of cache of function values
    tInit = params.tInitStart;
    iterNum = params.it; % number of iter of original method (outer loop)
    it = 1;                                         % number of iteration
    
    % This block of code determines starting value for t
    if iterNum == 1
        t1 = tInit;
    else
        val00 = vals(end-1); % take one before last function value
        % compute initial stepsize according to Nocedal simple rule
        t1 = computLineSearchStartPoint(val, val00, gr, dir); 
    end;
    
    [val1, ~, ~] = feval(functionName, x0 + t1*dir, [1 0 0]);
    evalNumbers.incrementBy([1 0 0]);
    derPhi0 = gr'*dir';

    val2 = val1;
    t2 = t1;
    
    % Predefine vector funValues for storing function values
    largeNum = 10^12;
    maxVecSize = M + 1;
    funValues = -largeNum*ones(1, maxVecSize);
    funValues(1:2) = [val, val1];
    currValues = [val, val1];
    
          
    % process  
    while (val2 > max(currValues) + rho*t2*derPhi0)
        if it == 1
            t2 = interQuadratic(t1, val, val1, derPhi0);
            [val2, ~, ~] = feval(functionName, x0 + t2*dir, [1 0 0]);
            evalNumbers.incrementBy([1 0 0]);
        else
            [t] = interCubic(t1, t2, val, val1, val2, derPhi0);
            val1 = val2;
            t1 = t2;
            t2 = t;
            [val2, ~, ~] = feval(functionName, x0 + t2*dir, [1 0 0]);
            evalNumbers.incrementBy([1 0 0]);
        end;
        it = it + 1;
        
        % take last M numbers from funValues
        funValues(it + 1) = val2;
        if it+1 > M
            currValues = funValues(end-M+1:end);
        else
            currValues = funValues(1 : it + 1);
        end;
     end; 
                
    % save output values
    xmin = x0 + t2*dir;
    outX = xmin; outT = t2;
    outVal = val2;
    % compute gradient in current point xmin 
    [~, outGr, ~] = feval(functionName, xmin, [0 1 0]);   
    evalNumbers.incrementBy([0 1 0]);
             
end

function [t] = interQuadratic(t1, val0, val1, der0)
    t = -der0*t1^2 / (2*(val1 - val0 - der0*t1));
end

function [t] = interCubic(t1, t2, val0, val1, val2, der0)
    a = 1/((t1^2*t2^2)*(t2 - t1)) * [t1^2, -t2^2] * [val2 - val0 - der0*t2; val1 - val0 - der0*t1];
    b = 1/((t1^2*t2^2)*(t2 - t1)) * [-t1^3, t2^3] * [val2 - val0 - der0*t2; val1 - val0 - der0*t1];
    t = (-b + sqrt(b^2 - 3*a*der0)) / (3*a);
end
