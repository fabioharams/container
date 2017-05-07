# Inform image from Docker Hub. This image bellow has .Net Framework 3.5 (and 2.0). 
# If you want to use only .Net Framework 4.6 then use the option 4.6 in the end of the command. 
# This image will depend of windowsservercore
FROM microsoft/dotnet-framework:3.5

# Execute the commands to install IIS Features
RUN powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools 
RUN powershell.exe Install-WindowsFeature -Name Web-Common-Http -IncludeAllSubFeature 
RUN powershell.exe Install-WindowsFeature -name Web-Health -IncludeAllSubFeature 
RUN powershell.exe Install-WindowsFeature -name Web-Health -IncludeAllSubFeature 
RUN powershell.exe Install-WindowsFeature -Name Web-Performance -IncludeAllSubFeature 
RUN powershell.exe Install-WindowsFeature -name Web-Security -IncludeAllSubFeature 
RUN powershell.exe Install-WindowsFeature -name Web-Mgmt-Tools -IncludeAllSubFeature 
RUN powershell.exe Install-WindowsFeature -name Web-Scripting-Tools -IncludeAllSubFeature 
RUN powershell.exe Install-WindowsFeature -name Web-App-Dev -IncludeAllSubFeature

# Enable Registry Key to allow IIS Remote Management
RUN powershell.exe New-ItemProperty -Path HKLM:\software\microsoft\WebManagement\Server -Name EnableRemoteManagement -Value 1 -Force

# Create local user and include on local administrators group
RUN net user fabioh Pa$$w0rd /add 
RUN net localgroup administrators fabioh /add

# Stop IIS Services
RUN net stop iisadmin 
RUN net stop w3svc 
RUN net stop wmsvc

# Start IIS Services
RUN net start iisadmin 
RUN net start w3svc 
RUN net start wmsvc

# Download and install URL Rewrite
RUN Powershell.exe New-item c:\teste 
RUN Powershell.exe Invoke-WebRequest https://download.microsoft.com/download/C/9/E/C9E8180D-4E51-40A6-A9BF-776990D8BCA9/rewrite_amd64.msi -OutFile C:\teste\rewrite_amd64.msi 
RUN msiexec.exe /i c:\teste\rewrite_amd64.msi /passive /rd /s /q c:\install

# Copy PFX file (located on HOST on C:\PFX) to comtainer and install
ADD c:\teste\certificado.pfx c:\teste\certificado.pfx 
RUN certutil -importpfx -p "123456" "c:\teste\certificado.pfx"

# Optional - enable Windows Update on container, 
# You can use the script from MSDN and with the name windowsupdate.vbs. 
# This step is not required because when you execute the command ===docker run=== 
# then a new version is checked from Docker Hub. 
# Remove the comment if you want to use these commands

# RUN Set-Service wuauserv -startupType automatic 
# RUN net start wuauserv ADD c:\teste\windowsupdate.vbs c:\teste\windowsupdate.vbs RUN cscript WindowsUpdate.vbs