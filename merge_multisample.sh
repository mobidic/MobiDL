#!/usr/bin/env bash

###########################################################################
#########																												###########
#########		mergemultisample																		###########
######### @uthor : D Baux	david.baux<at>inserm.fr								###########
######### Date : 10/05/2021																			###########
#########																												###########
###########################################################################

###########################################################################
###########
########### 	Script to semi-automate MobiDL treatment of families
###########
###########################################################################


### input: a txt file of format:

## RUN_PATH=
## BASE_JSON=
## DISEASE_FILE=
## GENES_OF_INTEREST=
## ACHAB_TODO=
## NUM_FAM=
## TRIO=[0|1]
## # if yes
## CI=
## FATHER=
## MOTHER=
## # if no
## AFFECTED=sample1,sample2...
## HEALTHY=sample1,sample2...


VERSION=1.0
USAGE="
Program: merge_multisample
Version: ${VERSION}
Contact: Baux David <david.baux@inserm.fr>

Usage: bash merge_multisample.sh -f /path/to/input/file -b /path/to/bcftools
"

if [ $# -eq 0 ]; then
	echo "${USAGE}"
	echo "Error Message : No arguments provided"
	echo ""
	exit 1
fi

usage ()
{
	echo 'This script prepares achab for families.'
	echo 'Usage : bash merge_multisample.sh'
	echo '	Mandatory arguments :'
	echo '		* -f|--family-file	<path to input file>'
	echo '	Optional arguments :'
	echo '		* -b|--bcftools	<path to bcftools>'
	echo '		* -t|--threads	<int>'
	echo '		* -s|--slurm'
	echo 'The slurm argument if provided will launch bcftools in a srun command.'
}

RED='\033[0;31m'
LIGHTRED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
# -- Script log

VERBOSITY=3
# -- Log variables

ERROR=1
WARNING=2
INFO=3
DEBUG=4
# -- Log functions got from cww.sh -- simplified here

error() { log "${ERROR}" "[${RED}error${NC}]" "$1" ; }
warning() { log "${WARNING}" "[${YELLOW}warn${NC}]" "$1" ; }
info() { log "${INFO}" "[${BLUE}info${NC}]" "$1" ; }
debug() { log "${DEBUG}" "[${LIGHTRED}debug${NC}]" "$1" ; }

# -- Print log

echoerr() { echo -e "$@" 1>&2 ; }

log() {
	if [ "${VERBOSITY}" -ge "$1" ]; then
		echoerr "[`date +'%Y-%m-%d %H:%M:%S'`] $2 - MM version : ${VERSION} - $3"
	fi
}

# -- Options

BCFTOOLS=$(which bcftools)
THREADS=1
SLURM=0

# -- Parse command line
while [ "$1" != "" ];do
	case $1 in
		-b | --bcftools) shift
			BCFTOOLS=$1
			;;
		-f | --family-file)	shift
			FAMILY_FILE=$1
			;;
		-t | --threads) shift
			if [[ "$1" =~ ^[0-9]+$ ]]
			then
				THREADS=$1
			fi
			;;
		-s | --slurm)
			SLURM=1
			;;
		-v | --verbosity) shift
			# Check if verbosity level argument is an integer before assignment
			if ! [[ "$1" =~ ^[0-9]+$ ]]
			then
				error "\"$1\" must be an integer !"
				echo " "
				help
			else
				VERBOSITY=$1
				((VERBOSITYCOUNTER++))
			fi
			;;
		-h | --help)	usage
			exit
			;;
		* )	usage
			exit 1
	esac
	shift
done

if [[ ! -x "${BCFTOOLS}" ]]; then
	error "bcftools path ${BCFTOOLS} seems to be wrong."
	usage
	exit 1
fi
if [[ ! -r "${FAMILY_FILE}" ]]; then
	error "File ${FAMILY_FILE} does not seem to exist."
	usage
	exit 1
fi


# -- get variables from conf file
source ${FAMILY_FILE}

if [[ ! -d "${RUN_PATH}" || ! -f "${BASE_JSON}" || ! "${RUN_ID}" || ! "${DATE}" || ! "${NUM_FAM}" || ! "${TRIO}"  || ! -f "${DISEASE_FILE}"  || "${GENES_OF_INTEREST}" == '' || ! -d "${ACHAB_TODO}" ]]; then
	error "There is an error with one of the params of the Family file."
	usage
	exit 1
fi
if [ ! "${AFFECTED}" ]; then
	error "There should be at least one sample affected."
	usage
	exit 1
fi
if [[ "${TRIO}" == 1 ]]; then
	if [[ ! "${CI}" || ! "${FATHER}" || ! "${MOTHER}" ]]; then
		error "At least one member of the trio is lacking."
		usage
		exit 1
	fi
fi

# RUN_PATH from autoDLML.sh comes with a / in the end - remove it
RUN_PATH=${RUN_PATH%\/}

# -- Debug
debug "BCFTOOLS:${BCFTOOLS}"
debug "FAMILY_FILE:${FAMILY_FILE}"
debug "THREADS:${THREADS}"
debug "SLURM:${SLURM}"
debug "RUN_PATH:${RUN_PATH}"
debug "BASE_JSON:${BASE_JSON}"
debug "DISEASE_FILE:${DISEASE_FILE}"
debug "GENES_OF_INTEREST:${GENES_OF_INTEREST}"
debug "RUN_ID:${RUN_ID}"
debug "SUBPATH:${SUBPATH}
debug "NUM_FAM:${NUM_FAM}"
debug "TRIO:${TRIO}"
debug "AFFECTED:${AFFECTED}"
debug "CI:${CI}"
debug "FATHER:${FATHER}"
debug "MOTHER:${MOTHER}"

# -- build the VCF list
if [[ "${TRIO}" == 1 ]]; then
	VCFS="${RUN_PATH}/${RUN_ID}/MobiDL/${SUBPATH}/${CI}/panelCapture/${CI}.vcf.gz,"
	VCFS+="${RUN_PATH}/${RUN_ID}/MobiDL/${SUBPATH}/${FATHER}/panelCapture/${FATHER}.vcf.gz,"
	VCFS+="${RUN_PATH}/${RUN_ID}/MobiDL/${SUBPATH}/${MOTHER}/panelCapture/${MOTHER}.vcf.gz"
else
	# -- build the list from the list of affected and HEALTHY
	# first split the sample list and rebuild the VCF list (with path)
	# VCF_AFFECTED
	IFS="," read -a VCF_AFFECTED <<< "${AFFECTED}"
	IFS="," read -a VCF_HEALTHY <<< "${HEALTHY}"
	VCFS=""
	for VCF_AFF in "${VCF_AFFECTED[@]}"; do
		VCFS+="${RUN_PATH}/${RUN_ID}/MobiDL/${SUBPATH}/${VCF_AFF}/panelCapture/${VCF_AFF}.vcf.gz,"
	done
	for VCF_HEA in "${VCF_HEALTHY[@]}"; do
		VCFS+="${RUN_PATH}/${RUN_ID}/MobiDL/${SUBPATH}/${VCF_HEA}/panelCapture/${VCF_HEA}.vcf.gz,"
	done
fi
IFS="," read -a VCF_ARRAY <<< "${VCFS}"

# -- prepare output
FAMILY_PATH="${RUN_PATH}/${RUN_ID}/MobiDL/${SUBPATH}/${NUM_FAM}"
mkdir -p "${FAMILY_PATH}"
cp "${BASE_JSON}" "${FAMILY_PATH}/captainAchab_inputs.json"
cp "${DISEASE_FILE}" "${FAMILY_PATH}/disease.txt"

# -- merge VCF
MERGE_CMD="${BCFTOOLS} merge --threads ${THREADS} "
for VCF in "${VCF_ARRAY[@]}"; do
	MERGE_CMD+="${VCF} "
done
# MERGE_CMD+="> ${FAMILY_PATH}/${NUM_FAM}.vcf"
SLURM_CMD=" "
if [ "${SLURM}" -eq 1 ];then
	SLURM_CMD="srun -N1 -c${THREADS} "
fi
info "launching bcftools"
debug "${SLURM_CMD}${MERGE_CMD} > ${FAMILY_PATH}/${NUM_FAM}.vcf"

${SLURM_CMD}${MERGE_CMD} > "${FAMILY_PATH}/${NUM_FAM}.vcf"

if [ $? -eq 0 ]; then
	# -- temp modif between monster and cluster
	# MONSTER_PREFIX="/RS_IURC/data"
	# CLUSTER_PREFIX="/mnt/data140"
	# JSON_RUN_PATH="${CLUSTER_PREFIX}${RUN_PATH#$MONSTER_PREFIX}"
	# JSON_DISEASE_FILE="${CLUSTER_PREFIX}${DISEASE_FILE#$MONSTER_PREFIX}"
	# info "${JSON_RUN_PATH}"
	# info "${JSON_DISEASE_FILE}"
	# -- prepare vars by escaping "/"
	# RUN_SED=${JSON_RUN_PATH////\\/}
	RUN_SED=${RUN_PATH////\\/}
	DISEASE_SED=${JSON_DISEASE_FILE////\\/}
	GENES_SED=${GENES_OF_INTEREST////\\/}
	# -- sed the JSON
	if [[ ${TRIO} == 0 ]]; then
		sed -i -e "s/\(  \"captainAchab\.sampleID\": \"\).*/\1${NUM_FAM}\",/" \
			-e "s/\(  \"captainAchab\.affected\": \"\).*/\1${AFFECTED}\",/" \
			-e "s/\(  \"captainAchab\.inputVcf\": \"\).*/\1${RUN_SED}\/${RUN_ID}\/MobiDL\/${NUM_FAM}\/${NUM_FAM}\.vcf\",/" \
			-e "s/\(  \"captainAchab\.diseaseFile\": \"\).*/\1${DISEASE_SED}\",/" \
			-e "s/\(  \"captainAchab\.genesOfInterest\": \"\).*/\1${GENES_SED}\",/" \
			-e "s/\(  \"captainAchab\.outDir\": \"\).*/\1${RUN_SED}\/${RUN_ID}\/MobiDL\/${NUM_FAM}\/\",/" \
			"${FAMILY_PATH}/captainAchab_inputs.json"
	else
		sed -i -e "s/\(  \"captainAchab\.sampleID\": \"\).*/\1${NUM_FAM}\",/" \
			-e "s/\(  \"captainAchab\.affected\": \"\).*/\1${AFFECTED}\",/" \
			-e "s/\(  \"captainAchab\.inputVcf\": \"\).*/\1${RUN_SED}\/${RUN_ID}\/MobiDL\/${NUM_FAM}\/${NUM_FAM}\.vcf\",/" \
			-e "s/\(  \"captainAchab\.diseaseFile\": \"\).*/\1${DISEASE_SED}\",/" \
			-e "s/\(  \"captainAchab\.checkTrio\": \"\).*/\1--trio\",/" \
			-e "s/\(  \"captainAchab\.caseSample\": \"\).*/\1${CI}\",/" \
			-e "s/\(  \"captainAchab\.fatherSample\": \"\).*/\1${FATHER}\",/" \
			-e "s/\(  \"captainAchab\.motherSample\": \"\).*/\1${MOTHER}\",/" \
			-e "s/\(  \"captainAchab\.genesOfInterest\": \"\).*/\1${GENES_SED}\",/" \
			-e "s/\(  \"captainAchab\.outDir\": \"\).*/\1${RUN_SED}\/${RUN_ID}\/MobiDL\/${NUM_FAM}\/\",/" \
			"${FAMILY_PATH}/captainAchab_inputs.json"
	fi

	info "JSON ${FAMILY_PATH}/captainAchab_inputs.json seded"

	rsync -az "${FAMILY_PATH}" "${ACHAB_TODO}"

	info "FAM ${NUM_FAM} sent to Achab"
else
	error "bcftools failed: ${MERGE_CMD}"
fi
