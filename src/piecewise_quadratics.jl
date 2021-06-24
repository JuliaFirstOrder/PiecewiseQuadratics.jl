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
    PiecewiseQuadratic()
    PiecewiseQuadratic(f::BoundedQuadratic)
    PiecewiseQuadratic(f_list::Vector{BoundedQuadratic}[; simplify_result=false])

Represents piecewise quadratic function, where each piece is a `BoundedQuadratic`.

The fields represent:
- `f_list`: a `Vector` of `BoundedQuadratic` functions

# Example
```jldoctest
julia> left = BoundedQuadratic(-Inf, 0., 0., -1., 0.)
BoundedQuadratic: f(x) = - 1.00000 x , ∀x ∈ [-Inf, 0.00000]

julia> right = BoundedQuadratic(0., Inf, 0., 1., 0.)
BoundedQuadratic: f(x) = + 1.00000 x , ∀x ∈ [0.00000, Inf]

julia> pwq = PiecewiseQuadratic([left, right])
Piecewise quadratic function:
BoundedQuadratic: f(x) = - 1.00000 x , ∀x ∈ [-Inf, 0.00000]
BoundedQuadratic: f(x) = + 1.00000 x , ∀x ∈ [0.00000, Inf]

```
"""
mutable struct PiecewiseQuadratic
    f_list::Vector{BoundedQuadratic}

    function PiecewiseQuadratic(f_list::Vector{BoundedQuadratic}; simplify_result=false)
        if simplify_result
            f_list = simplify(PiecewiseQuadratic(f_list; simplify_result=false)).f_list
        end
        return new(f_list)
    end
end

PiecewiseQuadratic() = PiecewiseQuadratic(BoundedQuadratic[])
PiecewiseQuadratic(f::BoundedQuadratic) = PiecewiseQuadratic([f])

"""
    indicator(dom::Interval)
    indicator(lb::Real, ub::Real)

Construct a PiecewiseQuadratic that is `0` on the interval and `Inf` everywhere else.

# Example
```jldoctest
julia> indicator(-5, 5)
Piecewise quadratic function:
BoundedQuadratic: f(x) = 0, ∀x ∈ [-5.00000, 5.00000]

```
"""
indicator(dom::Interval) = PiecewiseQuadratic(BoundedQuadratic(dom, 0, 0, 0))
indicator(lb::Real, ub::Real) = indicator(Interval(lb, ub))

function Base.show(io::IO, f::PiecewiseQuadratic)
    @printf(io, "Piecewise quadratic function:\n")
    for fi in f
        print(io, fi)
    end
end

"""
    zero(::Type{PiecewiseQuadratic})

Construct an empty PiecewiseQuadratic with no constraints.

# Example
```jldoctest
julia> zero(PiecewiseQuadratic)
Piecewise quadratic function:
BoundedQuadratic: f(x) = 0, ∀x ∈ ℝ

```
"""
zero(::Type{PiecewiseQuadratic}) = indicator(Interval())
copy(f::PiecewiseQuadratic) = PiecewiseQuadratic([copy(fi) for fi in f])
function copy!(out::PiecewiseQuadratic, f::PiecewiseQuadratic)
    out.f_list = f.f_list
    return out
end

#####
##### Indexing
#####

getindex(f::PiecewiseQuadratic, idx) = getindex(f.f_list, idx)
setindex!(f::PiecewiseQuadratic, val, idx) = setindex!(f.f_list, val, idx)
lastindex(f::PiecewiseQuadratic) = lastindex(f.f_list)
iterate(f::PiecewiseQuadratic) = iterate(f.f_list)
iterate(f::PiecewiseQuadratic, i::Int) = iterate(f.f_list, i::Int)
length(f::PiecewiseQuadratic) = length(f.f_list)
pop!(f::PiecewiseQuadratic) = pop!(f.f_list)

#####
##### Boolean
#####

"""
    isempty(f::PiecewiseQuadratic)

Return `true` if the PiecewiseQuadratic `f` is empty (`f_list` empty).
"""
isempty(f::PiecewiseQuadratic) = length(f) == 0

function ≈(f::PiecewiseQuadratic, g::PiecewiseQuadratic)
    if length(f) != length(g)
        return false
    end
    isequal = true
    for (fi, gi) in zip(f, g)
        isequal &= fi ≈ gi
    end
    return isequal
end

"""
    is_convex(f::PiecewiseQuadratic)

Return `true` if `f` is convex.

A `PiecewiseQuadratic` is convex if for all `i`:
* `f_i` is convex
* `f_i.ub == f_{i+1}.lb`
* `derivative(f_i)(f_i.ub) <= derivative(f_{i+1})(f_{i+1}.lb)`

# Example
```jldoctest
julia> left = BoundedQuadratic(-Inf, 0., 0., -1., 0.)
BoundedQuadratic: f(x) = - 1.00000 x , ∀x ∈ [-Inf, 0.00000]

julia> right = BoundedQuadratic(0., Inf, 0., 1., 0.)
BoundedQuadratic: f(x) = + 1.00000 x , ∀x ∈ [0.00000, Inf]

julia> pwq = PiecewiseQuadratic([left, right])
Piecewise quadratic function:
BoundedQuadratic: f(x) = - 1.00000 x , ∀x ∈ [-Inf, 0.00000]
BoundedQuadratic: f(x) = + 1.00000 x , ∀x ∈ [0.00000, Inf]

julia> is_convex(pwq)
true

```
"""
function is_convex(f::PiecewiseQuadratic)
    n = length(f.f_list)
    if n <= 1
        return is_convex(f.f_list[1])
    end
    for i in 1:(n - 1)
        left = f.f_list[i]
        right = f.f_list[i + 1]
        left_deriv = derivative(left, left.ub)
        right_deriv = derivative(right, right.lb)

        # not convex if not continuous or f_left's derivative is greater than f_right's
        if !continuous_and_overlapping(left, right) ||
           left_deriv - right_deriv > ϵ ||
           !is_convex(left)
            return false
        end
    end
    return true
end

#####
##### Operations
#####

"""
    (f::PiecewiseQuadratic)(x::Real)

Evaluate `f(x)` if `x` is in the domain of `f`, else return `Inf`.
"""
function (f::PiecewiseQuadratic)(x::Float64)
    for fi in f
        fi_x = fi(x)
        if fi_x < Inf
            return fi_x
        end
    end
    return Inf
end

+(f::PiecewiseQuadratic, g::PiecewiseQuadratic) = sum([f, g])
+(f::BoundedQuadratic, g::PiecewiseQuadratic) = g + PiecewiseQuadratic(f)
+(f::PiecewiseQuadratic, g::BoundedQuadratic) = g + f

-(f::PiecewiseQuadratic) = PiecewiseQuadratic(.-(f))

*(f::PiecewiseQuadratic, α::Real) = PiecewiseQuadratic(α .* f)
*(α::Real, f::PiecewiseQuadratic) = f * α

mult_scalar!(f::PiecewiseQuadratic, α::Real) = mult_scalar!(f, α, f)
function mult_scalar!(f::PiecewiseQuadratic, α::Real, out::PiecewiseQuadratic)
    @assert length(f) == length(out)
    return copy!(out, α * f)
end

"""
    scale(f::PiecewiseQuadratic, α::Real)

Return a new `PiecewiseQuadratic` that has been scaled by `α`. That is, given `f(x)` and `α`, returns `f(αx)`.

Note: this operation requires scaling the domain.

See also: [`scale!`](@ref)

# Example
```jldoctest
julia> f = PiecewiseQuadratic([BoundedQuadratic(-1., 0., 0., -1., 0.),
                               BoundedQuadratic(0., 1., 0., 1., 0.),
                               BoundedQuadratic(1., 5., 1., 1., 1.)])
Piecewise quadratic function:
BoundedQuadratic: f(x) = - 1.00000 x , ∀x ∈ [-1.00000, 0.00000]
BoundedQuadratic: f(x) = + 1.00000 x , ∀x ∈ [0.00000, 1.00000]
BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [1.00000, 5.00000]

julia> scale(f, 5)
Piecewise quadratic function:
BoundedQuadratic: f(x) = - 5.00000 x , ∀x ∈ [-0.20000, 0.00000]
BoundedQuadratic: f(x) = + 5.00000 x , ∀x ∈ [0.00000, 0.20000]
BoundedQuadratic: f(x) = 25.00000 x² + 5.00000 x + 1.00000, ∀x ∈ [0.20000, 1.00000]

```
"""
scale(f::PiecewiseQuadratic, α::Real) = PiecewiseQuadratic(scale.(f, α))

"""
    scale!(f::PiecewiseQuadratic, α::Real)
    scale!(f::PiecewiseQuadratic, α::Real, out::PiecewiseQuadratic)

Scale `f` inplace.

See also: [`scale`](@ref)
"""
scale!(f::PiecewiseQuadratic, α::Real) = scale!.(f, α)
scale!(f::PiecewiseQuadratic, α::Real, out::PiecewiseQuadratic) = copy!(out, scale(f, α))

"""
    perspective(f::PiecewiseQuadratic, α::Real)

Return the perspective function of `f`. That is, given `f(x)` and `α`, return `α * f(x / α)`.

Note: that this operation requires scaling of the domain.

See also: [`perspective!`](@ref)

# Example
```jldoctest
julia> f = PiecewiseQuadratic([BoundedQuadratic(-1., 0., 0., -5., 0.),
                               BoundedQuadratic(0., 2., 0., 2., 0.)])
Piecewise quadratic function:
BoundedQuadratic: f(x) = - 5.00000 x , ∀x ∈ [-1.00000, 0.00000]
BoundedQuadratic: f(x) = + 2.00000 x , ∀x ∈ [0.00000, 2.00000]

julia> persp = perspective(f, 5.)
Piecewise quadratic function:
BoundedQuadratic: f(x) = - 5.00000 x , ∀x ∈ [-5.00000, 0.00000]
BoundedQuadratic: f(x) = + 2.00000 x , ∀x ∈ [0.00000, 10.00000]

```
"""
perspective(f::PiecewiseQuadratic, α::Real) = PiecewiseQuadratic(perspective.(f, α))

"""
    perspective!(f::PiecewiseQuadratic, α::Real)
    perspective!(f::PiecewiseQuadratic, α::Real, out::PiecewiseQuadratic)

Shift perspective of `f` inplace.

See also: [`perspective`](@ref)
"""
perspective!(f::PiecewiseQuadratic, α::Real) = perspective!.(f, α)
function perspective!(f::PiecewiseQuadratic, α::Real, out::PiecewiseQuadratic)
    return copy!(out, perspective(f, α))
end

"""
    shift(f::PiecewiseQuadratic, δ::Real)

Return `f` shifted along the `x`-axis by `δ`.

Note: for `δ > 0`, this is a right shift. For `δ < 0`, this is a left shift.

See also: [`shift!`](@ref)

# Example
```jldoctest
julia> f = PiecewiseQuadratic([BoundedQuadratic(-1., 0., 0., -5., 0.),
                               BoundedQuadratic(0., 2., 0., 2., 0.)])
Piecewise quadratic function:
BoundedQuadratic: f(x) = - 5.00000 x , ∀x ∈ [-1.00000, 0.00000]
BoundedQuadratic: f(x) = + 2.00000 x , ∀x ∈ [0.00000, 2.00000]

julia> shift(f, 5.)
Piecewise quadratic function:
BoundedQuadratic: f(x) = - 5.00000 x + 25.00000, ∀x ∈ [4.00000, 5.00000]
BoundedQuadratic: f(x) = + 2.00000 x - 10.00000, ∀x ∈ [5.00000, 7.00000]

```
"""
shift(f::PiecewiseQuadratic, δ::Real) = PiecewiseQuadratic(shift.(f, δ))

"""
    shift!(f::PiecewiseQuadratic, δ::Real)
    shift!(f::PiecewiseQuadratic, δ::Real, out::PiecewiseQuadratic)

Shift `f` inplace along the `x`-axis by `δ`.

See also: [`shift`](@ref)
"""
shift!(f::PiecewiseQuadratic, δ::Real) = shift!.(f, δ)
shift!(f::PiecewiseQuadratic, δ::Real, out::PiecewiseQuadratic) = copy!(out, shift(f, δ))

"""
    tilt(f::PiecewiseQuadratic, α::Real)

Return `f` tilted by `α`. This shifts linear coefficient `q` by `α`.

See also: [`tilt!`](@ref)

# Example
```jldoctest
julia> f = PiecewiseQuadratic([BoundedQuadratic(-1., 0., 0., -5., 0.),
                               BoundedQuadratic(0., 2., 0., 2., 0.)])
Piecewise quadratic function:
BoundedQuadratic: f(x) = - 5.00000 x , ∀x ∈ [-1.00000, 0.00000]
BoundedQuadratic: f(x) = + 2.00000 x , ∀x ∈ [0.00000, 2.00000]

julia> tilt(f, 5.)
Piecewise quadratic function:
BoundedQuadratic: f(x) = 0, ∀x ∈ [-1.00000, 0.00000]
BoundedQuadratic: f(x) = + 7.00000 x , ∀x ∈ [0.00000, 2.00000]

```
"""
tilt(f::PiecewiseQuadratic, α::Real) = PiecewiseQuadratic(tilt.(f, α))

"""
    tilt!(f::PiecewiseQuadratic, α::Real)
    tilt!(f::PiecewiseQuadratic, α::Real, out::PiecewiseQuadratic)

Tilt `f` inplace.
"""
tilt!(f::PiecewiseQuadratic, α::Real) = tilt!.(f, α)
tilt!(f::PiecewiseQuadratic, α::Real, out::PiecewiseQuadratic) = copy!(out, tilt(f, α))

"""
     push!(f::PiecewiseQuadratic, g::BoundedQuadratic; simplify_result=false)

Add a BoundedQuadratic `g` to the right hand side of PiecewiseQuadratic `f`.
"""
function push!(f::PiecewiseQuadratic, g::BoundedQuadratic; simplify_result=false)
    push!(f.f_list, g)
    if simplify_result
        simplify(f; start_idx=length(f) - 1)
    end
end

"""
    append!(f::PiecewiseQuadratic, g::PiecewiseQuadratic; simplify_result=false)

Append a PiecewiseQuadratic `g` to the right hand side of PiecewiseQuadratic `f`.
"""
function append!(f::PiecewiseQuadratic, g::PiecewiseQuadratic; simplify_result=false)
    k = length(f)
    append!(f.f_list, g.f_list)
    if simplify_result && (k > 0)
        simplify(f; start_idx=k)
    end
end

"""
    reverse(f::PiecewiseQuadratic)

Return `f` reversed over the `y` axis. That is, given `f(x)`, return `f(-x)`.

See also: [`reverse`](@ref)
"""
reverse(f::PiecewiseQuadratic) = PiecewiseQuadratic(reverse(reverse.(f)))

"""
    reverse!(f::PiecewiseQuadratic)
    reverse!(f::PiecewiseQuadratic, out::PiecewiseQuadratic)

Reverse `f` inplace.

See also: [`reverse`](@ref)
"""
reverse!(f::PiecewiseQuadratic) = reverse!(f, f)
reverse!(f::PiecewiseQuadratic, out::PiecewiseQuadratic) = copy!(out, reverse(f))

"""
     simplify(f::PiecewiseQuadratic)

Return a simplified piecewise quadratic `f`.

A BoundedQuadratic `f_i` and and the current rightmost piece should be combined (to become the new rightmost piece) if
* Either of `f_i` or the rightmost piece is a point and they overlap at their lower and upper endpoints respectively
* `f_i` and the rightmost piece have the same coefficients and they correspond at their lower and upper endpoints respectively (they're just currently separate parts of the same function).

We also eliminate functions that are points at Inf or -Inf if they come up.

# Example
```jldoctest
julia> f = PiecewiseQuadratic([BoundedQuadratic(-1., 0., 0., -1., 0.),
                                      BoundedQuadratic(0., 0., 0., 0., 0.),
                                      BoundedQuadratic(0., 1., 0., 1., 0.),
                                      BoundedQuadratic(1., 2., 0., 1., 0.),
                                      BoundedQuadratic(3., 5., 1., 1., 1.)])
Piecewise quadratic function:
BoundedQuadratic: f(x) = - 1.00000 x , ∀x ∈ [-1.00000, 0.00000]
BoundedQuadratic: f(x) = 0, ∀x ∈ [0.00000, 0.00000]
BoundedQuadratic: f(x) = + 1.00000 x , ∀x ∈ [0.00000, 1.00000]
BoundedQuadratic: f(x) = + 1.00000 x , ∀x ∈ [1.00000, 2.00000]
BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [3.00000, 5.00000]

julia> simplify(f)
Piecewise quadratic function:
BoundedQuadratic: f(x) = - 1.00000 x , ∀x ∈ [-1.00000, 0.00000]
BoundedQuadratic: f(x) = + 1.00000 x , ∀x ∈ [0.00000, 2.00000]
BoundedQuadratic: f(x) = 1.00000 x² + 1.00000 x + 1.00000, ∀x ∈ [3.00000, 5.00000]

```
"""
function simplify(f::PiecewiseQuadratic)
    front, back = 1, length(f)
    if isempty(f[front])
        front += 1
    end
    # out = FixedMemoryPwq(back-front)
    out = PiecewiseQuadratic()
    push!(out, f[front])
    for (i, fi) in enumerate(f[(front + 1):end])
        if isempty(fi)
            continue
        end
        prev = out[end]

        val = fi(fi.lb)
        prev_val = prev(prev.ub)
        # if we have redundant points, keep the one with minimum value
        if is_point(prev) && is_point(fi) && prev.ub ≈ fi.lb
            # ignore right point if greater than the value of the left
            if prev_val ≳ val
                out[end] = fi
            end
        elseif continuous_and_overlapping(prev, fi) && (is_point(prev) || is_point(fi)) ||
               extend_dom(prev) ≈ extend_dom(fi)
            # take the coefficients of whichever function is not a point.
            # note: if we are combining and neither function is a point, both coefficient sets must be
            # the same, so it doesn't matter which we take.
            non_point = is_point(prev) ? fi : prev
            combined = restrict_dom(extend_dom(non_point), prev.lb, fi.ub)
            out[end] = combined
        elseif is_point(fi) && prev.ub ≈ fi.lb && val ≳ prev_val
            continue  # ignore
        elseif is_point(prev) && prev.ub ≈ fi.lb && prev_val ≳ val
            out[end] = fi  # replace
        else
            # no combination, add the current piece
            push!(out, fi)
        end
    end
    return out
end

"""
    sum(f_list::Vector{PiecewiseQuadratic})

Return the PiecewiseQuadratic sum of a list of PiecewiseQuadratics.

# Example
```jldoctest
julia> f = PiecewiseQuadratic([BoundedQuadratic(-1., 0., 0., -5., 0.),
                               BoundedQuadratic(0., 2., 0., 2., 0.)])
Piecewise quadratic function:
BoundedQuadratic: f(x) = - 5.00000 x , ∀x ∈ [-1.00000, 0.00000]
BoundedQuadratic: f(x) = + 2.00000 x , ∀x ∈ [0.00000, 2.00000]

julia> sum([f,f])
Piecewise quadratic function:
BoundedQuadratic: f(x) = - 10.00000 x , ∀x ∈ [-1.00000, 0.00000]
BoundedQuadratic: f(x) = + 4.00000 x , ∀x ∈ [0.00000, 2.00000]

julia> sum([f,-f])
Piecewise quadratic function:
BoundedQuadratic: f(x) = 0, ∀x ∈ [-1.00000, 0.00000]
BoundedQuadratic: f(x) = 0, ∀x ∈ [0.00000, 2.00000]

```
"""
function sum(f_list::Vector{PiecewiseQuadratic})
    work = PwqSumWorkspace(length(f_list))
    return _sum(f_list, work)
end

mutable struct PwqSumWorkspace
    f_active::Vector{BoundedQuadratic}
    active_idxs::Vector{Int64}
    active::BitArray
    ubs::Vector{Float64}
    next_fun_idxs::BitArray
    k::Int64

    function PwqSumWorkspace(k::Int64)
        f_active = Vector{BoundedQuadratic}(undef, k)
        active_idxs = Vector{Int64}(undef, k)
        active = BitArray(undef, k)
        ubs = Vector{Float64}(undef, k)
        next_fun_idxs = BitArray(undef, k)
        return new(f_active, active_idxs, active, ubs, next_fun_idxs, k)
    end
end

function _sum(f_list::Vector{PiecewiseQuadratic}, w::PwqSumWorkspace)
    k = length(f_list)
    @assert w.k == k
    @assert k > 0

    # Currently active functions
    for i in 1:k
        w.f_active[i] = f_list[i][1]
        w.active_idxs[i] = 1
        w.active[i] = length(f_list[i]) > 1
    end

    # Output function:
    g = PiecewiseQuadratic()
    sum_active, is_valid = _sum(w.f_active)
    if is_valid
        push!(g, sum(w.f_active))
    end

    # Loop to sum functions:
    while any(w.active)

        # Populate next_fun_idxs with all active functions with minimum upper bound:
        _get_min_ub!(w.f_active, w.active, w.ubs, w.next_fun_idxs)

        for i in 1:k
            if w.next_fun_idxs[i]
                w.active_idxs[i] += 1
                w.active[i] = w.active_idxs[i] < length(f_list[i])
                w.f_active[i] = f_list[i][w.active_idxs[i]]
            end
        end

        # Append the sum, if the domain is not empty:
        sum_active, is_valid = _sum(w.f_active)
        if is_valid
            push!(g, sum_active)
        end
    end
    return g
end

function _get_min_ub!(f_vec::Vector{BoundedQuadratic}, eligible::BitArray,
                      ubs::Vector{Float64}, idxs::BitArray)
    k = length(f_vec)
    ub_min = Inf
    for i in 1:k
        if eligible[i]
            ubs[i] = f_vec[i].ub
            ub_min = min(ubs[i], ub_min)
        end
    end
    for i in 1:k
        idxs[i] = eligible[i] && ubs[i] == ub_min
    end
end

function _get_min_ub(f_vec::Vector{BoundedQuadratic}, eligible::BitArray)
    k = length(f_vec)
    @assert k == length(eligible)
    ubs_and_idxs = [(fi.ub, i) for (i, fi) in enumerate(f_vec)][eligible]
    ub_min = minimum([ui[1] for ui in ubs_and_idxs])
    # Select all upper bounds equal to the minimum:
    idxs = [i for (ub, i) in ubs_and_idxs if (ub == ub_min)]
    return idxs
end

function _get_min_ub(f_vec::Vector{BoundedQuadratic}, eligible::Vector{Bool})
    return _get_min_ub(f_vec, convert(BitArray, eligible))
end

"""
    minimize(f::PiecewiseQuadratic)

Return the minimum `x` and `f(x)` of `f` over its domain.
"""
function minimize(f::PiecewiseQuadratic)
    v_star = Inf
    x_star = NaN
    for fi in f
        xi, vi = minimize(fi)
        if vi < v_star
            x_star = xi
            v_star = vi
        end
    end
    return x_star, v_star
end

"""
    prox(f::PiecewiseQuadratic, u::Float64[, ρ::Float64=1.0]; use_quadratic::Bool=true)

Return the proximal operator of `f`, `ρ` evaluated at `u`.

# Note: The proximal operator of `f`, `rho` is denoted:
```math
prox_{f, rho}(u) = argmin_{x ∈ dom(f)} f(x) + (rho / 2)||x - u||_2^2
```

See Section 6.2 of [arXiv:2103.05455](https://arxiv.org/abs/2103.05455) for more information.
"""
function prox(f::PiecewiseQuadratic, u::Float64, ρ::Float64=1.0; use_quadratic::Bool=true)
    ub_last = -Inf
    for fi in f
        p_adj = 2 * fi.p + (use_quadratic ? ρ : 0.0)
        lb = p_adj * fi.lb + fi.q
        ub = p_adj * fi.ub + fi.q
        if ub_last ≤ ρ * u ≤ lb
            return fi.lb
        elseif lb ≤ ρ * u ≤ ub
            return (ρ * u - fi.q) / p_adj
        end
        ub_last = ub
    end
    return f[end].ub
end

"""
    get_plot(f::PiecewiseQuadratic; N::Int64=1000)

Return `x`, `y` `N`-vectors for use with plotting libraries.

# Example
```julia
julia> using Plots

julia> f = PiecewiseQuadratic([
         BoundedQuadratic(-Inf, 3.0, 1.0, -3.0, 3.0),
         BoundedQuadratic(3.0, 4.0, 0.0, -1.0, 3.0),
         BoundedQuadratic(4.0, 6.0, 2.0, -20.0, 47.0),
         BoundedQuadratic(6.0, 7.5, 0.0, 1.0, -7.0),
         BoundedQuadratic(7.5, Inf, 0.0, 4.0, -29.0)
       ])
Piecewise quadratic function:
BoundedQuadratic: f(x) = 1.00000 x² - 3.00000 x + 3.00000, ∀x ∈ [-Inf, 3.00000]
BoundedQuadratic: f(x) = - 1.00000 x + 3.00000, ∀x ∈ [3.00000, 4.00000]
BoundedQuadratic: f(x) = 2.00000 x² - 20.00000 x + 47.00000, ∀x ∈ [4.00000, 6.00000]
BoundedQuadratic: f(x) = + 1.00000 x - 7.00000, ∀x ∈ [6.00000, 7.50000]
BoundedQuadratic: f(x) = + 4.00000 x - 29.00000, ∀x ∈ [7.50000, Inf]

julia> plot(get_plot(f); grid=false, linestyle=:dash, color=:black, label="piece-wise quadratic")
Plot{Plots.GRBackend() n=1}

julia> plot!(get_plot(simplify(envelope(f))); color=:blue, la=0.5, label="envelope")
Plot{Plots.GRBackend() n=2}

```
"""
function get_plot(f::PiecewiseQuadratic; N::Int64=1000)
    x = vcat([[fi.lb, fi.ub] for fi in f]...)
    x = x[isfinite.(x)]
    if isempty(x)
        x = [-5.0, 5]
    end
    x_min = minimum(x)
    x_max = maximum(x)
    span = x_max - x_min
    if span == 0.0
        span = 2.0
    end
    x_min -= 1 * span
    x_max += 1 * span
    x = vcat(range(x_min, x_max; length=N), x)
    x = sort(x)
    x = [x0 for (x0, x1) in zip(x[1:(end - 1)], x[2:end]) if x0 != x1]
    y = f.(x)
    return x, y
end
