macro search_and_replace(ex, search, replace)

    ex = Expr(:quote, ex)
    search = Expr(:quote, search)
    replace = Expr(:quote, replace)
    esc(quote
        subst(x) = MLStyle.@match x begin
            $search => $replace
            _ => x
        end
        MacroTools.prewalk(subst, $ex)
    end)
end

# I would need to use DocumentFormat.jl style code to do this
function search_and_replace(ex::String, search::String, replace::String, eval_fun = ex -> @eval Main $ex)

end