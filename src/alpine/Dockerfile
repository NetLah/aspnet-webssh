ARG IMAGE_TAG=6.0-alpine
FROM mcr.microsoft.com/dotnet/aspnet:${IMAGE_TAG} AS base

# Sample dotnet Alpine with ICU https://github.com/dotnet/dotnet-docker/blob/main/samples/dotnetapp/Dockerfile.alpine-x64#L20
ENV SSH_PORT=2222 \
    TZ=UTC \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8

# Copy files in structure /etc/ssh/sshd_config, /opt/startup/init_container.sh /tmp/ssh_setup.sh
COPY src/ /

# Install OpenSSH and set the password for root to "Docker!". In this example, "apk add" is the install instruction for an Alpine Linux-based image.
# .NET Core 2.0 Globalization Invariant Mode https://github.com/dotnet/announcements/issues/20
RUN apk add --no-cache openssh tzdata icu-data-full icu-libs \
    && mkdir -p /run/sshd \
    && chmod -R 755 /run/sshd \
    && echo "root:Docker!" | chpasswd \
    && chmod -R +x /opt/startup \
    && (sleep 1;/opt/startup/ssh_setup.sh 2>&1 > /dev/null) \
    && rm -rf /tmp/*
