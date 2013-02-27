#!/bin/bash -x

#Mainteneur : Yannou90
#
#Logiciel : DownTube bêta 3
#
#Dépendances : youtube-dl , yad , ffmpeg , lame , libmp3lame0 , xubuntu-restricted-extras , aria2
#
#Date : 15.07.2012
#
#Description : "DownTube" est une interface graphique à "youtube-dl" couplé à "aria2" un accélérateur de téléchargement . Il permet de télécharger une vidéo depuis Youtube , une chaine ou une playlist . Il permet également d'extraire l'audio de ces vidéos .
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

#Enregistrement des logs

echo -e "$(date)\n" 1>&2

#Variables

ICONP="$HOME/.icons"
ICON="$ICONP/downtube.png"
DOWNTUBEDIR="$HOME/.downtube"
EXTRACTDIR="$DOWNTUBEDIR/TMP"
DOWNTUBEPREF="$DOWNTUBEDIR/downtube.pref"
AUTH=""
COOKIES="$EXTRACTDIR/cookies.sqlite"
CMD="youtube-dl --cookies=\"$COOKIES\" --get-filename -l  -g"
LISTE="$EXTRACTDIR/list.down"
ENCODE="$EXTRACTDIR/encode.sh"
COMPLETE=""
USER=""
MDP=""
DIR=""
QV="Normal"
QA="Original"
AUDIO="FALSE"
URL=""
SEG="8"
POID="5"
TRY="0"
SORTIE=""

#Fonctions

function ERROR()
{
echo -e "
MESSAGE=\"$@\"
SORTIE=\"$SORTIE\"
DIR=\"$DIR\"
QV=\"$QV\"
QA=\"$QA\"
AUDIO=\"$AUDIO\"
URL=\"$URL\"
SEG=\"$SEG\"
POID=\"$POID\"
TRY=\"$TRY\"
TITRE=\"$TITRE\"
LINK=\"$LINK\"
" 1>&2
rm -rf "$EXTRACTDIR"
exit 1
}

function OPTIONS()
{
eval $(\
yad  \
--title="DownTube - Options" \
--window-icon="$ICON" \
--form  \
--text="
<b>Utilisateur</b> Exemple : downtube@gmail.com <b>*</b>
<b>Mot de passe</b> Le mot de passe gmail <b>*</b>
<b>Segmentation des fichiers</b> Le nombre de segments par fichier
<b>Poids des segments en Mio</b> Le poid minimum par segments
<b>Essais avant abandon</b> Le nombre d'essais maximum (0=max) avant d'abandonner un téléchargement

<b>*</b> Ces options sont facultatives : authentification pour le contenu adulte et privé
" \
--button="gtk-cancel:4" \
--button="gtk-ok:0" \
--field="Utilisateur" \
--field="Mot de passe:H" \
--field="Segmentation des fichiers:NUM" \
--field="Poids des segments en Mio:NUM" \
--field="Essais avant abandon:NUM" \
"$USER" \
"$MDP" \
"$SEG!1..16!1" \
"$POID!1..40!1" \
"$TRY!0..20!1" \
| awk -F'|' '{printf "USER=\"%s\"\nMDP=\"%s\"\nSEG=\"%s\"\nPOID=\"%s\"\nTRY=\"%s\"\n", $1, $2, $3, $4, $5}'
echo "ETAT=${PIPESTATUS[0]}")

if [[ ! "$ETAT" = "0" ]]
then
	if [[ -e "$DOWNTUBEPREF" ]]
	then
		source "$DOWNTUBEPREF"
	else
	USER=""
	MDP=""
	SEG="8"
	POID="5"
	TRY="0"
	fi
fi

}

function ABOUT()
{
yad  \
--title="DownTube"  \
--text="
<b>DownTube une interface graphique pour <a href='http://rg3.github.com/youtube-dl/'>Youtube-dl</a> couplé à <a href='http://aria2.sourceforge.net/'>Aria2</a> un accélérateur de téléchargement !
L'indispensable <a href='http://ffmpeg.org/'>FFmpeg</a> est utilisé pour l'encodage audio</b>

\tDownTube supporte l'authentification aux services google,utile pour le contenu adulte et privé.
Vous pouvez télécharger une chaine complete ou plusieurs vidéos en même temps,il suffit d'ajouter 
les liens les uns  après les autres.
\tAvec aria2 vous pouvez réduire considérablement la durée de téléchargement en sélectionnant
la taille et le nombre de segments de fichiers téléchargé en parallèle.
\tFFmpeg permet un encodage audio de grande qualitée en tirant le meilleur de votre machine.

<b>Developpeur</b> Yannou90
<b>Bêta testeur</b> Nico
<b>Dépendances</b> yad youtube-dl aria2c ffmpeg
" \
--window-icon="$ICON"  \
--image="$ICON" \
--image-on-top \
--button="gtk-ok:0"
}

#Vérification et installation des dépendances

if [[ ! -d "$DOWNTUBEDIR" ]]
then
	mkdir -p "$DOWNTUBEDIR"
	for i in youtube-dl yad ffmpeg lame libmp3lame0 xubuntu-restricted-extras aria2
	do
		dpkg --get-selections | grep -w install | grep -v "deinstall" | grep -w "^$i" || DEP="$i $DEP"
	done
	
	if [[ -n "$DEP" ]]
	then
		zenity --info --title DownTube --text "Les paquets suivant vont êtres installés :\n$DEP"
		xterm -e "sudo apt-get install -y $DEP"
	fi
	if [[ ! -e "$ICON" ]]
	then
		mkdir -p "$ICONP"
		aria2c --dir="$ICONP" "http://dev.yannou90.free.fr/data/telechargement/downtube.png"
	fi
fi

#Dossier de travail

if [[ ! -d "$EXTRACTDIR" ]]
then
	mkdir -p "$EXTRACTDIR" || ERROR "Le dossier de destination n\'existe pas ou ne peut-être créé !"
fi

#Si présent chargement des préférences

if [[ -e "$DOWNTUBEPREF" ]]
then
	source "$DOWNTUBEPREF"
fi

#Downtube

while [[ ! "$SORTIE" = "0" ]]
do
eval $(\
yad  \
--width=800 \
--height=600 \
--title="DownTube" \
--window-icon="$ICON"  \
--button="gtk-preferences:2" \
--button="gtk-about:3" \
--button="gtk-cancel:1" \
--button="gtk-ok:0" \
--form  \
--field="Destination:DIR" \
--field="Qualitée vidéo:CB" \
--field="Qualitée audio:CB" \
--field="Extraire l'audio : attention à la qualitée de la vidéo qui détermine le temps de téléchargement !:CHK" \
--field="Url(s):TXT" \
"$DIR" \
"$QV!Haute!Normal!Basse!H264-MP4-3072p!H264-MP4-1080p!H264-MP4-720p!H264-MP4-360p!H264-FLV-480p!H264-FLV-360p!H263-FLV-270p!H263-FLV-240p!WebM-1080p!WebM-720p!WebM-480p!WebM-360p!3GP-240p!3GP-144p" \
"$QA!Ogg!Mp3!Ac3!Wav!Wma" \
"$AUDIO" \
"" \
| awk -F'|' '{printf "DIR=\"%s\"\nQV=\"%s\"\nQA=\"%s\"\nAUDIO=\"%s\"\nURL=\"%s\"\n", $1, $2, $3, $4, $5}'
echo "SORTIE=${PIPESTATUS[0]}")

case "$SORTIE" in
	2)
		OPTIONS;;
	3)
		ABOUT;;
	1|252)
		ERROR "L'utilisateur à quitté DownTube !";;
esac

done

#Enregistrement des préférences

echo -e "
USER=\"$USER\"
MDP=\"$MDP\"
DIR=\"$DIR\"
QV=\"$QV\"
QA=\"$QA\"
AUDIO=\"$AUDIO\"
SEG=\"$SEG\"
POID=\"$POID\"
TRY=\"$TRY\"
" > "$DOWNTUBEPREF"

#Test et formatage URL : si echoué on quitte

if [[ ! -n "$URL" ]]
then
	ERROR "Pas d'URL ."
fi

URL="$(echo "$URL" | sed -e 's/\\n/ /g;s/http/ http/g')"

#Test utilisateur et mot de passe : si présent on l'utilise pour la connexion

if [[ -n "$USER" ]] && [[ -n "$MDP" ]]
then
	AUTH="-u $USER -p $MDP"
fi

#Qualitée vidéo

case $QV in
	Haute)
		FORMAT="";;
	Basse)
		FORMAT="--format=worst";;
	H264-MP4-3072p)
		FORMAT="--max-quality=38";;
	H264-MP4-1080p)
		FORMAT="--max-quality=37";;
	H264-MP4-720p)
		FORMAT="--max-quality=22";;
	Normal|H264-MP4-360p)
		FORMAT="--max-quality=18";;
	H264-FLV-480p)
		FORMAT="--max-quality=35";;
	H264-FLV-360p)
		FORMAT="--max-quality=34";;
	H263-FLV-270p)
		FORMAT="--max-quality=6";;
	H263-FLV-240p)
		FORMAT="--max-quality=5";;
	WebM-1080p)
		FORMAT="--max-quality=46";;
	WebM-720p)
		FORMAT="--max-quality=45";;
	WebM-480p)
		FORMAT="--max-quality=44";;	
	WebM-360p)
		FORMAT="--max-quality=43";;	
	H263-240p)
		FORMAT="--max-quality=5";;
	3GP-240p)
		FORMAT="--max-quality=36";;
	3GP-144p)
		FORMAT="--max-quality=17";;
esac

#Qualitée audio

if [[ "$AUDIO" = "TRUE" ]]
then
	case $QA in
		Ogg)
echo -e '#!/bin/bash
ffmpeg -i "$3" -acodec libvorbis -aq 3 -vn -ac 2 "$3".ogg
rm "$3"
exit $?
' > "$ENCODE";;
		Mp3)
echo -e '#!/bin/bash
ffmpeg -i "$3" -acodec libmp3lame -ab 160k -ac 2 -ar 44100 "$3".mp3
rm "$3"
exit $?
' > "$ENCODE";;
		Ac3)
echo -e '#!/bin/bash
ffmpeg -i "$3" -f ac3 -acodec ac3 -ab 192k -ar 48000 -ac 2 "$3".ac3
rm "$3"
exit $?
' > "$ENCODE";;
		Wav)
echo -e '#!/bin/bash
ffmpeg -i "$3" -vn -ar 44100 "$3".wav
rm "$3"
exit $?
' > "$ENCODE";;
		Wma)
echo -e '#!/bin/bash
ffmpeg -i "$3" -vn -acodec wmav2 -ab 160k "$3".wma
rm "$3"
exit $?
' > "$ENCODE";;
	esac
	chmod +x "$ENCODE"
	COMPLETE="--on-download-complete=\"$ENCODE\""
fi

#Téléchargement

(echo; eval $CMD $AUTH $FORMAT "$URL" 2>/dev/null | sed -r -e "s/ /_/g; s/^/out=/g; s/out=http/http/g; s|out=|\tdir=$DIR\n\tout=|g; /^$/d" > "$LISTE") | zenity --progress --pulsate  --auto-close --title DownTube --text "Construction de la liste de téléchargement\nveuillez patienter ..."

SEG="$(echo $SEG | cut -d',' -f1)"
POID="$(echo $POID | cut -d',' -f1)"
TRY="$(echo $TRY | cut -d',' -f1)"

xterm -T Téléchargement -e "aria2c $COMPLETE --file-allocation=falloc --load-cookies=\"$COOKIES\" -i\"$LISTE\" -s\"$SEG\"  -x\"$SEG\" -j\"$SEG\" -k\"$POID\"M -m\"$TRY\"; espeak -v fr -s 150 -p 75 \"Les téléchargements sont terminés . Appuyez sur une touche  pour quitter .  Merci , et à bientôt .\" &>/dev/null; echo \"Appuyez sur une touche pour quitter\"; read"

#On nettoie

rm -rf "$EXTRACTDIR"

#On quitte

exit 0
