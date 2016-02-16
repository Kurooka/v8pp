set PATH=%PATH%;%CD%\depot_tools
set GYP_MSVS_VERSION = 2013
cd v8
gclient sync
python build\gyp_v8 -Dtarget_arch=x64 --depth=. -I../v8_options.gypi tools/gyp/v8.gyp



