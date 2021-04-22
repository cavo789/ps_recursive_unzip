@echo off
cls
REM Remove the previous log (comment this line if you wish to keep the history)
del C:\temp\unzip\unzip.log
powershell .\unzip.ps1 -folder C:\temp\unzip -force -log C:\temp\unzip\unzip.log

