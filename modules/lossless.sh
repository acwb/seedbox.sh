#!/bin/bash

which flac > /dev/null || { echo "Installation de la dépendance flac"; echo "" ; sudo apt-get install flac; }
which lame > /dev/null || { echo "Installation de la dépendance lame"; echo "" ; sudo apt-get install lame;}
which avconv > /dev/null || { echo "Installation de la dépendance libav-tools (avconv)"; echo "" ; sudo apt-get install libav-tools;}

# préparation de vars
currentscript="lossless"
log_file=$scriptpath/logs/$currentscript.log
lame_log_file=$scriptpath/logs/lame.log
flac_log_file=$scriptpath/logs/flac.log
avconv_log_file=$scriptpath/logs/avconv.log


# pour gérer les espaces dans les filenames
OLDIFS=$IFS
IFS=$(echo -en "\n\b")


echo -e "   \e[2m[conversion des fichiers audio lossless: FLAC, APE]\e[0m"
sleep 1

if [ "$MP3_OVERWRITE" = true ] ; then MP3_OVERWRITE="-y" ; else MP3_OVERWRITE="" ; fi
if [ "$WAV_OVERWRITE" = true ] ; then WAV_OVERWRITE="-f" ; else WAV_OVERWRITE="" ; fi


# initialisation/remise à zéro des compteurs
count_converted=0
count_skipped=0
count_overwrite=0
count_errors=0
count_deleted=0
count_keep=0
allconv_start=$SECONDS # chronométrage des conversions

# on se place dans le dossier source
cd "$LOSSLESS_SOURCE_DIR"

# permet d'éviter que var="*.ext" si aucun fichier du type
shopt -s nullglob


# cherche si il y a des fichiers dans les 2 premiers niveaux (hors de leur subdir)
countrootfiles=$(find $LOSSLESS_SOURCE_DIR/* -maxdepth 1 -type f | wc -l)
if [ $countrootfiles != 0 ] ; then
	echo ""
	echo -e "  \e[91m✖\e[0m Fichiers orphelins à ranger dans des subdirs : \n"
	for h in `find $LOSSLESS_SOURCE_DIR/* -maxdepth 1 -type f` ; do
		echo "      $h"
	done
fi


# on cherche les fichiers lossless dans le dossier source
countflacfiles=$(find $LOSSLESS_SOURCE_DIR -type f -iname "*.flac" | wc -l)
countapefiles=$(find $LOSSLESS_SOURCE_DIR -type f -iname "*.ape" | wc -l)
countflacdir=$(find $LOSSLESS_SOURCE_DIR -name "*.flac" | grep -o '.*/' | sort | uniq | wc -l)
countapedir=$(find $LOSSLESS_SOURCE_DIR -name "*.ape" | grep -o '.*/' | sort | uniq | wc -l)  


# on affiche des infos seulement si des fichiers lossless sont trouvés
if [ $countflacfiles != 0 ] || [ $countapefiles != 0 ] ; then

	# on affiche les infos de ce sous dossier avec le nb de fichiers trouvés
	#echo ""
	#echo "*************************************************************************"
	#echo_log 1 "$PWD  "
	echo ""

	if [ $countflacfiles != 0 ] ; then
	  echo -e "  \e[34m➤\e[0m Albums en FLAC à convertir ($countflacfiles FLAC dans $countflacdir dossiers) :"
	  echo ""
	  for h in `find "$LOSSLESS_SOURCE_DIR" -name "*.flac" | grep -o '.*/' | sort | uniq  ` ; do
		echo "      $h"
	   done
	fi

	if [ $countapefiles != 0 ] ; then  
	  echo -e "  \e[34m➤\e[0m Albums en APE à convertir ($countapefiles APE dans $countapedir dossiers) :"
	  echo ""
	  for h in `find "$LOSSLESS_SOURCE_DIR" -name "*.ape" | grep -o '.*/' | sort | uniq  ` ; do
		echo "      $h"
	  done
	fi   

	# on vérifie si on a besoin de créer le dossier à l'emplacement de destination
	#newdir=$LOSSLESS_DEST_DIR/`basename $PWD`
	#if [ ! -d newdir ] ; then mkdir -p $newdir ; fi
fi



# pour chaque subdirectory du dossier source (dossiers catégorie)
for j in `find $LOSSLESS_SOURCE_DIR -mindepth 1 -maxdepth 1 -type d` ; do

	# on compte les fichiers qui nous intéressent dans ce dossier
	countdir=$(find $j/ -type d | grep -o '.*/' | wc -l)  
	countflacfiles=$(find $j/ -type f -iname "*.flac" | wc -l)
	countapefiles=$(find $j/ -type f -iname "*.ape" | wc -l)
	countmp3files=$(find $j/ -type f -iname "*.mp3" | wc -l)
	countlosslessfiles=$((countflacfiles + countapefiles))

	if [ $countlosslessfiles != 0 ] ; then  
		echo ""
		echo -e "  \e[34m➤\e[0m Scan de $j : $countflacfiles FLAC, $countapefiles APE, $countmp3files MP3 dans $countdir sous-dossiers"
	fi

	# si c'est un fichier, on prévient qu'il ne sera pas traité
	if [ -f "$j" ] ; then
		if [[ $j =~ \.flac$ ]] || [[ $j =~ \.ape$ ]]  ; then
			jfilename=$(basename "$j")
			echo -e "    \e[91m✖\e[0m À ranger dans un sous-dossier : $jfilename"
		fi
	fi


	# pour chacun des dossiers dans $soucedir/$j (/_albums/AlbumNameDir)
	for k in $j/* ; do


		# si c'est un fichier, on prévient qu'il ne sera pas traité
		if [ -f "$k" ] ; then
			if [[ $k =~ \.flac$ ]] || [[ $k =~ \.ape$ ]]  ; then
				kfilename=$(basename "$k")
				echo -e "    \e[91m✖\e[0m À ranger dans un sous-dossier : $kfilename"
			fi
		fi


		# si c'est un dossier (torrent)
		if [ -d "$k" ] ; then

			

			# on rentre dans $LOSSLESS_SOURCE_DIR/$j (exemple: /_music/_albums/)
			cd "$k"
			

			# on compte les fichiers qui nous intéressent dans ce dossier torrent
			countflacfiles=$(find . -type f -iname "*.flac" | wc -l)
			countapefiles=$(find . -type f -iname "*.ape" | wc -l)
			countmp3files=$(find . -type f -iname "*.mp3" | wc -l)
			countlosslessfiles=$((countflacfiles + countapefiles))

			

			# si il y a des fichiers, on rentre dans le dossier et on affiche des infos
			if [ $countflacfiles != 0 ] || [ $countapefiles != 0 ] ; then

				echo ""
				if [ $countmp3files != 0 ] ; then
					echo -e "    \e[34m➤\e[0m Poursuite de la conversion de $countlosslessfiles fichiers dans /$(basename "$k") ($countmp3files MP3 présents)"
				else
					echo -e "    \e[34m➤\e[0m Conversion de $countlosslessfiles fichiers dans /"$(basename "$k")
				fi
				
				echo ""

				cd "$k"

				# pour chaque fichier du dossier final
				for i in * ; do

					# si il s'agit d'un sous dossier
					if [ -d "$i" ] ; then
						# on ne prévient du sous dossier que si il y a des fichiers audio
						countflacfiles=$(find . -type f -iname "*.flac" | wc -l)
						countapefiles=$(find . -type f -iname "*.ape" | wc -l)
						countmp3files=$(find . -type f -iname "*.mp3" | wc -l)
						countlosslessfiles=$((countflacfiles + countapefiles))
						if [ $countlosslessfiles != 0 ] ; then
					 		echo -e "    \e[91m✖\e[0m $i >> sous-dossier contenant des audio (à déplacer)"
					 	fi
					fi

					# si il s'agit d'un fichier
					if [ -f "$i" ]; then

						ifilename=$(basename "$i") 
						# on vérifie son extension
					    if [[ $i =~ \.flac$ ]] || [[ $i =~ \.ape$ ]]; then
					  		source $scriptpath/inc/flacloop.inc
					  	# on ignore les autres types de fichiers
					    elif [[ $i =~ \.mp3$ ]] || [[ $i =~ \.txt$ ]] || [[ $i =~ \.log$ ]] || [[ $i =~ \.nfo$ ]] || [[ $i =~ \.jpg$ ]] || [[ $i =~ \.jpeg$ ]] || [[ $i =~ \.png$ ]] || [[ $i =~ \.wav$ ]] || [[ $i =~ \.cue$ ]] || [[ $i =~ \.m3u$ ]] || [[ $i =~ \.pls$ ]] || [[ $i =~ \.db$ ]] || [[ $i =~ \.ini$ ]] || [[ $i =~ \.DS_Store$ ]]       ; then
					    	echo -n ""
					    else
					  		echo -e "      \e[91m✖\e[0m $ifilename >> fichier non supporté"
					  	fi
					fi
				# boucle dossier final terminée	
				done
				echo ""
				if [ "$count_converted" != 0 ]; then
					echo -e "    \e[32m✓\e[0m $count_converted conversions effectuées dans /"$(basename "$k")
				fi
				if [ "$count_keep" != 0 ] || [ "$count_deleted" != 0 ]; then
					echo -e "    \e[34m↔\e[0m $count_deleted fichiers sources supprimés, $count_keep conservés "
				fi
				if [ "$count_errors" != 0 ]; then
					echo -e "    \e[91m✖\e[0m $count_errors erreurs de conversion dans /"$(basename "$k")
				fi
				cd .. # on remonte d'un niveau
			fi # a virer si decomment du else en dessous
			#else # si aucun fichier lossless n'est trouvé ici
			#	 echo -e "\e[34m✓\e[0m Aucun fichier lossless dans $k"
			#fi
		fi
	done
 
done # fin de toutes les boucles    

# on calcule le nombre de secondes écoulées depuis le début des conversions
allconv_duration=$(($SECONDS - $allconv_start))

echo ""



 if [ -n "${error_files}" ]; then
    echo -e "    \e[91m✖\e[0m Erreurs de conversion, vérifier les fichiers suivants :\n\n$error_files"
    echo_log 0 "Erreurs decode/encode / Vérifier les fichiers suivants :\n$error_files"
  fi


if [ "$count_converted" -ge 1 ] ; then

  echo -ne "  \e[32m✓\e[0m Opérations terminées en $(($allconv_duration / 60)) min ($allconv_duration sec) : "
  echo_log 0 "$count_converted conversions terminées en $(($allconv_duration / 60)) min ($allconv_duration sec) : $count_deleted supprimés, $count_keep conservés, $count_skipped passés, $count_overwrite écrasés, $count_errors erreurs."

  echo -n "$count_converted conversions"

  if [ "$count_deleted" -ge 1 ] ; then
    echo -n " / $count_deleted flac supprimés"
  fi

  if [ "$count_keep" -ge 1 ] ; then
    echo -n " / $count_keep flac conservés"
  fi

  if [ "$count_skipped" -ge 1 ] ; then
    echo -n " / $count_skipped passés"
  fi

  if [ "$count_overwrite" -ge 1 ] ; then
    echo -n " / $count_overwrite écrasés"
  fi

  if [ "$count_errors" -ge 1 ] ; then
    echo -n " / $count_errors erreurs"
  fi

  echo ""
  
  # notification si le nombre de conversions terminées est particulièrement élevé
  if [ "$count_converted" -ge $CONV_NOTIF ] ; then
  	send_notif "Conversions audio" "$count_converted conversions audio terminées"
  fi

else
  echo -e "  \e[32m✓\e[0m Aucune conversion dans $LOSSLESS_SOURCE_DIR"
  echo_log 0 "Aucun fichier à convertir."

fi


# on enlève le lock
lock_off $currentscript

#bash ~/scripts/util/transit-perms.sh




IFS=$OLDIFS

