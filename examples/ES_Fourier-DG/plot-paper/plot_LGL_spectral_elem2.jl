using Plots
push!(LOAD_PATH, "./src")
using Basis2DTri
using Basis1D
using LaTeXStrings
theme(:wong)
gr(aspect_ratio=1,legend=nothing,axis=nothing,border=nothing,ticks=nothing,
   markerstrokewidth=0,markersize=1)

r1D, w1D = gauss_lobatto_quad(0,0,4)


plot([-1;-1],[-1;1],seriescolor=:black,lw=3,label = nothing)
plot!([-1;1],[1;1],seriescolor=:black,lw=3,label = nothing)
plot!([1;1],[1;-1],seriescolor=:black,lw=3,label = nothing)
plot!([1;-1],[-1;-1],seriescolor=:black,lw=3,label = nothing)
scatter!(r1D,ones(size(r1D)),markersize=7,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!(r1D,r1D[2]*ones(size(r1D)),markersize=7,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!(r1D,zeros(size(r1D)),markersize=7,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!(r1D,r1D[4]*ones(size(r1D)),markersize=7,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!(r1D,-1*ones(size(r1D)),markersize=7,markercolor=:royalblue1,markerstrokecolor=:black,markerstrokewidth=2)

plot!([-1;-1].+2.5,[-1;1],seriescolor=:black,lw=3,label = nothing)
plot!([-1;1].+2.5,[1;1],seriescolor=:black,lw=3,label = nothing)
plot!([1;1].+2.5,[1;-1],seriescolor=:black,lw=3,label = nothing)
plot!([1;-1].+2.5,[-1;-1],seriescolor=:black,lw=3,label = nothing)
scatter!(r1D.+2.5,ones(size(r1D)),markersize=7,markercolor=:darkorange1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!(r1D.+2.5,r1D[2]*ones(size(r1D)),markersize=7,markercolor=:darkorange1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!(r1D.+2.5,zeros(size(r1D)),markersize=7,markercolor=:darkorange1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!(r1D.+2.5,r1D[4]*ones(size(r1D)),markersize=7,markercolor=:darkorange1,markerstrokecolor=:black,markerstrokewidth=2)
scatter!(r1D.+2.5,-1*ones(size(r1D)),markersize=7,markercolor=:darkorange1,markerstrokecolor=:black,markerstrokewidth=2)

savefig("LGL_spectral_elem_2.png")