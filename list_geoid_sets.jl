#!/usr/bin/env julia

"""
list_geoid_sets.jl

This script lists GEOID sets in the database.
Run it directly from a Julia REPL or command line:

```
julia list_geoid_sets.jl
```
"""

# Make sure GeoIDs package is available
using Pkg
try
    using GeoIDs
    using DataFrames
    using PrettyTables
catch
    # If running from the package directory, add the package in dev mode
    pkg"activate ."
    pkg"instantiate"
    pkg"add DataFrames PrettyTables"
    using GeoIDs
    using DataFrames
    using PrettyTables
end

# List all GEOID sets
function list_all_sets()
    try
        sets = GeoIDs.Store.list_geoid_sets()
        
        if isempty(sets)
            println("No GEOID sets found in the database.")
            return
        end
        
        println("\nGEOID Sets in Database:")
        println("======================")
        
        # Sort by set name for better display
        sort!(sets, :set_name)
        
        # Print as a table
        pretty_table(sets, 
            header=["Set Name", "Description", "Version", "GEOIDs", "Created", "Updated", "Current"],
            tf=tf_unicode_rounded,
            alignment=:l)
    catch e
        println("Error listing GEOID sets: $e")
    end
end

# List all GEOIDs and the sets they belong to
function list_all_geoids()
    try
        geoids = GeoIDs.list_all_geoids()
        
        if isempty(geoids)
            println("No GEOIDs found in any sets.")
            return
        end
        
        println("\nGEOIDs and their Sets:")
        println("=====================")
        
        # Print as a table
        pretty_table(geoids, 
            header=["GEOID", "Sets Count", "Belongs to Sets"],
            tf=tf_unicode_rounded,
            alignment=:l)
    catch e
        println("Error listing GEOIDs: $e")
    end
end

# List sets containing a specific GEOID
function list_sets_for_geoid(geoid)
    try
        sets = GeoIDs.which_sets(geoid)
        
        if isempty(sets)
            println("GEOID '$geoid' not found in any sets.")
            return
        end
        
        println("\nSets containing GEOID '$geoid':")
        println("============================")
        
        # Print as a table
        pretty_table(sets, 
            header=["Set Name", "Version", "Description", "Current"],
            tf=tf_unicode_rounded,
            alignment=:l)
    catch e
        println("Error listing sets for GEOID $geoid: $e")
    end
end

# Process command line arguments or show menu
if length(ARGS) > 0
    if ARGS[1] == "sets"
        list_all_sets()
    elseif ARGS[1] == "geoids"
        list_all_geoids()
    elseif ARGS[1] == "which" && length(ARGS) > 1
        list_sets_for_geoid(ARGS[2])
    else
        println("Usage:")
        println("  $PROGRAM_FILE sets   # List all GEOID sets")
        println("  $PROGRAM_FILE geoids # List all GEOIDs and their sets")
        println("  $PROGRAM_FILE which GEOID # List sets containing GEOID")
    end
else
    # Interactive menu
    println("\nGeoIDS Information Manager")
    println("========================")
    println("This tool helps you view information about GEOID sets in your database.")
    
    println("\nOptions:")
    println("1. List all GEOID sets")
    println("2. List all GEOIDs and their sets")
    println("3. Find which sets contain a specific GEOID")
    println("4. Exit")
    
    print("\nEnter your choice (1-4): ")
    choice = readline()
    
    if choice == "1"
        list_all_sets()
    elseif choice == "2"
        list_all_geoids()
    elseif choice == "3"
        print("Enter GEOID: ")
        geoid = readline()
        list_sets_for_geoid(geoid)
    else
        println("Exiting.")
    end
end 