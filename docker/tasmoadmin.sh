#!/bin/bash
set -eo pipefail

# Defined in the Dockerfile but
# if undefined, populate environment variables with sane defaults
TASMOADMIN_CONFIGFILE="/data/MyConfig.json"
TASMOADMIN_PORT="${TASMOADMIN_PORT:-80}"
TASMOADMIN_DATA="${TASMOADMIN_DATA:-/data}"
TASMOADMIN_WWW="${TASMOADMIN_WWW:-/var/www/tasmoadmin}"
TASMOADMIN_AUTH_FILE="${TASMOADMIN_AUTH_FILE:-${TASMOADMIN_DATA}/auth/users}"
TASMOADMIN_AUTH_USER="${TASMOADMIN_AUTH_USER:-}"
TASMOADMIN_AUTH_PASS="${TASMOADMIN_AUTH_PASS:-}"
TASMOADMIN_TLS_CRT="${TASMOADMIN_TLS_CRT:-${TASMOADMIN_DATA}/certs/tasmoadmin.crt}"
TASMOADMIN_TLS_KEY="${TASMOADMIN_TLS_KEY:-${TASMOADMIN_DATA}/certs/tasmoadmin.key}"
TASMOADMIN_USER="${TASMOADMIN_USER:-}"
TASMOADMIN_PASS="${TASMOADMIN_PASS:-}"
TASMOADMIN_LOGIN="${TASMOADMIN_LOGIN:-1}"

# Create /data/tasmoadmin/firmware if it does not exists
if [ ! -d "${TASMOADMIN_DATA}/firmwares" ]
then
    echo "* Creating ${TASMOADMIN_DATA}/firmwares ..."
    mkdir -p "${TASMOADMIN_DATA}/firmwares"
    chown nginx:nginx "${TASMOADMIN_DATA}/firmwares"
fi

# Create /data/tasmoadmin/updates if it does not exists
if [ ! -d "${TASMOADMIN_DATA}/updates" ]
then
    echo "* Creating ${TASMOADMIN_DATA}/updates ..."
    mkdir -p "${TASMOADMIN_DATA}/updates"
    chown nginx:nginx "${TASMOADMIN_DATA}/updates"
fi

echo "* Using env variables to generate webserver configuration ..."
if [ -r "${TASMOADMIN_TLS_CRT}" ] &&  [ -r "${TASMOADMIN_TLS_KEY}" ]
then
    cat <<- EOF > "/etc/nginx/conf.d/tasmoadmin.server"
	listen ${TASMOADMIN_PORT} ssl http2 default_server;
	ssl_certificate ${TASMOADMIN_TLS_CRT};
	ssl_certificate_key ${TASMOADMIN_TLS_KEY};
	ssl_protocols TLSv1.2 TLSv1.1 TLSv1;
	EOF
else
    cat <<- EOF > "/etc/nginx/conf.d/tasmoadmin.server"
	listen ${TASMOADMIN_PORT} default_server;
	EOF
fi
chown nginx:nginx "/etc/nginx/conf.d/tasmoadmin.server"

if [ -r "${TASMOADMIN_AUTH_FILE}" ]
then
    echo "* Copying ${TASMOADMIN_AUTH_FILE} ..."
    cp "${TASMOADMIN_AUTH_FILE}" "/etc/nginx/auth"
fi

if [ -n "${TASMOADMIN_AUTH_USER}" ] && [ -n "${TASMOADMIN_AUTH_PASS}" ]
then
    echo "* Generating Basic Auth user and password  ..."
    echo "${TASMOADMIN_AUTH_USER}:${TASMOADMIN_AUTH_PASS}" >> "/etc/nginx/auth"
fi

if [ -r "/etc/nginx/auth" ]
then
    cat <<- EOF > "/etc/nginx/conf.d/tasmoadmin.auth"
	auth_basic "TasmoAdmin Auth Required";
	auth_basic_user_file /etc/nginx/auth;
	EOF
    chown nginx:nginx /etc/nginx/conf.d/tasmoadmin.auth
fi

case ${TASMOADMIN_LOGIN} in
    NO|no|No)
        TASMOADMIN_LOGIN="0" ;;
    false|False|FALSE)
        TASMOADMIN_LOGIN="0" ;;
    0)
        TASMOADMIN_LOGIN="0" ;;
    ''|*)
        TASMOADMIN_LOGIN="1" ;;
esac
[ -n "${TASMOADMIN_PASS}" ] && TASMOADMIN_PASS=$(echo -n "${TASMOADMIN_PASS}" | md5sum | cut -d' ' -f 1)
if [ ! -r "${TASMOADMIN_CONFIGFILE}" ]
then
    echo "* Generating default configuration: ${TASMOADMIN_CONFIGFILE} ..."
	cat <<- EOF > "${TASMOADMIN_CONFIGFILE}"
	{
	    "ota_server_ssl": "0",
	    "ota_server_ip": "",
	    "ota_server_port": "80",
	    "username": "$TASMOADMIN_USER",
	    "password": "$TASMOADMIN_PASS",
	    "refreshtime": "8",
	    "current_git_tag": "",
	    "update_automatic_lang": "EN",
	    "nightmode": "disable",
	    "login": "$TASMOADMIN_LOGIN",
	    "scan_from_ip": "192.168.178.2",
	    "scan_to_ip": "192.168.178.254",
	    "homepage": "start",
	    "check_for_updates": "0",
	    "minimize_resources": "1"
	}
	EOF
    chown nginx:nginx "${TASMOADMIN_CONFIGFILE}"
else
    sed -i "s/\"username\":.*\"\(.*\)\"/\"username\": \"$TASMOADMIN_USER\"/g" "${TASMOADMIN_CONFIGFILE}"
    sed -i "s/\"login\":.*\"\(.*\)\"/\"login\": \"$TASMOADMIN_LOGIN\"/g" "${TASMOADMIN_CONFIGFILE}"
    [ -n "${TASMOADMIN_PASS}" ] && sed -i "s/\"password\":.*\"\(.*\)\"/\"password\": \"$TASMOADMIN_PASS\"/g" "${TASMOADMIN_CONFIGFILE}"
fi

echo "* Running supervisor ..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

