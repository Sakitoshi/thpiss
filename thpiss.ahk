#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn  ; Recommended for catching common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#NoTrayIcon
#SingleInstance Ignore
FileEncoding, UTF-8-Raw

ver = v1.2
ProgName = Touhou Patcher Installer Static Simulator %ver%

Gui, Add, Text, w200, This utility generates a copy of thcrap inside of Touhou games to make it work similarly to the old english patches.
Gui, Add, Text,, Continue?
Gui, Add, Button, w50 gYes Default, Yes
Gui, Add, Button, w50 xp+55 gNo, No
Gui, Add, Text, xp+55 yp+10, %ver%
Gui, Show,, %ProgName%
Return

No:
GuiClose:
ExitApp

Yes:
Gui, Submit
FileSelectFolder, ThcrapFolder,, 2, Select thcrap folder.
If ThcrapFolder =
    {
;	MsgBox,, %ProgName%, Cancel
	ExitApp
	}
IfNotExist %ThcrapFolder%\thcrap_loader.exe
    {
    MsgBox,, %ProgName%, thcrap_loader.exe not found.`nAre you sure thcrap is in this folder?.`nExiting now.
    ExitApp
    }
;FileSelectFolder, GameFolder,, 0,  Select Touhou game folder.
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

Gui, 3:Add, Text, w155, Select a Touhou game to use:
Gui, 3:Add, DropDownList, w155 vThGame Choose1 AltSubmit, %ThcrapListGamesName%
Gui, 3:Add, DropDownList, xp yp vThGameName, %ThcrapListGamesName%
Gui, 3:Add, Button, w72 gGameSelect Default, Select
GuiControl, 3:Hide1, ThGameName
Gui, 3:Show
Return

3GuiClose:
MsgBox, 4, %ProgName%, Exit?
IfMsgBox Yes
    ExitApp
Return

GameSelect:
GuiControlGet, ThGame, 3:, ThGame
GuiControl, 3:Choose, ThGameName, %ThGame%
Gui, 3:Submit
GameFolder := Game%ThGame%
ThExe := GameExe%ThGame%
ThcrapGameFolder := GameFolder "\thcrap"

If GameFolder =
    {
    MsgBox,, %ProgName%, A terrible error ocurred.`nExiting now.
    ExitApp
    }
If (! FileExist(GameFolder))
    {
    MsgBox,, %ProgName%, The Touhou game folder doesn't exist.`nMake sure to run Thcrap before using this tool`nExiting now.
    ExitApp
    }
;ThExe =
;Loop, Files, %GameFolder%\*.exe
;    If (A_LoopFileName ~= "th\w\w.exe") || (A_LoopFileName ~= "th\w\w\w.exe") || (A_LoopFileName = "alcostg.exe")
;        {
;        ThExe = %A_LoopFileName%
;        Break
;        }
If ThExe = 
    {
    MsgBox,, %ProgName%, Touhou game executable not found.`nAre you sure this is a Touhou game folder?`nExiting now.
    ExitApp
    }

ThcrapListLang =
Loop, Files, %ThcrapFolder%\*.js
    {
    If A_LoopFileName != games.js
        {
        ThcrapListLang .= A_LoopFileName . "|"
        }
    }
If ThcrapListLang =
    {
    MsgBox,, %ProgName%, Thcrap configuration files not found.`nAre you sure you ran thcrap?.`nExiting now.
    ExitApp
    }

Gui, 2:Add, Text, w155, Select a thcrap configuration file:
Gui, 2:Add, DropDownList, w155 vThcrapLang Choose1, %ThcrapListLang%
Gui, 2:Add, Button, w72 gLangSelect Default, Select
Gui, 2:Show
Return

2GuiClose:
MsgBox, 4, %ProgName%, Exit?
IfMsgBox Yes
    ExitApp
Return

LangSelect:
Gui, 2:Submit
If ThcrapFolder = %GameFolder%
    {
    MsgBox, 4, %ProgName%, Thcrap folder and Touhou folder are the same.`nNo files will be copied`, only the .exe will be created.`nIs that ok?
    IfMsgBox Yes
        Goto, NoCopy
    IfMsgBox No
        {
        MsgBox,, %ProgName%, Exiting now.
        ExitApp
        }
    }
Else If FileExist(ThcrapGameFolder "\thcrap_loader.exe") || FileExist(ThcrapGameFolder "\nmlgc") || FileExist(ThcrapGameFolder "\thpatch")
    {
    MsgBox, 4, %ProgName%, There is already a copy of thcrap files in this folder.`nOverwrite?
    IfMsgBox Yes
        {
        FileRemoveDir, %ThcrapGameFolder%, 1
        Goto, CopyFiles
        }
    Else IfMsgBox No
        MsgBox, 4, %ProgName%, Continue anyway?
        IfMsgBox No
            {
            MsgBox,, %ProgName%, Exiting now.
            ExitApp
            }
    }

CopyFiles:
Gui, copy:Add, Progress, w300 -Smooth vGlobalProgress
Gui, copy:Add, Text, w300 vGlobalText
;Gui, copy:Add, Progress, w300 Range0-100 -Smooth vSingleProgress
Gui, copy:Add, Text, w300 vSingleText
Gui, copy:Show,, %ProgName%

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
GuiControl, copy:+Range0-%FileCount%, GlobalProgress
GuiControl, copy:, GlobalText, %CopyCount%/%FileCount%
;copy
SkipField =
ReadNext =
FixField =
PatchFolderPrev =
Loop, Read, %ThcrapGameFolder%\%ThcrapLang%
    {
    Loop, Parse, A_LoopReadLine, ""
        {
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
                    copygui(ThcrapFolder "\" PatchFolders1 "\repo.js",ThcrapGameFolder "\" PatchFolders1 "\repo.js","SingleProgress","copy","SingleText")
                    CopyCount++
                    GuiControl, copy:, GlobalProgress, +1
                    GuiControl, copy:, GlobalText, %CopyCount%/%FileCount%
                    }
                }
            PatchFolderPrev .= PatchFolders1 ","
            Loop, Files, %ThcrapFolder%\%FixField%*.*
                {
                If (! FileExist(ThcrapGameFolder "\" FixField))
                    FileCreateDir, %ThcrapGameFolder%\%FixField%
                If A_LoopFileName in files.js,formats.js,global.js,patch.js,stringdefs.js,themes.js,versions.js
                    {
                    copygui(A_LoopFileFullPath,ThcrapGameFolder "\" FixField A_LoopFileName,"SingleProgress","copy","SingleText")
                    CopyCount++
                    GuiControl, copy:, GlobalProgress, +1
                    GuiControl, copy:, GlobalText, %CopyCount%/%FileCount%
                    }
                If A_LoopFileExt in ttf,otf
                    {
                    copygui(A_LoopFileFullPath,ThcrapGameFolder "\" FixField A_LoopFileName,"SingleProgress","copy","SingleText")
                    CopyCount++
                    GuiControl, copy:, GlobalProgress, +1
                    GuiControl, copy:, GlobalText, %CopyCount%/%FileCount%
                    }
                If A_LoopFileName contains %ThGameName%.
                    {
                    copygui(A_LoopFileFullPath,ThcrapGameFolder "\" FixField A_LoopFileName,"SingleProgress","copy","SingleText")
                    CopyCount++
                    GuiControl, copy:, GlobalProgress, +1
                    GuiControl, copy:, GlobalText, %CopyCount%/%FileCount%
                    }
                }
            If FileExist(ThcrapFolder "\" FixField ThGameName)
                {
                Loop, Files, %ThcrapFolder%\%FixField%%ThGameName%\*.*, FR
                    {
                    SplitPath, A_LoopFileFullPath,, SubField
                    FPos := InStr(A_LoopFileFullPath,FixField) + StrLen(FixField) + StrLen(ThGameName)
                    StringTrimLeft, SubField, SubField, % FPos
                    SubField := "\" SubField "\"
                    If SubField = \\
                        SubField := "\"
                    If (! FileExist(ThcrapGameFolder "\" FixField ThGameName SubField))
                        FileCreateDir, %ThcrapGameFolder%\%FixField%%ThGameName%%SubField%
                    copygui(A_LoopFileFullPath,ThcrapGameFolder "\" FixField ThGameName SubField A_LoopFileName,"SingleProgress","copy","SingleText")
                    CopyCount++
                    GuiControl, copy:, GlobalProgress, +1
                    GuiControl, copy:, GlobalText, %CopyCount%/%FileCount%
                    }
                }
            If FileExist(ThcrapFolder "\" FixField ThGameName "_custom")
                {
                Loop, Files, %ThcrapFolder%\%FixField%%ThGameName%_custom\*.*, FR
                    {
                    SplitPath, A_LoopFileFullPath,, SubField
                    FPos := InStr(A_LoopFileFullPath,FixField) + StrLen(FixField) + StrLen(ThGameName "_custom")
                    StringTrimLeft, SubField, SubField, % FPos
                    SubField := "\" SubField "\"
                    If SubField = \\
                        SubField := "\"
                    If (! FileExist(ThcrapGameFolder "\" FixField ThGameName "_custom" SubField))
                        FileCreateDir, %ThcrapGameFolder%\%FixField%%ThGameName%_custom%SubField%
                    copygui(A_LoopFileFullPath,ThcrapGameFolder "\" FixField ThGameName "_custom" SubField A_LoopFileName,"SingleProgress","copy","SingleText")
                    CopyCount++
                    GuiControl, copy:, GlobalProgress, +1
                    GuiControl, copy:, GlobalText, %CopyCount%/%FileCount%
                    }
                }
            }
        ReadNext = False
        }
    }
copygui(ThcrapFolder "\thcrap_loader.exe",ThcrapGameFolder "\thcrap_loader.exe","SingleProgress","copy","SingleText")
CopyCount++
GuiControl, copy:, GlobalProgress, +1
GuiControl, copy:, GlobalText, %CopyCount%/%FileCount%
Loop, Files, %ThcrapFolder%\*.dll
    {
    If A_LoopFileName != thcrap_update.dll
        {
        copygui(A_LoopFileFullPath,ThcrapGameFolder "\" A_LoopFileName,"SingleProgress","copy","SingleText")
        CopyCount++
        GuiControl, copy:, GlobalProgress, +1
        GuiControl, copy:, GlobalText, %CopyCount%/%FileCount%
        }
    }
Sleep, 2000
Gui, copy:Destroy

NoCopy:
GameFolder .= "\"
ThcrapGameFolder .= "\"

MsgBox, 4, %ProgName%, Wanna use a custom icon?
IfMsgBox Yes
    FileSelectFile, UserIcon, 1,,,Ico Files (*.ico)
Else
    UserIcon =

MsgBox, 4, %ProgName%, Disable automatic thcrap updates? (NOT RECOMMENDED)
IfMsgBox No
    FileCopy, %ThcrapFolder%\thcrap_update.dll, %ThcrapGameFolder%thcrap_update.dll
Else
    MsgBox,, %ProgName%, If you want to enable updates just copy`n"thcrap_update.dll" from the thcrap folder to:`n"%ThcrapGameFolder%"

SplitPath, ThExe,,,,Th
StringLeft, ThSuffix, ThcrapLang, 1
The = %GameFolder%%Th%%ThSuffix%.exe
FileInstall, thXXe.bin, %The%, 1
FileCopy, %The%, %GameFolder%custom_%ThSuffix%.exe, 1

BundleAhkScript(The, Th, UserIcon, ThcrapLang, GameFolder)
BundleAhkScript(GameFolder "custom_" ThSuffix ".exe", "custom", GameFolder "custom.exe", ThcrapLang)

MsgBox,, %ProgName%, All done :)`n`n"%Th%%ThSuffix%.exe" and "custom_%ThSuffix%.exe" created.
ExitApp

copyGuiClose:
Return

;Build function
BundleAhkScript(ExeFile, ThNumber, IcoFile="", ThcrapLang="", ThFolder="")
{
IfInString, IcoFile, .exe
    {
	GoSub, ExtractIconRes
	IcoTemp = temp.ico
    }
Else IfInString, IcoFile, .ico
    {
	FileCopy, %IcoFile%, %A_ScriptDir%\temp.ico
    IcoTemp = temp.ico
	}
Else If IcoFile =
    {
    IcoFile = %ThFolder%%ThNumber%.exe
	GoSub, ExtractIconRes
	IcoTemp = temp.ico
    }

If ThcrapLang =
    ThcrapLang = en.js

ScriptBody =
(
#NoEnv
#NoTrayIcon
#SingleInstance
SetWorkingDir `%A_ScriptDir`%
If FileExist("thcrap\thcrap_loader.exe") && FileExist("thcrap\%ThcrapLang%") && FileExist("%ThNumber%.exe")
Run, `%comspec`% /c "cd thcrap & thcrap_loader.exe "%ThcrapLang%" "..\%ThNumber%.exe"",, Hide UseErrorLevel
Else MsgBox, Check that "thcrap\thcrap_loader.exe"`, "thcrap\%ThcrapLang%" and "%ThNumber%.exe" exist within this folder.
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
    TargetFolder = %A_ScriptDir%
    IcoFile2 := IcoFile
	IconGroup := GetIconGroupNameByIndex(IcoFile, 1)
    hModule2 := LoadLibraryEx(IcoFile2)
    FileN := "temp.ico"
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
    hFile.CLose()
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
	FileDelete, temp.ico
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
