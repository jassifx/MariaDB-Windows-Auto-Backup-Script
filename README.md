# MariaDB Windows Auto Backup Script

A production-ready PowerShell script for Windows servers to automatically backup all MariaDB databases, compress them, and rotate old backups.

## Features
✅ Individual `.sql.zip` per database  
✅ Skips system databases  
✅ Boot-style status output  
✅ Log file per run  
✅ Auto-cleanup of backups older than X days  
✅ Scheduler ready

## Requirements
- MariaDB installed
- `mysqldump.exe` or `mariadb-dump.exe` and `mariadb.exe` in your `bin` folder.

## Configuration
Edit the script:
```powershell
$BasePath = "D:\backups\mariadb"
$MariaDBBin = "C:\Program Files\MariaDB 10.11\bin"
$User = "root"
$Password = "YOUR_PASSWORD"
$RetentionDays = 7
