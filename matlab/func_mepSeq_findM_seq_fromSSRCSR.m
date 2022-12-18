function [M_seq] = func_mepSeq_findM_seq_fromSSRCSR(M1_seq, M2_seq)
%% SEQ MEP STEP 3 (added): combine M1_seq and M2_seq into one 
M_seq = M1_seq;

toSelect_M2_seq = M2_seq == 1;
toSelect_M1_seq_zero = M1_seq == 0;
M_seq(toSelect_M2_seq & toSelect_M1_seq_zero) = 1;

toSelect_M2_seq = M2_seq == -1;
toSelect_M1_seq_zero = M1_seq == 0;
M_seq(toSelect_M2_seq & toSelect_M1_seq_zero) = -1;

% disp(['No. MEP compo pairs with SSR and non-conflicting CSR: ', num2str(sum(M_seq>0, 'all'))])