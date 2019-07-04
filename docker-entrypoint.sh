#!/bin/bash

# Ensure the hostname is all in lowercase
SERVER_FQDN="$(echo "${SERVER_FQDN}" | tr '[:upper:]' '[:lower:]')"
echo "ServerName ${SERVER_FQDN}" > /etc/apache2/conf-enabled/servername.conf

/opt/phabricator/bin/config set diffusion.ssh-port 2222
/opt/phabricator/bin/config set diffusion.ssh-user git
/opt/phabricator/bin/config set mysql.host mysql-phabricator
/opt/phabricator/bin/config set mysql.pass ${MYSQL_ROOT_PASSWORD}
/opt/phabricator/bin/config set phd.user root
/opt/phabricator/bin/config set phabricator.base-uri "http://${SERVER_FQDN}/"

# Reduce Phabricator setup issues
/opt/phabricator/bin/config set phabricator.timezone UTC
/opt/phabricator/bin/config set pygments.enabled true

/opt/phabricator/bin/storage upgrade --force || exit

/opt/phabricator/bin/phd start
# Listen on 8008 too
echo "Listen 8008" >> /etc/apache2/ports.conf
apachectl start

# Force the FQDN into hosts to workaround crazy things like the DNS servers
# being used being Google's anycast ones...
echo "127.0.0.1 $(echo ${SERVER_FQDN} | sed -e 's/:.*$//')" >> /etc/hosts

# Configure arcanist
/opt/arcanist/bin/arc set-config default "http://${SERVER_FQDN}"
# Switch directory (otherwise the default conduit-uri won't be picked up)
cd /tmp
arc install-certificate
echo "Use this terminal to test arc conduit commands e.g."
echo "echo '{
  \"queryKey\": \"active\"
}' | arc call-conduit user.search"
echo
echo "See https://secure.phabricator.com/conduit/ or "
echo "http://${SERVER_FQDN}/conduit for Phabricator API documentation"
echo
echo "Exit this terminal to stop the container"
exec /bin/bash
