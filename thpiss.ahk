#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Recommended for catching common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#NoTrayIcon
#SingleInstance, Off
FileEncoding, UTF-8-Raw

ver = v2.0
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
Gui, Main:+Disabled
ThcrapFolder := SelectFolder(2,"Select the Thcrap folder.")
Gui, Main:-Disabled
Gui, Main:+LastFound
WinActivate
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
            If A_LoopField not contains _custom,custom.exe
                ThcrapListGamesName .= A_LoopField . "|"
        If A_Index = 4
            If A_LoopField not contains _custom,custom.exe
                {
                GameNumber += 1
                FixField := StrReplace(A_LoopField,"/","\")
                SplitPath, FixField, GameExe, GamePath
                Game%GameNumber% := GamePath
                GameExe%GameNumber% := GameExe
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

The := GameFolder Th ThSuffix ".exe"
If CancelAll = 1
    Goto, EnableGui
FileInstall, thXXe.bin, %The%, 1
FileCopy, %The%, %GameFolder%custom_%ThSuffixCustom%.exe, 1
BundleAhkScript(The, ThExe, UserIcon, ThcrapLang, GameFolder)
BundleAhkScript(GameFolder "custom_" ThSuffixCustom ".exe", "custom.exe", GameFolder "custom.exe", ThcrapLang)

If DisableUpdates = 1
    MsgBox,, %ProgName%, All done :)`n`n"%Th%%ThSuffix%.exe" and "custom_%ThSuffixCustom%.exe" created.`n`nIf you want to enable updates just copy`n"thcrap_update.dll" from the Thcrap folder to:`n"%ThcrapGameFolder%"
Else
    MsgBox,, %ProgName%, All done :)`n`n"%Th%%ThSuffix%.exe" and "custom_%ThSuffixCustom%.exe" created.
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

;Build function
BundleAhkScript(ExeFile, ThExe, IcoFile="", ThcrapLang="", ThFolder="")
{
IcoTemp = %A_Temp%\temp.ico
IfInString, IcoFile, .exe
    GoSub, ExtractIconRes
Else IfInString, IcoFile, .ico
    FileCopy, %IcoFile%, %A_Temp%\temp.ico
Else If IcoFile =
    IcoFile = %ThFolder%%ThExe%
    GoSub, ExtractIconRes

If ThcrapLang =
    ThcrapLang = en.js

ScriptBody =
(
#NoEnv
#NoTrayIcon
#SingleInstance
SetWorkingDir `%A_ScriptDir`%
If FileExist("thcrap\thcrap_loader.exe") && FileExist("thcrap\%ThcrapLang%") && FileExist("%ThExe%")
Run, `%comspec`% /c "cd thcrap & thcrap_loader.exe "%ThcrapLang%" "..\%ThExe%"",, Hide UseErrorLevel
Else MsgBox, Check that "thcrap\thcrap_loader.exe"`, "thcrap\%ThcrapLang%" and "%ThExe%" exist within this folder.
ExitApp
)

VarSetCapacity(BinScriptBody, BinScriptBody_Len := StrPut(ScriptBody, "UTF-8") - 1)
StrPut(ScriptBody, &BinScriptBody, "UTF-8")
    
module := DllCall("BeginUpdateResource", "str", ExeFile, "uint", 0, "ptr")
        
; This "old-school" method of reading binary files is way faster than using file objects.

ReplaceAhkIcon(module, IcoTemp, ExeFile)

DllCall("UpdateResource", "ptr", module, "ptr", 10, "str", ">AUTOHOTKEY SCRIPT<", "ushort", 0x409, "ptr", &BinScriptBody, "uint", BinScriptBody_Len, "uint")

DllCall("EndUpdateResource", "ptr", module, "uint", 0)
RunWait, "%A_ScriptDir%\mpress.exe" -q -x "%ExeFile%",, Hide UseErrorLevel
Return

ExtractIconRes:
    IconGroup := GetIconGroupNameByIndex(IcoFile, 1)
    hModule2 := LoadLibraryEx(IcoFile)
    FileN := IcoTemp
    GoSub, WriteIcon
    DllCall("Kernel32.dll\FreeLibrary", "Ptr", hModule2)
    DllCall("Kernel32.dll\Sleep", "UInt", 1000)
Return

WriteIcon:
    RT_GROUP_ICON := 14
    RT_ICON := 3
    hFile := FileOpen(FileN, "rw", "CP0")
    sBuff := GetResource(hModule2, IconGroup, RT_GROUP_ICON, nSize, hResData)
    Icons := NumGet(sBuff + 0, 4, "UShort")
    hFile.RawWrite(sBuff + 0, 6)
    sBuff += 6
    Loop, %Icons% {
        hFile.RawWrite(sBuff + 0, 14)
        hFile.WriteUShort(0)
        sBuff += 14
    }
    DllCall("Kernel32.dll\FreeResource", "Ptr", hResData)
    EOF := hFile.Pos
    hFile.Pos := 18
    Loop %Icons% {
        nID := hFile.ReadUShort()
        hFile.Seek(-2, 1)
        hFile.WriteUInt(EOF)
        DataOffSet := hFile.Pos
        sBuff := GetResource(hModule2, nID, RT_ICON, nSize, hResData)
        hFile.Seek(-0, 2)
        hFile.RawWrite(sBuff + 0, nSize)
        DllCall("Kernel32.dll\FreeResource", "Ptr", hResData)
        EOF := hFile.Pos
        hFile.Pos := DataOffset + 12
    }
    hFile.Close()
Return
}

ReplaceAhkIcon(re, Icon, ExeFile)
{
    global _EI_HighestIconID
    static iconID := 1
    ids := EnumIcons(ExeFile, iconID)
    if !IsObject(ids)
        return false

    f := FileOpen(Icon, "r")
    if !IsObject(f)
        return false
    
    VarSetCapacity(igh, 8), f.RawRead(igh, 6)
    if NumGet(igh, 0, "UShort") != 0 || NumGet(igh, 2, "UShort") != 1
        return false
    
    wCount := NumGet(igh, 4, "UShort")
    
    VarSetCapacity(rsrcIconGroup, rsrcIconGroupSize := 6 + wCount*14)
    NumPut(NumGet(igh, "Int64"), rsrcIconGroup, "Int64") ; fast copy
    
    ige := &rsrcIconGroup + 6
    
    ; Delete all the images
    Loop, % ids.MaxIndex()
        DllCall("UpdateResource", "ptr", re, "ptr", 3, "ptr", ids[A_Index], "ushort", 0x409, "ptr", 0, "uint", 0, "uint")
    
    Loop, %wCount%
    {
        thisID := ids[A_Index]
        if !thisID
            thisID := ++ _EI_HighestIconID
        
        f.RawRead(ige+0, 12) ; read all but the offset
        NumPut(thisID, ige+12, "UShort")
        
        imgOffset := f.ReadUInt()
        oldPos := f.Pos
        f.Pos := imgOffset
        
        VarSetCapacity(iconData, iconDataSize := NumGet(ige+8, "UInt"))
        f.RawRead(iconData, iconDataSize)
        f.Pos := oldPos
        
        DllCall("UpdateResource", "ptr", re, "ptr", 3, "ptr", thisID, "ushort", 0x409, "ptr", &iconData, "uint", iconDataSize, "uint")
        
        ige += 14
    }
    
    DllCall("UpdateResource", "ptr", re, "ptr", 14, "ptr", iconID, "ushort", 0x409, "ptr", &rsrcIconGroup, "uint", rsrcIconGroupSize, "uint")
    FileDelete, %Icon%
    return true
}

EnumIcons(ExeFile, iconID)
{
    ; RT_GROUP_ICON = 14
    ; RT_ICON = 3
    global _EI_HighestIconID
    static pEnumFunc := RegisterCallback("EnumIcons_Enum")
    
    hModule := DllCall("LoadLibraryEx", "str", ExeFile, "ptr", 0, "ptr", 2, "ptr")
    if !hModule
        return
    
    _EI_HighestIconID := 0
    if DllCall("EnumResourceNames", "ptr", hModule, "ptr", 3, "ptr", pEnumFunc, "uint", 0) = 0
    {
        DllCall("FreeLibrary", "ptr", hModule)
        return
    }
    
    hRsrc := DllCall("FindResource", "ptr", hModule, "ptr", iconID, "ptr", 14, "ptr")
    hMem := DllCall("LoadResource", "ptr", hModule, "ptr", hRsrc, "ptr")
    pDirHeader := DllCall("LockResource", "ptr", hMem, "ptr")
    pResDir := pDirHeader + 6
    
    wCount := NumGet(pDirHeader+4, "UShort")
    iconIDs := []
    
    Loop, %wCount%
    {
        pResDirEntry := pResDir + (A_Index-1)*14
        iconIDs[A_Index] := NumGet(pResDirEntry+12, "UShort")
    }
    
    DllCall("FreeLibrary", "ptr", hModule)
    return iconIDs
}

EnumIcons_Enum(hModule, type, name, lParam)
{
    global _EI_HighestIconID
    if (name < 0x10000) && name > _EI_HighestIconID
        _EI_HighestIconID := name
    return 1
}

LoadLibraryEx(File)
{
   Return DllCall("Kernel32.dll\LoadLibraryEx", "Str", File, "Ptr", 0, "UInt", 0x02, "UPtr")
}

GetResource(hModule, rName, rType, ByRef nSize, ByRef hResData)
{
   Arg := (rName + 0 = "") ? &rName : rName
   hResource := DllCall("Kernel32.dll\FindResource", "Ptr", hModule, "Ptr", Arg, "Ptr", rType, "UPtr")
   nSize     := DllCall("Kernel32.dll\SizeofResource", "Ptr", hModule, "Ptr", hResource, "UInt")
   hResData  := DllCall("Kernel32.dll\LoadResource", "Ptr", hModule, "Ptr" , hResource, "UPtr")
   Return DllCall("Kernel32.dll\LockResource", "Ptr", hResData, "UPtr")
}

GetIconGroupNameByIndex(FilePath, Index, NamePtr := "", Param := "") {
   Static EnumProc := RegisterCallback("GetIconGroupNameByIndex", "F", 4)
   Static EnumCall := A_TickCount
   Static EnumCount := 0
   Static GroupIndex := 0
   Static GroupName := ""
   Static Loaded := 0
   ; ----------------------------------------------------------------------------------------------
   If (Param = EnumCall) { ; called by EnumResourceNames
      EnumCount++
      If (EnumCount = GroupIndex) {
         If ((NamePtr & 0xFFFF) = NamePtr)
            GroupName := NamePtr
         Else
            GroupName := StrGet(NamePtr)
         Return False
      }
      Return True
   }
   ; ----------------------------------------------------------------------------------------------
   EnumCount := 0
   GroupIndex := Index
   GroupName := ""
   Loaded := 0
   If !(HMOD := DllCall("GetModuleHandle", "Str", FilePath, "UPtr")) {
      If (HMOD := DllCall("LoadLibraryEx", "Str", FilePath, "Ptr", 0, "UInt", 0x02, "UPtr"))
         Loaded := HMOD
      Else
         Return ""
   }
   DllCall("EnumResourceNames", "Ptr", HMOD, "Ptr", 14, "Ptr", EnumProc, "Ptr", EnumCall)
   If (Loaded)
      DllCall("FreeLibrary", "Ptr", Loaded)
   Return GroupName
}

;Vista style folder picker
SelectFolder(FSFOptions,FSFText) {
   ; Common Item Dialog -> msdn.microsoft.com/en-us/library/bb776913%28v=vs.85%29.aspx
   ; IFileDialog        -> msdn.microsoft.com/en-us/library/bb775966%28v=vs.85%29.aspx
   ; IShellItem         -> msdn.microsoft.com/en-us/library/bb761140%28v=vs.85%29.aspx
   Static OsVersion := DllCall("GetVersion", "UChar")
   Static Show := A_PtrSize * 3
   Static SetOptions := A_PtrSize * 9
   Static GetResult := A_PtrSize * 20
   SelectedFolder := ""
   If (OsVersion < 6) { ; IFileDialog requires Win Vista+
      FileSelectFolder, SelectedFolder,, %FSFOptions%, %FSFText%
      Return SelectedFolder
   }
   If !(FileDialog := ComObjCreate("{DC1C5A9C-E88A-4dde-A5A1-60F82A20AEF7}", "{42f85136-db7e-439c-85f1-e4075d135fc8}"))
      Return ""
   VTBL := NumGet(FileDialog + 0, "UPtr")
   DllCall(NumGet(VTBL + SetOptions, "UPtr"), "Ptr", FileDialog, "UInt", 0x00000028, "UInt") ; FOS_NOCHANGEDIR | FOS_PICKFOLDERS
   
   If !DllCall(NumGet(VTBL + Show, "UPtr"), "Ptr", FileDialog, "Ptr", 0, "UInt") {
      If !DllCall(NumGet(VTBL + GetResult, "UPtr"), "Ptr", FileDialog, "PtrP", ShellItem, "UInt") {
         GetDisplayName := NumGet(NumGet(ShellItem + 0, "UPtr"), A_PtrSize * 5, "UPtr")
         If !DllCall(GetDisplayName, "Ptr", ShellItem, "UInt", 0x80028000, "PtrP", StrPtr) ; SIGDN_DESKTOPABSOLUTEPARSING
            SelectedFolder := StrGet(StrPtr, "UTF-16"), DllCall("Ole32.dll\CoTaskMemFree", "Ptr", StrPtr)
         ObjRelease(ShellItem)
    
      }
   }
   Return SelectedFolder
}

;Copy function code
copygui(filein,fileout,copyprogress,guiname="",copytext="")
{
SplitPath, filein, fileinname
SplitPath, fileout, fileoutname
If guiname !=
    guiname .= ":"
fread := FileOpen(filein,"r")
If (!fread)
    Return -1
fread_size := fread.Length
If fread_size > 1000000000
    {
    chunk_num := 1001
    fread_chunk_size := Floor(fread_size / 1000)
    fread_chunk_size_last := ((fread_size / 1000) - fread_chunk_size) * 1000
    }
Else
    {
    chunk_num := 101
    fread_chunk_size := Floor(fread_size / 100)
    fread_chunk_size_last := ((fread_size / 100) - fread_chunk_size) * 100
    }
fwrite := FileOpen(fileout,"w")
If (!fwrite)
    Return -1
Loop, %chunk_num%
    {
    If A_Index = %chunk_num%
        {
        fread.RawRead(fread_chunk,fread_chunk_size_last)
        fwrite.RawWrite(fread_chunk,fread_chunk_size_last)
        }
    If A_Index < %chunk_num%
        {
        fread.RawRead(fread_chunk,fread_chunk_size)
        fwrite.RawWrite(fread_chunk,fread_chunk_size)
        }
    If A_Index = 1
        {
        GuiControl, %guiname%, %copytext%, Copying %fileinname% - 0`%
        Continue
        }
    Else If (A_Index = chunk_num - 1)
        {
        GuiControl, %guiname%, %copytext%, Copying %fileinname% - %copypercentage%`%
        Continue
        }
    If chunk_num = 1001
        {
        each10 := SubStr(A_Index,0,1)
        If (each10 = 0 or A_Index = chunk_num)
            {
            GuiControl, %guiname%, %copyprogress%, +1
            If copytext !=
                {
                copypercentage += 1
                GuiControl, %guiname%, %copytext%, Copying %fileinname% - %copypercentage%`%
                }
            }
        }
    Else
        {
        GuiControl, %guiname%, %copyprogress%, +1
        If copytext !=
            {
            copypercentage += 1
            GuiControl, %guiname%, %copytext%, Copying %fileinname% - %copypercentage%`%
            }
        }
    }
fread.Close()
fwrite.Close()
Return 1
}
