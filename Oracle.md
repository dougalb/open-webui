# Oracle Database Support for Open WebUI

This document provides instructions for setting up and using Oracle Database 23ai with Open WebUI.

## Prerequisites

- Oracle Database 23ai or later
- Oracle client libraries installed on the application server
- Network connectivity between Open WebUI and Oracle database
- SYSDBA privileges for initial database setup

## Installation and Setup

### 1. Database Setup

Run the provided setup script as SYSDBA to create the database user, schema, and tables:

```sql
sqlplus / as sysdba @backend/oracle_setup.sql
```

Or connect manually and run the script:

```sql
sqlplus / as sysdba
SQL> @backend/oracle_setup.sql
```

The script will:
- Create a database user `OPENWEBUI` with password `OpenWebUI123!`
- Grant necessary privileges
- Create all required tables with proper Oracle data types
- Set up indexes for optimal performance
- Create triggers for automatic timestamp management

### 2. Environment Configuration

Set the following environment variables for Open WebUI:

```bash
# Basic Oracle connection
DATABASE_URL=oracle://OPENWEBUI:OpenWebUI123!@hostname:1521/service_name

# Optional: Specify database schema (defaults to username)
DATABASE_SCHEMA=OPENWEBUI

# Connection pooling settings (recommended for production)
DATABASE_POOL_SIZE=20
DATABASE_POOL_MAX_OVERFLOW=0
DATABASE_POOL_TIMEOUT=30
DATABASE_POOL_RECYCLE=3600
```

### 3. Connection String Formats

Open WebUI supports several Oracle connection string formats:

#### TNS Names
```
oracle://username:password@hostname:port/service_name
```

#### Easy Connect
```
oracle://username:password@hostname:port/service_name
```

#### TNS Alias (if using tnsnames.ora)
```
oracle://username:password@tns_alias
```

## Database Schema Customization

### Modifying User Credentials

To use different database credentials, modify the variables at the top of `oracle_setup.sql`:

```sql
DEFINE openwebui_user = 'YOUR_USER'
DEFINE openwebui_password = 'YOUR_PASSWORD'
DEFINE openwebui_tablespace = 'YOUR_TABLESPACE'
```

### Custom Schema Name

If you want to use a different schema name than the username:

1. Create the user with appropriate privileges
2. Set the `DATABASE_SCHEMA` environment variable
3. Ensure the user has access to the specified schema

## Oracle-Specific Features

### Data Types

Open WebUI uses Oracle-optimized data types:

- **JSON Data**: Stored as CLOB with application-level JSON handling
- **Timestamps**: Uses `NUMBER(19)` for nanosecond precision timestamps
- **Boolean Fields**: Uses `NUMBER(1)` with check constraints
- **Large Text**: Uses CLOB for unlimited text storage

### Performance Optimizations

The setup includes several performance enhancements:

1. **Indexes**: Created on frequently queried columns
2. **Connection Pooling**: Configured for optimal resource usage
3. **Timestamps**: Automatic triggers for created_at/updated_at fields
4. **Constraints**: Check constraints for data integrity

### Character Encoding

Oracle connections are configured with UTF-8 encoding for proper internationalization support.

## Troubleshooting

### Connection Issues

1. **TNS Error**: Verify Oracle client is installed and tnsnames.ora is configured
2. **Authentication**: Check username/password and user privileges
3. **Network**: Ensure firewall allows connections on Oracle port (usually 1521)

### Common Errors

#### "ORA-00942: table or view does not exist"
- User lacks SELECT privileges on system tables
- Schema name is incorrect
- Tables were not created successfully

#### "ORA-01017: invalid username/password"
- Check credentials in DATABASE_URL
- Verify user exists and is not locked
- Check password expiration

#### "ORA-12514: TNS:listener does not currently know of service"
- Verify service name in connection string
- Check Oracle listener configuration
- Confirm database service is running

### Performance Tuning

For high-traffic deployments, consider:

1. **Connection Pool Sizing**:
   ```bash
   DATABASE_POOL_SIZE=50
   DATABASE_POOL_MAX_OVERFLOW=10
   ```

2. **Oracle SGA/PGA Tuning**: Adjust Oracle memory parameters
3. **Index Optimization**: Monitor and add indexes based on query patterns
4. **Partitioning**: Consider table partitioning for large chat/message tables

## Monitoring and Maintenance

### Database Monitoring

Monitor these Oracle metrics:
- Connection pool utilization
- Query response times
- Table space usage
- Session counts

### Maintenance Tasks

Regular maintenance recommendations:
- Update table statistics: `EXEC DBMS_STATS.GATHER_SCHEMA_STATS('OPENWEBUI')`
- Monitor table space growth
- Archive old chat/message data if needed
- Backup database regularly

## Migration from Other Databases

### From SQLite

No automatic migration tool is provided. You'll need to:
1. Export data from SQLite
2. Transform data formats (especially JSON fields)
3. Import into Oracle using appropriate tools

### From PostgreSQL

Data types are largely compatible, but consider:
- JSON field handling differences
- Timestamp precision
- Sequence vs. auto-increment differences

## Security Considerations

### Database Security

1. **User Privileges**: Grant only necessary privileges
2. **Network Security**: Use encrypted connections (SSL/TLS)
3. **Password Policy**: Use strong passwords and regular rotation
4. **Audit Trail**: Enable Oracle auditing for compliance

### Application Security

1. **Connection Strings**: Store DATABASE_URL securely (environment variables, secrets management)
2. **SQL Injection**: Open WebUI uses parameterized queries via SQLAlchemy
3. **Access Control**: Configure application-level access controls

## Advanced Configuration

### Oracle RAC Support

For Oracle Real Application Clusters:

```bash
DATABASE_URL=oracle://user:pass@(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=host1)(PORT=1521))(ADDRESS=(PROTOCOL=TCP)(HOST=host2)(PORT=1521)))(CONNECT_DATA=(SERVICE_NAME=service)))
```

### Pluggable Database (PDB)

For pluggable databases, use the PDB service name:

```bash
DATABASE_URL=oracle://user:pass@hostname:1521/pdb_service_name
```

### SSL/TLS Configuration

For encrypted connections:

```bash
DATABASE_URL=oracle://user:pass@hostname:2484/service_name?ssl_mode=require
```

## Support and Resources

### Documentation
- [Oracle Database Documentation](https://docs.oracle.com/en/database/)
- [SQLAlchemy Oracle Dialect](https://docs.sqlalchemy.org/en/14/dialects/oracle.html)
- [python-oracledb Documentation](https://python-oracledb.readthedocs.io/)

### Community
- Open WebUI GitHub Issues
- Oracle Developer Community
- SQLAlchemy Community

## Version Compatibility

- **Oracle Database**: 19c, 21c, 23ai (recommended)
- **python-oracledb**: 3.1.1+
- **SQLAlchemy**: 2.0.38+

## Known Limitations

1. **Migrations**: Automatic schema migrations are not supported for Oracle
2. **Peewee ORM**: Legacy Peewee migrations are skipped for Oracle (SQLAlchemy only)
3. **Case Sensitivity**: Oracle identifiers are case-sensitive when quoted

## Example Configuration

Complete environment configuration example:

```bash
# Database connection
DATABASE_URL=oracle://OPENWEBUI:OpenWebUI123!@oracle-server:1521/XEPDB1
DATABASE_SCHEMA=OPENWEBUI

# Connection pooling
DATABASE_POOL_SIZE=20
DATABASE_POOL_MAX_OVERFLOW=5
DATABASE_POOL_TIMEOUT=30
DATABASE_POOL_RECYCLE=3600

# Disable automatic migrations (not supported for Oracle)
DB_MIGRATIONS=False

# Application settings
WEBUI_NAME="Open WebUI (Oracle)"
ENV=production
```

This configuration provides a robust, production-ready setup for running Open WebUI with Oracle Database 23ai.