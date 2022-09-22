function spqr_make (opt1)
%SPQR_MAKE compiles the SuiteSparseQR mexFunctions
%
% Example:
%   spqr_make
%
% SuiteSparseQR relies on CHOLMOD, AMD, and COLAMD, and optionally CCOLAMD,
% CAMD, and METIS.  Next, type
%
%   spqr_make
%
% in the MATLAB command window.  If METIS is not present in
% ../../SuiteSparse_metis, then it is not used.
%
% You must type the spqr_make command while in the SuiteSparseQR/MATLAB
% directory.
%
% See also spqr, spqr_solve, spqr_qmult, qr, mldivide

% SPQR, Copyright (c) 2008-2022, Timothy A Davis. All Rights Reserved.
% SPDX-License-Identifier: GPL-2.0+

details = 0 ;       % 1 if details of each command are to be printed, 0 if not

v = version ;
try
    % ispc does not appear in MATLAB 5.3
    pc = ispc ;
    mac = ismac ;
catch                                                                       %#ok
    % if ispc fails, assume we are on a Windows PC if it's not unix
    pc = ~isunix ;
    mac = 0 ;
end

flags = '' ;
is64 = (~isempty (strfind (computer, '64'))) ;
if (is64)
    % 64-bit MATLAB
    flags = '-largeArrayDims' ;
end

% MATLAB 8.3.0 now has a -silent option to keep 'mex' from burbling too much
if (~verLessThan ('matlab', '8.3.0'))
    flags = ['-silent ' flags] ;
end

include = '-DNMATRIXOPS -DNMODIFY -I. -I../../AMD/Include -I../../COLAMD/Include -I../../CHOLMOD/Include -I../Include -I../../SuiteSparse_config' ;

% Determine if METIS is available
metis_path = '../../SuiteSparse_metis' ;
have_metis = exist (metis_path, 'dir') ;

% fix the METIS 4.0.1 rename.h file
if (have_metis)
    fprintf ('Compiling SuiteSparseQR with METIS for MATLAB Version %s\n', v) ;
    include = [include ' -I' metis_path '/include'] ;
    include = [include ' -I' metis_path '/GKlib'] ;
    include = [include ' -I' metis_path '/libmetis'] ;
    include = [include ' -I../../CCOLAMD/Include -I../../CAMD/Include' ] ;
else
    fprintf ('Compiling SuiteSparseQR without METIS on MATLAB Version %s\n', v);
    include = ['-DNPARTITION ' include ] ;
end

%-------------------------------------------------------------------------------
% BLAS option
%-------------------------------------------------------------------------------

% This is exceedingly ugly.  The MATLAB mex command needs to be told where to
% find the LAPACK and BLAS libraries, which is a real portability nightmare.
% The correct option is highly variable and depends on the MATLAB version.

if (pc)
    if (verLessThan ('matlab', '6.5'))
        % MATLAB 6.1 and earlier: use the version supplied in CHOLMOD
        lib = '../../CHOLMOD/MATLAB/lcc_lib/libmwlapack.lib' ;
    elseif (verLessThan ('matlab', '7.5'))
        % use the built-in LAPACK lib (which includes the BLAS)
        lib = 'libmwlapack.lib' ;
    elseif (verLessThan ('matlab', '9.5'))
        lib = 'libmwlapack.lib libmwblas.lib' ;
    else
        lib = '-lmwlapack -lmwblas' ;
    end
else
    if (verLessThan ('matlab', '7.5'))
        % MATLAB 7.5 and earlier, use the LAPACK lib (including the BLAS)
        lib = '-lmwlapack' ;
    else
        % MATLAB 7.6 requires the -lmwblas option; earlier versions do not
        lib = '-lmwlapack -lmwblas' ;
    end
end

if (is64 && ~verLessThan ('matlab', '7.8'))
    % versions 7.8 and later on 64-bit platforms use a 64-bit BLAS
    fprintf ('with 64-bit BLAS\n') ;
    flags = [flags ' -DBLAS64'] ;
end

%-------------------------------------------------------------------------------
% GPU option
%-------------------------------------------------------------------------------

% GPU not yet supported for the spqr MATLAB mexFunction
% flags = [flags ' -DGPU_BLAS'] ;

if (~(pc || mac))
    % for POSIX timing routine
    lib = [lib ' -lrt'] ;
end

%-------------------------------------------------------------------------------
% ready to compile ...
%-------------------------------------------------------------------------------

config_src = { '../../SuiteSparse_config/SuiteSparse_config' } ;

amd_c_src = { ...
    '../../AMD/Source/amd_l1', ...
    '../../AMD/Source/amd_l2', ...
    '../../AMD/Source/amd_l_aat', ...
    '../../AMD/Source/amd_l_control', ...
    '../../AMD/Source/amd_l_defaults', ...
    '../../AMD/Source/amd_l_dump', ...
    '../../AMD/Source/amd_l_info', ...
    '../../AMD/Source/amd_l_order', ...
    '../../AMD/Source/amd_l_postorder', ...
    '../../AMD/Source/amd_l_post_tree', ...
    '../../AMD/Source/amd_l_preprocess', ...
    '../../AMD/Source/amd_l_valid' } ;

colamd_c_src = {
    '../../COLAMD/Source/colamd_l' } ;

% CAMD and CCOLAMD are not needed if we don't have METIS
camd_c_src = { ...
    '../../CAMD/Source/camd_l1', ...
    '../../CAMD/Source/camd_l2', ...
    '../../CAMD/Source/camd_l_aat', ...
    '../../CAMD/Source/camd_l_control', ...
    '../../CAMD/Source/camd_l_defaults', ...
    '../../CAMD/Source/camd_l_dump', ...
    '../../CAMD/Source/camd_l_info', ...
    '../../CAMD/Source/camd_l_order', ...
    '../../CAMD/Source/camd_l_postorder', ...
    '../../CAMD/Source/camd_l_preprocess', ...
    '../../CAMD/Source/camd_l_valid' } ;

ccolamd_c_src = {
    '../../CCOLAMD/Source/ccolamd_l' } ;

if (have_metis)

    metis_c_src = {
        'GKlib/b64', ...
        'GKlib/blas', ...
        'GKlib/csr', ...
        'GKlib/error', ...
        'GKlib/evaluate', ...
        'GKlib/fkvkselect', ...
        'GKlib/fs', ...
        'GKlib/getopt', ...
        'GKlib/gkregex', ...
        'GKlib/graph', ...
        'GKlib/htable', ...
        'GKlib/io', ...
        'GKlib/itemsets', ...
        'GKlib/mcore', ...
        'GKlib/memory', ...
        'GKlib/omp', ...
        'GKlib/pdb', ...
        'GKlib/pqueue', ...
        'GKlib/random', ...
        'GKlib/rw', ...
        'GKlib/seq', ...
        'GKlib/sort', ...
        'GKlib/string', ...
        'GKlib/timers', ...
        'GKlib/tokenizer', ...
        'GKlib/util', ...
        'libmetis/auxapi', ...
        'libmetis/balance', ...
        'libmetis/bucketsort', ...
        'libmetis/checkgraph', ...
        'libmetis/coarsen', ...
        'libmetis/compress', ...
        'libmetis/contig', ...
        'libmetis/debug', ...
        'libmetis/fm', ...
        'libmetis/fortran', ...
        'libmetis/frename', ...
        'libmetis/gklib', ...
        'libmetis/graph', ...
        'libmetis/initpart', ...
        'libmetis/kmetis', ...
        'libmetis/kwayfm', ...
        'libmetis/kwayrefine', ...
        'libmetis/mcutil', ...
        'libmetis/mesh', ...
        'libmetis/meshpart', ...
        'libmetis/minconn', ...
        'libmetis/mincover', ...
        'libmetis/mmd', ...
        'libmetis/ometis', ...
        'libmetis/options', ...
        'libmetis/parmetis', ...
        'libmetis/pmetis', ...
        'libmetis/refine', ...
        'libmetis/separator', ...
        'libmetis/sfm', ...
        'libmetis/srefine', ...
        'libmetis/stat', ...
        'libmetis/timing', ...
        'libmetis/util', ...
        'libmetis/wspace', ...
    } ;

    for i = 1:length (metis_c_src)
        metis_c_src {i} = [metis_path '/' metis_c_src{i}] ;
    end
end

cholmod_c_src = {
    '../../CHOLMOD/Core/cholmod_l_aat', ...
    '../../CHOLMOD/Core/cholmod_l_add', ...
    '../../CHOLMOD/Core/cholmod_l_band', ...
    '../../CHOLMOD/Core/cholmod_l_change_factor', ...
    '../../CHOLMOD/Core/cholmod_l_common', ...
    '../../CHOLMOD/Core/cholmod_l_complex', ...
    '../../CHOLMOD/Core/cholmod_l_copy', ...
    '../../CHOLMOD/Core/cholmod_l_dense', ...
    '../../CHOLMOD/Core/cholmod_l_error', ...
    '../../CHOLMOD/Core/cholmod_l_factor', ...
    '../../CHOLMOD/Core/cholmod_l_memory', ...
    '../../CHOLMOD/Core/cholmod_l_sparse', ...
    '../../CHOLMOD/Core/cholmod_l_transpose', ...
    '../../CHOLMOD/Core/cholmod_l_triplet', ...
    '../../CHOLMOD/Check/cholmod_l_check', ...
    '../../CHOLMOD/Check/cholmod_l_read', ...
    '../../CHOLMOD/Check/cholmod_l_write', ...
    '../../CHOLMOD/Cholesky/cholmod_l_amd', ...
    '../../CHOLMOD/Cholesky/cholmod_l_analyze', ...
    '../../CHOLMOD/Cholesky/cholmod_l_colamd', ...
    '../../CHOLMOD/Cholesky/cholmod_l_etree', ...
    '../../CHOLMOD/Cholesky/cholmod_l_factorize', ...
    '../../CHOLMOD/Cholesky/cholmod_l_postorder', ...
    '../../CHOLMOD/Cholesky/cholmod_l_rcond', ...
    '../../CHOLMOD/Cholesky/cholmod_l_resymbol', ...
    '../../CHOLMOD/Cholesky/cholmod_l_rowcolcounts', ...
    '../../CHOLMOD/Cholesky/cholmod_l_rowfac', ...
    '../../CHOLMOD/Cholesky/cholmod_l_solve', ...
    '../../CHOLMOD/Cholesky/cholmod_l_spsolve', ...
    '../../CHOLMOD/Supernodal/cholmod_l_super_numeric', ...
    '../../CHOLMOD/Supernodal/cholmod_l_super_solve', ...
    '../../CHOLMOD/Supernodal/cholmod_l_super_symbolic' } ;

cholmod_c_partition_src = {
    '../../CHOLMOD/Partition/cholmod_l_ccolamd', ...
    '../../CHOLMOD/Partition/cholmod_l_csymamd', ...
    '../../CHOLMOD/Partition/cholmod_l_camd', ...
    '../../CHOLMOD/Partition/cholmod_l_metis', ...
    '../../CHOLMOD/Partition/cholmod_l_nesdis' } ;

% SuiteSparseQR does not need the MatrixOps or Modify modules of CHOLMOD
%   cholmod_unused = {
%       '../../CHOLMOD/MatrixOps/cholmod_drop', ...
%       '../../CHOLMOD/MatrixOps/cholmod_horzcat', ...
%       '../../CHOLMOD/MatrixOps/cholmod_norm', ...
%       '../../CHOLMOD/MatrixOps/cholmod_scale', ...
%       '../../CHOLMOD/MatrixOps/cholmod_sdmult', ...
%       '../../CHOLMOD/MatrixOps/cholmod_ssmult', ...
%       '../../CHOLMOD/MatrixOps/cholmod_submatrix', ...
%       '../../CHOLMOD/MatrixOps/cholmod_vertcat', ...
%       '../../CHOLMOD/MatrixOps/cholmod_symmetry', ...
%       '../../CHOLMOD/Modify/cholmod_rowadd', ...
%       '../../CHOLMOD/Modify/cholmod_rowdel', ...
%       '../../CHOLMOD/Modify/cholmod_updown' } ;

% SuiteSparseQR source code, and mex support file
spqr_cpp_src = {
    '../Source/spqr_parallel', ...
    '../Source/spqr_1colamd', ...
    '../Source/spqr_1factor', ...
    '../Source/spqr_1fixed', ...
    '../Source/spqr_analyze', ...
    '../Source/spqr_append', ...
    '../Source/spqr_assemble', ...
    '../Source/spqr_cpack', ...
    '../Source/spqr_csize', ...
    '../Source/spqr_cumsum', ...
    '../Source/spqr_debug', ...
    '../Source/spqr_factorize', ...
    '../Source/spqr_fcsize', ...
    '../Source/spqr_freefac', ...
    '../Source/spqr_freenum', ...
    '../Source/spqr_freesym', ...
    '../Source/spqr_front', ...
    '../Source/spqr_fsize', ...
    '../Source/spqr_happly', ...
    '../Source/spqr_happly_work', ...
    '../Source/spqr_hpinv', ...
    '../Source/spqr_kernel', ...
    '../Source/spqr_larftb', ...
    '../Source/spqr_panel', ...
    '../Source/spqr_rconvert', ...
    '../Source/spqr_rcount', ...
    '../Source/spqr_rhpack', ...
    '../Source/spqr_rmap', ...
    '../Source/spqr_rsolve', ...
    '../Source/spqr_shift', ...
    '../Source/spqr_stranspose1', ...
    '../Source/spqr_stranspose2', ...
    '../Source/spqr_trapezoidal', ...
    '../Source/spqr_type', ...
    '../Source/spqr_tol', ...
    '../Source/spqr_maxcolnorm', ...
    '../Source/SuiteSparseQR_qmult', ...
    '../Source/SuiteSparseQR', ...
    '../Source/SuiteSparseQR_expert', ...
    '../MATLAB/spqr_mx' } ;

% SuiteSparse C source code, for MATLAB error handling
spqr_c_mx_src = { '../MATLAB/spqr_mx_error' } ;

% SuiteSparseQR mexFunctions
spqr_mex_cpp_src = { 'spqr', 'spqr_qmult', 'spqr_solve', 'spqr_singletons' } ;

if (pc)
    % Windows does not have drand48 and srand48, required by METIS.  Use
    % drand48 and srand48 in CHOLMOD/MATLAB/Windows/rand48.c instead.
    % Also provide Windows with an empty <strings.h> include file.
    obj_extension = '.obj' ;
    cholmod_c_src = [cholmod_c_src {'../../CHOLMOD/MATLAB/Windows/rand48'}] ;
    include = [include ' -I../../CHOLMOD/MATLAB/Windows'] ;
else
    obj_extension = '.o' ;
end

% compile each library source file
obj = '' ;

c_source = [config_src amd_c_src colamd_c_src cholmod_c_src spqr_c_mx_src ] ;
if (have_metis)
    c_source = [c_source cholmod_c_partition_src ccolamd_c_src ] ;
    c_source = [c_source camd_c_src metis_c_src] ;
end

cpp_source = spqr_cpp_src ;

kk = 0 ;

for f = cpp_source
    ff = f {1} ;
    slash = strfind (ff, '/') ;
    if (isempty (slash))
        slash = 1 ;
    else
        slash = slash (end) + 1 ;
    end
    o = ff (slash:end) ;
    obj = [obj  ' ' o obj_extension] ;                                      %#ok
    s = sprintf ('mex %s -O %s -c %s.cpp', flags, include, ff) ;
    kk = do_cmd (s, kk, details) ;
end

for f = c_source
    ff = f {1} ;
    if (isequal (ff, [metis_path '/GKlib/util']))
        % special case, since a file with the same name also exists in libmetis
        copyfile ([ff '.c'], 'GKlib_util.c', 'f') ;
        ff = 'GKlib_util' ;
        o = 'GKlib_util' ;
    elseif (isequal (ff, [metis_path '/GKlib/graph']))
        % special case, since a file with the same name also exist in libmetis
        copyfile ([ff '.c'], 'GKlib_graph.c', 'f') ;
        ff = 'GKlib_graph' ;
        o = 'GKlib_graph' ;
    else
        slash = strfind (ff, '/') ;
        if (isempty (slash))
            slash = 1 ;
        else
            slash = slash (end) + 1 ;
        end
        o = ff (slash:end) ;
    end
    % fprintf ('%s\n', o) ;
    o = [o obj_extension] ;
    obj = [obj  ' ' o] ;					            %#ok
    s = sprintf ('mex %s -O %s -c %s.c', flags, include, ff) ;
    kk = do_cmd (s, kk, details) ;
end


% compile each mexFunction
for f = spqr_mex_cpp_src
    s = sprintf ('mex %s -O %s %s.cpp', flags, include, f{1}) ;
    s = [s obj ' ' lib] ;                                                   %#ok
    kk = do_cmd (s, kk, details) ;
end

% clean up
s = ['delete ' obj] ;
status = warning ('off', 'MATLAB:DELETE:FileNotFound') ;
delete rename.h
warning (status) ;
do_cmd (s, kk, details) ;
fprintf ('\nSuiteSparseQR successfully compiled\n') ;

% remove the renamed METIS files, if they exist
if (exist ('GKlib_util.c', 'file'))
    delete ('GKlib_util.c') ;
end
if (exist ('GKlib_graph.c', 'file'))
    delete ('GKlib_graph.c') ;
end

%-------------------------------------------------------------------------------
function kk = do_cmd (s, kk, details)
%DO_CMD evaluate a command, and either print it or print a "."
if (details)
    fprintf ('%s\n', s) ;
else
    if (mod (kk, 60) == 0)
        fprintf ('\n') ;
    end
    kk = kk + 1 ;
    fprintf ('.') ;
end
eval (s) ;

