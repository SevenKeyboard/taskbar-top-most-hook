#Requires AutoHotkey v1.1.36+
#Include %A_ScriptDir%
#Include .\lib\ShellHookWindow.ahk
;==============================================================
; TaskbarTopMostHook — Detects Windows taskbar TopMost state changes via shell fullscreen events
;
; GitHub: https://github.com/SevenKeyboard/taskbar-top-most-hook
; Author: SevenKeyboard Ltd. (2026)
; License: MIT License
;==============================================================

/*
Example Usage:
    ShellHookWindow.register("shellMessage"), ShellHookWindow.unregisterOnExit()
    shellMessage(wParam, lParam)    {
        TaskbarTopMostHook.shellMessage(wParam, lParam)
    }
    TaskbarTopMostHook.setHook("callBackTaskbarTopMost")
    callBackTaskbarTopMost(onOff)    {
        tooltip % "TopMost : " onOff
    }
*/

class VersionManager_TaskbarTopMostHook
{
    static _ := VersionManager_TaskbarTopMostHook._init()
    _init()    {
        global
        TASKBARTOPMOSTHOOK_VERSION := "1.0.1"
        if (!this._verCheck(SHELLHOOKWINDOW_VERSION, "1.0.0"))
            throw exception("SHELLHOOKWINDOW_VERSION version 1.x is required (minimum 1.0.0).")
        return true
    }
    _verCheck(byRef actual, required)    {
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
    static _callbacks:={}
        ,_priorTopMostState:="", _thisTopMostState:=""
        ,_obmCallback:=objBindMethod(TaskbarTopMostHook,"_callback")
    setHook(functionName, runImmediately:=true)    {
        if (this._callbacks.hasKey(functionName))
            return
        this._callbacks[functionName]:=""
        this._priorTopMostState:="", this._thisTopMostState:=""
        if (runImmediately)
            this._callback()
    }
    unhook(functionName:="")    {
        if (functionName!="")    {
            if (this._callbacks.hasKey(functionName))
                    this._callbacks.delete(functionName)
        }  else  {
            this._callbacks:={}
        }
    }
    shellMessage(wParam, lParam, _*)    {
        if (!this._callbacks.count())
            return
        switch (wParam)
        {
            case 53,54: ;  Fullscreen on, off
                obm:=this._obmCallback
                setTimer % obm, -100
        }
    }
    _callback()    {
        this._thisTopMostState:=this.getTopMostState()
        if (this._thisTopMostState<0)
            return
        if (this._priorTopMostState==this._thisTopMostState)
            return
        for fn in this._callbacks    {
            if (!isFunc(fn))
                continue
            %fn%(format("{2}",this._priorTopMostState:=this._thisTopMostState
                ,this._thisTopMostState))
        }
    }
    getTopMostState()    {
        static GWL_EXSTYLE:=-20, WS_EX_TOPMOST:=0x00000008
        if !(hShell_TrayWnd:=dllCall("User32.dll\FindWindowEx", "Ptr",0, "Ptr",0, "Str","Shell_TrayWnd", "Ptr",0, "Ptr"))
            return -1
        if !(exStyle:=dllCall("User32.dll\GetWindowLong" (A_PtrSize==8?"Ptr":""), "Ptr",hShell_TrayWnd, "Int",GWL_EXSTYLE, (A_PtrSize==8?"Ptr":"Int")))
            return -2
        return !!(exStyle&WS_EX_TOPMOST)
    }
}