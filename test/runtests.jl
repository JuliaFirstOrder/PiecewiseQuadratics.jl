#=
Copyright 2021 BlackRock, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=#

using PiecewiseQuadratics
using Documenter
using Test

@testset "Doctests" begin
    DocMeta.setdocmeta!(PiecewiseQuadratics, :DocTestSetup, :(using PiecewiseQuadratics);
                        recursive=true)
    #= TODO: doctests fail with Julia 1.0...
    1. it appears that the output of `Vector{T}` displays as `Array{T,1}` instead
        this causes intersect(f_list::Vector{BoundedQuadratic}) to fail
    2. MethodError: no method matching range(::Float64, ::Float64; length=10)
        this causes get_plot(f::PiecewiseQuadratic; N::Int64=1000) to fail
    =#
    @test_skip doctest(PiecewiseQuadratics)
end

@testset "Intervals" begin
    include("test_intervals.jl")
end
@testset "Bounded Quadratics" begin
    include("test_bounded_quadratics.jl")
end
@testset "Piecewise Quadratics" begin
    include("test_piecewise_quadratics.jl")
end
@testset "Convex envelope" begin
    include("test_envelope.jl")
end
