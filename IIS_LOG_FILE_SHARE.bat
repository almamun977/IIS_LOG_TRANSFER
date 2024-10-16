cd /
D:
:: goto IIS file source location
cd D:\vFocus_Log\W3SVC1
:: get required file name

:: transfer file to temp location
setlocal movetotemplocation
for /f "skip=1 delims=" %%F in ('dir *.log /b/a-d/o-d') do (
	move /Y D:\vFocus_Log\W3SVC1\%%F D:\vFocus_Log\W3SVC1\Temp\%%F 
)
endlocal

:: Create executable for transfering file into required location
cd D:\vFocus_Log\W3SVC1\Temp

::Retry Machanism and logging process Start
set retrytime=0
:retryprocess
if %retrytime%==3 set retrytime=4
if %retrytime%==2 set retrytime=3
if %retrytime%==1 set retrytime=2
if %retrytime%==0 set retrytime=1

setlocal transfertoftp
for /f  "delims=" %%F in ('dir *.log /b/a-d/o-d') do (	
	echo %%F - start - %date% %time%>>list.txt	
	REM change SFTP_USER_NAME, SFTP_USER_PASS, HOST_IP_OR_NAME, default port 22
	echo open sftp://SFTP_USER_NAME:SFTP_USER_PASS@HOST_IP_OR_NAME:22>ftp.txt		
	echo lcd "cd D:\vFocus_Log\W3SVC1\Temp">>ftp.txt
	echo cd ../..>>ftp.txt
	REM SFTP lcation where log file will be transfered
	echo cd /data01/cdr/salcom/salesapp/rso_iis/GZVWDMS01>>ftp.txt	
	echo put %%F>>ftp.txt
	echo bye>>ftp.txt
	
	::sftp file export execution
	echo --------------------%%F file - execution started - %date% %time% -------------------->lastexecutionlog.txt
	REM YOU winscp.com file path
	"D:\RSO_APP_SYSTEM_MONITORING\IIS_LOG_FILE_SIZE\WinSCP\winscp.com" /script=ftp.txt >> lastexecutionlog.txt	
	echo --------------------%%F file - execution completed - %date% %time% -------------------->>lastexecutionlog.txt
	
	echo ---------------------------------------->>successexecutionlog.txt
	echo ---------------------------------------->>errorexecutionlog.txt
	find /c "binary" lastexecutionlog.txt > NUL && copy /b successexecutionlog.txt + lastexecutionlog.txt successexecutionlog.txt
	find /c "binary" lastexecutionlog.txt > NUL || copy /b errorexecutionlog.txt + lastexecutionlog.txt errorexecutionlog.txt
	:: move file to Backup folder
	find /c "binary" lastexecutionlog.txt > NUL && move /Y %%F D:\vFocus_Log\W3SVC1\Backup\%%F 

	echo completed - %date% %time%>>list.txt
)
endlocal

if %retrytime%==3 goto retryprocess
if %retrytime%==2 goto retryprocess
if %retrytime%==1 goto retryprocess
:: Retry Machanism and logging process End


:: delete more that 5 days old files from storage location
forfiles /p "D:\vFocus_Log\W3SVC1\Backup" /s /m *.* /D -5 /C "cmd /c del @path"