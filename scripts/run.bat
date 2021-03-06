@echo OFF
setlocal

REM Start a JBoss Data Virtualization and JBoss Fuse environment.
REM
REM This script expects JBoss Fuse to be running in order to start the shopping application
REM
REM author: ankit.b.verma@accenture.com
REM

set PROJECT_HOME=%~dp0
set DV_DIR=%PROJECT_HOME%target\dv
set AMQ_DIR=%PROJECT_HOME%target\amq
set SERVER_CONF_DV=%DV_DIR%\standalone\configuration\
set DV_DIR_OSGI=%DV_DIR:\=/%
set SUPPORT_DIR=%PROJECT_HOME%support
set DV_SUPPORT_DIR=%SUPPORT_DIR%\dv-support
set FUSE_SUPPORT_DIR=%SUPPORT_DIR%\fuse-support
set API_VERSION=v1



del %DV_DIR%\standalone\deployments\*shoppingApplication*.war*

:start
echo Choose the environment you wish to deploy the application...
echo
echo 1) Eap  6.1.0-Beta
echo 2) Fuse 6.2
set /p choice= Enter Your Choice (1,2)?
if '%choice%'=='' echo "%choice%" is not valid please try again
if '%choice%'=='1' goto eap
if '%choice%'=='2' goto fuse6_2
echo.
goto start


:eap
start call %AMQ_DIR%\bin\amq
call mvn -f "%PROJECT_HOME%\projects\shopping-demo-application\pom.xml" versions:set -DnewVersion=%API_VERSION%
call mvn -f "%PROJECT_HOME%\projects\shopping-demo-application\pom.xml" clean install -DskipTests

echo.
echo Starting JBoss Data Virtualization
echo.
start call %DV_DIR%\bin\standalone  -Dkaraf.home=%SERVER_CONF_DV%

goto eapDeployment

:fuse6_2

set FUSE_DIR=%PROJECT_HOME%target\fuse
call mvn -f "%PROJECT_HOME%\projects\shopping-demo-application\pom.xml" clean install -DskipTests
echo.
echo Starting JBoss Data Virtualization
echo.
start call %DV_DIR%\bin\standalone  -Dkaraf.home=%SERVER_CONF_DV%

goto fuseDeployment


:fuseDeployment
set KARAF_LOG=%FUSE_DIR%\data\log\fuse.log
	(	if exist "%KARAF_LOG%" (
				del %KARAF_LOG_6-1%
			)

	start call %FUSE_DIR%\bin\fuse
	echo Starting JBoss Fuse and wait for 60 seconds
	echo.
	timeout 60 /nobreak
	call "%FUSE_DIR%\bin\client.bat" "-h" "127.0.0.1" "-r" "10" "-u" "admin" "-p" "admin" 	"osgi:install -s war:mvn:com.redhat/application-interface/1.0.0-SNAPSHOT/war?Web-ContextPath=%API_VERSION%.shoppingApplication"
)
GOTO :EOF

:eapDeployment
(
	xcopy /Y /Q "%PROJECT_HOME%\projects\shopping-demo-application\application-interface\target\*shoppingApplication.war" "%DV_DIR%\standalone\deployments"
)
