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

    Unzip files present in folder c:\temp, recursively; don't ask for confirmation
    powershell .\unzip.ps1 -folder c:\temp -force
#>
param (
    # Source folder
    [string] $folder = "",
    # Show help screen
    [switch] $help = $false,
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

        Write-Host "`nThe script will scan a folder recursively and retrieve all .zip files then:"
        Write-Host ""
        Write-Host "   1. Uncompress the archive in the same folder"
        Write-Host "   2. Remove the zip"
        Write-Host ""
        Write-Host "Be careful, this script is destructive; will overwrite files during the unzip action and remove the archive afterward" -ForegroundColor White -BackgroundColor Red
        Write-Host ""
        Write-Host "At the end, all .zip files are uncompressed and removed"

        Write-Host $(
            "`nUsage: unzip [-help] [-force] [-folder <foldername>]`n"
        ) -ForegroundColor Cyan

        Write-Host $(
            " -help      Show this screen"
        )

        Write-Host $(
            " -force     Don't ask for confirmation, run the script"
        )

        Write-Host $(
            " -folder    Name of the folder to process"
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
        $Folder = $Folder.Trim()

        if (-not (Test-Path $Folder)) {
            Write-Host "ERROR - The target folder ""$Folder"" didn't exists" -ForegroundColor White -BackgroundColor Red
            exit -1
        }
    }

    <#
    .SYNOPSIS
        Add leading zeros, return "010" when $counter is set to 10
    #>
    function global:consoleAddLeadingZeros([int] $counter) {
        return "{0:000}" -f $counter
    }

    <#
    .SYNOPSIS
        Retrieve all .zip files recursively
    .OUTPUTS
        void
    #>
    function unzipArchives {

        # Get all zips; recursively; as an array. Keep three infos, folder name, full folder name and full filename
        $zipFiles = Get-ChildItem "*.zip" -Path $Folder -Recurse -File | Select Name, `
            @{ n = 'Folder'; e = { Convert-Path $_.PSParentPath } }, `
            @{ n = 'Foldername'; e = { ($_.PSPath -split '[\\]')[-2] } } ,
            @{ n = 'Fullname'; e = { Convert-Path $_.PSPath } }

        $count = $zipFiles.count

        Write-Host "`n$count archives were found in the folder $folder" -ForegroundColor Green

        if ($count -eq 0) {
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

            Write-Host (consoleAddLeadingZeros($progress)) -NoNewline
            Write-Host " /" (consoleAddLeadingZeros($count)) -NoNewline
            Write-Host " - Unzip $($zipFile.Fullname)"

            $location = $objShell.NameSpace($path)

            Write-Progress -Activity "Unzipping to $($path)" `
                -PercentComplete (($progress / ($zipFiles.Count + 1)) * 100) `
                -CurrentOperation $zipFile.Fullname `
                -Status "File $($progress) of $($zipFiles.Count)"

            $zipFolder = $objShell.NameSpace($zipFile.Fullname)

            # 1040 - No msgboxes to the user - http://msdn.microsoft.com/en-us/library/bb787866%28VS.85%29.aspx
            $location.Copyhere($zipFolder.items(), 1040)

            # And now remove the zip file
            Remove-Item $zipFile.Fullname

            Pop-Location
        }

        Write-Host "`nAll archives have been extracted"
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
    #endregion Entry point
}
