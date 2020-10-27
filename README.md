# Recursive unzip

![Banner](banner.svg)

> Scan a folder recursively and, for each retrieved `.zip` files, unzip it in the same folder then remove the archive. Use the native Windows compression feature; no dependency with other tools like `7-zip`.

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Install](#install)
* [Usage](#usage)
  * [Tips](#tips)
* [License](#license)

## Install

Clic on the green "Code" button, here top left. Download the zip.

You just need the `unzip.ps1` script. The `unzip.bat` file is provided as an example on how to call the script with parameters.

## Usage

Start a DOS prompt and execute the script by typing `powershell .\unzip.ps1` on the prompt. 

If you don't provide the required parameters, a help screen will be displayed:

```text
Recursive Unzip

The script will scan a folder recursively and retrieve all .zip files then:

   1. Uncompress the archive in the same folder
   2. Remove the zip

Be careful, this script is destructive; will overwrite files during the unzip action and remove the archive afterward.

At the end, all .zip files are uncompressed and removed

Usage: unzip [-help] [-force] [-folder <foldername>]

 -help      Show this screen
 -force     Don't ask for confirmation, run the script
 -folder    Name of the folder to process
```

The only required parameter is the parameter `-folder`. You need to specify there an existing folder name, the one where you've zip files.

By default, the script will ask for confirmation before doing his job. Please read the explanations displayed on the screen and press "yes" then <kbd>Enter</kbd> key to start the script. If you want to bypass that prompt, use the `-force` extra parameter.

If no zip are retrieved, the script will display something like this and exit:

```text
Recursive Unzip

0 archives were found in the folder C:\temp

No zip files found in folder C:\temp
```

Otherwise, the script will display the number of archives found and extract them one by one:

```text
Recursive Unzip

5 archives were found in the folder C:\temp\

001 / 005 - Unzip C:\temp\unzip.zip
002 / 005 - Unzip C:\temp\a1\a1.zip
003 / 005 - Unzip C:\temp\a1\a12\a12.zip
004 / 005 - Unzip C:\temp\a1\a12\a123\a123.zip
005 / 005 - Unzip C:\temp\a1\a12\a123\a1234\a1234.zip

All archives have been extracted
```

A progress bar will be displayed as the decompression progresses.

### Tips

You can also directly start the script like this: `powershell .\unzip.ps1 -folder c:\temp -force` to bypass the confirmation prompt.

## License

[MIT](LICENSE)
