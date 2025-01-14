function test19
%TEST19 look for NaN's from lchol (caused by Intel MKL 7.x bug)
% Example:
%   test19
% See also cholmod_test

% Copyright 2006-2023, Timothy A. Davis, All Rights Reserved.
% SPDX-License-Identifier: GPL-2.0+

fprintf ('=================================================================\n');
fprintf ('test19: look for NaN''s from lchol (caused by Intel MKL 7.x bug)\n') ;

Prob = ssget (936)                                                          %#ok
A = Prob.A ;
[p count] = analyze (A) ;
A = A (p,p) ;
tic
L = lchol (A) ;
t = toc ;
fl = sum (count.^2) ;
fprintf ('gflop rate: %8.2f\n', 1e-9*fl/t) ;
n = size (L,1) ;
for k = 1:n
    if (any (isnan (L (:,k))))
        k                                                                   %#ok
        error ('!') ;
    end
end

fprintf ('test19 passed; you have a NaN-free BLAS (must not be MKL 7.x...)\n') ;
