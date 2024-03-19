using ReplMaker

function parse_to_expr(s)
    quote Meta.parse($s) end
end
;

initrepl(parse_to_expr, 
                prompt_text="Expr> ",
                prompt_color = :blue, 
                start_key=')', 
                mode_name="Expr_mode")

