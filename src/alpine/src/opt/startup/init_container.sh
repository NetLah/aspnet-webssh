#!/usr/bin/env sh
cat >/etc/motd <<EOL
    _   ___ ___  _  _ ___ _____    ___             
   /_\ / __| _ \| \| | __|_   _|  / __|___ _ _ ___ 
  / _ \\__ \  _/| .' | _|  | |   | (__/ _ \ '_/ -_)
 /_/ \_\___/_|(_)_|\_|___| |_|    \___\___/_| \___|

ASP.NET Core v${ASPNET_VERSION}
EOL
cat /etc/motd

# starting sshd process
sed -i "s/SSH_PORT/$SSH_PORT/g" /etc/ssh/sshd_config
/usr/sbin/sshd

$STARTUPCOMMAND
