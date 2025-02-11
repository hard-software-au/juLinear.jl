########################################################################################################################
########################################            test_juLinear.jl            ########################################
########################################################################################################################

#Include test utilities
include("test_helpers.jl")


# Assuming juLinear is in the current namespace after inclusion
@testset "juLinear Tests" begin

    # Test parse_commandline()
    @testset "parse_commandline" begin
        # Simulate command-line arguments
        function test_parse_commandline(args, expected)
            s = ArgParseSettings()
            @add_arg_table! s begin
                "--filename", "-f"
                help = "Path to the problem file (LP or MPS format)"
                default = "default_file.lp"
                arg_type = String
                required = false

                "--interior", "-i"
                help = "Use interior point method (LP only)"
                action = :store_true

                "--no_presolve"
                help = "Do not presolve (default is false)"
                action = :store_true

                "--simplex", "-s"
                help = "Use simplex method (default)"
                action = :store_true

                "--verbose", "-v"
                help = "Verbose output"
                action = :store_true
            end
            parsed_args = parse_args(args, s)
            @test parsed_args["filename"] == expected["filename"]
            @test parsed_args["simplex"] == expected["simplex"]
            @test parsed_args["interior"] == expected["interior"]
            @test parsed_args["no_presolve"] == expected["no_presolve"]
            @test parsed_args["verbose"] == expected["verbose"]
        end

        test_args = ["--filename", "test_problem.lp", "--simplex", "--verbose"]
        expected = Dict(
            "filename" => "test_problem.lp",
            "simplex" => true,
            "interior" => false,
            "no_presolve" => false,
            "verbose" => true
        )
        test_parse_commandline(test_args, expected)
    end

    # Test load_lp_problem()
    @testset "load_lp_problem" begin
        # Mock LPProblem for testing without actual file I/O
        function juLinear.read_lp(filename::String)
            println("Mock read_lp called with filename: $filename")
            # Return a dummy LPProblem object
            return LPProblem(
                true,                 # is_max
                Float64[],            # c
                spzeros(0, 0),        # A
                Float64[],            # b
                Char[],               # sense
                Float64[],            # lb
                Float64[],            # ub
                String[],             # var_names
                Symbol[]              # con_names
            )
        end

        function juLinear.read_mps(filename::String)
            println("Mock read_mps called with filename: $filename")
            # Return a dummy LPProblem object
            return LPProblem(
                true,                 # is_max
                Float64[],            # c
                spzeros(0, 0),        # A
                Float64[],            # b
                Char[],               # sense
                Float64[],            # lb
                Float64[],            # ub
                String[],             # var_names
                Symbol[]              # con_names
            )
        end

        # Test with .lp file
        lp = juLinear.load_lp_problem("test_problem.lp")
        @test isa(lp, LPProblem)

        # Test with .mps file
        lp = juLinear.load_lp_problem("test_problem.mps")
        @test isa(lp, LPProblem)

        # Test with unsupported file format
        @test_throws ErrorException juLinear.load_lp_problem("test_problem.txt")
    end

    # # Test handle_lp_operations()
    # @testset "handle_lp_operations" begin
    #     # Mock necessary functions to avoid side effects
    #     function juLinear.presolve_lp(lp::LPProblem; verbose::Bool=false)
    #         println("Mock presolve_lp called")
    #         # Return a dummy PreprocessedLPProblem object
    #         return PreprocessedLPProblem(
    #             lp_original=lp,
    #             lp_presolved=lp,
    #             removed_rows=[],
    #             removed_columns=[],
    #             fixed_variables=Dict(),
    #             substitutions=Dict(),
    #             free_variables=[],
    #             variable_to_column_map=[],
    #             infeasible=false
    #         )
    #     end

    #     function juLinear.revised_simplex(lp::PreprocessedLPProblem; verbose::Bool=false)
    #         println("Mock revised_simplex called")
    #         # Return dummy solution and objective value
    #         return ([1.0, 2.0], 10.0)
    #     end

    #     parsed_args = Dict(
    #         "filename" => "test_problem.lp",
    #         "simplex" => true,
    #         "interior" => false,
    #         "no_presolve" => false,
    #         "verbose" => false
    #     )

    #     # Call the function and capture output
    #     @testset "Simplex method with presolve" begin
    #         output = capture_output() do
    #             juLinear.handle_lp_operations(parsed_args)
    #         end
    #         @test occursin("Mock presolve_lp called", output)
    #         @test occursin("Mock revised_simplex called", output)
    #     end

    #     # Test with no presolve
    #     parsed_args["no_presolve"] = true
    #     @testset "Simplex method without presolve" begin
    #         output = capture_output() do
    #             juLinear.handle_lp_operations(parsed_args)
    #         end
    #         @test occursin("Skipping presolve step", output)
    #         @test occursin("Mock revised_simplex called", output)
    #     end

    #     # Test with interior point method (not implemented)
    #     parsed_args["interior"] = true
    #     parsed_args["simplex"] = false
    #     @testset "Interior point method" begin
    #         output = capture_output() do
    #             juLinear.handle_lp_operations(parsed_args)
    #         end
    #         @test occursin("Using interior point method", output)
    #     end
    # end
end