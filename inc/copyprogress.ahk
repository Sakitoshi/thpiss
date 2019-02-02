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
