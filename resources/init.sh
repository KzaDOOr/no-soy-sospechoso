#!/bin/bash


# Verificación de argumentos
if [ "$#" = 0 ]; then
	echo "Error: No se pueden esteganografiar archivos sin archivos. Use -h o --help." >&2
	exit 1
fi

# Definición de funciones
function exitFunction {
	echo "Error - Argumento inválido: No se encontró $1. Use -h o --help." >&2
	exit 1
}

function helpFunction {
	echo "Uso: $0 [argumentos...]"; echo
	echo "   -h| --help                 Mostrar ayuda."; echo
	echo "   -c| --carrier=             Archivo portador a usar para ocultar un archivo. Debe usarse con -s y -o."; echo
	echo "   -s| --secret=              Archivo secreto a ocultar en el archivo portador. Debe usarse con -c y -o."; echo
	echo "   -e| --extract=             Archivo esteganografiado del que extraer un mensaje. Debe usarse con -o."; echo
	echo "   -o| --output=              Archivo de salida en el que crear un archivo esteganografiado. Debe usarse con -c y -s."
	echo "                              o"
	echo "                              Archivo de salida en el que extraer un archivo oculto. Debe usarse con -e."; echo
	exit 1
}


# Bucle para analizar los argumentos
while [ "$#" -gt 0 ]; do
	case "$1" in
		--help) helpFunction; shift 1;;
		-h) helpFunction; shift 1;;
		--carrier=*) [[ -s "${1#*=}" ]] && carrier="${1#*=}" || exitFunction "$1"; shift 1;;
		--secret=*) [[ -s "${1#*=}" ]] && secret="${1#*=}" || exitFunction "$1"; shift 1;;
		--extract=*) [[ -s "${1#*=}" ]] && estearch="${1#*=}" || exitFunction "$1"; shift 1;;
		--output=*) [[ "${1#*=}" ]] && output="${1#*=}" || exitFunction "$1"; shift 1;;
		--carrier|--secret|--extract|--output) echo "$1 debe establecerse = a un nombre de archivo. Ej. $1=tuArchivo.ext. Use -h o --help" >&2; exit 1;;
		-c) [[ -s "$2" ]] && carrier="$2" || exitFunction "$1 $2"; shift 2;;
		-s) [[ -s "$2" ]] && secret="$2" || exitFunction "$1 $2"; shift 2;;
		-e) [[ -s "$2" ]] && estearch="$2" || exitFunction "$1 $2"; shift 2;;
		-o) [[ "$2" ]] && output="$2" || exitFunction "$1"; shift 2;;
		-*) exitFunction "$1"; shift 1;;
		*) exitFunction "$1"; shift 1;;
	esac
done


function errorCases {
	if [[ -n "$estearch" && -z "$output" ]]; then
		echo "Error - Comando incorrecto: Especificar -e|--extraer= requiere un archivo -o|--output=. Use -h o --help." >&2
		exit 1
	fi
	if [[ -n "$output" && -z "$carrier" && -z "$estearch" ]]; then
		echo "Error - Comando incorrecto: Especificar -o|--output= requiere un archivo -c|--carrier= y un archivo -s|--secret=, o un archivo -e|--extraer=. Use -h o --help." >&2
		exit 1
	fi
	if [[ -n "$carrier" && -n "$estearch" ]]; then
		echo "Error - Comando incorrecto: No se puede especificar tanto un archivo -c|--carrier= como un archivo -e|--extraer=. Use -h o --help." >&2
		exit 1
	fi
	if [[ -n "$secret" && -n "$estearch" ]]; then
		echo "Error - Comando incorrecto: No se puede especificar tanto un archivo -s|--secret= como un archivo -e|--extraer=. Use -h o --help." >&2
		exit 1
	fi
	if [[ -e "$output" ]]; then
		echo "Error - Comando incorrecto: Ya existe un archivo con ese nombre. El script se cerrará sin realizar el esteganografiado." >&2
		echo "                     Cambie el nombre del archivo existente o especifique un nombre de archivo -o diferente. Use -h o --help." >&2
		exit 1
	fi
}


function declareInitialVariables {
	lastByte="$( wc -c $carrier | awk '{print $1}')"
	startByte=$(($lastByte + 1))
}

function preventMultipleSteggin {
	validestearchCheck="$(tail -c 500 $carrier | grep -a 'SECSHA' | awk '{print $1}')"
	if [ "$validestearchCheck" = "SECSHA:" ]; then
		echo "Error: El archivo portador $carrier ya ha sido utilizado para steggin'. Saliendo del programa." >&2
		exit 1
	fi
}

function concatenate {
	echo concatenating "$carrier" and "$secret"
	cat "$carrier" "$secret" > "$output"
}

function declareStegginVariables {
	endByte="$(wc -c $output | awk '{print $1}')"
	metaByte=$(($endByte + 1))
}

function getSha256Hashes {
	carSha="$(shasum -a 256 $carrier | awk '{print $1}')"
	secretSha="$(shasum -a 256 $secret | awk '{print $1}')"
}

function concatenateMetaDataText {
	echo "CARSHA: $carSha" > metaData.txt
	echo "SECSHA: $secretSha" >> metaData.txt
	echo "STARTBYTE: $startByte" >> metaData.txt
	echo "ENDBYTE: $endByte" >> metaData.txt
	echo "METABYTE: $metaByte" >> metaData.txt
	cat metaData.txt >> "$output"
}

function echoSucess {
	echo Archivo de metadatos:
	cat metadata.txt && echo; echo
	echo "!!!!! Éxito: El archivo $secret está oculto en el archivo $output !!!!!"
}

function cleanup {
	rm metadata.txt
}

function readMetaDataText {
	validestearchCheck="$(tail -c 500 $estearch | grep -a 'SECSHA' | awk '{print $1}')"
	if [ "$validestearchCheck" != "SECSHA:" ]; then
		echo "Error: El archivo $estearch no ha sido utilizado para steggin' previamente." >&2
		exit 1
	fi
	secSha="$(tail -c 500 $estearch | grep -a 'SECSHA' | awk '{print $2}')"
	carSha="$(tail -c 500 $estearch | grep -a 'CARSHA' | awk '{print $2}')"
	startByte="$(tail -c 500 $estearch | grep -a 'STARTBYTE' | awk '{print $2}')"
	endByte="$(tail -c 500 $estearch | grep -a 'ENDBYTE' | awk '{print $2}')"
	metaByte="$(tail -c 500 $estearch | grep -a 'METABYTE' | awk '{print $2}')"
}

function extractSecretFile {
	head -c "$endByte" "$estearch" | tail -c +"$startByte" > "$output"
	extractedSha="$(shasum -a 256 "$output" | awk '{print $1}')"
	echo "sha256 original:  $secSha"
	echo "sha256 extraído: $extractedSha"
	if [ "$extractedSha" = "$secSha" ]; then
		echo "ÉXITO: El archivo extraído $output es idéntico byte por byte al archivo original procesado."
	else
		echo "ADVERTENCIA: El archivo extraído $output ha sido modificado desde su steggin' original."
	fi
}

# No ejecutar el código si se cumplen estos casos de error.
errorCases

# Crear estearch si se proporcionaron un archivo portador (carrier), un archivo secreto (secret) y un archivo de salida (output).
if [[ -n "$carrier"  &&  -n "$secret" && -n "$output" ]]; then
	declareInitialVariables
	preventMultipleSteggin
	concatenate
	declareStegginVariables
	getSha256Hashes
	concatenateMetaDataText
	echoSucess
	cleanup
fi

# Dividir un archivo que ha sido previamente procesado.
if [[ -n "$estearch" && -n "$output" ]]; then
	readMetaDataText
	extractSecretFile
fi

exit 0