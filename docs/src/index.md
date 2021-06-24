# PiecewiseQuadratics.jl

**PiecewiseQuadratics.jl** is a [Julia](http://julialang.org) package for manipulation of univariate piecewise quadratic functions of the form
```math
f(x) = p x^2 + q x + r, ∀ x ∈ [lb, ub]
```
where:
* `p`, `q`, `r` are scalar
* `x` is the decision variable
* `lb` is the lower bound of `x`
* `ub` is the upper bound of `x`


## Contents

```@contents
Pages = ["index.md", "api.md"]
Depth = 2
```


## Installation
Use Julia's builtin package manager [Pkg](https://docs.julialang.org/en/v1/stdlib/Pkg/) to install.
From a Julia REPL:
```Julia
] add PiecewiseQuadratics
```

## Example
We specify a piecewise quadratic function by providing a list of bounded quadratics in order. Where the pieces overlap, we take the function value to be the minimum over all possible values.

We specify

```math
f(x) = \left\{\begin{array}{ll}
  x^2 - 3x - 3 & \text{if } x \in [-\infty, 3]\\
  x + 3 & \text{if } x \in [3, 4]\\
  2x^2 - 20x + 47 & \text{if } x \in [4, 6]\\
  x - 7 & \text{if } x \in [6, 7.5]\\
  4x - 29 & \text{if } x \in [7.5, \infty]\\
\end{array}\right.
```

as follows:

```@example 1
using PiecewiseQuadratics
f = PiecewiseQuadratic([
  # BoundedQuadratic(lb, ub, p, q, r),
  BoundedQuadratic(-Inf, 3.0, 1.0, -3.0, 3.0),
  BoundedQuadratic(3.0, 4.0, 0.0, -1.0, 3.0),
  BoundedQuadratic(4.0, 6.0, 2.0, -20.0, 47.0),
  BoundedQuadratic(6.0, 7.5, 0.0, 1.0, -7.0),
  BoundedQuadratic(7.5, Inf, 0.0, 4.0, -29.0)
])
```

We can visualize the function using [`get_plot`](@ref) and any common plotting library.
```@example 1
using Plots
plot(get_plot(f); grid=false, linestyle=:dash, color=:black, label="piece-wise quadratic")
plot!(get_plot(simplify(envelope(f))); color=:blue, la=0.5, label="envelope", xlims = (-2, 10), ylims = (-4, 18))
savefig("plot.svg"); nothing # hide
```

![](plot.svg)


## Authors
This package and [LCSO.jl](https://github.com/JuliaFirstOrder/LCSO.jl) were originally developed by [Nicholas Moehle](https://www.nicholasmoehle.com/), [Ellis Brown](http://ellisbrown.github.io), and [Mykel Kochenderfer](https://mykel.kochenderfer.com/) at BlackRock AI Labs.  They were developed to produce the results in the following paper: [arXiv:2103.05455](https://arxiv.org/abs/2103.05455).


## Reference
```@contents
Pages = ["api.md"]
Depth = 3
```
