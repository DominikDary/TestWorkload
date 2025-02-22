# escape=`

# Installer image
FROM mcr.microsoft.com/windows/servercore:ltsc2019-amd64 AS installer

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV ASPNETCORE_VERSION 2.1.12

RUN Invoke-WebRequest -OutFile aspnetcore.zip https://dotnetcli.blob.core.windows.net/dotnet/aspnetcore/Runtime/$Env:ASPNETCORE_VERSION/aspnetcore-runtime-$Env:ASPNETCORE_VERSION-win-x64.zip; `
    $aspnetcore_sha512 = '168da5f714611e73faac29cda8cdf183af2cc9e4a703943a435c385c36f55bd9bb15a1ca75c9bea69eade8c9031f828b3d767a4df0a11ac7e269aaa6ed30ca2b'; `
    if ((Get-FileHash aspnetcore.zip -Algorithm sha512).Hash -ne $aspnetcore_sha512) { `
        Write-Host 'CHECKSUM VERIFICATION FAILED!'; `
        exit 1; `
    }; `
    `
    Expand-Archive aspnetcore.zip -DestinationPath dotnet; `
    Remove-Item -Force aspnetcore.zip


# Runtime image
FROM mcr.microsoft.com/windows/servercore:ltsc2019-amd64

COPY --from=installer ["/dotnet", "/Program Files/dotnet"]

# In order to set system PATH, ContainerAdministrator must be used
USER ContainerAdministrator
RUN setx /M PATH "%PATH%;C:\Program Files\dotnet"
#USER ContainerUser

# Configure web servers to bind to port 80 when present
ENV ASPNETCORE_URLS=http://+:80 `
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true

 
#FROM mcr.microsoft.com/windows/servercore:ltsc2019-amd64 AS demoapp
# Downloading artifact
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
RUN Invoke-WebRequest -OutFile demoapp.zip http://nexus.marathon.mesos:27092/repository/dotnet-sample/0.1-SNAPSHOT/TestWorkload.zip; `
    Expand-Archive demoapp.zip -DestinationPath demoapp; `
    Remove-Item -Force demoapp.zip

#FROM mcr.microsoft.com/windows/servercore:ltsc2019-amd64 
#COPY --from=demoapp /demoapp ./
WORKDIR /demoapp/target
ENTRYPOINT ["dotnet", "DemoApp.dll"]
#CMD cmd