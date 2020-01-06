using Test
using MLStyle, MacroTools

@testset "search_and_replace" begin

ex = @search_and_replace sin(x) sin(x) cos(x)
@test ex == :( cos(x) )

ex = @search_and_replace sin(y) sin($x) cos($x)
@test ex == :( cos(y) )

ex = @search_and_replace sin(sin(x)) sin($x) cos($x +1)
@test ex == :( cos(cos(x+1) +1) )

end