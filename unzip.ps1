<#
.SYNOPSIS
   Recursive unzip
.AUTHOR
   Christophe AVONTURE
.DESCRIPTION
    Unzip all .zip files present in a given folder + sub-folders; recursively.
    Each .zip files will be removed just after the extraction
.EXAMPLES

    Display the help screen
    powershell .\unzip.ps1 -help

    Unzip files present in folder c:\temp, recursively
    powershell .\unzip.ps1 -folder c:\temp

    Unzip files present in folder c:\temp, recursively, keep tracking into a log file (append mode)
    powershell .\unzip.ps1 -folder c:\temp -log c:\temp\unzip.log

    Unzip files present in folder c:\temp, recursively; don't ask for confirmation
    powershell .\unzip.ps1 -folder c:\temp -force

    Unzip files present in folder c:\temp, recursively; don't ask for confirmation and delete archives once uncompressed
    powershell .\unzip.ps1 -folder c:\temp -force -delete
#>
param (
    # Source folder
    [string] $folder = "",
    # Logfile name for a tracking (f.i. c:\temp\unzip.log)
    [string] $logFile = "",
    # Show help screen
    [switch] $help = $false,
    # Delete the archive once uncompressed
    [switch] $delete = $false,
    # Don't ask for confirmation, run the script
    [switch] $force = $false
)
begin {

    <#
    .SYNOPSIS
        Display the help screen and exit
    .OUTPUTS
        void
    #>
    function showHelp {

        Write-Host "`nThe script will scan a folder recursively and retrieve all .zip files then uncompress the archive in the same folder."
        Write-Host ""
        Write-Host "If you specify the `-delete` command line argument, the archive is then removed."
        Write-Host ""
        Write-Host "Be careful, this script is destructive; will overwrite files during the unzip action and remove the archive afterward" -ForegroundColor White -BackgroundColor Red
        Write-Host ""
        Write-Host "At the end, all .zip files are uncompressed and removed"

        Write-Host $(
            "`nUsage: unzip [-help] [-delete] [-force] [-folder <foldername>] [-log <filename>]`n"
        ) -ForegroundColor Cyan

        Write-Host $(
            " -help      Show this screen"
        )

        Write-Host $(
            " -delete    Delete the archive once uncompressed successfully"
        )

        Write-Host $(
            " -force     Don't ask for confirmation, run the script"
        )

        Write-Host $(
            " -folder    Name of the folder to process (f.i. ""-folder c:\backups"")"
        )

        Write-Host $(
            " -log       Name of a logfile where to keep track of which files were processed (f.i. ""-log c:\unzip.log"")"
        )

        exit
    }

    <#
    .SYNOPSIS
        Validate command line parameters, make sure the specified folder exists
    .OUTPUTS
        void
    #>
    function validate {
        $folder = $folder.Trim()

        if (-not (Test-Path $folder)) {
            Write-Host "ERROR - The target folder ""$folder"" didn't exists" -ForegroundColor White -BackgroundColor Red
            exit -1
        }


        $logFile = $logFile.Trim()
    }

    <#
    .SYNOPSIS
        Add leading zeros, return "010" when $counter is set to 10
    #>
    function global:consoleAddLeadingZeros([int] $counter) {
        return "{0:00000}" -f $counter
    }

    <#
    .SYNOPSIS
        Write a line in a log file, append mode
    #>
    function LogWrite([string] $message, [string] $flag="INFO") {
        $dateStamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
        Add-content $Logfile -value "$dateStamp $flag::$message"
    }

    <#
    .SYNOPSIS
        Retrieve all .zip files recursively
    .OUTPUTS
        void
    #>
    function unzipArchives {
        LogWrite "START Unzip, process folder $($folder)"
        LogWrite "Please note: password protected file will be skipped and won't be uncompressed" "WARN"

        # Get all zips; recursively; as an array. Keep three infos, folder name, full folder name and full filename
        $zipFiles = Get-ChildItem "*.zip" -Path $folder -Recurse -File | Select Name, `
            @{ n = 'Folder'; e = { Convert-Path $_.PSParentPath } }, `
            @{ n = 'Foldername'; e = { ($_.PSPath -split '[\\]')[-2] } } ,
            @{ n = 'Fullname'; e = { Convert-Path $_.PSPath } }

        $count = $zipFiles.count

        Write-Host "`n$count archives were found in the folder $folder`n" -ForegroundColor Green

        if ($count -eq 0) {
            LogWrite "No zip files found"
            Write-Host "`nNo zip files found in folder $folder`n"
            exit
        }

        # Windows shell; needed for the native unzip of Windows
        $objShell = New-Object -com Shell.Application

        $progress = 0

        # Process zips, one by one
        foreach ($zipFile in $zipFiles) {
            $progress++

            # Get the folder name where the ZIP is stored
            $path = $zipFile.Folder
            Push-Location $path

            $logMessage = "$(consoleAddLeadingZeros($progress)) / $(consoleAddLeadingZeros($count)) - Unzip $($zipFile.Fullname)"
            LogWrite $logMessage

            Write-Host $logMessage -ForegroundColor Yellow -NoNewline

            $location = $objShell.NameSpace($path)

            Write-Progress -Activity "Unzipping to $($path)" `
                -PercentComplete (($progress / ($zipFiles.Count + 1)) * 100) `
                -CurrentOperation $zipFile.Fullname `
                -Status "File $($progress) of $($zipFiles.Count)"

            $zipFolder = $objShell.NameSpace($zipFile.Fullname)

            $FOF_DEFAULT = 0           # Default. No options specified.
            $FOF_SILENT = 4            # Do not display a progress dialog box.
            $FOF_RENAMEONCOLLISION = 8 # Rename the target file if a file exists at the target location with the same name.
            $FOF_NOCONFIRMATION = 16   # Click "Yes to All" in any dialog box displayed.
            $FOF_ALLOWUNDO = 64        # Preserve undo information, if possible.
            $FOF_FILESONLY = 128       # Perform the operation only if a wildcard file name (*.*) is specified.
            $FOF_SIMPLEPROGRESS = 256  # Display a progress dialog box but do not show the file names.
            $FOF_NOCONFIRMMKDIR = 512  # Do not confirm the creation of a new directory if the operation requires one to be created.
            $FOF_NOERRORUI = 1024      # Do not display a user interface if an error occurs.
            $FOF_NORECURSION = 4096    # Disable recursion.
            $FOF_SELECTFILES = 9182    # Do not copy connected files as a group. Only copy the specified files.

            # Using FOF_NOERRORUI, if the ZIP file is password protected, no error will be throwed and the file will be skipped

            #! Note: it seems impossible to detect if an error has occured or not; see https://stackoverflow.com/a/8275253
            #! This said, it's impossible to make sure the unzip was successfull
            $location.Copyhere($zipFolder.items(), $FOF_SILENT + $FOF_NOCONFIRMATION + $FOF_NOCONFIRMMKDIR + $FOF_NOERRORUI)

            # And now remove the zip file
            if ($delete) {
                Write-Host " (archive delete)" -ForegroundColor darkGray
                Remove-Item $zipFile.Fullname
            } else {
                Write-Host ""
            }

            Pop-Location
        }

        LogWrite "END Unzip, all archives in folder $($folder) have been processed"

        Write-Host "`nAll archives have been processed"
    }

    <#
    .SYNOPSIS
        Ask the user for confirmation before running the process
    .OUTPUTS
        return boolean
    #>
    function askBeforeContinue {
        $answer = read-host "Do you want to continue? Type yes or no then press Enter"

        switch ($answer) `
        {
            'yes' {
                return $TRUE
            }

            'no' {
                return $FALSE
            }

            default {
                Write-Host 'You may only answer yes or no, please try again.'
                askBeforeContinue
            }
        }
    }

    #region Entry point
    Write-Host "Recursive Unzip" -ForegroundColor Cyan

    if (($help) -or ("" -eq $folder)) {
        showHelp
    }

    validate

    $continue = $force
    if (-not $continue)  {
        $continue = askBeforeContinue
    }

    if ($continue) {
        unzipArchives
    }

    Write-Host "------------------"
    Get-Content -Path $logFile
    #endregion Entry point
}
