# GLPI Installation on ubuntu

Este directorio contiene scripts de automatización para la instalación y configuración de GLPI en un entorno Linux con PHP, MySQL y Apache2.

## Requisitos Previos

- Sistema operativo Linux
- Usuario con privilegios de superusuario (root)
- Conexión a Internet para la descarga de dependencias

## Contenido

El script `install_glpi.sh` realiza las siguientes tareas:

1. Instalación de MySQL Server y configuración segura.
2. Instalación de Apache2 y PHP 7.4 con complementos necesarios.
3. Creación de base de datos y usuarios de MySQL para GLPI.
4. Descarga y extracción de GLPI desde la última versión disponible en GitHub.
5. Configuración de permisos y directorios necesarios.
6. Creación de archivos de configuración personalizados.
7. Activación de módulos Apache2 y configuración de VirtualHost.

## Uso

1. Clone este repositorio:

   ```bash
   git clone https://github.com/castrojosec/glpi-installation-scripts.git

2. Ingresa al directorio clonado

   ```bash
   cd glpi-installation-scripts

3. Ejecuta el script de instalacion

   ```bash
   bash install_glpi.sh

## Notas Importantes
Asegúrate de ejecutar el script como superusuario (root).
Verifica que los puertos necesarios (por ejemplo, 80 para Apache) estén disponibles y no estén bloqueados por el firewall
