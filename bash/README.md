# Oracle DBA Helper Scripts

A collection of Bash scripts designed to simplify daily Oracle DBA tasks such as environment setup, database preview, and tablespace monitoring.

## Setup and Usage

1. Clone the repository:

	```bash
	git clone https://github.com/elvisndoj/oracle-dba
	```
2. Include the preview script in your ~/.bash_profile so it loads automatically after login:
	```
	. <path-to-repo>/oracle-dba/bash/preview.sh
	```
3. To configure the Oracle environment, type the ORACLE_SID of one of the available Oracle database instances. This will automatically set the required 	environment variables.
4. For easier access to the scripts, add aliases in your ~/.bashrc file:
	```
	alias p=". <path-to-repo>/oracle-dba/bash/preview.sh"
	alias tbs=". <path-to-repo>/oracle-dba/bash/tbs_usage.sh"
	```
 5.	Reload your shell:
	```
	source ~/.bashrc
	```
6. After the environment variables are set and a valid ORACLE_SID is selected (which sets ORACLE_HOME), you can easily run the scripts:
	```
 	p → Displays the preview screen
	tbs → Shows tablespace usage
	```
	Make sure a valid Oracle SID is selected before running the scripts.

	## Example Output

	##Preview screen:
	```
	[oracle@xxxxx ~]$ p
	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	 DB Instance:    oradb
	 DB Status:      up
	 DB Home:        /oracle19cSofts/app/oracle/product/19_28
	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	 DB Instance:    orclai
	 DB Status:      up
	 DB Home:        /oracle19cSofts/app/oracle/product/26
	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	 listener (LISTENER):            up      /oracle19cSofts/app/oracle/product/26/bin/tnslsnr
	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	[oracle@xxxxx ~]$
	
	##Tablespace usage
	
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
