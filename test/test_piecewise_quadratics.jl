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

@testset "Zero" begin
    @test zero(PiecewiseQuadratic) ≈ PiecewiseQuadratic(BoundedQuadratic(0.0, 0.0, 0.0))
end

@testset "Simplify" begin

    # Unsimplifiable.
    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 3.0, 0.0, 3.0, 4.0),
                            BoundedQuadratic(3.0, 4.0, 1.0, 3.0, 4.0)])
    @test simplify(f) ≈ f

    # One non-redundant point.
    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 3.0, 0.0, 0.0, 4.0),
                            BoundedQuadratic(3.0, 3.0, 0.0, 0.0, 1.0),
                            BoundedQuadratic(3.0, 4.0, 0.0, 0.0, 3.0)])
    @test simplify(f) ≈ f

    # Redundant point (left end).
    f = PiecewiseQuadratic([BoundedQuadratic(3.0, 3.0, 0.0, 0.0, 5.0),
                            BoundedQuadratic(3.0, 3.0, 0.0, 0.0, 1.0),
                            BoundedQuadratic(3.0, 4.0, 0.0, 0.0, 3.0)])
    g = PiecewiseQuadratic([BoundedQuadratic(3.0, 3.0, 0.0, 0.0, 1.0),
                            BoundedQuadratic(3.0, 4.0, 0.0, 0.0, 3.0)])
    @test simplify(f) ≈ g

    # Redundant point (right end).
    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 3.0, 0.0, 0.0, 10.0),
                            BoundedQuadratic(3.0, 4.0, 0.0, 0.0, 3.0),
                            BoundedQuadratic(4.0, 4.0, 0.0, 0.0, 10.0)])
    g = PiecewiseQuadratic([BoundedQuadratic(0.0, 3.0, 0.0, 0.0, 10.0),
                            BoundedQuadratic(3.0, 4.0, 0.0, 0.0, 3.0)])
    @test simplify(f) ≈ g

    # Redundant point (left).
    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 3.0, 0.0, 0.0, 4.0),
                            BoundedQuadratic(3.0, 3.0, 0.0, 0.0, 10.0),
                            BoundedQuadratic(3.0, 3.0, 0.0, 0.0, 50.0),
                            BoundedQuadratic(3.0, 4.0, 0.0, 0.0, 20.0)])
    g = PiecewiseQuadratic([BoundedQuadratic(0.0, 3.0, 0.0, 0.0, 4.0),
                            BoundedQuadratic(3.0, 4.0, 0.0, 0.0, 20.0)])
    @test simplify(f) ≈ g

    # Redundant point (right).
    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 3.0, 0.0, 0.0, 20.0),
                            BoundedQuadratic(3.0, 3.0, 0.0, 0.0, 10.0),
                            BoundedQuadratic(3.0, 3.0, 0.0, 0.0, 50.0),
                            BoundedQuadratic(3.0, 4.0, 0.0, 0.0, 4.0)])
    g = PiecewiseQuadratic([BoundedQuadratic(0.0, 3.0, 0.0, 0.0, 20.0),
                            BoundedQuadratic(3.0, 4.0, 0.0, 0.0, 4.0)])
    @test simplify(f) ≈ g

    # All points in constructor
    point = BoundedQuadratic(0, 0, 0, 0, 0)
    f = PiecewiseQuadratic(repeat([point], 5))
    @test simplify(f) ≈ PiecewiseQuadratic(point)

    # No redundant point (because of right gap).
    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 3.0, 0.0, 0.0, 20.0),
                            BoundedQuadratic(3.0, 3.0, 0.0, 0.0, 10.0),
                            BoundedQuadratic(4.0, 5.0, 0.0, 0.0, 4.0)])
    @test simplify(f) ≈ f

    # No redundant point (because of left gap).
    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 2.0, 0.0, 0.0, 4.0),
                            BoundedQuadratic(3.0, 3.0, 0.0, 0.0, 10.0),
                            BoundedQuadratic(3.0, 4.0, 0.0, 0.0, 20.0)])
    @test simplify(f) ≈ f

    # Complex
    f = PiecewiseQuadratic([BoundedQuadratic(-1.0, 0.0, 0.0, -1.0, 0.0),
                            BoundedQuadratic(0.0, 0.0, 0.0, 0.0, 0.0),
                            BoundedQuadratic(0.0, 1.0, 0.0, 1.0, 0.0),
                            BoundedQuadratic(1.0, 2.0, 0.0, 1.0, 0.0),
                            BoundedQuadratic(3.0, 5.0, 1.0, 1.0, 1)])
    g = PiecewiseQuadratic([BoundedQuadratic(-1.0, 0.0, 0.0, -1.0, 0.0),
                            BoundedQuadratic(0.0, 2.0, 0.0, 1.0, 0.0),
                            BoundedQuadratic(3.0, 5.0, 1.0, 1.0, 1.0)])
    @test simplify(f) ≈ g

    # Simplify in constructor
    f = PiecewiseQuadratic([BoundedQuadratic(-1.0, 0.0, 0.0, -1.0, 0.0),
                            BoundedQuadratic(0.0, 0.0, 0.0, 0.0, 0.0),
                            BoundedQuadratic(0.0, 1.0, 0.0, 1.0, 0.0),
                            BoundedQuadratic(1.0, 2.0, 0.0, 1.0, 0.0),
                            BoundedQuadratic(3.0, 5.0, 1.0, 1.0, 1)]; simplify_result=true)
    @test f ≈ g
end

@testset "Minimize" begin
    f = PiecewiseQuadratic([BoundedQuadratic(1.0, 2.0, 0.0, 0.0, 14.0),
                            BoundedQuadratic(2.0, 3.0, 0.0, 0.0, 24.0),
                            BoundedQuadratic(3.0, 4.0, 0.0, 0.0, 23.0)])
    @test minimize(f) == (1.0, 14.0)
end

@testset "Evaluate" begin
    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 3.0, 0.0, 0.0, 4.0),
                            BoundedQuadratic(3.0, 3.1, 0.0, 0.0, 1.0),
                            BoundedQuadratic(3.0, 4.0, 0.0, 0.0, 3.0)])
    @test f(2.0) ≈ 4.0
    @test f.([3.001, 3.05, 3.099]) ≈ ones(3)
    @test f(10.0) == Inf
end

@testset "Sum" begin
    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 3.0, 0.0, 0.0, 4.0),
                            BoundedQuadratic(3.0, 4.0, 0.0, 0.0, 3.0)])

    g = PiecewiseQuadratic([BoundedQuadratic(1.0, 2.0, 0.0, 0.0, 10.0),
                            BoundedQuadratic(2.0, 5.0, 0.0, 0.0, 20.0)])

    h = PiecewiseQuadratic([BoundedQuadratic(1.0, 2.0, 0.0, 0.0, 14.0),
                            BoundedQuadratic(2.0, 3.0, 0.0, 0.0, 24.0),
                            BoundedQuadratic(3.0, 4.0, 0.0, 0.0, 23.0)])

    @test f + g ≈ h
    @test g + f ≈ h
    @test sum([f, g, h]) ≈ 2.0 * h

    bq = BoundedQuadratic(0.0, 10.0, 1.0, 2.0, 4.0)
    exp = PiecewiseQuadratic([BoundedQuadratic(0.0, 3.0, 1.0, 2.0, 8.0),
                              BoundedQuadratic(3.0, 4.0, 1.0, 2.0, 7.0)])
    @test f + bq ≈ exp
end

@testset "Sum with disjoint domain" begin
    f1 = PiecewiseQuadratic([BoundedQuadratic(1.0, 1.0, 0.0)])
    f2 = PiecewiseQuadratic([BoundedQuadratic(-Inf, -1.0, 0.0, 0.0, 0.0)])
    f3 = PiecewiseQuadratic([BoundedQuadratic(1.0, Inf, 0.0, 0.0, 0.0)])
    h = sum([f1, f2, f3])
    h_true = PiecewiseQuadratic(BoundedQuadratic[])
    @test h ≈ h_true
end

@testset "Proximal operator" begin
    # Affine.
    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 3.0, 0.0)])
    @test prox(f, 5.0, 1.0) ≈ 2.0

    # Huber.
    μ = 1.0
    f = PiecewiseQuadratic([BoundedQuadratic(-Inf, -μ, 0.0, -μ, -μ^2 / 2),
                            BoundedQuadratic(-μ, μ, 0.5, 0.0, 0.0),
                            BoundedQuadratic(μ, Inf, 0.0, μ, -μ^2 / 2)])

    for u in [-5.0, 1.0, 3.0]
        for ρ in [0.1, 1.0, 10]
            σ = 1 / ρ
            prox_f = u - σ * u / max(abs(u), σ + 1)
            @test prox(f, u, ρ) ≈ prox_f
        end
    end

    # Indicator.
    f = indicator(-1, 1)

    for u in [-5.0, 0, 1.0, 3.0]
        for ρ in [0.1, 1.0, 10]
            prox_f = min(max(u, -1), 1)
            @test prox(f, u, ρ) ≈ prox_f
        end
    end
end

@testset "Shift" begin
    f = PiecewiseQuadratic([BoundedQuadratic(0, 5, 1, 2, 4)])
    shift!(f, 5.0)
    @test f ≈ PiecewiseQuadratic([BoundedQuadratic(5, 10, 1, -8, 19)])
end

@testset "Scale" begin
    f = PiecewiseQuadratic([BoundedQuadratic(0, 5, 1, 2, 4)])
    scale!(f, 5.0)
    @test f ≈ PiecewiseQuadratic([BoundedQuadratic(0, 1, 25, 10, 4)])
end

@testset "Tilt" begin
    f = PiecewiseQuadratic([BoundedQuadratic(0, 5, 1, 2, 4)])
    tilt!(f, 5.0)
    @test f ≈ PiecewiseQuadratic([BoundedQuadratic(0, 5, 1, 7, 4)])
end

@testset "Perspective" begin
    f = PiecewiseQuadratic([BoundedQuadratic(0, 5, 1, 2, 4)])
    perspective!(f, 5.0)
    @test f ≈ PiecewiseQuadratic([BoundedQuadratic(0, 25, 0.2, 2, 20)])
end

@testset "Scalar multiplication" begin
    f = PiecewiseQuadratic([BoundedQuadratic(0.0, 10.0, 1.0, 2.0, 4.0)])
    g = PiecewiseQuadratic([BoundedQuadratic(0.0, 10.0, 3.0, 6.0, 12.0)])
    @test 3.0 * f ≈ g
    @test f * 3.0 ≈ g
    mult_scalar!(f, 3.0)
    @test f ≈ g
end

@testset "Empty" begin
    f = PiecewiseQuadratic()
    g = PiecewiseQuadratic([BoundedQuadratic(0, 5, 1, 2, 4)])
    @test isempty(f)
    @test !isempty(g)
end

@testset "Negative" begin
    f = PiecewiseQuadratic([BoundedQuadratic(0, 5, 0, 2, 4)])
    g = PiecewiseQuadratic([BoundedQuadratic(0, 5, 0, -2, -4)])
    @test -f ≈ g
end

@testset "Get Plot" begin
    f = PiecewiseQuadratic([BoundedQuadratic(0, 5, 0, 2, 4)])
    N = 10
    x = [-5.0, -3.3333333333333335, -1.6666666666666667, 0.0, 1.6666666666666667,
         3.3333333333333335, 5.0, 6.666666666666667, 8.333333333333334]
    y = [Inf, Inf, Inf, 4.0, 7.333333333333334, 10.666666666666668, 14.0, Inf, Inf]
    @test get_plot(f; N=N) == (x, y)
end

@testset "Is Convex" begin
    #####
    ##### not convex
    #####

    # test single piece that is non convex (never enters loop)
    f = BoundedQuadratic(0.0, 1.0, -1.0, 0.0, 1.0)
    p = PiecewiseQuadratic(f)
    @test(!is_convex(p))

    # test non continuous
    f = BoundedQuadratic(0.0, 1.0, 1.0, 0.0, 1.0)
    g = BoundedQuadratic(5.0, 6.0, 2.0, 0.0, 1.0)
    p = PiecewiseQuadratic([f, g])
    @test(!is_convex(p))

    # test derivatives out of order
    f = BoundedQuadratic(-1.0, 0.0, 0.0, 1.0, 1.0)
    g = BoundedQuadratic(0.0, 1.0, 0.0, -1.0, 1.0)
    p = PiecewiseQuadratic([f, g])
    @test(!is_convex(p))

    # test middle piece not convex
    f = BoundedQuadratic(-1.0, 0.0, 0.0, -1.0, 0.0)
    g = BoundedQuadratic(0.0, 1.0, -1.0, 0.0, 0.0)
    h = BoundedQuadratic(1.0, 2.0, 0.0, 1.0, -2.0)
    p = PiecewiseQuadratic([f, g, h])
    @test(!is_convex(p))

    #####
    ##### is convex
    #####

    # test indicator is convex
    f = zero(PiecewiseQuadratic)
    @test(is_convex(f))

    # test single convex piece
    f = BoundedQuadratic(0.0, 1.0, 1.0, 0.0, 1.0)
    p = PiecewiseQuadratic(f)
    @test(is_convex(p))

    # test multi-piece convex
    f1 = BoundedQuadratic(-1.0, 0.0, 0.0, -1.0, 0.0)
    f2 = BoundedQuadratic(0.0, 1.0, 0.0, 0.0, 0.0)
    f3 = BoundedQuadratic(1.0, 2.0, 1.0, -2.0, 1.0)
    f4 = BoundedQuadratic(2.0, 3.0, 0.0, 3.0, -5.0)
    p = PiecewiseQuadratic([f1, f2, f3, f4])
    @test(is_convex(p))
end
