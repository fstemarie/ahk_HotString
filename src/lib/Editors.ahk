#include <Tools>

editors := []

Editors_Add() {
    OutputDebug, % "-- Editors_Add() `n"
    global editors
    Run, notepad,,, pid
    editors.Push(pid)
    WinWait, ahk_pid %pid%
    WinSetTitle, Notepad: %pid%
    Editors_Tile()
}

Editors_RemoveEnded() {
    OutputDebug, % "-- Editors_RemoveEnded() `n"
    global editors
    i := editors.Count()
    while i >= 1
    {
        pid := editors[i]
        if !WinExist("ahk_pid" pid)
            editors.RemoveAt(i)
        i--
    }
}

Editors_Tile() {
    OutputDebug, % "-- Editors_Tile() `n"
    global editors
    if !editors.Count()
        return
    Editors_RemoveEnded()
    mon := Get_CurrentMonitor()
    SysGet, mon, MonitorWorkArea, %mon%
    monWidth := monRight - monLeft
    monHeight := monBottom - monTop
    W := monWidth * 0.25
    H := monHeight * 0.75
    Y := monTop + monHeight * 0.25
    for i, pid in editors
    {
        X := monLeft + W * (i - 1)
        WinMove, ahk_pid %pid%,, %X%, %Y%, %W%, %H%
        WinSet, AlwaysOnTop, On, ahk_pid %pid%
        Sleep 100
        WinSet, AlwaysOnTop, Off, ahk_pid %pid%
    }
}
