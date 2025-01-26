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

# Function to perform the backup and restore
migrate_database() {
    local source_uri=$1
    local dest_uri=$2
    local dump_file="/tmp/db_backup_$(date +%Y%m%d_%H%M%S).dump"
    
    # Parse URIs
    IFS='|' read src_user src_pass src_host src_port src_db <<< $(parse_uri "$source_uri")
    IFS='|' read dst_user dst_pass dst_host dst_port dst_db <<< $(parse_uri "$dest_uri")
    
    echo "Starting database migration..."
    echo "Source database: $src_db on $src_host:$src_port"
    echo "Destination database: $dst_db on $dst_host:$dst_port"
    
    # Dump the source database
    echo "Creating backup from source database..."
    PGPASSWORD=$src_pass pg_dump \
        -Fc \
        -v \
        --no-owner \
        --no-acl \
        -h "$src_host" \
        -p "$src_port" \
        -U "$src_user" \
        -d "$src_db" \
        -f "$dump_file"
    
    # Check if dump was successful
    if [ $? -ne 0 ]; then
        echo "Error: Database dump failed"
        rm -f "$dump_file"
        exit 1
    fi
    
    # Drop existing connections to the destination database
    echo "Dropping existing connections to destination database..."
    PGPASSWORD=$dst_pass psql \
        -h "$dst_host" \
        -p "$dst_port" \
        -U "$dst_user" \
        -d postgres \
        -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$dst_db' AND pid <> pg_backend_pid();"
    
    # Drop and recreate the destination database
    echo "Recreating destination database..."
    PGPASSWORD=$dst_pass psql \
        -h "$dst_host" \
        -p "$dst_port" \
        -U "$dst_user" \
        -d postgres \
        -c "DROP DATABASE IF EXISTS \"$dst_db\";"
    
    PGPASSWORD=$dst_pass psql \
        -h "$dst_host" \
        -p "$dst_port" \
        -U "$dst_user" \
        -d postgres \
        -c "CREATE DATABASE \"$dst_db\";"
    
    # Restore the dump to the destination
    echo "Restoring backup to destination database..."
    PGPASSWORD=$dst_pass pg_restore \
        -v \
        --no-owner \
        --no-acl \
        -h "$dst_host" \
        -p "$dst_port" \
        -U "$dst_user" \
        -d "$dst_db" \
        "$dump_file"
    
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
