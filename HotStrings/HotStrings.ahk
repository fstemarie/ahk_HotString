#SingleInstance, force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
; SetKeyDelay 20
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

global csvFile := Get_csvFile()

Picker_Build()
Picker_Show()
LoadData()

Get_csvFile() {
    OutputDebug, % "-- Get_csvFile()"
    configFile := (A_ScriptDir . "\" . SubStr(A_ScriptName, 1, -4) . ".ini")
    IniRead, csvFile, %configFile%, Configuration, csvFile
    if (csvFile == "ERROR") {
        FileSelectFile, fsfValue, 3,, Choose your HotStrings CSV file, Comma Separated Values (*.csv)
        if (fsfValue) {
            IniWrite, %fsfValue%, %configFile%, Configuration, csvFile
            csvFile := fsfValue
        }
    }
    return csvFile
}

LoadData() {
    OutputDebug, % "-- LoadData()"
	objCSV := ObjCSV_CSV2Collection(csvFile, "HotString,Text,Category", False)

    ; Fill the ListView
    Gui, Picker:Default
    Gui, ListView, lvPicker
    GuiControl, Hide, lvPicker
    LV_Delete()
    ObjCSV_Collection2ListView(objCSV, Picker, lvPicker, strFieldOrder := "HotString,Text,Category")
    LV_Modify(20, "+Focus +Select")
    LV_ModifyCol(1, AutoHDR)
    LV_ModifyCol(2, 1050)
    LV_ModifyCol(3, AutoHDR)
    GuiControl, Show, lvPicker

    ; Setup HotStrings
    Loop, % objCSV.MaxIndex() {
        row := objCSV[A_Index]
        try {
            Hotstring("`:`:" row.HotString, row.Text)
            OutputDebug, % "Added HotString: " row.HotString
        }
        catch {
            MsgBox "The hotstring does not exist or it has no variant for the current IfWin criteria."
        }
    }
}

Password() {
    OutputDebug, % "-- Password()"

    static password
    if (password = "") {
        cmd := "KeePassCommand getfield Citrix Password"
        out := ComObjCreate("WScript.Shell").Exec(A_ComSpec . " /q /c " . cmd).StdOut.ReadAll()
        out := StrSplit(out, "`r`n")[4]
        out := RegExReplace(out, "\s+", " ")
        password := StrSplit(out, " ")[3]
    }
    return password
}
return

F1::
OutputDebug, % "HotKey F1 Pressed"
Loop 2 {
    Picker_Show()
}
return

#IfWinActive, Virtual Desktop - Desktop Viewer
:*:###::
    SendRaw % Password()
return
#IfWinActive

:?:ino::ion
::PArfait::Parfait
::PArfais::Parfait
::connectino::connexion
