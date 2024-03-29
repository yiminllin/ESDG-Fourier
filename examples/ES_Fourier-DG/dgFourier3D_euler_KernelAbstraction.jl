using Revise # reduce recompilation time
using Plots
# using Documenter
using LinearAlgebra
using SparseArrays
using BenchmarkTools
using UnPack
using ToeplitzMatrices

using KernelAbstractions
using CUDAapi
using CuArrays
CuArrays.allowscalar(false)

push!(LOAD_PATH, "./src")
using CommonUtils
using Basis1D
using Basis2DTri
using UniformTriMesh

push!(LOAD_PATH, "./examples/EntropyStableEuler")
using EntropyStableEuler

using SetupDG

S_N(x) = @. sin(pi*x/h)/(2*pi/h)/tan(x/2)
"""
Vandermonde matrix of sinc basis functions determined by h,
evaluated at r
"""
function vandermonde_Sinc(h,r)
    N = convert(Int, 2*pi/h)
    V = zeros(length(r),N)
    for n = 1:N
        V[:,n] = S_N(r.-n*h)
    end
    V[1,1] = 1
    V[end,end] = 1
    return V
end

vector_norm(U) = CuArrays.sum((x->x.^2).(U))

"Constants"
const sp_tol = 1e-12
# const has_gpu = CUDAapi.has_cuda_gpu()
const enable_test = false
"Program parameters"
compute_L2_err = false

"Approximation Parameters"
N_P   = 2;    # The order of approximation in polynomial dimension
Np_P  = Int((N_P+1)*(N_P+2)/2)
Np_F  = 8;    # The order of approximation in Fourier dimension
K1D   = 10;   # Number of elements in polynomial (x,y) dimension
CFL   = 1.0;
T     = 0.5;  # End time

"Time integration Parameters"
rk4a,rk4b,rk4c = rk45_coeffs()
CN = (N_P+1)*(N_P+2)*3/2  # estimated trace constant for CFL
dt = CFL * 2 / CN / K1D
Nsteps = convert(Int,ceil(T/dt))
dt = T/Nsteps

"Initialize Reference Element in Fourier dimension"
h = 2*pi/Np_F
column = [0; .5*(-1).^(1:Np_F-1).*cot.((1:Np_F-1)*h/2)]
column2 = [-pi^2/3/h^2-1/6; -((-1).^(1:Np_F-1)./(2*(sin.((1:Np_F-1)*h/2)).^2))]
Dt = Array{Float64,2}(Toeplitz(column,column[[1;Np_F:-1:2]]))
D2t = Array{Float64,2}(Toeplitz(column2,column2[[1;Np_F:-1:2]]))
t = LinRange(h,2*pi,Np_F)


"Initialize Reference Element in polynomial dimension"
rd = init_reference_tri(N_P);
@unpack fv,Nfaces,r,s,VDM,V1,Dr,Ds,rf,sf,wf,nrJ,nsJ,rq,sq,wq,Vq,M,Pq,Vf,LIFT = rd
Nq_P = length(rq)
Nfp_P = length(rf)
Nh_P = Nq_P+Nfp_P # Number of hybridized points
Lq = LIFT

"Mesh related variables"
# First initialize 2D triangular mesh
VX,VY,EToV = uniform_tri_mesh(K1D,K1D)
@. VX = 1+VX
@. VY = 1+VY
md = init_mesh((VX,VY),EToV,rd)
VX = repeat(VX,2)
VY = repeat(VY,2)
VZ = [2/Np_F*ones((K1D+1)*(K1D+1),1); 2*ones((K1D+1)*(K1D+1),1)]
EToV = [EToV EToV.+(K1D+1)*(K1D+1)]

# Make domain periodic
@unpack Nfaces,Vf = rd
@unpack xf,yf,K,mapM,mapP,mapB = md
LX,LY = (x->maximum(x)-minimum(x)).((VX,VY)) # find lengths of domain
mapPB = build_periodic_boundary_maps(xf,yf,LX,LY,Nfaces*K,mapM,mapP,mapB)
mapP[mapB] = mapPB
@pack! md = mapP

# Initialize 3D mesh
@unpack x,y,xf,yf,xq,yq,rxJ,sxJ,ryJ,syJ,J,nxJ,nyJ,sJ,mapM,mapP,mapB = md
x,y,xf,yf,xq,yq,rxJ,sxJ,ryJ,syJ,J,nxJ,nyJ,sJ = (x->reshape(repeat(x,inner=(1,Np_F)),size(x,1),Np_F*K)).((x,y,xf,yf,xq,yq,rxJ,sxJ,ryJ,syJ,J,nxJ,nyJ,sJ))
z,zq,zf = (x->reshape(repeat(collect(2/Np_F:(2/Np_F):2),inner=(1,x),outer=(K,1))',x,Np_F*K)).((Np_P,Nq_P,Nfp_P))
mapM = reshape(1:Nfp_P*Np_P*K,Nfp_P,Np_P*K)
mapP_2D = (x->mod1(x,Nfp_P)+div(x-1,Nfp_P)*Nfp_P*Np_F).(mapP)
mapP = reshape(repeat(mapP_2D,inner=(1,Np_F)),Nfp_P,Np_F,K)
for j = 1:Np_F
    mapP[:,j,:] = mapP[:,j,:].+(j-1)*Nfp_P
end
mapP = reshape(mapP,Nfp_P,Np_F*K)

# scale by Fourier dimension
M = h*M
wq = h*wq
wf = h*wf

# Hybridized operators
Vh = [Vq;Vf]
rxJ,sxJ,ryJ,syJ = (x->mapslices((y->Vh*y),x,dims=(1,2))).((rxJ,sxJ,ryJ,syJ))
Ef = Vf*Pq
Br,Bs = (x->diagm(wf.*x)).((nrJ,nsJ))
Qr,Qs = (x->Pq'*M*x*Pq).((Dr,Ds))
Qrh,Qsh = (x->1/2*[x[1]-x[1]' Ef'*x[2];
                   -x[2]*Ef   x[2]]).(((Qr,Br),(Qs,Bs)))
Qrh_skew,Qsh_skew = (x->1/2*(x-x')).((Qrh,Qsh))
Qt = Dt
Qth = Qt # Not the SBP operator, weighted when flux differencing
Ph = [Vq;Vf]*Pq # TODO: refactor

# TODO: assume mesh uniform affine, so Jacobian are constants
# TODO: fix other Jacobian parts
JP = 1/K1D^2
JF = 1/pi
J = JF*JP
wq = J*wq
wf = JF*wf
Lq = 1/JP*Lq
Qrh = JF*Qrh
Qsh = JF*Qsh
Qth = JP*Qth
Qrh_skew = 1/2*(Qrh-Qrh')
Qsh_skew = 1/2*(Qsh-Qsh')
LIFTq = Vq*Lq

function flux_differencing_xy!(∇fh,Qh,Qlog,ops_flux,geo_flux,param_flux)
    K,Nq_P,Nh_P,Np_F,Nd = param_flux
    rxJ,sxJ,ryJ,syJ = geo_flux
    Qrh_skew,Qsh_skew,Qth,wq = ops_flux
    if isa(∇fh[1],Array)
        kernel! = update∇fh_xy_kernel!(CPU(),4)
    else
        kernel! = update∇fh_xy_kernel!(CUDA(),256)
    end
    kernel!(∇fh,Qh,Qlog,Qrh_skew,Qsh_skew,Nh_P,Np_F,Nd,rxJ,sxJ,ryJ,syJ,ndrange=(K,Np_F))
end

#TODO: clean up function arguments
@kernel function update∇fh_xy_kernel!(∇fh,Qh,Qlog,Qrh_skew,Qsh_skew,Nh_P,Np_F,Nd,rxJ_mat,sxJ_mat,ryJ_mat,syJ_mat)
    k,nf = @index(Global, NTuple)
    j = nf+Np_F*(k-1)
    # TODO: find a fix for not passing matrices?
    rxJ,sxJ,ryJ,syJ = rxJ_mat[1,j],sxJ_mat[1,j],ryJ_mat[1,j],syJ_mat[1,j]
    for col_idx = 1:Nh_P
        for row_idx = col_idx:Nh_P
            Fxj_tmp, Fyj_tmp,_ = euler_fluxes(Qh[1][row_idx,j],Qh[2][row_idx,j],Qh[3][row_idx,j],Qh[4][row_idx,j],Qh[5][row_idx,j],
                                               Qh[1][col_idx,j],Qh[2][col_idx,j],Qh[3][col_idx,j],Qh[4][col_idx,j],Qh[5][col_idx,j],
                                               Qlog[1][row_idx,j],Qlog[2][row_idx,j],
                                               Qlog[1][col_idx,j],Qlog[2][col_idx,j])
            var_Qrh = Qrh_skew[row_idx,col_idx]
            var_Qsh = Qsh_skew[row_idx,col_idx]
            for d = 1:Nd
                update_val = 2*((rxJ*var_Qrh+sxJ*var_Qsh)*Fxj_tmp[d]
                               +(ryJ*var_Qrh+syJ*var_Qsh)*Fyj_tmp[d])
                ∇fh[d][row_idx,j] += update_val
                ∇fh[d][col_idx,j] -= update_val
            end
        end
    end
    @synchronize(true)
end

function flux_differencing_z!(∇fh,Qh,Qlog,ops_flux,geo_flux,param_flux)
    K,Nq_P,Nh_P,Np_F,Nd = param_flux
    rxJ,sxJ,ryJ,syJ = geo_flux
    Qrh_skew,Qsh_skew,Qth,wq = ops_flux
    if isa(∇fh[1],Array)
        kernel! = update∇fh_z_kernel!(CPU(),4)
    else
        kernel! = update∇fh_z_kernel!(CUDA(),256)
    end
    kernel!(∇fh,Qth,Np_F,Nd,wq,J,Qlog,Qh,ndrange=(K,Nq_P))
end

# TODO: clean up
@kernel function update∇fh_z_kernel!(∇fh,Qth,Np_F,Nd,wq,J,Qlog,Qh)
    k,nh = @index(Global,NTuple)
    j_idx = (k-1)*Np_F+1:k*Np_F
    wqn = 2/J*wq[nh]
    for col_idx = 1:Np_F
        for row_idx = col_idx:Np_F
            _,_,f_tmp = euler_fluxes((x->x[nh,j_idx[row_idx]]).(Qh),(x->x[nh,j_idx[col_idx]]).(Qh),(x->x[nh,j_idx[row_idx]]).(Qlog),(x->x[nh,j_idx[col_idx]]).(Qlog))
            var_Qth = wqn*Qth[row_idx,col_idx]
            for i = 1:Nd
                ∇fh[i][nh,j_idx[row_idx]] += var_Qth*f_tmp[i]
                ∇fh[i][nh,j_idx[col_idx]] -= var_Qth*f_tmp[i]
            end
        end
    end
    @synchronize(true)
end

# Wrapper
function update_rhs_flux!(flux,QM,QP,QlogM,QlogP,Nh_P,Nq_P,K,Np_F,Nfp_P,Nd,Qh,nxJ,nyJ,Qlog)
    #=
    if isa(flux[1],Array)
        kernel! = update_rhs_flux_kernel!(CPU(),8)
    else
        kernel! = update_rhs_flux_kernel!(CUDA(),256)
    end
    =#
    kernel! = update_rhs_flux_kernel!(CUDA(),256)
    kernel!(flux,QM,QP,QlogM,QlogP,Nh_P,Nq_P,K,Np_F,Nfp_P,Nd,Qh,nxJ,nyJ,Qlog,ndrange=size(flux[1]))
end

@kernel function update_rhs_flux_kernel!(flux,QM,QP,QlogM,QlogP,Nh_P,Nq_P,K,Np_F,Nfp_P,Nd,Qh,nxJ,nyJ,Qlog)
    row_idx, col_idx = @index(Global,NTuple)

    # tmp_idx = mapP[row_idx+(col_idx-1)*Nfp_P]
    # r_idx = Nq_P+Nh_P*div(tmp_idx-1,Nfp_P)+mod1(tmp_idx,Nfp_P)
    # tmp_flux_x, tmp_flux_y,_ = euler_fluxes((x->x[Nq_P+row_idx,col_idx]).(Qh),(x->x[r_idx]).(Qh),
    #                                         (x->x[Nq_P+row_idx,col_idx]).(Qlog),(x->x[r_idx]).(Qlog))
    tmp_flux_x, tmp_flux_y, _ = euler_fluxes((x->x[row_idx,col_idx]).(QM), (x->x[row_idx,col_idx]).(QP),
                                             (x->x[row_idx,col_idx]).(QlogM), (x->x[row_idx,col_idx]).(QlogP))
    tmp_nxJ = nxJ[row_idx,col_idx]
    tmp_nyJ = nyJ[row_idx,col_idx]
    for d = 1:5
        # normal_flux(fx,fy,u) = fx.*nxJ + fy.*nyJ - LFc.*(u[mapP]-u)
        # TODO: Lax Friedrichs
        flux[d][row_idx,col_idx] = tmp_flux_x[d]*tmp_nxJ + tmp_flux_y[d]*tmp_nyJ
    end
    @synchronize(true)
end

function convert_u_to_v!(VU,Q)
    @. VU[4] = Q[2]^2+Q[3]^2+Q[4]^2 # rhoUnorm
    @. VU[5] = Q[5]-.5*VU[4]/Q[1] # rhoe
    tmp3 = @. CuArrays.log(0.4*VU[5]/(Q[1]^1.4))
    @. VU[1] = tmp3 # TODO: why need to store in tmp3?
    @. VU[1] = (-Q[5]+VU[5]*(2.4-VU[1]))/VU[5]
    @. VU[2] = Q[2]/VU[5]
    @. VU[3] = Q[3]/VU[5]
    @. VU[4] = Q[4]/VU[5]
    @. VU[5] = -Q[1]/VU[5]
end

function convert_v_to_u!(Qh)
    tmp = CuArray(zeros(Nh_P,K*Np_F))
    tmp2 = CuArray(zeros(Nh_P,K*Np_F))

    @. tmp = Qh[2]^2+Qh[3]^2+Qh[4]^2 #vUnorm
    @. tmp2 = (0.4/((-Qh[5])^1.4))^(1/0.4)*exp(-(1.4 - Qh[1] + tmp/(2*Qh[5]))/0.4) # rhoeV
    @. Qh[1] = tmp2.*(-Qh[5])
    @. Qh[2] = tmp2.*Qh[2]
    @. Qh[3] = tmp2.*Qh[3]
    @. Qh[4] = tmp2.*Qh[4]
    @. Qh[5] = tmp2.*(1-tmp/(2*Qh[5]))

    @. tmp = Qh[1]/(2*0.4*(Qh[5]-.5*(Qh[2]^2+Qh[3]^2+Qh[4]^2)/Qh[1])) #beta
    @. Qh[2] = Qh[2]./Qh[1]
    @. Qh[3] = Qh[3]./Qh[1]
    @. Qh[4] = Qh[4]./Qh[1]
    @. Qh[5] = tmp
end

VPh = Vq*[Pq Lq]*diagm(1 ./ [wq;wf])
# TODO: refactor
Vq,Vf,wq,wf,Pq,Lq,Qrh_skew,Qsh_skew,Qth,Ph,LIFTq,rxJ,sxJ,ryJ,syJ,sJ,nxJ,nyJ,VPh = (x->CuArray(x)).((Vq,Vf,wq,wf,Pq,Lq,Qrh_skew,Qsh_skew,Qth,Ph,LIFTq,rxJ,sxJ,ryJ,syJ,sJ,nxJ,nyJ,VPh))
ops = (Vq,Vf,wq,wf,Pq,Lq,Qrh_skew,Qsh_skew,Qth,Ph,LIFTq,VPh)
mesh = (rxJ,sxJ,ryJ,syJ,sJ,nxJ,nyJ,JP,JF,J,h,mapM,mapP)
param = (K,Np_P,Nfp_P,Np_F,Nq_P,Nh_P)

function rhs(Q,ops,mesh,param,compute_rhstest)

    Vq,Vf,wq,wf,Pq,Lq,Qrh_skew,Qsh_skew,Qth,Ph,LIFTq,VPh = ops
    rxJ,sxJ,ryJ,syJ,sJ,nxJ,nyJ,JP,JF,J,h,mapM,mapP = mesh
    K,Np_P,Nfp_P,Np_F,Nq_P,Nh_P = param
    Nd = length(Q) # number of components
    param_flux = (K,Nq_P,Nh_P,Np_F,Nd)
    geo_flux = (rxJ,sxJ,ryJ,syJ)
    ops_flux = (Qrh_skew,Qsh_skew,Qth,wq)
    
    # Entropy projection
    VU = (CuArray(zeros(Nq_P,K*Np_F)),CuArray(zeros(Nq_P,K*Np_F)),CuArray(zeros(Nq_P,K*Np_F)),CuArray(zeros(Nq_P,K*Np_F)),CuArray(zeros(Nq_P,K*Np_F)))
    convert_u_to_v!(VU,Q)
    Qh = (x->Ph*x).(VU)
    convert_v_to_u!(Qh)

    # Surface interpolation
    Qlog = (CuArrays.log.(Qh[1]),CuArrays.log.(Qh[5]))
    QM = (x->x[Nq_P+1:end,:]).(Qh)
    QlogM = (x->x[Nq_P+1:end,:]).(Qlog)
    QP = (x->x[mapP]).(QM)
    QlogP = (x->x[mapP]).(QlogM)

    # Surface Kernel 
    # TODO: implement Lax Friedrichs
    # TODO: storing flux, so avoid calculate flux on face quad point again?
    flux = (CuArray(zeros(Nfp_P,K*Np_F)),CuArray(zeros(Nfp_P,K*Np_F)),CuArray(zeros(Nfp_P,K*Np_F)),CuArray(zeros(Nfp_P,K*Np_F)),CuArray(zeros(Nfp_P,K*Np_F)))
    event = update_rhs_flux!(flux,QM,QP,QlogM,QlogP,Nh_P,Nq_P,K,Np_F,Nfp_P,Nd,Qh,nxJ,nyJ,Qlog)
    wait(event)
    flux = (x->LIFTq*x).(flux) # TODO: put it into update_rhs_flux!

    # Volume Kernel    
    # Flux differencing
    ∇fh = (CuArray(zeros(Nh_P,K*Np_F)),CuArray(zeros(Nh_P,K*Np_F)),CuArray(zeros(Nh_P,K*Np_F)),CuArray(zeros(Nh_P,K*Np_F)),CuArray(zeros(Nh_P,K*Np_F)))
    event = flux_differencing_xy!(∇fh,Qh,Qlog,ops_flux,geo_flux,param_flux)
    wait(event)
    event = flux_differencing_z!(∇fh,Qh,Qlog,ops_flux,geo_flux,param_flux)
    wait(event)
    ∇f = (x->VPh*x).(∇fh)

    # TODO: why changing K breaks the program?
    rhsQ = @. -(∇f+flux)

    if enable_test
        @show maximum.(VU)
        @show minimum.(VU)
        @show sum.(VU)
        @show maximum.(∇fh)
        @show minimum.(∇fh)
        @show sum.(∇fh)
        @show maximum.(rhsQ)
        @show minimum.(rhsQ)
        @show sum.(rhsQ)
        @show maximum.(flux)
        @show minimum.(flux)
        @show sum.(flux)
    end

    rhstest = 0
    if compute_rhstest
	for fld in eachindex(rhsQ)
            rhstest += sum(wq.*VU[fld].*rhsQ[fld])
        end
    end
    return rhsQ,rhstest
end


xq,yq,zq = (x->reshape(x,Nq_P,Np_F*K)).((xq,yq,zq))
# All directions
println(" ")
println("======= All directions =======")
ρ_exact(x,y,z,t) = @. 1+0.2*sin(pi*(x+y+z-3/2*t))
ρ = @. 1+0.2*sin(pi*(xq+yq+zq))
u = ones(size(xq))
v = -1/2*ones(size(xq))
w = ones(size(xq))
p = ones(size(xq))
Q_exact(x,y,z,t) = (ρ_exact(x,y,z,t),u,v,w,p)

Q = primitive_to_conservative(ρ,u,v,w,p)
Q = collect(Q)
resQ = [zeros(size(Q[1])) for _ in eachindex(Q)]
Q = [CuArray(Q[1]),CuArray(Q[2]),CuArray(Q[3]),CuArray(Q[4]),CuArray(Q[5])]
resQ = [CuArray(resQ[1]),CuArray(resQ[2]),CuArray(resQ[3]),CuArray(resQ[4]),CuArray(resQ[5])]
#rhs(Q,ops,mesh,param,false)
# @btime rhs(Q,ops,mesh,param,false)

@time begin
for i = 1:Nsteps
    rhstest = 0
    for INTRK = 1:5
	if enable_test
	@show "=================================="
	@show i
	@show INTRK	
	end
        compute_rhstest = INTRK==5
        rhsQ,rhstest = rhs(Q,ops,mesh,param,compute_rhstest)
        @. resQ = rk4a[INTRK]*resQ + dt*rhsQ
        @. Q += rk4b[INTRK]*resQ
    end

    if i%10==0 || i==Nsteps
        println("Time step: $i out of $Nsteps with rhstest = $rhstest")
    end
end

end # time

rq2,sq2,wq2 = quad_nodes_2D(N_P+2)
Vq2 = vandermonde_2D(N_P,rq2,sq2)/VDM
Vq2 = CuArray(Vq2)
Pq = CuArray(Pq)
x = CuArray(x)
y = CuArray(y)
z = CuArray(z)
xq2,yq2,zq2 = (x->Vq2*x).((x,y,z))
ρ = Vq2*Pq*Q[1]
ρ_ex = ρ_exact(xq2,yq2,zq2,T)
Q = (x->Vq2*Pq*x).(Q)

rhounorm = vector_norm((Q[1],Q[2],Q[3]))./Q[1]
p = @. 0.4*(Q[5]-.5*rhounorm)
Q = (Q[1],Q[2]./Q[1],Q[3]./Q[1],Q[4]./Q[1],p)
Q_ex = Q_exact(xq2,yq2,zq2,T)
Q_ex = (x->CuArray(x)).(Q_ex)
wq2 = CuArray(wq2)

L2_err = 0.0
for fld in eachindex(Q)
    global L2_err
    L2_err += sum(h*J*wq2.*(Q[fld]-Q_ex[fld]).^2)
end
println("L2err at final time T = $T is $L2_err\n")
#=
@show maximum.(Q)
@show maximum.(Q_ex)
@show minimum.(Q)
@show minimum.(Q_ex)
@show sum.(Q)
@show sum.(Q_ex)
=#
