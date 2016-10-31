# Seedbox.sh

> Destiné à être executé en mode automatique dès le démarrage,
> ce script automatise la récupération et le traitement de fichiers
> téléchargés depuis une seedbox et suivant plusieurs étapes : 

### [1] SERVICES.sh >> Vérification des services

	Vérifie que les processus paramétrés dans la configuration 
	sont bien en cours de fonctionnement.
	Option par défaut: lancer les processus manquants (RUN_MISSING)

### [2] CHECKDISK.sh >> Vérification des disques

	Contrôle le montage et l'espace libre des disques locaux paramétrés
	Empêche l'exécution du script si un disque est marqué comme manquant
	
	Si le disque de backup paramétré est absent et vide (dossier local),
	un certain processus est arrêté (crashplan par défaut)

### [3] FTPSYNC.sh >> Synchronisation uni-directionnelle d'une seedbox via FTP

	Méthode utilisée: lftp
	Option par défaut: supprime les fichiers de la seedbox après leur téléchargement
	Paramètres à éditer: > host et authentification FTP
					  	 > emplacement fichiers sur seedbox
					  	 > emplacement fichiers locaux

### [4] LOSSLESS.sh >> Convertir automatiquement tous les fichiers LOSSLESS en MP3

	Méthode utilisée: avconv, flac, lame
	Formats audio compatibles : mp3, ape
	Options par défaut: - écrase si besoin le fichier mp3 si incomplet
						- supprime le lossless si mp3 présent et conforme
						- supprime le lossless après conversion
 	NB: non récursif, prévu pour sourcedir/category/albumdir/track.flac

### [5] CUESPLIT.sh >> Splitter les éventuelles audio "image" d'après fichiers CUE

	Méthode utilisée: mp3splt
	Options par défaut: - supprime le fichier CUE après split réussi
						- supprime le fichier image après split réussi

### [6] GRABBER.sh >> Synchronisation de playlists YouTube

	Recherche et télécharge les nouvelles vidéos contenues dans plusieurs fichiers "todl"
	Méthode utilisée : youtube-dl
	Options par défaut: 
				- renomme les fichiers pour compatibilité avec Plex
				- télécharge la cover, description et les éventuels sous-titres
				- log les vidéos pour ne pas les télécharger plus d'une fois

### [7] CLEANUP.sh >> Nettoyer les fichiers inutiles dans le répertoire de destination

	Méthode utilisée: find -delete
	Type de fichiers supprimés par défaut: pls, m3u, log, url, nfo, gif, bmp, part
	Noms de fichiers supprimés par défaut: thumbs.db, desktop.ini, .DS_Store


## OPTIONS

Le script peut être executé sans option via la commande ./start.sh
la configuration par défaut (config.conf) est alors utilisée.

	-p=[module], --bypass=[module]  ne pas executer tel script ()
	                                exemple -s=seedbox pour passer directement au script suivant
	-l=[speed], --limit=[speed]     régler une limitation de débit download en Ko/s
	-r=[time], --restart=[time]     régler le temps d'attente en heures avant restart (mode auto only)
	-m, --mute                      n'envoyer aucune notification
	-a, --auto                      mode auto, aucune interaction de l'utilisateur nécessaire
	-i, --interactive               mode manuel, demande plus de confirmations que par défaut
	-t,, -s, --test, --sandbox      mode test, s'agit pas sur les fichiers (pas de conv ni suppression)
	-h, --help                      afficher cette aide

	EXAMPLES
	start.sh -a --limit=200	 		lancement en mode automatique avec limitation de débit à 200 Ko/s
	start.sh -i --bypass=seedbox 	lancement en mode interactif en passant le module seedbox
	start.sh lossless -t 			lancement du module lossless uniquement en mode test