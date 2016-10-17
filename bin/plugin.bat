@ECHO OFF

set name=%~1
set encoding=unicode
if "%~2" == "ansi" set encoding=ansi

upx --all-methods --compress-icons=0 Win32\Release\%name%
SET ERROR=%ERRORLEVEL%
if %ERRORLEVEL% == 2 SET ERROR=0
if not %ERROR% == 0 pause > NUL

upx --all-methods --compress-icons=0 Win64\Release\%name%
SET ERROR=%ERRORLEVEL%
if %ERRORLEVEL% == 2 SET ERROR=0
if not %ERROR% == 0 pause > NUL

echo Copiyng %encoding% files
if not exist ".\x86-%encoding%" mkdir ".\x86-%encoding%"
if not exist ".\x64-%encoding%" mkdir ".\x64-%encoding%"
copy /Y "Win32\Release\%name%" ".\x86-%encoding%\"
copy /Y "Win64\Release\%name%" ".\x64-%encoding%\"