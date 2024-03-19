using ReplMaker

function parse_to_expr(s)
    quote eval(Meta.parse($s)) end
end

function go()
    if !isinteractive()
        @info "Session is not interactive"
        return
    end
    initrepl(parse_to_expr;
             prompt_text="eval> ",
             prompt_color=:magenta,
             start_key=')',
             mode_name=:evaluation,)
end