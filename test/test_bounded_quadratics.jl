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

@testset "Negative" begin
    f = BoundedQuadratic(0.0, 3.0, 0.0, 3.0, 4.0)
    g = BoundedQuadratic(0.0, 3.0, 0.0, -3.0, -4.0)
    @test -f ≈ g
end

@testset "Evaluate" begin
    f = BoundedQuadratic(0.0, 3.0, 1.0, 3.0, 4.0)
    @test f(2.0) ≈ 2^2 + 3 * 2 + 4
    @test f(4.0) == Inf
end

@testset "Reverse" begin
    f = BoundedQuadratic(0.0, 3.0, 1.0, 3.0, 4.0)
    g = BoundedQuadratic(-3.0, 0.0, 1.0, -3.0, 4.0)
    @test reverse(f) ≈ g
end

@testset "Continous and Overlapping?" begin
    f = BoundedQuadratic(0.0, 3.0, 0.0, 0.0, 4.0)
    g = BoundedQuadratic(3.0, 4.0, 0.0, 0.0, 4.0)
    h = BoundedQuadratic(3.0, 4.0, 0.0, 0.0, 3.0)
    @test continuous_and_overlapping(f, g)
    @test !continuous_and_overlapping(f, h)
end

@testset "Add_scalar" begin
    f = BoundedQuadratic(0.0, 3.0, 1.0, 2.0, 4.0)
    g = BoundedQuadratic(0.0, 3.0, 1.0, 2.0, 5.0)
    @test f + 1.0 ≈ g
end

@testset "Intersect" begin
    f = BoundedQuadratic(0.0, 10.0, 1.0, 2.0, 4.0)
    g = BoundedQuadratic(1.0, 9.0, 1.0, 2.0, 5.0)
    h = BoundedQuadratic(2.0, 8.0, 1.0, 2.0, 5.0)

    fun_list, is_valid = intersect([f, g, h])
    @test is_valid
    for fi in fun_list
        @test fi.lb == 2.0
        @test fi.ub == 8.0
    end

    h = BoundedQuadratic(20.0, 30.0, 1.0, 2.0, 5.0)
    fun_list, is_valid = intersect([f, g, h])
    @test !is_valid
end

@testset "Get tangent" begin
    f = BoundedQuadratic(0.0, 10.0, 1.0, 0.0, 0.0)
    g = BoundedQuadratic(0.0, 2.0, -1.0)
    @test g ≈ get_tangent(f, 1.0)
end

@testset "Restrict domain" begin
    f = BoundedQuadratic(0.0, 10.0, 1.0, 2.0, 4.0)
    g = BoundedQuadratic(0.0, 8.0, 1.0, 2.0, 4.0)
    @test g ≈ restrict_dom(f, -2.0, 8.0)
end

@testset "Extend domain" begin
    f = BoundedQuadratic(0.0, 10.0, 1.0, 2.0, 4.0)
    g = BoundedQuadratic(1.0, 2.0, 4.0)
    @test g ≈ extend_dom(f)
end

@testset "Is point?" begin
    f = BoundedQuadratic(0.0, 10.0, 1.0, 2.0, 4.0)
    @test !is_point(f)

    f = BoundedQuadratic(0.0, 0.0, 1.0, 2.0, 4.0)
    @test is_point(f)
end

@testset "Scalar multiplication" begin
    f = BoundedQuadratic(0.0, 10.0, 1.0, 2.0, 4.0)
    g = BoundedQuadratic(0.0, 10.0, 3.0, 6.0, 12.0)
    @test 3.0 * f ≈ g
    @test f * 3.0 ≈ g
end

@testset "Sum" begin
    f = BoundedQuadratic(0.0, 8.0, 1.0, 2.0, 4.0)
    g = BoundedQuadratic(2.0, 10.0, 3.0, 0.0, 2.0)
    h = BoundedQuadratic(2.0, 8.0, 4.0, 2.0, 6.0)
    @test f + g ≈ h
    @test sum([f, g]) ≈ h
end

@testset "Shift" begin
    g = BoundedQuadratic(0, 5, 1, 2, 4)
    @test shift(g, 5.0) ≈ BoundedQuadratic(5, 10, 1, -8, 19)
end

@testset "Scale" begin
    g = BoundedQuadratic(0, 5, 1, 2, 4)
    @test scale(g, 5.0) ≈ BoundedQuadratic(0, 1, 25, 10, 4)
end

@testset "Tilt" begin
    g = BoundedQuadratic(0, 5, 1, 2, 4)
    tilt!(g, 5.0)
    @test g ≈ BoundedQuadratic(0, 5, 1, 7, 4)
end

@testset "Perspective" begin
    g = BoundedQuadratic(0, 5, 1, 2, 4)
    @test perspective(g, 5.0) ≈ BoundedQuadratic(0, 25, 0.2, 2, 20)
end
