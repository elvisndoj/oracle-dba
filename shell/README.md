# Oracle DBA Shell Toolkit

This directory contains Bash-based Oracle Database Administration utilities used for environment discovery, real-time monitoring, and storage analysis in Linux-based Oracle environments.

These scripts are designed for operational DBAs who need fast visibility into database status, configuration, and resource usage.

---

# Contents

| Script 		| Purpose 													  |
|---------------|-------------------------------------------------------------|
| preview.sh 	| Interactive Oracle environment dashboard and session loader |
| tbs_usage.sh	| Tablespace usage monitoring and capacity check			  |

---

# preview.sh — Oracle Environment Dashboard

## Overview

`preview.sh` is a dynamic Oracle environment inspection and control script.

It acts as a lightweight DBA dashboard that:

- Detects Oracle Homes from Oracle inventory
- Reads `/etc/oratab` for configured databases
- Checks database status (OPEN / MOUNTED / DOWN)
- Detects ASM instances and Grid Infrastructure
- Displays system-wide Oracle overview
- Generates dynamic shell functions for quick database access

---

## Key Features

### Automatic Discovery
- Parses Oracle inventory XML
- Detects installed Oracle Homes
- Reads `/etc/oratab` for database instances

### Database Status Monitoring
Combines OS-level and database-level checks:

- Process inspection (`pmon`)
- SQL validation (`v$instance`)

Supports status detection:
- OPEN
- MOUNTED
- STARTED (NOMOUNT)
- DOWN

---

### ASM / Grid Infrastructure Support
- Detects ASM instances (`+ASM`)
- Displays ASM diskgroup usage (`v$asm_diskgroup`)
- Detects Grid Infrastructure services (OHASD, listener)

---

### Real-Time Oracle Overview

Displays a consolidated table including:

- Database instances
- ASM instances
- Listener status
- Grid Infrastructure status
- Oracle Homes

---

## Usage

### Recommended (interactive session)

This script must be **sourced**, not executed directly:

```
source ~/oracle-dba/shell/preview.sh
```

1. Clone the repository:

	```bash
	git clone https://github.com/elvisndoj/oracle-dba
	```
2. Include the preview script in your ~/.bash_profile so it loads automatically after login:
	```
	source ~/oracle-dba/shell/preview.sh
	```
3. To configure the Oracle environment, type the ORACLE_SID of one of the available Oracle database instances. This will automatically set the required 	environment variables.
4. For easier access to the scripts, add aliases in your ~/.bashrc file:
	```
	alias p="source ~/oracle-dba/shell/preview.sh"
	alias tbs="source ~/oracle-dba/shell/tbs_usage.sh"
	```
 5.	Reload your shell:
	```
	source ~/.bashrc
	```
6. After the environment variables are set and a valid ORACLE_SID is selected (which sets ORACLE_HOME), you can easily run the scripts:
	```
 	p	 	→ Displays the preview screen
	tbs		→ Shows tablespace usage
	```
	Make sure a valid Oracle SID is selected before running the scripts.

## Example Output

##Preview screen:
```
[oracle@xxxxx ~]$ p

COMPONENT                 SID                  STATUS               ORACLE_HOME
------------------------- ---------------      ------------         ------------------------------
OraDB23Home1 (rdbms)      orclai               UP                   /oracle19cSofts/app/oracle/product/26
OraDB19Home2 (rdbms)      oradb                MOUNTED              /oracle19cSofts/app/oracle/product/19_28
OraDB19Home1 (rdbms)      -                    -                    /oracle19cSofts/DB
oms13c1 (rdbms)           -                    -                    /oracle/em_home
agent13c1 (rdbms)         -                    -                    /oracle/agent/agent_13.5.0.0.0
listener (LISTENER)       -                    UP                   /oracle19cSofts/app/oracle/product/26
[oracle@xxxxx ~]$ orclai
✔ SID: orclai
✔ HOME: /oracle19cSofts/app/oracle/product/26
STATUS: UP
-------------------------------------------
db_unique_name          = orclai
database_role           = PRIMARY
log_mode                = NOARCHIVELOG
open_mode               = READ WRITE
flashback_on            = NO
switchover_status       = NOT ALLOWED
dataguard_broker        = FALSE
force_logging           = NO
-------------------------------------------
[oracle@xxxxx ~]$ oradb
✔ SID: oradb
✔ HOME: /oracle19cSofts/app/oracle/product/19_28
STATUS: MOUNTED
[oracle@xxxxx ~]$

```

##Tablespace usage

```
[oracle@xxxxx ~]$ tbs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Tablespace Usage of Instance: orclai
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

INSTANCE Tablespace Name           AutoExtend Files TotalSpace UsedSpace FreeSpace %Used %Free Used%FromMax ExtendUpto(MB)
-------- ------------------------- ---------- ----- ---------- --------- --------- ----- ----- ------------ --------------
orclai   SYSTEM                    YES            1       1110      1108         2   100     0            0       33554432
orclai   USERS                     YES            1          7         6         1    87    13            0       33554432
orclai   UNDOTBS1                  YES            1         40        33         7    83    17            0       33554432
orclai   SYSAUX                    YES            1        700       663        37    95     5            0       33554432
```
