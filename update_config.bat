@echo off
echo Generating config.h from .env file...
python generate_config.py
if %ERRORLEVEL% EQU 0 (
    echo Configuration updated successfully!
) else (
    echo Error generating configuration!
)
pause
