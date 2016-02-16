if exist "depot_tools\" (
	echo "not clone"
) else (
	call :gitclone
)


set PATH=%PATH%;%CD%\depot_tools

exit /b

rem =================================================
rem subrutine
rem =================================================
:gitclone
echo "clone for google depot tools"
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
fetch v8
exit /b

