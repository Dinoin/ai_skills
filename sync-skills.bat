@echo off
echo Syncing skill files to Copilot skills folder...

REM Source and target directories
set SOURCE_DIR=%~dp0
set TARGET_DIR=C:\Users\Dinoin_Chen\.copilot\skills

REM Ensure target directory exists
if not exist "%TARGET_DIR%" (
    echo Creating target directory: %TARGET_DIR%
    mkdir "%TARGET_DIR%"
)

REM Sync all root-level skill folders (exclude .github and .git)
echo Copying skill folders from %SOURCE_DIR% to %TARGET_DIR%
for /d %%d in ("%SOURCE_DIR%*") do (
    if /I not "%%~nxd"==".github" (
        if /I not "%%~nxd"==".git" (
            echo Copying %%~nxd...
            xcopy "%%d" "%TARGET_DIR%\%%~nxd\" /E /I /Y /Q > nul
            if errorlevel 1 (
                echo Error copying %%~nxd
            ) else (
                echo Successfully copied %%~nxd
            )
        )
    )
)

echo.
echo Skill sync completed!
echo.
