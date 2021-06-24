# API Documentation

Docstrings for PiecewiseQuadratics.jl interface members can be [accessed through Julia's built-in documentation system](https://docs.julialang.org/en/v1/manual/documentation/#Accessing-Documentation) or in the list below.

```@meta
CurrentModule = PiecewiseQuadratics
```

## Contents

```@contents
Pages = ["api.md"]
Depth = 3
```

## Index

```@index
Pages = ["api.md"]
```


## Types

```@docs
Interval
BoundedQuadratic
PiecewiseQuadratic
FixedMemoryPwq
```

### Constructors

```@docs
zero
indicator
get_line
```

## Functions

### Boolean

```@docs
isempty
is_point
is_almost_point
continuous_and_overlapping
is_convex
```

### Quadratic Manipulation

```@docs
reverse
reverse!
scale
scale!
perspective
perspective!
shift
shift!
tilt
tilt!
restrict_dom
restrict_dom!
extend_dom
extend_dom!
append!
push!
simplify
```

### Utility

```@docs
domain
intersect
derivative
sum
solve_quad
get_tangent
```

### Optimization

```@docs
minimize
envelope
prox
```

### Plotting

```@docs
get_plot
```
