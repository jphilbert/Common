rem --------- Name of File --------- 
echo off
color F1
mode con:cols=80 lines=40

set name=FILE_NAME
set uid=
set pwd=
set db=edwrpt.world
echo on

rem --------- Create Table --------- 
(echo @"%name%.sql";
    echo quit;) | sqlplus %uid%/%pwd%@%db%

rem --------- Load Data --------- 
sqlldr %uid%/%pwd%@%db% control=%name%.ctl


echo off
rem --------- View Log --------- 
echo View Log
CHOICE /T 10 /C yn /D y

if ERRORLEVEL 2 goto :quit

:view
type %name%.log |more

:quit
pause