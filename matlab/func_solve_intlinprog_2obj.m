function [sol_table,x,fval,exitflag,output, f1_value, f2_value] = func_solve_intlinprog_2obj(x0, nEleByEff, nEleByCost, nA, nD, nR, nM, nvars, ...
    Qrd, seq_pred, seq_succ, buffer, options, ...
    coeffDura, coeffCost, onlyX0_bool, normalisationFactor_obj1, normalisationFactor_obj2)
% nEleByEff = duration;
% nEleByCost = cost;
% nEleByEff: duration, as 3D matrix of a, r, m [days]
% nEleByCost: cost, as 3D matrix of a, r, m [euro]
% both are at activity cluster level, i.e. have been multiplied by the number of elements
sol = nvars;
% nD: for mode 1 (the slowest mode), for each resource, calculate the sum of duration of all activities,
% then find the max sum
% nD = max(sum(nEleByEff(:,:,1))); 
% nvars = nA*(2 + nR*(2+nM+3*nD));

%% Variables ===============================================
n1Res = 2+nM+3*nD;
n1Act = 2+nR*(2+nM+3*nD);
lb = zeros(nvars,1);
% the start date of dummy start is 0, all its successors can start in day 1
ub = ones(nvars,1);
for a = 1:nA
    ub((a-1)*n1Act +1) = nD;  % ES_a
    ub((a-1)*n1Act +2) = nD;  % EF_a
    for res = 1:nR
        ub((a-1)*n1Act +2 + (res-1)*n1Res + 1) = nD;  % ES_ar
        ub((a-1)*n1Act +2 + (res-1)*n1Res + 2) = nD;  % EF_ar
    end
end
intcon = 1:nvars;


%% two choices:
% onlyX0_bool = true: if only need the initial solution
% onlyX0_bool = false: if should solve by intlinprog

if onlyX0_bool == true  % if only need the initial solution
    sol = x0;  % result x from intlinprog is a column vector; x0: row vector
    x = x0';
    fval = [];
    exitflag = [];
    output = [];
    
    
else  % if should solve by intlinprog, then go through all the formulation: objectives, constraints, solve, ...
    %% Objective ===============================================
    % Objective 1: total duration 
    f1 = zeros(1,nvars);
    % should not include ES_a or ES_ar in the function
    % may lead to false early start time: ES_a = 5 but actually should = 6
    for a = 1:nA
        f1((a-1)*n1Act + 1) = -1/(nA*nD/2)/2;  % ES_a
        f1((a-1)*n1Act + 2) = 1/(nA*nD/2);  % EF_a
        for res = 1:nR
            f1((a-1)*n1Act + 2 + (res-1)*n1Res + 1) = -1/(nA*nD*nR/2)/2;  % ES_ar
            f1((a-1)*n1Act + 2 + (res-1)*n1Res + 2) = 1/(nA*nD*nR/2);  % EF_ar
        end
    end
    f1((nA-1)*n1Act +2) = 1;  % EF_nA
    % f1 = f1 / (53-42);
    f1 = f1 * normalisationFactor_obj1;


    % Objective 2: total cost
    f2 = zeros(1,nvars);
    for a = 1:nA
        for res = 1:nR
            for m = 1:nM
                f2((a-1)*n1Act + 2 + (res-1)*n1Res + 2 + m) = nEleByCost(a,res,m);
            end
        end
    end
    % normalisation
    % f2 = f2 / (217.9e3 - 182.1e3);
    f2 = f2 * normalisationFactor_obj2;

    %% Constraints: inequality ===============================================
    % write the blocks for different levels, then make diagnol block matrix
    % FIrst, write one block for one resource for one activity
    A_1Res_eqn7 = zeros(nD-1, n1Res);
    % A_1Res_eqn7_Z = ...
    %     [1 -1  0  0
    %      0  1 -1  0
    %      0  0  1 -1];
    for r = 1:nD-1
        A_1Res_eqn7(r, 2+nM+nD +r) = 1;
        A_1Res_eqn7(r, 2+nM+nD +r+1) = -1;
    end
    A_1Res_eqn9 = zeros(nD-1, n1Res);
    % A_1Res_eqn9_Zp = ...
    %     [-1 1  0  0
    %      0 -1  1  0
    %      0  0 -1  1];
    for r = 1:nD-1
        A_1Res_eqn9(r, 2+nM+2*nD +r) = -1;
        A_1Res_eqn9(r, 2+nM+2*nD +r+1) = 1;
    end
    A_1Res_eqn10 = zeros(nD, nD);
    for r = 1:nD
        A_1Res_eqn10(r, 2+nM +r) = -1;
        A_1Res_eqn10(r, 2+nM+nD +r) = 1;
        A_1Res_eqn10(r, 2+nM+2*nD +r) = 1;
    end
    A_1Res = [A_1Res_eqn7; A_1Res_eqn9; A_1Res_eqn10];
    b_1Res = [zeros(nD-1,n1Res); zeros(nD-1,n1Res); ones(nD,n1Res)];
    height_1Res = height(A_1Res);

    % Second, write the block for one activity
    height_1Act = nR*((nD-1)+(nD-1)+nD) + nR + nR;
    A_1Act = zeros(height_1Act, n1Act);
    for res = 1:nR
        for r = 1:height_1Res
            for c = 1:n1Res
                A_1Act((res-1)*height_1Res +r, 2+ (res-1)*n1Res +c) = A_1Res(r,c);
            end
        end
    end
    for res = 1:nR  
        A_1Act(nR*height_1Res + res, 1) = 1;  % (eqn.1)
        A_1Act(nR*height_1Res + res, 2 +(res-1)*n1Res + 1) = -1;  % (eqn.1)
        A_1Act(nR*height_1Res +nR + res, 2) = -1;  % (eqn.2)
        A_1Act(nR*height_1Res +nR + res, 2 +(res-1)*n1Res + 2) = 1;  % (eqn.2)
    end
    b_1Act = zeros(height_1Act, n1Act);
    for res = 1:nR
        for r = 1:height_1Res
            b_1Act((res-1)*height_1Res +r) = b_1Res(r);
        end
    end

    % Third, write the block for the whole project (part 1) -----------sparse-------------
    % A_Part1 as sparse matrix --------------------------------------------------------
    % A_Part1 is large, so there may be an "out of memory" error
    % if so, display the error message
    errorMessage = [];
    try
        % Error-maker
        i_A_part1 = zeros(1, nA*height_1Act*n1Act);
        j_A_part1 = zeros(1, nA*height_1Act*n1Act);
        s_A_part1 = zeros(1, nA*height_1Act*n1Act);
    catch ME  %MException struct
        % fprintf(1,'The identifier was:\n%s', e.identifier);
        % fprintf(1,'Error in function "func_solve_intlinprog_2obj":\n%s', e.message);
        errorMessage = ['Error in func_solve_intlinprog_2obj: ', ME.message];

        if ME.message == 'Out of memory.'
            errorMessage = [errorMessage, ' Possible reason: nvars is too large. Suggest to take x0 only (i.e. set onlyX0_bool = true)'];
        end
        disp(errorMessage)
        rethrow(ME)  % terminates the programme
    end
    % i_A_part1 = zeros(1, nA*height_1Act*n1Act);
    % j_A_part1 = zeros(1, nA*height_1Act*n1Act);
    % s_A_part1 = zeros(1, nA*height_1Act*n1Act);


    % num of rows: (nA*height_1Act)
    % num of cols: (nA*n1Act)
    % all the nonzeros in one row firsst, then the next row
    for a = 1:nA
        for b = 1:height_1Act
            for c = 1:n1Act
                i_A_part1((a-1)*(n1Act*height_1Act) + (b-1)*n1Act + c) = (a-1)*height_1Act + b;
            end
        end
    end
    for a = 1:nA
        for b = 1:height_1Act
            for c = 1:n1Act
                j_A_part1((a-1)*(n1Act*height_1Act) + (b-1)*n1Act + c) = (a-1)*n1Act + c;
            end
        end
    end
    for a = 1:nA
        for b = 1:height_1Act
            for c = 1:n1Act
                s_A_part1((a-1)*(n1Act*height_1Act) + (b-1)*n1Act + c) = A_1Act(b, c);
            end
        end
    end
    A_part1 = sparse(i_A_part1, j_A_part1, s_A_part1, nA*height_1Act, nvars);


    b_part1 = zeros(nA*height_1Act,1);
    for a = 1:nA
        for r = 1:height_1Act
            b_part1((a-1)*height_1Act +r) = b_1Act(r);
        end
    end

    % Fourth, write the blocks for the whole project (part 2 and part_seq)
    A_part2 = zeros(nD*nR, nvars);  % (eqn.5)
    for res = 1:nR
        for d = 1:nD
            for a = 1:nA
                A_part2((res-1)*nD + d, (a-1)*n1Act +(res-1)*n1Res + (2+2+nM) +d) = 1;
            end
        end
    end
    b_part2 = zeros(nD*nR,1);
    for res = 1:nR
        for d = 1:nD
            b_part2((res-1)*nD + d, 1) = Qrd(res, d);
        end
    end

    A_partSeq = zeros(length(seq_pred), nvars);
    for i = 1:length(seq_pred)
        A_partSeq(i, (seq_pred(i)-1)*n1Act + 2) = 1;
        A_partSeq(i, (seq_succ(i)-1)*n1Act + 1) = -1;
    end
    b_partSeq = -1 * (buffer' + 1);

    A = [A_part1; A_part2; A_partSeq];
    b = [b_part1; b_part2; b_partSeq];



    %% Constraints: equality ===============================================
    Aeq_eqn3 = zeros(nA*nR, nvars);
    for a = 1:nA
        for res = 1:nR
            Aeq_eqn3((a-1)*nR + res, (a-1)*n1Act + 2 + (res-1)*n1Res + 1) = 1;
            Aeq_eqn3((a-1)*nR + res, (a-1)*n1Act + 2 + (res-1)*n1Res + 2) = -1;
            for m = 1:nM
                Aeq_eqn3((a-1)*nR + res, (a-1)*n1Act + 2 + (res-1)*n1Res + 2 + m) = nEleByEff(a,res,m);
            end
        end
    end
    beq_eqn3 = ones(nA*nR,1);

    Aeq_eqn6and8 = zeros(2*nA*nR, nvars);
    for a = 1:nA
        for res = 1:nR
            % (eqn.6)
            Aeq_eqn6and8((a-1)*nR + res, (a-1)*n1Act + 2 + (res-1)*n1Res + 1) = 1;
            for d = 1:nD
                Aeq_eqn6and8((a-1)*nR + res, (a-1)*n1Act + 2 + (res-1)*n1Res + (2+nM+nD) + d) = 1;
            end
            % (eqn.8)
            Aeq_eqn6and8(nA*nR + (a-1)*nR + res, (a-1)*n1Act + 2 + (res-1)*n1Res + 2) = -1;
            for d = 1:nD
                Aeq_eqn6and8(nA*nR + (a-1)*nR + res, (a-1)*n1Act + 2 + (res-1)*n1Res + (2+nM+2*nD) + d) = 1;
            end
        end
    end
    beq_eqn6and8 = [(nD+1)*ones(nA*nR,1); zeros(nA*nR,1)];

    Aeq_eqn11 = zeros(nA*nR, nvars);
    for a = 1:nA
        for res = 1:nR
            for m = 1:nM
                Aeq_eqn11((a-1)*nR + res, (a-1)*n1Act + 2 + (res-1)*n1Res + 2 + m) = 1;
            end
        end
    end
    beq_eqn11 = ones(nA*nR,1);

    Aeq = [Aeq_eqn3; Aeq_eqn6and8; Aeq_eqn11];
    beq = [beq_eqn3; beq_eqn6and8; beq_eqn11];


    %% Solution & output ===============================================
    f = coeffDura * f1 + coeffCost * f2;
    tic
    [x,fval,exitflag,output] = intlinprog(f,intcon,A,b,Aeq,beq,lb,ub,x0,options);
    toc
    sol = x';  % sol: row vector
end




%% write the result into a table
sol_mat = reshape(sol, [n1Act, nA])';

ESEF_act = zeros(nA, 2);
for a = 1:nA
    ESEF_act(a,1) = sol((a-1)*n1Act +1);
    ESEF_act(a,2) = sol((a-1)*n1Act +2);
end

tableRowName = repmat(" ", nA*nR, 1);
for a = 1:nA
    for res = 1:nR
        tableRowName((a-1)*nR+res,1) = strcat("Act",num2str(a),"_Res",num2str(res));
    end
end
sz = [nA*nR 2+n1Res];
varTypes = repmat("double", 1, 2+n1Res);
varNames = repmat("var", 1, 2+n1Res);
varNames(1) = "ES_Act";
varNames(2) = "EF_Act";
varNames(3) = "ES_Res";
varNames(4) = "EF_Res";
for m = 1:nM
    varNames(2+2+m) = strcat("M",num2str(m));
end
for d = 1:nD
    varNames(2+2+nM+d) = strcat("D",num2str(d));
    varNames(2+2+nM+nD+d) = strcat("z",num2str(d));
    varNames(2+2+nM+2*nD+d) = strcat("z_p",num2str(d));
end
sol_table = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames,'RowNames',tableRowName);
for a = 1:nA
    for res = 1:nR
        sol_table{(a-1)*nR+res,1} = sol_mat(a,1); % ESEF for each activity
        sol_table{(a-1)*nR+res,2} = sol_mat(a,2);
        for i = 1:n1Res                                % ESEF for each resource, M, U, z, z_p
            if abs(sol_mat(a,2+(res-1)*n1Res+i)) < 1e-9
                sol_table{(a-1)*nR+res,2+i} = 0;
            else
                sol_table{(a-1)*nR+res,2+i} = sol_mat(a,2+(res-1)*n1Res+i);
            end
        end
    end
end
% sol_table;
% sol = sol_table;

% values of objective functions
f1_value = ESEF_act(nA, 2);
f2 = zeros(1,nvars);
    for a = 1:nA
        for res = 1:nR
            for m = 1:nM
                f2((a-1)*n1Act + 2 + (res-1)*n1Res + 2 + m) = nEleByCost(a,res,m);
            end
        end
    end
f2_value = f2 * sol';
