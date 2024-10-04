module lp_hsd_ipm

using SparseArrays
using LinearAlgebra
# Local modules
push!(LOAD_PATH, ".")
using lp_problem
using lp_standard_form_converter

# Export the solver function
export hsdLPsolver

function hsdLPsolver(lp::LPProblem; toler=1e-8, beta=0.995, verbose=false)
    # Step 1: Convert the LP problem to standard form using the provided function
    lp_std = convert_to_standard_form(lp; verbose=false)

    # Extract data from the standardized LPProblem
    c = lp_std.c
    A = lp_std.A
    b = lp_std.b
    l = lp_std.l
    u = lp_std.u
    variable_types = lp_std.variable_types

    if verbose
        @show size(c)
        @show size(A)
        @show size(b)
        @show size(l)
        @show size(u)
    end

    n_vars = length(c)          # Total number of variables after standardization
    n_constraints = length(b)

    # Initialize variables
    n = n_vars
    m = n_constraints

    x = ones(n)                # Primal variables initialized to vector of ones
    y = zeros(m)               # Dual variables initialized to zero
    z = ones(n)                # Dual slack variables initialized to vector of ones
    τ = 1.0                    # Homogeneous variable initialized to 1
    κ = 1.0                    # Homogeneous variable initialized to 1

    μ = (dot(x, z) + τ * κ) / (n + 1)  # Initial value for complementarity measure
    iteration = 0
    max_iterations = 100

    # Store values for plotting
    x_vals, y_vals, z_vals, τ_vals, κ_vals = [], [], [], [], []

    while μ > toler && iteration < max_iterations
        if verbose
            println("Iteration: $iteration")
            println("Complementarity measure (μ): $μ")
            println("Primal variables (x): $x")
            println("Dual variables (y): $y")
            println("Dual slack variables (z): $z")
            println("τ: $τ, κ: $κ")
        end

        # Store current values
        push!(x_vals, copy(x))
        push!(y_vals, copy(y))
        push!(z_vals, copy(z))
        push!(τ_vals, τ)
        push!(κ_vals, κ)

        # Compute residuals
        rp = b * τ - A * x
        rD = c * τ - A' * y - z
        rτ = dot(c, x) - dot(b, y) + κ

        if verbose
            println("Residuals -")
            println("   rp: $rp")
            println("   rD: $rD")
            println("   rτ: $rτ")
        end

        # Form the KKT system to find search directions (dy, dx, dτ, dz, dκ)
        X = spdiagm(x)
        Z = spdiagm(z)

        # Adjust zero matrices to match dimensions
        zeros_m_m = spzeros(m, m)
        zeros_m_n = spzeros(m, n)
        zeros_m_1 = spzeros(m, 1)
        zeros_n_m = spzeros(n, m)
        zeros_n_n = spzeros(n, n)
        zeros_n_1 = spzeros(n, 1)
        zeros_1_m = spzeros(1, m)
        zeros_1_n = spzeros(1, n)
        zeros_1_1 = spzeros(1, 1)

        # Newton system for predictor step
        lhs = vcat(
            hcat(zeros_m_m, A, zeros_m_1, zeros_m_n, -b),
            hcat(-A', zeros_n_n, -c, -I(n), c),
            hcat(b', -c', zeros_1_1, zeros_1_n, zeros_1_1),
            hcat(Z, zeros_n_m, zeros_n_1, X, zeros_n_1),
            hcat(zeros_1_m, c', zeros_1_1, zeros_1_n, zeros_1_1)
        )
        rhs = vcat(
            rp,
            rD,
            rτ,
            -X * z + μ * ones(n),
            -τ * κ + μ
        )

        if verbose
            println("KKT Matrix (lhs):")
            println("   $lhs")
            println("Right-hand side (rhs):")
            println("   $rhs")
        end

        # Solve for the direction
        d = lhs \ rhs

        # Correct the slicing of the solution vector to match the problem dimensions
        dy = d[1:m]
        dx = d[m+1:m+n]
        dτ = d[m+n+1]
        dz = d[m+n+2:m+2*n+1]
        dκ = d[end]

        # Predictor-corrector: take affine step and use it to determine centering parameter γ
        α_affine_x = isempty(dx[dx .< 0]) ? Inf : minimum(-x[dx .< 0] ./ dx[dx .< 0])
        α_affine_z = isempty(dz[dz .< 0]) ? Inf : minimum(-z[dz .< 0] ./ dz[dz .< 0])
        α_affine = minimum([
            α_affine_x,
            α_affine_z,
            dτ < 0 ? -τ / dτ : Inf,
            dκ < 0 ? -κ / dκ : Inf
        ])
        α_affine *= beta

        μ_affine = (dot(x + α_affine * dx, z + α_affine * dz) + (τ + α_affine * dτ) * (κ + α_affine * dκ)) / (n + 1)
        γ = (μ_affine / μ)^3

        # Corrector step
        rhs_corrector = copy(rhs)
        rhs_corrector[m+n+2:m+2*n+1] .= -X * z + γ * μ * ones(n)
        rhs_corrector[end] = -τ * κ + γ * μ

        # Solve for the corrector direction
        d_corrector = lhs \ rhs_corrector
        dy_corr = d_corrector[1:m]
        dx_corr = d_corrector[m+1:m+n]
        dτ_corr = d_corrector[m+n+1]
        dz_corr = d_corrector[m+n+2:m+2*n+1]
        dκ_corr = d_corrector[end]

        # Update variables with the corrected step size
        α_x_corr = isempty(dx_corr[dx_corr .< 0]) ? Inf : minimum(-x[dx_corr .< 0] ./ dx_corr[dx_corr .< 0])
        α_z_corr = isempty(dz_corr[dz_corr .< 0]) ? Inf : minimum(-z[dz_corr .< 0] ./ dz_corr[dz_corr .< 0])
        α = minimum([
            α_x_corr,
            α_z_corr,
            dτ_corr < 0 ? -τ / dτ_corr : Inf,
            dκ_corr < 0 ? -κ / dκ_corr : Inf
        ])
        α *= beta

        # Update the primal, dual, and slack variables
        x += α * dx_corr
        y += α * dy_corr
        z += α * dz_corr
        τ += α * dτ_corr
        κ += α * dκ_corr

        # Update the complementarity measure
        μ = (dot(x, z) + τ * κ) / (n + 1)

        iteration += 1
    end

    # Return the optimal solution along with the recorded values for plotting
    return (x, y, z, τ, κ, iteration, x_vals, y_vals, z_vals, τ_vals, κ_vals)
end

end # module lp_hsd_ipm
