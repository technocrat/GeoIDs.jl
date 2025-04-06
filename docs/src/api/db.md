# Database Module

```@meta
CurrentModule = GeoIDs.DB
```

The Database module handles all PostgreSQL database interactions, including connection management, table setup, and query execution.

## Database Connection

Functions for creating, managing, and using database connections:

```@docs
get_connection
with_connection
get_connection_string
get_db_name
get_db_params
```

## Query Execution

Functions for executing SQL queries and commands:

```@docs
execute
execute_query
```

## Schema Management

Functions for setting up and managing the database schema:

```@docs
setup_tables
```

## Module Index

```@index
Pages = ["db.md"]
``` 