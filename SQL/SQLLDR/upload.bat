rem --------- Name of File --------- 
set name=UROL_MEMBER_INFO

rem --------- Create Table --------- 
(echo @"%name%.sql";
    echo quit;) | sqlplus UID/PWD@edwrpt.world

rem --------- Load Data --------- 
sqlldr UID/PWD@edwrpt control=upload.ctl