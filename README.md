#Gestii APIClient

Con esta herramienta puedes subir archivos a Gestii con solo arrastrarlos a una carpeta de tu computadora. Adicionalmente te permite descargar automaticamente tus reportes generados.


##Instalación 

 * Descargar la versión más reciente desde https://github.com/Gestii/APIClient/releases/latest
 * Crear una carpeta donde se sincronizarán los archivos
 * copiar GestiiAPI.exe a esta carpeta
 * crear un archivo llamado `api_config.ini` con los siguietnes parametros
```
[API]
apikey=<tu apikey>
layout=<id del layout>
url=https://<agencia>.gestii.com
```
* cambiar la apikey y la URL a los valores de tu agencia 
* Ejecutar el archivo GestiiAPI.exe
 
##Uso
  Para subir archivos solo hay que depositar los archivos en la carpeta que creaste, cuando estos se suban se moveran a la subcarpeta llamada `/correctos` en caso de que se detecten errores el archivo con los errores se encontrará en la subcarpeta `/errores`

Para descargar  reportes lo único que hay que hacer es mandarlos a generar desde su portal de gestii, en cuanto el reporte se terminé de generar este se descargará automaticamente en la subcarpeta `/reportes`

Puede solicitar a soporte que se generen automaticamente los reportes en intervalos de un dia.


Esta herramienta se comunica con gestii mediante la aPI definida en http://devs.gestii.com/ 

