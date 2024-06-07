function anyfy_col!(df, cname) 
    df[!, cname] = Vector{Any}(df[!, cname])
    return nothing
end

function prepare_xl(df0)
    df = copy(df0)
    headers = String[]
    for nm in names(df)
        (;colheader, v) = sep_unit(df[!, nm])
        # (eltype(df[!, nm]) <: AbstractString) || 
        anyfy_col!(df, nm)
        push!(headers, colheader)
        colheader == "" || (df[!, nm] = v)
    end
    pushfirst!(df, headers)
    return df
end

function sep_unit(v)
    (eltype(v) <: Quantity) || return (;colheader = "", v)
    colheader = v |> eltype |> unit |> string
    v = v .|> ustrip |> Vector{Any}
    (;colheader, v)
end


"""
    out_paths(f_src) 
        → (;fname, f_src, src_dir, rslt_dir, outf, errf)

From given source file, generates names and paths used for sources and results.

Function `out_paths` is public, not exported.
"""
function out_paths(f_src)
    ! isfile(f_src) && error("file \"$f_src\" do not exist")
    src_dir, fname = splitdir(f_src)
    fname, _ = splitext(fname)
    rslt_dir = joinpath(src_dir, "$(fname)_rslt")
    mkpath(rslt_dir)
    
    outf_name = "$(fname)_rslt.xlsx"
    errf_name = "$(fname)_err.txt"
    outf = joinpath(rslt_dir, outf_name)
    errf = joinpath(rslt_dir, errf_name)

    rm(errf; force=true)

    return (;fname, f_src, src_dir, rslt_dir, outf, errf)
end

"""
    write_errors(errf, errors) → errored::Bool

Saves backtraces of errors into a file.

# Arguments
- `errf`: File where errors will be saved.
- `errors`: Array of backtraces

# Returns
- `errored`: `false` if `errors` was an empty array.

Function `write_errors` is public, not exported.
"""
function write_errors(errf, errors)
    errored = !isempty(errors)
    if errored
        open(errf, "w") do io
            for e in errors
                e = NamedTuple(e)
                (;row, exceptn) = e

                comment = get(e, :comment, "no further info")
                back_trace = get(e, :back_trace, nothing)


                println(io, "row = $row: $comment")
                println(io, "Errored: $exceptn")
                println(io, "-------- backtrace --------")
                if back_trace isa Vector
                    for sf in back_trace
                        println(io, sf)
                    end
                end
                println(io, "_"^80, "\n")
                back_trace
            end
        end
    end
    return errored
end

getplots(itr) = [k => v for (k, v) in pairs(itr) if isplot(v)]

"""
    saveplots(rs, rslt_dir; plotformat = "png", kwargs...) → nothing

Saves plot objects as generated by a data processing function into files of given format.

# Arguments
- `rs`: NamedTuple with the processing results.
- `rslt_dir`: directory where to put files. 

# Keyword arguments
- `plotformat = "png"`: If plotformat == "none", do not save.
- Other kwargs will be ignored.

Function `saveplots` is public, not exported.
"""
function saveplots(rs, rslt_dir; plotformat = "png", kwargs...)
    plotformat = lowercase(string(plotformat))
    plotformat == "none" && return nothing
    subset = get(rs, :subset, 0)
    no = get(rs, :no, subset)
    plot_annotation = get(rs, :plot_annotation, "")
    allplots = getplots(rs)
    singleplot = length(allplots) == 1
    for (k, v) in allplots
        pl = v
        prefix = subset==no ? "fig$no" : "fig$subset-$no"
        singleplot || (prefix *= "_$(k)_")
        fname = "$(prefix)_$plot_annotation.$plotformat"
        fname = replace(fname, " " => "_")
        fl = joinpath(rslt_dir, fname)
        save_plot(pl, fl)
    end
    return nothing
end

"""
    proc_data(xlfile, datafiles, paramsets, procwhole_fn, procsubset_fn, postproc_fn; throwonerr=false) 
        → (; overview, subsets_results, résumé, errors)

Saves `DataFrames` as generated by the three data processing functions into (multiple) tables of an XLSX file

# Arguments
- `overview`, `subsets_results`, `résumé`::NamedTuple: Results of actual data processing in the form (; dataframes=(;df1, df2...), ...). 
    The key 'dataframes' is optional.
- `outf`: target XLSX file.

# Returns
- `dfs`: a NamedTuple of DataFrames

Function `proc_data` ???.
"""
function proc_data(xlfile, datafiles, paramsets, procwhole_fn, procsubset_fn, postproc_fn; throwonerr=false)
    subsets_results = []
    errors = []
    overview = résumé = (;)
    try
        isnothing(procwhole_fn) || (overview = procwhole_fn(xlfile, datafiles, paramsets))
        if !isnothing(procsubset_fn)
            for (i, pm_subset) in pairs(paramsets)
                try
                    push!(subsets_results, procsubset_fn(i, pm_subset, overview, xlfile, datafiles, paramsets))
                catch exceptn
                    back_trace = stacktrace(catch_backtrace())
                    comment = get(pm_subset, :comment, "")
                    push!(errors, (;row=i, comment, exceptn, back_trace))
                    throwonerr && rethrow(exceptn)
                end    
            end
        end
        isnothing(postproc_fn) || (résumé = postproc_fn(xlfile, datafiles, paramsets, overview, subsets_results))
    catch exceptn
        back_trace = stacktrace(catch_backtrace())
        push!(errors,(;row=-1, comment="error opening of processing data file", exceptn, back_trace))
        throwonerr && rethrow(exceptn)
    end
    return (; overview, subsets_results, résumé, errors)
end

"""
    combine2df(subsets_results) → DataFrame

Combines `NamedTuple`s (or equivalent) into a dataFrame.

Function `combine2df` is public, not exported.
"""
function combine2df(subsets_results)
    rows = []
    for sr in subsets_results
        r = get(sr, :df_row, nothing)
        isnothing(r) || push!(rows, r)
    end
    isempty(rows) && return nothing
    return DataFrame(rows)
end

"""
    write_xl_tables(fl, nt_dfs; overwrite=true) → Nothing

Writes multiple DataFrames into an XLSX file.

# Arguments
- `fl`: target XLSX file.
- `nt_dfs::NamedTuple`: DataFrames to save. `nt_dfs` keys will map to table names.  

Function `write_xl_tables` is public, not exported.
"""
function write_xl_tables(fl, nt_dfs; overwrite=true)
    ps = [string(k)=>v for (k, v) in pairs(nt_dfs)]
    XLSX.writetable(fl, ps; overwrite)
    return nothing
end

"""
    save_dfs(overview, subsets_results, résumé, outf) → NamedTuple

Saves `DataFrames` as generated by the three data processing functions into (multiple) tables of an XLSX file

# Arguments
- `overview`, `subsets_results`, `résumé`::NamedTuple: Results of actual data processing in the form (; dataframes=(;df1, df2...), ...). 
    The key 'dataframes' is optional.
- `outf`: target XLSX file.

# Returns
- `dfs`: a NamedTuple of DataFrames

Function `save_dfs` is public, not exported.
"""
function save_dfs(overview, subsets_results, résumé, outf)
    subsets_df = combine2df(subsets_results)
    overview_dfs = get(overview, :dataframes, nothing)
    résumé_dfs = get(résumé, :dataframes, nothing)
    isnothing(overview_dfs) && (overview_dfs=(;)) # dataframes field of overview may be abscent, or may be dataframes=nothing
    isnothing(résumé_dfs) && (résumé_dfs=(;))
    dfs = merge(overview_dfs, résumé_dfs)
    if !isnothing(subsets_df) 
        subsets_df = prepare_xl(subsets_df)
        dfs = merge(dfs, (;SubsetsRslt=subsets_df))
    end

    isempty(dfs) || write_xl_tables(outf, dfs)
    return dfs
end

"""
    save_all_plots(overview, subsets_results, résumé, rslt_dir, paramsets) → nothing

Saves plot objects as generated by the three data processing functions into files of given format.

# Arguments
- `overview`, `subsets_results`, `résumé`::NamedTuple: Results of actual data processing in the form (; plots=(;df1, df2...), ...). 
    The key 'plots' is optional.
- `rslt_dir`: directory where to put files.
- `paramsets::Vector{NamedTuple}`: If paramsets[1] has field `plotformat`, it will be the format for saving plots. 

Function `save_all_plots` is public, not exported.
"""
function save_all_plots(overview, subsets_results, résumé, rslt_dir, paramsets)
    overview_plots = get(overview, :plots, nothing)
    résumé_plots = get(résumé, :plots, nothing)
    isnothing(overview_plots) && (overview_plots=(;))
    isnothing(résumé_plots) && (résumé_plots=(;))
    plots = merge(overview_plots, résumé_plots)
    ps1 = paramsets[1]
    ntkwargs = haskey(ps1, :plotformat) ? (; plotformat = ps1.plotformat) : (;)
    if !isempty(plots)
        plots = merge(plots, (;subset=0))
        saveplots(plots, rslt_dir; ntkwargs...)
    end
    for subs in subsets_results
        saveplots(subs.rs, rslt_dir; ntkwargs...);
    end
    return nothing
end

"""
    save_results(results, xlfile, paramsets) → (;dfs)

Calls the functions [`save_dfs`](@ref), [`save_all_plots`](@ref), [`write_errors`](@ref) to save the results and errors.

# Arguments
- `results`: `NamedTuple` having structure `(; overview, subsets_results, résumé, errors)`
- `overview`, `subsets_results`, `résumé`::NamedTuple: Results of actual data processing in the form (; plots=(;df1, df2...), ...). 
    The key 'plots' is optional.
- `xlfile`: Path to the XLSX file with the parameter.
- `paramsets::Vector{NamedTuple}` 

# Returned value
- `(;dfs)`: A NamedTuple of DataFrames as returned by [`save_dfs`]:(@ref) 

Function `save_results` is public, not exported.
"""
function save_results(results, xlfile, paramsets)
    (; overview, subsets_results, résumé, errors) = results
    (;fname, f_src, src_dir, rslt_dir, outf, errf) = out_paths(xlfile)
    dfs = save_dfs(overview, subsets_results, résumé, outf)
    save_all_plots(overview, subsets_results, résumé, rslt_dir, paramsets)
    write_errors(errf, errors)
    return (;dfs)
end

function proc_n_save(procwhole_fn, procsubset_fn, postproc_fn;
        xlfile,
        datafiles=nothing, 
        paramsets = [(;)],
        # paramtables=(;setup="params_setup", exper="params_experiment"),
        )
    throwonerr = get(paramsets[1], :throwonerr, false)
    # (;df_setup, df_exp) = read_xl_paramtables(xlfile; paramtables)
    # paramsets = exper_paramsets(paramsets, df_exp, df_setup);
    results = proc_data(xlfile, datafiles, paramsets, procwhole_fn, procsubset_fn, postproc_fn; throwonerr)
    (; overview, subsets_results, résumé, errors) = results
    (;dfs) = save_results(results, xlfile, paramsets)
    return (; overview, subsets_results, résumé, errors, dfs) 
end
