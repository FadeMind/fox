@(set "0=%~f0"^)#) & powershell -nop -c iex([io.file]::ReadAllText($env:0)) & exit/b
#:: double-click to run or just copy-paste into powershell - it's a standalone hybrid script
#::
$_Paste_in_Powershell = { $host.ui.RawUI.WindowTitle = 'Edge Removal - AveYo, 2022.06.19'

$also_remove_webview = 1 

## fixed latest cumulative update (LCU) failing due to non-matching EndOfLife entries
$appx = @(); $prov = @(); $msn = "Microsoft.MicrosoftEdge"
$bing = "${msn}_8wekyb3d8bbwe", "${msn}.Stable_8wekyb3d8bbwe", "${msn}DevToolsClient_8wekyb3d8bbwe"
get-appxpackage -allusers |where {$_.PackageFullName -like '*MicrosoftEdge*'} |foreach {$appx += $_.PackageFullName}
get-appxprovisionedpackage -online |where {$_.PackageName -like '*MicrosoftEdge*'} |foreach {$prov += $_.PackageName}
if ($also_remove_webview -ne 0) {
  get-appxpackage -allusers |where {$_.PackageFullName -like '*Win32WebViewHost*'} |foreach {$appx += $_.PackageFullName}
  get-appxprovisionedpackage -online |where {$_.PackageName -like '*Win32WebViewHost*'} |foreach {$prov += $_.PackageName}
  $bing += 'Microsoft.Win32WebViewHost_cw5n1h2txyewy'
}
$users = ([wmi]"win32_userAccount.Domain='$env:userdomain',Name='$env:username'").SID,'S-1-5-18'
$store = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
reg add "$store" /f /v CleanupTaskComplete /d 0 /t reg_dword 2>&1 >''
foreach ($p in $bing) { reg add "$store\Deprovisioned\$p" /f /ve /d "" 2>&1 >'' }
foreach ($p in $prov) { foreach ($user in $users) { reg add "$store\EndOfLife\$user\$p" /f /ve /d "" 2>&1 >'' } }
foreach ($p in $appx) { foreach ($user in $users) { reg add "$store\EndOfLife\$user\$p" /f /ve /d "" 2>&1 >'' } }

## find all Edge setup.exe
$setup = @(); $root = @(); $bho = @(); "LocalApplicationData","ProgramFilesX86","ProgramFiles" |foreach {
  $setup += dir $($([Environment]::GetFolderPath($_)) + '\Microsoft\Edge*\setup.exe') -rec -ea 0
  $root += dir $($([Environment]::GetFolderPath($_)) + '\Microsoft\Edge*') -rec -ea 0
  $bho += dir $($([Environment]::GetFolderPath($_)) + '\Microsoft\Edge*\ie_to_edge_stub.exe') -rec -ea 0
}

## export ChrEdgeFkOff innovative redirector
foreach ($b in $bho) { if (test-path $b) { copy $b "$env:ProgramData\ie_to_edge_stub.exe" -force -ea 0; break } }

## set useless policies
foreach ($p in 'HKLM\SOFTWARE\Policies','HKLM\SOFTWARE') {
  reg add "$p\Microsoft\EdgeUpdate" /f /v InstallDefault /d 0 /t reg_dword >''
  reg add "$p\Microsoft\EdgeUpdate" /f /v "Install{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}" /d 0 /t reg_dword >''
  reg add "$p\Microsoft\EdgeUpdate" /f /v DoNotUpdateToEdgeWithChromium /d 1 /t reg_dword >''
}

## remove Edge lame uninstall block
$uninstall = '\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge'
foreach ($wow in '','\Wow6432Node') {'HKCU:','HKLM:' |foreach { rp $($_ + $wow + $uninstall) NoRemove -force -ea 0 } }

## shut it down
foreach ($e in 'MicrosoftEdgeUpdate','chredge','msedge','msedgewebview2','Widgets') { kill -name $e -force -ea 0 }

## uninstall app
foreach ($p in $prov) { powershell -nop -c remove-appxprovisionedpackage -online -packagename $p 2>&1 >''}
foreach ($p in $appx) { 
  powershell -nop -c remove-appxpackage -package $p 2>&1 >''; 
  powershell -nop -c remove-appxpackage -allusers -package $p 2>&1 >''
}

## shut it down, again
foreach ($e in 'MicrosoftEdgeUpdate','chredge','msedge','msedgewebview2','Widgets') { kill -name $e -force -ea 0 }

## brute-run found Edge setup.exe with uninstall args
$purge = '--uninstall --force-uninstall --system-level'
if ($also_remove_webview -ne 0) { foreach ($s in $setup) { try{ start -wait $s -args "--msedgewebview $purge" } catch{} } }
foreach ($s in $setup) { try{ start -wait $s -args "--msedge $purge" } catch{} }

## fix LCU
foreach ($p in $prov) { foreach ($user in $users) { reg delete "$store\EndOfLife\$user\$p" /f 2>&1 >'' } }
foreach ($p in $appx) { foreach ($user in $users) { reg delete "$store\EndOfLife\$user\$p" /f 2>&1 >'' } }
$done1 = reg query "$store\EndOfLife" /f "*MicrosoftEdge*" /k /s
foreach ($i in $done1) { if ($i -like '*MicrosoftEdge*') {reg delete "$i" /f 2>&1 >''} }
$done2 = reg query "$store\EndOfLife" /f "*Win32WebViewHost*" /k /s
foreach ($i in $done2) { if ($i -like '*Win32WebViewHost*') {reg delete "$i" /f 2>&1 >''} }

## remove leftovers
#foreach ($i in 'MicrosoftEdgeUpdateTaskMachineCore','MicrosoftEdgeUpdateTaskMachineUA') { schtasks /delete /tn "$i" /f 2>&1 >''}
#$updt = reg query "HKLM\SYSTEM\CurrentControlSet\Services" /f "edgeupd*" /k
#foreach ($i in $updt) { if ($i -like '\Services\edgeupd*') {reg delete "$i" /f 2>&1 >''} }
#$elev = reg query "HKLM\SYSTEM\CurrentControlSet\Services" /f "EdgeElevat*" /k
#foreach ($i in $elev) { if ($i -like '\Services\EdgeElevat*') {reg delete "$i" /f 2>&1 >''} }
#$IELaunch = '\Microsoft\Internet Explorer\Quick Launch'
#del $([Environment]::GetFolderPath('Desktop') + '\Microsoft Edge*.lnk') -force -ea 0 2>&1 >''
#del $([Environment]::GetFolderPath('ApplicationData') + $IELaunch + '\Microsoft Edge*.lnk') -force -ea 0 2>&1 >''
#del $($env:SystemRoot+'\System32\config\systemprofile\AppData\Roaming' + $IELaunch + '\Microsoft Edge*.lnk') -force -ea 0 2>&1 >''
#del $($env:SystemDrive+'\Users\Public\Desktop\Microsoft Edge*.lnk') -force -ea 0 2>&1 >''
#foreach ($dir in $root) { rmdir $dir -rec -force -ea 0 2>&1 >'' } 

##################################################################################################################################

## add ChrEdgeFkOff to redirect microsoft-edge: anti-competitive links to the default browser 
$ChrEdgeFkOff = @'
@echo off
::# toggle when launched without arguments, else jump to arguments: "install" or "remove"
set CLI=%*& set IFEO=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options& set MSE=& set BHO=&;
for /f "tokens=2*" %%V in ('reg query "HKCR\MSEdgeMHT\shell\open\command" /ve 2^>nul') do set "ProgID=%%W"
for %%W in (%ProgID%) do if not defined MSE set "MSE=%%~W"& set "MSEPath=%%~dpW"
if /i "%CLI%"=="" reg query "%IFEO%\ie_to_edge_stub.exe\0" /v Debugger >nul 2>nul && goto remove || goto install
if /i "%~1"=="install" (goto install) else if /i "%~1"=="remove" goto remove

:install
if defined MSEPath for /f "delims=" %%W in ('dir /o:D /b /s "%MSEPath%\*ie_to_edge_stub.exe" 2^>nul') do set "BHO=%%~fW" 
if not exist "%MSEPath%chredge.exe" if exist "%MSE%" mklink /h "%MSEPath%chredge.exe" "%MSE%" >nul
if defined BHO copy /y "%BHO%" "%ProgramData%\\" >nul 2>nul
call :export ChrEdgeFkOff.vbs > "%ProgramData%\ChrEdgeFkOff.vbs"
reg add HKCR\microsoft-edge /f /ve /d URL:microsoft-edge >nul
reg add HKCR\microsoft-edge /f /v "URL Protocol" /d "" >nul
reg add HKCR\microsoft-edge /f /v "NoOpenWith" /d "" >nul 
reg add HKCR\microsoft-edge\shell\open\command /f /ve /d "\\"%ProgramData%\ie_to_edge_stub.exe\\" %%1" >nul
reg add HKCR\MSEdgeHTM /f /v "NoOpenWith" /d "" >nul
reg add HKCR\MSEdgeHTM\shell\open\command /f /ve /d "\\"%ProgramData%\ie_to_edge_stub.exe\\" %%1" >nul
reg add "%IFEO%\ie_to_edge_stub.exe" /f /v UseFilter /d 1 /t reg_dword >nul >nul
reg add "%IFEO%\ie_to_edge_stub.exe\0" /f /v FilterFullPath /d "%ProgramData%\ie_to_edge_stub.exe" >nul
reg add "%IFEO%\ie_to_edge_stub.exe\0" /f /v Debugger /d "wscript.exe \\"%ProgramData%\ChrEdgeFkOff.vbs\\" //B //T:60" >nul
reg add "%IFEO%\msedge.exe" /f /v UseFilter /d 1 /t reg_dword >nul
reg add "%IFEO%\msedge.exe\0" /f /v FilterFullPath /d "%MSE%" >nul
reg add "%IFEO%\msedge.exe\0" /f /v Debugger /d "wscript.exe \\"%ProgramData%\ChrEdgeFkOff.vbs\\" //B //T:60" >nul
exit /b 

:remove
del /f /q "%ProgramData%\ChrEdgeFkOff.vbs" "%MSEPath%chredge.exe" >nul 2>nul 
rem del /f /q "%ProgramData%\ie_to_edge_stub.exe"
reg delete HKCR\microsoft-edge /f /v "NoOpenWith" >nul 2>nul
reg add HKCR\microsoft-edge\shell\open\command /f /ve /d "\\"%MSE%\\" --single-argument %%1" >nul
reg delete HKCR\MSEdgeHTM /f /v "NoOpenWith" >nul 2>nul
reg add HKCR\MSEdgeHTM\shell\open\command /f /ve /d "\\"%MSE%\\" --single-argument %%1" >nul
reg delete "%IFEO%\ie_to_edge_stub.exe" /f >nul 2>nul
reg delete "%IFEO%\msedge.exe" /f >nul 2>nul
exit /b

:export: [USAGE] call :export NAME
setlocal enabledelayedexpansion || Prints all text between lines starting with :NAME:[ and :NAME:] - A pure batch snippet by AveYo
set [=&for /f "delims=:" %%s in ('findstr /nbrc:":%~1:\[" /c:":%~1:\]" "%~f0"')do if defined [ (set /a ]=%%s-3)else set /a [=%%s-1 
<"%~f0" ((for /l %%i in (0 1 %[%) do set /p =)&for /l %%i in (%[% 1 %]%) do (set txt=&set /p txt=&echo(!txt!)) &endlocal &exit /b

:ChrEdgeFkOff_vbs:[
' ChrEdgeFkOff v4 - make start menu web search, widgets links or help open in your chosen default browser - by AveYo  
Dim A,F,CLI,URL,decode,utf8,char,u,u1,u2,u3,ProgID,Choice : CLI = "": URL = "": For i = 1 to WScript.Arguments.Count - 1
A = WScript.Arguments(i): CLI = CLI & " " & A: If InStr(1, A, "microsoft-edge:", 1) Then: URL = A: End If: Next 

decode = Split(URL,"%"): u = 0: Do While u <= UBound(decode): If u <> 0 Then
char = Left(decode(u),2): If "&H" & Left(char,2) >= 128 Then
decode(u) = "": u = u + 1: char = char & Left(decode(u),2): If "&H" & Left(char,2) < 224 Then
u1 = Cint("&H" & Left(char,2)) Mod 32: u2 = Cint("&H" & Mid(char,3,2)) Mod 64: utf8 = ChrW(u2 + u1 * 64)
Else: decode(u) = "": u = u + 1: char = char & Left(decode(u),4): u1 = Cint("&H" & Left(char,2)) Mod 16
u2 = Cint("&H" & Mid(char,3,2)) Mod 32: u3 = Cint("&H" & Mid(char,5,2)) Mod 64: utf8 = ChrW(u3 + (u2 + u1 * 64) * 64): End If
Else: utf8 = Chr("&H" & char): End If: decode(u) = utf8 & Mid(decode(u),3)
End If: u = u + 1: Loop: URL = Trim(Join(decode,"")) ' stackoverflow . com /questions/17880395

On error resume next
Set W = CreateObject("WScript.Shell"): F = Split(URL,"://",2,1): If UBound(F) > 0 Then URL = F(1)
ProgID = W.RegRead("HKCU\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice\ProgID")
Choice = W.RegRead("HKCR\\" & ProgID & "\shell\open\command\\"): ProgID = W.RegRead("HKCR\MSEdgeMHT\shell\open\command\\")
If Instr(1,ProgID,Chr(34),1) Then ProgID = Split(ProgID,Chr(34))(1) Else ProgID = Split(ProgID,Chr(32))(1)
If Instr(1,Choice,ProgID,1) Then URL = "": End If: ProgID = Replace(ProgID,"msedge.exe","chredge.exe")
If URL = "" Then W.Run """" & ProgID & """ " & Trim(CLI), 1, False Else W.Run """https://" & URL & """", 1, False
' done
:ChrEdgeFkOff_vbs:]

'@
[io.file]::WriteAllText("$env:Temp\ChrEdgeFkOff.cmd",$ChrEdgeFkOff) >''
& "$env:Temp\ChrEdgeFkOff.cmd" install

##################################################################################################################################

## refresh explorer
kill -name 'sihost' -force

echo "`n EDGE REMOVED! IF YOU NEED TO SETUP ANOTHER BROWSER, ENTER: `n"
write-host -fore green @'
 $ffsetup='https://download.mozilla.org/?product=firefox-latest&os=win';
 $firefox="$([Environment]::GetFolderPath('Desktop'))\FirefoxSetup.exe";
 (new-object System.Net.WebClient).DownloadFile($ffsetup,$firefox); start $firefox
'@;''  

} ; start -verb runas powershell -args "-nop -noe -c & {`n`n$($_Paste_in_Powershell-replace'"','\"')}"
$_Press_Enter
#::
