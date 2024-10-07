module LpUtils

export is_running_in_notebook

function is_running_in_notebook()
    # Check if running in VS Code's Jupyter notebook environment
    if (haskey(ENV, "VSCODE_PID") || haskey(ENV, "VSCODE_CWD"))
        return true
        # Check if running in a general Jupyter environment (including VS Code)
    elseif isdefined(Main, :IJulia) && Main.IJulia.inited
        return true
    else
        return false
    end
end

end # module
