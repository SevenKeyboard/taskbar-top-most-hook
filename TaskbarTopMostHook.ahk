#Requires AutoHotkey v2.0.0+
#Include "%A_ScriptDir%"
#Include ".\lib\ShellHookWindow.ahk"
;==============================================================
; TaskbarTopMostHook — Detects Windows taskbar TopMost state changes via shell fullscreen events
;
; GitHub: https://github.com/SevenKeyboard/taskbar-top-most-hook
; Author: SevenKeyboard Ltd. (2026)
; License: MIT License
;==============================================================

/*
Example Usage:
    ShellHookWindow.register(shellMessage), ShellHookWindow.unregisterOnExit()
    shellMessage(wParam, lParam, *)    {
        TaskbarTopMostHook.shellMessage(wParam, lParam)
    }
    TaskbarTopMostHook.setHook(callBackTaskbarTopMost)
    callBackTaskbarTopMost(OnOff)    {
        tooltip "TopMost : " OnOff
    }
*/

class VersionManager_TaskbarTopMostHook
{
    static _ := this._init()
    static _init()    {
        global
        TASKBARTOPMOSTHOOK_VERSION := "1.0.1"
        if (!this._verCheck(&SHELLHOOKWINDOW_VERSION, "1.0.0"))
            throw error("SHELLHOOKWINDOW_VERSION version 1.x is required (minimum 1.0.0).")
        return true
    }
    static _verCheck(&actual, required)    {
        if !isSet(actual)
            return false
        actualMajor     := strSplit(actual, ".",, 2)[1]
        requiredMajor   := strSplit(required, ".",, 2)[1]
        if (actualMajor !== requiredMajor)
            return false
        return verCompare(actual, ">=" required)
    }
}
class TaskbarTopMostHook
{
    static _callbacks:=map()
        ,_priorTopMostState:="", _thisTopMostState:=""
        ,_obmCallback:=objBindMethod(this,"_callback")
    static setHook(function, runImmediately:=true)    {
        if (this._callbacks.has(function))
            return
        this._callbacks[function]:=""
        this._priorTopMostState:="", this._thisTopMostState:=""
        if (runImmediately)
            this._callback()
    }
    static unhook(function?)    {
        if (isSet(function))    {
            if (this._callbacks.has(function))
                    this._callbacks.delete(function)
        }  else  {
            this._callbacks:=map()
        }
    }
    static shellMessage(wParam, lParam, *)    {
        if (!this._callbacks.Count)
            return
        switch (wParam)
        {
            case 53,54: ;  Fullscreen on, off
                setTimer(this._obmCallback,-100)
        }
    }
    static _callback()    {
        this._thisTopMostState:=this.getTopMostState()
        if (this._thisTopMostState<0)
            return
        if (this._priorTopMostState==this._thisTopMostState)
            return
        for fn in this._callbacks    {
            if (!hasMethod(fn))
                continue
            fn.call((this._priorTopMostState:=this._thisTopMostState
                ,this._thisTopMostState))
        }
    }
    static getTopMostState()    {
        static GWL_EXSTYLE:=-20, WS_EX_TOPMOST:=0x00000008
        if !(hShell_TrayWnd:=dllCall("User32.dll\FindWindowEx", "Ptr",0, "Ptr",0, "Str","Shell_TrayWnd", "Ptr",0, "Ptr"))
            return -1
        if !(exStyle:=dllCall("User32.dll\GetWindowLong" (A_PtrSize==8?"Ptr":""), "Ptr",hShell_TrayWnd, "Int",GWL_EXSTYLE, (A_PtrSize==8?"Ptr":"Int")))
            return -2
        return !!(exStyle&WS_EX_TOPMOST)
    }
}