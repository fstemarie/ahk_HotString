
; ----------------------------------------------------------------------------

#include <AnimateWindow>
#include <AutoXYWH>

global PICKER_HWND
, PICKER_TABS
, PICKER_LVPICKER
, PICKER_LVPICKER_HWND
, PICKER_LBCATEGORIES
, PICKER_BTNDOC
, PICKER_BTNEDIT
, PICKER_BTNRELOAD
, PICKER_BTNQUIT
, PICKER_BTNNEW
, PICKER_BTNDELETE
, PICKER_BTNSAVE
, PICKER_TVNOTES
, PICKER_EDTNOTE
, WM_ACTIVATEAPP := 0x001C
, LVM_SETHOVERTIME := 0x1047
, LVS_EX_HEADERDRAGDROP := 0x10
, LVS_EX_TRACKSELECT := 0x8

hsCol := ""
category := ""
categories := ""

Picker_Gui_Build() {
    OutputDebug, % "-- Picker_Build() `n"
    global category, PICKER_LBCATEGORIES
    Gui, Picker:New, +Owner +Resize +AlwaysOnTop +MinSize628x150 +HwndPICKER_HWND
    +LabelPicker_On, HotStrings
    Gui, Color, BDC3CB
    Gui, Font, s16, Bold
    Gui, Margin, 5, 5
    Gui, Add, Tab3, +vPICKER_TABS x0 y0 w1000 h600, Picker|Notes

    Gui, Tab, 1
    Gui, Add, ListView, w800 h505 +AltSubmit -Multi +Grid -Border
        +vPICKER_LVPICKER +HwndPICKER_LVPICKER_HWND +gPicker_lvPicker_OnEvent
        +LV%LVS_EX_TRACKSELECT% +LV%LVS_EX_HEADERDRAGDROP% Section
    PostMessage, %LVM_SETHOVERTIME%, 0, 1,, ahk_id %PICKER_LVPICKER_HWND%
    LV_InsertCol(1, 0, "Treated")
    LV_InsertCol(2, 150, "Trigger")
    LV_InsertCol(3, 20000, "Replacement")
    Gui, Add, ListBox, ys w180 hp 0x100 -Border Sort
        +vPICKER_LBCATEGORIES +gPicker_lbCategories_OnEvent
    Gui, Add, Button, xs w150 h45 +vPICKER_BTNDOC +gPicker_btnDoc_OnClick Section, Edit &Doc
    Gui, Add, Button, ys wp hp +vPICKER_BTNEDIT +gPicker_btnEdit_OnClick, &Text Editor
    Gui, Add, Button, ys wp hp +vPICKER_BTNRELOAD +gPicker_btnReload_OnClick, &Reload
    Gui, Add, Button, ys wp hp +vPICKER_BTNQUIT +gPicker_btnQuit_OnClick, &Quit
    Gui, Add, Button, Hidden Default gPicker_btnSubmit_OnClick

    Gui, Tab, 2
    Gui, Add, TreeView, w490 h505 Section +vPICKER_TVNOTES +gPicker_tvNotes_OnEvent
    Gui, Add, Edit, ys w490 hp +vPICKER_EDTNOTE
    Gui, Add, Button, xs w150 h45 +vPICKER_BTNNEW +gPicker_btnNew_OnClick Section, &New
    Gui, Add, Button, ys wp hp +vPICKER_BTNDELETE +gPicker_btnDelete_OnClick, &Delete
    Gui, Add, Button, ys wp hp +vPICKER_BTNSAVE +gPicker_btnSave_OnClick, &Save
    Gui, Show, w1000 h600 Hide
    AutoXYWH("reset")
    OnMessage(WM_ACTIVATEAPP, "Picker_OnWMACTIVATEAPP")
    category := config.defaultCategory?config.defaultCategory:"*"
    Picker_lbCategories_Update()
}

Picker_Gui_Show() {
    OutputDebug, % "-- Picker_Show() `n"
    global category
    Gui Picker:Default
    Gui Picker:+LastFound
    ; Select the default category if there is one
    if config.stickyDefault and config.defaultCategory {
        category := config.defaultCategory
        GuiControl, ChooseString, PICKER_LBCATEGORIES, %category%
    }
    Picker_lvPicker_Update()

    ; Places the GUI Window in the center of the screen
    WinGetPos,,, W, H
    mon := Picker_Get_Monitor()
    ctr := Picker_Find_Center(mon, W, H)
    Gui, Picker:Show, % "x"ctr.guiLeft " y"ctr.guiTop " hide"
    AnimateWindow(PICKER_HWND, 125, AW_ACTIVATE + AW_BLEND)
    WinActivate
    GuiControl, Focus, PICKER_LVPICKER
}

Picker_Load_HotStrings(objCSV) {
    global hsCol, categories

    if !objCSV
        return
    if objCSV.Count() = 0
        return

    hsCol := objCSV
    Loop % hsCol.Count() {
        category := hsCol[A_Index]["Category"]
        ; Gather all the categories
        categories .= category . "|"
        ; Find the default category if there is one
        if SubStr(cat, 1, 1) = "@"
            config.defaultCategory := category
    }
    Sort, categories, U D|
    categories := "*|" . categories
    Picker_lbCategories_Update()
}

Picker_Get_Monitor() {
    OutputDebug, % "-- Picker_GetMonitor() `n"
    CoordMode, Mouse, Screen
    MouseGetPos, mouseX, mouseY
    SysGet, monCount, MonitorCount
    mon := 1
    Loop % monCount {
        SysGet, mon, Monitor, %A_Index%
        if mouseX between %monLeft% and %monRight%
            if mouseY between %monTop% and %monBottom%
            mon := A_Index
    }
    return mon
}

Picker_Find_Center(mon, W, H) {
    OutputDebug, % "-- Picker_FindCenter() `n"
    SysGet, mon, Monitor, %mon%
    guiLeft := Ceil(monLeft + (monRight - monLeft - W) / 2),
    guiTop := Ceil(monTop + (monBottom - monTop - H) / 2)
    return {"guiLeft": guiLeft, "guiTop": guiTop}
}

Picker_OnEscape() {
    OutputDebug, % "-- Picker_OnEscape() `n"
    AnimateWindow(PICKER_HWND, 125, AW_HIDE + AW_BLEND)
}

Picker_OnSize() {
    OutputDebug, % "-- Picker_OnSize() `n"
    if (A_EventInfo = 1)
        return
    AutoXYWH("wh", "PICKER_TABS", "PICKER_LVPICKER")
    AutoXYWH("xh", "PICKER_LBCATEGORIES")
    AutoXYWH("w0.5 h", "PICKER_TVNOTES")
    AutoXYWH("w0.5 x0.5 h", "PICKER_EDTNOTE")
    GuiControlGet, pos, Pos, PICKER_LVPICKER
    GuiControl, Move, PICKER_BTNDOC, % "y"posH+10
    GuiControl, Move, PICKER_BTNEDIT, % "y"posH+10
    GuiControl, Move, PICKER_BTNRELOAD, % "y"posH+10
    GuiControl, Move, PICKER_BTNQUIT, % "y"posH+10

    GuiControlGet, pos, Pos, PICKER_TVNOTES
    GuiControl, Move, PICKER_BTNNEW, % "y"posH+10
    GuiControl, Move, PICKER_BTNDELETE, % "y"posH+10
    GuiControl, Move, PICKER_BTNSAVE, % "y"posH+10
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
    global category
    if (A_GuiEvent = "Normal") {
        GuiControlGet, category,, PICKER_LBCATEGORIES
        Picker_lvPicker_Update()
    }
}

Picker_lbCategories_Update() {
    OutputDebug, % "-- Picker_lbCategories_Update() `n"
    global category, categories
    GuiControl, Text, PICKER_LBCATEGORIES, %categories%
    GuiControl, ChooseString, PICKER_LBCATEGORIES, %category%
}

Picker_lvPicker_OnEvent() {
    OutputDebug, % "-- Picker_lvPicker_OnEvent() `n"
    global Picker_LVPICKER
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
    }
}

Picker_lvPicker_Update() {
    OutputDebug, % "-- Picker_lvPicker_Update() `n"
    global hsCol, category
    if !hsCol return
        ; Filter the Data
    Gui, ListView, PICKER_LVPICKER
    LV_Delete()
    ; Fill the ListView
    Critical, On
    GuiControl, -Redraw, PICKER_LVPICKER
    loop, % hsCol.Length()
    {
        hs := hsCol[A_Index]
        if (category != "*" and hs["Category"] != category)
            continue
        LV_Add("", hs["Treated"], hs["Trigger"], hs["Replacement"])
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

Picker_btnDoc_OnClick() {
    OutputDebug, % "-- Picker_btnDoc_OnClick() `n"
    if config.document
        Run, % config.document
}

Picker_btnEdit_OnClick() {
    OutputDebug, % "-- Picker_btnEdit_OnClick() `n"
    Run, notepad.exe
}

Picker_btnNew_OnClick() {

}

Picker_btnDelete_OnClick() {

}

Picker_btnSave_OnClick() {

}
