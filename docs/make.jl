using Documenter
using MaterialDocs
using GeoIDs

makedocs(;
    sitename = "GeoIDs.jl",
    authors = "Richard Careaga <public@careaga.net>",
    modules = [GeoIDs],
    format = Material3(;
        theme = :ocean_depth,
        dark_mode = :toggle,
        edit_link = "main",
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://technocrat.github.io/GeoIDs.jl",
    ),
    repo = Remotes.GitHub("technocrat", "GeoIDs.jl"),
    pages = [
        "Home" => "index.md",
        "User Guide" => [
            "PostgreSQL Setup" => "guide/postgresql-setup.md",
            "Database Configuration" => "guide/database-config.md",
            "Database Setup" => "guide/database-setup.md",
            "Getting Started" => "guide/getting-started.md",
            "GEOID Sets" => "guide/geoid-sets.md",
            "Spatial Filtering" => "guide/spatial-filtering.md",
            "Set Operations" => "guide/set-operations.md",
            "Versioning" => "guide/versioning.md",
        ],
        "API Reference" => [
            "Core" => "api/core.md",
            "DB" => "api/db.md",
            "Store" => "api/store.md",
            "Fetch" => "api/fetch.md",
            "Operations" => "api/operations.md",
            "Setup" => "api/setup.md",
        ],
        "Contributing" => "contributing.md",
    ],
    checkdocs = :none,
)

deploydocs(;
    repo = "github.com/technocrat/GeoIDs.jl.git",
    devbranch = "main",
)
