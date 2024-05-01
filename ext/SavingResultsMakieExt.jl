module SavingResultsMakieExt

using GivEmExel

using Makie

isplot(::P ) where P <: Union{Makie.Figure, Makie.AbstractScene, Makie.AbstractPlot} = true

_saveplot(pl::P, fl) where P <: Union{Makie.Figure, Makie.AbstractScene, Makie.AbstractPlot} = Makie.save(fl, pl)

"""
FileIO.save(filename, scene; size = size(scene), pt_per_unit = 0.75, px_per_unit = 1.0)

julia> supertype(Figure)
Any

julia> subtypes(Figure)
Type[]

julia> supertype(Scene)
AbstractScene

julia> supertype(AbstractScene)
MakieCore.Transformable

julia> subtypes(MakieCore.Transformable)
3-element Vector{Any}:
 AbstractPlot
 AbstractScene
 Transformation

julia> Makie.AxisPlot
Makie.AxisPlot

julia> supertype(ans)
Any
julia> Makie.FigureAxisPlot
Makie.FigureAxisPlot

julia> supertype(ans)
Any 

julia> Scatter
Scatter (alias for Plot{MakieCore.scatter})

julia> supertype(ans)
MakieCore.ScenePlot{MakieCore.scatter}

julia> supertype(ans)
AbstractPlot{MakieCore.scatter}

"""
end