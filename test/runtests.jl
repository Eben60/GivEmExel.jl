using GivEmExel
using Test, Unitful

using GivEmExel: read_xl_paramtables, merge_params, nt_skipmissing, read_units, mergent

@testset "GivEmExel" begin

p = joinpath(@__DIR__, "..", "data/testset.xlsx")
(;df_setup, df_exp) = read_xl_paramtables(p)
(nt1, nt_exp1, nt_setup) = merge_params(df_exp, df_setup, 1)
(nt2, nt_exp2, ) = merge_params(df_exp, df_setup, 2)

@show nt1
@show nt2

@test nt_skipmissing((;a=1.0, b=missing, c=2)) == (;a=1.0, c=2)
@test isequal(read_units(df_setup), (; area = u"cm^2", vol = u"mL", temp = u"°C", δvol = missing, p₁ = u"bar", 
                                p₂ = u"bar", V = u"kV", I = u"mA", I0 = u"μA", c = missing))

# @test keys_skipmissing(df_setup[2, :]) == [:area, :vol, :temp, :p₁, :p₂, :V, :I, :I0]

# @test nt1.area == nt_setup.area
# @test nt2.area == nt_exp2.area

@test mergent([:a=>1, :b=>2], (;a="7"), [:c=>8]) == (;a="7", b=2, c=8)

end
;