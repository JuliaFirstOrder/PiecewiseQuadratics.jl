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

module PiecewiseQuadratics

import Base: sum, length, iterate, getindex, setindex!, lastindex, push!, append!
import Base: copy, zero, convert, +, *, ==, ≈, -, ∈, ⊆, <, ≤, ≥, >, ∩, display, show,
             reverse
import Base: pop!, isempty, intersect, empty!
using Printf

# Basic types
export Interval, BoundedQuadratic, PiecewiseQuadratic, FixedMemoryPwq, PwqSumWorkspace

# Operations
export <, >, ≤, ≥, ≲, ≳, ==, ≈, ⊆, ∈
export isempty, is_point, is_almost_point, continuous_and_overlapping, is_convex
export +, -, *, ∩
export sum, intersect, minimize, derivative, _sum

export copy, copy!, display, show, domain
export zero, indicator, get_line, get_tangent, domain

export reverse, scale, perspective, shift, tilt, restrict_dom, extend_dom
export reverse!, scale!, perspective!, shift!, tilt!, restrict_dom!, extend_dom!

export envelope, append_envelope!

export getindex, setindex!, lastindex, iterate, length, pop!, push!, append!
export mult_scalar!, simplify, prox, get_plot

include("intervals.jl")
include("utils.jl")
include("bounded_quadratics.jl")
include("piecewise_quadratics.jl")
include("fixed_memory_pwq.jl")
include("envelope.jl")

end
