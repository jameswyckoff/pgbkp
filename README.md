# pgbkp - PostgreSQL Backup and Migration Tool

A simple yet powerful command-line tool for backing up, restoring, and migrating PostgreSQL databases.

## Features

- Backup PostgreSQL databases to files
- Restore databases from backup files
- Migrate data between databases
- Support for both URI and file-based operations
- Automatic handling of database connections
- Clean database recreation during restore

## Installation & Usage

### Using Nix (Recommended)

There are several ways to use this tool with Nix:

1. Quick run without installation:
```bash
nix run github:jameswyckoff/pgbkp -- <source> <destination>
```

2. Install to your profile:
```bash
nix profile install github:jameswyckoff/pgbkp
```

3. Add to your NixOS/Home Manager configuration:
```nix
{
  inputs.pgbkp.url = "github:jameswyckoff/pgbkp";
  
  # Use in your configuration
  environment.systemPackages = [ inputs.pgbkp.packages.${system}.default ];
}
```

### Manual Usage

While using Nix is recommended to ensure correct dependencies, you can also run the script directly if you have the required dependencies installed:

- PostgreSQL client tools (pg_dump, pg_restore, psql) - must be the same version as your PostgreSQL server
- file command

Clone the repository and make the script executable:
```bash
git clone https://github.com/jameswyckoff/pgbkp.git
chmod +x pgbkp/script.sh
./pgbkp/script.sh <source> <destination>
```

## Usage Examples

```bash
pgbkp <source> <destination>
```

Where source and destination can be either:
- PostgreSQL URI (postgresql://user:pass@host:port/dbname)
- Backup file path (.dump)

### Examples

1. Migrate between databases:
```bash
pgbkp postgresql://user:pass@localhost:5432/sourcedb postgresql://user:pass@localhost:5432/destdb
```

2. Create a backup:
```bash
pgbkp postgresql://user:pass@localhost:5432/sourcedb backup.dump
```

3. Restore from backup:
```bash
pgbkp backup.dump postgresql://user:pass@localhost:5432/newdb
```

4. Copy a backup file:
```bash
pgbkp source.dump dest.dump
```

## Requirements

- PostgreSQL client tools (pg_dump, pg_restore, psql)
- file command

These dependencies are automatically handled when installing through Nix.

## License

MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
