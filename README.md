# ASP.NET Core Runtime image supports Azure AppService Web SSH

A customized ASP.NET Core Runtime image supports Azure AppService Web SSH. Docker image repository is on https://hub.docker.com/r/netlah/aspnet-webssh.

## Support ASP.NET Core

- ASP.NET Core 6.0, mcr.microsoft.com/dotnet/aspnet:6.0 tags: `6.0-alpine`, `6.0-bookworm-slim`, `6.0-bullseye-slim`, `6.0-jammy`, `6.0-focal`
- ASP.NET Core 7.0, mcr.microsoft.com/dotnet/aspnet:7.0 tags: `7.0-alpine`, `7.0-bookworm-slim`, `7.0-bullseye-slim`, `7.0-jammy`
- ASP.NET Core 8.0, mcr.microsoft.com/dotnet/aspnet:8.0 tags: `8.0-alpine`, `8.0-bookworm-slim`, `8.0-jammy`
- ASP.NET Core 9.0, mcr.microsoft.com/dotnet/aspnet:9.0 tags: `9.0-alpine`, `9.0-bookworm-slim`, `9.0-jammy`

## Github source

https://github.com/NetLah/aspnet-webssh

## Build Status

[![Docker Image CI](https://github.com/NetLah/aspnet-webssh/actions/workflows/docker-image.yml/badge.svg)](https://github.com/NetLah/aspnet-webssh/actions/workflows/docker-image.yml)

## Run example ASP.NET Core container with WebSSH support

- Run with WebSSH support, using `STARTCOMMAND` environment for original entrypoint.

```
docker run -it --rm --name aspnetssh --entrypoint /opt/startup/init_container.sh -e "STARTUPCOMMAND=exec dotnet WebApp.dll" -p 5002:80 -p 2222:2222 -e TZ=Asia/Singapore netlah/spa-host:6.0-alpine
```

- Run with WebSSH support, using command arguments for original entrypoint.

```
docker run -it --rm --name aspnetssh --entrypoint /opt/startup/init_container.sh -p 5002:80 -p 2222:2222 -e TZ=Asia/Singapore netlah/spa-host:6.0-alpine exec dotnet WebApp.dll
```

Output

```
    _   ___ ___  _  _ ___ _____    ___
   /_\ / __| _ \| \| | __|_   _|  / __|___ _ _ ___
  / _ \\__ \  _/| .` | _|  | |   | (__/ _ \ '_/ -_)
 /_/ \_\___/_|(_)_|\_|___| |_|    \___\___/_| \___|

Alpine Linux v3.16
ASP.NET Core v6.0.10
Startup 2022-10-05 12:34:56 +0800 Asia/Singapore
[02:33:30 INF] Application starting...
[02:33:30 INF] Application initializing...
```

![aspnet-webssh](https://raw.githubusercontent.com/NetLah/aspnet-webssh/main/docs/aspnet-webssh.png)

## Test SSH to container

![ssh_2222_container](https://raw.githubusercontent.com/NetLah/aspnet-webssh/main/docs/ssh_2222_container.png)

## Reference

- https://learn.microsoft.com/en-us/azure/app-service/configure-custom-container?pivots=container-linux#enable-ssh
- https://hub.docker.com/_/microsoft-dotnet-aspnet/
