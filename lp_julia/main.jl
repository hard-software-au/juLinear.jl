include("lp_presolve.jl")
using .lpPresolve
using SparseArrays

using SparseArrays


include("read_mps.jl")
using .MPSReader

# Function to get the file path from the user
function get_file_path_from_user()
    if length(ARGS) == 0
        println("Please enter the path to the MPS file:")
        file_path = readline()
    else
        file_path = ARGS[1]
    end
    return file_path
end

# Correct example usage
#file_path = get_file_path_from_user()
file_path = "lp_code/benchmarks/mps_files/ex4-3.mps"

# Read the MPS file
lp = MPSReader.read_mps_from_file(file_path)
#presolved_lp, fixed_vars, obj_adjust = presolve(lp, verbose=true)
println(lp)