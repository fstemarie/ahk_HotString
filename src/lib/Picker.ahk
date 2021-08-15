
; ----------------------------------------------------------------------------
; Picker Gui Code
global lvPicker
global txtPicker
global pickerHwnd
global lvPickerHwnd
global lbCategories
global centers

if (A_ScriptName = "Picker.ahk")
    ExitApp 1

Picker_Build() {
    OutputDebug, % "-- Picker_Build()"
    Gui, Picker:New, +Owner +Border +HwndpickerHwnd, PickerGui
    Gui, +LabelPicker_On -Caption ; +AlwaysOnTop
    Gui, Font, s16, Cascadia Bold
    Gui, Margin, 10, 10
    Gui, Add, Button, Hidden Default gPicker_btnSubmit_OnClick ;btnSubmit
    Gui, Add, ListView, xm ym w1140 r15 LV0x8 vlvPicker HwndlvPickerHwnd
    GuiControl, +gPicker_lvPicker_OnEvent +Hdr, lvPicker
    GuiControl, +AltSubmit -Multi +Grid +Border Report, lvPicker ;lvPicker
    PostMessage, 0x1047, 0, 1,, ahk_id %lvPickerHwnd% ;LVM_SETHOVERTIME
    Gui, Add, ListBox, x+m ym w150 hp 0x100 vlbCategories
    GuiControl, +gPicker_lbCategories_OnEvent Sort, lbCategories ;lbCategories
    Gui, Add, Text, vtxtPicker xm w1300 r10 Border
    Gui, Add, Button, xm y+m w120 r1 gPicker_btnQuit_OnClick, &Quit ;btnReload
    Gui, Add, Button, x+m wp r1 gPicker_btnReload_OnClick, &Reload ;btnQuit
    Gui, Add, Button, x+m wp r1 gPicker_btnCsvEdit_OnClick, Edit &CSV ;btnCsvEdit
    Gui, Add, Button, x+m wp r1 gPicker_btnDoc_OnClick, Edit &Doc ;btnDoc
    Gui, Add, Button, x+m wp r1 gPicker_btnEdit_OnClick, &Text Editor ;btnEdit
    Gui, Add, Button, x+m wp r1 gPicker_btnHelp_OnClick, &Help ;btnHelp
    OnMessage(0x001C, "Picker_OnWMACTIVATEAPP") ;WM_ACTIVATEAPP
    Picker_lbCategories_Update()
}

Picker_OnEscape() {
    OutputDebug, % "-- Picker_OnEscape()"
    Gui Picker:Hide
}

Picker_OnSize() {
}

Picker_OnWMACTIVATEAPP(wParam, lParam, msg, hwnd) {
    if (hwnd = pickerHwnd) {
        OutputDebug, % "-- Picker_OnWMACTIVATEAPP()"
        if (!wParam) {
            OutputDebug, % A_Tab . "Window Deactivated"
            Gui, Picker:Hide
            return 0
        } else {
            OutputDebug, % A_Tab . "Window Activated"
        }
    }
}

Picker_btnSubmit_OnClick() {
    OutputDebug, % "-- Picker_btnSubmit_OnClick()"
    GuiControlGet, focused, Picker:FocusV
    if ("lvPicker" = focused) {
        Gui, Picker:Default
        Gui, ListView, lvPicker
        row := LV_GetNext(1, F)
        LV_GetText(treated, row, 1)
        LV_GetText(cell, row, 3)
        Gui, Picker:Hide
        if (!treated) {
            SendRaw, %cell%
        } else {
            Send, %cell%
        }
    }
}

Picker_lbCategories_OnEvent() {
    OutputDebug, % "-- Picker_lbCategories_OnEvent()"
    if (A_GuiEvent = "Normal") {
        GuiControlGet, category,, lbCategories
        Picker_lvPicker_Update()
    }
}

Picker_lbCategories_Update() {
    OutputDebug, % "-- Picker_lbCategories_Update()"
    ; Setup categories
    GuiControl, Text, lbCategories, %categories%
}

Picker_lvPicker_OnEvent() {
    OutputDebug, % "-- Picker_lvPicker_OnEvent()"
    Gui, Picker:Default
    Gui, ListView, lvPicker
    LV_GetText(cell, A_EventInfo, 3)
    LV_GetText(treated, A_EventInfo, 1)
    if (A_GuiEvent == "Normal") {
        Gui, Picker:Hide
        if (!treated) {
            SendRaw, %cell%
        } else {
            Send, %cell%
        }
    } else if (A_GuiEvent == "I") {
        GuiControl, Text, txtPicker, %cell%
    }
}

Picker_lvPicker_Update() {
    OutputDebug, % "-- Picker_lvPicker_Update()"
    Critical, On
    ; Filter the Data
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
    Gui, Picker:ListView, lvPicker
    GuiControl, -Redraw, lvPicker
    LV_Delete()
    Func("ObjCSV_Collection2Listview").call(objFiltered, Picker
    , lvPicker, strFieldOrder := "Treated,Trigger,Replacement")

    ;Resize the columns
    LV_ModifyCol(1, 0)
    LV_ModifyCol(2, AutoHdr)
    SendMessage, 0x1000+29, 1, 0,, ahk_id %lvPickerHwnd%
    colW := ErrorLevel
    GuiControlGet, pos, Pos, lvPicker
    LV_ModifyCol(3, (posW - colW - 4))
    GuiControl, +Redraw, lvPicker
    LV_Modify(1, "+Focus +Select")
    Critical, Off
}

Picker_btnReload_OnClick() {
    OutputDebug, % "-- Picker_btnReload_OnClick()"
    Reload
}

Picker_btnQuit_OnClick() {
    OutputDebug, % "-- Picker_btnQuit_OnClick()"
    ExitApp, 0
}

Picker_btnCsvEdit_OnClick() {
    OutputDebug, % "-- Picker_btnCsvEdit_OnClick()"
    if config.csvEditor and config.csvFile
        Run, % config.csvEditor . " " . config.csvFile
}

Picker_btnDoc_OnClick() {
    OutputDebug, % "-- Picker_btnDoc_OnClick()"
    if config.document
        Run, % config.document
}

Picker_btnEdit_OnClick() {
    OutputDebug, % "-- Picker_btnEdit_OnClick()"
    if config.editor
        Run, % config.editor
}

Picker_btnHelp_OnClick() {
    OutputDebug, % "-- Picker_btnHelp_OnClick()"
    Run, % "https://www.autohotkey.com/docs/KeyList.htm"
}

Picker_Show() {
    OutputDebug, % "-- Picker_Show()"

    ; Places the GUI Window in the center of the screen
    static centers
    if !centers {
        Gui, Picker:Show, AutoSize Center
        centers := Picker_FindCenters()
    }
    mon := Picker_GetMonitor()
    guiLeft := centers[mon].guiLeft
    guiTop := centers[mon].guiTop
    Gui, Picker:Show, % "x"guiLeft " y"guiTop
    GuiControl, Focus, lvPicker
    LV_Modify(1, "+Focus +Select")

    ; Select the default category if there is one
    if config.stickyDefault and config.defaultCategory {
        category := config.defaultCategory
    }
    GuiControl, Picker:Choose, lbCategories, %category%
    Picker_lvPicker_Update()
}

Picker_GetMonitor() {
    OutputDebug, % "-- Picker_GetMonitor()"
    CoordMode, Mouse, Screen
    MouseGetPos, mouseX, mouseY
    SysGet, monCount, MonitorCount
    Loop % monCount {
        SysGet, mon, Monitor, %A_Index%
        if (mouseX >= monLeft && mouseX <= monRight
        && mouseY >= monTop && mouseY <= monBottom) {
            mon := A_Index
            break
        }
    }
    return %mon%
}

Picker_FindCenters() {
    OutputDebug, % "-- Picker_FindCenters()"
    centers := []
    WinGetPos,,, guiWidth, guiHeight, ahk_id %pickerHwnd%
    SysGet, monCount, MonitorCount
    Loop % monCount {
        SysGet, mon, Monitor, %A_Index%
        guiLeft := Ceil(monLeft + (monRight - monLeft - guiWidth) / 2)
        guiTop := Ceil(monTop + (monBottom - monTop - guiHeight) / 2)
        centers.Push({"guiLeft": guiLeft, "guiTop": guiTop})
    }
    return centers
}
