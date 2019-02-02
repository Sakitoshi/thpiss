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
