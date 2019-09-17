## assignments
# init methods
assignements(ex::EArgs, assigned=[]) =
    begin map(x -> assignements(x, assigned), ex.args); unique(assigned) end

assignements(ex::EHanded, assigned=[]) =
    begin map(x -> assignements(x, assigned), [ex.rhs; ex.lhs]);  unique(assigned) end

assignements(ex::ECall, assigned=[]) =
    begin map(x -> assignements(x, assigned), [ex.fun; ex.args]); unique(assigned) end

assignements(ex, assigned) = nothing
assignements(ex::Symbol, assigned) = nothing

# collect methods
function assignements(ex::EAssignment, assigned=[]) 
    assignements(ex, ex.lhs, assigned)
    assignements(ex.rhs, assigned) #propagate on the rhs
    unique(assigned)
end

assignements(ex::EAssignment, lhs::Symbol, assigned) = push!(assigned, lhs)
assignements(ex::EAssignment, lhs::ECall,  assigned) = push!(assigned, lhs.fun)
assignements(ex::EAssignment, lhs::ETuple, assigned) = append!(assigned, lhs.args)

## variables
variables(ex::Union{Expr,AbstractExpr}, vars=[]) = begin map(x -> variables(x,vars), args(ex)); unique(vars) end
variables(ex::Vector, vars) = begin map(x -> variables(x,vars), ex); unique(vars) end
variables(ex, vars) = nothing

# when we have an assignement switch to 4 args form
function variables(ex::EAssignment, vars=[]) 
    variables(ex, ex.lhs, ex.rhs, vars)
    unique(vars)
end
# f(x,y) = x*y + C : ignore x and y
function variables(ex::EAssignment, lhs::ECall, rhs, vars) 
    ignore = variables(lhs)
    rhs_vars = variables(rhs)
    append!(vars, setdiff(rhs_vars, ignore))
    unique(vars)
end
# otherwise keep going
function variables(ex::EAssignment, lhs, rhs, vars) 
    variables(lhs, vars)
    variables(rhs, vars)
    unique(vars)
end

variables(ex::Symbol, vars) = push!(vars, ex)
variables(ex::ECall,  vars)  = variables(ex.args, vars) #skip the function name
variables(ex::EKeyword, vars) = variables(ex.rhs, vars) #skip the lhs
variables(ex::EUsing, vars) = nothing

function _unassigned_variables(ex)
    vars = variables(ex)
    assigned = assignements(ex)

    uvars = setdiff(vars, assigned)
    filter(filter_variable, uvars)
end
unassigned_variables(ex::Expr) = _unassigned_variables(econvert(ex))
unassigned_variables(ex::AbstractExpr) = _unassigned_variables(ex)

function filter_variable(s::Symbol)
    try
        t = @eval Main typeof($s)
        t <: DataType && return false
        t <: Module && return false
        t <: Type && return false
    catch err
    end
    true
end