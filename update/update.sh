#!/bin/bash

#solo para usos educacionales
#no se debe usar en produccion


# Definimos la URL de la imagen a descargar, usted puede personalizar esta script con la url de su repo
url="https://raw.githubusercontent.com/vtomasv/no-soy-sospechoso/main/img/logo.jpeg"

# Definimos el nombre de archivo de salida
filename="logo.jpeg"

# Descargamos la imagen utilizando la función download_image
download_image() {
    wget -O "$filename" "$url"
}

# Llamamos a la función download_image
download_image