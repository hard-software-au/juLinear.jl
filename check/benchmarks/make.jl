using Documenter
using juLinear  # Replace with your module name

makedocs(
    sitename = "juLinear Documentation",
    modules = [juLinear],
    format = Documenter.HTML(),
    pages = [
        "Home" => "index.md",
        "Test Framework" => "TestFramework.md",
        "Test Helpers" => "TestHelpers.md"
    ]
)