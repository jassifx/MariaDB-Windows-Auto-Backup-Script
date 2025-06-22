A **production-ready PowerShell script** for Windows servers that automatically backs up **all MariaDB databases** (each in a separate .sql.zip), maintains clear logs, and rotates old backups — with a clean boot-style output inspired by Linux package managers.

**📌 Features**

- ✅ One .sql.zip per database — clean & easy to restore
- ✅ Skips system databases automatically
- ✅ Linux boot-style, color-coded output \[ OK \] \[ SKIP \] \[ FAIL \] \[ .... \]
- ✅ Separate folders for **backups** and **logs**
- ✅ Auto-creates missing folders
- ✅ Deletes backups older than **X days**
- ✅ Scheduler-friendly — run daily/hourly

**⚙️ Requirements**

- Windows Server or Windows 10+
- MariaDB installed (mariadb.exe and mariadb-dump.exe in bin)
- PowerShell 5 or newer

**📁 Folder Structure**

BasePath/

├── backups/ → \`.sql.zip\` backups per database

├── logs/ → One log file per run

└── auto-backup.ps1 → The script

**🔧 Configuration**

Open auto-backup.ps1 and adjust:

\# Base folder for backups & logs:

$BasePath = "D:\\backups\\mariadb"

\# MariaDB binaries:

$MariaDBBin = "C:\\Program Files\\MariaDB 10.11\\bin"

\# MariaDB credentials:

$User = "root"

$Password = "YOUR_PASSWORD"

\# Days to keep backups:

$RetentionDays = 7

**🚀 How to Run Manually**

powershell.exe -ExecutionPolicy Bypass -File "D:\\backups\\mariadb\\auto-backup.ps1"

Watch live \[ OK \] / \[ SKIP \] / \[ FAIL \] statuses and get a log in logs/.

**🔁 Automate with Task Scheduler**

Use **Windows Task Scheduler** to run daily/hourly:

- **Program:** powershell.exe
- **Arguments:**

\-ExecutionPolicy Bypass -File "D:\\backups\\mariadb\\auto-backup.ps1"

- **Recommended:**
  - Run with highest privileges
  - Run whether user is logged in or not

**🧹 Logs & Rotation**

- Each run writes a log:  
    logs/backup_log_dd_MM_yyyy_HH-mm-ss.txt
- Backups older than $RetentionDays are **automatically deleted** at the end of each run.
- Logs are kept indefinitely (prune manually if needed).

**🔑 Restore Example**

Unzip, then run:

mariadb.exe -u root -p yourdb < yourdb-22_06_2025_12-00-00.sql

**📄 License**

MIT License — free to use, modify, and share.

**👨‍💻 Author**

**Made by** [**Jaspreet**](https://github.com/jassifx) **+ ChatGPT**

If you like this script, ⭐ star the repo and share it!

**🔗 Useful**

- MariaDB Docs
- [Windows Task Scheduler](https://learn.microsoft.com/en-us/windows/win32/taskschd/task-scheduler-start-page)

✅ **Happy Backups — Clean Servers Forever!**
