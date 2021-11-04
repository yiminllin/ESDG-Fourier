using Plots
push!(LOAD_PATH, "./src")
using Basis2DTri
using Basis1D
using LaTeXStrings
theme(:wong)
gr(aspect_ratio=1,legend=nothing,axis=nothing,border=nothing,ticks=nothing,
   markerstrokewidth=0,markersize=1)

Q_GLegendre_rq_N3 = [-0.861136311594054,-0.339981043584857,0.339981043584856,0.861136311594053,-1.000000000000000,-1.000000000000000,-1.000000000000000,-1.000000000000000,-0.861136311594054,-0.339981043584857,0.339981043584856,0.861136311594053,0.168314227951316,-0.542461986333870,0.168314227951316,-0.625852241617446,-0.542461986333870,-0.625852241617446];
Q_GLegendre_sq_N3 = [-1.000000000000000,-1.000000000000000,-1.000000000000000,-1.000000000000000,-0.861136311594054,-0.339981043584857,0.339981043584856,0.861136311594053,0.861136311594054,0.339981043584857,-0.339981043584856,-0.861136311594053,-0.542461986333870,0.168314227951316,-0.625852241617446,0.168314227951316,-0.625852241617446,-0.542461986333870];
 
r1D, w1D = gauss_lobatto_quad(0,0,4)


plot([-1;-1],[-1;1],seriescolor=:black,lw=3,label = nothing)
scatter!([-0.542461986333870],[0.168314227951316],markersize=100,size=(500,500),markerstrokestyles=:dot,markerstrokecolor=:grey,markerstrokewidth=2,markercolor=:white)
plot!([-1;1],[1;-1],seriescolor=:black,lw=3,label = nothing)
plot!([1;-1],[-1;-1],seriescolor=:black,lw=3,label = nothing)
#plot!([r1D[2];r1D[4]],[0;0],seriescolor=:grey,linestyle=:dash,lw=3,label = nothing)
#plot!([0;0],[r1D[2];r1D[4]],seriescolor=:grey,linestyle=:dash,lw=3,label = nothing)
scatter!(Q_GLegendre_rq_N3, Q_GLegendre_sq_N3,markersize=5,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!([-0.542461986333870;-0.625852241617446;-0.339981043584857], [0.168314227951316;0.168314227951316;0.339981043584857],markersize=5,markershape=:rect,markercolor=:darkorange1,markerstrokecolor=:black,markerstrokewidth=2)
plot!([-0.54246198633387,-0.625852241617446],[0.168314227951316;0.168314227951316],seriescolor=:grey,linestyle=:dash,lw=3,label = nothing)
plot!([-0.54246198633387,-0.339981043584857],[0.168314227951316;0.339981043584857],seriescolor=:grey,linestyle=:dash,lw=3,label = nothing)
# scatter!(r1D,ones(size(r1D)),markersize=7,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
# scatter!(r1D,r1D[2]*ones(size(r1D)),markersize=7,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
# scatter!(r1D,zeros(size(r1D)),markersize=7,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
# scatter!(r1D,r1D[4]*ones(size(r1D)),markersize=7,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
# scatter!(r1D,-1*ones(size(r1D)),markersize=7,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
# scatter!([0;r1D[2];0;r1D[4];0],[r1D[2];0;0;0;r1D[4]],markersize=7,markershape=:rect,markercolor=:darkorange1,markerstrokecolor=:black,markerstrokewidth=2)
#scatter!(r1D[2:4],ones(3),markersize=7,markershape=:rect,markercolor=:darkorange1,markerstrokecolor=:black,markerstrokewidth=2)
savefig("SBP_quad.png")