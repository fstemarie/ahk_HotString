; Ahk2Exe-AddResource ../assets/Hblue.ico, 160   ; Replaces 'H on blue'
; Ahk2Exe-AddResource ../assets/Sgreen.ico, 206  ; Replaces 'S on green'
; Ahk2Exe-AddResource ../assets/Hred.ico, 207    ; Replaces 'H on red'
; Ahk2Exe-AddResource ../assets/Sred.ico, 208    ; Replaces 'S on red'

; ----------------------------------------------------------------------------
;region Script level settings
#SingleInstance, force
#NoEnv ; Recommended for performance and compatibility
SendMode Input ; Recommended for new scripts
; SetKeyDelay 20
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
;endregion
; ----------------------------------------------------------------------------

#include <ObjCSV>
#include <Configuration>
#include <Picker>
#include *i <Password>

global version = 6
, objCSV
, hsCache := {}
, category := ""
, categories := ""
, config := Get_Config()

; ----------------------------------------------------------------------------
;region Auto-Execute Section
Notify_Updated() ; Checks to see if it's been updated to notify the user
if Check_Updates()
    Update_Script()
; Check_Dependencies() ; Checks for and download the dependencies

Load_CSV() ; Loads the data from the CSV file
Create_HotStrings() ; From the loaded data, create the hotstrings
Picker_Build() ; Build the Gui
return
;endregion

; ----------------------------------------------------------------------------
;region Code unrelated to Gui
Notify_Updated() {
    OutputDebug, % "-- Notify_Updated() `n"
    if FileExist(A_ScriptDir . "\updated.txt") {
        FileDelete, %A_ScriptDir%\updated.txt
        TrayTip, Updates, The script has been updated
    }
}

Check_Updates() {
    OutputDebug, % "-- Check_Updates() `n"
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
    OutputDebug, % "-- Update_Script() `n"
    url := "https://raw.githubusercontent.com/fstemarie/"
    . "ahk_HotStrings/master/src/lib/Configuration.ahk"
    UrlDownloadToFile, %url%, %A_ScriptFullPath%\lib
    url := "https://raw.githubusercontent.com/fstemarie/"
    . "ahk_HotStrings/master/src/lib/Picker.ahk"
    UrlDownloadToFile, %url%, %A_ScriptFullPath%\lib
    url := "https://raw.githubusercontent.com/fstemarie/"
    . "ahk_HotStrings/master/src/HotStrings.ahk"
    UrlDownloadToFile, %url%, %A_ScriptFullPath%
    FileAppend, "", %A_ScriptDir% . "\updated.txt"
    Reload
}

Get_Config() {
    OutputDebug, % "-- Get_Config() `n"
    configFile := SubStr(A_ScriptFullPath, 1, -4) . ".ini"
    if !FileExist(configFile)
        FileAppend,, %configFile%
    return new Configuration(configFile)
}

Load_CSV() {
    OutputDebug, % "-- Load_CSV() `n"
    objCSV := ObjCSV_CSV2Collection(config.csvFile
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
    OutputDebug, % "-- Create_HotStrings() `n"

    ; Setup HotStrings
    For trigger, arrHS in hsCache {
        objHS := arrHS[1]
        Hotstring("`:X`:" objHS.Trigger, "Send_Replacement")
        OutputDebug, % A_Tab . "Added HotString: " objHS.Trigger "`n"
    }
}

Send_Replacement() {
    OutputDebug, % "-- Send_Replacement() `n"
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
return
;endregion

; ----------------------------------------------------------------------------
;region HotKeys and HotStrings definitions
; #IfWinNotActive, ahk_exe Code.exe
F2::
    OutputDebug, % "HotKey F1 Pressed `n"
    Picker_Show()
return
#IfWinActive

:?:ino::ion
::PArfait::Parfait
::PArfais::Parfait
::connexino::connexion
:C:JE::Je
;endregion
