; ----------------------------------------------------------------------
;region Script level settings
#SingleInstance, force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
; SetKeyDelay 20
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
;endregion
; ----------------------------------------------------------------------

; LVM_SETHOVERTIME   := 0x1047 ; (LVM_FIRST + 71)
; LVN_HOTTRACK       := -121 ; (LVN_FIRST - 21)
; LVS_EX_TRACKSELECT := 0x00000008
; WM_NOTIFY          := 0x004E
; WM_ACTIVATEAPP     := 0x001C

global version = 1
global lvPicker
global txtPicker
global hwndPicker
global lbCategories
global category
global csvFile := Get_csvFile()
global objCSV := ObjCSV_CSV2Collection(csvFile, "HotString,Text,Category,Treated", False, strFileEncoding:="UTF-16")

; ----------------------------------------------------------------------
;region Auto-Execute Section
if (Updates_Available()) {
    TrayTip, Updates, Updates are available
    Menu, Tray, Add
    Menu, Tray, Add, Update, Update
}
Load_HotStrings()
Picker_Build()
Picker_Show()
return
;endregion
; ----------------------------------------------------------------------

; ----------------------------------------------------------------------
;region HotKeys and HotStrings definitions

; #IfWinNotActive, ahk_exe Code.exe
F1::
OutputDebug, % "HotKey F1 Pressed"
Loop 2 {
    Picker_Show()
}
return
#IfWinActive

#F1::
return
#IfWinActive, PickerGui
#F1::
OutputDebug, % "HotKey WIN-F1 Pressed"
Run, GeekSquad.ods, D:\francois\Documents
return
#IfWinActive

#IfWinActive, Virtual Desktop - Desktop Viewer
:*:###::
    SendRaw % Get_Password()
return
#IfWinActive

:?:ino::ion
::PArfait::Parfait
::PArfais::Parfait
::connexino::connexion
:C:JE::Je
;endregion
; ----------------------------------------------------------------------

; ----------------------------------------------------------------------
;region Code unrelated to Gui
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

Updates_Available() {
    global version
    static updatesAvailable = "New"

    if (updatesAvailable = "New") {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", "https://raw.githubusercontent.com/fstemarie/ahk_HotStrings/master/version.txt", true)
        whr.Send()
        whr.WaitForResponse()
        gh_version := Format("{:i}", whr.ResponseText)
        updatesAvailable := (gh_version > version)
    }
    return updatesAvailable
}

Update() {
    UrlDownloadToFile, https://raw.githubusercontent.com/fstemarie/ahk_HotStrings/master/HotStrings/HotStrings.ahk, %A_ScriptFullPath%
    Reload
}

Load_HotStrings() {
    OutputDebug, % "-- LoadData()"
    ; Setup HotStrings
    Loop, % objCSV.MaxIndex() {
        row := objCSV[A_Index]
        try {
            if (!row.Treated) {
                Hotstring("`:R`:" row.HotString, row.Text)
            } else {
                HotString("`:`:" row.HotString, row.Text)
            }
            OutputDebug, % "Added HotString: " row.HotString
        }
        catch {
            MsgBox "The hotstring does not exist or it has no variant for the current IfWin criteria."
        }
    }
}

Get_Password() {
    OutputDebug, % "-- Get_Password()"

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
;endregion
; ----------------------------------------------------------------------

; ----------------------------------------------------------------------
;region Gui Code
Picker_Build() {
    OutputDebug, % "-- Picker_Build()"
    Gui, Picker:New, -Caption +AlwaysOnTop +Border +HwndhwndPicker +LabelPicker_On, PickerGui
    Gui, +Owner +LabelPicker_On
    Gui, Font, s16, Cascadia Bold
    Gui, Margin, 10, 10
    Gui, Add, Button, Hidden Default gPicker_btnSubmit_OnClick  ; btnSubmit
    Gui, Add, ListView, xm ym w1140 r15 Hdr LV0x8 HwndhwndlvPicker vlvPicker gPicker_lvPicker_OnEvent AltSubmit -Multi +Border Report ; lvPicker
    PostMessage, 0x1047, 0, 1,, ahk_id %hwndlvPicker% ;LVM_SETHOVERTIME txtPicker
    Gui, Add, ListBox, x+m ym w150 hp 0x100 vlbCategories gPicker_lbCategories_OnEvent Sort ; lbCategories
    Gui, Add, Text, vtxtPicker xm w1300 r10 Border
    Gui, Add, Button, xm y+m w100 r1 gPicker_btnQuit_OnClick, Quit ; btnReload
    Gui, Add, Button, x+m wp r1 gPicker_btnReload_OnClick, Reload ; btnQuit
    Gui, Add, Button, x+m wp r1 gPicker_btnEdit_OnClick, Edit ; btnEdit
    Gui, Add, Button, x+m wp r1 gPicker_btnDoc_OnClick, Doc ; btnDoc
    Gui, Add, Button, x+m wp r1 gPicker_btnNote_OnClick, Notepad ; btnNote
    OnMessage(0x001C, "Picker_OnWMACTIVATEAPP") ;WM_ACTIVATEAPP
    Picker_lbCategories_Update()
    Picker_lvPicker_Update()
}

Picker_OnEscape() {
    OutputDebug, % "-- Picker_OnEscape()"
    Gui Picker:Hide
}

Picker_OnWMACTIVATEAPP(activated) {
    OutputDebug, % "-- Picker_OnWMACTIVATEAPP()"
    if (!activated) {
        Gui, Picker:Hide
        return 0
    }
}

Picker_btnSubmit_OnClick() {
    OutputDebug, % "-- Picker_btnSubmit_OnClick()"
    Gui, Picker:Default
    Gui, ListView, lvPicker
    row := LV_GetNext(0)
    if (row > 0) {
        Gui, Picker:Hide
        LV_GetText(cell, row, 2)
        LV_GetText(treated, row, 4)
        if (!treated) {
            SendRaw, %cells%
        } else {
            Send, %cell%
        }
    }
}

Picker_lbCategories_OnEvent() {
    global category
    if (A_GuiEvent = "Normal") {
        GuiControlGet, category,, lbCategories
        Picker_lvPicker_Update()
    }
}

Picker_lbCategories_Update() {
    ; Setup categories
    categories := "*|"
    Loop, % objCSV.MaxIndex() {
        row := objCSV[A_Index]
        categories := categories . "|" . row.Category
    }
    Sort, categories, U D|
    GuiControl, Text, lbCategories, %categories%
}

Picker_lvPicker_OnEvent() {
    OutputDebug, % "-- Picker_lvPicker_OnEvent()"
    Gui, Picker:Default
    Gui, ListView, lvPicker
    LV_GetText(cell, A_EventInfo, 2)
    LV_GetText(treated, A_EventInfo, 4)
    if (A_GuiEvent == "Normal") {
        Gui, Picker:Hide
        if (!treated) {
            SendRaw, %cell%
        } else {
            Send, %cell%
        }
    } else if (A_GuiEvent == "I") {
        Critical, On
        GuiControl, Text, txtPicker, %cell%
    }
}

Picker_lvPicker_Update() {
    if (category and category != "*") {
        objFiltered := []
        Loop, % objCSV.MaxIndex() {
            if (objCSV[A_Index].Category = category)
                objFiltered.Push(objCSV[A_Index])
        }
    } else {
        objFiltered := objCSV
    }

    ; Fill the ListView
    Gui, Picker:Default
    Gui, ListView, lvPicker
    GuiControl, Hide, lvPicker
    LV_Delete()
    ObjCSV_Collection2ListView(objFiltered, Picker, lvPicker, strFieldOrder := "HotString,Text,Category,Treated")
    LV_ModifyCol(1, AutoHDR)
    LV_ModifyCol(2, 1005)
    LV_ModifyCol(3, 0)
    LV_ModifyCol(4, 0)
    GuiControl, Show, lvPicker
    LV_Modify(20, "+Focus +Select")
}

Picker_btnReload_OnClick() {
    OutputDebug, % "-- Picker_btnReload_OnClick()"
    Reload
}

Picker_btnQuit_OnClick() {
    OutputDebug, % "-- Picker_btnQuit_OnClick()"
    ExitApp, 0
}

Picker_btnEdit_OnClick() {
    OutputDebug, % "-- Picker_btnEdit_OnClick()"
    RunWait %csvFile%
}

Picker_btnDoc_OnClick() {
    OutputDebug, % "-- Picker_btnDoc_OnClick()"
    Run, GeekSquad.ods, D:\francois\Documents
}

Picker_btnNote_OnClick() {
    OutputDebug, % "-- Picker_btnNote_OnClick()"
    Run notepad.exe
}

Picker_Show() {
    OutputDebug, % "-- Picker_Show()"
    static centers
    if !IsObject(centers) {
        Gui, Show, AutoSize Center
        centers := Picker_FindCenters()
    }
    mon := Picker_GetMonitor()
    guiLeft := centers[mon].guiLeft
    guiTop := centers[mon].guiTop
    Gui, Picker:Show, % "x"guiLeft " y"guiTop
    GuiControl, Focus, lvPicker
    LV_Modify(1, "+Focus +Select")
}

Picker_GetMonitor() {
    OutputDebug, % "-- Picker_GetMonitor()"
    CoordMode, Mouse, Screen
    MouseGetPos, mouseX, mouseY
    SysGet, monCount, MonitorCount
    Loop % monCount {
        SysGet, mon, Monitor, %A_Index%
        if (mouseX >= monLeft && mouseX <= monRight && mouseY >= monTop && mouseY <= monBottom) {
            mon := A_Index
            break
        }
    }
    return %mon%
}

Picker_FindCenters() {
    OutputDebug, % "-- Picker_FindCenters()"
    centers := []
    WinGetPos,,, guiWidth, guiHeight, ahk_id %hwndPicker%
    SysGet, monCount, MonitorCount
    Loop % monCount {
        SysGet, mon, Monitor, %A_Index%
        guiLeft := Ceil(monLeft + (monRight - monLeft - guiWidth) / 2)
        guiTop := Ceil(monTop + (monBottom - monTop - guiHeight) / 2)
        centers.Push({"guiLeft": guiLeft, "guiTop": guiTop})
    }
    return centers
}
;endregion
; ----------------------------------------------------------------------
