
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
, PICKER_IMGLIST
, PICKER_EDTNOTE
, WM_ACTIVATEAPP := 0x001C
, LVM_SETHOVERTIME := 0x1047
, LVS_EX_HEADERDRAGDROP := 0x10
, LVS_EX_TRACKSELECT := 0x8

hsCol :=
notesCol :=
category :=
categories :=
currentNote :=

Picker_Gui_Build()
{
    OutputDebug, % "-- Picker_Build() `n"
    global category
    totalWidth := 1000
    totalHeight := 600
   
    PICKER_IMGLIST := IL_Create(2)
    IL_Add(PICKER_IMGLIST, "shell32.dll", 2)
    IL_Add(PICKER_IMGLIST, "shell32.dll", 4)

    Gui, Picker:New, +Owner +Resize +MinSize628x150 +HwndPICKER_HWND
    +LabelPicker_On, HotStrings
    Gui, Color, BDC3CB
    Gui, Font, s16, Bold
    Gui, Margin, 5, 5
    Gui, Add, Tab3, +vPICKER_TABS x0 y0 w1000 h600, Picker|Notes

    Gui, Tab, 1
    w := (totalWidth - 20) * 0.8
    h := (totalHeight - 51) * 0.92
    Gui, Add, ListView, w%w% h%h% +AltSubmit -Multi +Grid -Border
        +vPICKER_LVPICKER +HwndPICKER_LVPICKER_HWND +gPicker_lvPicker_OnEvent
        +LV%LVS_EX_TRACKSELECT% +LV%LVS_EX_HEADERDRAGDROP% Section
    PostMessage, %LVM_SETHOVERTIME%, 0, 1,, ahk_id %PICKER_LVPICKER_HWND%
    LV_InsertCol(1, 0, "Treated")
    LV_InsertCol(2, 150, "Trigger")
    LV_InsertCol(3, 20000, "Replacement")
    w := (totalWidth - 20) * 0.2
    h := (totalHeight - 51) * 0.08
    Gui, Add, ListBox, ys w%w% hp 0x100 -Border Sort
        +vPICKER_LBCATEGORIES +gPicker_lbCategories_OnEvent
    Gui, Add, Button, xs w150 h%h% +vPICKER_BTNDOC +gPicker_btnDoc_OnClick Section, Edit &Doc
    Gui, Add, Button, ys wp hp +vPICKER_BTNEDIT +gPicker_btnEdit_OnClick, &Text Editor
    Gui, Add, Button, ys wp hp +vPICKER_BTNRELOAD +gPicker_btnReload_OnClick, &Reload
    Gui, Add, Button, ys wp hp +vPICKER_BTNQUIT +gPicker_btnQuit_OnClick, &Quit
    Gui, Add, Button, Hidden Default gPicker_btnSubmit_OnClick

    Gui, Tab, 2
    w := (totalWidth - 20) * 0.35
    h := (totalHeight - 51) * 0.92
    Gui, Add, TreeView, w%w% h%h% Section +vPICKER_TVNOTES
        +gPicker_tvNotes_OnEvent +ImageList%PICKER_IMGLIST%
    w := (totalWidth - 20) * 0.65
    h := (totalHeight - 51) * 0.08
    Gui, Add, Edit, ys w%w% hp +vPICKER_EDTNOTE +gPicker_edtNote_OnChange
    Gui, Add, Button, xs w150 h45 +vPICKER_BTNNEW +gPicker_btnNew_OnClick Section, &New
    Gui, Add, Button, ys wp hp +vPICKER_BTNDELETE +gPicker_btnDelete_OnClick, &Delete
    Gui, Add, Button, ys wp hp Disabled +vPICKER_BTNSAVE +gPicker_btnSave_OnClick, &Save
    Gui, Show, w%totalWidth% h%totalHeight% Hide
    AutoXYWH("reset")
    OnMessage(WM_ACTIVATEAPP, "Picker_OnWMACTIVATEAPP")
    category := config.defaultCategory?config.defaultCategory:"*"
    Picker_lbCategories_Update()
    Picker_tvNotes_Update()
}

Picker_Gui_Show()
{
    OutputDebug, % "-- Picker_Show() `n"
    global category
    Gui Picker:Default
    Gui Picker:+LastFound
    ; Select the default category If there is one
    If config.stickyDefault and config.defaultCategory
    {
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

Picker_Load_HotStrings(objCSV)
{
    global hsCol, categories

    If !objCSV or objCSV.Count() = 0
        Return
    hsCol := objCSV
    Loop % hsCol.Count()
    {
        category := hsCol[A_Index]["Category"]
        ; Gather all the categories
        categories .= category . "|"
        ; Find the default category If there is one
        If SubStr(cat, 1, 1) = "@"
            config.defaultCategory := category
    }
    Sort, categories, U D|
    categories := "*|" . categories
    Picker_lbCategories_Update()
}

Picker_Get_Monitor()
{
    OutputDebug, % "-- Picker_GetMonitor() `n"
    CoordMode, Mouse, Screen
    MouseGetPos, mouseX, mouseY
    SysGet, monCount, MonitorCount
    mon := 1
    Loop % monCount
    {
        SysGet, mon, Monitor, %A_Index%
        If mouseX between %monLeft% and %monRight%
            If mouseY between %monTop% and %monBottom%
            mon := A_Index
    }
    Return mon
}

Picker_Find_Center(mon, W, H)
{
    OutputDebug, % "-- Picker_FindCenter() `n"
    SysGet, mon, Monitor, %mon%
    guiLeft := Ceil(monLeft + (monRight - monLeft - W) / 2),
    guiTop := Ceil(monTop + (monBottom - monTop - H) / 2)
    Return {"guiLeft": guiLeft, "guiTop": guiTop}
}

Picker_OnEscape()
{
    OutputDebug, % "-- Picker_OnEscape() `n"
    AnimateWindow(PICKER_HWND, 125, AW_HIDE + AW_BLEND)
}

Picker_OnSize()
{
    OutputDebug, % "-- Picker_OnSize() `n"
    If (A_EventInfo = 1)
        Return
    AutoXYWH("wh", "PICKER_TABS", "PICKER_LVPICKER")
    AutoXYWH("xh", "PICKER_LBCATEGORIES")
    AutoXYWH("w0.3 h", "PICKER_TVNOTES")
    AutoXYWH("w0.7 x0.3 h", "PICKER_EDTNOTE")
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

Picker_OnWMACTIVATEAPP(wParam, lParam, msg, hwnd)
{
    If (hwnd = PICKER_HWND)
    {
        OutputDebug, % "-- Picker_OnWMACTIVATEAPP() `n"
        If (!wParam)
        {
            OutputDebug, % A_Tab . "Window Deactivated `n"
            Gui, Picker:Hide
            Return 0
        }
        Else
        {
            OutputDebug, % A_Tab . "Window Activated `n"
        }
    }
}

Picker_lbCategories_OnEvent()
{
    OutputDebug, % "-- Picker_lbCategories_OnEvent() `n"
    global category
    If (A_GuiEvent = "Normal")
    {
        GuiControlGet, category,, PICKER_LBCATEGORIES
        Picker_lvPicker_Update()
    }
}

Picker_lbCategories_Update()
{
    OutputDebug, % "-- Picker_lbCategories_Update() `n"
    global category, categories
    GuiControl, Text, PICKER_LBCATEGORIES, %categories%
    GuiControl, ChooseString, PICKER_LBCATEGORIES, %category%
}

Picker_lvPicker_OnEvent()
{
    OutputDebug, % "-- Picker_lvPicker_OnEvent() `n"
    global Picker_LVPICKER
    Gui, ListView, PICKER_LVPICKER
    LV_GetText(cell, A_EventInfo, 3)
    LV_GetText(treated, A_EventInfo, 1)
    If (A_GuiEvent == "Normal")
    {
        Gui, Picker:Hide
        If (!treated)
        {
            SendRaw, %cell%
        }
        Else
        {
            Send, %cell%
        }
    }
}

Picker_lvPicker_Update()
{
    OutputDebug, % "-- Picker_lvPicker_Update() `n"
    global hsCol, category
    If !hsCol Return
        ; Filter the Data
    Gui, ListView, PICKER_LVPICKER
    LV_Delete()
    ; Fill the ListView
    Critical, On
    GuiControl, -Redraw, PICKER_LVPICKER
    loop, % hsCol.Length()
    {
        hs := hsCol[A_Index]
        If (category != "*" and hs["Category"] != category)
            continue
        LV_Add("", hs["Treated"], hs["Trigger"], hs["Replacement"])
    }
    GuiControl, +Redraw, PICKER_LVPICKER
    Critical, Off
}

Picker_btnReload_OnClick()
{
    OutputDebug, % "-- Picker_btnReload_OnClick() `n"
    Reload
}

Picker_btnQuit_OnClick()
{
    OutputDebug, % "-- Picker_btnQuit_OnClick() `n"
    ExitApp, 0
}

Picker_btnDoc_OnClick()
{
    OutputDebug, % "-- Picker_btnDoc_OnClick() `n"
    If config.document
        Run, % config.document
}

Picker_btnEdit_OnClick()
{
    OutputDebug, % "-- Picker_btnEdit_OnClick() `n"
    Run, notepad.exe
}

Picker_btnSubmit_OnClick()
{
    OutputDebug, % "-- Picker_btnSubmit_OnClick() `n"
    GuiControlGet, focused, Picker:FocusV
    If ("PICKER_LVPICKER" = focused)
    {
        Gui, Picker:Default
        Gui, ListView, PICKER_LVPICKER
        row := LV_GetNext(1, F)
        LV_GetText(treated, row, 1)
        LV_GetText(cell, row, 3)
        Gui, Picker:Hide
        If (!treated)
        {
            SendRaw, %cell%
        }
        Else
        {
            Send, %cell%
        }
    }
}

Picker_tvNotes_OnEvent()
{
    OutputDebug, % "-- Picker_tvNotes_OnEvent() `n"
    global notesCol, currentNote
    Switch A_GuiEvent {
        Case "S":
            If currentNote.Dirty
            {
                message := "You have changes that have not been saved yet. Do you want to save those changes ?"
                MsgBox, 0x2034, Unsaved note, %message%
                IfMsgBox, Yes
                    Picker_edtNote_SaveChanges()
                IfMsgBox, No
                    Picker_edtNote_CancelChanges()
            }
            If notesCol[A_EventInfo]["Directory"]
            {
                currentNote :=
                GuiControl, Text, PICKER_edtNote,
                Return
            }
            Else
            {
                currentNote := notesCol[A_EventInfo]
                file := FileOpen(currentNote.FullPath, "R")
                If !file
                {
                    MsgBox, 0x2010, Error, Error %A_LastError%
                    Return
                }
                content := file.Read()
                file.close()
                GuiControl,, PICKER_EDTNOTE, %content%
                GuiControlGet, content,, PICKER_EDTNOTE
                currentNote.Content := content
            }
    }
}

Picker_tvNotes_Update()
{
    OutputDebug, % "-- Picker_tvNotes_Update() `n"
    oldWD := A_WorkingDir
    notesDir := config.notesDir
    Gui, Picker:+LastFound
    Gui, Treeview, PICKER_TVNOTES
    GuiControl, -Redraw, PICKER_TVNOTES
    Critical, On
    TV_Delete(PICKER_TVNOTES)
    Picker_tvNotes_Recurse(notesDir, 0)
    Critical, Off
    GuiControl, +Redraw, PICKER_TVNOTES
    SetWorkingDir, %oldWD%
}

Picker_tvNotes_Recurse(path, currentID)
{
    global notesCol := notesCol?notesCol:{}
    Loop, Files, %path%\*.*, DF
    {
        If A_LoopFileAttrib contains D
        {
            noteID := TV_Add(A_LoopFileName, currentID, "+Icon2 +Expand")
            Picker_tvNotes_Recurse(A_LoopFileFullPath, noteID)
        }
        Else If A_LoopFileExt != "txt"
        {
            SplitPath A_LoopFileName,,,, fileName
            noteID := TV_Add(fileName, currentID, "+Icon1")
        }
        Else
            Continue
        notesCol[noteID] := {FileName: A_LoopFileName
            , FullPath: A_LoopFileFullPath
            , Attrib: A_LoopFileAttrib
            , Directory: InStr(A_LoopFileAttrib, "D")?True:False
            , Size: A_LoopFileSize}
    }
}

Picker_edtNote_OnChange()
{
    OutputDebug, % "-- Picker_edtNote_OnChanges() `n"
    global currentNote
    GuiControlGet, content,, PICKER_EDTNOTE
    If currentNote.Content != content
    {
        currentNote.Dirty := True
        GuiControl, Enable, PICKER_BTNSAVE
    }
    Else
    {
        currentNote.Dirty := False
        GuiControl, Disable, PICKER_BTNSAVE
    }
}

Picker_edtNote_SaveChanges()
{
    OutputDebug, % "-- Picker_edtNote_SaveChanges() `n"
    global currentNote
    GuiControlGet, content,, PICKER_EDTNOTE
    file := FileOpen(currentNote.FullPath, "W")
    If !file
    {
        MsgBox, 0x2010, Error, Error %A_LastError%
        Return
    }
    file.Write(content)
    file.Close()
    currentNote.Dirty := False
    GuiControl, Disable, PICKER_BTNSAVE
}

Picker_edtNote_CancelChanges()
{
    OutputDebug, % "-- Picker_edtNote_CancelChanges() `n"
    global currentNote
    currentNote.Dirty := False
    GuiControl, Disable, PICKER_BTNSAVE
}

Picker_btnNew_OnClick()
{
    OutputDebug, % "-- Picker_btnNew_OnClick() `n"
}

Picker_btnDelete_OnClick()
{
    OutputDebug, % "-- Picker_btnDelete_OnClick() `n"
}

Picker_btnSave_OnClick()
{
    OutputDebug, % "-- Picker_btnSave_OnClick() `n"
    Picker_edtNote_SaveChanges()

}
