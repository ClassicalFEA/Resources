@echo off
rem ======================================================================
rem  orun.bat - run an OpenCourant model with one command
rem
rem  Put this file in the OpenCourant folder (next to exec, extlib, ...).
rem
rem  Usage:   orun  model.rad       [threads]   (renamed to model_0000.rad if needed)
rem           orun  model.k         [threads]     (LS-DYNA format)
rem
rem  Runs the Starter, then every Engine file (model_0001.rad, _0002, ...)
rem  in the folder the input file is in. Results are written there too.
rem  Threads defaults to the number of processors on the PC.
rem ======================================================================
setlocal

if "%~1"=="" (
  echo Usage: orun ^<model_0000.rad ^| model.k^> [threads]
  exit /b 1
)
if not exist "%~1" (
  echo Input file not found: %~1
  exit /b 1
)

rem --- OpenCourant environment (taken from this script's location) -----
set "OPENCOURANT_PATH=%~dp0"
set "OPENCOURANT_PATH=%OPENCOURANT_PATH:~0,-1%"
set "RAD_CFG_PATH=%OPENCOURANT_PATH%\hm_cfg_files"
set "RAD_H3D_PATH=%OPENCOURANT_PATH%\extlib\h3d\lib\win64"
set "KMP_STACKSIZE=400m"
set "OMP_STACKSIZE="
set "PATH=%OPENCOURANT_PATH%\extlib\hm_reader\win64;%OPENCOURANT_PATH%\extlib\intelOneAPI_runtime\win64;%OPENCOURANT_PATH%\exec;%PATH%"

if not "%~2"=="" (
  set "OMP_NUM_THREADS=%~2"
) else if not defined OMP_NUM_THREADS (
  set "OMP_NUM_THREADS=%NUMBER_OF_PROCESSORS%"
)

set "STARTER=%OPENCOURANT_PATH%\exec\starter_win64.exe"
set "ENGINE=%OPENCOURANT_PATH%\exec\engine_win64.exe"
if not exist "%STARTER%" ( echo Not found: %STARTER% & exit /b 1 )
if not exist "%ENGINE%"  ( echo Not found: %ENGINE%  & exit /b 1 )

rem --- Work in the input file's folder ----------------------------------
pushd "%~dp1"
set "INPUT=%~nx1"
set "ROOT=%~n1"
if /i not "%~x1"==".rad" goto :named_ok
if /i "%ROOT:~-5%"=="_0000" ( set "ROOT=%ROOT:~0,-5%" & goto :named_ok )

rem --- Name given was an engine file (ROOT_0001.rad): use its starter ---
if /i "%ROOT:~-5%"=="_0001" (
  set "ROOT=%ROOT:~0,-5%"
  goto :have_root
)

rem --- Any other .rad name: work out what it is and rename it -----------
rem     /BEGIN = starter (model) file  -> ROOT_0000.rad
rem     /RUN without /BEGIN = engine   -> ROOT_0001.rad
findstr /b /i /c:"/BEGIN" "%INPUT%" >nul
if not errorlevel 1 (
  call :rename_to "%INPUT%" "%ROOT%_0000.rad" || ( popd & exit /b 1 )
  goto :have_root
)
findstr /b /i /c:"/RUN" "%INPUT%" >nul
if not errorlevel 1 (
  call :rename_to "%INPUT%" "%ROOT%_0001.rad" || ( popd & exit /b 1 )
  goto :have_root
)
echo *** %INPUT% has neither /BEGIN nor /RUN - is it a Radioss input file?
popd & exit /b 1

:have_root
set "INPUT=%ROOT%_0000.rad"
if not exist "%INPUT%" (
  echo *** Starter file %INPUT% not found next to the engine file.
  popd & exit /b 1
)
:named_ok

echo.
echo === OpenCourant: %INPUT%   (%OMP_NUM_THREADS% threads)
echo === Starter ...
"%STARTER%" -i "%INPUT%" -np 1
if errorlevel 1 goto :starter_failed
if not exist "%ROOT%_0000.out" goto :starter_failed

rem --- Single-file deck: engine cards sit in the starter file, ending
rem     with /END/ENGINE. The engine then reads the starter file itself.
if /i "%~x1"==".rad" (
  findstr /b /i /c:"/END/ENGINE" "%INPUT%" >nul && (
    call :engine "%INPUT%" || ( popd & exit /b 1 )
    goto :all_done
  )
)

if not exist "%ROOT%_0001.rad" (
  echo *** No engine file %ROOT%_0001.rad found - check %ROOT%_0000.out
  popd & exit /b 1
)

rem --- Run each engine file in order (_0001, _0002, ...) ----------------
for /f "delims=" %%F in ('dir /b /on "%ROOT%_0*.rad" ^| findstr /v /i "_0000.rad"') do (
  call :engine "%%F" || ( popd & exit /b 1 )
)

:all_done
echo.
echo === Done. Results are in %CD%
popd
exit /b 0

:starter_failed
if exist "%ROOT%_0000.out" (
  echo *** Starter failed - see %CD%\%ROOT%_0000.out
) else (
  echo *** Starter failed before writing any output - see the messages above
)
popd & exit /b 1

:rename_to
if exist "%~2" (
  echo *** Can't rename %~1 to %~2 - a file with that name already exists.
  exit /b 1
)
ren "%~1" "%~2" || exit /b 1
echo === Renamed %~1 to %~2
exit /b 0

:engine
echo.
echo === Engine: %~1
"%ENGINE%" -i "%~1"
if errorlevel 1 (
  echo *** Engine failed on %~1 - see its .out file
  exit /b 1
)
exit /b 0