ARG SDK_IMAGE_TAG=6.0-alpine
FROM mcr.microsoft.com/dotnet/aspnet:${SDK_IMAGE_TAG} AS base

ENV SSH_PORT=2222 \
    TZ=UTC

# Copy files in structure /etc/ssh/sshd_config, /opt/startup/init_container.sh /tmp/ssh_setup.sh
COPY src/ /
COPY ssh_setup.sh /tmp

# Install OpenSSH and set the password for root to "Docker!". In this example, "apk add" is the install instruction for an Alpine Linux-based image.
RUN apk add --no-cache openssh tzdata \
    && mkdir -p /run/sshd \
    && chmod -R 755 /run/sshd \
    && echo "root:Docker!" | chpasswd \
    && chmod -R +x /opt/startup \
    && chmod -R +x /tmp/ssh_setup.sh \
    && (sleep 1;/tmp/ssh_setup.sh 2>&1 > /dev/null) \
    && rm -rf /tmp/*
