@echo off
echo Activating chatbot_env virtual environment...
call chatbot_env\Scripts\activate.bat
echo.
echo Starting the chatbot application...
echo.
streamlit run chatbot.py
pause
