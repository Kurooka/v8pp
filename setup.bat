IF EXIST "depot_tools"(
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
)

set PATH=%PATH%;%CD%\depot_tools
fetch v8

