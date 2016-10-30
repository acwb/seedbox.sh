#!/bin/bash


# préparation de vars
currentscript="cuesplit"
log_file=$scriptpath/logs/$currentscript.log
temp_log_file=$scriptpath/logs/mp3splt.log

# initialisation/remise à zéro des compteurs
count_splitted=0
count_errors=0
count_cuedeleted=0
count_mp3deleted=0
allsplit_start=$SECONDS # chronométrage des conversions

# permet d'éviter que var="*.ext" si aucun fichier du type
#shopt -s nullglob

echo -e "   \e[2m[split de fichier audio d'après un CUE]\e[0m"
sleep 1

countcuefiles=$(find "$CUE_SOURCE_DIR" -type f -iname "*.cue" | wc -l)

if [ $countcuefiles != 0 ] ; then

	# on lance le chrono
	START_TIME_CURRENT=$SECONDS

	# on se place dans le dossier source
	cd "$CUE_SOURCE_DIR"

	# pour chaque subdirectory du dossier source (dossiers catégorie)
	for j in `find $CUE_SOURCE_DIR -mindepth 1 -maxdepth 1 -type d` ; do


		# on compte les fichiers qui nous intéressent dans ce dossier
		countdir=$(find $j/ -type d | grep -o '.*/' | wc -l)  
		countcuefiles=$(find $j/ -type f -iname "*.cue" | wc -l)
	 	countmp3files=$(find $j/ -type f -iname "*.mp3" | wc -l)


		if [ $countcuefiles != 0 ] ; then  
			echo ""
			echo -e "\e[34m➤\e[0m Scan de $j : $countcuefiles CUE, $countmp3files MP3 dans $countdir sous-dossiers"
		fi


		# pour chacun des dossiers dans $soucedir/$j (/_albums/AlbumNameDir)
		for k in $j/* ; do

				goodtogo=0

			# si c'est un dossier (torrent)
			if [ -d "$k" ] ; then

			
				# on rentre dans $LOSSLESS_SOURCE_DIR/$j (exemple: /_music/_albums/)
				cd "$k"
				

				# on compte les fichiers qui nous intéressent dans ce dossier torrent
				countcuefiles=$(find . -type f -iname "*.cue" | wc -l)
				countmp3files=$(find . -type f -iname "*.mp3" | wc -l)
				countlosslessfiles=$((countflacfiles + countapefiles))

				

				# si il y a des fichiers, on rentre dans le dossier et on affiche des infos
				if [ $countcuefiles != 0 ]  ; then

					echo ""
					echo -e "  \e[34m➤\e[0m Split de $countcuefiles fichiers dans /"$(basename "$k")
					echo ""

					cd "$k"

					# pour chaque fichier du dossier final
					for cuefile in *.cue ; do

	 
					 	audiofile="${cuefile%.cue}.mp3"
					 	 
			
					 	# le mp3 correspondant au cue existe
					 	if [ -f "$CUE_SOURCE_DIR/$audiofile" ] ; then
					 		goodtogo=1

					 	# au cas où le mp3 correspond au cue n'est pas trouvé
					 	else

					 		#echo "    $cuefile : le MP3 correspondant au CUE n'est pas trouvé"

					 		countmp3files=$(find "$k" -type f -iname "*.mp3" | wc -l)
					 		# si il n'y a qu'un seul mp3 d'un autre nom, on considère que c'est le bon
							if [ "$countmp3files" = 1 ] ; then  
								
								audiofile=$(find "$k" -type f -iname "*.mp3")
								goodtogo=1

							
							# si il y a plus d'un fichier mp3
							else 

								# on vérifie si il y a plus de mp3 que de flac (= album deja converti)
								if [ "$countmp3files" -gt "$countcuefiles" ]; then
						            echo -e "    \e[34m↔\e[0m $cuefile : suppression de $countcuefiles fichier(s) CUE ($countmp3files MP3 présents)"
						            echo ""
						            if [ "$SAND_BOX" = false ] ; then 
							            find "$k" -maxdepth 1 -type f -name "*.cue" -delete 
							            count_cuedeleted=$((count_cuedeleted+1))
							        fi
						            goodtogo=0

						        # si il y a autant de mp3 que de cue (album non converti et mal nommé)
						        else

									echo -e "    \e[91m✖\e[0m $cuefile : Le mp3 correspondant n'est pas correctement nommé. Fichiers mp3 dans ce dossier :"
									echo ""
									ls -d "$CUE_SOURCE_DIR/*.mp3"
									echo ""

									read -e -p "      Corriger le nom du fichier MP3 à splitter d'après le CUE : "  audiofile

									# si on répond rien, on annule
									if [ -z "$audiofile" ] ; then 
										echo -e "  \e[91m✖\e[0m Annulation"
										goodtogo=0
										exit
									else
										goodtogo=1
									fi

								fi
							fi
						fi
					# boucle dossier final terminée	
					done
					echo ""
					cd .. # on remonte d'un niveau
				fi # a virer si decomment du else en dessous
				#else # si aucun fichier lossless n'est trouvé ici
				#	 echo -e "\e[34m✓\e[0m Aucun fichier lossless dans $k"
				#fi
			fi
	 
	 
		 	if [ "$goodtogo" = 1 ]; then
		 		echo ""
			 	echo -en "    $audiofile"
 
			 	mp3splt -q -a -c "$cuefile" -o @n.\ @t "$audiofile" > $temp_log_file 2>&1  

			 	if [ $? -eq 0 ]; then 
			 		count_splitted=$((count_converted+1)) # compteur de fichiers convertis
			 		echo -en "\r    \e[32m✓\e[0m $audiofile"
			 		if [ "$SAND_BOX" = false ] ; then 
				 		#echo "    Suppression des fichiers obsolètes"
				 		if [ -f "$PWD/$cuefile" ] ; then rm -i "$PWD/$cuefile" ; count_cuedeleted=$((count_deleted+1)) ; fi
						if [ -f "$PWD/$audiofile" ] ; then rm  -i "$PWD/$audiofile" ; count_mp3deleted=$((count_deleted+1)) ; fi
						
						
					fi
				else
					count_errors=$((count_errors+1)) # compteur d'erreurs
					error_files="DECODE ERROR: $audiofile"$'\n'"${error_files}"
					echo -e "\r    \e[91m✖\e[0m $audiofile"
					echo ""
				fi
			fi
 
		done
	done

	# on calcule le nombre de secondes écoulées depuis le début des conversions
	allsplit_duration=$(($SECONDS - $allsplit_start))


	echo -ne "   \e[32m✓\e[0m Opérations terminées en $(($allsplit_duration / 60)) min ($allsplit_duration sec) : "
	echo_log 0 "$count_converted conversions terminées en $(($allsplit_duration / 60)) min ($allsplit_duration sec) : $count_deleted supprimés, $count_keep conservés, $count_skipped passés, $count_overwrite écrasés, $count_errors erreurs."

	echo -n "$count_splitted fichiers splittés"

	if [ "$count_cuedeleted" -ge 1 ] ; then
		echo -n " / $count_cuedeleted CUE supprimés"
	fi

	if [ "$count_mp3deleted" -ge 1 ] ; then
		echo -n " / $count_mp3deleted MP3 supprimés"
	fi

	if [ "$count_errors" -ge 1 ] ; then
		echo  " / $count_errors erreurs :"
		echo -e "$error_files"
	fi


 
# aucun fichier CUE trouvé
else
	echo ""
	echo -e "  \e[32m✓\e[0m Aucun fichier CUE dans $CUE_SOURCE_DIR"
fi

# on enlève le lock
lock_off $currentscript
