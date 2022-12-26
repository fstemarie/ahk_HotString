
; ----------------------------------------------------------------------------

#include <AnimateWindow>
#include <AutoXYWH>
#include <Note.cls>
#include <Tools>

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
, PICKER_BTNRENAME
, PICKER_BTNSAVE
, PICKER_TVNOTES
, PICKER_IMGLIST
, PICKER_EDTNOTE
, notesCol

notesCol :=
category :=

Picker_Load_HotStrings(objCSV) {
    OutputDebug, % "-- Picker_Load_HotStrings() `n"
    if !objCSV or objCSV.Count() = 0
        return
    loop % objCSV.Count()
    {
        category := objCSV[A_Index]["Category"]
        ; Gather all the categories
        categories .= category . "|"
    }
    Sort, categories, U D|
    categories := "*|" . categories
    Picker_lbCategories_Update(categories)
    Picker_lvPicker_Update(objCSV)
}

Picker_Get_NoteID() {
    OutputDebug, % "-- Picker_Get_NoteID() `n"
    Gui, Picker:Treeview, PICKER_TVNOTES
    return TV_GetSelection()
}

Picker_Gui_Build() {
    OutputDebug, % "-- Picker_Build() `n"
    global category
    totalWidth := 1000
    totalHeight := 600
    WM_ACTIVATEAPP := 0x001C
    LVM_SETHOVERTIME := 0x1047
    LVS_EX_HEADERDRAGDROP := 0x10
    LVS_EX_TRACKSELECT := 0x8

    PICKER_IMGLIST := IL_Create(2)
    IL_Add(PICKER_IMGLIST, "shell32.dll", 2)
    IL_Add(PICKER_IMGLIST, "shell32.dll", 4)

    Gui, Picker:New, +Resize +OwnDialogs +MinSize628x150 +HwndPICKER_HWND
    +LabelPicker_Gui_On, HotStrings
    Gui, Default
    Gui, Color, BDC3CB
    Gui, Font, s16, Bold
    Gui, Margin, 5, 5
    Gui, Add, Tab3, +vPICKER_TABS x0 y0 w1000 h600, Picker|Notes

    Gui, Tab, 1
    w := (totalWidth - 19) * 0.8
    h := (totalHeight - 49) * 0.92
    Gui, Add, ListView, w%w% h%h% +AltSubmit -Multi +Grid -Border
        +vPICKER_LVPICKER +HwndPICKER_LVPICKER_HWND +gPicker_lvPicker_OnEvent
        +LV%LVS_EX_TRACKSELECT% +LV%LVS_EX_HEADERDRAGDROP% Section
    PostMessage, %LVM_SETHOVERTIME%, 0, 1,, ahk_id %PICKER_LVPICKER_HWND%
    LV_InsertCol(1, 0, "Treated")
    LV_InsertCol(2, 150, "Trigger")
    LV_InsertCol(3, 20000, "Replacement")
    w := (totalWidth - 19) * 0.2
    h := (totalHeight - 49) * 0.08
    Gui, Add, ListBox, ys w%w% hp 0x100 -Border Sort
        +vPICKER_LBCATEGORIES +gPicker_lbCategories_OnEvent
    Gui, Add, Button, xs w150 h%h% +vPICKER_BTNDOC +gPicker_btnDoc_OnClick Section, Edit &Doc
    Gui, Add, Button, ys wp hp +vPICKER_BTNEDIT +gPicker_btnEdit_OnClick, &Text Editor
    Gui, Add, Button, ys wp hp +vPICKER_BTNRELOAD +gPicker_btnReload_OnClick, &Reload
    Gui, Add, Button, ys wp hp +vPICKER_BTNQUIT +gPicker_btnQuit_OnClick, &Quit
    Gui, Add, Button, Hidden Default gPicker_btnSubmit_OnClick

    Gui, Tab, 2
    w := (totalWidth - 19) * 0.35
    h := (totalHeight - 49) * 0.92
    Gui, Add, TreeView, w%w% h%h% -ReadOnly +WantF2 Section +vPICKER_TVNOTES
        +gPicker_tvNotes_OnEvent +ImageList%PICKER_IMGLIST%
    w := (totalWidth - 19) * 0.65
    h := (totalHeight - 49) * 0.08
    Gui, Add, Edit, ys w%w% hp +WantTab +vPICKER_EDTNOTE +gPicker_edtNote_OnChange
    Gui, Add, Button, xs w150 h45 +vPICKER_BTNNEW +gPicker_btnNew_OnClick Section, &New
    Gui, Add, Button, ys wp hp +vPICKER_BTNDELETE +gPicker_btnDelete_OnClick, &Delete
    Gui, Add, Button, ys wp hp Disabled +vPICKER_BTNSAVE +gPicker_btnSave_OnClick, &Save
    Gui, Show, w%totalWidth% h%totalHeight% Hide

    Menu, tvNotes_Menu, Add, New Note, Picker_tvNotes_OnMenu
    Menu, tvNotes_Menu, Add, Delete Note, Picker_tvNotes_OnMenu
    Menu, tvNotes_Menu, Add, Rename Note, Picker_tvNotes_OnMenu

    Gui, Show, Hide W%totalWidth% H%totalHeight%
    AutoXYWH("reset")
    OnMessage(WM_ACTIVATEAPP, "Picker_Gui_OnWMACTIVATEAPP")
    category := config.defaultCategory?config.defaultCategory:"*"
    Picker_tvNotes_Update()
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
    mon := Get_CurrentMonitor()
    ctr := Find_Center(mon, W, H)
    Gui, Picker:Show, % "x"ctr.X " y"ctr.Y " hide"
    AnimateWindow(PICKER_HWND, 125, AW_ACTIVATE + AW_BLEND)
    WinActivate
    GuiControl, Focus, PICKER_LVPICKER
}

Picker_Gui_OnContextMenu() {
    if (A_GuiControl = "PICKER_TVNOTES")
        Menu, tvNotes_Menu, Show, %A_GuiX%, %A_GuiY%
}

Picker_Gui_OnEscape() {
    OutputDebug, % "-- Picker_Gui_OnEscape() `n"
    AnimateWindow(PICKER_HWND, 125, AW_HIDE + AW_BLEND)
}

Picker_Gui_OnClose() {
    OutputDebug, % "-- Picker_Gui_OnClose() `n"
    AnimateWindow(PICKER_HWND, 125, AW_HIDE + AW_BLEND)
}

Picker_Gui_OnSize() {
    OutputDebug, % "-- Picker_Gui_OnSize() `n"
    if (A_EventInfo = 1)
        return
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

Picker_Gui_OnWMACTIVATEAPP(wParam, lParam, msg, hwnd) {
    if (hwnd = PICKER_HWND)
    {
        ; OutputDebug, % "-- Picker_Gui_OnWMACTIVATEAPP() `n"
        if (!wParam)
            Picker_Gui_OnDeactivate()
        else
            Picker_Gui_OnActivate()
    }
}

Picker_Gui_OnActivate() {
    OutputDebug, % "-- Picker_Gui_OnActivate() `n"
    SetTimer, GuiHide, Off
}

Picker_Gui_OnDeactivate() {
    OutputDebug, % "-- Picker_Gui_OnDeactivate() `n"
    SetTimer, GuiHide, 1000
    Return

GuiHide:
    Gui, Picker:Hide
Return
}

Picker_lbCategories_OnEvent() {
    OutputDebug, % "-- Picker_lbCategories_OnEvent() `n"
    global category
    if (A_GuiEvent = "Normal") {
        GuiControlGet, category,, PICKER_LBCATEGORIES
        Picker_lvPicker_Update()
    }
}

Picker_lbCategories_Update(categories) {
    OutputDebug, % "-- Picker_lbCategories_Update() `n"
    global category
    GuiControl, Text, PICKER_LBCATEGORIES, %categories%
    GuiControl, ChooseString, PICKER_LBCATEGORIES, %category%
}

Picker_lvPicker_OnEvent() {
    OutputDebug, % "-- Picker_lvPicker_OnEvent() `n"
    LV_GetText(cell, A_EventInfo, 3)
    switch A_GuiEvent {
        case "Normal": {
            LV_GetText(treated, A_EventInfo, 1)
            Gui, Picker:Hide
            if (!treated) {
                SendRaw, %cell%
            } else {
                Send, %cell%
            }
        }
        case "I": {
            if InStr(ErrorLevel, "f") {
                ToolTip
            }
        }
        case "RightClick": {
            MouseGetPos, mouseX, mouseY
            ToolTip, %cell%, %mouseX%, %mouseY%
            SetTimer, Picker_lvPicker_RemoveToolTip
        }
    }
}

Picker_lvPicker_RemoveToolTip() {
    if (A_TimeIdle < 100 or A_TimeIdle > 3000) {
        ToolTip
        SetTimer, Picker_lvPicker_RemoveToolTip, Off
    }
}

Picker_lvPicker_Update(new_hsCol := "") {
    OutputDebug, % "-- Picker_lvPicker_Update() `n"
    global category
    static hsCol
    hsCol := new_hsCol?new_hsCol:hsCol
    if !hsCol
        return
        ; Filter the Data
    Gui, Picker:ListView, PICKER_LVPICKER
    LV_Delete()
    ; Fill the ListView
    critical, On
    GuiControl, -Redraw, PICKER_LVPICKER
    loop, % hsCol.Length()
    {
        hs := hsCol[A_Index]
        if (category != "*" and hs["Category"] != category)
            continue
        LV_Add("", hs["Treated"], hs["Trigger"], hs["Replacement"])
    }
    GuiControl, +Redraw, PICKER_LVPICKER
    critical, Off
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
    Editors_RemoveEnded()
    Editors_Add()
    Editors_Tile()
}

Picker_btnSubmit_OnClick() {
    OutputDebug, % "-- Picker_btnSubmit_OnClick() `n"
    GuiControlGet, focused, Picker:FocusV
    if (focused = "PICKER_LVPICKER") {
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

Picker_tvNotes_OnMenu(itemName, itemPos, MenuName) {
    OutputDebug, % "-- Picker_tvNotes_OnMenu() `n"
    switch itemPos {
        case 1:
            Picker_Notes_New()
        case 2:
            Picker_Notes_Delete()
        case 3:
            Send, {F2}
    }
}

Picker_tvNotes_OnEvent() {
    OutputDebug, % "-- Picker_tvNotes_OnEvent() `n"
    global notesCol
    static lastID
    switch A_GuiEvent {
        case "S": {
            GuiControl, Enable, PICKER_EDTNOTE
            if lastID {
                if notesCol[lastID].Dirty {
                    message := "
                    ( Join
                        You have changes that have not been saved yet.`n
                        Do you want to save those changes ?
                    )" 
                    MsgBox, 0x2034, Unsaved note, %message%
                    IfMsgBox, Yes
                        Picker_Notes_Save(lastID)
                    IfMsgBox, No
                        Picker_Notes_Cancel(lastID)
                }
            }
            note := notesCol[A_EventInfo]
            GuiControl, Text, PICKER_EDTNOTE,
            fullPath := note.FullPath
            if !note.Directory {
                file := FileOpen(fullPath, "R")
                if !file {
                    MsgBox, Cannot open file %fullPath% reading
                    return
                }
                content := file.Read()
                file.close()
                GuiControl, Text, PICKER_EDTNOTE, %content%
                GuiControlGet, content,, PICKER_EDTNOTE
                note.Content := content
                lastID := A_EventInfo
            }
        }

        case "e": {
            note := notesCol[A_EventInfo]
            oldTitle := note.Title
            TV_GetText(newTitle, A_EventInfo)
            try {
                note.rename(newTitle)
            } catch e {
                TV_Modify(A_EventInfo,, oldTitle)
                MsgBox 0x2030, Error, %e%
            }
        }
    }
}

Picker_tvNotes_Update()
{
    OutputDebug, % "-- Picker_tvNotes_Update() `n"
    oldWD := A_WorkingDir
    notesDir := config.notesDir
    Gui, Picker:+LastFound
    ; Gui, Treeview, PICKER_TVNOTES
    GuiControl, -Redraw, PICKER_TVNOTES
    critical, On
    TV_Delete()
    Picker_tvNotes_Recurse(notesDir, 0)
    critical, Off
    GuiControl, +Redraw, PICKER_TVNOTES
    SetWorkingDir, %oldWD%
}

Picker_tvNotes_Recurse(path, currentID) {
    global notesCol
    notesCol := notesCol?notesCol:{}

    loop, Files, %path%\*.*, DF
    {
        if InStr(A_LoopFileAttrib, "D") {
            noteID := TV_Add(A_LoopFileName, currentID, "+Icon2 +Expand")
            Picker_tvNotes_Recurse(A_LoopFileFullPath, noteID)
        } else if (A_LoopFileExt = "txt") {
            SplitPath A_LoopFileName,,,, fileName
            noteID := TV_Add(fileName, currentID, "+Icon1")
        } else
            continue
        directory := InStr(A_LoopFileAttrib, "D")?True:False
        notesCol[noteID] := new Note(noteID, A_LoopFileFullPath, directory)
    }
}

Picker_edtNote_OnChange() {
    OutputDebug, % "-- Picker_edtNote_OnChanges() `n"
    global notesCol
    note := notesCol[Picker_Get_NoteID()]
    GuiControlGet, content,, PICKER_EDTNOTE
    if note.Content != content {
        note.Dirty := True
    } else {
        note.Dirty := False
    }
}

Picker_Notes_New() {
    OutputDebug, % "-- Picker_Notes_New `n"
    notesDir := config.notesDir
    Gui +OwnDialogs
    FileSelectFile, fullPath, S 0x10, %notesDir%\New_Note.txt, Create a new Note, Notes (*.txt)
    if !ErrorLevel {
        FileAppend,, %fullPath%
        Picker_tvNotes_Update()
    }

}

Picker_Notes_Delete() {
    OutputDebug, % "-- Picker_Notes_Delete `n"
    global notesCol
    noteID := Picker_Get_NoteID()
    directory := notesCol[noteID].Directory
    fullPath := notesCol[noteID].FullPath
    if directory {
        FileRemoveDir, %fullPath%, 1
        if !ErrorLevel {
            Picker_tvNotes_Update()
        }
    } else {
        FileDelete, %fullPath%
        if !ErrorLevel {
            notesCol.Delete(noteID)
            TV_Delete(noteID)
        }
    }
    GuiControl, Text, PICKER_EDTNOTE,
    GuiControl, Disable, PICKER_EDTNOTE
}

Picker_Notes_Rename() {
    OutputDebug, % "-- Picker_Notes_Rename `n"
}

Picker_Notes_Save(noteID) {
    OutputDebug, % "-- Picker_edtNote_SaveChanges() `n"
    global notesCol
    note := notesCol[noteID]
    GuiControlGet, content,, PICKER_EDTNOTE
    file := FileOpen(note.FullPath, "W")
    if !file {
        MsgBox, 0x2010, Error, Error %A_LastError%
        return
    }
    file.Write(content)
    file.Close()
    note.Dirty := False
}

Picker_Notes_Cancel(noteID := "") {
    OutputDebug, % "-- Picker_edtNote_CancelChanges() `n"
    note := noteID?noteID:Picker_Get_NoteID()
    note.Dirty := False
}

Picker_btnNew_OnClick() {
    OutputDebug, % "-- Picker_btnNew_OnClick() `n"
    notesDir := config.notesDir
    Gui +OwnDialogs
    FileSelectFile, fullPath, S 0x10, %notesDir%\New_Note.txt, Create a new Note, Notes (*.txt)
    if !ErrorLevel {
        FileAppend,, %fullPath%
        Picker_tvNotes_Update()
    }
}

Picker_btnDelete_OnClick() {
    OutputDebug, % "-- Picker_btnDelete_OnClick() `n"
    Picker_Notes_Delete()
}

Picker_btnSave_OnClick() {
    OutputDebug, % "-- Picker_btnSave_OnClick() `n"
    ; noteID := Picker_Get_NoteID()
    Picker_Notes_Save(Picker_Get_NoteID())
}
