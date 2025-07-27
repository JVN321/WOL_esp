Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Get the directory where this VBS script is located
strScriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)

' Build the path to the PowerShell script
strPSScript = strScriptDir & "\StartupSleep.ps1"

' Run PowerShell script hidden (0 = hidden window, False = don't wait for completion)
objShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & strPSScript & """", 0, False
