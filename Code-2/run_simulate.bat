@echo off
:: Disable command echoing for a cleaner interface

:: ==========================================
:: 1. Configuration
:: ==========================================
:: Note: Ensure your conda environment is named 'draw'
set ENV_NAME=draw

:: Automatically locate the conda installation path
:: If automatic detection fails, you may need to manually specify the path below
for /f "delims=" %%i in ('where conda') do set CONDA_EXE=%%i
set CONDA_ROOT=%CONDA_EXE:Scripts\conda.exe=%

:: ==========================================
:: 2. Activate Environment
:: ==========================================
echo [INFO] Activating conda environment: %ENV_NAME%...

:: Use 'call' to invoke conda.bat to activate the environment without breaking the script
call "%CONDA_ROOT%\condabin\conda.bat" activate %ENV_NAME%

:: ==========================================
:: 3. Run Python Script
:: ==========================================
echo [INFO] Running DP algorithm...

:: Please replace main.py with your actual main script filename
python simulate.py

:: ==========================================
:: 4. Finish
:: ==========================================
echo [INFO] Done.
pause