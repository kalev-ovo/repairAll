@echo off
REM 家政维修服务平台 - 环境变量配置（以管理员身份运行）
REM 或手动添加到：系统属性 → 环境变量 → 用户变量

setx FLUTTER_HOME "C:\flutter"
setx PUB_HOSTED_URL "https://pub.flutter-io.cn"
setx FLUTTER_STORAGE_BASE_URL "https://storage.flutter-io.cn"

REM 将 Flutter 添加到 PATH（需要手动操作或管理员权限）
echo.
echo 请确保以下路径在 PATH 中：
echo   C:\flutter\bin
echo   C:\Users\%USERNAME%\AppData\Local\Android\Sdk\cmdline-tools\latest\bin
echo.
echo 操作步骤:
echo   1. Win+R → sysdm.cpl
echo   2. 高级 → 环境变量
echo   3. 编辑 Path → 添加上述两行
echo.
echo 环境变量已设置。重新打开终端生效。
pause
