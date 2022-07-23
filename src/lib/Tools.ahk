Find_Center(mon, W, H) {
    OutputDebug, % "-- Find_Center() `n"
    SysGet, mon, Monitor, %mon%
    X := Ceil(monLeft + (monRight - monLeft - W) / 2),
    Y := Ceil(monTop + (monBottom - monTop - H) / 2)
    return {"X": X, "Y": Y}
}

Get_CurrentMonitor() {
    OutputDebug, % "-- Get_Monitor() `n"
    CoordMode, Mouse, Screen
    MouseGetPos, mouseX, mouseY
    SysGet, monCount, MonitorCount
    mon := 1
    loop % monCount
    {
        SysGet, mon, Monitor, %A_Index%
        if mouseX between %monLeft% and %monRight%
            if mouseY between %monTop% and %monBottom%
            mon := A_Index
    }
    return mon
}

