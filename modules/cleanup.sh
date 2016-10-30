#!/bin/bash
currentscript="cleanup"

echo -e "   \e[2m[recherche et nettoyage de fichiers inutiles]\e[0m"  
echo ""
 
# réinitialisation des options
tagcommand_delete="-delete"  

# paramétrage des options selon config
if [ "$SAND_BOX" = true ] ; then
	echo "Mode SANDBOX"
	tagcommand_delete=""
fi
 
# on revérifie les paramètres au cas où (dangereux si certains vars sont vides)
check_params &> /dev/null


# mise en array des paramètres de fichiers à rechercher
filenames=($CLEANUP_NAME)
filetypes=($CLEANUP_EXT)


echo -ne "   \e[34m➤\e[0m Nettoyage de $CLEANUP_DIR \n \n"


# nettoyage par nom de fichier
for filename in "${filenames[@]}" ; do

	goodtodel=0

	echo -ne "     \e[34m➤\e[0m Recherche de fichiers $filename"

	countfnametodel=$(find "$CLEANUP_DIR" -type f -iname "$filename" | wc -l)
	if [ "$countfnametodel" != 0 ] ; then  

		# si le mode interactif est actif
		if [ "$MANUAL_RUN" = true ] || [ "$AUTO_RUN" = false ]  ; then
			
			# on liste les fichiers concernés
			echo ""
			echo ""
			find "$CLEANUP_DIR" -type f -name "*$filename"
			echo ""

			# on demande confirmation avant suppression
			read -n1 -r -p "Confirmer la suppression de ces fichiers $filename ? (o/N) " key
		    if [[ $key =~ ^([oO])$ ]] ; then
		    	echo ""
		      goodtodel=1
		    else
		      echo -en "\r     \e[91m✖\e[0m Fichiers $filename non supprimés \n"
		      goodtodel=0
		    fi

		fi

		if [ "$goodtodel" = 1 ] || [ "$AUTO_RUN" = true ] ; then

			# l'option -delete n'est pas insérée en mode sandbox
			listfiletodel=$(find "$CLEANUP_DIR" -type f -name "*$filename" $tagcommand_delete)
			echo $listfiletodel
			echo ""

			if [ $? -eq 0 ]; then
				count_clean=$((count_clean+countfnametodel))  
				deletedfiles=$((deletedfiles+listfiletodel))
				echo -en "\r     \e[32m✓\e[0m Suppression de $countfnametodel fichiers $filename \n"
			else
				echo -en "\r     \e[91m✖\e[0m Fichiers $filename non supprimés \n"
			fi
		fi
		echo ""
	else
		sleep 0.1
		echo -en "\r     \e[32m✓\e[0m Nettoyage des fichiers $filename \n"
	fi
done


# nettoyage par type de fichier
for filetype in "${filetypes[@]}" ; do

	goodtodel=0


	echo -ne "     \e[34m➤\e[0m Recherche de fichiers .$filetype"

	countexttodel=$(find "$CLEANUP_DIR" -type f -iname "*.$filetype" | wc -l)
	if [ "$countexttodel" != 0 ] ; then  

		# si le mode interactif est actif
		if [ "$MANUAL_RUN" = true ] || [ "$AUTO_RUN" = false ]  ; then
			
			# on liste les fichiers concernés
			echo ""
			find "$CLEANUP_DIR" -type f -name "*.$filetype"
			echo ""

			# on demande confirmation avant suppression
			read -n1 -r -p "Confirmer la suppression de ces fichiers .$filetype ? (o/N) " key
		    if [[ $key =~ ^([oO])$ ]] ; then

		      goodtodel=1
		    else
		    	echo -en "\r     \e[91m✖\e[0m Fichiers .$filetype non supprimés \n"
		      goodtodel=0
		    fi

		fi

		if [ "$goodtodel" = 1 ] || [ "$AUTO_RUN" = true ] ; then

			# l'option -delete n'est pas insérée en mode sandbox
			listfiletodel=$(find "$CLEANUP_DIR" -type f -name "*.$filetype" $tagcommand_delete)

			if [ $? -eq 0 ]; then
				count_clean=$((count_clean+countexttodel))
				deletedfiles=$((deletedfiles+listfiletodel))
				echo -en "\r     \e[32m✓\e[0m Suppression de $countfnametodel fichiers .$filetype \n"
			else
				echo -en "\r     \e[91m✖\e[0m Fichiers .$filetype non supprimés \n"
			fi
		fi
		echo ""
	else
		sleep 0.1
		echo -en "\r     \e[32m✓\e[0m Nettoyage des fichiers .$filetype \n"
	fi


done

echo
echo -ne "   \e[32m✓\e[0m Nettoyage terminé : "
if [ "$count_clean" != "" ] ; then
	echo "$count_clean fichiers supprimés :"
	echo "$deletedfiles"
else
	echo "aucun fichier à supprimer"
fi

