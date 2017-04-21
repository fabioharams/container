Scenario
========

This document is intended to deploy a Windows Container using "Real
World" features on IIS like SSL, URL rewrite, Host Header, .Net
Framework 2.0, 3.5, etc. You can use this document to migrate your Web Site
running on Windows Server 2008/2012/2016 to Windows Containers on
Windows Server 2016 with Docker. Also this document can be used to validate the migration to Windows Container.

The steps listed on this documentation were developed with Rodrigo Immaginario (Microsoft Regional Director and MVP)

Requirements:
-------------

-   Use an Windows Server 2016 (with Desktop Experience) as a HOST and
    install IIS Management Console. To facilitate your deployment is
    recommended to use the image on Microsoft Azure containing Windows
    Server 2016 with Containers.
-   Update the HOST and make sure that update
    [KB4015217](http://www.catalog.update.microsoft.com/Search.aspx?q=kb4015217)
    is included. This update enable support for Docker Swarm and other
    enhancements required to work properly
-   All these steps use Windows Server Core as a container image
-   Create a local folder on HOST (eg. C:\SHARED) to use during setup.
    This folder will be used to exchange files to Container in a easy
    way

Step 1: Prepare the container image
----------------------------

1) Open PowerShell and execute the following command to download the
base image: 

    docker pull windowsservercore

It's very important to use the latest image from Docker Hub because the update KB4015217 is applied. 

2) Create your container using an image from Docker Hub containing .Net
Framework 3.5 .The following command will create a new container (using
an image with .Net Framework 3.5 from Docker Hub) with the name web-01,
map the local folder (C:\\SHARED) on HOST to container and will open a
command prompt 

    docker run -it --name web-01 -v c:\\shared:c:\\shared microsoft/dotnet-framework:3.5

3) Using the command prompt opened by the previous command then execute PowerShell: 

    powershell

4) List all features installed inside the container

    get-windowsfeature

5) Execute the following commands to install IIS Features. To reduce
time installing each feature then you can include the parameter IncludeAllSubfeature 
```
 Install-WindowsFeature -name Web-Server -IncludeManagementTools 
 Install-WindowsFeature -name Web-Common-Http -IncludeAllSubfeature 
 Install-WindowsFeature -name Web-Health -IncludeAllSubFeature 
 Install-WindowsFeature -name Web-Performance -IncludeAllSubFeature
 Install-WindowsFeature -name Web-Security -IncludeAllSubFeature 
 Install-WindowsFeature -name Web-Mgmt-Tools -IncludeAllSubFeature 
 Install-WindowsFeature -name Web-Scripting-Tools -IncludeAllSubFeature 
 Install-WindowsFeature -name Web-App-Dev -IncludeAllSubFeature
```

TIP: These features can vary according to what do you want to install.If you want to install each feature individually then execute the command Get-WindowsFeature and use the column Name (not display name)

6) Change the value of Registry Key. This step allow to connect remotely via IIS Management Console via HOST

    New-ItemProperty -Path HKLM:\software\microsoft\WebManagement\Server -name EnableRemoteManagement -Value 1 -Force

7) Create a local user inside the container. This user will be used to connect remotely via IIS Management Console. On this example we will create a local user called FabioH with the password Pa$$w0rd and we will include on local administrators group. This step is very important because the user created will be available only inside this Container (if you check on your HOST you cannot see this user)

    net user FabioH Pa$$w0rd /add
    net localgroup administrators fabioh /add

8) Stop IIS services

    net stop iisadmin
    net stop w3svc
    net stop wmsvc

9) Start IIS services
    net start iisadmin
    net start w3svc
    net start wmsvc

10) Exit from container. The first command will exit from PowerShell and the second command will exit from CMD Prompt, returning to console on HOST.

    exit
    exit

11) Stop the container and commit changes to a new image with the name web-image1.

    docker stop web-01
    docker commit web-01 web-image1

12) Remove the container stopped

    docker rm web-01

13) Restart the HOST

    shutdown /r /t 0


## Create the container using the image

After the creation of the image then we can start creating the container and update image

1) Create new container using image generated previously, binding ports 80 + 443 and mapping Shared Folder on HOST

    docker run -it --name web-02 -v c:\shared:c:\shared -p 80:80 443:443 web-image1

2) Verify the IP Address assigned to container
- option 1: docker exec web-02 web-02
- option 2: list all containers and take note of ContainerID of web-02
- - docker ps -a
- check ip address assigned
- - docker inspect -f "{{ .NetworkSettings.Networks.nat.IPAddress }}" ContainerID

3) Open IIS Management Console on HOST and then connect using the ip address of the container

TIP: if you cannot connect then check if the wmsvc is already started on container. You can verify using these commands:

    get-service

4) Once you are connected then you can configure a lot of settings

5) Install [URL Rewrite](https://download.microsoft.com/download/C/9/E/C9E8180D-4E51-40A6-A9BF-776990D8BCA9/rewrite_amd64.msi) inside the container

- Option 1: From HOST: download URL Rewrite from internet and copy to the folder C:\SHARED
- Option 2: From HOST: download URL Rewrite from internet and copy to container using command "docker cp"

TIP: download URL Rewrite inside the container using Powershell
- Invoke-WebRequest https://download.microsoft.com/download/C/9/E/C9E8180D-4E51-40A6-A9BF-776990D8BCA9/rewrite_amd64.msi -OutFile C:\teste\rewrite_amd64.msi

Command line to install URL in silent mode

    msiexec.exe /i c:\shared\rewrite_amd64.msi /passive /rd /s /q cc:\install

TIP: you can remotely install using docker command: docker exec web-02 msiexec.exe /i c:\shared\rewrite_amd64.msi /passive /rd /s /q cc:\install

6) Copy and install certificate inside the container. On this example we decided to use a PFX file (with password) because is the best way to import the certificate. This step must be accomplished inside the container

    certutil -importpfx -p "123456" "C:/temp/Certificate.pfx"

7) Copy the content of your web site to container

- Option 1: use docker cp to copy the folder from your HOST to your container
- Option 2: use the parameter docker run -v to mount a directory from your HOST to container

8) OPTIONAL: you can enable Windows Update on container and this procedure will ensure that new fixes/updates are applied to container

- Option 1: if you are disconnected from the container then you can reconnect again using command docker exec

```
 - docker exec -it web-01 cmd
 Change the startup of the service to automatic or manual (default = disabled)
 - Set-Service wuauserv -startupType automatic
 Start the service
 - net start wuauserv
 Execute one of the procedures below to update your container
 - using PowerShell
 - - Install-Module PSWindowsUpdate
 - Execute the script from [MSDN](https://msdn.microsoft.com/en-us/library/aa387102(VS.85).aspx) and save as a VBS file
 - - cscript WindowsUpdate.vbs
```

9. After you finish these settings then you can create a new image

    docker stop web-01
    docker commit web-01 web-image2

10. Check if the new image was created

    docker images

11. Create new container based on this new image.

    docker run -it --name WEB-03 -v c:\shared:c:\shared -p 80:80 -p 443:443 web-image2



## Steps using Dockerfile (automatic deployment)

These are the steps to use on your dockerfile. Remember that the steps below does not contain procedures and specific settings via IIS Management Console.

```
# Inform image from Docker Hub. This image bellow has .Net Framework 3.5 (and 2.0). If you want to use only .Net Framework 4.6 then use the option 4.6 in the end of the command. This image will depend of windowsservercore
FROM microsoft/dotnet-framework:3.5

# Execute the commands to install IIS Features
RUN powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools \
RUN powershell.exe Install-WindowsFeature -Name Web-Common-Http -IncludeAllSubFeature \
RUN powershell.exe Install-WindowsFeature -name Web-Health -IncludeAllSubFeature \
RUN powershell.exe Install-WindowsFeature -name Web-Health -IncludeAllSubFeature \
RUN powershell.exe Install-WindowsFeature -Name Web-Performance -IncludeAllSubFeature \
RUN powershell.exe Install-WindowsFeature -name Web-Security -IncludeAllSubFeature \
RUN powershell.exe Install-WindowsFeature -name Web-Mgmt-Tools -IncludeAllSubFeature \
RUN powershell.exe Install-WindowsFeature -name Web-Scripting-Tools -IncludeAllSubFeature \
RUN powershell.exe Install-WindowsFeature -name Web-App-Dev -IncludeAllSubFeature 

# Enable Registry Key to allow IIS Remote Management
RUN powershell.exe New-ItemProperty -Path HKLM:\software\microsoft\WebManagement\Server -Name EnableRemoteManagement -Value 1 -Force

# Create local user and include on local administrators group
RUN net user fabioh Pa$$w0rd /add \
RUN net localgroup administrators fabioh /add

# Stop IIS Services
RUN net stop iisadmin \
RUN net stop w3svc \
RUN net stop wmsvc

# Start IIS Services
RUN net start iisadmin \
RUN net start w3svc \
RUN net start wmsvc

# Download and install URL Rewrite
RUN Powershell.exe New-item c:\teste \
RUN Powershell.exe Invoke-WebRequest https://download.microsoft.com/download/C/9/E/C9E8180D-4E51-40A6-A9BF-776990D8BCA9/rewrite_amd64.msi -OutFile C:\teste\rewrite_amd64.msi \
RUN msiexec.exe /i c:\teste\rewrite_amd64.msi /passive /rd /s /q c:\install

# Copy PFX file (located on HOST on C:\PFX) to comtainer and install.
ADD c:\teste\certificado.pfx c:\teste\certificado.pfx \
RUN certutil -importpfx -p "123456" "c:\teste\certificado.pfx"

# Optional - enable Windows Update on container, You can use the script from [MSDN](https://msdn.microsoft.com/en-us/library/aa387102(VS.85).aspx) and with the name windowsupdate.vbs. This step is not required because when you execute the command ===docker run=== then a new version is checked from Docker Hub. 
RUN Set-Service wuauserv -startupType automatic \
RUN net start wuauserv
ADD c:\teste\windowsupdate.vbs c:\teste\windowsupdate.vbs
RUN cscript WindowsUpdate.vbs
```
