<?php 
/*
//  Permet d'ajouter de façon rapide et simple une URL à l'une des ToDownloadLists (/conf/tograb/*)
//
//  Paramètres :
//		- $_GET['url'] >> url de la vidéo/playlist à ajouter
//		- $_GET['file'] >> nom du fichier dans lequel l'ajouter
//						   (par défaut si non renseigné: todl.conf)
//  Après l'URL, une description peut être ajoutée grâce au caractère "#"
//  Les espaces sont automatiquement convertis pour être pris en compte
//
//  Exemple: index.php?url=http://adresse_de_la_video # description optionnelle
//
//  STEPS
//
//  Editer la variable $listpath avec l'emplacement du dossier /tograb
//
//  Déplacer ce fichier ou créer un symlink dans un répertoire du serveur web avec la commande:
//  ln -s <SCRIPT_PATH>/seedbox/php/grab/index.php <WEB_PATH>/grab/index.php
//
//  Vérifier les autorisations des fichiers DLlists et du dossier /conf/tograb (chown/chmod)
//
//  Ajouter l'adresse de ce php en tant que moteur de recherche avec un mot-clé court (ex: grab)  
//
*/

$listpath = '/home/toto/scripts/seedbox/conf/tograb/';

 
# si on a renseigné un nom de fichier dans lequel ajouter l'url
if($_GET['file']){

	$file=$listpath.$_GET['file'].".conf";
	# on vérifie si le fichier existe
	if (!file_exists($file)) {
	    echo "Erreur: Le fichier ".$file." n'existe pas.";
	    exit;
	}
# si on a pas renseigné de nom de fichier, on ajoute l'url dans le fichier par défaut
} else {
	$file=$listpath."todl.conf";
}

# on lit le contenu du fichier demandé
$urllist = file_get_contents($file);

# si on a bien renseigné une URL en paramètre
if($_GET['url']){

	# on vérifie si l'url n'est pas déja contenue dans le fichier
	if (strpos($urllist, $_GET['url']) !== false) {
	    echo "Déjà dans ".$_GET['file']." : ".$_GET['url'];

	# sinon on ajoute l'url
	} else {
		$newurllist = $_GET['url']."\n".$urllist;
		file_put_contents($file, $newurllist);
		$urllist="$newurllist";
		echo "Ajout à ".$_GET['file']." de : ".$_GET['url'];
	}	

# si aucune URL n'est renseignée en paramètre
} else {
	echo "Rentrer une URL en paramètre sous la forme :<br/>index.php?url=http://lien_playlist # commentaire optionnel<br/>ou<br/>index.php?url=http://lien_playlist&file=rss";
}

# dans tous les cas, on affiche le contenu du fichier
echo "<br/><br/><b>Liste d'attente dans <i>".$_GET['file'].".conf</i></b>:</br>";
$urllist=str_replace("#"," <b> #",$urllist);
$urllist=str_replace("\n","</b></li><br/><li>",$urllist);
echo "<ul><li>".$urllist."</li></ul>";


 ?> 