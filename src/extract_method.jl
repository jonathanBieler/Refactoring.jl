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
assignements(ex::EAssignment, lhs::ERef,   assigned) = push!(assigned, lhs.lhs)
assignements(ex::EAssignment, lhs::EDot,   assigned) = assigned #e.g. x.a = b, x is not assigned
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

function _unassigned_variables(ex, eval_type)
    vars = variables(ex)
    assigned = assignements(ex)

    uvars = setdiff(vars, assigned)
    filter(s -> filter_variable(s, eval_type), uvars)
end
unassigned_variables(ex::Expr, eval_type) = _unassigned_variables(econvert(ex), eval_type)
unassigned_variables(ex::AbstractExpr, eval_type) = _unassigned_variables(ex, eval_type)

function filter_variable(s::Symbol, eval_type)
    try
        t = eval_type(s)
        t <: DataType && return false
        t <: Module && return false
        t <: Type && return false
    catch err
    end
    true
end

function indent_body(body, tab)

    lines = split(body,"\n")
    ident_length = [length(l) - length(lstrip(l)) for l in lines]
    line_length  = [length(l) for l in lines]
    
    min_ident = minimum( ident_length[line_length.>0] )
     
    lines = [tab * l[(1+min_ident):end] for l in lines]
    
    join(lines, "\n")
end

function extract_method(body, tab = "    ", eval_type = s -> @eval Main typeof($s))

    ex  = try 
        ex = Base.parse_input_line(body)
    catch err
        println(err)
        return ""
    end
    
    args = unassigned_variables(ex, eval_type)
    sargs = join(args, ", ")
    
    body = indent_body(body, tab)
        
"
function ($sargs)
$body
end
"
end
