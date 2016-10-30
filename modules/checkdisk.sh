#!/bin/bash

echo -e "   \e[2m[vérification du montage des disques et de l'espace disponible]\e[0m"  
echo""

disks=($LOCAL_DISKS)
notifcontent=""
count_exceeted="0"
count_missing="0"

# pour chaque disque (mount paths) indiqués dans la config
for disk in "${disks[@]}" ; do

    disk_output=$(basename $disk)
    disk_mounted=false

    echo -ne "   \e[34m➤\e[0m Vérification du disque $disk_output.."

    # on vérifie si le disque est bien monté
    if mount | grep "on ${disk} type" > /dev/null ; then disk_mounted=true ; fi
    if mount | grep "${disk} on" > /dev/null ; then disk_mounted=true ; fi

    # si le disque est absent, on affiche une alerte
    if [ "$disk_mounted" = false ]; then
        count_missing=$((count_missing+1))
        alert_notif="$notifcontent Disque $disk_output absent \n"  
        echo -e "\r   \e[91m✖\e[0m Vérification du disque $disk_output : \e[91mABSENT\e[0m "
    else

        # on vérifie si l'emplacement n'est pas vide (disque non monté remplacé par dossier local existant)
        if [ "$(ls -A $disk)" ]; then 
        
            # récupération des infos d'espace occupé/libre avec la commande df -h
            used_pourcent=$(df -h | grep ${disk} | awk {'print $5'})
            free_space=$(df -h | grep ${disk} | awk {'print $4'})
            used_space=$(df -h | grep ${disk} | awk {'print $3'})
            total_space=$(df -h | grep ${disk} | awk {'print $2'})

            # si la valeur récupérée est valide
            if [ ${used_pourcent} ]; then

                used_pourcent_output=${used_pourcent::-1}   
                used_pourcent_output=$(format_pourcent $used_pourcent_output)

                # on vérifie si le % utilisé est supérieur au % indiqué dans la config
                if [ ${used_pourcent%?} -ge ${SPACE_ALERT%?} ]; then 
                    count_exceeted=$((count_exceeted+1))  
                    echo -e "\r   \e[91m✖\e[0m Vérification du disque $disk_output : $used_pourcent_output utilisés sur $total_space -> $free_space d'espace libre"
                    alert_notif="$notifcontent Disque $disk_output : $free_space d'espace libre \n"
                else
                    echo -e "\r   \e[32m✓\e[0m Vérification du disque $disk_output : $used_pourcent_output utilisés sur $total_space -> $free_space d'espace libre"
                fi
            else
                echo -e "\r   \e[91m✖\e[0m Vérification du disque $disk_output : les infos d'espace occupé et libre n'ont pas pu être récupérées"
            fi

        else
            count_missing=$((count_missing+1))
            alert_notif="$notifcontent Disque $disk_output absent \n" 
            echo -e "\r   \e[91m✖\e[0m Le disque $disk_output est vide, erreur de montage ?"
        fi
    fi

done

if [[ "$count_missing" -ge 1 ]]; then

    echo ""
    echo -e "\r   \e[91m✖\e[0m $count_missing disque(s) absent(s)"
    send_notif "Alerte disque" "$alert_notif"

    # si le disque manquant est celui assigné au backup, on ne stoppe pas l'execution du script
    # par contre on arrête le service crashplan pour éviter qu'il sature le disque local
    if [[ "$disk_output" = "$BACKUP_DISK" ]]  ; then
        echo -ne "\n\n   \e[34m➤\e[0m Le disque de backup $BACKUP_DISK n'est pas monté"
        if (( $(ps -ef | grep -v grep | grep $BACKUP_PROC | wc -l) > 0 )) ; then
            echo -e ", arrêt de $BACKUP_PROC." 
            service $BACKUP_PROC stop
        else
            echo -e ", $BACKUP_PROC n'est pas en fonctionnement."
            if [[ "$BACKUP_FORCE" = false ]]; then
                exit 0
            fi
        fi
    else
        # on arrête l'execution du script sauf si le paramètre force est actif
        if [[ "$SPACE_FORCE" = false ]] ; then
            panic_button checkdisk " : $count_missing disque(s) absent(s)"
        fi
    fi
    echo ""
fi

if [[ "$count_exceeted" -ge 1 ]]; then

    echo ""
    echo -e "\r   \e[91m✖\e[0m $count_exceeted dépassement(s) du quota d'utilisation maximum d'espace disque ($SPACE_ALERT)"
    send_notif "Alerte disque" "$alert_notif"

    if [[ "$SPACE_FORCE" = false ]]; then
        panic_button checkdisk " : dépassement du quota d'utilisation maximum d'espace disque ($SPACE_ALERT)"
    fi
    echo ""
fi


