##!/bin/bash


currentscript="grabber"

echo -e "   \e[2m[synchronisation en local de playlists YouTube]\e[0m"  
echo ""

# logfile "archive" enregistrant les url des vidéos pour ne pas les télécharger une seconde fois
log_file=$scriptpath/logs/$currentscript.log
archive_file=$scriptpath/logs/youtube-downloaded.log


# démarrage du chronomètre
alldl_start=$SECONDS # chronométrage des conversions

echo -ne "   \e[34m➤\e[0m Synchronisation des playlists YouTube \n\n"

#playlists=($STREAM_PLS)

for myplaylist in "${STREAM_MYPLS[@]}" ; do
 	youtube-dl -o "$STREAM_DIR/$STREAM_MYPLS_SUBPATH/$STREAM_MYPLS_FNAME" -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --embed-subs --sub-lang $STREAM_SUB_LANG --write-thumbnail --embed-thumbnail --dateafter $STREAM_AFTERDATE --download-archive $archive_file --write-description --max-downloads $STREAM_MAXDL $afterdate --limit-rate "$DL_SPEED"K --no-warnings --ignore-errors --add-metadata $myplaylist
	echo
done

for playlist in "${STREAM_PLS[@]}" ; do
 	youtube-dl -o "$STREAM_DIR/$STREAM_PLS_SUBPATH/$STREAM_PLS_FNAME" -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --embed-subs --sub-lang $STREAM_SUB_LANG --write-thumbnail --embed-thumbnail --dateafter $STREAM_AFTERDATE --download-archive $archive_file --write-description --max-downloads $STREAM_MAXDL $afterdate --limit-rate "$DL_SPEED"K --no-warnings --ignore-errors --add-metadata $playlist
	echo
	#pl_url="https://www.youtube.com/playlist?list=PL43OynbWaTMK02ry3pueuz9i4ouljleUm"
	#youtube-dl -o $STREAM_DIR/$subpath$STREAM_FILENAME_FORMAT -f bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best --embed-subs --sub-lang $STREAM_SUB_LANG --write-description --write-thumbnail --embed-thumbnail --download-archive $archive_file $simulate --max-downloads $STREAM_MAXDL --dateafter $STREAM_AFTERDATE --limit-rate $DL_SPEEDK --no-warnings --ignore-errors --add-metadata  ${pl_url}
	#youtube-dl -s -o '$STREAM_DIR/$subpath$STREAM_FILENAME_FORMAT' -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' $thumb $desc $sub $overwrite $simulate --max-downloads $STREAM_MAXDL $afterdate --limit-rate $DL_SPEED --no-warnings --ignore-errors --add-metadata  ${pl_url}
done

# renommage des fichiers pour compatibilité Plex (fichier .summary + format date)
if [ "$STREAM_FILENAME_RENAME" = true ]; then
	echo -ne "\n     \e[34m➤\e[0m Renommage des fichiers pour compatibilité Plex \n"
	find $STREAM_DIR -name "*.description" -exec rename 's/\.description$/.summary/' '{}' \; &> /dev/null
	find $STREAM_DIR -exec rename -v 's/(\d{4})(\d{2})(\d{2})/$1-$2-$3/'  '{}' \; &> /dev/null
fi

# on calcule le nombre de secondes écoulées depuis le début des téléchargements
alldl_duration=$(($SECONDS - $alldl_start))

echo -ne "\n  \e[32m✓\e[0m Synchronisation terminée en $(($alldl_duration / 60)) min ($alldl_duration sec)"