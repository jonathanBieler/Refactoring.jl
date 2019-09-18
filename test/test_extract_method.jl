using Test

import Refactoring: econvert, variables, assignements

@testset "extract method" begin

ex = Meta.parse("x = 1")
ex = econvert(ex)
@test variables(ex) == [:x]
@test assignements(ex) == [:x]

ex = Meta.parse("x,y = 1,2")
ex = econvert(ex)
@test variables(ex) == [:x,:y]
@test assignements(ex) == [:x,:y]

ex = Meta.parse("f(x) = x")
ex = econvert(ex)
@test variables(ex) == []
@test assignements(ex) == [:f]

ex = Meta.parse("f(x=1, y=rand(N))")
ex = econvert(ex)
@test variables(ex) == [:N]
@test assignements(ex) == []

ex = quote 
    x,y,z,k = 1,c,3,4
    g = x*d
end
ex = econvert(ex)
@test variables(ex) == [:x,:y,:z,:k,:c,:g,:d]
@test assignements(ex) == [:x,:y,:z,:k,:g]
@test unassigned_variables(ex) == [:c,:d]

@test unassigned_variables(quote 
    x,y,z,k = 1,2,3,4
    g = x*y
end) == Symbol[]

if !@isdefined Geom
    @eval Main module Geom end
end

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
@test unassigned_variables(ex) == [:K1,:K2,:K3,:K4,:K5,:K6,:K8] 

ex = quote
    pmin = pinit
    para = zeros(length(pmin),Niter)
    lik, lr = Float64[], Float64[]
    res = DiffBase.GradientResult(pmin)
    w = ones(length(pmin)); #w[1] *= 0.1
end
@test unassigned_variables(ex) == [:pinit, :Niter] 

ex = quote
    x = f(Int, Base, sin)
    y = cos(x)
end
@test unassigned_variables(ex) == [:sin]

# comprehensions
ex = quote
    x = [i for i=1:10]
end
@test unassigned_variables(ex) == []

ex = quote
    x = [i for i=1:N]
end
@test unassigned_variables(ex) == [:N]

ex = quote
    x = [f(i,k) for i=1:length(N)]
end
@test unassigned_variables(ex) == [:k,:N]

ex = quote
    f(x,y) = x*y + a
    ex = f(1,2)
end
@test unassigned_variables(ex) == [:a] 

ex = quote
    sel  = df[Symbol("col")] .== "x"
end
@test unassigned_variables(ex) == [:df] 

ex = quote
    sel  = df[Symbol(S)] .== "x"
end
@test unassigned_variables(ex) == [:df, :S] 

ex = quote
    sel  = df[Symbol(S)] .== x
end
@test unassigned_variables(ex) == [:df, :S, :x] 

ex = quote
    for y in umks
        for umk in y
            u1, u2 = split_umk(umk)
            d_ = Mod.distance(u1,u2)
            P[length(u1),length(u2)] += 1
            if d_ > 3
                push!(j,(u1,u2))
            end
            push!(d, d_)
        end
    end
end
@test unassigned_variables(ex) == [:umks, :P, :j, :d] 

m = extract_method("x = sin(y)")
@test m == 
"
function (y)
    x = sin(y)
end
"

end