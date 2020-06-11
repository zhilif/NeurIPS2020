function [x,hist] = optTrustRegion(objFun,x0,args)
global sampleSize;

%% Set general arguments.
if isfield(args,'maxItrs'); maxItrs = args.maxItrs; else; maxItrs = 20; end
if isfield(args,'subProbMaxItr'); subProbMaxItr = args.subProbMaxItr; else; subProbMaxItr = 100; end
if isfield(args,'maxProps'); maxProps = args.maxProps; else; maxProps = 1000; end
if isfield(args,'gradTol'); gradTol = args.gradTol; else; gradTol = 1E-6; end
if isfield(args,'testFun'); testFun = args.testFun; else; testFun = []; end
if isfield(args,'delta'); delta = args.delta; else; delta = 1; end
if isfield(args,'eta1'); eta1 = args.eta1; else; eta1 = 0.8; end
if isfield(args,'eta2'); eta2 = args.eta2; else; eta2 = 1E-4; end
if isfield(args,'gamma1'); gamma1 = args.gamma1; else; gamma1 = 2; end
if isfield(args,'gamma2'); gamma2 = args.gamma2; else; gamma2 = 1.2; end



hist.objVal = [];
hist.props = 1;
hist.gradNorm = [];
hist.testVal = zeros(1,1);
hist.elapsed_time = [];


xk = x0;
k = 0;
%%%%%%%%%%%%%%%%% Start of Printing Headers %%%%%%%%%%%%%%%%%%%%%%%%%%
logBody0 = '%5i  %13g %13.2e \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t %13.2f\n';
logBodyk = '%5i  %13g %13.2e %11.2f %13.2f %9i %14s %16.2e %13.2f\n';

%logBody0 = '%5i  %13g %13.2e \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t %24.2f\n';
%logBodyk = '%5i  %13g %13.2e  \t%10g %12.2e %7g %12.2g%12.2g%14g%15.2f\n';
%%%%%%%%%%%%%%%%% End of Printing Headers %%%%%%%%%%%%%%%%%%%%%%%%%%
hist.elapsed_time = 1E-16;
hist = recordHistory(hist, objFun, xk, testFun);
while true
    fail_count = 0;
    current_props = 0;
    current_elapsed_time = 0;
    tic;
    [fk,gk,Hk] = objFun(xk);
    tt = toc; current_elapsed_time = current_elapsed_time + tt;
    if k == 0
        current_props = current_props + 2;
    else
        hist = recordHistory(hist, objFun, xk, testFun);
        assert(length(hist.elapsed_time) == length(hist.objVal));
        assert(length(hist.elapsed_time) == length(hist.testVal));
    end
    if mod(k,10) == 0
        fprintf('%5s %11s %16s %14s %10s %15s %13s %10s %16s\n','k','fun','norm(g)', 'time(sec)', 'Delta', 'SubProbItrs', 'SubProbFlag', 'Props', 'Test Results');
    end
    if k >= 1
        fprintf( logBodyk, k, hist.objVal(end) , norm(gk), hist.elapsed_time(end), delta, subProbIters, subProbFlag,hist.props(end),hist.testVal(end) );
    else
        fprintf( logBody0, k, hist.objVal(end), norm(gk), hist.testVal(end));
    end
    if norm(gk) < gradTol || k >= maxItrs || hist.props(end) > maxProps || delta == 0
        break;
    end
    tic;
    steihaugParams = [0, subProbMaxItr, 0]; % parameters for Steighaug-CG
    while true % CG Steihaug Loop
        if fail_count == 0
            z = randn(size(x0));
            p0 = 0.99*delta*z/norm(z);
        else
            p0 = [];
        end
        [pk,mk, subProbIters, subProbFlag] = cg_steihaug (@(x) Hk*x, gk, delta, steihaugParams, p0 );
%         if mk >= 0
%             lll = 0;
%         end
%         assert(mk <= 0);
        
        current_props = current_props + subProbIters*2*sampleSize;
        
        f_new = objFun(xk + pk);
        current_props = current_props + 1;
        rho = (fk - f_new)/-mk;
        if mk >= 0 || rho < eta2
            fail_count = fail_count + 1;
            % fprintf('FALIURE No. %d: delta = %g, rho = %g, iters: %g\n', fail_count, delta, rho,num);
            delta = delta/gamma1;
            pk = 0;
        elseif rho < eta1
            % fprintf('SUCCESS: delta = %g, rho = %g, s = %g\niters: %g\n', delta, rho, norm(z), num );
            %                             w = w + z;
            delta = gamma2*delta;
            break
        else
            % fprintf('SUPER SUCCESS: delta = %g, rho = %g, s = %g\niters: %g\n', delta, rho, norm(z),num );
            %                             w = w + z;
            delta = gamma1*delta;
            break;
        end
    end
    xk = xk + pk;
    tt = toc; current_elapsed_time = current_elapsed_time + tt;
    hist.elapsed_time = [hist.elapsed_time, hist.elapsed_time(end) + current_elapsed_time];
    k = k + 1;
    hist.props = [hist.props, hist.props(end) + current_props];
end
x = xk;
end