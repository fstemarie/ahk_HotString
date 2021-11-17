Send_Password() {
    password := Fetch_Password()

    SendRaw, %password%
}

Fetch_Password() {
    OutputDebug, % "-- Fetch_Password() `n"
    static password
    oldClip := ClipboardAll
    if (password = "") {
        cmd := ComSpec . " /q /c D:\applications\KeePassCommander\"
        + "KeePassCommand.exe getfield Citrix Password | clip"
        RunWait, %cmd%,, Hide
        out := RegExReplace(Clipboard, "(\s+)|(\r\n)", " ")
        password := StrSplit(out, " ")[8]
    }
    Clipboard := oldClip
    return password
}

Hotstring("`:X*`:###", "Send_Password")
