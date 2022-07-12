; Ahk2Exe-AddResource ../assets/Hgreen.ico, 160  ; Replaces 'H on green'
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

global objCSV
, hsCache := {}
, category := ""
, categories := ""
, config := Get_Config()

; ----------------------------------------------------------------------------
;region Auto-Execute Section
Load_CSV() ; Loads the data from the CSV file
Create_HotStrings() ; From the loaded data, create the hotstrings
Picker_Build() ; Build the Gui
return
;endregion

; ----------------------------------------------------------------------------
;region Code unrelated to Gui
Get_Config() {
    OutputDebug, % "-- Get_Config() `n"
    configFile := SubStr(A_ScriptFullPath, 1, -4) . ".ini"
    if !FileExist(configFile)
        FileAppend,, %configFile%
    return new Configuration(configFile)
}

Check_Config() {
    if !config.csvFile {
        FileSelectFile, fsfValue, 3,, Choose your HotStrings CSV file, CSV File (*.csv)
        if (fsfValue) {
            config.csvFile := fsfValue
        } else {
            OutputDebug, % "No CSV File selected"
            MsgBox, 16, HotStrings.ahk - No CSV File, You MUST select a CSV File
            ExitApp, 1
        }
    }
    if !config.notesDir {
        FileSelectFolder, fsfValue, %A_MyDocuments%,, Choose a folder for notes
        if (fsfValue) {
            config.notesDir := fsfValue
        } else {
            OutputDebug, % "No notes folder selected"
            MsgBox, 16, HotStrings.ahk - No notes Folder, You MUST select a notes folder
            ExitApp, 1
        }
    }
}

Load_CSV() {
    OutputDebug, % "-- Load_CSV() `n"
    objCSV := ObjCSV_CSV2Collection(config.csvFile
    , "Trigger,Replacement,Category,Treated", False)

    i := objCSV.MaxIndex()
    if !i {
        return
    }
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
F1::
    OutputDebug, % "HotKey F1 Pressed `n"
    Picker_Show()
return
#IfWinActive
;endregion

#include *i <Corrections>
