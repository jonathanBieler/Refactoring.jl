# Refactoring.jl

[![Build Status](https://travis-ci.com/jonathanBieler/Refactoring.jl.svg?branch=master)](https://travis-ci.com/jonathanBieler/Refactoring.jl)
[![Coverage Status](https://coveralls.io/repos/github/jonathanBieler/Refactoring.jl/badge.svg?branch=master)](https://coveralls.io/github/jonathanBieler/Refactoring.jl?branch=master)

```julia
using Refactoring

ex = quote
    using Gadfly
    mu = K1
    const alpha = 1
    const beta = (alpha+1)*mu
    for i=1:10
        x = rand(100, f(K2)) 
    end
    plot(x = K3, y = pdf(InverseGamma(K4,beta),K5), Geom.line)
    ind, K7 = K6.asd
    x = [K8[K7] for i=1:K6]
end

julia> unassigned_variables(ex)
7-element Array{Any,1}:
 :K1
 :K2
 :K3
 :K4
 :K5
 :K6
 :K8
```