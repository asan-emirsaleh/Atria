
module Atria

# using ArgParse
# using BioSymbols
# using BioSequences
# using Printf
# using JSON
# using Statistics
# using DelimitedFiles
# using Distributed
# using Base.Threads
# using TimerOutputs
# using Logging
# using DataStructures
# using Markdown

include(joinpath("BioBits", "BioBits.jl"))
using .BioBits

include(joinpath("FqRecords", "FqRecords.jl"))
using .FqRecords

include(joinpath("Trimmer", "Trimmer.jl"))
using .Trimmer

include(joinpath("Benchmark", "Benchmark.jl"))
using .Benchmark

include(joinpath("AtriaTest", "AtriaTest.jl"))
using .AtriaTest


function julia_main()

    help_programs = """
    Available programs:
        atria       Pair-end trimming software (default)
        simulate    Generate artificial pair-end reads
        randtrim    Randomly trim R1 or R2 at a random position
        readstat    Collect trimming statistics
                        (reads should be generated by `atria simulate`)
        statplot    Plot trimming statistics
                        (`Rscript` in PATH required)
        test        Test Atria program
        p | prog    Show this program list
    """

    if length(ARGS)::Int64 >= 1
        if ARGS[1] in ["prog", "p"]
            println(help_programs)
        elseif ARGS[1] in ("atria", "Atria")
            if "-R" in ARGS || "--read2" in ARGS
                # paired-end
                julia_wrapper_atria(ARGS[2:end]::Vector{String})
            else
                julia_wrapper_atria_single_end(ARGS[2:end]::Vector{String})
            end
        elseif ARGS[1] == "simulate"
            julia_wrapper_simulate(ARGS[2:end]::Vector{String})
        elseif ARGS[1] == "randtrim"
            julia_wrapper_randtrim(ARGS[2:end]::Vector{String})
        elseif ARGS[1] == "readstat"
            julia_wrapper_readstat(ARGS[2:end]::Vector{String})
        elseif ARGS[1] == "statplot"
            julia_wrapper_rscript(statplot_code, ARGS[2:end]::Vector{String})
        elseif ARGS[1] == "test"
            test_atria()
        else
            if "-R" in ARGS || "--read2" in ARGS
                # paired-end
                julia_wrapper_atria(ARGS::Vector{String})
            else
                julia_wrapper_atria_single_end(ARGS::Vector{String})
            end
        end
    else
        atria_markdown_help()
    end
    return 0
end



end  # module end
