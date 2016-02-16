echo off

if exist "depot_tools\" (
	echo "not clone"
) else (
	call :gitclone
)

goto :END

rem =================================================
rem subrutine
rem =================================================

:gitclone

echo "clone for google depot tools"
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
set PATH=%PATH%;%CD%\depot_tools
fetch v8
exit /b

:END
pause
