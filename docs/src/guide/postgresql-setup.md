# Setting up PostgreSQL

GeoIDs.jl requires a PostgreSQL database with the PostGIS extension. This guide walks you through setting up a local PostgreSQL server on both macOS and Ubuntu.

## Database Authentication

> **Note**: GeoIDs.jl now uses PostgreSQL's default socket authentication which doesn't require username and password on local development setups. This is especially convenient on macOS with Homebrew installations where the user running Julia has permission to connect to the database.

## macOS Setup

### Method 1: Using Homebrew (Recommended)

1. **Install Homebrew** (if not already installed):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. **Install PostgreSQL**:
```bash
brew install postgresql@17
```

3. **Initialize the database**:
```bash
initdb --locale=C -E UTF-8 $(brew --prefix)/var/postgres
```

4. **Start PostgreSQL service**:
```bash
brew services start postgresql@17
```

5. **Verify installation**:
```bash
psql postgres
```

With the Homebrew installation, PostgreSQL is configured to allow socket authentication for the current user, which means you won't need to provide a username or password when connecting from Julia.

### Method 2: Using PostgreSQL.app

1. Download PostgreSQL.app from [https://postgresapp.com/](https://postgresapp.com/)
2. Move to your Applications folder and open it
3. Click "Initialize" to create a new server
4. Add to your PATH with:
```bash
echo 'export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"' >> ~/.zshrc
```

## Ubuntu Setup

1. **Update package lists**:
```bash
sudo apt update
```

2. **Install PostgreSQL**:
```bash
sudo apt install postgresql postgresql-contrib
```

3. **Verify the service status**:
```bash
sudo systemctl status postgresql
```

4. **Start PostgreSQL** (if not already running):
```bash
sudo systemctl start postgresql
```

5. **Enable autostart on boot**:
```bash
sudo systemctl enable postgresql
```

## Installing PostGIS Extension

PostGIS extends PostgreSQL with geospatial capabilities, which are essential for GeoIDs.jl to work with geographic data. It adds support for geographic objects, spatial indexing, and geographic functions.

### macOS PostGIS Installation

#### Using Homebrew

1. **Install PostGIS**:
```bash
brew install postgis
```

2. **Create a database** (if you haven't already):
```bash
createdb tiger
```

3. **Enable PostGIS extension in your database**:
```bash
psql -d tiger -c "CREATE EXTENSION postgis;"
psql -d tiger -c "CREATE EXTENSION postgis_topology;"
```

4. **Verify PostGIS installation**:
```bash
psql -d tiger -c "SELECT PostGIS_Version();"
```

#### Using PostgreSQL.app

If you installed PostgreSQL using PostgreSQL.app, PostGIS is typically already included. To verify and enable it:

1. **Connect to your database**:
```bash
psql -d tiger
```

2. **Enable PostGIS extension**:
```sql
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
```

3. **Verify PostGIS installation**:
```sql
SELECT PostGIS_Version();
```

### Ubuntu PostGIS Installation

1. **Install PostGIS packages**:
```bash
sudo apt install postgis postgresql-14-postgis-3
```

Note: The exact package name might vary depending on your PostgreSQL version. Replace `14` with your installed PostgreSQL version if different.

2. **Create a database** (if you haven't already):
```bash
sudo -u postgres createdb tiger
```

3. **Enable PostGIS extension**:
```bash
sudo -u postgres psql -d tiger -c "CREATE EXTENSION postgis;"
sudo -u postgres psql -d tiger -c "CREATE EXTENSION postgis_topology;"
```

4. **Verify PostGIS installation**:
```bash
sudo -u postgres psql -d tiger -c "SELECT PostGIS_Version();"
```

### Troubleshooting PostGIS Installation

If you encounter issues when installing or enabling PostGIS:

1. **Missing prerequisites**: Some systems might need additional dependencies:
   ```bash
   # Ubuntu
   sudo apt install build-essential libxml2-dev libgeos-dev libproj-dev libjson-c-dev libgdal-dev
   ```

2. **PostGIS extension not found**:
   - Check if PostGIS is properly installed
   - Verify the correct PostgreSQL version compatibility
   - Try reinstalling the PostGIS package

3. **Permission issues**:
   - Ensure you're connecting with a user that has superuser privileges
   - On Ubuntu, prefix commands with `sudo -u postgres` when needed

## Post-Installation Configuration

### Creating a Database and User

1. **Switch to the postgres user**:
```bash
# On macOS
psql -U postgres

# On Ubuntu
sudo -u postgres psql
```

2. **Create a new database**:
```bash
CREATE DATABASE tiger;
```

3. **Create a new user and set password**:
```bash
CREATE USER myuser WITH ENCRYPTED PASSWORD 'mypassword';
```

4. **Grant privileges to the user on the database**:
```bash
GRANT ALL PRIVILEGES ON DATABASE tiger TO myuser;
```

5. **Make the user a superuser for PostGIS** (needed to create extensions):
```bash
ALTER USER myuser WITH SUPERUSER;
```

### Configure Remote Access (Optional)

1. **Edit postgresql.conf** to listen on all interfaces:
```bash
# On macOS with Homebrew
vim $(brew --prefix)/var/postgres/postgresql.conf

# On Ubuntu
sudo vim /etc/postgresql/14/main/postgresql.conf
```

Find the line with `listen_addresses` and change it to:
```
listen_addresses = '*'
```

2. **Edit pg_hba.conf** to allow remote connections:
```bash
# On macOS with Homebrew
vim $(brew --prefix)/var/postgres/pg_hba.conf

# On Ubuntu
sudo vim /etc/postgresql/14/main/pg_hba.conf
```

Add the following line:
```
host    all             all             0.0.0.0/0               md5
```

3. **Restart PostgreSQL**:
```bash
# On macOS with Homebrew
brew services restart postgresql

# On Ubuntu
sudo systemctl restart postgresql
```

## Common Troubleshooting

1. **Connection refused errors**: Check if PostgreSQL is running with `ps aux | grep postgres`
2. **Authentication failed**: Ensure your pg_hba.conf is properly configured for the authentication method
3. **Permission denied**: Check user privileges with `\l` in psql
4. **Port conflicts**: If port 5432 is already in use, change PostgreSQL's port in postgresql.conf
5. **PostGIS functions not available**: Make sure PostGIS extension is enabled in your specific database with `\dx` in psql

## Next Steps

After setting up PostgreSQL and PostGIS, you can proceed to [database initialization](database-setup.md) to set up GeoIDs.jl with your database. 