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
const ϵ = 1e-12

function ≈(a::Real, b::Real)
    return (abs(a - b) ≤ ϵ) || (a == b)  # Second case covers infinite values.
end
≉(a::Real, b::Real) = !(a ≈ b)

function ≲(a::Real, b::Real)
    return a ≤ b + ϵ
end
≳(a::Real, b::Real) = b ≲ a
⋦(a::Real, b::Real) = !((a ≳ b) || isnan(a) || isnan(b))
⋧(a::Real, b::Real) = b ⋦ a

"""
    solve_quad(a::Real, b::Real, c::Real)

Solve a quadratic function `a x^2 + b x + c` using the quadratic formula.
"""
function solve_quad(a::Real, b::Real, c::Real)
    if a == 0
        if b == 0.0
            return NaN, NaN
        else
            return -c / b, NaN
        end
    else
        b2m4ac = b^2 - 4 * a * c
        if !(b2m4ac ≳ 0.0)
            return NaN, NaN
        end
        sqrt_b2m4ac = sqrt(pos(b2m4ac))
        if b > 0
            x1 = (-b - sqrt_b2m4ac) / (2 * a)
            x2 = 2 * c / (-b - sqrt_b2m4ac)
        else
            x1 = (-b + sqrt_b2m4ac) / (2 * a)
            x2 = 2 * c / (-b + sqrt_b2m4ac)
        end
        return x1, x2
    end
end

pos(a::Real) = max(a, 0)
neg(a::Real) = pos(-a)
clip(a::Real, lb::Real, ub::Real) = min(max(a, lb), ub)
clip(a::Real, dom::Interval) = clip(a, dom.lb, dom.ub)
