#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Recommended for catching common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#NoTrayIcon
#SingleInstance, Off
FileEncoding, UTF-8-Raw
ListLines, Off
#Include inc
#Include build.ahk
#Include copyprogress.ahk
#Include folderpicker.ahk

ver = v2.0.1
ProgName = Touhou Patcher Installer Static Simulator
Title = %ProgName% %ver%

DetectHiddenWindows, On
WinGet, L, List, %A_ScriptFullPath% ahk_class AutoHotkey
If L2 !=
    {
    WinGet, PID, PID, ahk_id %L2%
    WinActivate, ahk_pid %PID%
    ExitApp
    }
DetectHiddenWindows, Off

Working = 0
CancelAll = 0

Gui, Splash:Add, Text, w200, This utility generates a copy of thcrap inside of Touhou games to make it work similarly to the old english patches.
Gui, Splash:Add, Text,, Continue?
Gui, Splash:Add, Button, w50 gSplashYes Default, Yes
Gui, Splash:Add, Button, w50 xp+55 gSplashNo, No
Gui, Splash:Add, Text, xp+55 yp+10, %ver%
Gui, Splash:Show,, %ProgName%
Return

SplashNo:
SplashGuiClose:
ExitApp

SplashYes:
Gui, Splash:Destroy

Main:
Gui, Main:Add, Text, ym+4 Section,Thcrap Folder:
Gui, Main:Add, Edit, ys-3 w200 r1 vThcrapFolder gInputThcrapFolder
Gui, Main:Add, Button, ys-4 vSelectThcrapFolder gSelectThcrapFolder, ...

Gui, Main:Add, Text, xs yp+33 w160 Section, Select a Touhou game to use:
Gui, Main:Add, DropDownList, ys-4 w139 vThGame AltSubmit
Gui, Main:Add, DropDownList, xp yp vThGameName
GuiControl, Main:Hide, ThGameName

Gui, Main:Add, Text, xs yp+33 w160 Section, Select a Thcrap configuration file:
Gui, Main:Add, DropDownList, ys-4 w139 vThcrapLang

Gui, Main:Add, Checkbox, xs y+16 w107 Section vUserIconCheck, Use custom icon
Gui, Main:Add, Picture, x+140 ys-9 w32 h32 vUserIcon
Gui, Main:Add, Button, ys-4 vSelectIcon gSelectIcon, ...
Gui, Main:Add, Checkbox, xs y+2 Section vUsevpatch, Use vpatch (only if available)
Gui, Main:Add, Checkbox, xs y+8 vDisableUpdates, Disable automatic Thcrap updates (NOT RECOMMENDED)
Gui, Main:Add, Text, xs y+12, Shortcut name: Game name +
Gui, Main:Add, Radio, xs w309 r1 -Wrap vExeName1 Checked, First letter of config file (e.g. "thXXe.exe")
Gui, Main:Add, Radio, xs w309 r1 -Wrap vExeName2, Underscore + Full config file name (e.g. "thXX_en.exe")

Gui, Main:Add, Progress, y+10 w309 -Smooth vGlobalProgress
Gui, Main:Add, Text, w55 r1 Section vGlobalText
Gui, Main:Add, Text, x+1 ys w2 r1, |
;Gui, Main:Add, Progress, w309 Range0-100 -Smooth vSingleProgress
Gui, Main:Add, Text, x+5 ys w246 r1 vSingleText

Gui, Main:Add, Button, xm y+10 vOkButton gOkButton Default, Start
Gui, Main:Add, Button, xp yp vCancelButton gCancelButton, Cancel
GuiControl, Main:Hide, CancelButton
GuiControl, Main:Focus, OkButton
Gui, Main:+hWndMainGuihWnd
Gui, Main:Show,, %ProgName% 
Return

MainGuiClose:
If Working = 0
    ExitApp
Else
    {
    MsgBox, 4, %ProgName%, %ProgName% is working.`n`nExit anyway?
    IfMsgBox Yes
        ExitApp
    }
Return

CancelButton:
CancelAll = 1
Return

SelectThcrapFolder:
Gui, Main:+OwnDialogs
ThcrapFolder := SelectFolder(2,"Select the Thcrap folder",MainGuihWnd)
If ThcrapFolder =
    Return
Else
    GuiControl, Main:, ThcrapFolder, %ThcrapFolder%
Return

InputThcrapFolder:
GuiControlGet, ThcrapFolder, Main:, ThcrapFolder
ThcrapListGamesName := "|"
GuiControl, Main:, ThGameName, %ThcrapListGamesName%
Loop, Read, %ThcrapFolder%\games.js
    {
    Loop, Parse, A_LoopReadLine, ""
        {
        If A_Index = 2
            {
            If A_LoopField not contains _custom
                ThcrapListGamesName .= A_LoopField "|"
            If A_LoopField contains _custom
                ThGameName := StrReplace(A_LoopField,"_custom")
            }
        If A_Index = 4
            {
            FixField := StrReplace(A_LoopField,"/","\")
            SplitPath, FixField, GameExe, GamePath
            If A_LoopField not contains custom.exe
                {
                GameNumber += 1
                Game%GameNumber% := GamePath
                GameExe%GameNumber% := GameExe
                }
            If A_LoopField contains custom.exe
                GameCustomExe%ThGameName% := GameExe
            }
        }
    }
If ThcrapListGamesName =
    ThcrapListGamesName := "|"
ThcrapListLang := "|"
GuiControl, Main:, ThcrapLang, %ThcrapListLang%
Loop, Files, %ThcrapFolder%\*.js
    {
    If A_LoopFileName not in games.js,config.js
        ThcrapListLang .= A_LoopFileName "|"
    }
If ThcrapListLang =
    ThcrapListLang := "|"
GuiControl, Main:, ThGame, %ThcrapListGamesName%
GuiControl, Main:, ThGameName, %ThcrapListGamesName%
GuiControl, Main:Choose, ThGame, 1
GuiControl, Main:, ThcrapLang, %ThcrapListLang%
GuiControl, Main:Choose, ThcrapLang, 1
Return

SelectIcon:
Gui, Main:+OwnDialogs
FileSelectFile, UserIcon, 1,,,Ico Files (*.ico)
If UserIcon !=
    {
    GuiControl, Main:, UserIconCheck, 1
    GuiControl, Main:, UserIcon, %UserIcon%
    }
Return

OkButton:
Gui, Main:+OwnDialogs
GuiControlGet, ThGame, Main:, ThGame
GuiControl, Main:Choose, ThGameName, %ThGame%
Gui, Main:Submit, NoHide
GameFolder := Game%ThGame%
ThExe := GameExe%ThGame%
ThcrapGameFolder := GameFolder "\thcrap"
ThAltExe =
If (ThcrapFolder = "" || ThGame = "" || ThGameName = "")
    Return
GoSub, DisableGui

If GameFolder =
    {
    MsgBox,, %ProgName%, A terrible error occurred.
    Goto, EnableGui
    }
If (! FileExist(GameFolder))
    {
    MsgBox,, %ProgName%, The Touhou game folder doesn't exist.`nMake sure to run Thcrap before using this tool.
    Goto, EnableGui
    }
If FileExist(GameFolder "\vpatch.exe")
    {
    If Usevpatch = 1
        {
        ThAltExe := ThExe
        ThExe := "vpatch.exe"
        }
    }
If ThExe = 
    {
    MsgBox,, %ProgName%, Touhou game executable not found.`nConfigure Thcrap properly before using this program.
    Goto, EnableGui
    }
If ThcrapFolder = %GameFolder%
    {
    MsgBox, 4, %ProgName%, Thcrap folder and Touhou folder are the same.`nNo files will be copied`, only the .exe will be created.`nIs that ok?
    IfMsgBox Yes
        Goto, NoCopy
    IfMsgBox No
        Goto, EnableGui
    }
Else If FileExist(ThcrapGameFolder "\thcrap_loader.exe") || FileExist(ThcrapGameFolder "\nmlgc") || FileExist(ThcrapGameFolder "\thpatch")
    {
    MsgBox, 4, %ProgName%, There is already a copy of Thcrap files in this folder.`n`nOverwrite?
    IfMsgBox Yes
        {
        FileRemoveDir, %ThcrapGameFolder%, 1
        Goto, CopyFiles
        }
    Else IfMsgBox No
        MsgBox, 4, %ProgName%, Nothing will be copied (except thcrap_update.dll if you didn't disabled updates) only the exe's will be created.`n`nContinue anyway?
        IfMsgBox Yes
            Goto, NoCopy
        IfMsgBox No
            Goto, EnableGui
    }

CopyFiles:
FileCreateDir, %ThcrapGameFolder%
FileCopy, %ThcrapFolder%\%ThcrapLang%, %ThcrapGameFolder%\%ThcrapLang%
;count files to copy
SkipField =
ReadNext =
FixField =
PatchFolderPrev =
CopyCount = 0
FileCount = 0
Loop, Read, %ThcrapGameFolder%\%ThcrapLang%
    {
    Loop, Parse, A_LoopReadLine, ""
        {
        If CancelAll = 1
            Goto, EnableGui
        If A_LoopField = archive
            {
            SkipField = True
            Continue
            }
        If SkipField = True
            {
            SkipField = False
            ReadNext = True
            Continue
            }
        If ReadNext = True
            {
            FixField := StrReplace(A_LoopField,"/","\")
            StringSplit, PatchFolders, A_LoopField, /
            If PatchFolders1 not in %PatchFolderPrev%
                If FileExist(ThcrapFolder "\" PatchFolders1 "\repo.js")
                    FileCount++
            PatchFolderPrev .= PatchFolders1 ","
            Loop, Files, %ThcrapFolder%\%FixField%*.*
                {
                If A_LoopFileName in files.js,formats.js,global.js,patch.js,stringdefs.js,themes.js,versions.js
                    FileCount++
                If A_LoopFileExt in ttf,otf
                    FileCount++
                If A_LoopFileName contains %ThGameName%.
                    FileCount++
                }
            If FileExist(ThcrapFolder "\" FixField ThGameName)
                {
                Loop, Files, %ThcrapFolder%\%FixField%%ThGameName%\*.*, FR
                    FileCount++
                }
            If FileExist(ThcrapFolder "\" FixField ThGameName "_custom")
                {
                Loop, Files, %ThcrapFolder%\%FixField%%ThGameName%_custom\*.*, FR
                    FileCount++
                }
            }
        ReadNext = False
        }
    }
FileCount++
Loop, Files, %ThcrapFolder%\*.dll
    {
    If A_LoopFileName != thcrap_update.dll
        FileCount++
    }
GuiControl, Main:+Range0-%FileCount%, GlobalProgress
GuiControl, Main:, GlobalText, %CopyCount%/%FileCount%
;copy
SkipField =
ReadNext =
FixField =
PatchFolderPrev =
Loop, Read, %ThcrapGameFolder%\%ThcrapLang%
    {
    Loop, Parse, A_LoopReadLine, ""
        {
        If CancelAll = 1
            Goto, EnableGui
        If A_LoopField = archive
            {
            SkipField = True
            Continue
            }
        If SkipField = True
            {
            SkipField = False
            ReadNext = True
            Continue
            }
        If ReadNext = True
            {
            FixField := StrReplace(A_LoopField,"/","\")
            StringSplit, PatchFolders, A_LoopField, /
            If PatchFolders1 not in %PatchFolderPrev%
                {
                If (! FileExist(ThcrapGameFolder "\" PatchFolders1))
                    FileCreateDir, %ThcrapGameFolder%\%PatchFolders1%
                If FileExist(ThcrapFolder "\" PatchFolders1 "\repo.js")
                    {
                    copygui(ThcrapFolder "\" PatchFolders1 "\repo.js",ThcrapGameFolder "\" PatchFolders1 "\repo.js","SingleProgress","Main","SingleText")
                    CopyCount++
                    GuiControl, Main:, GlobalProgress, +1
                    GuiControl, Main:, GlobalText, %CopyCount%/%FileCount%
                    }
                }
            PatchFolderPrev .= PatchFolders1 ","
            Loop, Files, %ThcrapFolder%\%FixField%*.*
                {
                If CancelAll = 1
                    Goto, EnableGui
                If (! FileExist(ThcrapGameFolder "\" FixField))
                    FileCreateDir, %ThcrapGameFolder%\%FixField%
                If A_LoopFileName in files.js,formats.js,global.js,patch.js,stringdefs.js,themes.js,versions.js
                    {
                    copygui(A_LoopFileFullPath,ThcrapGameFolder "\" FixField A_LoopFileName,"SingleProgress","Main","SingleText")
                    CopyCount++
                    GuiControl, Main:, GlobalProgress, +1
                    GuiControl, Main:, GlobalText, %CopyCount%/%FileCount%
                    }
                If A_LoopFileExt in ttf,otf
                    {
                    copygui(A_LoopFileFullPath,ThcrapGameFolder "\" FixField A_LoopFileName,"SingleProgress","Main","SingleText")
                    CopyCount++
                    GuiControl, Main:, GlobalProgress, +1
                    GuiControl, Main:, GlobalText, %CopyCount%/%FileCount%
                    }
                If A_LoopFileName contains %ThGameName%.
                    {
                    copygui(A_LoopFileFullPath,ThcrapGameFolder "\" FixField A_LoopFileName,"SingleProgress","Main","SingleText")
                    CopyCount++
                    GuiControl, Main:, GlobalProgress, +1
                    GuiControl, Main:, GlobalText, %CopyCount%/%FileCount%
                    }
                }
            If FileExist(ThcrapFolder "\" FixField ThGameName)
                {
                Loop, Files, %ThcrapFolder%\%FixField%%ThGameName%\*.*, FR
                    {
                    If CancelAll = 1
                        Goto, EnableGui
                    SplitPath, A_LoopFileFullPath,, SubField
                    FPos := InStr(A_LoopFileFullPath,FixField) + StrLen(FixField) + StrLen(ThGameName)
                    StringTrimLeft, SubField, SubField, % FPos
                    SubField := "\" SubField "\"
                    If SubField = \\
                        SubField := "\"
                    If (! FileExist(ThcrapGameFolder "\" FixField ThGameName SubField))
                        FileCreateDir, %ThcrapGameFolder%\%FixField%%ThGameName%%SubField%
                    copygui(A_LoopFileFullPath,ThcrapGameFolder "\" FixField ThGameName SubField A_LoopFileName,"SingleProgress","Main","SingleText")
                    CopyCount++
                    GuiControl, Main:, GlobalProgress, +1
                    GuiControl, Main:, GlobalText, %CopyCount%/%FileCount%
                    }
                }
            If FileExist(ThcrapFolder "\" FixField ThGameName "_custom")
                {
                Loop, Files, %ThcrapFolder%\%FixField%%ThGameName%_custom\*.*, FR
                    {
                    If CancelAll = 1
                        Goto, EnableGui
                    SplitPath, A_LoopFileFullPath,, SubField
                    FPos := InStr(A_LoopFileFullPath,FixField) + StrLen(FixField) + StrLen(ThGameName "_custom")
                    StringTrimLeft, SubField, SubField, % FPos
                    SubField := "\" SubField "\"
                    If SubField = \\
                        SubField := "\"
                    If (! FileExist(ThcrapGameFolder "\" FixField ThGameName "_custom" SubField))
                        FileCreateDir, %ThcrapGameFolder%\%FixField%%ThGameName%_custom%SubField%
                    copygui(A_LoopFileFullPath,ThcrapGameFolder "\" FixField ThGameName "_custom" SubField A_LoopFileName,"SingleProgress","Main","SingleText")
                    CopyCount++
                    GuiControl, Main:, GlobalProgress, +1
                    GuiControl, Main:, GlobalText, %CopyCount%/%FileCount%
                    }
                }
            }
        ReadNext = False
        }
    }
copygui(ThcrapFolder "\thcrap_loader.exe",ThcrapGameFolder "\thcrap_loader.exe","SingleProgress","Main","SingleText")
CopyCount++
GuiControl, Main:, GlobalProgress, +1
GuiControl, Main:, GlobalText, %CopyCount%/%FileCount%
Loop, Files, %ThcrapFolder%\*.dll
    {
    If CancelAll = 1
        Goto, EnableGui
    If A_LoopFileName != thcrap_update.dll
        {
        copygui(A_LoopFileFullPath,ThcrapGameFolder "\" A_LoopFileName,"SingleProgress","Main","SingleText")
        CopyCount++
        GuiControl, Main:, GlobalProgress, +1
        GuiControl, Main:, GlobalText, %CopyCount%/%FileCount%
        }
    }
Sleep, 1000

NoCopy:
If CancelAll = 1
    Goto, EnableGui
GameFolder .= "\"
ThcrapGameFolder .= "\"

If (! FileExist(UserIcon))
    UserIcon =

;MsgBox, 4, %ProgName%, Disable automatic Thcrap updates? (NOT RECOMMENDED)
If DisableUpdates = 0
    FileCopy, %ThcrapFolder%\thcrap_update.dll, %ThcrapGameFolder%thcrap_update.dll
Else If FileExist(ThcrapGameFolder "thcrap_update.dll")
    FileDelete, %ThcrapGameFolder%thcrap_update.dll

GuiControl, Main:, SingleText, Creating exe's
If ThAltExe !=
    {
    SplitPath, ThAltExe,,,,Th
    If UserIcon =
        UserIcon := GameFolder ThAltExe
    }
Else
    SplitPath, ThExe,,,,Th
If ExeName1 = 1
    {
    StringLeft, ThSuffix, ThcrapLang, 1
    ThSuffixCustom := ThSuffix
    }
If ExeName2 = 1
    {
    SplitPath, ThcrapLang,,,, ThSuffixCustom
    ThSuffix := "_" ThSuffixCustom
    }
SplitPath, GameCustomExe%ThGameName%,,,,CustomExe
The := GameFolder Th ThSuffix ".exe"
ThCustom := GameFolder CustomExe "_" ThSuffixCustom ".exe"
If CancelAll = 1
    Goto, EnableGui
FileInstall, thXXe.bin, %The%, 1
If FileExist(GameFolder GameCustomExe%ThGameName%)
    {
    FileCopy, %The%, %GameFolder%custom_%ThSuffixCustom%.exe, 1
    BundleAhkScript(ThCustom, GameCustomExe%ThGameName%, GameFolder GameCustomExe%ThGameName%, ThcrapLang)
    }
BundleAhkScript(The, ThExe, UserIcon, ThcrapLang, GameFolder)

If DisableUpdates = 1
    MsgBox,, %ProgName%, All done :)`n`n"%Th%%ThSuffix%.exe" and "custom_%ThSuffixCustom%.exe" created.`n`nIf you want to enable updates just copy`n"thcrap_update.dll" from the Thcrap folder to:`n"%ThcrapGameFolder%"
Else
    MsgBox,, %ProgName%, All done :)`n`n"%Th%%ThSuffix%.exe" and "%CustomExe%_%ThSuffixCustom%.exe" created.
Goto, EnableGui
Return

EnableGui:
GuiControl, Main:Enable, ThcrapFolder
GuiControl, Main:Enable, SelectThcrapFolder
GuiControl, Main:Enable, ThGame
GuiControl, Main:Enable, ThcrapLang
GuiControl, Main:Enable, UserIconCheck
GuiControl, Main:Enable, SelectIcon
GuiControl, Main:Enable, Usevpatch
GuiControl, Main:Enable, DisableUpdates
GuiControl, Main:Enable, ExeName1
GuiControl, Main:Enable, ExeName2
GuiControl, Main:Hide, CancelButton
GuiControl, Main:Show, OkButton
Working = 0
If CancelAll = 1
    {
    GuiControl, Main:, GlobalText,
    GuiControl, Main:, GlobalProgress, 0
    GuiControl, Main:, SingleText, Cancelled
    }
Else
    {
    GuiControl, Main:, GlobalText,
    GuiControl, Main:, SingleText, Finished
    }
CancelAll = 0
Return

DisableGui:
GuiControl, Main:Disable, ThcrapFolder
GuiControl, Main:Disable, SelectThcrapFolder
GuiControl, Main:Disable, ThGame
GuiControl, Main:Disable, ThcrapLang
GuiControl, Main:Disable, UserIconCheck
GuiControl, Main:Disable, SelectIcon
GuiControl, Main:Disable, Usevpatch
GuiControl, Main:Disable, DisableUpdates
GuiControl, Main:Disable, ExeName1
GuiControl, Main:Disable, ExeName2
GuiControl, Main:Hide, OkButton
GuiControl, Main:Show, CancelButton
Working = 1
Return
