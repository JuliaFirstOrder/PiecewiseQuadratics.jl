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
    Interval(lb::Real, ub::Real)

Represents a univariate interval.

The fields represent:
- `lb`: Lower bound of the interval
- `ub`: Upper bound of the interval

# Example
```jldoctest
julia> interval = Interval(0., 1.)
[0.00000, 1.00000]

julia> Interval()
ℝ

```
"""
mutable struct Interval
    lb::Float64
    ub::Float64
    function Interval(lb::Real, ub::Real)
        @assert !isnan(lb)
        @assert !isnan(ub)
        return new(lb, ub)
    end
end

Interval() = Interval(-Inf, Inf)

function Base.show(io::IO, A::Interval)
    if A.lb == -Inf && A.ub == Inf
        @printf(io, "ℝ\n")
    else
        @printf(io, "[%.5f, %.5f]\n", A.lb, A.ub)
    end
end

#####
##### Boolean
#####

"""
    isempty(A::Interval)

Return `true` if the interval `A` is empty (`isempty(A::Interval)`).
"""
isempty(A::Interval) = A.lb > A.ub

∈(x::Real, A::Interval) = (x ≥ A.lb) & (x ≤ A.ub)

function ⊆(A::Interval, B::Interval)
    return (A.lb ∈ B) & (A.ub ∈ B)
end

==(A::Interval, B::Interval) = (A.lb == B.lb) && (A.ub == B.ub)

≈(A::Interval, B::Interval) = (A.lb ≈ B.lb) && (A.ub ≈ B.ub)

function <(A::Interval, B::Interval)
    return A.ub < B.lb
end

function >(A::Interval, B::Interval)
    return B < A
end

∩(A::Interval, B::Interval) = Interval(max(A.lb, B.lb), min(A.ub, B.ub))
