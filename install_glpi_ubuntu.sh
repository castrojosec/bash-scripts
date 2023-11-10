#!/bin/bash

# Verificar usuario root
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script debe ejecutarse como superusuario (root)."
  exit 1
fi

# Variables para los nombres de usuarios y contraseñas de MySQL
MYSQL_ROOT_USER="root"
MYSQL_ROOT_PASSWORD="Jose_glpi2320#"
MYSQL_ROOT_HOST="localhost"

GLPI_DB="glpi"
GLPI_USER="glpi_user"
GLPI_PASSWORD="Glpi2320#_pick"
GLPI_HOST="localhost"

# Actualiza el sistema
apt update

# Instala MySQL Server
apt install mysql-server -y

# Inicia el servicio de MySQL
systemctl start mysql

# Habilita MySQL para que se inicie automaticamente en el arranque del sistema
systemctl enable mysql

# Ejecuta la instalacion segura de mysql
mysql_secure_installation <<EOF
y
2
y
y
y
y
EOF

# Cambiar la contraseña del usuario root y crear db glpi
cat > sql_config.sql <<-EOF
CREATE DATABASE $GLPI_DB charset utf8mb4 collate utf8mb4_unicode_ci;
CREATE USER '$GLPI_USER'@'$GLPI_HOST' identified by '$GLPI_PASSWORD';
grant all privileges on $GLPI_DB.* to '$GLPI_USER'@'$GLPI_HOST';
grant select on mysql.time_zone_name to '$GLPI_USER'@'$GLPI_HOST';
USE mysql;
ALTER USER '$MYSQL_ROOT_USER'@'$MYSQL_ROOT_HOST' IDENTIFIED WITH caching_sha2_password BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF

# Ejecutar script para cambiar la contraseña root
mysql < sql_config.sql

sleep 1
#rm sql_config.sql

#Instalar apache2
echo "Validando la instalacion de apache"

if dpkg -l |grep -q apache2;
then
        echo "Apache ya esta instalado"
else
        echo "instalando el paquete"
        apt install apache2 -y
	systemctl start apache2
	systemctl enable apache2 
fi

#Instalar php y complementos
#Si el server ya tiene instalado el php se debe validar
#echo "Validando la instalacion de php"

#if dpkg -l |grep -q php;
#then
#        echo "PHP ya esta instalado"
#else
#        echo "instalando php y sus complementos"
#        apt-get install php7.4 -y
#	apt install -y php-{mbstring,curl,gd,xml,intl,ldap,apcu,xmlrpc,cas,zip,bz2,mysql}
#        apt-get install -y libapache2-mod-php7.4
#fi

#Instalar php y complementos en killercode ya viene el php 7.4.3
echo "instalando php y sus complementos"
apt-get install -y php7.4
apt-get install -y php-{mbstring,curl,gd,xml,intl,ldap,apcu,xmlrpc,cas,zip,bz2,mysql}
  apt-get install -y libapache2-mod-php7.4

#Reiniciar el apache y habilitar el php
a2enmod php7.4
systemctl restart apache2

# Crear carpetas para el aplicativo
mkdir /etc/glpi /var/log/glpi/ /glpicolombia

# Descargar y extraer el fuente del aplicativo en la carpeta raiz
wget -P ~/glpicolombia https://github.com/glpi-project/glpi/releases/download/10.0.10/glpi-10.0.10.tgz /glpicolombia
tar -xzf /root/glpicolombia/glpi-10.0.10.tgz -C /root/glpicolombia/

#Se debe validar que ya exista msqlserver y apache instalados
mv /root/glpicolombia/glpi /var/www/
mv /var/www/glpi/files/ /var/lib/glpi

# Crear archivo en inc
# Ruta del archivo
RUTA_INC="/var/www/glpi/inc/downstream.php"

# Comprobar si downstream ya existe
if [ -e "$RUTA_INC" ]; then
  echo "El archivo ya existe en $RUTA_INC."
  exit 1
fi

# Contenido del archivo
EXT_DIR='<?php
define("GLPI_CONFIG_DIR", "/etc/glpi/");
if (file_exists(GLPI_CONFIG_DIR . "/local_define.php")) {
        require_once GLPI_CONFIG_DIR . "/local_define.php";
}'

# Crea el archivo y escribe el contenido
echo "$EXT_DIR" > "$RUTA_INC"
echo "El archivo $RUTA_INC ha sido creado exitosamente con el contenido."

# Crear archivo en etc
# Ruta del archivo
RUTA_ETC="/etc/glpi/local_define.php"

# Comprobar si downstream ya existe
if [ -e "$RUTA_ETC" ]; then
  echo "El archivo ya existe en $RUTA_ETC."
  exit 1
fi

# Contenido del archivo
EXT_ETC='<?php
define("GLPI_VAR_DIR", "/var/lib/glpi");
define("GLPI_LOG_DIR", "/var/log/glpi");'

# Crea el archivo y escribe el contenido
echo "$EXT_ETC" > "$RUTA_ETC"
echo "El archivo $RUTA_ETC ha sido creado exitosamente con el contenido."

#Permisos de escritura para el directorio principal y para los externos
chown -R www-data: /var/www/glpi/ /etc/glpi/ /var/lib/glpi/ /var/log/glpi/

#Activar los modulos Expires y Rewrite
a2enmod expires rewrite

#Crear archivo de configuracion para los alias
# Ruta del archivo
RUTA_CONF="/etc/apache2/sites-available/glpi.conf"

# Comprobar si downstream ya existe
if [ -e "$RUTA_CONF" ]; then
  echo "El archivo ya existe en $RUTA_CONF."
  exit 1
fi

# Contenido del archivo
CONF_AL='Alias /glpi /var/www/glpi/public
<Directory /var/www/glpi/public>
        AllowOverride all
        RewriteEngine on
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
</Directory>'

# Crea el archivo y escribe el contenido
echo "$CONF_AL" > "$RUTA_CONF"
echo "El archivo $RUTA_CONF ha sido creado exitosamente con el contenido."

# Añadimos la nueva configuracion
a2ensite glpi.conf

# Reiniciamos el apache
systemctl restart apache2

# Editamos el archivo de los virtualhost
# Ruta del archivo
RUTA_VH="/etc/apache2/sites-available/000-default.conf"

# Contenido del archivo
EXT_VH='<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/glpi/public

    <Directory /var/www/glpi/public>
        Require all granted

        RewriteEngine on
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
</VirtualHost>'

# Crea el archivo y escribe el contenido
#echo "$EXT_VH" > "$RUTA_ETC"
echo "$EXT_VH" | tee "$RUTA_VH"
echo "El archivo $RUTA_VH ha sido creado exitosamente con el contenido."

# Reiniciamos el apache
systemctl restart apache2

php /var/www/glpi/bin/console db:install -d $GLPI_DB -u $GLPI_USER -p $GLPI_PASSWORD -L es_CO -f -n
