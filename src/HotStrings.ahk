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
#include <Configuration.cls>
#include <Picker>
#include <Editors>
#include *i <Password>

global config
hsCol := {}

; ----------------------------------------------------------------------------
;region Auto-Execute Section
config := Get_Config()
Check_Config()
Picker_Gui_Build()
Load_CSV() ; Loads the data from the CSV file
return
;endregion

; ----------------------------------------------------------------------------
;region Code unrelated to Gui

; Create the config object
Get_Config() {
    OutputDebug, % "-- Get_Config() `n"
    configFile := SubStr(A_ScriptFullPath, 1, -4) . ".ini"
    if !FileExist(configFile)
        FileAppend,, %configFile%
    return new Configuration(configFile)
}

; check if the CSV file and notes directory are configured and exists
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
        FileSelectFolder, fsfValue, *%A_MyDocuments%,, Choose a folder for notes
        if (fsfValue) {
            config.notesDir := fsfValue
        } else {
            OutputDebug, % "No notes folder selected"
            MsgBox, 16, HotStrings.ahk - No notes Folder, You MUST select a notes folder
            ExitApp, 1
        }
    }
}

; Load the CSV file, send the data to the gui
Load_CSV() {
    OutputDebug, % "-- Load_CSV() `n"
    global hsCol

    Register_HotStrings(hsCol)
    Picker_Load_HotStrings(objCSV)
}

; From the loaded data, create the hotstrings
Register_HotStrings(hsCol) {
    OutputDebug, % "-- Create_HotStrings() `n"

    ; Setup HotStrings
    For trigger, _ in hsCol {
        Hotstring("`:X`:" trigger, "Send_Replacement")
        OutputDebug, % A_Tab . "Added HotString: " trigger "`n"
    }
}

; Send the replacement text related to the trigger
Send_Replacement() {
    OutputDebug, % "-- Send_Replacement() `n"
    global hsCol
    trigger := SubStr(A_ThisHotkey, 4)
    if hsCol.HasKey(trigger) {
        arrHS := hsCol[trigger]
        OutputDebug, % A_Tab . "Trigger = " . trigger
        OutputDebug, % A_Tab . "arrHS.Count() = " . arrHS.Count()
        if arrHS.Count() = 1
            hs := arrHS[1]
        else if arrHS.Count() > 1 {
            hs := arrHS.Pop()
            arrHS.InsertAt(1, hs)
        }
        if hs.Treated
            Send, % hs.Replacement
        else
            SendRaw, % hs.Replacement
    }
}
return
;endregion

; ----------------------------------------------------------------------------
;region HotKeys and HotStrings definitions
; #IfWinNotActive, ahk_exe Code.exe
#if !A_IsCompiled
^F1::
    KeyWait, CTRL, T1
    if ErrorLevel {
        OutputDebug, % "#### HotKey F1 Long Pressed `n"
        SoundBeep
        Editors_RemoveEnded()
        Editors_Tile()
        return
    }
    OutputDebug, % "#### HotKey F1 Pressed `n"
    Picker_Gui_Show()
return

#if A_IsCompiled
F1::
    KeyWait, F1, T1
    if ErrorLevel {
        OutputDebug, % "#### HotKey F1 Long Pressed `n"
        SoundBeep
        Editors_RemoveEnded()
        Editors_Tile()
        return
    }
    OutputDebug, % "#### HotKey F1 Pressed `n"
    Picker_Gui_Show()
return
#if

; #IfWinActive
;endregion

#include *i <Corrections>
