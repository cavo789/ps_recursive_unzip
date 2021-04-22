# Recursive unzip

![Banner](banner.svg)

> Scan a folder recursively and, for each retrieved `.zip` files, unzip it in the same folder then remove the archive. Use the native Windows compression feature; no dependency with other tools like `7-zip`.

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Install](#install)
* [Usage](#usage)
  * [Password protected file](#password-protected-file)
  * [Tips](#tips)
* [License](#license)

## Install

Click on the green "Code" button, here top left. Download the zip.

You just need the `unzip.ps1` script. The `unzip.bat` file is provided as an example on how to call the script with parameters.

## Usage

Start a DOS prompt and execute the script by typing `powershell .\unzip.ps1` on the prompt.

If you don't provide the required parameters, a help screen will be displayed:

```text
Recursive Unzip

The script will scan a folder recursively and retrieve all .zip files then uncompress the archive in the same folder.

If you specify the `-delete` command line argument, the archive is then removed.

Be careful, this script can be destructive: will overwrite files during the unzip action and remove the archive afterward.

At the end, all .zip files are uncompressed and removed

Usage: unzip [-help] [-delete] [-force] [-folder <foldername>] [-log <filename>]

 -help      Show this screen
 -delete    Delete the archive once uncompressed
 -force     Don't ask for confirmation, run the script
 -folder    Name of the folder to process
 -log       Name of a logfile where to keep track of which files were processed (append mode)
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

### Password protected file

Using the native Windows uncompress method, it seems to be impossible to get an exit code i.e. does the uncompress action has succeeded or not.

When a ZIP is password protected, the file will be skipped and no error will trigger as soon as the `FOF_NOERRORUI` flag has been used. That flag is meanwhile used in the source to make the tool working in a cron task (*every night, uncompress files in a given folder f.i.*).

By looking at the logfile, you'll then see that the password zip has been retrieved and processed but you can't see if the unzip has work or not.

So, in conclusion, **no protected file will be unzipped by this tool**, they'll be ignored without any notification.

### Tips

You can also directly start the script like this: `powershell .\unzip.ps1 -folder c:\temp -force` to bypass the confirmation prompt.

## License

[MIT](LICENSE)
