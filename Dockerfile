# escape=`
FROM microsoft/aspnet
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

RUN $password = ConvertTo-SecureString -AsPlainText Qwerty123 -Force; `
    New-LocalUser -Name Tester -Password $password; `
    Add-LocalGroupMember -Group Administrators -Member Tester; `
    Install-Module Saritasa.WinRM -Force; `
    Install-WinrmHttps;

EXPOSE 80
EXPOSE 5986
EXPOSE 8172
