#!/bin/bash


mp3length=0 
flaclength=0
goodtogo=0 

 

 

flacsize=`get_filesize $i`
flaclength=$(avconv -i $i 2>&1 | egrep "Duration" | cut -d ' ' -f 4 | sed s/,// )
losslesstype="${i##*.}"

# on extrait le filename en l'extension flac
newname=`basename $PWD/$i $losslesstype`mp3 

 
echo -en "       $i \e[2m($flaclength / $flacsize)\e[0m"

# on vérifie que le mp3 n'existe pas déja
if [ -f "$PWD/$newname" ] ; then

    # si oui on récupère sa durée (pour comparaison) et son poid (pour info)
    mp3length=$(avconv -i $newname 2>&1 | egrep "Duration" | cut -d ' ' -f 4 | sed s/,// )
    mp3size=$(find . -maxdepth 1 -name "$newname" -printf "%s\n" )

    echo_log 0 "Un fichier MP3 $newname ($mp3length / $mp3size octets) existe déja"

    # on compare les durées des deux fichiers
    checkdiff_length $flaclength $mp3length

    if [ "$mp3valid" -eq 0 ]; then # $mp3valid = 1 si les durées sont ok
        echo -en "\r      \e[34m±\e[0m [OVERWRITE] $i \e[2m($flaclength / $flacsize)\e[0m"
        echo_log 0 "Sa durée ($mp3length) ne correspond pas à celle du $losslesstype ($flaclength) - On peut remplacer le fichier"
        count_overwrite=$((count_overwrite+1)) # compteur de fichiers écrasés
        goodtogo=1
    else
        echo -en "\r      \e[34m±\e[0m [SKIP] $i \e[2m($flaclength / $flacsize)\e[0m"
        if [ "$auto" = 1 ] ; then # on supprime le fichier source flac inutile
            echo_log 0 "La durée du MP3 correspond à celle du $losslesstype : suppression auto du $losslesstype"
            if [ "$SAND_BOX" = false ] ; then 
                rm -f "$PWD/$i" # pas de confirmation si mode -auto
            fi
        else
            echo_log 0 "La durée du MP3 correspond à celle du $losslesstype - Suppression confirmée du $losslesstype"
            if [ "$SAND_BOX" = false ] ; then 
                rm -i "$PWD/$i"
            fi
        fi
        count_skipped=$((count_skipped+1)) # compteur de fichiers passés
        goodtogo=0 
    fi
fi


# si aucun mp3 n'est présent, on lance la conversion

# on lance le chrono
START_TIME_CURRENT=$SECONDS


# si le fichier est un flac, on le decode en wav
if [ "$losslesstype" = "flac" ]; then

    # décodage du flac > wav
    flac $WAV_OVERWRITE -d "$i"  > $flac_log_file 2>&1  

    if [ $? -eq 0 ]; then
        echo -n " >"
        echo_log 0 "Fichier $losslesstype décodé avec succès"
        goodtogo=1
    else
        echo -e "\r      \e[91m✖\e[0m $i \e[2m($flaclength / $flacsize)\e[0m : ERREUR lors du décodage, fichier corrompu ?"
        echo_log 0 "Erreur lors du décodage de $i (fichier corrompu ?)"
        error_files="      $i"$'\n'"${error_files}"
        count_errors=$((count_errors+1)) # compteur d'erreurs
        goodtogo=0 
    fi
fi

# si le fichier est un ape, on est bon pour passer à la conversion
if [ "$losslesstype" = "ape" ]; then
    echo -n " >"
    goodtogo=1
fi



sleep 1 



if [ "$goodtogo" = 1 ] ; then


    if [ "$losslesstype" = "ape" ]; then
        avconv $MP3_OVERWRITE -i "$i" -V0 "${i%.ape}.mp3" > $avconv_log_file 2>&1  
    fi

    if [ "$losslesstype" = "flac" ]; then
    
        # encodage du flac > mp3
        lame -V0 --verbose "${i%.flac}.wav" "${i%.flac}.mp3" > $lame_log_file 2>&1  

    fi

    

    if [ $? -eq 0 ]; then
        echo -n "> "
        echo_log 0 "Fichier $losslesstype encodé avec succès"
        goodtogo=1
    else
        echo -en "\r    \e[91m✖\e[0m $i \e[2m($flaclength / $flacsize)\e[0m : ERREUR lors de l'encodage "
        echo_log 0 "Erreur lors de l'encodage de $i (fichier corrompu ?)"
        error_files="DECODE ERROR: $i"$'\n'"${error_files}"
        count_errors=$((count_errors+1)) # compteur d'erreurs
        goodtogo=0 
    fi
fi

# avconv $overwrite -i $i -ab 320000  >& /dev/null # || break 3
# le || break permet de sortir du loop en cas d'erreur ou ctrl+C (et ainsi éviter de supprimer un flac après une conversion foireuse)

if [ "$goodtogo" = 1 ] ; then

    # conversion terminée, on récupère le chrono et la taille du fichier
    ELAPSED_TIME_CURRENT=$(($SECONDS - $START_TIME_CURRENT))
    mp3size=`get_filesize $PWD/$newname`
    mp3length=$(avconv -i $newname 2>&1 | egrep "Duration" | cut -d ' ' -f 4 | sed s/,// )

    # on confirme la fin de la conversion en affichant son filename et filesize
    echo -en "\r    \e[32m✓\e[0m $i \e[2m($flaclength / $flacsize)\e[0m >> $newname \e[2m($mp3length / $mp3size)\e[0m  "
    echo ""
    ####echo -n "Fichier converti en $ELAPSED_TIME_CURRENT sec "
    echo_log 0 "$ELAPSED_TIME_CURRENT ' $newname ($mp3size)"

    # on vérifie si le fichier mp3 nouvellement créé existe bien
    ####echo -n "/ File Check: "
    if [ -d "$PWD/$newname" ] ; then
        echo -en "\r    \e[91m✖\e[0m $i \e[2m($flaclength / $flacsize)\e[0m : ERREUR ! Fichier $losslesstype conservé: $i"
        echo_log 0 "ERREUR: Fichier MP3 introuvable: $PWD/$newname"
        count_errors=$((count_errors+1)) # compteur d'erreurs
    else
        ####echo -n "OK "
        echo_log 0 "Vérifications: fichier existant  $newname"

        # on compare les durées des deux fichiers
        checkdiff_length "$flaclength" "$mp3length"


        if [ "$mp3valid" -eq 0 ]; then # $mp3valid = 1 si les durées sont ok
            echo -en "\r    \e[91m✖\e[0m $i \e[2m($flaclength / $flacsize)\e[0m : ERREUR: la durée du MP3 ($mp3length) ne correspond pas à celle du $losslesstype ($flaclength), fichier conservé."
            echo_log 0 "ERREUR: la durée du MP3 ($mp3length) ne correspond pas à celle du $losslesstype ($flaclength)"
            count_errors=$((count_errors+1)) # compteur d'erreurs
        else
            ####echo -n "OK "
            echo_log 0 "OK: la durée du MP3 ($mp3length) correspond bien à celle du $losslesstype ($flaclength)"

            # le flac a été à priori converti avec succès
            count_converted=$((count_converted+1)) # compteur de fichiers convertis
            if [ "$LOSSLESS_DEL" = true ] ; then # si option supprimer flac après conversion active
                
                if [ -f "${i%.flac}.wav" ] ; then # suppression du wav si existant (flac>wav>mp3)
                    if [ "$SAND_BOX" = false ] ; then 
                        rm "${i%.flac}.wav"
                    fi
                    if [ $? -eq 0 ]; then
                        echo_log 0 "Fichier WAVE supprimé : ${i%.flac}.wav"
                    else 
                        echo_log 0 "ERREUR: Fichier WAVE non supprimé : ${i%.flac}.wav"
                        echo "Fichier WAVE non supprimé ! "
                    fi
                fi
                if [ -f "$i" ] ; then
                    if [ "$SAND_BOX" = false ] ; then 
                        rm "$i" # suppression du fichier source (flac ou ape)
                    fi
                    if [ $? -eq 0 ]; then
                        echo_log 0 "Fichier $losslesstype supprimé : $i"
                    else 
                        echo_log 0 "ERREUR: Fichier $losslesstype non supprimé : $i"
                        echo "/ $losslesstype non supprimé ! "
                    fi
                fi

                count_deleted=$((count_deleted+1)) # compteur de fichiers supprimés apres conversions
            else
                echo_log 1 "Fichier(s) source conservé(s) (option LOSSLESS_DEL=false)"
                count_keep=$((count_keep+1)) # compteur de fichiers préservés apres conversions                    
            fi
        fi
    fi
fi
