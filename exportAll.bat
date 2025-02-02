@echo off
setlocal

set UT_DIR=C:\UnrealTournament
set OUTPUT_DIR=C:\UnrealTournament\MyAimbot\export

echo Starting source code extraction...

if not exist "%OUTPUT_DIR%" (
    echo Creating output directory: "%OUTPUT_DIR%"
    mkdir "%OUTPUT_DIR%"
)

for %%F in ("%UT_DIR%\System\*.u") do (
    echo Extracting source from: %%F
	
    set PACKAGE_NAME=%%~nF
    set PACKAGE_PATH=%OUTPUT_DIR%\%%~nF
	set CLASS_NAME=%%~nF

	if not exist "%PACKAGE_PATH%" (
        mkdir "%PACKAGE_PATH%"
    )
	"%UT_DIR%\System\ucc" batchexport %%F class uc "%PACKAGE_PATH%"
	
	for %%A in ("%PACKAGE_PATH%\*.uc") do (
		set FILENAME=%%~nA
		if not "%%FILENAME%%"=="ScriptCode" (
			set NEW_NAME=%PACKAGE_PATH%\%%~nA.uc
			if not "%%A"=="%NEW_NAME%" (
				ren "%%A" "%%~nA.uc"
			)
		)
    )
)

echo Source code extraction complete.
echo Files have been saved in "%OUTPUT_DIR%"

pause
endlocal