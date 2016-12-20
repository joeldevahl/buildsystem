@echo off

@REM Check for Visual Studio
call set "VSPATH="
if defined VS140COMNTOOLS ( if not defined VSPATH (
	call set "VSPATH=%%VS140COMNTOOLS%%"
) )
if defined VS120COMNTOOLS ( if not defined VSPATH (
	call set "VSPATH=%%VS120COMNTOOLS%%"
) )
if defined VS110COMNTOOLS ( if not defined VSPATH (
	call set "VSPATH=%%VS110COMNTOOLS%%"
) )
if defined VS100COMNTOOLS ( if not defined VSPATH (
	call set "VSPATH=%%VS100COMNTOOLS%%"
) )
if defined VS90COMNTOOLS ( if not defined VSPATH (
	call set "VSPATH=%%VS90COMNTOOLS%%"
) )
if defined VS80COMNTOOLS ( if not defined VSPATH (
	call set "VSPATH=%%VS80COMNTOOLS%%"
) )

@REM check if we already have the tools in the environment
if exist "%VCINSTALLDIR%" (
	goto compile
)

if not defined VSPATH (
	echo You need Microsoft Visual Studio 8, 9, 10, 11, 12, 13 or 15 installed
	pause
	exit
)

@REM set up the environment
if exist "%VSPATH%..\..\vc\vcvarsall.bat" (
	call "%%VSPATH%%..\..\vc\vcvarsall.bat" amd64
	goto compile
)

echo Unable to set up the environment
pause
exit

:compile
bam --dry projgen=true
