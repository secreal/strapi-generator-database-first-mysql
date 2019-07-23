@echo off
@title Generator Strapi
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
pushd %~dp0
setlocal EnableExtensions EnableDelayedExpansion

color 0A

::check Bootstrap
reg add "HKCU\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled /t REG_DWORD /d 1 /f >nul
::where /q mysql || SET errorMessage=mysql.exe tidak ditemukan, silahkan masukkan ke path terlebih dahulu && goto errorControl

::Set Environment
set newline=^echo:

:: ============================================= database chooser =======================================================
:dua
Echo Choose Server:
SET serverList=1
if exist serverList.db (
for /f "delims=" %%x in (serverList.db) do (
	Echo !serverList!. %%x
	set /a serverList+=1
))
if %serverList%==1 Echo ^(Server list still empty^! please add new server^)
Echo [+] add server
Echo [-] remove server
set /a serverList-=1
set /p pilihan=type number (1-!serverList!):
set pilihan=%pilihan:~0,2%
Set _tempvar=0
if "%pilihan%"=="+" GOTO :tambahServer
if "%pilihan%"=="-" GOTO :hapusServer
If %pilihan% gtr !serverList! Set _tempvar=1
If %pilihan% lss 1 Set _tempvar=1
if %_tempvar% EQU 1 GOTO :dua
set pilihServer=1
if exist serverList.db (
for /f "delims=" %%x in (serverList.db) do (
	if !pilihServer!==!pilihan! SET namaServer=%%x
	set /a pilihServer+=1
)) else (Echo Sorry, list server still empty!)
goto :tiga

:tambahServer
cls
Echo Please insert your server name with port
Echo default port of mysql was 3306 ex: localhost -P3306
set /P serverBaru=:
echo !serverBaru! >> serverList.db
cls
goto :dua

:hapusServer
cls
set hapusSatuServer=1
SET serverList=1
Echo Pilih yg mau didelete
for /f "delims=" %%x in (serverList.db) do (
	Echo !serverList!. %%x
	set /a serverList+=1
)
set /p d1=:
set hapusSatuServer=1
for /f "delims=" %%x in (serverList.db) do (
	if NOT !hapusSatuServer!==!d1! Echo %%x >> tempserverList.db
	set /a hapusSatuServer+=1
)
del serverList.db
ren tempserverList.db serverList.db
cls
goto :dua

::Login method
:tiga

:userName
set /P usernameDB=Enter Username: 
IF [!usernameDB!] == [] GOTO :userName
:passWord
Set /P "passwordDB=Enter a Password:" < Nul
Call :PasswordInput
set passwordDB=!Line!
IF [!passwordDB!] == [] GOTO :passWord
Set userlogin=-u!usernameDB!
set MYSQL_PWD=!passwordDB!
goto :empat


:: choose database
:empat
@echo:
Echo choose database:
set /a x = 0
FOR /F  %%S IN ('mysql -h %namaServer% %userlogin% -s -e "show databases;"') DO (
if "%%S"=="Msg" Echo Login ke database gagal && goto :dua
if "%%S"=="HResult" Echo Login ke database gagal && goto :dua
if not "%%S"=="information_schema" (
if not "%%S"=="performance_schema" (
if not "%%S"=="mysql" (
if not "%%S"=="phpmyadmin" (
set /a x += 1
Echo !x!. %%S ))))
)
set /p pilihan=type number (1-%x%):
Set _tempvar=0
If %pilihan% GTR %x% Set _tempvar=1
If %pilihan% LSS 1 Set _tempvar=1
If %_tempvar% EQU 1 goto :empat
set /a x = 0
FOR /F  %%S IN ('mysql -h %namaServer% %userlogin% -s -e "show databases;"') DO (
if not "%%S"=="information_schema" (
if not "%%S"=="performance_schema" (
if not "%%S"=="mysql" (
if not "%%S"=="phpmyadmin" (
set /a x += 1 ))))
IF !pilihan! EQU !x! SET namaDatabase=%%S)
goto :lima

:: choose table
:lima
@echo:
Echo Please select the table to be generated, delete the unnecessary ones
Echo [press enter to open the tableList.log]
pause >nul
mysql -h %namaServer% %userlogin% %namaDatabase% -s -e "show tables;" >tableList.log
goto :enam

:enam
tableList.log
@echo:
Echo [Please change and save tableList.log then press enter to continue]
pause >nul
for /f %%x in (tableList.log) do echo %%x
set /p pilihan=Is the list correct (y/n)?
IF "%pilihan%" == "y" GOTO :enam

:enam
::generate semua kecuali model.json
IF not EXIST api (mkdir api)

for /f %%x in (tableList.log) do (
SET nama_tabel=%%x
:: besarkan huruf depan
CALL :FirstUp result !nama_tabel!
:: ganti _ dengan spasi
SET NamaTabel=!result:_= !
:: besarkan huruf depan setelah _
CALL :TCase NamaTabel
:: gabungkan jadi camel case
SET NamaTabel=!NamaTabel: =!
echo generating !NamaTabel!
IF not EXIST api\!NamaTabel! (mkdir api\!NamaTabel!)
IF not EXIST api\!NamaTabel!\config (mkdir api\!NamaTabel!\config)
IF not EXIST api\!NamaTabel!\controllers (mkdir api\!NamaTabel!\controllers)
IF not EXIST api\!NamaTabel!\models (mkdir api\!NamaTabel!\models)
IF not EXIST api\!NamaTabel!\services (mkdir api\!NamaTabel!\services)
set pathconfig=api\!NamaTabel!\config\
set pathcontrollers=api\!NamaTabel!\controllers\
set pathmodels=api\!NamaTabel!\models\
set pathservices=api\!NamaTabel!\services\

set filenameconfig=!pathconfig!routes.json
set filenamecontrollers=!pathcontrollers!!NamaTabel!.js
set filenamemodels=!pathmodels!!NamaTabel!.js
set filenamemodelssettings=!pathmodels!!NamaTabel!.settings.json
set filenameservices=!pathservices!!NamaTabel!.js

echo {"routes": [{"method": "GET", "path": >!filenameconfig!
echo "/!nama_tabel!", "handler": "!NamaTabel!.find", "config": {"policies": []}},{ "method": "GET", "path": >>!filenameconfig!
echo "/!nama_tabel!/count", "handler": "!NamaTabel!.count", "config": { "policies": [] } }, { "method": "GET", "path": >>!filenameconfig!
echo "/!nama_tabel!/:id", "handler": "!NamaTabel!.findOne", "config": { "policies": [] } }, { "method": "POST", "path": >>!filenameconfig!
echo "/!nama_tabel!", "handler": "!NamaTabel!.create", "config": { "policies": [] } }, { "method": "PUT", "path": >>!filenameconfig!
echo "/!nama_tabel!/:id", "handler": "!NamaTabel!.update", "config": { "policies": [] } }, { "method": "DELETE", "path": >>!filenameconfig!
echo "/!nama_tabel!/:id", "handler": "!NamaTabel!.delete", "config": { "policies": [] } } ] } >>!filenameconfig!

echo 'use strict'^;>!filenamecontrollers!
echo.>>!filenamecontrollers!
echo /**>>!filenamecontrollers!
echo  * Read the documentation ^(https://strapi.io/documentation/3.0.0-beta.x/guides/controllers.html#core-controllers^)>>!filenamecontrollers!
echo  * to customize this controller>>!filenamecontrollers!
echo  */>>!filenamecontrollers!
echo.>>!filenamecontrollers!
echo module.exports ^= {}^;>>!filenamecontrollers!

echo 'use strict'^;>!filenamemodels!
echo.>>!filenamemodels!
echo /**>>!filenamemodels!
echo  * Lifecycle callbacks for the `!NamaTabel!` model.>>!filenamemodels!
echo  */>>!filenamemodels!
echo.>>!filenamemodels!
echo module.exports ^= {>>!filenamemodels!
echo   // Before saving a value.>>!filenamemodels!
echo   // Fired before an `insert` or `update` query.>>!filenamemodels!
echo   // beforeSave: async ^(model, attrs, options^) ^=^> {},>>!filenamemodels!
echo.>>!filenamemodels!
echo   // After saving a value.>>!filenamemodels!
echo   // Fired after an `insert` or `update` query.>>!filenamemodels!
echo   // afterSave: async ^(model, response, options^) ^=^> {},>>!filenamemodels!
echo.>>!filenamemodels!
echo   // Before fetching a value.>>!filenamemodels!
echo   // Fired before a `fetch` operation.>>!filenamemodels!
echo   // beforeFetch: async ^(model, columns, options^) ^=^> {},>>!filenamemodels!
echo.>>!filenamemodels!
echo   // After fetching a value.>>!filenamemodels!
echo   // Fired after a `fetch` operation.>>!filenamemodels!
echo   // afterFetch: async ^(model, response, options^) ^=^> {},>>!filenamemodels!
echo.>>!filenamemodels!
echo   // Before fetching all values.>>!filenamemodels!
echo   // Fired before a `fetchAll` operation.>>!filenamemodels!
echo   // beforeFetchAll: async ^(model, columns, options^) ^=^> {},>>!filenamemodels!
echo.>>!filenamemodels!
echo   // After fetching all values.>>!filenamemodels!
echo   // Fired after a `fetchAll` operation.>>!filenamemodels!
echo   // afterFetchAll: async ^(model, response, options^) ^=^> {},>>!filenamemodels!
echo.>>!filenamemodels!
echo   // Before creating a value.>>!filenamemodels!
echo   // Fired before an `insert` query.>>!filenamemodels!
echo   // beforeCreate: async ^(model, attrs, options^) ^=^> {},>>!filenamemodels!
echo.>>!filenamemodels!
echo   // After creating a value.>>!filenamemodels!
echo   // Fired after an `insert` query.>>!filenamemodels!
echo   // afterCreate: async ^(model, attrs, options^) ^=^> {},>>!filenamemodels!
echo.>>!filenamemodels!
echo   // Before updating a value.>>!filenamemodels!
echo   // Fired before an `update` query.>>!filenamemodels!
echo   // beforeUpdate: async ^(model, attrs, options^) ^=^> {},>>!filenamemodels!
echo.>>!filenamemodels!
echo   // After updating a value.>>!filenamemodels!
echo   // Fired after an `update` query.>>!filenamemodels!
echo   // afterUpdate: async ^(model, attrs, options^) ^=^> {},>>!filenamemodels!
echo.>>!filenamemodels!
echo   // Before destroying a value.>>!filenamemodels!
echo   // Fired before a `delete` query.>>!filenamemodels!
echo   // beforeDestroy: async ^(model, attrs, options^) ^=^> {},>>!filenamemodels!
echo.>>!filenamemodels!
echo   // After destroying a value.>>!filenamemodels!
echo   // Fired after a `delete` query.>>!filenamemodels!
echo   // afterDestroy: async ^(model, attrs, options^) ^=^> {}>>!filenamemodels!
echo }^;>>!filenamemodels!

echo {"connection": "default", "collectionName": "!nama_tabel!", "info": {"name": "!NamaTabel!", "description": ""},>!filenamemodelssettings!
echo   "options": {"increments": false, "comment": ""},>>!filenamemodelssettings!
echo   "attributes": {>>!filenamemodelssettings!
set /a x=0
FOR /F %%S IN ('mysql -h %namaServer% %userlogin% -s -e "SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '!namaDatabase!' AND TABLE_NAME = '!nama_tabel!';"') DO (
    set /a x += 1
    SET dataType!x!=%%S)
set /a x=0
FOR /F %%S IN ('mysql -h %namaServer% %userlogin% -s -e "SELECT IS_NULLABLE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '!namaDatabase!' AND TABLE_NAME = '!nama_tabel!';"') DO (
    set /a x += 1
    SET nullable!x!=%%S)
set /a x=0
FOR /F %%S IN ('mysql -h %namaServer% %userlogin% -s -e "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '!namaDatabase!' AND TABLE_NAME = '!nama_tabel!';"') DO (
    set /a x += 1
    SET fieldName!x!=%%S)
	set pertama=
FOR /L %%i IN (1,1,!x!) DO (
	set tipedata=
	if "!dataType%%i!" == "double" set tipedata=float
	if "!dataType%%i!" == "bigint" set tipedata=biginteger
	if "!dataType%%i!" == "int" set tipedata=integer
	if "!dataType%%i!" == "tinyint" set tipedata=boolean
	if "!dataType%%i!" == "datetime" set tipedata=date
	if "!dataType%%i!" == "timestamp" set tipedata=date
	if "!dataType%%i!" == "varchar" set tipedata=string
	if "!dataType%%i!" == "longtext" set tipedata=json
	if "!dataType%%i!" == "char" set tipedata=string
echo     !pertama!"!fieldName%%i!": { "type": "!tipedata!"}>>!filenamemodelssettings!
set pertama=,

)
echo }}>>!filenamemodelssettings!

echo 'use strict'^;>!filenameservices!
echo.>>!filenameservices!
echo /**>>!filenameservices!
echo  * Read the documentation ^(https://strapi.io/documentation/3.0.0-beta.x/guides/services.html#core-services^)>>!filenameservices!
echo  * to customize this service>>!filenameservices!
echo  */>>!filenameservices!
echo.>>!filenameservices!
echo module.exports ^= {}^;>>!filenameservices!
)

:end
echo done, thank you :D - secreal
pause
exit




























:errorControl
echo %errorMessage%
pause
exit

:PasswordInput
::Author: Carlos Montiers Aguilera
::Last updated: 20150401. Created: 20150401.
::Set in variable Line a input password
For /F skip^=1^ delims^=^ eol^= %%# in (
'"Echo(|Replace.exe "%~f0" . /U /W"') Do Set "CR=%%#"
For /F %%# In (
'"Prompt $H &For %%_ In (_) Do Rem"') Do Set "BS=%%#"
Set "Line="
:_PasswordInput_Kbd
Set "CHR=" & For /F skip^=1^ delims^=^ eol^= %%# in (
'Replace.exe "%~f0" . /U /W') Do Set "CHR=%%#"
If !CHR!==!CR! Echo(&Goto :Eof
If !CHR!==!BS! (If Defined Line (Set /P "=!BS! !BS!" <Nul
Set "Line=!Line:~0,-1!"
)
) Else (Set /P "=*" <Nul
If !CHR!==! (Set "Line=!Line!^!"
) Else Set "Line=!Line!!CHR!"
)
Goto :_PasswordInput_Kbd

:FirstDown
setlocal EnableDelayedExpansion
set "temp=%~2"
set "helper=##aabbccddeeffgghhiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz"
set "first=!helper:*%temp:~0,1%=!"
set "first=!first:~0,1!"
if "!first!"=="#" set "first=!temp:~0,1!"
set "temp=!first!!temp:~1!"
(
    endlocal
    set "result=%temp%"
    goto :eof
)
GOTO :EOF

:FirstUp
setlocal EnableDelayedExpansion
set "temp=%~2"
set "helper=##AABBCCDDEEFFGGHHIIJJKKLLMMNNOOPPQQRRSSTTUUVVWWXXYYZZ"
set "first=!helper:*%temp:~0,1%=!"
set "first=!first:~0,1!"
if "!first!"=="#" set "first=!temp:~0,1!"
set "temp=!first!!temp:~1!"
(
    endlocal
    set "result=%temp%"
    goto :eof
)
GOTO :EOF

:LoCase
:: Subroutine to convert a variable VALUE to all lower case.
:: The argument for this subroutine is the variable NAME.
SET %~1=!%1:A=a!
SET %~1=!%1:B=b!
SET %~1=!%1:C=c!
SET %~1=!%1:D=d!
SET %~1=!%1:E=e!
SET %~1=!%1:F=f!
SET %~1=!%1:G=g!
SET %~1=!%1:H=h!
SET %~1=!%1:I=i!
SET %~1=!%1:J=j!
SET %~1=!%1:K=k!
SET %~1=!%1:L=l!
SET %~1=!%1:M=m!
SET %~1=!%1:N=n!
SET %~1=!%1:O=o!
SET %~1=!%1:P=p!
SET %~1=!%1:Q=q!
SET %~1=!%1:R=r!
SET %~1=!%1:S=s!
SET %~1=!%1:T=t!
SET %~1=!%1:U=u!
SET %~1=!%1:V=v!
SET %~1=!%1:W=w!
SET %~1=!%1:X=x!
SET %~1=!%1:Y=y!
SET %~1=!%1:Z=z!
GOTO:EOF

:TCase
:: Subroutine to convert a variable VALUE to Title Case.
:: The argument for this subroutine is the variable NAME.
FOR %%i IN (" a= A" " b= B" " c= C" " d= D" " e= E" " f= F" " g= G" " h= H" " i= I" " j= J" " k= K" " l= L" " m= M" " n= N" " o= O" " p= P" " q= Q" " r= R" " s= S" " t= T" " u= U" " v= V" " w= W" " x= X" " y= Y" " z= Z") DO CALL SET "%1=%%%1:%%~i%%"
GOTO:EOF

:Trim
set Params=%*
for /f "tokens=1*" %%a in ("!Params!") do EndLocal & set %1=%%b
exit /b