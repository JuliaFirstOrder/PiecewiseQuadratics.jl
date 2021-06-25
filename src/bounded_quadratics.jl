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
    BoundedQuadratic(lb::Real, ub::Real, p::Real, q::Real, r::Real)

Represents bounded quadratic function
```math
f(x) = px^2 + qx + r, ∀ x ∈ [lb, ub]
```

The fields represent:
- `lb`: Lower bound of the function
- `ub`: Upper bound of the function
- `p`: Coefficient of the quadratic term
- `q`: Coefficient of the linear term
- `r`: Constant

# Example
```jldoctest
julia> bq = BoundedQuadratic(0., 5., 3., 2., 1.)
BoundedQuadratic: f(x) = 3.00000 x² + 2.00000 x + 1.00000, ∀x ∈ [0.00000, 5.00000]

```
"""
mutable struct BoundedQuadratic
    lb::Float64
    ub::Float64
    p::Float64
    q::Float64
    r::Float64

    function BoundedQuadratic(lb::Real, ub::Real, p::Real, q::Real, r::Real)
        @assert !isnan(lb)
        @assert !isnan(ub)
        @assert isfinite(p)
        @assert isfinite(q)
        @assert isfinite(r)
        return new(lb, ub, p, q, r)
    end
end

"""
    BoundedQuadratic()

Constructs an unbounded BoundedQuadratic `f(x) = 0, ∀ x`.
"""
BoundedQuadratic() = BoundedQuadratic(0.0, 0.0, 0.0)

"""
    BoundedQuadratic(p::Real, q::Real, r::Real)

Constructs a unbounded `BoundedQuadratic` function `f(x) = px^2 + qx + r, ∀ x ∈ ℝ`.
"""
BoundedQuadratic(p::Real, q::Real, r::Real) = BoundedQuadratic(Interval(), p, q, r)

"""
    BoundedQuadratic(dom::Interval, p::Real, q::Real, r::Real

Constructs a `BoundedQuadratic` function on an Interval `dom`.
"""
function BoundedQuadratic(dom::Interval, p::Real, q::Real, r::Real)
    return BoundedQuadratic(dom.lb, dom.ub, p, q, r)
end

function Base.show(io::IO, f::BoundedQuadratic)
    @printf(io, "BoundedQuadratic: f(x) = ")
    if f.p > 0
        @printf(io, "%.5f x² ", f.p)
    elseif f.p < 0
        @printf(io, "-%.5f x² ", -f.p)
    end
    if f.q > 0
        @printf(io, "+ %.5f x ", f.q)
    elseif f.q < 0
        @printf(io, "- %.5f x ", -f.q)
    end
    if f.r > 0
        @printf(io, "+ %.5f", f.r)
    elseif f.r < 0
        @printf(io, "- %.5f", -f.r)
    end
    if (f.p == 0) & (f.q == 0)
        @printf(io, "0")
    end
    @printf(io, ", ∀x ∈ ")
    print(io, domain(f))
    return
end

"""
    zero(::Type{BoundedQuadratic})

Construct an empty BoundedQuadratic with no constraints.

# Example
```jldoctest
julia> zero(BoundedQuadratic)
BoundedQuadratic: f(x) = 0, ∀x ∈ ℝ

```
"""
zero(::Type{BoundedQuadratic}) = BoundedQuadratic()
copy(f::BoundedQuadratic) = BoundedQuadratic(f.lb, f.ub, f.p, f.q, f.r)
function copy!(out::BoundedQuadratic, f::BoundedQuadratic)
    out.lb = f.lb
    out.ub = f.ub
    out.p = f.p
    out.q = f.q
    out.r = f.r
    return out
end

"""
    get_tangent(f::BoundedQuadratic, x::Real)

Construct a new unbounded `BoundedQuadratic` representing the (unbounded) tangent line to `f` at the point `x`.

# Example
```jldoctest
julia> bq = BoundedQuadratic(-1., 1., 1., 1., 1.)
BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [-1.00000, 1.00000]

julia> tangent = get_tangent(bq, 0.5)
BoundedQuadratic: f(x) = + 2.00000 x + 0.75000, ∀x ∈ ℝ

```
"""
function get_tangent(f::BoundedQuadratic, x::Real)
    q_tan = 2 * f.p * x + f.q
    r_tan = f.p * x^2 + f.q * x + f.r - q_tan * x
    return BoundedQuadratic(Interval(), 0.0, q_tan, r_tan)
end

"""
    get_line(x1::Real, y1::Real, x2::Real, y2::Real)

Construct a new unbounded `BoundedQuadratic` representing a line passing through `(x1, y1)` and `(x2, y2)`.

# Example
```jldoctest
julia> line = get_line(1., 2., 3., 4.)
BoundedQuadratic: f(x) = + 1.00000 x + 1.00000, ∀x ∈ ℝ

```
"""
function get_line(x1::Real, y1::Real, x2::Real, y2::Real)
    @assert x1 != x2
    q = (y2 - y1) / (x2 - x1)
    return BoundedQuadratic(0.0, q, y1 - q * x1)
end

"""
    domain(f::BoundedQuadratic)

Return the Interval on which the BoundedQuadratic is defined.

# Example
```jldoctest
julia> bq = BoundedQuadratic(0., 5., 3., 2., 1.)
BoundedQuadratic: f(x) = 3.00000 x² + 2.00000 x + 1.00000, ∀x ∈ [0.00000, 5.00000]

julia> dom = domain(bq)
[0.00000, 5.00000]

```
"""
domain(f::BoundedQuadratic) = Interval(f.lb, f.ub)

#####
##### Boolean
#####

"""
    isempty(f::BoundedQuadratic)

Return `true` if the domain of the BoundedQuadratic `f` is empty.
"""
isempty(f::BoundedQuadratic) = isempty(domain(f))

function ≤(g::BoundedQuadratic, f::BoundedQuadratic)
    @assert g.p == 0
    return (g.lb ≤ f.lb) & (g.ub ≥ f.lb) & (minimize(f - g)[2] ≥ 0)
end

≥(g::BoundedQuadratic, f::BoundedQuadratic) = f ≤ g

function ≲(g::BoundedQuadratic, f::BoundedQuadratic)
    @assert g.p == 0
    return (g.lb ≲ f.lb) & (g.ub ≳ f.ub) & (minimize(f - g)[2] ≳ 0.0)
end

≳(g::BoundedQuadratic, f::BoundedQuadratic) = f ≲ g

function ≈(f::BoundedQuadratic, g::BoundedQuadratic)
    return ((abs(f.lb - g.lb) ≤ ϵ) | (f.lb == g.lb)) &
           ((abs(f.ub - g.ub) ≤ ϵ) | (f.ub == g.ub)) &
           (abs(f.p - g.p) ≤ ϵ) &
           (abs(f.q - g.q) ≤ ϵ) &
           (abs(f.r - g.r) ≤ ϵ)
end

"""
    is_point(f::BoundedQuadratic)

Return `true` if the BoundedQuadratic is defined only on a single point (`lb == ub`).

See also: [`is_almost_point`](@ref)

# Example
```jldoctest
julia> bq = BoundedQuadratic(0., 5., 3., 2., 1.)
BoundedQuadratic: f(x) = 3.00000 x² + 2.00000 x + 1.00000, ∀x ∈ [0.00000, 5.00000]

julia> is_point(bq)
false

julia> bq = BoundedQuadratic(5., 5., 3., 2., 1.)
BoundedQuadratic: f(x) = 3.00000 x² + 2.00000 x + 1.00000, ∀x ∈ [5.00000, 5.00000]

julia> is_point(bq)
true

```
"""
is_point(f::BoundedQuadratic) = f.lb == f.ub

"""
    is_almost_point(f::BoundedQuadratic)

Return `true` if the BoundedQuadratic is approximately defined only on a single point (`lb ≈ ub`).

See also: [`is_point`](@ref)

# Example
```jldoctest
julia> bq = BoundedQuadratic(5., 5. + 1e-14, 3., 2., 1.)
BoundedQuadratic: f(x) = 3.00000 x² + 2.00000 x + 1.00000, ∀x ∈ [5.00000, 5.00000]

julia> is_point(bq)
false

julia> is_almost_point(bq)
true

```
"""
function is_almost_point(f::BoundedQuadratic)
    return (is_point(f)) || (f.lb ≈ f.ub)
end

"""
    continuous_and_overlapping(f::BoundedQuadratic, g::BoundedQuadratic)

Return `true` if `f`'s right endpoint corresponds with `g`'s left endpoint.
"""
function continuous_and_overlapping(f::BoundedQuadratic, g::BoundedQuadratic)
    return (f.ub ≈ g.lb) && (f(f.ub) ≈ g(g.lb))
end

is_convex(f::BoundedQuadratic) = f.p >= 0.0

#####
##### Operations
#####

"""
    (f::BoundedQuadratic)(x::Real)

Evaluate `f(x)` if `x` is in the domain of `f`, else return `Inf`.

# Example
```jldoctest
julia> bq = BoundedQuadratic(3., 2., 1.)
BoundedQuadratic: f(x) = 3.00000 x² + 2.00000 x + 1.00000, ∀x ∈ ℝ

julia> bq(1.)
6.0

```
"""
function (f::BoundedQuadratic)(x::Real)
    if x in domain(f)
        return f.p * x^2 + f.q * x + f.r
    else
        return Inf
    end
end

function +(f::BoundedQuadratic, a::Real)
    return BoundedQuadratic(f.lb, f.ub, f.p, f.q, f.r + a)
end

function -(f::BoundedQuadratic)
    @assert f.p == 0.0
    return BoundedQuadratic(f.lb, f.ub, -f.p, -f.q, -f.r)
end

function +(f::BoundedQuadratic, g::BoundedQuadratic)
    dom = domain(f) ∩ domain(g)
    return BoundedQuadratic(dom, f.p + g.p, f.q + g.q, f.r + g.r)
end

function -(f::BoundedQuadratic, g::BoundedQuadratic)
    return f + (-g)
end

*(f::BoundedQuadratic, α::Real) = BoundedQuadratic(f.lb, f.ub, α * f.p, α * f.q, α * f.r)
*(α::Real, f::BoundedQuadratic) = f * α

"""
    scale(f::BoundedQuadratic, α::Real)

Return a new `BoundedQuadratic` that has been scaled by `α`. That is, given `f(x)` and `α`, returns `f(αx)`.

Note: this operation requires scaling the domain.

See also: [`scale!`](@ref)

# Example
```jldoctest
julia> bq = BoundedQuadratic(-1., 1., 1., 1., 1.)
BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [-1.00000, 1.00000]

julia> scale(bq, 2.)
BoundedQuadratic: f(x) = 4.00000 x² + 2.00000 x + 1.00000, ∀x ∈ [-0.50000, 0.50000]

```
"""
function scale(f::BoundedQuadratic, α::Real)
    return BoundedQuadratic(f.lb / α, f.ub / α, α^2 * f.p, α * f.q, f.r)
end

"""
     scale!(f::BoundedQuadratic, α::Real)
     scale!(f::BoundedQuadratic, α::Real, out::BoundedQuadratic)

Scale `f` inplace.

See also: [`scale`](@ref)
"""
scale!(f::BoundedQuadratic, α::Real) = scale!(f, α, f)
scale!(f::BoundedQuadratic, α::Real, out::BoundedQuadratic) = copy!(out, scale(f, α))

"""
    perspective(f::BoundedQuadratic, α::Real)

Return the perspective function of `f`. That is, given `f(x)` and `α`, return `α * f(x / α)`.

Note: that this operation requires scaling of the domain.

See also: [`perspective!`](@ref)

# Example
```jldoctest
julia> bq = BoundedQuadratic(-1., 1., 1., 1., 1.)
BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [-1.00000, 1.00000]

julia> perspective(bq, 2.)
BoundedQuadratic: f(x) = 0.50000 x² + 1.00000 x + 2.00000, ∀x ∈ [-2.00000, 2.00000]

```
"""
function perspective(f::BoundedQuadratic, α::Real)
    return BoundedQuadratic(α * f.lb, α * f.ub, f.p / α, f.q, f.r * α)
end

"""
    perspective!(f::BoundedQuadratic, α::Real)
    perspective!(f::BoundedQuadratic, α::Real, out::BoundedQuadratic)

Shift perspective of `f` inplace.

See also: [`perspective`](@ref)
"""
perspective!(f::BoundedQuadratic, α::Real) = perspective!(f, α, f)
function perspective!(f::BoundedQuadratic, α::Real, out::BoundedQuadratic)
    return copy!(out, perspective(f, α))
end

"""
    shift(f::BoundedQuadratic, δ::Real)

Return `f` shifted along the `x`-axis by `δ`.

Note: for `δ > 0`, this is a right shift. For `δ < 0`, this is a left shift.

See also: [`shift!`](@ref)

# Example
```jldoctest
julia> bq = BoundedQuadratic(-1., 1., 1., 1., 1.)
BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [-1.00000, 1.00000]

julia> shift(bq, 2.)
BoundedQuadratic: f(x) = 1.00000 x² - 3.00000 x + 3.00000, ∀x ∈ [1.00000, 3.00000]

```
"""
function shift(f::BoundedQuadratic, δ::Real)
    return BoundedQuadratic(f.lb + δ, f.ub + δ, f.p, f.q - 2 * f.p * δ,
                            f.p * δ^2 - f.q * δ + f.r)
end

"""
    shift!(f::BoundedQuadratic, δ::Real)
    shift!(f::BoundedQuadratic, δ::Real, out::BoundedQuadratic)

Shift `f` inplace along the `x`-axis by `δ`.

See also: [`shift`](@ref)
"""
shift!(f::BoundedQuadratic, δ::Real) = shift!(f, δ, f)
function shift!(f::BoundedQuadratic, δ::Real, out::BoundedQuadratic)
    return copy!(out, shift(f, δ))
end

"""
    tilt(f::BoundedQuadratic, α::Real)

Return `f` tilted by `α`. This shifts linear coefficient `q` by `α`.

See also: [`tilt!`](@ref)

# Example
```jldoctest
julia> bq = BoundedQuadratic(-1., 1., 1., 1., 1.)
BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [-1.00000, 1.00000]

julia> tilt(bq, 2.)
BoundedQuadratic: f(x) = 1.00000 x² + 3.00000 x + 1.00000, ∀x ∈ [-1.00000, 1.00000]

```
"""
function tilt(f::BoundedQuadratic, α::Real)
    return BoundedQuadratic(f.lb, f.ub, f.p, f.q + α, f.r)
end

"""
    tilt!(f::BoundedQuadratic, α::Real)
    tilt!(f::BoundedQuadratic, α::Real, out::BoundedQuadratic)

Tilt `f` inplace.

See also: [`tilt`](@ref)
"""
tilt!(f::BoundedQuadratic, α::Real) = tilt!(f, α, f)
function tilt!(f::BoundedQuadratic, α::Real, out::BoundedQuadratic)
    return copy!(out, tilt(f, α))
end

"""
    restrict_dom(f::BoundedQuadratic, dom::Interval)
    restrict_dom(f::BoundedQuadratic, lb::Real, ub::Real)

Return a new BoundedQuadratic with domain restricted to the intersect of the passed domain.

See also: [`restrict_dom!`](@ref)

# Example
```jldoctest
julia> bq = BoundedQuadratic(-10., 10., 1., 1., 1.)
BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [-10.00000, 10.00000]

julia> restrict_dom(bq, 2., 3.)
BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [2.00000, 3.00000]

```
"""
function restrict_dom(f::BoundedQuadratic, dom::Interval)
    restricted_dom = domain(f) ∩ dom
    @assert restricted_dom.ub ≥ restricted_dom.lb
    return BoundedQuadratic(restricted_dom, f.p, f.q, f.r)
end
restrict_dom(f::BoundedQuadratic, lb::Real, ub::Real) = restrict_dom(f, Interval(lb, ub))

"""
    restrict_dom!(f::BoundedQuadratic, dom::Interval)
    restrict_dom!(f::BoundedQuadratic, lb::Real, ub::Real)
    restrict_dom!(f::BoundedQuadratic, lb::Real, ub::Real, out::BoundedQuadratic)

Restrict domain of `f` inplace.

See also: [`restrict_dom`](@ref)
"""
restrict_dom!(f::BoundedQuadratic, dom::Interval) = restrict_dom!(f, dom, f)
function restrict_dom!(f::BoundedQuadratic, dom::Interval, out::BoundedQuadratic)
    return copy!(out, restrict_dom(f, dom))
end
restrict_dom!(f::BoundedQuadratic, lb::Real, ub::Real) = restrict_dom!(f, lb, ub, f)
function restrict_dom!(f::BoundedQuadratic, lb::Real, ub::Real, out::BoundedQuadratic)
    return restrict_dom!(f, Interval(lb, ub), f)
end

"""
    extend_dom(f::BoundedQuadratic)

Return an unbounded version of `f`.

See also: [`extend_dom!`](@ref)

# Example
```jldoctest
julia> bq = BoundedQuadratic(-1., 1., 1., 1., 1.)
BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [-1.00000, 1.00000]

julia> extend_dom(bq)
BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ ℝ

```
"""
extend_dom(f::BoundedQuadratic) = BoundedQuadratic(f.p, f.q, f.r)

"""
    extend_dom!(f::BoundedQuadratic)
    extend_dom!(f::BoundedQuadratic, out::BoundedQuadratic)

Remove the bounds of `f` inplace.

See also: [`extend_dom`](@ref)
"""
extend_dom!(f::BoundedQuadratic) = extend_dom!(f, f)
extend_dom!(f::BoundedQuadratic, out::BoundedQuadratic) = copy!(out, extend_dom(f))

"""
    reverse(f::BoundedQuadratic)

Return `f` reversed over the `y` axis. That is, given `f(x)`, return `f(-x)`.

See also: [`reverse!`](@ref)

# Example
```jldoctest
julia> bq = BoundedQuadratic(-1., 2., 1., 1., 1.)
BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [-1.00000, 2.00000]

julia> reverse(bq)
BoundedQuadratic: f(x) = 1.00000 x² - 1.00000 x + 1.00000, ∀x ∈ [-2.00000, 1.00000]

```
"""
reverse(f::BoundedQuadratic) = BoundedQuadratic(-f.ub, -f.lb, f.p, -f.q, f.r)

"""
    reverse!(f::BoundedQuadratic)
    reverse!(f::BoundedQuadratic, out::BoundedQuadratic)

Reverse `f` inplace.

See also: [`reverse`](@ref)
"""
reverse!(f::BoundedQuadratic) = reverse!(f, f)
function reverse!(f::BoundedQuadratic, out::BoundedQuadratic)
    return copy!(out, reverse(f))
end

"""
    derivative(f::BoundedQuadratic)

Return the derivative of `f`, `f'`

# Example
```jldoctest
julia> bq = BoundedQuadratic(3., 2., 1.)
BoundedQuadratic: f(x) = 3.00000 x² + 2.00000 x + 1.00000, ∀x ∈ ℝ

julia> derivative(bq)
BoundedQuadratic: f(x) = + 6.00000 x + 2.00000, ∀x ∈ ℝ

```
"""
function derivative(f::BoundedQuadratic)
    return BoundedQuadratic(f.lb, f.ub, 0.0, 2.0 * f.p, f.q)
end

"""
    derivative(f::BoundedQuadratic, x::Real)

Evaluate the derivative of `f` at `x`, `f'(x)`.

# Example
```jldoctest
julia> bq = BoundedQuadratic(3., 2., 1.)
BoundedQuadratic: f(x) = 3.00000 x² + 2.00000 x + 1.00000, ∀x ∈ ℝ

julia> derivative(bq, 2.)
14.0

```
"""
derivative(f::BoundedQuadratic, x::Real) = derivative(f)(x)

function _sum(f_list::Vector{BoundedQuadratic})
    dom, is_valid = _intersect(f_list)

    p = 0.0
    q = 0.0
    r = 0.0
    if is_valid
        for fi in f_list
            p += fi.p
            q += fi.q
            r += fi.r
        end
        return BoundedQuadratic(dom, p, q, r), is_valid
    else
        return BoundedQuadratic(dom, 0.0, 0.0, 0.0), is_valid
    end
end

"""
    sum(f_list::Vector{BoundedQuadratic})

Return the BoundedQuadratic sum of a list of BoundedQuadratics if it is valid, else `nothing`.

# Example
```jldoctest
julia> bq = BoundedQuadratic(-1., 5., 1., 2., 3.)
BoundedQuadratic: f(x) = 1.00000 x² + 2.00000 x + 3.00000, ∀x ∈ [-1.00000, 5.00000]

julia> sum([bq, bq])
BoundedQuadratic: f(x) = 2.00000 x² + 4.00000 x + 6.00000, ∀x ∈ [-1.00000, 5.00000]

```
"""
function sum(f_list::Vector{BoundedQuadratic})
    g, is_valid = _sum(f_list)
    if is_valid
        return g
    else
        return nothing
    end
end

function _intersect(f_list::Vector{BoundedQuadratic})
    k = length(f_list)
    doms = [Interval(), map(domain, f_list)...]
    dom = reduce(∩, doms)
    is_valid = !isempty(dom)
    return dom, is_valid
end


# TODO: the following example code fails as a doctest with Julia 1.0...
# it appears that the output of `Vector{T}` displays as `Array{T,1}` instead
"""
    intersect(f_list::Vector{BoundedQuadratic})

Intersect the domains of a list of BoundedQuadratics if possible.

# Example
```julia
julia> f_list = [BoundedQuadratic(-100, 100, 1, 1, 1),
          BoundedQuadratic(-50, 25, 1, 1, 1),
          BoundedQuadratic(0, 50, 1, 1, 1)]
3-element Vector{BoundedQuadratic}:
 BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [-100.00000, 100.00000]

 BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [-50.00000, 25.00000]

 BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [0.00000, 50.00000]

julia> out, valid = intersect(f_list);

julia> valid
true

julia> out
3-element Vector{BoundedQuadratic}:
 BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [0.00000, 25.00000]

 BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [0.00000, 25.00000]

 BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [0.00000, 25.00000]


julia> f_list = [BoundedQuadratic(-100, 0, 1,1,1)
            BoundedQuadratic(25, 50, 1,1,1)]  # non-overlapping
2-element Vector{BoundedQuadratic}:
 BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [-100.00000, 0.00000]

 BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [25.00000, 50.00000]

julia> out, valid = intersect(f_list);

julia> valid
false

julia> out
2-element Vector{BoundedQuadratic}:
 #undef
 #undef

```
"""
function intersect(f_list::Vector{BoundedQuadratic})
    k = length(f_list)
    dom, is_valid = _intersect(f_list)

    g_list = Vector{BoundedQuadratic}(undef, k)
    if is_valid
        for (i, f) in enumerate(f_list)
            g_list[i] = restrict_dom(f, dom)
        end
    end
    return g_list, is_valid
end

"""
    minimize(f::BoundedQuadratic)

Return the minimum `x` and `f(x)` of `f` over its domain.
"""
function minimize(f::BoundedQuadratic)
    if f.lb > f.ub  # Infeasible.
        xstar = NaN
        min_val = Inf
    else  # Feasible, but possibly unbounded.
        if f.p > 0
            xstar = -f.q / (2 * f.p)
            if xstar < f.lb
                xstar = f.lb
            elseif xstar > f.ub
                xstar = f.ub
            end
        elseif f.q > 0
            xstar = (f.lb == -Inf) ? NaN : f.lb
        elseif f.q < 0
            xstar = (f.ub == Inf) ? NaN : f.ub
        else  # Case of p = 0, q = 0.
            if f.lb > -Inf
                xstar = f.lb
            elseif f.ub < Inf
                xstar = f.ub
            else
                xstar = 0.0
            end
        end
        if isfinite(xstar)
            min_val = f.p * xstar^2 + f.q * xstar + f.r
        else
            min_val = -Inf
        end
    end
    return xstar, min_val
end
