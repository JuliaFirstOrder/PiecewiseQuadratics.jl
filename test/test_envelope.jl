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

function run_test(f::PiecewiseQuadratic, h::PiecewiseQuadratic)
    return (simplify(envelope(f)) ≈ h) && (simplify(envelope(reverse(f))) ≈ reverse(h))
end

function plot_test(f::PiecewiseQuadratic, h::PiecewiseQuadratic)
    clf()
    X, Y = get_plot(f)
    plot(X, Y)
    X, Y = get_plot(simplify(envelope(f)))
    plot(X, Y)
    X, Y = get_plot(h)
    plot(X, Y; linestyle=:dash)
    return legend(["f", "env(f)", "f**"])
end

@testset "Midpoint to endpoint" begin
    f = PiecewiseQuadratic([BoundedQuadratic(-Inf, 1.0, 1.0, 2.0, 2.0),
                            BoundedQuadratic(1.0, 1.0, 1.0, 2.0, 1.0),
                            BoundedQuadratic(1.0, Inf, 1.0, 2.0, 2.0)])
    h = PiecewiseQuadratic([BoundedQuadratic(-Inf, 0.0, 1.0, 2.0, 2.0),
                            BoundedQuadratic(0.0, 1.0, 0.0, 2.0, 2.0),
                            BoundedQuadratic(1.0, 2.0, 0.0, 6.0, -2.0),
                            BoundedQuadratic(2.0, Inf, 1.0, 2.0, 2.0)])
    @test run_test(f, h)
    @test run_test(reverse(f), reverse(h))
end

@testset "Convex functions" begin
    f = PiecewiseQuadratic([BoundedQuadratic(-Inf, 1.0, 0.0, -1.0, 1.0),
                            BoundedQuadratic(1.0, Inf, 0.0, 1.0, -1.0)])
    @test run_test(f, f)
    @test run_test(reverse(f), reverse(f))

    f = PiecewiseQuadratic([BoundedQuadratic(1.0, -2.0, 1.0)])
    @test run_test(f, f)
    @test run_test(reverse(f), reverse(f))
end

@testset "Nonconvex piecewise affine" begin
    f = PiecewiseQuadratic([BoundedQuadratic(-Inf, 1.0, 0.0, 1.0, 2.0),
                            BoundedQuadratic(1.0, 1.0, 0.0, 2.0, 0.0),
                            BoundedQuadratic(1.0, Inf, 0.0, 3.0, 0.0)])
    h = PiecewiseQuadratic([BoundedQuadratic(-Inf, 1.0, 0.0, 1.0, 1.0),
                            BoundedQuadratic(1.0, Inf, 0.0, 3.0, -1.0)])
    @test run_test(f, h)
    @test run_test(reverse(f), reverse(h))
end

@testset "Midpoint to midpoint" begin
    f = PiecewiseQuadratic([BoundedQuadratic(-Inf, 0.0, 1.0, 1.0, 1.0),
                            BoundedQuadratic(0.0, Inf, 1.0, -1.0, 1.0)])
    h = PiecewiseQuadratic([BoundedQuadratic(-Inf, -0.5, 1.0, 1.0, 1.0),
                            BoundedQuadratic(-0.5, 0.5, 0.0, 0.0, 0.75),
                            BoundedQuadratic(0.5, Inf, 1.0, -1.0, 1.0)])
    @test run_test(f, h)
end

@testset "Upper to lower" begin
    f = PiecewiseQuadratic([BoundedQuadratic(-Inf, 0.0, 1.0, -1.0, 1.0),
                            BoundedQuadratic(0.0, Inf, 1.0, 1.0, 1.0)])
    @test run_test(f, f)

    f = PiecewiseQuadratic([BoundedQuadratic(-Inf, 0.0, 0.0, -1.0, 1.0),
                            BoundedQuadratic(0.0, Inf, 0.0, 1.0, 1.0)])
    @test run_test(f, f)
end

@testset "Irrelevant point" begin
    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 0.0, 0.0, 0.0, 1.0),
                            BoundedQuadratic(0.0, Inf, 0.0, 1.0, 0.0)])
    h = PiecewiseQuadratic([BoundedQuadratic(0.0, Inf, 0.0, 1.0, 0.0)])
    @test run_test(f, h)
end

@testset "Relevant point" begin
    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 0.0, 0.0, 0.0, -1.0),
                            BoundedQuadratic(0.0, Inf, 0.0, 1.0, 0.0)])
    h = PiecewiseQuadratic([BoundedQuadratic(0.0, Inf, 0.0, 1.0, -1.0)])
    @test run_test(f, h)

    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 0.0, 0.0, 0.0, -1.0),
                            BoundedQuadratic(0.0, 1.0, 0.0, 1.0, 0.0)])
    h = PiecewiseQuadratic([BoundedQuadratic(0.0, 1.0, 0.0, 2.0, -1.0)])
    @test run_test(f, h)
end

@testset "Lower to upper" begin
    f = PiecewiseQuadratic([BoundedQuadratic(-1.0, 0.0, 0.0, 1.0, 1.0),
                            BoundedQuadratic(0.0, 1.0, 0.0, -1.0, 1.0)])
    h = PiecewiseQuadratic([BoundedQuadratic(-1.0, 1.0, 0.0, 0.0, 0.0)])
    @test run_test(f, h)
end

@testset "Upper to upper" begin
    f = PiecewiseQuadratic([BoundedQuadratic(-1.0, 0.0, 0.0, -1.0, 0.0),
                            BoundedQuadratic(0.0, 1.0, 0.0, -1.0, 1.0)])
    h = PiecewiseQuadratic([BoundedQuadratic(-1.0, 0.0, 0.0, -1.0, 0.0),
                            BoundedQuadratic(0.0, 1.0, 0.0, 0.0, 0.0)])
    @test run_test(f, h)
end

@testset "Two points" begin
    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 0.0, 0.0, 0.0, 1.0),
                            BoundedQuadratic(0.0, 0.0, 0.0, 0.0, 0.0)])
    h = PiecewiseQuadratic([BoundedQuadratic(0.0, 0.0, 0.0, 0.0, 0.0)])
    @test run_test(f, h)

    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 0.0, 0.0, 0.0, 0.0),
                            BoundedQuadratic(0.0, 0.0, 0.0, 0.0, 1.0)])
    h = PiecewiseQuadratic([BoundedQuadratic(0.0, 0.0, 0.0, 0.0, 0.0)])
    @test run_test(f, h)
end

@testset "Test case 1" begin
    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 1.0, 0.0, 0.0, 0.0),
                            BoundedQuadratic(1.0, 2.0, 0.0, 1.0, -1.0),
                            BoundedQuadratic(2.0, Inf, 1.0, -4.0, 5.0)])
    z1 = 0.8284271247461898
    z2 = 2.414213562373095
    h = PiecewiseQuadratic([BoundedQuadratic(0.0, 1.0, 0.0, 0.0, 0.0),
                            BoundedQuadratic(1.0, z2, 0.0, z1, -z1),
                            BoundedQuadratic(z2, Inf, 1.0, -4.0, 5.0)])

    @test run_test(f, h)
end

@testset "Test case 2" begin
    f = PiecewiseQuadratic([BoundedQuadratic(-2.0, -1.0, 0.0, 1.0, -1.0),
                            BoundedQuadratic(-1.0, 0.0, 0.0, 2.0, 0.0),
                            BoundedQuadratic(0.0, Inf, 0.0, 0.0, 0.0)])
    h = PiecewiseQuadratic([BoundedQuadratic(-2.0, Inf, 0.0, 0.0, -3.0)])

    @test run_test(f, h)
end

@testset "Test case 3" begin
    f = PiecewiseQuadratic([BoundedQuadratic(0.00000000000000000000, 0.02157170544841656434,
                                             11.64694718222335900748,
                                             -0.04528496679275312298,
                                             0.00031129231510998337),
                            BoundedQuadratic(0.02157170544841656434, 0.02157170544841656434,
                                             11.64694718222335900748,
                                             -0.04528496679275312298,
                                             0.00031129231510998337),
                            BoundedQuadratic(0.02157170544841656434, Inf,
                                             11.64694718222335900748,
                                             -0.04528497091670485170,
                                             0.00031129240407065537)])
    h = deepcopy(f)
    @test run_test(simplify(f), simplify(h))
end
