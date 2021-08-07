; ----------------------------------------------------------------------------
;region Script level settings
#SingleInstance, force
#NoEnv ; Recommended for performance and compatibility
SendMode Input ; Recommended for new scripts
; SetKeyDelay 20
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
;endregion
; ----------------------------------------------------------------------------

; LVM_SETHOVERTIME   := 0x1047 ; (LVM_FIRST + 71)
; LVN_HOTTRACK       := -121 ; (LVN_FIRST - 21)
; LVS_EX_TRACKSELECT := 0x00000008
; WM_NOTIFY          := 0x004E
; WM_ACTIVATEAPP     := 0x001C
#include *i <Configuration>
#include *i <ObjCSV>
#include *i <Picker>

global version = 5
global objCSV
global hsCache
global category
global categories
global config := Get_Config()

; ----------------------------------------------------------------------------
;region Auto-Execute Section
Notify_Updated() ; Checks to see if it's been updated to notify the user
if Check_Updates()
    Update_Script()
Check_Dependencies() ; Checks for and download the dependencies
Load_CSV() ; Loads the data from the CSV file
Create_HotStrings() ; From the loaded data, create the hotstrings
Func("Picker_Build").call() ; Build the Gui
Func("Picker_Show").call() ; Show the Gui that we just built
return
;endregion
; ----------------------------------------------------------------------------

; ----------------------------------------------------------------------------
;region Code unrelated to Gui
Notify_Updated() {
    OutputDebug, % "-- Notify_Updated()"
    if FileExist(A_ScriptDir . "\updated.txt") {
        FileDelete, %A_ScriptDir%\updated.txt
        TrayTip, Updates, The script has been updated
    }
}

Check_Updates() {
    OutputDebug, % "-- Check_Updates()"
    static updatesAvailable := "New"

    if (updatesAvailable = "New") {
        url := "https://raw.githubusercontent.com/"
        . "fstemarie/ahk_HotStrings/master/version.txt"
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, true)
        whr.Send()
        whr.WaitForResponse()
        gh_version := Format("{:i}", whr.ResponseText)
        updatesAvailable := (gh_version > version)
    }
    return updatesAvailable
}

Update_Script() {
    OutputDebug, % "-- Update_Script()"
    url := "https://raw.githubusercontent.com/fstemarie/"
    . "ahk_HotStrings/master/HotStrings/Lib/Configuration.ahk"
    UrlDownloadToFile, %url%, %A_ScriptFullPath%\lib
    url := "https://raw.githubusercontent.com/fstemarie/"
    . "ahk_HotStrings/master/HotStrings/Lib/Picker.ahk"
    UrlDownloadToFile, %url%, %A_ScriptFullPath%\lib
    url := "https://raw.githubusercontent.com/fstemarie/"
    . "ahk_HotStrings/master/HotStrings/HotStrings.ahk"
    UrlDownloadToFile, %url%, %A_ScriptFullPath%
    FileAppend, "", %A_ScriptDir% . "\updated.txt"
    Reload
}

Check_Dependencies() {
    OutputDebug, % "-- Check_Dependencies()"
    hasToReload := false
    libDir := A_ScriptDir . "\lib"
    if !FileExist(libDir)
        FileCreateDir, %libDir%

    ; ObjCSV.ahk
    file := libDir . "\ObjCSV.ahk"
    if !FileExist(file) {
        url := "https://raw.githubusercontent.com/"
        . "JnLlnd/ObjCSV/master/Lib/ObjCSV.ahk"
        UrlDownloadToFile, %url%, %file%
        hasToReload := true
    }
    ; Picker.ahk
    file := libDir . "\Picker.ahk"
    if !FileExist(file) {
        url := "https://raw.githubusercontent.com/"
        . "fstemarie/ahk_HotStrings/master/HotStrings/Lib/Picker.ahk"
        UrlDownloadToFile, %url%, %file%
        hasToReload := true
    }

    ; Configuration.ahk
    file := libDir . "\Configuration.ahk"
    if !FileExist(file) {
        url := "https://raw.githubusercontent.com/"
        . "fstemarie/ahk_HotStrings/master/HotStrings/Lib/Configuration.ahk"
        UrlDownloadToFile, %url%, %file%
        hasToReload := true
    }
    if hasToReload
        Reload
}

Get_Config() {
    OutputDebug, % "-- Get_Config()"
    return new Configuration(SubStr(A_ScriptFullPath, 1, -4) . ".ini")
}

Load_CSV() {
    OutputDebug, % "-- Load_CSV()"
    hsCache := {}
    categories := ""
    objCSV := Func("ObjCSV_CSV2Collection").call(config.csvFile
    , "Trigger,Replacement,Category,Treated", False)

    i := objCSV.MaxIndex()
    while i >= objCSV.MinIndex() {
        ; Remove rows that don't have the Text field filled
        row := objCSV[i]
        if !row.Replacement {
            objCSV.RemoveAt(i--)
            continue
        }
        ; Gather all the categories
        categories .= row.Category . "|"

        ; Find the default category if there is one
        if SubStr(row.Category, 1, 1) = "@"
            config.defaultCategory := row.Category

        ; Fill hsCache with all the hotstrings
        if !hsCache.HasKey(row.Trigger)
            hsCache[row.Trigger] := []
        objHS := {Trigger: row.Trigger, Replacement: row.Replacement
        , Treated: row.Treated}
        hsCache[row.Trigger].Push(objHS)
        i--
    }
    Sort, categories, U D|
    categories := "*|" . categories
    config.defaultCategory := config.defaultCategory?config.defaultCategory
    category := config.defaultCategory?config.defaultCategory:"*"
}

Create_HotStrings() {
    OutputDebug, % "-- Create_HotStrings()"

    ; Setup HotStrings
    For trigger, arrHS in hsCache {
        objHS := arrHS[1]
        Hotstring("`:X`:" objHS.Trigger, "Send_Replacement")
        OutputDebug, % A_Tab . "Added HotString: " objHS.Trigger
    }
}

Send_Replacement() {
    OutputDebug, % "-- Send_Replacement()"
    trigger := SubStr(A_ThisHotkey, 4)
    if hsCache.HasKey(trigger) {
        arrHS := hsCache[trigger]
        OutputDebug, % A_Tab . "Trigger = " . trigger
        OutputDebug, % A_Tab . "arrHS.Count() = " . arrHS.Count()
        if arrHS.Count() = 1 {
            objHS := arrHS[1]
        } else if arrHS.Count() > 1 {
            objHS := arrHS.Pop()
            arrHS.InsertAt(1, objHS)
        }
        if objHS.Treated {
            Send, % objHS.Replacement
        } else {
            SendRaw, % objHS.Replacement
        }
    }
}

Fetch_Password() {
    OutputDebug, % "-- Fetch_Password()"
    static password
    if (password = "") {
        cmd := "KeePassCommand getfield Citrix Password"
        out := ComObjCreate("WScript.Shell")
        .Exec(A_ComSpec . " /q /c " . cmd).StdOut.ReadAll()
        out := StrSplit(out, "`r`n")[4]
        out := RegExReplace(out, "\s+", " ")
        password := StrSplit(out, " ")[3]
    }
    return password
}
return
;endregion
; ----------------------------------------------------------------------------

; ----------------------------------------------------------------------------
;region HotKeys and HotStrings definitions

; #IfWinNotActive, ahk_exe Code.exe
F1::
    OutputDebug, % "HotKey F1 Pressed"
    Func("Picker_Show").call()
return
#IfWinActive

#IfWinActive, Virtual Desktop - Desktop Viewer
:*:###::
    SendRaw % Fetch_Password()
return
#IfWinActive

:?:ino::ion
::PArfait::Parfait
::PArfais::Parfait
::connexino::connexion
:C:JE::Je
;endregion
; ----------------------------------------------------------------------------
