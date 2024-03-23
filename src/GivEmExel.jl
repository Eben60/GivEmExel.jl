module GivEmExel
using Unitful, DataFrames, XLSX, Preferences
using NativeFileDialog: pick_file
using SimpleArgParse

export pick_file, @load_preference, @set_preferences!, @has_preference
export parse_cl_string
export repl
export emptyargs, prompt_and_parse, proc_ARGS, full_interact

export SimpleArgParse

# temporary exports
export read_units, nt_skipmissing, merge_params, process_data, keys_skipmissing, merge_params, 
    parse_commandline, to_nt, get_xl

include("process_data.jl")
include("parse_ARGS.jl")
include("utils.jl")
include("repl.jl")
include("get_xl.jl")
include("interact.jl")

end
