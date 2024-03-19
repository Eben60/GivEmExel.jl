using ReplMaker

backwards_show(io, M, x) = (show(io, M, x); println(io))
backwards_show(io, M, v::Union{Vector, Tuple}) = (show(io, M, reverse(v)); println(io))



initrepl(Meta.parse,
                show_function = backwards_show,
                prompt_text = "reverse_julia> ",
                start_key = '>',
                mode_name = "reverse mode")