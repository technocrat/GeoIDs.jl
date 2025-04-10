# GeoIDs.jl Scripts

This directory contains utility scripts for the GeoIDs.jl package.

## populate_geoids.jl

This script populates the GeoIDs database tables with all predefined datasets from the PredefinedSets module. It should be run once to initialize the database with standard geographic region definitions.

### Usage

```bash
julia populate_geoids.jl [--force] [--verbose]
```

### Options

- `--force`: Forcibly recreate sets even if they already exist
- `--verbose`: Print detailed information about each operation

### Example

Basic usage:

```bash
julia populate_geoids.jl
```

Verbose output with forced recreation:

```bash
julia populate_geoids.jl --force --verbose
```

### Execution Through GeoIDs Module

The script functionality is also automatically executed when you first load the GeoIDs module through the `initialize_predefined_geoid_sets()` function called in the module's `__init__()`. However, this script provides more detailed feedback and control over the process.

### Requirements

This script requires:

1. A properly configured PostgreSQL database
2. The GeoIDs.jl package installed and accessible in your Julia environment
3. The required database tables (created automatically if they don't exist)

### Environment Variables

The script uses the following environment variables to connect to the database:

- `GEOIDS_DB_NAME`: Database name (defaults to "tiger")
- `GEOIDS_DB_HOST`: Database host (defaults to "localhost")
- `GEOIDS_DB_PORT`: Database port (defaults to "5432")

No username/password authentication is used by default, as the script assumes socket authentication. 