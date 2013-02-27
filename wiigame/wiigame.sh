#!/bin/bash -x

#Mainteneur : Yannou90
#
#Profil ubuntu.fr : http://forum.ubuntu-fr.org/profile.php?id=73803
#
#Logiciel :
#
#Dépendances : wit http://wit.wiimm.de/
#
#Date :
#
#Description :
#
#Ce programme est libre, vous pouvez le redistribuer et/ou le modifier selon les termes
#de la Licence Publique Générale GNU publiée par la Free Software Foundation
#(version 2 ou bien toute autre version ultérieure choisie par vous).
#
#Ce programme est distribué car potentiellement utile, mais SANS AUCUNE GARANTIE,
#ni explicite ni implicite, y compris les garanties de commercialisation ou d'adaptation
# dans un but spécifique. Reportez-vous à la Licence Publique Générale GNU pour plus
#de détails.
#
#Vous devez avoir reçu une copie de la Licence Publique Générale GNU en même temps
#que ce programme ; si ce n'est pas le cas, écrivez à la Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, États-Unis.

## DECLARATION DES VARIABLES	##

VERSION="0.5.4"
ETAT=0
DNG="False"
WIICONF="$HOME/.wiigame"
DIRWGF="$WIICONF/wgf"
COVERDIR="$WIICONF/cover"
COVER3DDIR="$WIICONF/cover3D"
COVERFULLDIR="$WIICONF/coverfull"
COVERDISCDIR="$WIICONF/disc"
ARTWORK="http://www.wiiboxart.com/artwork"
ICON_URL="http://dev.yannou90.free.fr/data/telechargement/wiigame"
LIST_URL="$WIICONF/url.txt"
COVER="cover"
DOWNLOAD="Toujours"
CONNEXION="8"
FORMAT="wbfs"
PROFONDEUR="1"
CONF="$WIICONF/wiigame.ini"
GUICON="$WIICONF/cover.png"
MTAB="$WIICONF/wfuse.mtab"
IFS='
'

mkdir -p "$WIICONF/"{cover,cover3D,coverfull,disc,wgf}

for i in cover cover3D coverfull disc
do
	if [[  ! -e "$WIICONF/$i.png" ]]
	then
		echo -e "$ICON_URL/$i.png" >> "$LIST_URL"
	fi
done

if [[ -e "$LIST_URL" ]]
then
	aria2c -j 8 -x 8 -s 8 -d "$WIICONF" -i "$LIST_URL"
	rm "$LIST_URL"
fi



##	FONCTIONS	##

function OPTIONS()
{
	eval $(\
	yad \
	--title "Préférences" \
	--text "<b>Préférences</b> de WiiGame $VERSION" \
	--window-icon "gtk-preferences" \
	--image "gtk-preferences" \
	--image-on-top \
	--button="gtk-about:10" \
	--button="gtk-cancel:1" \
	--button="gtk-ok:0" \
	--form \
	--field "Répertoire des jeux:DIR" \
	--field "Jaquettes:DIR" \
	--field "Jaquettes 3D:DIR" \
	--field "Jaquettes completes:DIR" \
	--field "Jaquettes de disque:DIR" \
	--field "Url" \
	--field "Jaquette par defaut:CB"	\
	--field "Téléchargement des jaquettes:CB" \
	--field "Connexions par serveur:NUM" \
	--field "Format des jeux par defaut:CB" \
	--field "Recherche reccursive:NUM" \
	"$WIIGAME" \
	"$COVERDIR" \
	"$COVER3DDIR" \
	"$COVERFULLDIR" \
	"$COVERDISCDIR" \
	"$ARTWORK" \
	"$COVER!cover!cover3D!coverfull!disc" \
	"$DOWNLOAD!Toujours!Importation!Jamais" \
	"$CONNEXION!1..16!1" \
	"$FORMAT!wbfs!iso!ciso!wdf!wia" \
	"$PROFONDEUR!1..10!1" \
	| awk -F'|' '{printf "WIIGAME=\"%s\"\nCOVERDIR=\"%s\"\nCOVER3DDIR=\"%s\"\nCOVERFULLDIR=\"%s\"\nCOVERDISCDIR=\"%s\"\nARTWORK=\"%s\"\nCOVER=\"%s\"\nDOWNLOAD=\"%s\"\nCONNEXION=\"%s\"\nFORMAT=\"%s\"\nPROFONDEUR=\"%s\"\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11}'
echo "ETAT=${PIPESTATUS[0]}")

PROFONDEUR="$(echo $PROFONDEUR | cut -d',' -f1)"
CONNEXION="$(echo $CONNEXION | cut -d',' -f1)"

if [[ "$ETAT" = "0" ]]
then
	case "$COVER"
	in
		cover)
			DIRCOVER="$COVERDIR";;
		cover3D)
			DIRCOVER="$COVER3DDIR";;
		coverfull)
			DIRCOVER="$COVERFULLDIR";;
		disc)
			DIRCOVER="$COVERDISCDIR";;
	esac
	echo -e "\
	WIIGAME=\"$WIIGAME\"
	COVERDIR=\"$COVERDIR\"
	COVER3DDIR=\"$COVER3DDIR\"
	COVERFULLDIR=\"$COVERFULLDIR\"
	COVERDISCDIR=\"$COVERDISCDIR\"
	ARTWORK=\"$ARTWORK\"
	COVER=\"$COVER\"
	DOWNLOAD=\"$DOWNLOAD\"
	CONNEXION=\"$CONNEXION\"
	FORMAT=\"$FORMAT\"
	DIRCOVER=\"$DIRCOVER\"
	PROFONDEUR=\"$PROFONDEUR\"" > "$CONF"
fi
return "$ETAT"
}

function GUI()
{
for i in $LISTGAME
do
	FILEWGF="$(basename $i)"
	WGF="$DIRWGF/$FILEWGF.wgf"
	
	source "$WGF"
	
	if [[ ! -e "$DIRCOVER/$ID6.png" ]] 
	then
		COVERGAME="$WIICONF/$COVER.png"
	else
		COVERGAME="$DIRCOVER/$ID6.png"
	fi
	echo -e "FALSE\n$COVERGAME\n$ID6\n$POID\n$REGION\n$TITRE\n$i"
done | yad \
--title "WiiGame $VERSION" \
--text "\
<b>Systeme de fichier :</b>
	$(df -h "$WIIGAME" )
<b>Nombre de jeux :</b>	$NBR" \
--window-icon "$GUICON" \
--width 800 \
--height 600 \
--always-print-result \
--buttons-layout center \
--button="gtk-preferences:11" \
--button="gtk-add:12" \
--button="gtk-save-as:13" \
--button="gtk-delete:14" \
--button="gtk-edit:15" \
--button="gtk-quit:16" \
--search-column=6 \
--regex-search \
--list \
--checklist \
--print-column=7 \
--column "Selection:CHK" \
--column "Image:IMG" \
--column "ID6:TXT" \
--column "Poid:NUM" \
--column "Region:TXT" \
--column "Titre:TXT" \
--column "Chemin:HD" \
| tr -d '|'

return "${PIPESTATUS[1]}"
}

function ABOUT()
{
yad  \
--title="WiiGame $VERSION"  \
--text="
<b> A Propos...</b>

WiiGame $VERSION une interface graphique pour wit :

	-convertion de->vers wbfs , iso , ciso , wdf , wia
	-copy , convert , scrub , edit
	-modification de l'id6
	-modification du titre
	-systeme de mise en cache pour un chargement rapide de la gui
	-téléchargement des jaquettes
	-choix du type de jaquette cover , cover3D , coverfull , disc
	-choix de l'url des coverflows
	-glisser/déposer pour la convertion du format
	
<a href='http://wit.wiimm.de/'><b>wit</b></a> est utilisé pour la manipulation des jeux
<a href='http://aria2.sourceforge.net/'><b>aria2c</b></a> est un puissant gestionnaire de téléchargement
<a href='http://code.google.com/p/yad/'><b>yad</b></a> quand à lui permet la création de la GUI

<b>Developpeur : </b> Yannou90
<b>Dépendances : </b> <a href='http://code.google.com/p/yad/'>yad</a> <a href='http://aria2.sourceforge.net/'>aria2c</a> <a href='http://wit.wiimm.de/'>wit</a>
" \
--window-icon="$WIICONF/cover3D.png"  \
--image="$WIICONF/cover3D.png" \
--image-on-top \
--button="gtk-ok:0"

ETAT="11"
}

function LIST()
{
	LISTGAME="$(wit  FLIST -r "$@" --rdepth "$PROFONDEUR")"
	CODE="$?"
	WITERROR "$CODE"
	NBR="$(echo "$LISTGAME" |  sed -e '/^$/d' |wc -l)"
	
	source "$CONF"
	
	for i in $LISTGAME
	do
		FILEWGF="$(basename $i)"
		WGF="$DIRWGF/$FILEWGF.wgf"
		
		if [[ ! -e "$WGF" ]]
		then
			eval $(wit -T0 LL "$i" | grep -v "^ID6\|^Total\|^-\|^$" | awk '{printf "ID6=\"%s\"\nPOID=\"%s\"\nREGION=\"%s\"\nTITRE=\"%s\"\n", $1, $2, $3,substr($0,index($0,$4))}' )
			echo -e "\
			ID6=\"$ID6\"
			POID=\"$POID\"
			REGION=\"$REGION\"
			TITRE=\"$TITRE\"" > "$WGF"
		fi
		
		source "$WGF"
		
		if [[ ! -e "$DIRCOVER/$ID6.png" ]]
		then
			echo "$ARTWORK/$COVER/$ID6.png" >> "$LIST_URL"
		fi
		
	done
	
	if [[ ! -e "$WIICONF/$COVER.png" ]]
	then
		echo -e "$ICON_URL/$COVER.png\n\tdir=$WIICONF"  >> "$LIST_URL"
	fi

}

function ARIA2C()
{
	if [[ -e "$LIST_URL" ]]
	then
		aria2c -j "$CONNEXION" -x "$CONNEXION" -s "$CONNEXION" -d "$DIRCOVER" -i "$LIST_URL" \
		| sed -u "s|^|#|g; s|$DIRCOVER/||g" \
		| yad  \
		--title "WiiGame $VERSION" \
		--text "<b>Téléchargement</b> des jaquettes manquantes ..." \
		--window-icon "gtk-network" \
		--image "gtk-network" \
		--image-on-top \
		--progress \
		--pulsate \
		--auto-close \
		--progress-text "Veuillez patienter ..." 
		rm "$LIST_URL"
	fi
}

function TRANS()
{
	eval $(\
	yad \
	--title "$TRANSTITRE" \
	--text "$TRANSMESSAGE" \
	--window-icon="$TRANSICON"  \
	--image="$TRANSICON" \
	--image-on-top \
	--form \
	--field "Repertoire:DIR" \
	--field "Format:CB" \
	"$HOME" \
	"$FORMAT!wbfs!iso!ciso!wdf!wia" \
	| awk -F'|' '{printf "TRANSDIR=\"%s\"\nFORMAT=\"%s\"\n", $1, $2}'
	echo "ETAT=${PIPESTATUS[0]}")

return "$ETAT"
}

function COPY()
{
	wit -T0 -u COPY  --"$FORMAT" --source $GAME  -D "$1/%+" \
	| sed -u "s|^|#|g; s|${TRANSDIR}/||g; s|${WIIGAME}/||g" \
	| yad  \
	--title "$TRANSTITRE" \
	--text "$TRANSMESSAGE" \
	--window-icon "$TRANSICON"  \
	--image "$TRANSICON" \
	--image-on-top \
	--progress \
	--pulsate \
	--auto-close \
	--progress-text "Veuillez patienter ..." 
	
	CODE="${PIPESTATUS[0]}"
	WITERROR "$CODE"
}

function IMPORT()
{
for i in $LISTGAME
do
	FILEWGF="$(basename $i)"
	WGF="$DIRWGF/$FILEWGF.wgf"
	source "$WGF"
	if [[ ! -e "$DIRCOVER/$ID6.png" ]] 
	then
		COVERGAME="$WIICONF/$COVER.png"
	else
		COVERGAME="$DIRCOVER/$ID6.png"
	fi
	echo -e "$1\n$COVERGAME\n$ID6\n$POID\n$REGION\n$TITRE\n$i"
done | yad \
--title "$TRANSTITRE" \
--text "$TRANSMESSAGE" \
--window-icon "$TRANSICON" \
--image "$TRANSICON" \
--image-on-top \
--width 800 \
--height 600 \
--always-print-result \
--search-column=6 \
--regex-search \
--list \
--checklist \
--print-column=7 \
--column "Selection:CHK" \
--column "Image:IMG" \
--column "ID6:TXT" \
--column "Poid:NUM" \
--column "Region:TXT" \
--column "Titre:TXT" \
--column "Chemin:HD" \
| tr -d '|'

return "${PIPESTATUS[1]}"
}

function EDITGAME()
{
	DIRFILE="$(dirname "$1")"
	FILEWGF="$(basename "$1")"
	WGF="$DIRWGF/$FILEWGF.wgf" 
	
	source "$WGF"
	
	if [[ ! -e "$DIRCOVER/$ID6.png" ]] 
	then
		COVERGAME="$WIICONF/$COVER.png"
	else
		COVERGAME="$DIRCOVER/$ID6.png"
	fi
	
	eval $(\
	yad \
	--title "Editer" \
	--width 800 \
	--window-icon "gtk-edit" \
	--image "$COVERGAME" \
	--button="gtk-edit:0" \
	--button="gtk-cancel:1" \
	--form \
	--field "Titre" \
	--field "ID6" \
	--field "Dump:TXT" \
	"$TITRE" \
	"$ID6" \
	"$(wit -T0 DUMP "$1")" \
| awk -F'|' '{ printf "TITRE=\"%s\"\nID6=\"%s\"\n", $1, $2 }'

echo ETAT="${PIPESTATUS[0]}")

if [[ "$ETAT" = "0" ]]
then
	wit CONVERT --id="$ID6" --name="$TITRE" "$1" \
	| sed -u "s|^|#|g; s|$DIRFILE/||g" \
	| yad  \
	--title "Edition" \
	--text "<b>Modification</b> du jeux en cours , veuillez patienter ..." \
	--window-icon="gtk-edit"  \
	--image="gtk-edit" \
	--image-on-top \
	--progress \
	--pulsate \
	--auto-close \
	--progress-text "Veuillez patienter ..." 
	
	CODE="${PIPESTATUS[0]}"
	WITERROR "$CODE"
	 
	rm "$WGF"
	
fi

return "$ETAT"
}

function WITERROR()
{
	ERROR="$1"
	
	if [[ "$ERROR" = "0" ]]
	then
		return 0
	fi
	MESSAGE="$(wit ERROR | grep -w "$ERROR" | cut -d':' -f3)"
	yad --window-icon "gtk-dialog-error" --image "gtk-dialog-error" --button "gtk-ok:0" --title "Erreur" --text "$MESSAGE"
}

if [[ -e "$CONF" ]]
then
	source "$CONF"
else
	OPTIONS
fi

if  [[ ! -d "$WIIGAME" ]]
then 
	rm "$CONF"
fi

if [[ ! "$@" = "" ]]
then
	ETAT="13"
	GAME="$@"
	DNG="True"
fi

while true
do
	case $ETAT
	in
		0|1)
			LIST "$WIIGAME"
			if [[ "$DOWNLOAD" = "Toujours" ]]
			then
				ARIA2C
			fi
			if [[ -e "$LIST_URL" ]]
			then
				rm "$LIST_URL"
			fi
			GAME="$(GUI)"
			ETAT="$?";;		
		10)
			ABOUT;;
		11)
			OPTIONS;;
		12)
			TRANSICON="gtk-add"
			TRANSTITRE="Importer"
			TRANSMESSAGE="<b>Importer</b> la sélection"
			TRANS  
			if [[ "$?" = "0" ]]
			then
				LIST "$TRANSDIR"
				if [[ ! "$DOWNLOAD" = "Jamais" ]]
				then
					ARIA2C
				fi
				if [[ -e "$LIST_URL" ]]
				then
					rm "$LIST_URL"
				fi
				GAME="$(IMPORT "FALSE")"
				if [[ "$?" = "0" ]] && [[ -n "$GAME" ]]
				then
					COPY "$WIIGAME"
				fi
			fi;;
		13)
			if [[ "no$GAME" = "no" ]]
			then
				yad --window-icon "gtk-dialog-error" --image "gtk-dialog-error" --button "gtk-ok:0" --title "Erreur" --text "Aucun fichier sélectionné"
				ETAT="0"
			else
				TRANSICON="gtk-save-as"
				TRANSTITRE="Exporter"
				TRANSMESSAGE="<b>Exporter</b> la sélection"
				TRANS 
				if [[ "$?" = "0" ]]
				then
					COPY "$TRANSDIR"
				fi
			fi
			if [[ "$DNG" = "True" ]]
			then
				exit 0
			fi;;
		14)
			if [[ "no$GAME" = "no" ]]
			then
				yad --window-icon "gtk-dialog-error" --image "gtk-dialog-error" --button "gtk-ok:0" --title "Erreur" --text "Aucun fichier sélectionné"
			else
				TRANSICON="gtk-delete"
				TRANSTITRE="Supprimer"
				TRANSMESSAGE="La suppression est définitve!"
				LISTGAME="$GAME"
				GAME="$(IMPORT "TRUE")"
				if [[ "$?" = "0" ]]
				then
					wit RM $GAME
					WITERROR "$?"
				fi
			fi
			ETAT="0";;
		15)
			if [[ "no$GAME" = "no" ]]
			then
				yad --window-icon "gtk-dialog-error" --image "gtk-dialog-error" --button "gtk-ok:0" --title "Erreur" --text "Aucun fichier sélectionné"
				ETAT="0"
			else
				LISTGAME="$GAME"
				NBR="$(echo "$GAME" | wc -l)"
				if [[ "$NBR" = "1" ]]
				then
					EDITGAME "$GAME"
				else
					yad --window-icon "gtk-dialog-error" --image "gtk-dialog-error" --button "gtk-ok:0" --title "Erreur" --text "Vous ne pouvez éditer qu'un fichier à la fois"
					ETAT="0"
				fi
			fi;;
		16)
			exit 0;;
		252)
			exit 252;;
	esac
done
