#!/bin/bash
bash $scriptpath/dos2unix.sh 2>/dev/null # A VIRER
#
#==============================================================================
#  ███████╗███████╗███████╗██████╗ ██████╗  ██████╗ ██╗  ██╗   ███████╗██╗  ██╗
#  ██╔════╝██╔════╝██╔════╝██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝   ██╔════╝██║  ██║
#  ███████╗█████╗  █████╗  ██║  ██║██████╔╝██║   ██║ ╚███╔╝    ███████╗███████║
#  ╚════██║██╔══╝  ██╔══╝  ██║  ██║██╔══██╗██║   ██║ ██╔██╗    ╚════██║██╔══██║
#  ███████║███████╗███████╗██████╔╝██████╔╝╚██████╔╝██╔╝ ██╗██╗███████║██║  ██║
#  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝
#==============================================================================
#%
#% DESCRIPTION: Script d'automatisation de seedbox :
#%
#%	 Destiné à être executé en mode automatique dès le démarrage,
#%   ce script automatise la récupération et le traitement de fichiers
#%   téléchargés depuis une seedbox et suivant plusieurs étapes : 
#%
#%	 [1] SERVICES.sh >> Vérification des services
#%
#%		Vérifie que les processus paramétrés dans la configuration 
#%		sont bien en cours de fonctionnement.
#%		Option par défaut: lancer les processus manquants (RUN_MISSING)
#%
#%	 [2] CHECKDISK.sh >> Vérification des disques
#%
#%		Contrôle le montage et l'espace libre des disques locaux paramétrés
#%		Empêche l'exécution du script si un disque est marqué comme manquant
#%		
#%		Si le disque de backup paramétré est absent et vide (dossier local),
#%		un certain processus est arrêté (crashplan par défaut)
#%
#%	 [3] FTPSYNC.sh >> Synchronisation uni-directionnelle d'une seedbox via FTP
#%
#%		Methode utilisée: lftp
#%    	Option par défaut: supprime les fichiers de la seedbox après leur téléchargement
#%   	Paramètres à éditer: > host et authentification FTP
#%						  	 > emplacement fichiers sur seedbox
#%						  	 > emplacement fichiers locaux
#%
#%   [4] LOSSLESS.sh >> Convertir automatiquement tous les fichiers LOSSLESS en MP3
#%
#%    	Méthode utilisée: avconv, flac, lame
#%    	Formats audio compatibles : mp3, ape
#%    	Options par défaut: - écrase si besoin le fichier mp3 si incomplet
#%							- supprime le lossless si mp3 présent et conforme
#%							- supprime le lossless après conversion
#%	 	NB: non récursif, prévu pour sourcedir/category/albumdir/track.flac
#%
#%   [5] CUESPLIT.sh >> Splitter les éventuelles audio "image" d'après fichiers CUE
#%
#%		Méthode utilisée: mp3splt
#%    	Options par défaut: - supprime le fichier CUE après split réussi
#%							- supprime le fichier image après split réussi
#%
#%   [6] GRABBER.sh >> Synchronisation de playlists YouTube
#%
#%		Recherche et télécharge les nouvelles vidéos uploadées dans les playlists
#%		paramétrées dans la configuration.
#%		Méthode utilisée : youtube-dl
#%    	Options par défaut: 
#%					- renomme les fichiers pour compatibilité avec Plex
#%					- télécharge la cover, description et les éventuels sous-titres
#%					- log les vidéos pour ne pas les télécharger plus d'une fois
#%
#%   [7] CLEANUP.sh >> Nettoyer les fichiers inutiles dans le répertoire de destination
#%
#%		Méthode utilisée: find -delete
#%    	Type de fichiers supprimés par défaut: pls, m3u, log, url, nfo, gif, bmp, part
#%    	Noms de fichiers supprimés par défaut: thumbs.db, desktop.ini, .DS_Store
#%
#%
#================================================================
#%
#%	Le script peut être executé sans option via la commande ./start.sh
#%  la configuration par défaut (config.conf) est alors utilisée.
#%
#% OPTIONS
#%
#%    [module]						  executer uniquement le module spécifié
#%    -p=[module], --bypass=[module]  ne pas executer tel script ()
#%                                    exemple -s=ftpsync pour passer directement au script suivant
#%    -l=[speed], --limit=[speed]     régler une limitation de débit download en Ko/s
#%    -r=[time], --restart=[time]     régler le temps d'attente en heures avant restart (mode auto only)
#%    -m, --mute                      n'envoyer aucune notification
#%    -a, --auto                      mode auto, aucune interaction de l'utilisateur nécessaire
#%    -i, --interactive               mode manuel, demande plus de confirmations que par défaut
#%    -t,, -s, --test, --sandbox      mode test, s'agit pas sur les fichiers (pas de conv ni suppression)
#%    -h, --help                      afficher cette aide
#%
#% EXAMPLES
#%    start.sh -a --limit=200	 	  lancement en mode automatique avec limitation de débit à 200 Ko/s
#%    start.sh -i --bypass=ftpsync 	  lancement en mode interactif en passant le module ftpsync
#%    start.sh lossless -t 			  lancement du module lossless uniquement en mode test
#%
#%================================================================
#% IMPLEMENTATION
#%    version         seedbox.sh 0.0.4
#%    author          totoclectic
#%    license         GNU General Public License
#%
#%================================================================
#%  HISTORY
#%     2016/10/17 : Création du script
#%     2016/10/27 : Premier git
#% 	   2016/10/30 : Nouveaux modules: services, checkdisk, grabber
#% 
#%================================================================
#% END_OF_HEADER
#%================================================================

# stocke l'emplacement de ce script
scriptpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" 
currentscript="start"
log_file=$scriptpath/logs/$currentscript.log

# include des fonctions et config
source "$scriptpath/inc/functions.fn"
load_config 

trap_on start # fonction d'interruption du script (CTRL+C)

# détermine si des options ont été spécifiées
if [ $# -eq 0 ]; then defaultconfig=true
else defaultconfig=false ; currentconfig="$@" ; fi

# traitements des options et paramètres de la ligne de commande
while [[ $# -gt 0 ]] ; do
    opt="$1";
    shift; 
    case "$opt" in
        "--" ) break 2;;
        "--bypass"|"-p" )
           MOD_SKIP="$1"; shift;;
        "--bypass="*|"-p="* )   
           MOD_SKIP="${opt#*=}";;
        "--restart"|"-r" )
           AUTO_RESTART="$1"; shift;;
        "--restart="*|"-r="* )   
           AUTO_RESTART="${opt#*=}";;
        "--limit"|"-l" )
           DL_SPEED="$1"; DL_SPEED_FORCE=true; shift;;
        "--limit="*|"-l="* )    
           DL_SPEED="${opt#*=}" ; DL_SPEED_FORCE=true;;
        "--auto"|"-a" )
           AUTO_RUN=true;;
        "--mute"|"-m" )
           MUTE_NOTIF=true;;
        "--interactive"|"-i" )
           MANUAL_RUN=true;;
        "--sandbox"|"--test"|"-s"|"-t" )
           SAND_BOX=true;;
        "--help"|"-h" )
           usage ;;
        *) if [ -f "$scriptpath/modules/$opt.sh" ]; then SOLO_RUN="$opt" ; else echo "le module $scriptpath/modules/$opt.sh n'est pas trouvé" ;  error ; fi ;;
   esac
done

process_params

clear
echo -e "\e[2m
 ███████╗███████╗███████╗██████╗ ██████╗  ██████╗ ██╗  ██╗   ███████╗██╗  ██╗
 ██╔════╝██╔════╝██╔════╝██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝   ██╔════╝██║  ██║
 ███████╗█████╗  █████╗  ██║  ██║██████╔╝██║   ██║ ╚███╔╝    ███████╗███████║
 ╚════██║██╔══╝  ██╔══╝  ██║  ██║██╔══██╗██║   ██║ ██╔██╗    ╚════██║██╔══██║
 ███████║███████╗███████╗██████╔╝██████╔╝╚██████╔╝██╔╝ ██╗██╗███████║██║  ██║
 ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝
 ============================================================================\e[0m"

echo_params
check_params

# si on a spécifié un module dans la ligne de commande, on n'execute que lui
if [ "$SOLO_RUN" != "" ] ; then exec_module $SOLO_RUN ; echo ""; exit 0 ; fi

# sinon on lance la routine d'execution des différents modules dans l'ordre
if [ "$RUN_SERVICES" = true ] ; then exec_module services ; else RUN_SERVICES=false ; fi
if [ "$RUN_CHECKDISK" = true ] ; then exec_module checkdisk ; else RUN_CHECKDISK=false ; fi
if [ "$RUN_FTPSYNC" = true ] ; then exec_module ftpsync ; else RUN_FTPSYNC=false ; fi
if [ "$RUN_LOSSLESS" = true ] ; then exec_module lossless ; else RUN_LOSSLESS=false ; fi
if [ "$RUN_CUESPLIT" = true ] ; then exec_module cuesplit ; else RUN_CUESPLIT=false ; fi
if [ "$RUN_GRABBER" = true ] ; then exec_module grabber ; else RUN_GRABBER=false ; fi
if [ "$RUN_CLEANUP" = true ] ; then exec_module cleanup ; else RUN_CLEANUP=false ; fi


if [ "$RUN_SERVICES" = false ] && [ "$RUN_CHECKDISK" = false ] && [ "$RUN_FTPSYNC" = false ] && [ "$RUN_LOSSLESS" = false ] && [ "$RUN_CUESPLIT" = false ] && [ "$RUN_GRABBER" = false ] && [ "$RUN_CLEANUP" = false ] ; then
	echo "Tous les scripts ont été bypassés."
	exit 0
else
	echo -ne "\n\e[34m➤\e[0m Toutes les opérations sont terminées. "
fi

restart_loop
