#!/usr/bin/env julia

# SPDX-License-Identifier: MIT

"""
populate_geoids.jl

This script populates the GeoIDs database tables with all predefined datasets from the PredefinedSets module.
It should be run once to initialize the database with standard geographic region definitions.

Usage:
    julia populate_geoids.jl [--force] [--verbose]

Options:
    --force     Forcibly recreate sets even if they already exist
    --verbose   Print detailed information about each operation
"""

using GeoIDs
using GeoIDs.DB
using GeoIDs.Store
using GeoIDs.PredefinedSets
using GeoIDs.Setup
using DataFrames
using LibPQ
using Dates

"""
    populate_predefined_sets(force::Bool=false, verbose::Bool=false)

Populate the GeoIDs database with all predefined datasets from the PredefinedSets module.

# Arguments
- `force::Bool`: If true, recreate sets even if they already exist
- `verbose::Bool`: If true, print detailed information about each operation

# Returns
- `Dict`: Summary of operations performed
"""
function populate_predefined_sets(force::Bool=false, verbose::Bool=false)
    # Ensure database and tables exist
    Setup.initialize_database()
    
    if verbose
        println("Database initialized. Setting up tables...")
    end
    
    DB.setup_tables()
    
    if verbose
        println("Tables configured. Beginning population of predefined sets...")
    end
    
    # Get all existing sets to check which ones we need to create
    existing_sets = Dict{String, Bool}()
    
    try
        result = Store.list_geoid_sets()
        for row in eachrow(result)
            existing_sets[row.set_name] = true
        end
        
        if verbose
            println("Found $(length(existing_sets)) existing sets in database.")
        end
    catch e
        @warn "Error retrieving existing GEOID sets: $e"
    end
    
    # Track what we've done
    summary = Dict(
        "created" => String[],
        "skipped" => String[],
        "failed" => String[]
    )
    
    # Process each predefined set
    for (set_name, (geoids, description)) in PredefinedSets.PREDEFINED_SETS
        if verbose
            println("Processing set: $set_name ($(length(geoids)) counties)")
        end
        
        # Skip if set exists and we're not forcing recreation
        if !force && haskey(existing_sets, set_name)
            if verbose
                println("  Set '$set_name' already exists. Skipping. (Use --force to recreate)")
            end
            push!(summary["skipped"], set_name)
            continue
        end
        
        # Create the set
        try
            if haskey(existing_sets, set_name) && force
                # Delete existing set first
                if verbose
                    println("  Force flag set. Deleting existing set '$set_name'")
                end
                Store.delete_geoid_set(set_name)
            end
            
            if verbose
                println("  Creating set '$set_name' with $(length(geoids)) counties")
            end
            
            Store.create_geoid_set(set_name, description, geoids)
            push!(summary["created"], set_name)
            
            if verbose
                println("  Successfully created set '$set_name'")
            end
        catch e
            @warn "Failed to create GEOID set '$set_name': $e"
            push!(summary["failed"], set_name)
        end
    end
    
    return summary
end

function print_summary(summary)
    println("\nPopulation Summary:")
    println("==================")
    println("Created: $(length(summary["created"])) sets")
    for set in sort(summary["created"])
        println("  - $set")
    end
    
    println("\nSkipped: $(length(summary["skipped"])) sets")
    for set in sort(summary["skipped"])
        println("  - $set")
    end
    
    if !isempty(summary["failed"])
        println("\nFailed: $(length(summary["failed"])) sets")
        for set in sort(summary["failed"])
            println("  - $set")
        end
    end
end

function main()
    # Parse command line arguments
    force = "--force" in ARGS
    verbose = "--verbose" in ARGS || "-v" in ARGS
    
    if verbose
        println("Starting GeoIDs population script...")
        println("Force mode: $force")
    end
    
    # Run the population function
    summary = populate_predefined_sets(force, verbose)
    
    # Print summary
    print_summary(summary)
    
    # Reload constants in the module
    GeoIDs.load_predefined_geoids()
    
    println("\nPopulation complete. You can now use the predefined GEOID sets in your application.")
end

# Run as a script
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end 