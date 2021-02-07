#!/usr/bin/env julia

# using BioSymbols
# using BioSequences
# using Statistics
#
# include("apiBioFqRecords.jl")

function julia_wrapper_readstat(ARGS)

    help_page = """
    usage: atria readstat [-h] FASTQS...

    positional arguments:
      FASTQS      input trimmed fastqs. caution: raw fastq has to be
                  generated by `atria simulate`.

    optional arguments:
      -h, --help  show this help message and exit
    """

    if "-h" in ARGS || "--help" in ARGS || length(ARGS) == 0
        println(help_page)
        return 0
    end

    time0 = time()

    map(peReadSimulatorStats_main, ARGS)

    @info "read simulation stats: all done" elapsed=time() - time0
    return 0
end

@inline function fastq_parser(r::FqRecord)
    splitted = split(String(copy(r.id)), " ")

    # read validate
    if length(splitted) < 7 || !occursin("@PeReadSimulator", splitted[1])
        @error "read simulation stats: read format invalid: reads should be simulated by peReadSimulator and read headers should be intact." invalid_header=String(r.id) _module=nothing _group=nothing _id=nothing _file=nothing
        exit(3)
    end

    seq_id = splitted[1]
    true_length = parse(Int64, splitted[2][6:end])
    insert_size = parse(Int64, splitted[3][13:end])
    error_rate = parse(Float64, splitted[4][12:end])
    seq_length = parse(Int64, splitted[5][12:end])
    error_insert = parse(Int64, splitted[6][14:end])
    error_adapter = parse(Int64, splitted[7][15:end])

    if r.seq == dna"N"  # compatible with Atria
        trimmed_length = 0
    else
        trimmed_length = length(r.seq)
    end

    delta_length = true_length - trimmed_length
    is_trim_successful = trimmed_length == true_length
    return (seq_id, seq_length, insert_size, error_rate, error_insert, error_adapter, true_length, trimmed_length, delta_length, is_trim_successful)
end

function stats(n_repeat::Int64, overtrim_deviations::Vector{Int64}, undertrim_deviations::Vector{Int64})
    n_overtrim  = length(overtrim_deviations )
    n_undertrim = length(undertrim_deviations)

    rate_precision = (n_repeat - n_overtrim - n_undertrim) / n_repeat
    rate_overtrim  = n_overtrim  / n_repeat
    rate_undertrim = n_undertrim / n_repeat

    median_deviation = 0
    median_deviation_overtrim = 0
    median_deviation_undertrim = 0

    if n_overtrim > 0
        median_deviation_overtrim = median(overtrim_deviations)
    end
    if n_undertrim > 0
        median_deviation_undertrim = median(undertrim_deviations)
    end
    if n_overtrim + n_undertrim > 0
        append!(overtrim_deviations, -undertrim_deviations)
        median_deviation = median!(overtrim_deviations)
    end

    return rate_precision, rate_overtrim, rate_undertrim, median_deviation, median_deviation_overtrim, median_deviation_undertrim
end

function peReadSimulatorStats_main(input::String)
    @info "read simulation stats: start" input

    if !isfile(input)
        @warn "read simulation stats: input FASTQ file not valid: skip" FILE=input _module=nothing _group=nothing _id=nothing _file=nothing
        return nothing
    end

    r = FqRecord()
    io = open(input, "r")

    # check if the file is empty
    if eof(io)
        @warn "read simulation stats: input FASTQ file empty: skip" FILE=input _module=nothing _group=nothing _id=nothing _file=nothing
        return nothing
    end

    # table = fastq_parser(input::String)
    # generate stat-detail.tsv
    stat_detail = open(input * ".stat-detail.tsv", "w+")

    stat_detail_header = "seq_id\tseq_length\tinsert_size\terror_rate\terror_insert\terror_adapter\ttrue_length\ttrimmed_length\tdelta_length\tis_trim_successful"
    println(stat_detail, stat_detail_header)

    stat_summary = open(input * ".stat.tsv", "w+")
    stat_summary_header = "seq_length\tinsert_size\terror_rate\trepeat\tprecision\trate_overtrim\trate_undertrim\tdeviation\tdeviation_overtrim\tdeviation_undertrim"
    println(stat_summary, stat_summary_header)

    ### first read
    fqreadrecord!(r::FqRecord, io::IO)

    read_stat = fastq_parser(r)
    println(stat_detail, join(read_stat, "\t"))

    (seq_id, seq_length, insert_size, error_rate, error_insert, error_adapter, true_length, trimmed_length, delta_length, is_trim_successful) = read_stat

    # identifier
    current_seq_length = seq_length
    current_insert_size = insert_size
    current_error_rate = error_rate

    # stats
    n_repeat = 1

    overtrim_deviations  = Vector{Int64}()
    undertrim_deviations = Vector{Int64}()

    if delta_length > 0
        push!(overtrim_deviations, delta_length)
    elseif delta_length < 0
        push!(undertrim_deviations, delta_length)
    end

    ### other reads
    while !eof(io)
        fqreadrecord!(r::FqRecord, io::IO)

        read_stat = fastq_parser(r)
        println(stat_detail, join(read_stat, "\t"))

        (seq_id, seq_length, insert_size, error_rate, error_insert, error_adapter, true_length, trimmed_length, delta_length, is_trim_successful) = read_stat

        # check identifier
        if current_seq_length == seq_length && current_insert_size == insert_size && current_error_rate == error_rate
            ### same identifier: append
            n_repeat += 1

            if delta_length > 0
                push!(overtrim_deviations, delta_length)
            elseif delta_length < 0
                push!(undertrim_deviations, delta_length)
            end
        else
            ### new identifier: compute stats; refresh variables
            # compute stats
            stats_results = stats(n_repeat, overtrim_deviations, undertrim_deviations)
            stats_results_string = join(Any[current_seq_length, current_insert_size, current_error_rate, n_repeat, stats_results...], "\t")
            println(stat_summary, stats_results_string)

            # refresh variables
            current_seq_length = seq_length
            current_insert_size = insert_size
            current_error_rate = error_rate

            n_repeat = 1

            overtrim_deviations  = Vector{Int64}()
            undertrim_deviations = Vector{Int64}()

            if delta_length > 0
                push!(overtrim_deviations, delta_length)
            elseif delta_length < 0
                push!(undertrim_deviations, delta_length)
            end
        end
    end

    ### compute stats for the last
    stats_results = stats(n_repeat, overtrim_deviations, undertrim_deviations)
    stats_results_string = join(Any[current_seq_length, current_insert_size, current_error_rate, n_repeat, stats_results...], "\t")
    println(stat_summary, stats_results_string)

    ### closing
    close(io)
    close(stat_detail)
    close(stat_summary)

    @info "read simulation stats: output" detail="$input.stat-detail.tsv" summary="$input.stat.tsv"
end