; LVM_SETHOVERTIME   := 0x1047 ; (LVM_FIRST + 71)
; LVN_HOTTRACK       := -121 ; (LVN_FIRST - 21)
; LVS_EX_TRACKSELECT := 0x00000008
; WM_NOTIFY          := 0x004E
; WM_ACTIVATEAPP     := 0x001C

global lvPicker
global txtPicker
global hwndPicker

Picker_Build() {
    OutputDebug, % "-- Picker_Build()"
    Gui, Picker:New, -Caption +AlwaysOnTop +Border +HwndhwndPicker +LabelPicker_On, PickerGui
    Gui, +Owner +LabelPicker_On
    Gui, Font, s16, Cascadia Bold
    Gui, Margin, 10, 10
    Gui, Add, Button, Hidden Default gPicker_btnSubmit_OnClick  ; btnSubmit
    Gui, Add, ListView, xm ym w1310 r15 Hdr LV0x8 HwndhwndlvPicker vlvPicker gPicker_lvPicker_OnEvent AltSubmit -Multi +Border Report ; lvPicker
    PostMessage, 0x1047, 0, 1,, ahk_id %hwndlvPicker% ;LVM_SETHOVERTIME txtPicker
    Gui, Add, Text, vtxtPicker w1310 r10 Border
    Gui, Add, Button, xm y+m w100 r1 gPicker_btnQuit_OnClick, Quit ; btnReload
    Gui, Add, Button, x+m wp r1 gPicker_btnReload_OnClick, Reload ; btnQuit
    Gui, Add, Button, x+m wp r1 gPicker_btnEdit_OnClick, Edit ; btnEdit
    Gui, Add, Button, x+m wp r1 gPicker_btnDoc_OnClick, Doc ; btnDoc
    Gui, Add, Button, x+m wp r1 gPicker_btnNote_OnClick, Notepad ; btnNote
    OnMessage(0x001C, "Picker_OnWMACTIVATEAPP") ;WM_ACTIVATEAPP
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
