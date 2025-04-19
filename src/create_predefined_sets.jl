#!/usr/bin/env julia

"""
create_predefined_sets.jl

This script creates predefined GEOID sets in the database.
Run it directly from a Julia REPL or command line:

```
julia create_predefined_sets.jl
```
"""

# Make sure GeoIDs package is available
using Pkg
try
    using GeoIDs
catch
    # If running from the package directory, add the package in dev mode
    pkg"activate ."
    pkg"instantiate"
    using GeoIDs
end

# List of available predefined sets
function list_predefined_sets()
    println("\nAvailable predefined GEOID sets:")
    println("------------------------------")
    
    # Sort sets by name for better display
    set_names = sort(collect(keys(GeoIDs.PredefinedSets.PREDEFINED_SETS)))
    
    for name in set_names
        desc = GeoIDs.PredefinedSets.PREDEFINED_SETS[name][2]
        geoids = GeoIDs.PredefinedSets.PREDEFINED_SETS[name][1]
        println("$name: $desc ($(length(geoids)) GEOIDs)")
    end
end

# Create a single set
function create_one_set(set_name)
    if !haskey(GeoIDs.PredefinedSets.PREDEFINED_SETS, set_name)
        println("Error: Unknown set '$set_name'")
        list_predefined_sets()
        return false
    end
    
    geoids, description = GeoIDs.PredefinedSets.PREDEFINED_SETS[set_name]
    
    try
        GeoIDs.Store.create_geoid_set(set_name, description, geoids)
        println("Created set '$set_name' with $(length(geoids)) GEOIDs")
        return true
    catch e
        println("Error creating set '$set_name': $e")
        return false
    end
end

# Create all sets
function create_all_sets()
    println("Creating all predefined GEOID sets...")
    
    success_count = 0
    failure_count = 0
    
    for (name, (geoids, desc)) in GeoIDs.PredefinedSets.PREDEFINED_SETS
        try
            GeoIDs.Store.create_geoid_set(name, desc, geoids)
            println("  ✓ Created '$name' with $(length(geoids)) GEOIDs")
            success_count += 1
        catch e
            println("  ✗ Failed to create '$name': $(typeof(e))")
            failure_count += 1
        end
    end
    
    println("\nSummary: Created $success_count sets, failed to create $failure_count sets")
end

# Process command line arguments or show menu
if length(ARGS) > 0
    if ARGS[1] == "all"
        create_all_sets()
    elseif ARGS[1] == "list"
        list_predefined_sets()
    else
        for set_name in ARGS
            create_one_set(set_name)
        end
    end
else
    # Interactive menu
    println("\nGeoIDS Predefined Sets Manager")
    println("=============================")
    println("This tool helps create predefined GEOID sets in your database.")
    
    list_predefined_sets()
    
    println("\nOptions:")
    println("1. Create all predefined sets")
    println("2. Create a specific set")
    println("3. Exit")
    
    print("\nEnter your choice (1-3): ")
    choice = readline()
    
    if choice == "1"
        create_all_sets()
    elseif choice == "2"
        print("Enter set name: ")
        set_name = readline()
        create_one_set(set_name)
    else
        println("Exiting.")
    end
end 