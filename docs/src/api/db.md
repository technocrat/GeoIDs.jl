# Database Module

```@meta
CurrentModule = GeoIDs.DB
```

The Database module handles all PostgreSQL database interactions, including connection management, table setup, and query execution.

> **Note**: The Database module now uses PostgreSQL's default socket authentication for local connections, which doesn't require username and password settings on most development setups.

## Database Connection

Functions for creating, managing, and using database connections:

```@docs
get_connection
with_connection
get_connection_string
get_db_name
get_db_params
```

## Connection String Format

The connection string is now formatted as:

```
postgresql://host:port/dbname
```

For example:
```
postgresql://localhost:5432/tiger
```

This format uses PostgreSQL's default authentication mechanism, which is socket authentication on most development setups.

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