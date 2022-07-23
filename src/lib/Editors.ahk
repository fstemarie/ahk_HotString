editors := []

Editors_Add() {
    OutputDebug, % "-- Editors_Add() `n"
    global editors
    Run, notepad,,, pid
    editors.Push(pid)
    Sleep 100
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
        WinSet, Top
    }
}
