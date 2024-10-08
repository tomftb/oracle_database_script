@ECHO OFF
SETLOCAL
CLS
Rem Active code page
:: 852	Slavic (Latin II)
:: 65001	UTF-8 *
CHCP 65001 >nul 2>&1

SET CURRENT_DIR=%~dp0
::
:: 7zip config
::
SET ZIP_APP="C:\Program Files\7-Zip\7z.exe"
SET "ZIP_APP_OPTIONS=a -t7z -mx9 -mmt4"
::
:: Oracle exp.exe location
::
SET "EXP_APP=C:\Oracle\WINDOWS.X64_193000_db_home\bin\exp.exe"
::
:: External directory location
::
SET "EXT_DIR=D:\"
::
:: Database counter files
::
SET "COUNTER_FILE=%CURRENT_DIR%counter.txt"
SET "EXTERNAL_COUNTER_FILE=%CURRENT_DIR%counter_external.txt"
::
:: Script config
::
SET "BACKUP_LOG=%CURRENT_DIR%backup.log"
SET /A MAX=20
SET /A MAX_EXTERNAL=60
SET "FILE_CONTENT=n"
SET "EXTERNAL_FILE_CONTENT=n"
SET /A ACT=0
SET /A ACT_EXTERNAL=0
SET "NEW_FILE=n"
SET "STATUS=y"
::
:: Oracle config
::
SET "CURRENT_SID=your_oracle_sid"
SET "ORACLE_PORT=your_oracle_port"
SET "ORACLE_HOST=your_oracle_host"
::
:: Oracle database Kamsoft default users config
::
SET APW_USER[0]=apw_user
SET APW_USER[1]=apw_user_password
SET EDE_USER[0]=ede
SET EDE_USER[1]=ede_user_password
SET KS_USER[0]=ks
SET KS_USER[1]=ks_user_password
SET FN_USER[0]=fn
SET FN_USER[1]=fn_user_password

CALL :getCurrentDateTimeWithArg "%~0 SCRIPT STARTS" >> %BACKUP_LOG%

call :setBackupDir STATUS , AOW
call :setBackupDir STATUS , EDE
call :setBackupDir STATUS , KS
call :setBackupDir STATUS , FN

call :checkCounterFile %COUNTER_FILE% , NEW_FILE
call :setCounter ACT , %NEW_FILE% , FILE_CONTENT , %COUNTER_FILE%

SET "NEW_FILE=n"

call :checkCounterFile %EXTERNAL_COUNTER_FILE% , NEW_FILE
call :setCounter ACT_EXTERNAL , %NEW_FILE% , EXTERNAL_FILE_CONTENT , %EXTERNAL_COUNTER_FILE%

call :updateCounterFile %FILE_CONTENT% , %COUNTER_FILE%
call :updateCounter %ACT% , %MAX% , %COUNTER_FILE%

call :updateCounterFile %EXTERNAL_FILE_CONTENT% , %EXTERNAL_COUNTER_FILE%
call :updateCounter %ACT_EXTERNAL% , %MAX% , %EXTERNAL_COUNTER_FILE%

CALL :createBackup STATUS , %APW_USER[0]% , %APW_USER[1]%
CALL :createBackup STATUS , %EDE_USER[0]% , %EDE_USER[1]%
CALL :createBackup STATUS , %KS_USER[0]% , %KS_USER[1]%
CALL :createBackup STATUS , %FN_USER[0]% , %FN_USER[1]%

CALL :createArch STATUS , %CURRENT_DIR%AOW\%APW_USER[0]%_%ACT%.7z , %CURRENT_DIR%%APW_USER[0]%.dmp , %CURRENT_DIR%%APW_USER[0]%.log
CALL :createArch STATUS , %CURRENT_DIR%EDE\%EDE_USER[0]%_%ACT%.7z , %CURRENT_DIR%%EDE_USER[0]%.dmp , %CURRENT_DIR%%EDE_USER[0]%.log
CALL :createArch STATUS , %CURRENT_DIR%KS\%KS_USER[0]%_%ACT%.7z , %CURRENT_DIR%%KS_USER[0]%.dmp , %CURRENT_DIR%%KS_USER[0]%.log
CALL :createArch STATUS , %CURRENT_DIR%FN\%FN_USER[0]%_%ACT%.7z , %CURRENT_DIR%%FN_USER[0]%.dmp , %CURRENT_DIR%%FN_USER[0]%.log

CALL :externalCopy STATUS , %CURRENT_DIR%AOW\%APW_USER[0]%_%ACT%.7z , %EXT_DIR% , %APW_USER[0]%_%ACT_EXTERNAL%.7z
CALL :externalCopy STATUS , %CURRENT_DIR%EDE\%EDE_USER[0]%_%ACT%.7z , %EXT_DIR% , %EDE_USER[0]%_%ACT_EXTERNAL%.7z
CALL :externalCopy STATUS , %CURRENT_DIR%KS\%KS_USER[0]%_%ACT%.7z , %EXT_DIR% , %KS_USER[0]%_%ACT_EXTERNAL%.7z
CALL :externalCopy STATUS , %CURRENT_DIR%FN\%FN_USER[0]%_%ACT%.7z , %EXT_DIR% , %FN_USER[0]%_%ACT_EXTERNAL%.7z

GOTO :MAIN

:getCurrentDateTime
@echo %date% %time%
EXIT /B 0
:getCurrentDateTimeWithArg
@echo [%date% %time%] %~1
EXIT /B 0
:setBackupDir
CALL :getCurrentDateTimeWithArg %~0 >> %BACKUP_LOG%
IF EXIST "%CURRENT_DIR%%~2" (
 :: BACKUP DIR EXISTS
 CALL :getCurrentDateTimeWithArg "%~0 BACKUP DIR `%CURRENT_DIR%%~2` EXISTS - CONTINUE" >> %BACKUP_LOG%
 EXIT /B 0
) ELSE (
 CALL :getCurrentDateTimeWithArg "%~0 BACKUP DIR `%CURRENT_DIR%%~2` NOT EXISTS - TRY TO CREATE" >> %BACKUP_LOG%
)
:: TRY CREATE BACKUP DIR
mkdir "%CURRENT_DIR%%~2"
IF %ERRORLEVEL% NEQ 0 (
 CALL :getCurrentDateTimeWithArg "%~0 FAILED TO CREATE BACKUP DIR - `%CURRENT_DIR%%~2`" >> %BACKUP_LOG%
 SET %~1=n
 EXIT /B 1
) ELSE (
 CALL :getCurrentDateTimeWithArg "%~0 SUCCESSFULLY CREATED BACKUP DIR - `%CURRENT_DIR%%~2`" >> %BACKUP_LOG%
 EXIT /B 0
)
EXIT /B 0
:: FUNCTION checkCounterFile
:checkCounterFile
CALL :getCurrentDateTimeWithArg %~0 %~1 >> %BACKUP_LOG%
if exist %~1 (
 CALL :getCurrentDateTimeWithArg "%~0 file counter `%~1` exists - CONTINUE" >> %BACKUP_LOG%
 SET %~2=n
) else (
 CALL :getCurrentDateTimeWithArg "%~0 file counter `%~1` doesn't exist - UPDATE FILE STATUS" >> %BACKUP_LOG%
 SET %~2=y
)
EXIT /B 0
:: FUNCTION setCounter
:setCounter
CALL :getCurrentDateTimeWithArg %~0 %~2 >> %BACKUP_LOG%

if [%STATUS%]==[n] ( 
 CALL :getCurrentDateTimeWithArg "%~0 ERROR EXIST - EXIT" >> %BACKUP_LOG%
 EXIT /B 0
)
IF %~2 EQU y (
 CALL :getCurrentDateTimeWithArg "%~0 NEW FILE" >> %BACKUP_LOG%
 set /A %~1=1
 CALL :getCurrentDateTimeWithArg "%~0 ACT - 1" >> %BACKUP_LOG%
 EXIT /B 0
)
FOR /F %%i IN (%~4) DO (
 set /A %~1=%%i
 CALL :getCurrentDateTimeWithArg "%~0 ACT - %%i"  >> %BACKUP_LOG%
 SET %~3=y
 CALL :getCurrentDateTimeWithArg "%~0 FILE_CONTENT - y"  >> %BACKUP_LOG%
 EXIT /B 0
)
EXIT /B 0
:: FUNCTION checkFileContent
:updateCounterFile
CALL :getCurrentDateTimeWithArg %~0 >> %BACKUP_LOG%
IF %~1 EQU n (
 CALL :getCurrentDateTimeWithArg "%~0 SET DEFAULT COUNTER FILE CONTENT - `1`" >> %BACKUP_LOG%
 echo|set /p="1" > %~2
  EXIT /B 0
) ELSE (
 CALL :getCurrentDateTimeWithArg "%~0 COUNTER FILE CONTENT OKEY" >> %BACKUP_LOG%
)
EXIT /B 0
:: FUNCTION updateCounter
:updateCounter
CALL :getCurrentDateTimeWithArg %~0 >> %BACKUP_LOG%
CALL :getCurrentDateTimeWithArg "%~0 ACT - %~1" >> %BACKUP_LOG%
CALL :getCurrentDateTimeWithArg "%~0 MAX - %~2" >> %BACKUP_LOG%
SET /A NEW=%~1+1
CALL :getCurrentDateTimeWithArg "%~0 NEW - %NEW%" >> %BACKUP_LOG%
IF %NEW% GTR %~2 (
  CALL :getCurrentDateTimeWithArg "%~0 NEW VALUE GREATER THAN MAX - reset counter" >> %BACKUP_LOG%
  echo|set /p="1" > %~3
) else (
  CALL :getCurrentDateTimeWithArg "%~0 NEW VALUE LESS THAN MAX - update counter" >> %BACKUP_LOG%
  CALL :getCurrentDateTimeWithArg "%~0 NEW - %NEW%" >> %BACKUP_LOG%
  echo|set /p="%NEW%" > %~3
)
EXIT /B 0
:createBackup
CALL :getCurrentDateTimeWithArg %~0 >> %BACKUP_LOG%

if [%STATUS%]==[n] ( 
 CALL :getCurrentDateTimeWithArg "%~0 ERROR EXIST - EXIT" >> %BACKUP_LOG%
 EXIT /B 0
)
CALL :getCurrentDateTimeWithArg "%~0 USER - `%~2`" >> %BACKUP_LOG%

%EXP_APP% %~2/%~3@%ORACLE_HOST%:%ORACLE_PORT%/%CURRENT_SID% file=%~2.DMP log=%~2.LOG buffer=60000 rows=y consistent=y compress=y feedback=1000 grants=y >nul 2>&1
Rem  >nul 2>&1

CALL :getCurrentDateTimeWithArg "%~0 ERROR LEVEL - `%ERRORLEVEL%`" >> %BACKUP_LOG%

IF %ERRORLEVEL% NEQ 0 (
 CALL :getCurrentDateTimeWithArg "%~0 FAILED TO CREATE BACKUP USER - `%~2`" >> %BACKUP_LOG%
 SET %~1=n
 EXIT /B 1
) ELSE (
 CALL :getCurrentDateTimeWithArg "%~0 SUCCESSFULLY CREATED BACKUP USER - `%~2`"  >> %BACKUP_LOG%
)
EXIT /B 0
:createArch
CALL :getCurrentDateTimeWithArg %~0 >> %BACKUP_LOG%
if [%STATUS%]==[n] ( 
 CALL :getCurrentDateTimeWithArg "%~0 ERROR EXIST - EXIT" >> %BACKUP_LOG%
 EXIT /B 0
)
%ZIP_APP% %ZIP_APP_OPTIONS% %~2 %~3 %~4 >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
 CALL :getCurrentDateTimeWithArg "%~0 FAILED TO CREATE ARCHIVES - `%~2`" >> %BACKUP_LOG%
 SET %~1=n
 EXIT /B 1
) ELSE (
 CALL :getCurrentDateTimeWithArg "%~0 SUCCESSFULLY CREATED ARCHIVES - `%~2`"  >> %BACKUP_LOG%
)
EXIT /B 0
:externalCopy
CALL :getCurrentDateTimeWithArg "%~0 SRC - `%~2` EXT DIR - `%~3` EXT FILE - `%~4`" >> %BACKUP_LOG%
if [%STATUS%]==[n] ( 
 CALL :getCurrentDateTimeWithArg "%~0 ERROR EXIST - EXIT" >> %BACKUP_LOG%
 EXIT /B 0
)
if [%~2]==[] ( 
 CALL :getCurrentDateTimeWithArg "SET %~0 ARG2 - file to copy `%~2`"  >> %BACKUP_LOG%
 SET %~1=n
 EXIT /B 1
) 
if ["%~3"]==[] ( 
 CALL :getCurrentDateTimeWithArg "SET %~0 ARG3 - empty directory where to copy `%~3`"  >> %BACKUP_LOG%
 SET %~1=n
 EXIT /B 1
)
if ["%~4"]==[] ( 
 CALL :getCurrentDateTimeWithArg "SET %~0 ARG3 - empty new file to copy `%~4`"  >> %BACKUP_LOG%
 SET %~1=n
 EXIT /B 1
)
CALL :exist %~1 , %~2
if [%STATUS%]==[n] ( 
 CALL :getCurrentDateTimeWithArg "%~0 ERROR EXIST - EXIT" >> %BACKUP_LOG%
 EXIT /B 0
)
CALL :exist %~1 , %~3
if [%STATUS%]==[n] ( 
 CALL :getCurrentDateTimeWithArg "%~0 ERROR EXIST - EXIT" >> %BACKUP_LOG%
 EXIT /B 0
)
copy /Y %~2 /D %~3%~4 >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
 CALL :getCurrentDateTimeWithArg "%~0 FAILED TO EXECUTE - `%~2`" >> %BACKUP_LOG%
 SET %~1=n
 EXIT /B 1
) ELSE (
 CALL :getCurrentDateTimeWithArg "%~0 SUCCESSFULLY EXECUTE - `%~2`"  >> %BACKUP_LOG%
)
EXIT /B 0
:: ################### FUNCTION exists() ###################
:exist
CALL :getCurrentDateTimeWithArg %~0 >> %BACKUP_LOG%
:: %~1 = status
:: %~2 = file

::ECHO STATUS = %STATUS%
CALL :getCurrentDateTimeWithArg %~2 >> %BACKUP_LOG%

if [%STATUS%]==[n] ( 
 CALL :getCurrentDateTimeWithArg "ERROR EXIST %~0 - EXIT" >> %BACKUP_LOG%
 EXIT /B 0
) 
if ["%~2"]==[] ( 
 CALL :getCurrentDateTimeWithArg "%~0 SET ARG1 FILE - `%~2`" >> %BACKUP_LOG%
 SET %~1=n
:: EXIT
EXIT
) 
IF EXIST "%~2" ( 
 CALL :getCurrentDateTimeWithArg "%~0 FILE `%~2` EXIST - CONTINUE" >> %BACKUP_LOG%
) ELSE (
 CALL :getCurrentDateTimeWithArg "%~0 ERROR FILE - `%~2` NOT EXIST" >> %BACKUP_LOG%
 SET %~1=n
EXIT /B 1
)

EXIT /B 0
:MAIN

CALL :getCurrentDateTimeWithArg "%~0 SCRIPT ENDS" >> %BACKUP_LOG%
ENDLOCAL
Rem PAUSE
EXIT /B 0
Rem exit