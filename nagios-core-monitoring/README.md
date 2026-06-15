# NAGIOS CORE STEP-BY-STEP GUIDE

This documentation is a step-by-step guid how to install and configure Nagios Core Version 4.5.13 for Oracle Database Monitoring.
The Nagios Core is hosted in: Red Hat Enterprise Linux release 8.10 (Ootpa)  4.18.0-553.104.1.el8_10.x86_64 as a test environment.

# Part 1. Installation of Nagios Core and Nagios Plugins

Installation is performed following the guide as per documentation:

```
https://library.nagios.com/docs/nagios-core/getting-started/Nagios-Core-Installing-Nagios-Core-From-Source#rhel-centos-oracle-linux
```

# Part 2. Configuration of monitoring for Oracle DB using non-default plugin "check_oracle_health"

I used the pluging from: https://omd.consol.de/docs/plugins/check_oracle_health/

1. Download and Install Oracle Client: LINUX.X64_193000_client_home.zip
I used OS user "nagios" for all the configurations (as owner of the oracle software):

1.1 Add below line in your .bash_profile:
```
# User specific environment and startup programs 
export ORACLE_HOME=/oracleclient/oracle_base/oracle_client_home
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export C_INCLUDE_PATH=$ORACLE_HOME/sdk/include
export LIBRARY_PATH=$ORACLE_HOME/lib
export PKG_CONFIG_PATH=$ORACLE_HOME/lib/pkgconfig
export TNS_ADMIN=$ORACLE_HOME/network/admin
export CV_ASSUME_DISTID=OL7.9
```
1.2 Create the directories:

```
    mkdir $ORACLE_HOME
    chmod -R 750 $ORACLE_HOME
    unzip LINUX.X64_193000_client_home.zip -d ${ORACLE_HOME}
```

1.3 Install Oracle client:

```
    $ORACLE_HOME/runInstaller -silent -ignorePrereqFailure -ignoreInternalDriverError -responseFile $ORACLE_HOME/install/response/clientsetup.rsp UNIX_GROUP_NAME=nagios INVENTORY_LOCATION=/oracleclient ORACLE_BASE=/oracleclient/oracle_base
```

2. Install neccessary packages as root:

```
    sudo dnf install -y autoconf automake libtool make gcc glibc glibc-common perl perl-DBI perl-devel libdbi-devel perl-ExtUtils-MakeMaker
```

3. The installation of the perl-modules DBI and DBD::Oracle is required. (https://omd.consol.de/docs/plugins/check_oracle_health/)
    3.1  Install DBD::Oracle via CPAN (recommended method):
          Switch to nagios user: ```cpan```
          Then inside CPAN type: ```install DBD::Oracle```

! If it fails with below error:

```
-L/oracleclient/oracle_base/oracle_client_home/lib -lclntsh -ldl -lm -lpthread -lnsl -lirc -limf -lirc -lrt -laio -lresolv -lsvml -lperl
\ /usr/bin/ld: cannot find -lnsl /usr/bin/ld: cannot find -laio collect2: error: ld returned 1 exit status make: *** [Makefile:526: blib/arch/auto/DBD/Oracle/Oracle.so] Error 1 ZARQUON/DBD-Oracle-1.95.tar.gz /usr/bin/make -- NOT OK
```
It means CPAN is injecting Oracle sysliblist defaults, which include: -lnsl -lirc -limf -laio -lsvml
this line in your log proves it:

``` Sysliblist: -ldl -lm -lpthread -lnsl -lirc -limf -lirc -lrt -laio -lresolv -lsvml ```

This is coming from Oracle client detection, not CPAN.
To fix the issue, follow the steps:
    ``` cpan > look DBD::Oracle ```  will provide the build directory (i.e: /home/nagios/.cpan/build/DBD-Oracle-1.95-4)
      3.1.1  In bash:
	  	```
              unset LIBS
              unset LDLOADLIBS
              unset EXTRALIBS
		```
      3.1.2 Go to building directory:
	  ``` cd /home/nagios/.cpan/build/DBD-Oracle-1.95-4 ```
            --> regenerate Makefile with clean LIBS by running the commands in following sequence:
			```
			make clean
			perl Makefile.PL LIBS="-L$ORACLE_HOME/lib -lclntsh -ldl -lm -lpthread -lresolv" 
			make
			make install
			```
             --> Verifications:
            	 Run in bash:
				 ``` perl -MDBD::Oracle -e 'print "DBD::Oracle OK\n"'	```	 DBD::Oracle prerequisite is fulfilled 
            	 ``` perl -MDBI -e 'print "DBI OK\n"'  ```   DBI prerequisite is fulfilled

4.  Build & compile: check_oracle_health-3.3.3.2 downloaded from https://omd.consol.de/docs/plugins/check_oracle_health/
	4.1	``` su - nagios ```
	4.2	``` cd <?>/check_oracle_health-3.3.3.2 ```
	4.3	``` autoreconf -fi ```  this will generate "configure" file
    		
	For some reason, I run in an small issue with, but if you dont face any issue, skipp this part and go to next instruction:
	Error:
	autoconf 2.60 used instead of 2.69
	Root cause:
	/usr/local/bin/autoconf (old version) was overriding system tools
		
	Double check the binaries (most probably If I should have run a dnf update it would be okay!!): 
	#which -a autoconf
	#type -a autoconf
	#ls -l $(which autoconf)

	Build in home directory: /home/nagios/check_oracle_health-3.3.3.2

	4.4	Install to: /usr/local/nagios/libexec
		```
		./configure --prefix=/usr/local/nagios  ## check ./configure --help for the options
		make
		make install
		```

6. Run: ``` sudo systemctl edit nagios ``` and paste:

	This is based on your variables defined previously.
	```
	[Service]
	Environment="ORACLE_HOME=/oracleclient/oracle_base/oracle_client_home"
	Environment="LD_LIBRARY_PATH=/oracleclient/oracle_base/oracle_client_home/lib"
	Environment="TNS_ADMIN=/oracleclient/oracle_base/oracle_client_home/network/admin"
	Environment="PATH=/oracleclient/oracle_base/oracle_client_home/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"
	Environment="PERL5LIB=/home/nagios/perl5/lib/perl5:/home/nagios/perl5/lib/perl5/x86_64-linux-thread-multi"
	```
	``` 
		sudo systemctl daemon-reload
		sudo systemctl restart nagios
	```
 
Now that you have finished with nagios server configuration and plugin compilation, its time to add the target hosts ( oracle db servers).

Oracle Database Monitoring

7. To add configurations for oracle db monitoring, check the official documentation, but what I did is:

    Edit:	``` /usr/local/nagios/etc/objects/commands.cfg ``` and add the following:
    ```
    define command {
        command_name    check_oracle_health
        command_line    $USER1$/check_oracle_health --connect=$HOSTADDRESS$:$ARG1$/$ARG2$ --username=$ARG3$ --password=$ARG4$ --mode=$ARG5$ --warning=$ARG6$ --critical=$ARG7$
    }
    ```


8. Edit the configuration file: ``` /usr/local/nagios/etc/nagios.cfg ```

    Add line: ``` cfg_dir=/usr/local/nagios/etc/hosts ``` where "hosts" is a custom directory I created to organize the hosts.

8. Copy or create a config file for each oracle server you want to monitor:

    i.e: I copied: /usr/local/nagios/etc/objects/localhost.cfg to /usr/local/nagios/etc/hosts/<oracle-server>.cfg

    Edit /usr/local/nagios/etc/hosts/<oracle-server>.cfg by changing: host_name <oracle-server> and remove the services you don't want to monitor or added new services as in my case:
    Added check_oracle_health:

For service_name, I have already exported: TNS_ADMIN=$ORACLE_HOME/network/admin and created a tnsnames.ora with the entries on it (tnsping succeeded).

```
# Monitor Connection Time
define service {
    use                 generic-service
    host_name           <oracle-server>
    service_description Oracle Connection Time
    check_command       check_oracle_health!1521!<service_name>!<db_user>!<db_passw>!connection-time!1!2
}

# Monitor Tablespace Usage
define service {
    use                 generic-service
    host_name           <oracle-server>
    service_description Oracle Tablespace Usage
    check_command       check_oracle_health!1521!<service_name>!<db_user>!<db_passw>!tablespace-usage!85!95
}

# Monitor ASM Disk Usage Usage

define service {
    use                 generic-service
    host_name           <oracle-server>
    service_description Oracle ASM Disk Usage
    check_command       check_oracle_health!1521!<service_name>!<db_user>!<db_passw>!asm-diskgroup-usage!85!95
}

```
# You can check the help and documentation to add other services: /usr/local/nagios/libexec/check_oracle_health --help
