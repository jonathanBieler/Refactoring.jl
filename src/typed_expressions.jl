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
EAssignment(ex::Expr) = EAssignment(ex.args[1],ex.args[2])
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
EKeyword(ex::Expr) = EKeyword(ex.args[1],ex.args[2])
EKeyword(ex::EKeyword) = ex
isa_expr(ex::Expr, ::Type{EKeyword}) = ex.head == :kw
args(ex::EKeyword) = [ex.lhs; ex.rhs]

const EExpr = [ECall, ETuple, EAssignment, EUsing, EKeyword]
const EArgs = Union{Expr, ECall, ETuple, EUsing}
const EHanded = Union{EAssignment, EKeyword}

# I should maybe loop at each node instead of at the top
function econvert(ex) 
    for E in EExpr
        ex = econvert(E, ex)
    end
    ex
end

econvert(::Type{<:AbstractExpr}, x) = x

function econvert(::Type{T}, ex::EArgs) where T <: AbstractExpr
    ex = econvert(T, ex, ex.args)
    isa_expr(ex,T) ? T(ex) : ex
end
function econvert(::Type{T}, ex, args::Vector) where T <: AbstractExpr
    for i in 1:length(ex.args)
        ex.args[i] = econvert(T, ex.args[i])
    end
    ex
end
econvert(::Type{T}, ex, args) where T <: AbstractExpr = ex

function econvert(::Type{T}, ex::EHanded) where T <: AbstractExpr
    ex = econvert(T, ex, ex.rhs)
    ex = econvert(T, ex, ex.lhs)
    isa_expr(ex,T) ? T(ex) : ex
end

#end