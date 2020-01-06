module Refactoring

    using MacroTools, MLStyle

    export extract_method, unassigned_variables, @search_and_replace

    include("typed_expressions.jl")
    include("extract_method.jl")
    include("search_and_replace.jl")

end # module
