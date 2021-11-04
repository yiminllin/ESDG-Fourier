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

count = 0
for i = (1:3:8*3).+8
    j = 10
    plot!([-1;-1].+i,[-1;2].+j,seriescolor=:black,lw=3,label = nothing)
    plot!([-1;2].+i,[2;2].+j,seriescolor=:black,lw=3,label = nothing)
    plot!([2;2].+i,[2;-1].+j,seriescolor=:black,lw=3,label = nothing)
    plot!([2;-1].+i,[-1;-1].+j,seriescolor=:black,lw=3,label = nothing)
    if (count < 2)
        scatter!([0.5;0.5].+i,[0.5;0.5].+j,markersize=12.5,markercolor=:darkred,markershape=:rect,label=nothing)
    elseif (count < 4)
        scatter!([0.5;0.5].+i,[0.5;0.5].+j,markersize=12.5,markercolor=:darkorange1,markershape=:rect,label=nothing)
    elseif (count < 6)
        scatter!([0.5;0.5].+i,[0.5;0.5].+j,markersize=12.5,markercolor=:aquamarine4,markershape=:rect,label=nothing)
    else
        scatter!([0.5;0.5].+i,[0.5;0.5].+j,markersize=12.5,markercolor=:royalblue1,markershape=:rect,label=nothing)
    end
    global count = count+1
end


for j = 0:2:2
    for i = 0:2:6
        plot!([-1;-1].+i,[-1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([-1;1].+i,[1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;1].+i,[1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;-1].+i,[-1;-1].+j,seriescolor=:black,lw=3,label = nothing)
    end
end

for j = 0:2:2
    for i = (0:2:6) .+ 12
        plot!([-1;-1].+i,[-1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([-1;1].+i,[1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;1].+i,[1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;-1].+i,[-1;-1].+j,seriescolor=:black,lw=3,label = nothing)
    end
end

for j = 0:2:2
    for i = (0:2:6) .+ 24
        plot!([-1;-1].+i,[-1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([-1;1].+i,[1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;1].+i,[1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;-1].+i,[-1;-1].+j,seriescolor=:black,lw=3,label = nothing)
    end
end

for j = 0:2:2
    for i = (0:2:6) .+ 36
        plot!([-1;-1].+i,[-1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([-1;1].+i,[1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;1].+i,[1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;-1].+i,[-1;-1].+j,seriescolor=:black,lw=3,label = nothing)
    end
end

############
#  Step 1 
############

count = 0
for j = (2:-2:0) .- 12
    for i = 0:2:6
        plot!([-1;-1].+i,[-1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([-1;1].+i,[1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;1].+i,[1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;-1].+i,[-1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        if (count < 2)
            scatter!([0;0].+i,[0;0].+j,markersize=8,markercolor=:darkred,markershape=:rect,label=nothing)
        elseif (count < 4)
            scatter!([0;0].+i,[0;0].+j,markersize=8,markercolor=:darkorange1,markershape=:rect,label=nothing)
        end
        global count = count + 1
    end
end



for j = (0:2:2) .- 12
    for i = (0:2:6) .+ 12
        plot!([-1;-1].+i,[-1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([-1;1].+i,[1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;1].+i,[1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;-1].+i,[-1;-1].+j,seriescolor=:black,lw=3,label = nothing)
    end
end

count = 0
for j = (2:-2:0) .- 12
    for i = (0:2:6) .+ 24
        plot!([-1;-1].+i,[-1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([-1;1].+i,[1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;1].+i,[1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;-1].+i,[-1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        if (count < 2)
            scatter!([0;0].+i,[0;0].+j,markersize=8,markercolor=:aquamarine4,markershape=:rect,label=nothing)
        elseif (count < 4)
            scatter!([0;0].+i,[0;0].+j,markersize=8,markercolor=:royalblue1,markershape=:rect,label=nothing)
        end
        global count = count + 1
    end
end

for j = (0:2:2) .- 12
    for i = (0:2:6) .+ 36
        plot!([-1;-1].+i,[-1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([-1;1].+i,[1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;1].+i,[1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;-1].+i,[-1;-1].+j,seriescolor=:black,lw=3,label = nothing)
    end
end


############
#  Step 2 
############

count = 0
for j = (2:-2:0) .- 12*2
    for i = 0:2:6
        plot!([-1;-1].+i,[-1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([-1;1].+i,[1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;1].+i,[1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;-1].+i,[-1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        if (count < 2)
            scatter!([0;0].+i,[0;0].+j,markersize=8,markercolor=:darkred,markershape=:rect,label=nothing)
        end
        global count = count + 1
    end
end

count = 0
for j = (2:-2:0) .- 12*2
    for i = (0:2:6) .+ 12
        plot!([-1;-1].+i,[-1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([-1;1].+i,[1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;1].+i,[1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;-1].+i,[-1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        if (count < 2)
            scatter!([0;0].+i,[0;0].+j,markersize=8,markercolor=:darkorange1,markershape=:rect,label=nothing)
        end
        global count = count + 1
    end
end

count = 0
for j = (2:-2:0) .- 12*2
    for i = (0:2:6) .+ 24
        plot!([-1;-1].+i,[-1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([-1;1].+i,[1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;1].+i,[1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;-1].+i,[-1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        if (count < 2)
            scatter!([0;0].+i,[0;0].+j,markersize=8,markercolor=:aquamarine4,markershape=:rect,label=nothing)
        end
        global count = count + 1
    end
end

count = 0
for j = (2:-2:0) .- 12*2
    for i = (0:2:6) .+ 36
        plot!([-1;-1].+i,[-1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([-1;1].+i,[1;1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;1].+i,[1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        plot!([1;-1].+i,[-1;-1].+j,seriescolor=:black,lw=3,label = nothing)
        if (count < 2)
            scatter!([0;0].+i,[0;0].+j,markersize=8,markercolor=:royalblue1,markershape=:rect,label=nothing)
        end
        global count = count + 1
    end
end


plot!([0;0],[0;0],seriescolor=:black,lw=3,label = nothing)
savefig("IO.png")