# =================================================================
# MariaDB Backup Script for Windows Server — Production Version
# Author: Jaspreet + ChatGPT
# Features:
#   ✔️ Boot-style output (like dnf/systemctl)
#   ✔️ Separate folders: /backups and /logs
#   ✔️ Creates folders if missing
#   ✔️ One log file per run
#   ✔️ Skips system DBs
#   ✔️ Robust error handling
#   ✔️ Auto-delete old backups (>7 days)
#   ✔️ Scheduler-ready
# =================================================================

# ------------------------------
# CONFIGURATION
# ------------------------------

# Base folder (change this to your desired parent folder)
$BasePath   = "D:\backups\mariadb"

# Auto subfolders:
$BackupPath = Join-Path $BasePath "backups"
$LogPath    = Join-Path $BasePath "logs"

# MariaDB settings:
$MariaDBBin = "C:\Program Files\MariaDB 10.11\bin"
$User = "root"
$Password = "Password"

# Timestamp for files:
$Timestamp = Get-Date -Format "dd_MM_yyyy_HH-mm-ss"
$LogFile   = Join-Path $LogPath "backup_log_$Timestamp.txt"

# Retention period (days)
$RetentionDays = 7

# ------------------------------
# SUPPORT FUNCTIONS
# ------------------------------

function Log {
    param([string]$Message)
    Add-Content -Path $LogFile -Value $Message
}

function Status {
    param([string]$Type, [string]$Message)
    $Tag = switch ($Type) {
        "OK"   { "[  OK  ]" }
        "SKIP" { "[ SKIP ]" }
        "FAIL" { "[ FAIL ]" }
        "INFO" { "[ INFO ]" }
    }
    $Color = switch ($Type) {
        "OK"   { "Green" }
        "SKIP" { "Yellow" }
        "FAIL" { "Red" }
        "INFO" { "Cyan" }
    }
    Write-Host "$Tag $Message" -ForegroundColor $Color
    Log "$($Type): $Message"
}

# ------------------------------
# INITIALIZE FOLDERS
# ------------------------------

foreach ($Path in @($BackupPath, $LogPath)) {
    if (-Not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
        Write-Host "[  OK  ] Created folder: $Path" -ForegroundColor Green
    }
}

# ------------------------------
# START
# ------------------------------

Write-Host "`n========== MariaDB Backup - Production Mode ==========" -ForegroundColor Cyan
Status "INFO" "Timestamp: $Timestamp"

# ------------------------------
# STEP 1: Get list of databases
# ------------------------------

Status "INFO" "Fetching database list..."
$AllDBs = & "$MariaDBBin\mariadb.exe" "-u$User" "-p$Password" -N -e "SHOW DATABASES;" 2>&1

if ($LASTEXITCODE -ne 0) {
    Status "FAIL" "Could not get database list. Output: $AllDBs"
    exit 1
}

Status "OK" "Raw DBs: $AllDBs"

# ------------------------------
# STEP 2: Filter user DBs
# ------------------------------

$SystemDBs = @("information_schema", "performance_schema", "mysql", "sys")
$UserDBs = @()

Write-Host "`nChecking databases:" -ForegroundColor Cyan
foreach ($Db in $AllDBs) {
    if ($SystemDBs -contains $Db) {
        Status "SKIP" "$Db - System database"
    } else {
        Status "OK" "$Db - Marked for backup"
        $UserDBs += $Db
    }
}

# ------------------------------
# STEP 3: Backup each user DB
# ------------------------------

if ($UserDBs.Count -eq 0) {
    Status "INFO" "No user databases found. Nothing to backup. Exiting."
    exit 0
}

foreach ($Db in $UserDBs) {
    Write-Host "`n------------------------------" -ForegroundColor DarkCyan
    Status "INFO" "Backing up: $Db"

    $SqlFile = Join-Path $BackupPath "$Db-$Timestamp.sql"
    $ZipFile = "$SqlFile.zip"

    Status "INFO" "Dumping to $SqlFile ..."
    $DumpOutput = & "$MariaDBBin\mariadb-dump.exe" "-u$User" "-p$Password" --databases $Db --single-transaction --routines --triggers --events --hex-blob > $SqlFile 2>&1

    if ($LASTEXITCODE -ne 0 -or -Not (Test-Path $SqlFile)) {
        Status "FAIL" "Dump failed for $Db. Output: $DumpOutput"
        continue
    } else {
        Status "OK" "Dump successful."
    }

    Status "INFO" "Compressing to $ZipFile ..."
    try {
        Compress-Archive -Path $SqlFile -DestinationPath $ZipFile -Force
        Status "OK" "Compression done: $ZipFile"
        Remove-Item $SqlFile -Force
        Status "OK" "Deleted raw SQL: $SqlFile"
    }
    catch {
        Status "FAIL" "Compression failed for $Db. $_"
    }
}

# ------------------------------
# STEP 4: Remove old backups
# ------------------------------

Write-Host "`n------------------------------" -ForegroundColor DarkCyan
Status "INFO" "Checking for backups older than $RetentionDays days..."

$OldFiles = Get-ChildItem -Path $BackupPath -Filter "*.zip" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) }

if ($OldFiles.Count -eq 0) {
    Status "INFO" "No old backups found to remove."
} else {
    foreach ($File in $OldFiles) {
        try {
            Remove-Item $File.FullName -Force
            Status "OK" "Removed old backup: $($File.Name)"
        }
        catch {
            Status "FAIL" "Could not remove: $($File.Name). $_"
        }
    }
}

Write-Host "`n========== Backup complete ==========" -ForegroundColor Cyan
Status "OK" "Log saved to: $LogFile"
