#!/bin/bash

DRIVEPATH="."
FAVPATH="./00_copiarfavoritos/"
LOGDIR="$FAVPATH/logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/log_$(date +'%Y-%m-%d').txt"
FALTANTES_FILE="$LOGDIR/faltantes_$(date +'%Y-%m-%d').txt"

> "$FALTANTES_FILE"

copiadas=0
faltantes=0
skipped=0

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

log "===== INICIO ====="

for systemdir in "$DRIVEPATH"/*/ ; do
    [ -d "$systemdir" ] || continue
    system=$(basename "$systemdir")

    # Ignorar ports
    [[ "$system" == "ports" ]] && { log "Sistema 'ports' ignorado"; continue; }

    gamelist="$systemdir/gamelist.xml"
    [[ ! -f "$gamelist" ]] && log "Sin gamelist.xml en $system" && continue

    mapfile -t favorites < <(xmllint --xpath "//game[favorite='true']/path/text()" "$gamelist" 2>/dev/null)
    mapfile -t names < <(xmllint --xpath "//game[favorite='true']/name/text()" "$gamelist" 2>/dev/null)
    mapfile -t images < <(xmllint --xpath "//game[favorite='true']/image/text()" "$gamelist" 2>/dev/null)

    [[ ${#favorites[@]} -eq 0 ]] && log "Sin favoritos en $system" && continue

    dest="$FAVPATH/$system"
    mkdir -p "$dest"

    for i in "${!favorites[@]}"; do
        rel_path="${favorites[$i]}"
        name="${names[$i]}"
        image_rel="${images[$i]}"
        rom_basename=$(basename "$rel_path")

        exact_path="$systemdir/$rel_path"
        if [[ -f "$exact_path" ]]; then
            rom_path="$exact_path"
        else
            rom_path=$(find "$systemdir" -type f -iname "*$rom_basename*" -print -quit)
            [[ -z "$rom_path" ]] && rom_path=$(find "$DRIVEPATH" -type f -iname "*$rom_basename*" -print -quit)
        fi

        if [[ -n "$rom_path" && -f "$rom_path" ]]; then
            rom_dirname=$(dirname "$rom_path")
            subfolder=$(basename "$rom_dirname")
            dest_file_dir="$dest/$subfolder"
            mkdir -p "$dest_file_dir"
            dest_file="$dest_file_dir/$(basename "$rom_path")"

            if [[ -f "$dest_file" ]]; then
                log "ROM ya existe y se salta: $name"
                ((skipped++))
                continue
            fi

            log "Copiando: $name -> $subfolder/"
            cp -v -- "$rom_path" "$dest_file" 2>&1 | tee -a "$LOGFILE"
            ((copiadas++))

            # Copiar imagen
            if [[ -n "$image_rel" ]]; then
                exact_image="$systemdir/$image_rel"
                if [[ -f "$exact_image" ]]; then
                    img_dest_dir="$dest_file_dir/images"
                    mkdir -p "$img_dest_dir"
                    cp -v -- "$exact_image" "$img_dest_dir" 2>&1 | tee -a "$LOGFILE"
                fi
            fi

        else
            log "ROM no encontrada: $rel_path"
            echo "$system/$rel_path" >> "$FALTANTES_FILE"
            ((faltantes++))
        fi
    done
done

echo
echo "===== FIN DEL PROCESO ====="
echo "ROMs copiadas correctamente: $copiadas"
echo "ROMs ya existentes (omitidas): $skipped"
echo "ROMs faltantes: $faltantes"
echo "Log completo: $LOGFILE"

if [[ $faltantes -eq 0 ]]; then
    echo "? Copia de favoritos completada sin errores."
else
    echo "? Copia de favoritos completada con errores."
    echo "Revisa el log y el archivo de faltantes: $FALTANTES_FILE"
fi

echo
read -n1 -r -p "Pulsa cualquier tecla para salir..." key
echo
