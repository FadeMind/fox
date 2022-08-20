@(set '(=)||' <# lean and mean cmd / powershell hybrid #> @'

::# ChrEdgeFkOff - open desktop & start menu web search, widgets links or help in your chosen default browser - by AveYo
::# v7 no more cmd flash ;) v6 PoS Defender started screaming about the former vbs version so went vbs-less as well; v5 fix
::# v4 innovative redirect even if Edge is uninstalled! v3 powershell-less active part; parse "install" or "remove" args
::# if Edge is already removed, try installing Edge Stable, then remove it via Edge_Removal.bat

@echo off & title ChrEdgeFkOff || AveYo 2022.08.20

::# elevate with native shell by AveYo
>nul reg add hkcu\software\classes\.Admin\shell\runas\command /f /ve /d "cmd /x /d /r set \"f0=%%2\"& call \"%%2\" %%3"& set _= %*
>nul fltmc|| if "%f0%" neq "%~f0" (cd.>"%temp%\runas.Admin" & start "%~n0" /high "%temp%\runas.Admin" "%~f0" "%_:"=""%" & exit /b)

::# lean xp+ color macros by AveYo:  %<%:af " hello "%>>%  &  %<%:cf " w\"or\"ld "%>%   for single \ / " use .%|%\  .%|%/  \"%|%\"
for /f "delims=:" %%s in ('echo;prompt $h$s$h:^|cmd /d') do set "|=%%s"&set ">>=\..\c nul&set /p s=%%s%%s%%s%%s%%s%%s%%s<nul&popd"
set "<=pushd "%appdata%"&2>nul findstr /c:\ /a" &set ">=%>>%&echo;" &set "|=%|:~0,1%" &set /p s=\<nul>"%appdata%\c"

::# toggle when launched without arguments, else jump to arguments: "install" or "remove"
set CLI=%*&(set IFEO=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options&set MSE=&set BHO=&set ProgID=)
call :reg_var "HKCR\MSEdgeMHT\shell\open\command" "" ProgID
for %%. in (%ProgID%) do if not defined MSE set "MSE=%%~."& set "MSEPath=%%~dp."
if /i "%CLI%"=="" reg query "%IFEO%\ie_to_edge_stub.exe\0" /v Debugger >nul 2>nul && goto remove || goto install
if /i "%~1"=="install" (goto install) else if /i "%~1"=="remove" goto remove

:install
if defined MSEPath for /f "delims=" %%W in ('dir /o:D /b /s "%MSEPath%\*ie_to_edge_stub.exe"') do set "BHO=%%~fW"
if not exist "%MSEPath%chredge.exe" if exist "%MSE%" mklink /h "%MSEPath%chredge.exe" "%MSE%" >nul
if defined BHO copy /y "%BHO%" "%ProgramData%\" >nul 2>nul
call :export ChrEdgeFkOff_cmd > "%ProgramData%\ChrEdgeFkOff.cmd"
set "Headless_Console_by_AveYo=%systemroot%\system32\conhost.exe --headless" & rem still innovating
reg add "HKCR\microsoft-edge" /f /ve /d URL:microsoft-edge >nul
reg add "HKCR\microsoft-edge" /f /v "URL Protocol" /d "" >nul
reg add "HKCR\microsoft-edge" /f /v "NoOpenWith" /d "" >nul
reg add "HKCR\microsoft-edge\shell\open\command" /f /ve /d "\"%ProgramData%\ie_to_edge_stub.exe\" %%1" >nul
reg add "HKCR\MSEdgeHTM" /f /v "NoOpenWith" /d "" >nul
reg add "HKCR\MSEdgeHTM\shell\open\command" /f /ve /d "\"%ProgramData%\ie_to_edge_stub.exe\" %%1" >nul
reg add "%IFEO%\ie_to_edge_stub.exe" /f /v UseFilter /d 1 /t reg_dword >nul >nul
reg add "%IFEO%\ie_to_edge_stub.exe\0" /f /v FilterFullPath /d "%ProgramData%\ie_to_edge_stub.exe" >nul
reg add "%IFEO%\ie_to_edge_stub.exe\0" /f /v Debugger /d "%Headless_Console_by_AveYo% \"%ProgramData%\ChrEdgeFkOff.cmd\"" >nul
reg add "%IFEO%\msedge.exe" /f /v UseFilter /d 1 /t reg_dword >nul
reg add "%IFEO%\msedge.exe\0" /f /v FilterFullPath /d "%MSE%" >nul
reg add "%IFEO%\msedge.exe\0" /f /v Debugger /d "%Headless_Console_by_AveYo% \"%ProgramData%\ChrEdgeFkOff.cmd\"" >nul
if "%CLI%" neq "" exit /b
echo;& %<%:f0 " ChrEdgeFkOff V7 "%>>% & %<%:2f " INSTALLED "%>>% & %<%:f0 " run again to remove "%>%
timeout /t 7
exit /b

:remove
del /f /q "%ProgramData%\ChrEdgeFkOff.*" "%MSEPath%chredge.exe" >nul 2>nul
rem del /f /q "%ProgramData%\ie_to_edge_stub.exe"
reg delete HKCR\microsoft-edge /f /v "NoOpenWith" >nul 2>nul
reg add HKCR\microsoft-edge\shell\open\command /f /ve /d "\"%MSE%\" --single-argument %%1" >nul
reg delete HKCR\MSEdgeHTM /f /v "NoOpenWith" >nul 2>nul
reg add HKCR\MSEdgeHTM\shell\open\command /f /ve /d "\"%MSE%\" --single-argument %%1" >nul
reg delete "%IFEO%\ie_to_edge_stub.exe" /f >nul 2>nul
reg delete "%IFEO%\msedge.exe" /f >nul 2>nul
if "%CLI%" neq "" exit /b
echo;& %<%:f0 " ChrEdgeFkOff V7 "%>>% & %<%:df " REMOVED "%>>% & %<%:f0 " run again to install "%>%
timeout /t 7
exit /b

:export: [USAGE] call :export NAME
setlocal enabledelayedexpansion || Prints all text between lines starting with :NAME:[ and :NAME:] - A pure batch snippet by AveYo
set [=&for /f "delims=:" %%s in ('findstr /nbrc:":%~1:\[" /c:":%~1:\]" "%~f0"')do if defined [ (set /a ]=%%s-3)else set /a [=%%s-1
<"%~f0" ((for /l %%i in (0 1 %[%) do set /p =)&for /l %%i in (%[% 1 %]%) do (set txt=&set /p txt=&echo(!txt!)) &endlocal &exit /b

:ChrEdgeFkOff_cmd:[
@title ChrEdgeFkOff V7 & echo off & set ?= open start menu web search, widgets links or help in your chosen browser - by AveYo
rem PoS Defender started screaming about the former vbs version, so now this window will flash briefly. V7: not anymore ;)
call :reg_var "HKCU\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice" ProgID ProgID
if /i "%ProgID%" equ "MSEdgeHTM" echo;Default browser is set to Edge! Change it or remove ChrEdgeFkOff script. & pause & exit /b
call :reg_var "HKCR\%ProgID%\shell\open\command" "" Browser
set Choice=& for %%. in (%Browser%) do if not defined Choice set "Choice=%%~."
call :reg_var "HKCR\MSEdgeMHT\shell\open\command" "" FallBack
set ChrEdge=& for %%. in (%FallBack%) do if not defined ChrEdge set "ChrEdge=%%~."
set "CLI=%CMDCMDLINE:"=`%"
set "CLI=%CLI:~0,-1%"
set "CLI=%CLI:*ChrEdgeFkOff.cmd`=%"
set "CLI=%CLI:*ie_to_edge_stub.exe`=%"
set "CLI=%CLI:*msedge.exe`=%"
set "URL=http%CLI:*http=%" & set "NOOP=%CLI:microsoft-edge=%" & set "PASSTROUGH=%ChrEdge:msedge=chredge%"
if /i "%CLI%" equ "%NOOP%" if exist "%PASSTROUGH%" start "" "%PASSTROUGH%" %CLI:`="%
if /i "%CLI%" equ "%NOOP%" exit /b
set ".=%URL:!=}%"&setlocal enabledelayedexpansion& rem brute url percent decoding
set ".=!.:%%={!" &set ".=!.:{3A=:!" &set ".=!.:{2F=/!" &set ".=!.:{3F=?!" &set ".=!.:{23=#!" &set ".=!.:{5B=[!" &set ".=!.:{5D=]!"
set ".=!.:{40=@!"&set ".=!.:{21=}!" &set ".=!.:{24=$!" &set ".=!.:{26=&!" &set ".=!.:{27='!" &set ".=!.:{28=(!" &set ".=!.:{29=)!"
set ".=!.:{2A=*!"&set ".=!.:{2B=+!" &set ".=!.:{2C=,!" &set ".=!.:{3B=;!" &set ".=!.:{3D==!" &set ".=!.:{25=%!" &set ".=!.:{20= !"
endlocal& set "URL=%.:}=!%"
start "" "%Choice%" "%URL%" & exit /b

:reg_var [USAGE] call :reg_var "HKCU\Volatile Environment" value-or-"" variable [extra options]
set "reg_var=" & set reg_var/=/v %2& if %2=="" set reg_var/=/ve& rem AveYo, v2: support localized empty value names
for /f "tokens=* delims=" %%V in ('reg query "%~1" %reg_var/% /z /se "," %4 %5 %6 %7 %8 %9 2^>nul') do set "reg_var=%%V"
set "reg_var/=" & if %2=="" if defined reg_var set "reg_var=%reg_var:*)    =%"
if not defined reg_var (set "%~3=" & exit /b) else set "%~3=%reg_var:*)    =%" & set reg_var=& exit /b
rem done

:ChrEdgeFkOff_cmd:]

'@); $0 = "$env:temp\ChrEdgeFkOff.cmd"; ${(=)||} -split "\r?\n" | out-file $0 -encoding default -force; & $0
# press enter
