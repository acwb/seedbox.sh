#!/bin/bash

echo -e "   \e[2m[vérification du bon fonctionnement de divers processus]\e[0m"  
echo""

services=($SERVICES)

# pour chaque processus indiqués dans la config
for service in "${services[@]}" ; do

    echo -ne "   \e[34m➤\e[0m Processus $service"

    if (( $(ps -ef | grep -v grep | grep $service | wc -l) > 0 )) ; then
    	echo -en "\r   \e[32m✓\e[0m Processus $service : en fonctionnement \n"
    else

        echo -en "\r   \e[91m✖\e[0m $service : hors service "

        if [ "$RUN_MISSING" = true ]; then
            service $service start &> /dev/null
            if [ $? -eq 0 ]; then 
            	echo -en "\r   \e[32m✓\e[0m Démarrage du processus $service \n"
            else
            	echo -en "\r   \e[91m✖\e[0m Erreur lors du lancement de $service \n"
            fi
        else
        	echo -en "(option RUN_MISSING désactivée) \n"
        	send_notif "Processus HS" "$service est manquant"
        fi
    fi
done