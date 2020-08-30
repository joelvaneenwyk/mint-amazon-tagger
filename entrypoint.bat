@echo off

::set PYTHON3="C:\Program Files\Python38\python.exe"
set PYTHON3="C:\Program Files (x86)\Microsoft Visual Studio\Shared\Python37_64\python.exe"

echo Initializing Python 3 environment.
%PYTHON3% -m pip uninstall --yes mint-amazon-tagger > nul 2>&1

%PYTHON3% -m pip install --upgrade pip > nul 2>&1

%PYTHON3% -m pip install --user -r "%~dp0requirements\base.txt" > nul 2>&1
%PYTHON3% -m pip install --user -r "%~dp0requirements\windows.txt" > nul 2>&1

::%PYTHON3% setup.py install

echo Launching 'mint-amazon-tagger' CLI.
%PYTHON3% "%~dp0entrypoint.py" %*