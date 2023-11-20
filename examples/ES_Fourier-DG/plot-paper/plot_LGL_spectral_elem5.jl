using Plots
push!(LOAD_PATH, "./src")
using Basis2DTri
using Basis1D
using LaTeXStrings
theme(:wong)
gr(aspect_ratio=1,legend=nothing,axis=nothing,border=nothing,ticks=nothing,
   markerstrokewidth=0,markersize=1)

r1D, w1D = gauss_lobatto_quad(0,0,4)


plot([-1;-1],[-1;1],seriescolor=:black,lw=2,label = nothing)
plot!([-1;1],[1;1],seriescolor=:black,lw=2,label = nothing)
plot!([1;1],[1;-1],seriescolor=:black,lw=2,label = nothing)
plot!([1;-1],[-1;-1],seriescolor=:black,lw=2,label = nothing)
scatter!(r1D,ones(size(r1D)),markersize=5,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!(r1D,r1D[2]*ones(size(r1D)),markersize=5,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!(r1D,zeros(size(r1D)),markersize=5,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!(r1D,r1D[4]*ones(size(r1D)),markersize=5,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!(r1D,-1*ones(size(r1D)),markersize=5,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)

plot!([-1;-1].-0.2,[-1;1],seriescolor=:black,lw=2,label = nothing)
plot!([-1;1],[1;1].+0.2,seriescolor=:black,lw=2,label = nothing)
plot!([1;1].+0.2,[1;-1],seriescolor=:black,lw=2,label = nothing)
plot!([1;-1],[-1;-1].-0.2,seriescolor=:black,lw=2,label = nothing)

scatter!(-1.2*ones(size(r1D)),r1D,markersize=5,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!(1.2*ones(size(r1D)),r1D,markersize=5,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!(r1D,1.2*ones(size(r1D)),markersize=5,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!(r1D,-1.2*ones(size(r1D)),markersize=5,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)

scatter!(r1D,ones(size(r1D)),markersize=7,markercolor=:darkorange1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!(zeros(size(r1D)),r1D,markersize=7,markercolor=:darkorange1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!([0.0],[1.0],markersize=7,markercolor=:springgreen2,markerstrokecolor=:black,markerstrokewidth=2)
scatter!([0.0],[1.2],markersize=7,markercolor=:darkorange1,markerstrokecolor=:black,markerstrokewidth=2)

# scatter!(r1D.+2,ones(size(r1D)),markersize=7,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
# scatter!(r1D.+2,r1D[2]*ones(size(r1D)),markersize=7,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
# scatter!(r1D.+2,zeros(size(r1D)),markersize=7,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
# scatter!(r1D.+2,r1D[4]*ones(size(r1D)),markersize=7,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
# scatter!(r1D.+2,-1*ones(size(r1D)),markersize=7,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)

savefig("~/Desktop/LGL_spectral_elem_5.png")