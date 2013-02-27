#!/bin/bash

#Mainteneur : Yannou90
#
#Logiciel : permute.sh
#
#Version : 0.4.3
#
#Dépendances : 7z , bc
#
#Date : 06.02.2013
#
#Description : créer des passphrases de longueurs définis par l'utilisateur en fonction d'un dictionnaire
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

######################
## On cree les variables de bases ##
######################

OPT_PASS=$1
SEQ="3"
LONGMIN="1"
LONGMAX="4"
NUM="1"
TEMPS="$(date +%s)"
NEW="${TEMPS}_PASSE_1.txt"
TMP="${TEMPS}_tmp.txt"
DICO="${TEMPS}_DICO.txt"
NBR="1"
FACT="1"
CONV=""
VITESSE="0"
FULL="1"
WDIR=""
REPONSE="n"
COMPRESSE="1"
PHRASES="n"
NBRM="1000000"
SEP=" "
VERIF="n"
EXIT="n"
ANS="31556952"
MOIS="2629746"
JOURS="86400"

#############
## Le menu d'aide ##
#############

function HELP()
{
	echo -e "\
	
	${0##*/} permet la génération de phrases à partir d'un dictionnaire , par permutations des mots .
	
	Ce projet à pour but de démontrer l'inutilité du force-brute .
	
	Utilisation :
	
	${0##*/} -[!:L:w:i:p:d:r:P:s:] <ARGUMENT> -v -h -y -C
	
	${0##*/}  -l <LONG_MIN> -L <LONG_MAX> -w <NBR_MOTS> -i <DICO> -d <DIR> -C -P <NBR_PHRASES> -s <SEPARATEUR>
	${0##*/} -v -L <LONG_MAX> -w <NBR_MOTS> -i <DICO>
	${0##*/} -i <DICO>  -P 10000
	${0##*/} -r <ARCHIVE>
	${0##*/} -h
		
	-l <LONG_MIN>
		Longueur minimal du mot du dictionnaire (LONG_MIN=1 par défaut) .
	-L <LONG_MAX>
		Longueur maximal du mot du dictionnaire (LONG_MAX=4 par défaut) .
	-w <NBR_MOTS>
		Nombre de mots composant la phrase (NBR_MOTS=3 par défaut) .
	-i <DICO>
		Chemin vers le dictionnaire 
	-v
		Mode verbeux , plus lent , toutes les combinaisons de 2 à <NBR_MOTS> sont affichées , le mode compression n'est pas compatible .
	-d <DIR>
		Dossier de sortie , par défaut celui contenant le dictionnaire .
	-r <ARCHIVE>
		Permet de lire sur la sortie standard le contenu d'une archive au format 7z créé avec ${0##*/}
	-y
		Pas de confirmation , pas d'interraction avec l'utilisateur .
	-C
		Mode compression : les données sont directement compressée , le mode verbeux n'est pas compatible .
	-P <NBR_PHRASES>
		Limiter la création de  phrases à <NBR_PHRASES> ( par défaut limité à 1000000 )
	-s <SEPARATEUR>
		Utilise <SEPARATEUR> comme séparateur entre chaque mot (SEPARATEUR=" " par défaut) .
	-h
		Affiche ce message		
		
	Exemple d'utilisation :
	
	# Créer 1000000 de phrases de 5 mots basé sur les mots de 2 à 8 caractères de dico.txt , utiliser ':'  comme séparateur , le fichier est compressé au format 7z :
	
	$0 -l 2 -L 8 -w 5 -i dico.txt -C -P 1000000 -s ":"
	
	# Créer des phrases de 3 mots basé sur les mots inférieur à 4 caractères de dico.txt , aucunes confirmation n'est nécessaire :
	
	$0  -L 4 -w 3 -i dico.txt -y
	
	# Créer des phrases de 3 mots dans  123456789.txt basé sur les mots de 1 à 4 caractères de dico.txt , limité à 1000000 phrases , toutes les combinaisons sont affichées sur la sortie standars :
	
	$0  -i dico.txt -v
	
	# Lire une archive créée avec ${0##*/} :
	
	$0  -r 1234567890.7z"
}

##################
## Pas de sortie standard ##
##################

function PERMQUICK()
{
	TMP="${TEMPS}_PASSE_${PASSE}.txt"
	while read WORD
	do
		if [[ "$NULL" = "sep" ]]
		then
			sed -u -e "/^$/d; /$WORD/d; $MXq; s/^/$WORD /g; s/ /$SEP/g" "$NEW"
		else
			sed -u -e "/^$/d; /$WORD/d;  $MXq; s/^/$WORD /g " "$NEW"
		fi
		PERAC="$(bc<<<"$PERAC+1")"
		ACT="$(bc -l<<<"(($PERAC/$PERC)*100)+(($NUM/$SEQ)*100)" | cut -d'.' -f1)"
		printf "\rProgression : $ACT/100" 1>&2
	done < "$DICO" | head -n "$MAX" > "$TMP"
}

##############
## Sortie standard ##
##############

function PERMTEE()
{
	TMP="${TEMPS}_PASSE_${PASSE}.txt"
	
	while read WORD
	do
		if [[ "$NULL" = "sep" ]]
		 then
			sed -u -e "/^$/d; /$WORD/d; $MXq; s/^/$WORD /g; s/ /$SEP/g" "$NEW"
		else
			sed -u -e "/^$/d; /$WORD/d; $MXq; s/^/$WORD /g " "$NEW"
		fi
	done < "$DICO" | head -n "$MAX" | tee -a "$TMP" | sed -e "s/ /$SEP/g"
}

############
## Compression ##
############

function PERMX()
{	
	TMP="${TEMPS}_PASSE_${PASSE}.7z"
	while read WORD
	do
		7z e  "$NEW" -so 2>/dev/null | sed -u -e "/^$/d; $MXq; /$WORD/d; s/^/$WORD /g "
		PERAC="$(bc<<<"$PERAC+1")"
		ACT="$(bc -l<<<"(($PERAC/$PERC)*100)+(($NUM/$SEQ)*100)" | cut -d'.' -f1)"
		printf "\rProgression : $ACT/100" 1>&2
	done < "$DICO" | head -n "$MAX" | 7z a "$TMP" -si &>/dev/null
}

############
## Permutation ##
############

function PERMUTE()
{
	if [[ "$1" = "2" ]]
	then
		ARCH="${TEMPS}_PASSE_1.7z"
		7z a "$ARCH" "$NEW"  &>/dev/null
		rm "$NEW"
		NEW="$ARCH"
		(( SEQ-- ))
	fi
	PERC="$(bc<<<"$LIGNE*$SEQ")"
	PERAC="0"
	while [[ ! "$NUM" = "$SEQ" ]]
	do
		PASSE="$(( NUM + 1 ))"
		if [[ "$PASSE" = "$SEQ" ]]
		then
			if [[ "$NULL" = "0" ]]
			then
				NULL="sep"
			fi
			if [[ ! "$COMPRESSE" = "0" ]]
			then
			MAX="$NBRM"
			fi
		fi
		case "$1" in
			0)
				PERMQUICK;;
			1)
				PERMTEE;;
			2)
				PERMX;;
		esac
		mv -f  "$TMP"  "$NEW"
		(( NUM++ ))
	done
	printf "\rProgression : 100/100\n" 1>&2
	if [[ "$1" = "2" ]]
	then
		7z a  "$NEW" "$DICO" &>/dev/null
		echo "SEP=\"$SEP\"" > "${TEMPS}_DICO.sep"
		7z a  "$NEW"  "${TEMPS}_DICO.sep" &>/dev/null
		rm "${TEMPS}_DICO.sep" "$DICO"
		DICO="${TEMPS}_DICO.7z"
	fi
	mv -f "$NEW" "$DICO"
}

###########
## Nettoyage ##
###########

function CLEAN()
{
	rm "$DICO"
	if [[ -d "$WDIR" ]]
	then
		rmdir "$WDIR"
	fi
}

###########################################
## Convertion octets -> Kio -> Mio -> Gio -> Tio -> Pio -> Eio -> Zio -> Yio ##
###########################################

function CONVERTION()
{
	COUNT="1024"
	
	if COMPARE "$COUNT" "$1" 
	then
		return 0
	fi
	
	echo "Soit :" 1>&2
	
	for i in K M G T P E Z Y
	do
	if COMPARE "$1" "$COUNT"
	then
		CONV="$(bc<<<"scale=2; $1/$COUNT")"
		echo "- ${CONV} ${i}io"
		COUNT="$(bc<<<"$COUNT*1024")"
	else
		return 0
	fi
	done 1>&2
}

################################################
## Résoudre le probleme des chaines longues dans les comparaisons nnumériques ##
################################################

function COMPARE()
{
	ZERO="$(bc<<<"$1<=$2")"
	return "$ZERO"
}

###################
## Lire une archive ULTRA ##
###################

function READ()
{
	ZIP="$1"
	NOM_ZIP="$(basename "$1")"
	DICT="$(echo "$NOM_ZIP" | cut -d'.' -f1)"
	TXT_DICT="$DICT.txt"
	TXT_SEP="$DICT.sep"
	eval $(7z e -so "$ZIP" -- "$TXT_SEP" 2>/dev/null | cat)

	while read WORD
	do
		if [[ es"$SEP"pace = "es pace" ]]
		then
			7z e -so "$ZIP" -- "$DICT" 2>/dev/null | sed -u -e "/$WORD/d; s/^/$WORD /g"
		else
			7z e -so "$ZIP" -- "$DICT" 2>/dev/null | sed -u -e "/$WORD/d; s/^/$WORD /g; s/ /$SEP/g" 
		fi
	done <<<"$(7z e -so "$ZIP" -- "$TXT_DICT" 2>/dev/null | cat)"
}

################
## On parse les options ##
################

while getopts ":l:L:w:i:d:r:P:s:vyCh" OPT_PASS
do
	case "$OPT_PASS" in
	l)
		LONGMIN="$OPTARG";;
	L)
		LONGMAX="$OPTARG";;
	w)
		SEQ="$OPTARG";;
	i)
		ORIGINAL="$OPTARG"
		if [[ ! -e "$ORIGINAL" ]]
		then
			echo "Le fichier n'existe pas" 1>&2
			exit 1
		fi
		DIR="${ORIGINAL%/*}";;
	v)
		VITESSE="1";;
	d)
		WDIR="$OPTARG"
		mkdir -p "$WDIR"
		DIR="$WDIR";;
	y)
		REPONSE="y"
		EXIT="y";;
	C)
		COMPRESSE="0";;
	r)
		ZIP="$OPTARG"
		if [[ ! -e "$ZIP" ]]
		then
			echo "Le fichier n'existe pas" 1>&2
			exit 1
		fi
		if [[ "$(file "$OPTARG" | grep -w "7-zip")" = "1" ]]
		then
			echo "Cette archive n'est pas pris en charge" 1>&2
			exit 1
		fi
		READ "$ZIP"
		exit 0;;
	P)
		NBRM="$OPTARG";;
	s)
		SEP="$OPTARG"
		NULL="0";;
	h)
		HELP
		exit 0;;
	*)
		HELP
		exit 1;;
	esac
done

#################
## Pas d'options -> help ##
#################

if [[ "$(echo "$@"no)" = "no" ]]
then
	HELP
	exit 1
fi
################################
## Le mode compression désactive le mode verbeux ##
################################


if [[ "$COMPRESSE" = "0" ]]
then
	if  [[ "$VITESSE" = "1" ]]
	then
		echo -e "Le mode compression et le mode verbeux sont inccompatibles" 1>&2
	exit 1
	fi
	VITESSE="2"
fi

##########################
## On se place dans le dossier de travail ##
##########################

cd "$DIR"

#####################################
## On trie le dictionnaire en fonction de la longeur des mots ##
#####################################

LONGX="$(bc<<<"$LONGMAX +1")"
sed   "/^.\{$LONGMIN\}/!d; /^.\{$LONGX\}/d" "$ORIGINAL" | sort -u -R > "$DICO"

##################################
## On reccupere le nombre de mots du dictionnaire trié ##
##################################

LIGNE="$(wc -l<"$DICO")"
MULTIPLI="$LIGNE"

#############################################################
## Si le nombre de mots par phrases à créer est supérieur au nombre de mot du dictionnaire , on quitte ##
#############################################################

if COMPARE   "$SEQ"  "$LIGNE"
then
	echo "Le nombre de mots composants la phrase doit être égal ou inférieur au nombre de mots composants le dictionnaire :
	Nombre de lignes du dictionnaire : $LIGNE
	Nombre de mots par phrase :$SEQ " 1>&2
	rm "$DICO"
	exit 1
fi

###########################
## Calcul du poid et du nombre de phrases ##
###########################

POID="$(stat -c %s "$DICO")"
PMOY="$(bc<<<"$POID/$LIGNE")"
MAX="$(bc<<<"($NBRM/($LIGNE-$SEQ))+1")"
MX="$(bc<<<"($MAX/$LIGNE)+1")"

while [[ "$NBR" != "$SEQ" ]]
do
	(( NBR ++ ))
	MULTIPLI="$(bc<<<"$MULTIPLI - 1")"
	FACT="$(bc<<<"$FACT*$MULTIPLI")"
done

PHRASE="$(bc<<<"$LIGNE*$FACT")"
TOTAL="$(bc<<<"$POID*$FACT*$SEQ")"
PTOT="$(bc<<<"$PMOY*$SEQ*$NBRM")"

if COMPARE "$NBRM" "$PHRASE"
then
	PTOT="$TOTAL"
	NBRM="$PHRASE"
fi

if [[ "$VITESSE" = "2" ]]
then	
	PTOT="$(bc<<<"(($PMOY*($SEQ-1)*$MAX)+$POID)/33")"
fi


##################################################
## On invite l'utilisateur à choisir si oui ou non il souhaite exploser son disque dur :) ##
##################################################

LIBRE="$(bc<<<"$(df "$DICO" | grep dev | awk '{ print $4 }')*1024")"
echo "Espace libre disponible : $LIBRE octets" 1>&2
CONVERTION "$LIBRE"

echo -e "\n\
Nombre de lignes du dictionnaire : $LIGNE
Longueur minimal des mots : $LONGMIN
Longueur maximal des mots : $LONGMAX
Nombre de mots par phrase : $SEQ
Nombre de phrases : $PHRASE
Poid : $TOTAL octets" 1>&2
CONVERTION "$TOTAL"

echo -e "\n\
Nombre de phrases limitées à : $NBRM
Poid supposé du fichier généré : $PTOT octets" 1>&2
CONVERTION "$PTOT"

POURCENT="$(bc -l<<<"100*($NBRM/$PHRASE)")"

echo -e "\nCe fichier couvre $POURCENT % des possibibiltées !"  1>&2

if COMPARE "$PTOT" "$LIBRE"
then
	echo -e "\nVous ne disposez pas de l'espace disque nécessaire !\nVeuillez corriger les options sélectionnées ." 1>&2
	exit 1
fi

##############
## On lance la bête ##
##############

if [[ "$REPONSE" = "n" ]]
then
	echo -e "\nSouhaitez vous poursuivre ?\n[y/n]" 1>&2
	read REPONSE
else
	echo -e "\nExécution sans confirmation\n" 1>&2
fi


case "$REPONSE" in
	y) 
		cp "$DICO" "$NEW"
		DEBUT="$(date +%s)"
		PERMUTE "$VITESSE"
		FIN="$(date +%s)"
		GEN="$(bc<<<"$FIN-$DEBUT")";;
	n)
		echo "On quitte"
		CLEAN
		exit 0;;
	*)
		echo "Choix invalide , on quitte ." 1>&2
		CLEAN
		exit 1;;
esac

##############################
## Quelques informations sur le fichier produit ##
##############################

TOTAL="$(stat -c %s "$DICO")"
DATE="$(date +"%H h %M mn %S s" -d "0000-01-01 $GEN seconds")"
VIT="$(bc<<<"$NBRM/$GEN")"
TVIT="$(bc<<<"$PHRASE/$VIT")"
TANS="$(bc<<<"$TVIT/$ANS")"
TREST="$(bc<<<"$TVIT-($TANS*$ANS)")"
TMOIS="$(bc<<<"$TREST/$MOIS")"
TREST="$(bc<<<"$TREST-($TMOIS*$MOIS)")"
TJOURS="$(bc<<<"$TREST/$JOURS")"
TREST="$(bc<<<"$TREST-($TJOURS*$JOURS)")"
TDATE="$(date +"$TANS années $TMOIS mois $TJOURS jours %H heures %M minutes %S secondes" -d "0000-01-01 $TREST seconds")"

echo -e "
Fichier de sortie : $DIR/$DICO
Poid du fichier produit : $TOTAL octets" 1>&2
CONVERTION "$TOTAL"

echo -e "
Temps écoulé ; $GEN secondes
Soit : $DATE" 1>&2

echo -e "\nVitesse d'éxécution : $VIT phrases par seconde" 1>&2

echo -e "\nTemps nécessaire à la créations de toutes les phrases :\n$TDATE" 1>&2

if [[ "$EXIT" = "y" ]]
then
	exit 0
fi

echo -e "
Souhaitez vous vérifier le nombre de phrases générées ?
Attention cette opération peut être très longue
[y/n]" 1>&2

read VERIF

if [[ "$VERIF" = "y" ]]
then
	if [[ "$VITESSE" = "2" ]]
	then
		eval $(READ "$DICO" | wc -l -c | awk '{ printf "NBR_PH=\"%s\"\nPOID=\"%s\"\n", $1, $2 }')
		TXCMP="$(bc<<<"$POID/$TOTAL")"
		echo -e "\nPoid décompressé : $POID octets" 1>&2
		CONVERTION "$POID"
		echo -e "\nNombre de phrases générées : $NBR_PH\nTaux de compression : $TXCMP" 1>&2
		exit 0
	else
		NBR_PH="$(wc -l<"$DICO")"
		echo -e "\nNombre de phrases générées : $NBR_PH" 1>&2
	fi
fi

exit 0

