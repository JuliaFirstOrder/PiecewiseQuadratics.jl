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
    FixedMemoryPwq(len::Int64)

Represents piecewise quadratic function with a fixed-length Vector of `BoundedQuadratic`s.

The fields represent:
- `f_list`: a `Vector` of `BoundedQuadratic` functions
- `len`: how many of the `f_list` entries are filled in.
"""
mutable struct FixedMemoryPwq
    f_list::Vector{BoundedQuadratic}
    len::Int64

    function FixedMemoryPwq(len::Int64)
        return new(Vector{BoundedQuadratic}(undef, len), 0)
    end
end

function FixedMemoryPwq(f::Vector{BoundedQuadratic}, len::Int64)
    f_new = FixedMemoryPwq(len)
    k = length(f)
    f_new[1:k] = f
    f_new.len = k
    return f_new
end

FixedMemoryPwq(f::PiecewiseQuadratic, len::Int64) = FixedMemoryPwq(f.f_list, len)
FixedMemoryPwq(f::PiecewiseQuadratic) = FixedMemoryPwq(f, length(f.f_list))

PiecewiseQuadratic(f::FixedMemoryPwq) = PiecewiseQuadratic(f[1:end])

function Base.show(io::IO, f::FixedMemoryPwq)
    print(io, "$(f.len)-element Fixed-memory ")
    print(io, PiecewiseQuadratic(f))
    return
end

length(f::FixedMemoryPwq) = f.len
getindex(f::FixedMemoryPwq, idx) = getindex(f.f_list, idx)
setindex!(f::FixedMemoryPwq, val, idx) = setindex!(f.f_list, val, idx)
lastindex(f::FixedMemoryPwq) = f.len
iterate(f::FixedMemoryPwq) = iterate(f.f_list)
iterate(f::FixedMemoryPwq, i::Int) = iterate(f.f_list, i::Int)
function empty!(f::FixedMemoryPwq)
    return f.len = 0
end

function reverse!(f::FixedMemoryPwq)
    k = length(f)
    if k % 2 == 0
        i = Int64(k / 2)
        j = i + 1
    else
        i = floor(Int64, k / 2)
        j = i + 2
        f[i + 1] = reverse(f[i + 1])
    end
    while i > 0
        rev_fi = reverse(f[i])
        f[i] = reverse(f[j])
        f[j] = rev_fi
        i -= 1
        j += 1
    end
end

function pop!(f::FixedMemoryPwq)
    f.len -= 1
    return f[f.len + 1]
end

function append!(f::FixedMemoryPwq, g::FixedMemoryPwq)
    for i in 1:(g.len)
        f.f_list[f.len + i] = g.f_list[i]
    end
    return f.len += g.len
end

function push!(f::FixedMemoryPwq, g::BoundedQuadratic)
    f.f_list[f.len + 1] = g
    return f.len += 1
end

function append!(f::PiecewiseQuadratic, g::FixedMemoryPwq; simplify_result=false)
    return append!(f, PiecewiseQuadratic(g[1:length(g)]); simplify_result=simplify_result)
end
