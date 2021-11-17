;Activates the window. Do not use this value with AW_HIDE.
global AW_ACTIVATE := 0x00020000
;Uses a fade effect. This flag can be used only if hwnd is a top-level window.
,AW_BLEND := 0x00080000
;Makes the window appear to collapse inward if AW_HIDE is used or expand outward
;if the AW_HIDE is not used. The various direction flags have no effect.
,AW_CENTER := 0x00000010
;Hides the window. By default, the window is shown.
,AW_HIDE := 0x00010000
;Animates the window from left to right. This flag can be used with roll or
;slide animation. It is ignored when used with AW_CENTER or AW_BLEND.
,AW_HOR_POSITIVE := 0x00000001
;Animates the window from right to left. This flag can be used with roll or
;slide animation. It is ignored when used with AW_CENTER or AW_BLEND.
,AW_HOR_NEGATIVE := 0x00000002
;Uses slide animation. By default, roll animation is used. This flag is ignored
;when used with AW_CENTER.
,AW_SLIDE := 0x00040000
;Animates the window from top to bottom. This flag can be used with roll or
;slide animation. It is ignored when used with AW_CENTER or AW_BLEND.
,AW_VER_POSITIVE := 0x00000004
;Animates the window from bottom to top. This flag can be used with roll or
;slide animation. It is ignored when used with AW_CENTER or AW_BLEND.
,AW_VER_NEGATIVE := 0x00000008

AnimateWindow(hWnd, Duration, Flag) {
    return DllCall("AnimateWindow", "UInt"
    , hWnd, "Int", Duration, "UInt" , Flag)
}
