;Vista style folder picker
SelectFolder(FSFOptions,FSFText="",hWndOwner="0") {
   ; Common Item Dialog -> msdn.microsoft.com/en-us/library/bb776913%28v=vs.85%29.aspx
   ; IFileDialog        -> msdn.microsoft.com/en-us/library/bb775966%28v=vs.85%29.aspx
   ; IShellItem         -> msdn.microsoft.com/en-us/library/bb761140%28v=vs.85%29.aspx
   Static OsVersion := DllCall("GetVersion", "UChar")
   Static Show := A_PtrSize * 3
   Static SetOptions := A_PtrSize * 9
   Static SetTitle := A_PtrSize * 17
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
   If (FSFText != "")
      DllCall(NumGet(VTBL + SetTitle, "UPtr"), "Ptr", FileDialog, "Str", FSFText, "UInt")
   If !DllCall(NumGet(VTBL + Show, "UPtr"), "Ptr", FileDialog, "Ptr", hWndOwner, "UInt") {
      If !DllCall(NumGet(VTBL + GetResult, "UPtr"), "Ptr", FileDialog, "PtrP", ShellItem, "UInt") {
         GetDisplayName := NumGet(NumGet(ShellItem + 0, "UPtr"), A_PtrSize * 5, "UPtr")
         If !DllCall(GetDisplayName, "Ptr", ShellItem, "UInt", 0x80028000, "PtrP", StrPtr) ; SIGDN_DESKTOPABSOLUTEPARSING
            SelectedFolder := StrGet(StrPtr, "UTF-16"), DllCall("Ole32.dll\CoTaskMemFree", "Ptr", StrPtr)
         ObjRelease(ShellItem)
      }
   }
   ObjRelease(FileDialog)
   Return SelectedFolder
}
