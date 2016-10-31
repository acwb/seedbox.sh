#!/bin/bash
echo -e "   \e[2m[téléchargements depuis plateformes de streaming]\e[0m"  
echo ""

# logfile "archive" enregistrant les url des vidéos pour ne pas les télécharger une seconde fois
currentscript="grabber"
log_file=$scriptpath/logs/$currentscript.log
archive_file=$scriptpath/logs/youtube-downloaded.log

set_speedlimit # on revérifie l'heure pour set la speed limit

# démarrage du chronomètre
alldl_start=$SECONDS # chronométrage des conversions

OLDIFS=$IFS # on garde le IFS par default
IFS=$'\n' # on change le IFS pour avoir les sauts de lignes comme seuls séparateurs
set -f    # disable globbing


echo -ne "   \e[34m➤\e[0m Synchronisation des playlists YouTube personnelles \n\n"
	for mypl in $(cat "$STREAM_MYPLS"); do

	 	countlines=$(cat "$STREAM_MYPLS" | wc -l)
	 	urldesc=$(cut -d '#' -f 2- <<< "$mypl")
	  	echo "      - "$urldesc
	  	echo -e "         téléchargement de $STREAM_MAXDL vidéos / $countlines playlists \n"

	  	mypl=${mypl%#*}  # on ignore les commentaires inscrits après les #
	  	youtube-dl -o "$STREAM_DIR/$STREAM_MYPLS_SUBPATH/$STREAM_MYPLS_FNAME" -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --sleep-interval 2 --embed-subs --sub-lang $STREAM_SUB_LANG --write-thumbnail --embed-thumbnail --dateafter $STREAM_AFTERDATE --download-archive $archive_file --write-description --max-downloads $STREAM_MAXDL $afterdate --limit-rate "$DL_SPEED"K --no-warnings --ignore-errors --add-metadata $mypl
		
	done
	video_rename


echo -ne "   \e[34m➤\e[0m Synchronisation des playlists YouTube \n\n"
	for playlist in $(cat "$STREAM_PLS"); do
	 	
	 	urldesc="$( cut -d '#' -f 2- <<< "$playlist" )"
	  	echo "      - "$urldesc
	  	echo -e "         téléchargement de $STREAM_MAXDL vidéos / $countlines playlists \n"

	  	playlist=${playlist%#*}  # on ignore les commentaires inscrits après les #
	  	youtube-dl -o "$STREAM_DIR/$STREAM_PLS_SUBPATH/$STREAM_PLS_FNAME" -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --sleep-interval 2 --embed-subs --sub-lang $STREAM_SUB_LANG --write-thumbnail --embed-thumbnail --dateafter $STREAM_AFTERDATE --download-archive $archive_file --write-description --max-downloads $STREAM_MAXDL $afterdate --limit-rate "$DL_SPEED"K --no-warnings --ignore-errors --add-metadata $playlist
		
	done
	video_rename


echo -ne "   \e[34m➤\e[0m Synchronisation des vidéos via flux RSS \n\n"
	for rsslist in $(cat "$STREAM_RSS"); do

	 	urldesc="$( cut -d '#' -f 2- <<< "$rsslist" )"
	  	echo "      - "$urldesc
	  	echo -e "         téléchargement de $STREAM_MAXDL vidéos / $countlines playlists \n"

	  	rsslist=${rsslist%#*}  # on ignore les commentaires inscrits après les #
	  	youtube-dl -o "$STREAM_DIR/$STREAM_RSS_SUBPATH/$STREAM_RSS_FNAME" -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --sleep-interval 2 --embed-subs --sub-lang $STREAM_SUB_LANG --write-thumbnail --embed-thumbnail --dateafter $STREAM_AFTERDATE --download-archive $archive_file --write-description --max-downloads $STREAM_MAXDL $afterdate --limit-rate "$DL_SPEED"K --no-warnings --ignore-errors --add-metadata $rsslist
		
	done
	video_rename


echo -ne "   \e[34m➤\e[0m Téléchargement des vidéos marquées à DL dans todl.txt \n\n"
	for todl in $(cat "$STREAM_TODL"); do

	 	
		urldesc="$( cut -d '#' -f 2- <<< "$todl" )"
	  	echo "      - "$urldesc
	  	echo -e "         téléchargement de $STREAM_MAXDL / $countlines vidéos \n"

	  	todl=${todl%#*}  # on ignore les commentaires inscrits après les #
	  	youtube-dl -o "$STREAM_DIR/$STREAM_TODL_SUBPATH/$STREAM_TODL_FNAME" -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --sleep-interval 2 --embed-subs --sub-lang $STREAM_SUB_LANG --write-thumbnail --embed-thumbnail --dateafter $STREAM_AFTERDATE --download-archive $archive_file --write-description --max-downloads $STREAM_MAXDL $afterdate --limit-rate "$DL_SPEED"K --no-warnings --ignore-errors --add-metadata $todl
		
	done
	bash ~/scripts/cryptbox/pclean.sh &> /dev/null
	video_rename

# on rétablie le IFS par defaut
IFS=$OLDIFS

# on calcule le nombre de secondes écoulées depuis le début des téléchargements
alldl_duration=$(($SECONDS - $alldl_start))

echo -ne "\n  \e[32m✓\e[0m Synchronisations terminées en $(($alldl_duration / 60)) min ($alldl_duration sec)"