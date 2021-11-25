
; ----------------------------------------------------------------------------

#include <AnimateWindow>

global PICKER_LVPICKER
, PICKER_HWND
, PICKER_TXTPICKER
, PICKER_LVPICKER_HWND
, PICKER_LBCATEGORIES
, PICKER_WIDTH := 1024
, PICKER_HEIGHT := 568
, PICKER_MARGINX := 5
, PICKER_MARGINY := 5
, WM_ACTIVATEAPP := 0x001C
, LVM_SETHOVERTIME := 0x1047
, LVS_EX_HEADERDRAGDROP := 0x10
, LVS_EX_TRACKSELECT := 0x8

Picker_Build() {
    OutputDebug, % "-- Picker_Build() `n"

    global PICKER_WIDTH := 1024
    ,PICKER_HEIGHT := 568

    Gui, Picker:New, +Owner -Border +HwndPICKER_HWND
    +LabelPicker_On -Caption +AlwaysOnTop
    ; Gui, Color, 907FA4, A58FAA
    ; Gui, Color, 363062, D8B9C3
    Gui, Color, BDC3CB
    Gui, Font, s16, Bold
    Gui, Margin, %PICKER_MARGINX%, %PICKER_MARGINY%
    Gui, Add, Button, x0 y0 Hidden Default gPicker_btnSubmit_OnClick
    Gui, Add, ListView, xm ym w1000 h412 +Hdr +AltSubmit -Multi +Grid
    -Border +Report +vPICKER_LVPICKER +HwndPICKER_LVPICKER_HWND
    +gPicker_lvPicker_OnEvent +NoSort +NoSortHdr
    +LV%LVS_EX_TRACKSELECT% +LV%LVS_EX_HEADERDRAGDROP%
    PostMessage, %LVM_SETHOVERTIME%, 0, 1,, ahk_id %PICKER_LVPICKER_HWND%
    LV_InsertCol(1, 0, "Treated")
    LV_InsertCol(2, 150, "Trigger")
    LV_InsertCol(3, 843, "Replacement")
    Gui, Add, ListBox, x+m ym w150 hp 0x100 +vPICKER_LBCATEGORIES
    +gPicker_lbCategories_OnEvent -Border Sort
    Gui, Add, Text, x10 y+10 w1000 h130 +vPICKER_TXTPICKER -Border
    Gui, Add, Button, xm y+m w150 h40 gPicker_btnCsvEdit_OnClick, Edit &CSV
    Gui, Add, Button, x+m yp wp hp gPicker_btnDoc_OnClick, Edit &Doc
    Gui, Add, Button, x+m yp wp hp gPicker_btnEdit_OnClick, &Text Editor
    Gui, Add, Button, x+m yp wp hp gPicker_btnReload_OnClick, &Reload
    Gui, Add, Button, x+m yp wp hp gPicker_btnQuit_OnClick, &Quit
    OnMessage(WM_ACTIVATEAPP, "Picker_OnWMACTIVATEAPP")
    Picker_lbCategories_Update()
    Picker_lvPicker_Update()
}

Picker_OnEscape() {
    OutputDebug, % "-- Picker_OnEscape() `n"
    AnimateWindow(PICKER_HWND, 125, AW_HIDE + AW_BLEND)
}

Picker_OnSize() {
    ; OutputDebug, % "-- Picker_OnSize() `n"
    ; msgbox % A_GuiWidth . "`n" . A_GuiHeight
}

Picker_OnWMACTIVATEAPP(wParam, lParam, msg, hwnd) {
    if (hwnd = PICKER_HWND) {
        OutputDebug, % "-- Picker_OnWMACTIVATEAPP() `n"
        if (!wParam) {
            OutputDebug, % A_Tab . "Window Deactivated `n"
            Gui, Picker:Hide
            return 0
        } else {
            OutputDebug, % A_Tab . "Window Activated `n"
        }
    }
}

Picker_btnSubmit_OnClick() {
    OutputDebug, % "-- Picker_btnSubmit_OnClick() `n"
    GuiControlGet, focused, Picker:FocusV
    if ("PICKER_LVPICKER" = focused) {
        Gui, Picker:Default
        Gui, ListView, PICKER_LVPICKER
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
    OutputDebug, % "-- Picker_lbCategories_OnEvent() `n"
    if (A_GuiEvent = "Normal") {
        GuiControlGet, category,, PICKER_LBCATEGORIES
        Picker_lvPicker_Update()
    }
}

Picker_lbCategories_Update() {
    OutputDebug, % "-- Picker_lbCategories_Update() `n"
    GuiControl, Text, PICKER_LBCATEGORIES, %categories%
}

Picker_lvPicker_OnEvent() {
    OutputDebug, % "-- Picker_lvPicker_OnEvent() `n"
    Gui, Picker:Default
    Gui, ListView, PICKER_LVPICKER
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
        GuiControl, Text, PICKER_TXTPICKER, %cell%
    }
}

Picker_lvPicker_Update() {
    OutputDebug, % "-- Picker_lvPicker_Update() `n"
    ; Filter the Data

    Gui, Picker:Default
    Gui, ListView, PICKER_LVPICKER
    GuiControl, -Redraw, PICKER_LVPICKER
    LV_Delete()
    ; Fill the ListView
    Critical, On
    loop, % objCSV.MaxIndex()
    {
        row := objCSV[A_Index]
        filtered := false
        if (category and category != "*" and row.Category != category)
            filtered := true
        if (!filtered)
            LV_Add("", row["Treated"], row["Trigger"], row["Replacement"])
    }
    GuiControl, +Redraw, PICKER_LVPICKER
    Critical, Off
}

Picker_btnReload_OnClick() {
    OutputDebug, % "-- Picker_btnReload_OnClick() `n"
    Reload
}

Picker_btnQuit_OnClick() {
    OutputDebug, % "-- Picker_btnQuit_OnClick() `n"
    ExitApp, 0
}

Picker_btnCsvEdit_OnClick() {
    OutputDebug, % "-- Picker_btnCsvEdit_OnClick() `n"
    if config.csvEditor and config.csvFile
        Run, % config.csvEditor . " " . config.csvFile
}

Picker_btnDoc_OnClick() {
    OutputDebug, % "-- Picker_btnDoc_OnClick() `n"
    if config.document
        Run, % config.document
}

Picker_btnEdit_OnClick() {
    OutputDebug, % "-- Picker_btnEdit_OnClick() `n"
    if config.editor
        Run, % config.editor
}

Picker_btnHelp_OnClick() {
    OutputDebug, % "-- Picker_btnHelp_OnClick() `n"
    Run, % "https://www.autohotkey.com/docs/KeyList.htm"
}

Picker_Show() {
    OutputDebug, % "-- Picker_Show() `n"
    static centers

    ; Select the default category if there is one
    if config.stickyDefault and config.defaultCategory
        category := config.defaultCategory
    Picker_lvPicker_Update()
    GuiControl, Choose, PICKER_LBCATEGORIES, %category%
    LV_Modify(1, "+Focus +Select")
    GuiControl, Focus, PICKER_LVPICKER

    ; Places the GUI Window in the center of the screen
    if (!centers)
        centers := Picker_FindCenters()
    mon := Picker_GetMonitor()
    guiLeft := centers[mon].guiLeft
    guiTop := centers[mon].guiTop
    Gui, Picker:Show, % "x"guiLeft " y"guiTop " hide"
    AnimateWindow(PICKER_HWND, 125, AW_ACTIVATE + AW_BLEND)
}

Picker_GetMonitor() {
    OutputDebug, % "-- Picker_GetMonitor() `n"
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
    OutputDebug, % "-- Picker_FindCenters() `n"
    global PICKER_WIDTH, PICKER_HEIGHT
    centers := []
    SysGet, monCount, MonitorCount
    Loop % monCount {
        SysGet, mon, Monitor, %A_Index%
        guiLeft := Ceil(monLeft + (monRight - monLeft - PICKER_WIDTH) / 2)
        guiTop := Ceil(monTop + (monBottom - monTop - PICKER_HEIGHT) / 2)
        centers.Push({"guiLeft": guiLeft, "guiTop": guiTop})
    }
    return centers
}
