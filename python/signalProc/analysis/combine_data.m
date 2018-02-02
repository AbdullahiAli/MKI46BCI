x = load('../data_left_bram');
y = load('../data_right_bram');
% Check to see that both files contain the same variables
vrs = fieldnames(x);
if ~isequal(vrs,fieldnames(y))
    error('Different variables in these MAT-files')
end
% Concatenate data
for k = 1:length(vrs)
    x.(vrs{k}) = [x.(vrs{k});y.(vrs{k})];
end
% Save result in a new file
save('data.mat','-struct','x')