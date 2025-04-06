using Documenter
using GeoIDs

makedocs(
    sitename = "GeoIDs.jl",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://technocrat.github.io/GeoIDs.jl",
    ),
    modules = [GeoIDs],
    authors = "Richard Careaga <public@careaga.net>",
    repo = "https://github.com/technocrat/GeoIDs.jl/blob/{commit}{path}#L{line}",
    pages = [
        "Home" => "index.md",
        "User Guide" => [
            "Getting Started" => "guide/getting-started.md",
            "GEOID Sets" => "guide/geoid-sets.md",
            "Spatial Filtering" => "guide/spatial-filtering.md",
            "Set Operations" => "guide/set-operations.md",
            "Versioning" => "guide/versioning.md",
            "Database Configuration" => "guide/database-config.md",
        ],
        "API Reference" => [
            "Core" => "api/core.md",
            "DB" => "api/db.md",
            "Store" => "api/store.md",
            "Fetch" => "api/fetch.md",
            "Operations" => "api/operations.md",
        ],
        "Contributing" => "contributing.md",
    ],
)

deploydocs(
    repo = "github.com/technocrat/GeoIDs.jl.git",
    devbranch = "main",
    push_preview = true,
) 