# module TypedExpressions

# export econvert
# export AbstractExpr, ECall, EArgs, EAssignment, ETuple, EKeyword

abstract type AbstractExpr end

isa_expr(ex::Expr, ::Type{<:AbstractExpr}) = false
isa_expr(ex::T, ::Type{K}) where {T<:AbstractExpr, K<:AbstractExpr} = T == K

args(ex::T) where T<:AbstractExpr = ex.args
args(ex::Expr) = ex.args

""" ECall """
struct ECall <: AbstractExpr
    fun::Any
    args::Vector{Any}
end
ECall(ex::Expr) = ECall(ex.args[1], ex.args[2:end])
ECall(ex::ECall) = ex
isa_expr(ex::Expr, ::Type{ECall}) = ex.head == :call

""" ETuple """
struct ETuple <: AbstractExpr
    args
end
ETuple(ex::Expr) = ETuple(ex.args)
ETuple(ex::ETuple) = ex
isa_expr(ex::Expr, ::Type{ETuple}) = ex.head == :tuple

""" EAssignment """
struct EAssignment <: AbstractExpr
    lhs
    rhs
end
EAssignment(ex::Expr) = EAssignment(ex.args[1], ex.args[2])
EAssignment(ex::EAssignment) = ex
isa_expr(ex::Expr, ::Type{EAssignment}) = ex.head == :(=)
args(ex::EAssignment) = [ex.lhs; ex.rhs]

""" EUsing """
struct EUsing <: AbstractExpr
    args
end
EUsing(ex::Expr) = EUsing(ex.args)
EUsing(ex::EUsing) = ex
isa_expr(ex::Expr, ::Type{EUsing}) = ex.head == :using

""" EKeyword """
struct EKeyword <: AbstractExpr
    lhs
    rhs
end
EKeyword(ex::Expr) = EKeyword(ex.args[1], ex.args[2])
EKeyword(ex::EKeyword) = ex
isa_expr(ex::Expr, ::Type{EKeyword}) = ex.head == :kw
args(ex::EKeyword) = [ex.lhs; ex.rhs]


""" ERef """
struct ERef <: AbstractExpr
    lhs
    rhs
end
ERef(ex::Expr) = begin
    length(ex.args) == 1 && return ERef(ex.args[1], nothing)
    length(ex.args) == 2 && return ERef(ex.args[1], ex.args[2])
    ERef(ex.args[1], ex.args[2:end])
end
ERef(ex::ERef) = ex
isa_expr(ex::Expr, ::Type{ERef}) = (ex.head == :ref) #&& (length(ex.args) == 2)
args(ex::ERef) = [ex.lhs; ex.rhs]

""" EDot """
struct EDot <: AbstractExpr
    lhs
    rhs
end
EDot(ex::Expr) = EDot(ex.args[1], ex.args[2])
EDot(ex::ERef) = ex
isa_expr(ex::Expr, ::Type{EDot}) = (ex.head == :.) && (length(ex.args) == 2)
args(ex::EDot) = [ex.lhs; ex.rhs]

#

const EExpr = [ECall, ETuple, ERef, EDot, EAssignment, EUsing, EKeyword]#order matters (pobably a bug)
const EArgs = Union{Expr, ECall, ETuple, EUsing}
const EHanded = Union{EAssignment, EKeyword, ERef, EDot}

# go down the tree for each expression type and try to convert
# I should maybe loop at each node instead of at the top
function econvert(ex) 
    for E in EExpr
        ex = econvert(E, ex)
    end
    ex
end

econvert(::Type{<:AbstractExpr}, x) = x

# for EArgs (including Expr), convert arguments, then convert expression
function econvert(::Type{T}, ex::EArgs) where T <: AbstractExpr
    ex = econvert_args(T, ex, ex.args, :args)
    isa_expr(ex, T) ? T(ex) : ex
end

# for EHanded, convert both hands, then convert expression
function econvert(::Type{T}, ex::EHanded) where T <: AbstractExpr
    ex = econvert_args(T, ex, ex.rhs, :rhs)
    ex = econvert_args(T, ex, ex.lhs, :lhs)
    isa_expr(ex, T) ? T(ex) : ex
end

# args argument is just for dispatch, we want to loop over vectors only
function econvert_args(::Type{T}, ex::EArgs, args::Vector, fieldname) where T <: AbstractExpr
    v = getfield(ex, fieldname)
    for i in 1:length(v)
        v[i] = econvert(T, v[i])
    end
    ex
end
# do nothing for Symbols, Numbers, etc.
econvert_args(::Type{T}, ex, args, fieldname) where T <: AbstractExpr = ex



#end