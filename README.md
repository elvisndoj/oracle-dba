# Oracle DBA Toolkit

A structured collection of Oracle Database Administration scripts, monitoring queries, and troubleshooting utilities used for real-world database support and performance analysis.

This repository is designed as a practical DBA reference toolkit for day-to-day operations, incident investigation, and performance tuning.

---

## Purpose

The goal of this repository is to centralize commonly used Oracle DBA tasks such as:

- Performance monitoring
- Session and locking analysis
- Storage and tablespace management
- Undo and temporary tablespace tracking
- Basic automation scripts (shell)
- Monitoring integration (Nagios)

---

## Repository Structure

### SQL Scripts
Core Oracle diagnostic and monitoring queries.

- `performance/` ? Active sessions, long-running SQL, redo/undo analysis
- `locking/` ? Blocking sessions and lock detection
- `storage/` ? Tablespace, TEMP, and UNDO usage monitoring
- `transactions/` ? Transaction and rollback monitoring

### Shell Scripts
Automation and quick operational checks.

### Monitoring
Nagios integration scripts and checks.

### ASM / RMAN / Data Guard
(Planned / in progress) Oracle infrastructure and high availability topics.

### Docs
Troubleshooting guides, use cases, and architecture notes.

---

## Environment

This repository is tested and used in environments such as:

- Oracle Database 19c
- Oracle Linux 8, RHEL 8
- ASM (Automatic Storage Management)
- RMAN backup/recovery
- Nagios monitoring

---

## Typical Use Cases

- Investigating slow database performance
- Identifying blocking sessions
- Monitoring tablespace growth
- Checking undo/temp usage issues
- Supporting production incidents
- Basic DBA health checks

---

## Disclaimer

These scripts are intended for learning, support, and operational use.
Always validate queries before running in production environments.

---

## Author

Maintained by: Elvis Ndoj  
Oracle DBA / Platform Engineer