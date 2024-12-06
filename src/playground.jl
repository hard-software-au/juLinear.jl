using LinearAlgebra
using SparseArrays
using Random
using ArgParse
using DataStructures
using Test

# JuMP
using JuMP
using MathOptInterface
const MOI = MathOptInterface

include("problems/lp_problem_structs.jl")
include("file_formats/lp_file_formater.jl")
include("preprocess/lp_presolve.jl")
include("preprocess/lp_standard_form_converter.jl")
include("solvers/lp_revised_simplex.jl")

mps_folder_path = "../check/problems/mps_files/"
mps_folder_path = "/Users/roryyarr/Desktop/Linear Programming/lp_code/check/Problems/mps_files/"

lp = LPProblem(false, [4.0, 3.0, 1.0, 7.0, 6.0], sparse([1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3], [1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5], [1.0, 2.0, -3.0, 2.0, -1.0, 2.0, 3.0, 2.0, 1.0, 1.0, 2.0, -1.0, -3.0, 1.0, 2.0], 3, 5), [9.0, 10.0, 11.0], ['L', 'L', 'L'], [0.0, 0.0, 0.0, 0.0, 0.0], [Inf, Inf, Inf, Inf, Inf], ["X1", "X2", "X3", "X4", "X5"], [:Continuous, :Continuous, :Continuous, :Continuous, :Continuous])

pre_lp = presolve_lp(lp)

# Profile.Allocs.@profile for _ in 1:10
#     revised_simplex(pre_lp)
# end

# PProf.Allocs.pprof()

using Profile

@profview for _ in 1:10000
    revised_simplex(pre_lp)
end

@profview for _ in 1:100000
    presolve_lp(lp)
end


# @profview for _ in 1:200000
@profview_allocs for _ in 1:200000
    convert_to_standard_form(lp)
end


function profile_test(n)
    for i = 1:n
        A = randn(100,100,20)
        m = maximum(A)
        Am = mapslices(sum, A; dims=2)
        B = A[:,:,5]
        Bsort = mapslices(sort, B; dims=1)
        b = rand(100)
        C = B.*b
    end
end

@profview profile_test(10)


simple = read_mps(mps_folder_path * "simple.mps")
blend = read_mps(mps_folder_path * "blend.mps")
big = read_mps(mps_folder_path * "30n20b8.mps")
# read_mps("/Users/roryyarr/Desktop/Linear Programming/lp_code/check/Problems/mps_files/problem.mps")


spy(simple.A)
spy(blend.A)

using Plots


spy(lp.A)

spy([1 0 0; 0 1 0; 0 0 1])
(1+1)^2

a = spdiagm(0 => ones(50), 1 => ones(49), -1 => ones(49), 10 => ones(40), -10 => ones(40))
b = spdiagm(0 => 1:50, 1 => 1:49, -1 => 1:49, 10 => 1:40, -10 => 1:40)
plot(spy(a), spy(b), title = ["Unique nonzeros" "Different nonzeros"])