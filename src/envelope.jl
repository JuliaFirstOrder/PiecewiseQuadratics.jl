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

"""
    envelope(f::PiecewiseQuadratic)

Computes the greatest convex lower bound of a `PiecewiseQuadratic` `f`.

# Example
```jldoctest
julia> f = PiecewiseQuadratic([BoundedQuadratic(-Inf, 0., 0., 1., 0.),
                               BoundedQuadratic(0., 3., 0., 0., 0.)])
Piecewise quadratic function:
BoundedQuadratic: f(x) = + 1.00000 x , ∀x ∈ [-Inf, 0.00000]
BoundedQuadratic: f(x) = 0, ∀x ∈ [0.00000, 3.00000]

julia> envelope(f)
Piecewise quadratic function:
BoundedQuadratic: f(x) = + 1.00000 x - 3.00000, ∀x ∈ [-Inf, 3.00000]

```
"""
function envelope(f::PiecewiseQuadratic)
    h = FixedMemoryPwq(2 * length(f))
    env = FixedMemoryPwq(3)  # Pre-allocated workspace.
    for fi in f
        append_envelope!(h, fi, env)
    end
    return PiecewiseQuadratic(h)
end

function append_envelope!(f::FixedMemoryPwq, g::BoundedQuadratic, env::FixedMemoryPwq)
    if length(f) == 0
        push!(f, g)
    else
        intersection_at_left = true
        empty!(env)

        while (length(f) > 0) & intersection_at_left
            empty!(env)
            fi = pop!(f)
            intersection_at_left = append_envelope!(fi, g, env)
        end
        append!(f, env)
    end
end

function append_envelope!(f::BoundedQuadratic, g::BoundedQuadratic, env::FixedMemoryPwq)
    @assert f.ub ≤ g.lb
    @assert length(env) == 0

    _, _ = _envelope_midpt_midpt!(f, g, env)
    if length(env) > 0
        return false
    end

    _, _ = _envelope_midpt_endpt!(f, g, env)
    if length(env) > 0
        return false
    end

    _, iar = _envelope_midpt_endpt!(reverse(g), reverse(f), env)
    if length(env) > 0
        reverse!(env)
        return iar
    end

    ial, _ = _envelope_endpt_endpt!(f, g, env, true)
    if length(env) > 0
        return ial
    end

    _, iar = _envelope_endpt_endpt!(reverse(g), reverse(f), env, false)
    if length(env) > 0
        reverse!(env)
        return iar
    end

    error("Error in convex envelope computation.")

    return false, 0
end

function _envelope_midpt_midpt!(f::BoundedQuadratic, g::BoundedQuadratic,
                                env::FixedMemoryPwq)
    if (f.p > 0) & (g.p > 0)
        a = (f.p^2 / g.p - f.p)
        b = (f.p / g.p) * (f.q - g.q)
        c = f.r - g.r + (f.q - g.q)^2 / (4 * g.p)
        x1, x2 = solve_quad(a, b, c)
        for xf in [x1, x2]
            xg = f.p / g.p * xf + (f.q - g.q) / (2 * g.p)
            if (xf ≳ f.lb) && (xf ≲ f.ub) && (xg ≳ g.lb) && (xg ≲ g.ub)
                xf = clip(xf, f.lb, f.ub)
                xg = clip(xg, g.lb, g.ub)
                m = 2 * f.p * xf + f.q
                env[1] = BoundedQuadratic(f.lb, xf, f.p, f.q, f.r)
                env[2] = BoundedQuadratic(xf, xg, 0.0, m, f(xf) - m * xf)
                env[3] = BoundedQuadratic(xg, g.ub, g.p, g.q, g.r)
                env.len = 3
                return false, false
            end
        end
    end
    return false, false, 0
end

function _envelope_midpt_endpt!(f::BoundedQuadratic, g::BoundedQuadratic,
                                env::FixedMemoryPwq)
    if f.p > 0

        # Midpoint to lower
        xg = g.lb
        xf = _envelope_point_quad(xg, g(xg), f.p, f.q, f.r)
        if !isnan(xf)
            if (xf ≳ f.lb) && (xf ≲ f.ub)
                xf = clip(xf, f.lb, f.ub)
                h = get_tangent(f, xf)
                if h ≲ g
                    clip(xf, f.lb, f.ub)
                    env[1] = restrict_dom(f, -Inf, xf)
                    env[2] = restrict_dom(h, xf, xg)
                    env[3] = restrict_dom(g, xg, Inf)
                    env.len = 3
                    return false, false
                end
            end
        end

        # Midpoint to (finite) upper
        xg = g.ub
        xf = _envelope_point_quad(xg, g(xg), f.p, f.q, f.r)
        if !isnan(xf)
            if (xf ≳ f.lb) && (xf ≲ f.ub)
                xf = clip(xf, f.lb, f.ub)
                h = get_tangent(f, xf)
                if h ≲ g
                    env[1] = restrict_dom(f, -Inf, xf)
                    env[2] = restrict_dom(h, xf, xg)
                    env.len = 2
                    return false, true
                end
            end
        end

        # Midpoint to (infinite) upper
        if isinf(g.ub) & (g.p == 0.0)
            xf = (g.q - f.q) / (2 * f.p)
            if (xf ≳ f.lb) && (xf ≲ f.ub)
                xf = clip(xf, f.lb, f.ub)
                h = BoundedQuadratic(0.0, g.q, extend_dom(f)(xf) - g.q * xf)
                if h ≲ g
                    env[1] = restrict_dom(f, -Inf, xf)
                    env[2] = restrict_dom(h, xf, Inf)
                    env.len = 2
                    return false, false
                end
            end
        end
    end
    return false, false, 0
end

function _envelope_endpt_endpt!(f::BoundedQuadratic, g::BoundedQuadratic,
                                env::FixedMemoryPwq, do_symmetric::Bool)
    if do_symmetric
        # Upper to lower (no gap)
        if f.ub == g.lb
            if is_point(f) && (f(f.ub) ≳ g(g.lb))
                env[1] = g
                env.len = 1
                return true, is_point(g)
            elseif is_point(g) && (g(g.lb) ≳ f(f.ub))
                env[1] = f
                env.len = 1
                return true, is_point(g)
            elseif (f(f.ub) ≈ g(g.lb)) && (2 * f.p * f.ub + f.q ≲ 2 * g.p * g.lb + g.q)
                env[1] = f
                env[2] = g
                env.len = 2
                return is_point(f), is_point(g)
            end
        end

        # Upper to lower (with gap)
        if f.ub != g.lb
            h = get_line(f.ub, f(f.ub), g.lb, g(g.lb))
            if (h ≲ f) && (h ≲ g)
                env[1] = f
                env[2] = restrict_dom(h, f.ub, g.lb)
                env[3] = g
                env.len = 3
                return is_point(f), is_point(g)
            end
        end

        # (Finite) lower to (finite) upper
        if (f.lb > -Inf) && (g.ub < Inf) && (f.lb != g.ub)
            h = get_line(f.lb, f(f.lb), g.ub, g(g.ub))
            if (h ≲ f) && (h ≲ g)
                env[1] = restrict_dom(h, f.lb, g.ub)
                env.len = 1
                return true, true
            end
        end
    end

    # Upper to (finite) upper
    if (g.ub < Inf) && (f.ub != g.ub)
        h = get_line(f.ub, f(f.ub), g.ub, g(g.ub))
        if (h ≲ f) && (h ≲ g)
            env[1] = f
            env[2] = restrict_dom(h, f.ub, g.ub)
            env.len = 2
            return is_point(f), true
        end
    end

    # (Finite) lower to (infinite) upper
    if (f.lb > -Inf) && (g.ub == Inf) && (g.p == 0)
        h = BoundedQuadratic(0.0, g.q, f(f.lb) - g.q * f.lb)
        if (h ≲ f) && (h ≲ g)
            env[1] = restrict_dom(h, f.lb, g.ub)
            env.len = 1
            return true, false
        end
    end

    # Upper to (infinite) upper
    if g.ub == Inf && (g.p == 0)
        h = BoundedQuadratic(0.0, g.q, f(f.ub) - g.q * f.ub)
        if (h ≲ f) && (h ≲ g)
            env[1] = f
            env[2] = restrict_dom(h, f.ub, Inf)
            env.len = 2
            return is_point(f), false
        end
    end

    return false, false
end

function _envelope_point_quad(x1::Float64, y1::Float64, p::Float64, q::Float64, r::Float64)
    a = p
    b = -2 * p * x1
    c = -q * x1 - r + y1

    x1, x2 = solve_quad(a, b, c)
    x_tan = minimum(solve_quad(a, b, c))
    return x_tan
end
