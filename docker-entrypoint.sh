#!/bin/bash
set -euo pipefail

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
        local var="$1"
        local fileVar="${var}_FILE"
        local def="${2:-}"
        if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
                echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
                exit 1
        fi
        local val="$def"
        if [ "${!var:-}" ]; then
                val="${!var}"
        elif [ "${!fileVar:-}" ]; then
                val="$(< "${!fileVar}")"
        fi
        export "$var"="$val"
        unset "$fileVar"
}

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then
        if [ "$(id -u)" = '0' ]; then
                case "$1" in
                        apache2*)
                                user="${APACHE_RUN_USER:-www-data}"
                                group="${APACHE_RUN_GROUP:-www-data}"

                                # strip off any '#' symbol ('#1000' is valid syntax for Apache)
                                pound='#'
                                user="${user#$pound}"
                                group="${group#$pound}"
                                ;;
                        *) # php-fpm
                                user='www-data'
                                group='www-data'
                                ;;
                esac
        else
                user="$(id -u)"
                group="$(id -g)"
        fi
fi

        if [ ! -e index.php ]; then
                # if the directory exists and OMP doesn't appear to be installed AND the permissions of it are root:root, let's chown it (likely a Docker-created directory)
                if [ "$(id -u)" = '0' ] && [ "$(stat -c '%u:%g' .)" = '0:0' ]; then
                        chown "$user:$group" .
                fi

                echo >&2 "OMP not found in $PWD - copying now..."
                if [ -n "$(ls -A)" ]; then
                        echo >&2 "WARNING: $PWD is not empty! (copying anyhow)"
                fi
                sourceTarArgs=(
                        --create
                        --file -
                        --directory /var/www/omp
                        --owner "$user" --group "$group"
                )
                targetTarArgs=(
                        --extract
                        --file -
                )
                if [ "$user" != '0' ]; then
                        # avoid "tar: .: Cannot utime: Operation not permitted" and "tar: .: Cannot change mode to rwxr-xr-x: Operation not permitted"
                        targetTarArgs+=( --no-overwrite-dir )
                fi
                tar "${sourceTarArgs[@]}" . | tar "${targetTarArgs[@]}"
                echo >&2 "Complete! WordPress has been successfully copied to $PWD"
                if [ ! -e .htaccess ]; then
                        # NOTE: The "Indexes" option is disabled in the php:apache base image
                        cat > .htaccess <<-'EOF'
                                # BEGIN WordPress
                                <IfModule mod_rewrite.c>
                                RewriteEngine On
                                RewriteBase /
                                RewriteRule ^index\.php$ - [L]
                                RewriteCond %{REQUEST_FILENAME} !-f
                                RewriteCond %{REQUEST_FILENAME} !-d
                                RewriteRule . /index.php [L]
                                </IfModule>
                                # END WordPress
                        EOF
                        chown "$user:$group" .htaccess
                fi
        fi

                file_env 'OMP_DB_HOST'
                file_env 'OMP_DB_USER'
                file_env 'OMP_DB_PASSWORD'
                file_env 'OMP_DB_NAME'

exec "$@"
