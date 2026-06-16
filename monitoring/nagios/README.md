# Nagios Core + Oracle Database Monitoring (check_oracle_health)

![Nagios](https://img.shields.io/badge/Nagios-Core-blue)
![Oracle](https://img.shields.io/badge/Oracle-Database-red)
![RHEL](https://img.shields.io/badge/RHEL-8.10-green)
![Status](https://img.shields.io/badge/Type-Lab%20Setup-orange)

---

## Table of Contents

1. Overview  
2. Environment  
3. Nagios Core Installation  
4. Oracle Monitoring Plugin  
5. Oracle Client Installation  
6. System Packages  
7. Perl Dependencies (DBD::Oracle)  
8. check_oracle_health Plugin Build  
9. Systemd Configuration  
10. Oracle Monitoring Configuration  
11. Troubleshooting  
12. Verification  

---

## 1. Overview

This guide describes step-by-step installation and configuration of Nagios Core 4.5.13 for monitoring Oracle Database using the check_oracle_health plugin.

This setup is intended for a test environment.

---

## 2. Environment

- OS: Red Hat Enterprise Linux 8.10 (Ootpa)  
- Kernel: 4.18.0-553.104.1.el8_10.x86_64  
- User: nagios  

---

## 3. Nagios Core Installation

Follow official documentation:

https://library.nagios.com/docs/nagios-core/getting-started/Nagios-Core-Installing-Nagios-Core-From-Source#rhel-centos-oracle-linux

---

## 4. Oracle Monitoring Plugin

We use:

check_oracle_health

Official documentation:

https://omd.consol.de/docs/plugins/check_oracle_health/

---

## 5. Oracle Client Installation

### 5.1 Download
LINUX.X64_193000_client_home.zip

---

### 5.2 Environment Variables (.bash_profile)

```
export ORACLE_HOME=/oracleclient/oracle_base/oracle_client_home  
export PATH=$ORACLE_HOME/bin:$PATH  
export LD_LIBRARY_PATH=$ORACLE_HOME/lib  
export C_INCLUDE_PATH=$ORACLE_HOME/sdk/include  
export LIBRARY_PATH=$ORACLE_HOME/lib  
export PKG_CONFIG_PATH=$ORACLE_HOME/lib/pkgconfig  
export TNS_ADMIN=$ORACLE_HOME/network/admin  
export CV_ASSUME_DISTID=OL7.9  
```
---

### 5.3 Setup
```
mkdir -p $ORACLE_HOME  
chmod -R 755 $ORACLE_HOME  
chown -R nagios:nagios $ORACLE_HOME  

unzip LINUX.X64_193000_client_home.zip -d ${ORACLE_HOME}
```
---

### 5.4 Silent Install

```
$ORACLE_HOME/runInstaller -silent -ignorePrereqFailure -ignoreInternalDriverError \
-responseFile $ORACLE_HOME/install/response/clientsetup.rsp \
UNIX_GROUP_NAME=nagios \
INVENTORY_LOCATION=/oracleclient \
ORACLE_BASE=/oracleclient/oracle_base
```
---

## 6. System Packages
```
dnf install -y autoconf automake libtool make gcc glibc glibc-common \
perl perl-DBI perl-devel libdbi-devel perl-ExtUtils-MakeMaker

dnf update
```
---

## 7. Perl Dependencies (DBD::Oracle)

### 7.1 Install via CPAN

```
cpan  
install DBD::Oracle  
```
---

### 7.2 Error Encountered

/usr/bin/ld: cannot find -lnsl  
/usr/bin/ld: cannot find -laio  

Root cause:
Oracle sysliblist injects:

-ldl -lm -lpthread -lnsl -lirc -limf -lrt -laio -lresolv -lsvml  

---

### 7.3 Fix
```
cpan  
look DBD::Oracle  
```
```
unset LIBS  
unset LDLOADLIBS  
unset EXTRALIBS  
```
cd /home/nagios/.cpan/build/DBD-Oracle-*  
```
make clean  
perl Makefile.PL LIBS="-L$ORACLE_HOME/lib -lclntsh -ldl -lm -lpthread -lresolv"  
make  
make install  
```
---

### 7.4 Verification

perl -MDBD::Oracle -e 'print "DBD::Oracle OK\n"'  
perl -MDBI -e 'print "DBI OK\n"'  

---

## 8. check_oracle_health Plugin Build
```
su - nagios  
cd check_oracle_health-3.3.3.2  
autoreconf -fi  
```
---

### Issue: Autoconf Version Mismatch

autoconf 2.60 used instead of 2.69  

Cause:
Old autoconf in /usr/local/bin overriding system version  

Check:

which -a autoconf  
type -a autoconf  

---

### Build

```
./configure --prefix=/usr/local/nagios  
make  
make install  
```
Installed to:

/usr/local/nagios/libexec  

---

## 9. Systemd Configuration
```
sudo systemctl edit nagios  

[Service]  
Environment="ORACLE_HOME=/oracleclient/oracle_base/oracle_client_home"  
Environment="LD_LIBRARY_PATH=/oracleclient/oracle_base/oracle_client_home/lib"  
Environment="TNS_ADMIN=/oracleclient/oracle_base/oracle_client_home/network/admin"  
Environment="PATH=/oracleclient/oracle_base/oracle_client_home/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"  
Environment="PERL5LIB=/home/nagios/perl5/lib/perl5:/home/nagios/perl5/lib/perl5/x86_64-linux-thread-multi"  
```
```
systemctl daemon-reload  
systemctl restart nagios  
```
---

## 10. Oracle Monitoring Configuration

### Command Definition

/usr/local/nagios/etc/objects/commands.cfg  

```
define command {  
    command_name    check_oracle_health  
    command_line    $USER1$/check_oracle_health --connect=$HOSTADDRESS$:$ARG1$/$ARG2$ \
    --username=$ARG3$ --password=$ARG4$ --mode=$ARG5$ \
    --warning=$ARG6$ --critical=$ARG7$  
}
```
---

### Config Directory

/usr/local/nagios/etc/nagios.cfg  

```
cfg_dir=/usr/local/nagios/etc/hosts  
```
---

## 11. Host Configuration Setup (IMPORTANT)

To add a new Oracle server for monitoring:

### Step 1: Copy template

Copy default host configuration:

```
/usr/local/nagios/etc/objects/localhost.cfg → /usr/local/nagios/etc/hosts/<oracle-server>.cfg  
```
---

### Step 2: Edit host file

Edit:
```
/usr/local/nagios/etc/hosts/<oracle-server>.cfg  
```
Change:
```
- host_name → <oracle-server>
```
Remove unwanted default services from localhost template.

Then add Oracle-specific services as needed (see below).

---

### Step 3: Example Services

```
define service {  
    use                 generic-service  
    host_name           <oracle-server>  
    service_description Oracle Connection Time  
    check_command       check_oracle_health!1521!<service_name>!<db_user>!<db_pass>!connection-time!1!2  
}  

define service {  
    use                 generic-service  
    host_name           <oracle-server>  
    service_description Oracle Tablespace Usage  
    check_command       check_oracle_health!1521!<service_name>!<db_user>!<db_pass>!tablespace-usage!85!95  
}  

define service {  
    use                 generic-service  
    host_name           <oracle-server>  
    service_description Oracle ASM Disk Usage  
    check_command       check_oracle_health!1521!<service_name>!<db_user>!<db_pass>!asm-diskgroup-usage!85!95  
}  
```
---

## 12. Troubleshooting

### CPAN Errors
Missing libraries:
- lnsl
- laio

Fix:
Rebuild DBD::Oracle with cleaned LIBS

---

### Autoconf Issue
Wrong version used (2.60 instead of 2.69)

Cause:
/usr/local/bin/autoconf overriding system binary

---

### Oracle Environment Issues
Ensure:
- ORACLE_HOME is correct
- LD_LIBRARY_PATH is correct
- TNS_ADMIN is correct
- systemd environment is loaded properly

---

## 13. Verification

/usr/local/nagios/libexec/check_oracle_health --help  

```
tnsping <service>  
sqlplus <user>/<pass>@<service>  
```
---

## End of Guide
