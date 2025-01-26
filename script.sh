set -e

# Function to extract components from PostgreSQL URI
parse_uri() {
    local uri=$1
    local user=$(echo $uri | sed -E 's/^postgres(ql)?:\/\/([^:]+):.*/\2/')
    local password=$(echo $uri | sed -E 's/^postgres(ql)?:\/\/[^:]+:([^@]+).*/\2/')
    local host=$(echo $uri | sed -E 's/^postgres(ql)?:\/\/[^@]+@([^:]+).*/\2/')
    local port=$(echo $uri | sed -E 's/.*:([0-9]+)\/.*/\1/')
    local dbname=$(echo $uri | sed -E 's/.*\/([^?]+).*/\1/')
    
    echo "$user|$password|$host|$port|$dbname"
}

# Function to validate PostgreSQL URI
validate_uri() {
    local uri=$1
    if [[ ! $uri =~ ^postgres(ql)?:\/\/[^:]+:[^@]+@[^:]+:[0-9]+\/[^\/]+$ ]]; then
        echo "Error: Invalid PostgreSQL URI format"
        echo "Expected format: postgresql://user:password@host:port/dbname"
        exit 1
    fi
}

# Function to check if required tools are installed
check_requirements() {
    local tools=("pg_dump" "pg_restore" "psql")
    for tool in "${tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            echo "Error: Required tool '$tool' is not installed"
            exit 1
        fi
      done
}

# Function to backup a database
backup_database() {
    local uri=$1
    local dump_file=$2
    
    # Parse URI
    IFS='|' read user pass host port db <<< $(parse_uri "$uri")
    
    echo "Starting database backup..."
    echo "Source database: $db on $host:$port"
    
    # Dump the database
    echo "Creating backup..."
    PGPASSWORD=$pass pg_dump \
        -Fc \
        -v \
        --no-owner \
        --no-acl \
        -h "$host" \
        -p "$port" \
        -U "$user" \
        -d "$db" \
        -f "$dump_file"
    
    # Check if dump was successful
    if [ $? -ne 0 ]; then
        echo "Error: Database dump failed"
        rm -f "$dump_file"
        exit 1
    fi
    
    echo "Backup completed successfully!"
}

# Function to restore a database
restore_database() {
    local uri=$1
    local dump_file=$2
    
    # Parse URI
    IFS='|' read user pass host port db <<< $(parse_uri "$uri")
    
    echo "Starting database restore..."
    echo "Destination database: $db on $host:$port"
    
    # Drop existing connections
    echo "Dropping existing connections..."
    PGPASSWORD=$pass psql \
        -h "$host" \
        -p "$port" \
        -U "$user" \
        -d postgres \
        -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$db' AND pid <> pg_backend_pid();"
    
    # Drop and recreate the database
    echo "Recreating database..."
    PGPASSWORD=$pass psql \
        -h "$host" \
        -p "$port" \
        -U "$user" \
        -d postgres \
        -c "DROP DATABASE IF EXISTS \"$db\";"
    
    PGPASSWORD=$pass psql \
        -h "$host" \
        -p "$port" \
        -U "$user" \
        -d postgres \
        -c "CREATE DATABASE \"$db\";"
    
    # Restore the dump
    echo "Restoring backup..."
    PGPASSWORD=$pass pg_restore \
        -v \
        --no-owner \
        --no-acl \
        -h "$host" \
        -p "$port" \
        -U "$user" \
        -d "$db" \
        "$dump_file"
    
    echo "Restore completed successfully!"
}

# Function to perform the migration
migrate_database() {
    local source_uri=$1
    local dest_uri=$2
    local dump_file="/tmp/db_backup_$(date +%Y%m%d_%H%M%S).dump"
    
    echo "Starting database migration..."
    
    # Perform backup
    backup_database "$source_uri" "$dump_file"
    
    # Perform restore
    restore_database "$dest_uri" "$dump_file"
    
    # Cleanup
    rm -f "$dump_file"
    
    echo "Migration completed successfully!"
}

# Main script
main() {
    # Check if correct number of arguments provided
    if [ "$#" -ne 2 ]; then
        echo "Usage: $0 <source_uri> <destination_uri>"
        echo "Example: $0 postgresql://user:pass@localhost:5432/sourcedb postgresql://user:pass@localhost:5432/destdb"
        exit 1
    fi
    
    local source_uri=$1
    local dest_uri=$2
    
    # Validate URIs
    validate_uri "$source_uri"
    validate_uri "$dest_uri"
    
    # Check required tools
    check_requirements
    
    # Perform migration
    migrate_database "$source_uri" "$dest_uri"
}

# Execute main function with all script arguments
main "$@"
