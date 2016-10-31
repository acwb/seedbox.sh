#!/bin/bash

# préparation de vars
START_TIME=$SECONDS # initialisation du chronométrage des conversions
currentscript="seedbox"
log_file=$scriptpath/logs/$currentscript.log
temp_log_file=$scriptpath/logs/lftp.log

# masquage de certaines infos si mode démo activé
if [[ "$DEMO_MODE" = true ]]; then
	FTP_USER_OUTPUT="*****"
	FTP_HOST_OUTPUT="*****"
else
	FTP_USER_OUTPUT="$FTP_USER"
	FTP_HOST_OUTPUT="$FTP_HOST"
fi

echo -e "   \e[2m[synchronisation de la Seedbox : $FTP_USER_OUTPUT@$FTP_HOST_OUTPUT]\e[0m"
echo ""

echo_log 0 "Synchronisation du FTP $FTP_USER@ftp.$FTP_HOST vers $FTP_LOCAL_DIR"
echo -n "   " ; echo_log 1 "\e[2mConnexion au serveur FTP:\e[0m $FTP_USER_OUTPUT@$FTP_HOST_OUTPUT"
echo -n "   " ; echo_log 1 "\e[2mPrioritaire(s):\e[0m  $MIRROR_ORDER  \e[2m/  Ignoré(s):\e[0m  $MIRROR_EXCLUDE"  
echo -n "   " ; echo_log 1 "$DL_PARALLEL \e[2mtéléchargement(s) parallèles - Segmentation des fichiers en\e[0m $DL_SEGMENT"
echo -n "   " ; echo_log 1 "\e[2mLimite de débit:\e[0m $DL_SPEED Ko/s  \e[2m/  Option(s):\e[0m  $MIRROR_OPTIONS "
echo ""


echo -ne "   \e[34m➤\e[0m Connexion au serveur et listing des fichiers "

# PARTIE A MODIFIER SELON LES BESOIN
countmusic1=`curl -l -s -u $FTP_USER:$FTP_PWD ftp://$FTP_HOST/_music/_albums/ | wc -l` ; sleep 0.1 ; echo -n "."
countmusic2=`curl -l -s -u $FTP_USER:$FTP_PWD ftp://$FTP_HOST/_music/_BO/ | wc -l`;sleep 0.1;echo -n "."
countmusic3=`curl -l -s -u $FTP_USER:$FTP_PWD ftp://$FTP_HOST/_music/_VA/ | wc -l`;sleep 0.1;echo -n "."
countfilms=`curl -l -s -u $FTP_USER:$FTP_PWD ftp://$FTP_HOST/_films/ | wc -l`;sleep 0.1;echo -n "."
countseries=`curl -l -s -u $FTP_USER:$FTP_PWD ftp://$FTP_HOST/_series/ | wc -l`;sleep 0.1;echo -n "."
countdocus=`curl -l -s -u $FTP_USER:$FTP_PWD ftp://$FTP_HOST/_docus/ | wc -l`;sleep 0.1;echo -n "."
countpodcasts=`curl -l -s -u $FTP_USER:$FTP_PWD ftp://$FTP_HOST/_podcasts/ | wc -l`;sleep 0.1;echo -n "."
countress=`curl -l -s -u $FTP_USER:$FTP_PWD ftp://$FTP_HOST/_ress/ | wc -l`;sleep 0.1;echo -n "."
countebooks=`curl -l -s -u $FTP_USER:$FTP_PWD ftp://$FTP_HOST/_ebooks/ | wc -l`;sleep 0.1;echo -n "."
countseed=`curl -l -s -u $FTP_USER:$FTP_PWD ftp://$FTP_HOST/__seed/ | wc -l`;sleep 0.1;echo ""
countincomplete=`curl -l -s -u $FTP_USER:$FTP_PWD ftp://$FTP_HOST/__incomplete/ | wc -l`
countmusic=$(( $countmusic1 + $countmusic2 + $countmusic3))
countfiles=$(( $countmusic1 + $countmusic2 + $countmusic3 + $countfilms + $countseries + $countdocus + $countpodcasts + $countress + $countebooks))
echo ""
echo -ne "     " ; echo_log 1 "\e[0m$countincomplete\e[2m torrents en cours - \e[0m$countseed\e[2m torrents en seed - \e[0m$countfiles\e[2m torrents terminés :"
echo -ne "     "
if [ $countmusic -ge 1 ]; then  echo -ne "\e[0m$countmusic\e[2m albums " ; fi
if [ $countfilms -ge 1 ]; then  echo -ne "\e[0m$countfilms\e[2m films " ; fi
if [ $countseries -ge 1 ]; then  echo -ne "\e[0m$countseries\e[2m épisodes " ; fi
if [ $countdocus -ge 1 ]; then  echo -ne "\e[0m$countdocus\e[2m docs " ; fi
if [ $countpodcasts -ge 1 ]; then  echo -en "\e[0m$countpodcasts\e[2m podcasts " ; fi
if [ $countress -ge 1 ]; then  echo -ne "\e[0m$countress\e[2m ressources " ; fi
if [ $countebooks -ge 1 ]; then  echo -ne "\e[0m$countebooks\e[2m ebooks " ; fi  
 

if [ $countfiles = 0 ]; then
  echo -ne "     \e[2m" ;  echo_log 1 "Aucun torrent disponible"
  echo -e "\e[0m\n"

else

  echo -e "\e[0m\n"
  echo -ne "   \e[34m➤\e[0m Lancement de la synchronisation des $countfiles torrents \n \n"  
  sleep 1

lftp -u $FTP_USER,$FTP_PWD $FTP_HOST << EOF
set ftp:ssl-allow no
set mirror:order '$MIRROR_ORDER'
set net:limit-total-rate '$DL_SPEED'K
mirror -c $MIRROR_OPTIONS --parallel=$DL_PARALLEL --use-pget-n=$DL_SEGMENT --exclude-glob $MIRROR_EXCLUDE --log=$temp_log_file  --verbose "$FTP_REMOTE_DIR" "$FTP_LOCAL_DIR"
quit
# doit être en début de ligne
EOF

  # si la commande s'est terminé sans erreurs
  if [ $? -eq 0 ]; then

    now=$(date +"%Y/%m/%d %H:%M:%S")
    ELAPSED_TIME=$(($SECONDS - $START_TIME))

    echo -ne "   \e[32m✓\e[0m Synchronisation terminée en $(($ELAPSED_TIME / 60)) min ($ELAPSED_TIME sec) \n"
    echo_log 0 "Synchronisation terminée en $(($ELAPSED_TIME / 60)) min ($ELAPSED_TIME sec)"

  else
    echo -e "\r   \e[91m✖\e[0m La synchronisation ne s'est pas correctement déroulée. \n" 
    echo_log 0 "La synchronisation ne s'est pas correctement déroulée." 

  fi

fi


 

# opération terminée: suppression du lock
lock_off $currentscript

# traitement du fichier log
cat $temp_log_file >> $log_file
sed -i 's/%20/ /g' "${log_file}"




