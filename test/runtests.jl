using Refactoring
using Test

@testset "Refactoring.jl" begin

    ex = Refactoring.econvert(Meta.parse("x[i] = 1"))
    @test ex.lhs.lhs == :x
    @test ex.lhs.rhs == :i
     
    include("test_extract_method.jl")
    include("test_search_and_replace.jl")

end
