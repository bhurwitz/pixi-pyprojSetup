echo off
setlocal EnableDelayedExpansion
set "char=%%%%"
set "fileToComment=C:\Users\bchur\Desktop\Projects\dummyFile.txt"

(
  for /f "usebackq tokens=* delims=" %%A in (`findstr /n "^" "%fileToComment%"`) do (
    set "line=%%A"
    set "line=!line:*:=!"
    echo !char! !line!
  )
) > "C:\Users\bchur\Desktop\Projects\dummyOutput.txt"