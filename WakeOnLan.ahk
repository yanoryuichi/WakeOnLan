; 使い方: WakeOnLan.exe [セクション名]   (例: WakeOnLan.exe MyPC1)
; ahk をコンパイルした exe と同じフォルダに WakeOnLan.ps1 / config.ini を置く
SetWorkingDir %A_ScriptDir%
name = %1%
Run, powershell -WindowStyle hidden -ExecutionPolicy Bypass -File ".\WakeOnLan.ps1" -Name "%name%",, Hide
