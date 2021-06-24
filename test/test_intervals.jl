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

@testset "Membership" begin
    S = Interval(2.0, 4.0)
    @test 3.0 ∈ S
    @test 2.0 ∈ S
    @test 4.0 ∈ S
    @test !(5.0 ∈ S)
end

@testset "Inclusion" begin
    @test Interval(2.0, 4.0) ⊆ Interval(1.0, 5.0)
    @test !(Interval(1.0, 5.0) ⊆ Interval(2.0, 4.0))
    @test !(Interval(2.0, 5.0) ⊆ Interval(1.0, 4.0))
end

@testset "Is empty" begin
    @test !isempty(Interval(2.0, 4.0))
    @test isempty(Interval(4.0, 2.0))
    @test !isempty(Interval(4.0, 4.0))
end

@testset "Equals" begin
    @test Interval(2.0, 4.0) == Interval(2.0, 4.0)
    @test !(Interval(2.0, 4.0) == Interval(3.0, 5.0))
    @test Interval(2.0, 4.0) != Interval(3.0, 5.0)
    @test !(Interval(2.0, 4.0) != Interval(2.0, 4.0))
end

@testset "Approx. Equals" begin
    ϵ = 1e-12
    @test !(Interval(2 + ϵ, 4 + ϵ) ≈ Interval(2.0, 4.0))
    ϵ /= 10
    @test Interval(2 + ϵ, 4 + ϵ) ≈ Interval(2.0, 4.0)
    @test !(Interval(2 + ϵ, 4 + ϵ) ≈ Interval(3.0, 5.0))
end

@testset "Intersection" begin
    @test Interval(2.0, 4.0) ∩ Interval(1.0, 5.0) ≈ Interval(2.0, 4.0)
    @test Interval(2.0, 5.0) ∩ Interval(1.0, 4.0) ≈ Interval(2.0, 4.0)
    @test Interval(1.0, 4.0) ∩ Interval(2.0, 5.0) ≈ Interval(2.0, 4.0)
    @test isempty(Interval(1.0, 2.0) ∩ Interval(4.0, 5))
end

@testset "Less than" begin
    @test Interval(2.0, 4.0) < Interval(5.0, 7.0)
    @test !(Interval(2.0, 4.0) < Interval(1.0, 3.0))
end

@testset "Greater than" begin
    @test Interval(5.0, 7.0) > Interval(2.0, 4.0)
    @test !(Interval(1.0, 3.0) > Interval(2.0, 4.0))
end
