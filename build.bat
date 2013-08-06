@setlocal

@echo off
@prompt $H

rem See if the user has set the FLEX_HOME environment variable
rem If FLEX_HOME set, then use this value
if not "[%FLEX_HOME%]" == "[]" goto FLEX_HOME_set
rem Try to set something reasonable for the default value of FLEX_HOME
set FLEX_HOME=E:\Adobe\ADOBEF~1.5\sdks\4.5.0.20967

:FLEX_HOME_set

set ant.opts=-DFLEX_HOME="%FLEX_HOME%" -DILOG_HOME="D:\PROGRA~1\IBM\ILOG\ELIXIR~1.5TR"

set target=build



rem See if JAVA_HOME is set ('ant' needs it)
if "[%JAVA_HOME%]" == "[]" goto java_home_not_set

rem See if ANT_HOME is set
if "[%ANT_HOME%]" == "[]" goto ant_home_not_set

rem We need to increase the memory, if you use the ANT_OPTS
rem option you may need to add this option to your setting.
if "[%ANT_OPTS%]" == "[]" set ANT_OPTS=-Xmx512m

call "%ANT_HOME%\bin\ant" %ant.opts% %target%
if not errorlevel 1 goto done

echo "Error: failed to %target% the sample
goto error

:java_home_not_set
echo "JAVA_HOME is not set, create an environment variable JAVA_HOME and try again"
goto error

:ant_home_not_set
echo "ANT_HOME is not set, create an environment variable ANT_HOME and try again"
goto error

:error

@rem Could @pause here only on errors

:done

@rem Pause here because sometimes we have errors that the ant task does not detect
@pause

@endlocal
