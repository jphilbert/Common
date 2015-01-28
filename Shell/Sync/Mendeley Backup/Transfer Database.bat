@ECHO OFF

set sqlite_file=jphilbert@gmail.com@www.mendeley.com.sqlite

set app_dir_1=C:\Users\hilbertjp
set app_dir_2=C:\Users\HSDSD

set replacement_1=hilbertjp/Local_Files
set replacement_2=JPH_0001/Documents


:MENU
CLS

ECHO ======= Mendeley DB Transfer ========
ECHO.
ECHO -------------- Main -----------------
ECHO  1.  Copy Database Here
ECHO  2.  Relocate Files in Database
ECHO  3.  Copy Database There
ECHO -------------------------------------
ECHO.
ECHO ==========PRESS 'Q' TO QUIT==========
ECHO.

SET INPUT=
SET /P INPUT=Please select a number: 

IF /I '%INPUT%'=='1' GOTO CopyHere
IF /I '%INPUT%'=='2' GOTO Relocate
IF /I '%INPUT%'=='3' GOTO CopyThere
IF /I '%INPUT%'=='Q' GOTO Quit

CLS

ECHO ============INVALID INPUT============
ECHO -------------------------------------
ECHO Please select a number from the Main
echo Menu [1-3] or select 'Q' to quit.
ECHO -------------------------------------
ECHO ======PRESS ANY KEY TO CONTINUE======

PAUSE > NUL
GOTO MENU


@rem ------------------------------------------------------------
:CopyHere
@rem ------------------------------------------------------------
CLS

ECHO ======= Mendeley DB Transfer ========
ECHO.
ECHO -------- Select Directory -----------
ECHO  1.  %app_dir_1%
ECHO  2.  %app_dir_2%
ECHO 	     OR
ECHO      Type in another
ECHO -------------------------------------
ECHO.
ECHO ======== PRESS 'R' TO Return ========
ECHO.

SET INPUT=
SET /P INPUT=Please select a number: 

IF /I '%INPUT%'=='1' SET INPUT=%app_dir_1%
IF /I '%INPUT%'=='2' SET INPUT=%app_dir_2%
IF /I '%INPUT%'=='R' GOTO Menu

@rem ECHO Use %sqlite_file%
@rem SET /P INPUT2=Y or Type: 

@rem IF /I '%INPUT2%'=='Y' SET INPUT2=%sqlite_file%
SET INPUT2=%sqlite_file%

SET P="%INPUT%\AppData\Local\Mendeley Ltd\Mendeley Desktop\%INPUT2%"
echo Copying: %p% to db.sqlite
copy %p% db.sqlite 
PAUSE
GOTO MENU


@rem ------------------------------------------------------------
:Relocate
@rem ------------------------------------------------------------
CLS

ECHO ======= Mendeley DB Transfer ========
ECHO.
ECHO -------- Select Source Text ---------
ECHO  1.  %replacement_1%
ECHO  2.  %replacement_2%
ECHO	     OR
ECHO      Type in another
ECHO -------------------------------------
ECHO.
ECHO ======== PRESS 'R' TO Return ========
ECHO.

SET S=
SET /P S=Please select a number: 

IF /I '%S%'=='1' SET S=%replacement_1%
IF /I '%S%'=='2' SET S=%replacement_2%
IF /I '%S%'=='R' GOTO Menu

CLS

ECHO ======= Mendeley DB Transfer ========
ECHO.
ECHO ----- Select Replacement Text -------
ECHO  1.  %replacement_1%
ECHO  2.  %replacement_2%
ECHO	     OR
ECHO      Type in another
ECHO -------------------------------------
ECHO.
ECHO ======== PRESS 'R' TO Return ========
ECHO.

SET R=
SET /P R=Please select a number: 

IF /I '%R%'=='1' SET R=%replacement_1%
IF /I '%R%'=='2' SET R=%replacement_2%
IF /I '%R%'=='R' GOTO Menu

echo Replacing: %S% with %R%

Replace-in-DB %S% %R%

PAUSE
GOTO MENU


@rem ------------------------------------------------------------
:CopyThere
@rem ------------------------------------------------------------
CLS

ECHO ======= Mendeley DB Transfer ========
ECHO.
ECHO -------- Select Directory -----------
ECHO  1.  %app_dir_1%
ECHO  2.  %app_dir_2%
ECHO 	     OR
ECHO      Type in another
ECHO -------------------------------------
ECHO.
ECHO ======== PRESS 'R' TO Return ========
ECHO.

SET INPUT=
SET /P INPUT=Please select a number: 

IF /I '%INPUT%'=='1' SET INPUT=%app_dir_1%
IF /I '%INPUT%'=='2' SET INPUT=%app_dir_2%
IF /I '%INPUT%'=='R' GOTO Menu

@rem ECHO Use %sqlite_file%
@rem SET /P INPUT2=Y or Type: 

@rem IF /I '%INPUT2%'=='Y' SET INPUT2=%sqlite_file%
SET INPUT2=%sqlite_file%

SET P="%INPUT%\AppData\Local\Mendeley Ltd\Mendeley Desktop\%INPUT2%"

echo Backingup: %p%
copy %p% %p%.bak

echo Copying: db.sqlite to %p%
copy db.sqlite %p%

PAUSE
GOTO MENU


:Quit
CLS

@rem ECHO ============== Closing ==============
@rem ECHO -------------------------------------
@rem ECHO ======PRESS ANY KEY TO CONTINUE======

@rem PAUSE>NUL
