#!/bin/bash

###########################################################################
#########														###########
#########		AutoDLML											###########
######### @uthor : D Baux	david.baux<at>chu-montpellier.fr	###########
######### Date : 28/10/2021										###########
#########														###########
###########################################################################

###########################################################################
###########
########### 	Script to automate MobiDL pipelines
########### 	to treat NGS data
###########
###########################################################################


####	This script is meant to be croned
####	must check the runs directory, identify new runs
####	and launch the appropriate MobiDL pipeline when a new run is available


##############		If any option is given, print help message	##################################
VERSION=20260201
# USAGE="
# Program: metaAutoDLML
# Version: ${VERSION}
# Contact: Baux David <david.baux@chu-montpellier.fr>, Felix VanDerMeeren <felix.vandermeeren@chu-montpellier.fr>

# Usage: This script is meant to be croned
# 	Should be executed once per 10 minutes

# "
usage() {
	echo 'This script automates MobiDL workflows.'
	echo 'Program: metaAutoDLML'
	echo 'Version: ${VERSION}'
	echo 'Contact: Baux David <david.baux@chu-montpellier.fr>'
	echo 'Usage : bash autoDLML.sh --config <path to conf file> [-v 4]'
	echo '	Mandatory arguments :'
	echo '		* -c|--config		<path to conf file>: default: ./autoDL.conf'
	echo '	Optional arguments :'
	echo '		* -v | --verbosity	<integer> : decrease or increase verbosity level (ERROR : 1 | WARNING : 2 | INFO : 3 (default) | DEBUG : 5)'
	echo '	General arguments :'
	echo '		* -h: 			show this help message and exit'
	echo ''
	exit
}

# bloc needed if no arguments should be provided
# if [ $# -ne 0 ]; then
# 	echo "${USAGE}"
# 	echo "Error Message : Arguments provided"
# 	echo ""
# 	exit 1
# fi

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
		echoerr "[`date +'%Y-%m-%d %H:%M:%S'`] $2 - autoDLML version : ${VERSION} - $3"
	fi
}


###############		Get options from conf file			##################################
CONFIG_FILE='./autoDL.conf'
# CONFIG_FILE='/bioinfo/softs/MobiDL_conf/autoDL.conf'
DRY_RUN=false

###############		Parse command line			##################################
while [ "$1" != "" ];do
	case $1 in
		-c | --config)	shift
			CONFIG_FILE=$1			
			;;
		-v | --verbosity) shift 
			# Check if verbosity level argument is an integer before assignment 
			if ! [[ "$1" =~ ^[0-9]+$ ]]
			then 
				error "\"$1\" must be an integer !"
				echo " "
				usage 
			else 
				VERBOSITY=$1
			fi 
			;;
		-d | --dry-run) shift
			DRY_RUN=true
			;;
		-h | --help)	usage
			exit
			;;
		* )	usage
			exit 1
	esac
	shift
done

# -- SLURM
# does not work for some reason must be hard-written
# SRUN="/usr/bin/srun -N1 -c1 -pprod -J"
# SBATCH="sbatch -N=1 -n=1 -c=1 -p=prod -J="
# could be used as is with --wrap w/out file

if [ ! -f "${CONFIG_FILE}" ]; then
    error "Config file ${CONFIG_FILE} not found!"
fi

# we check the params against a regexp
UNKNOWN=$(cat  ${CONFIG_FILE} | grep -Evi "^(#.*|[A-Z0-9_]*=[a-z0-9_ \"\.\/\$\{\}\*-]*)$")
if [ -n "${UNKNOWN}" ]; then
	error "Error in config file. Offending lines:"
	error "${UNKNOWN}"
	exit 1
fi

source "${CONFIG_FILE}"

###############		1st check whether another instance of the script is running	##################

RESULT=$(ps x | grep -v grep | grep -c ${SERVICE})
debug "${SERVICE} pids: $(ps x | grep -v grep |grep -c ${SERVICE})"

if [ "${RESULT}" -gt 3 ]; then
	exit 0
fi

debug "CONFIG FILE: ${CONFIG_FILE}"


###############		Get run info file				 ##################################

# the file contains the run id and a code
# 0 => not treated => to do - used to retreat a run in case ex of error
# 1 => nenufaar is running -in case the security above does not work
# 2 => run treated - ignore directory
# the file is stored in an array and modified by the script

if [ ! -s "${RUNS_FILE}" ]; then
    error "Runs file ${RUNS_FILE} not found or is empty!"
	exit 1
fi

declare -A RUN_ARRAY #init array
while read LINE
do
	if echo ${LINE} | grep -E -v '^(#|$)' &>/dev/null; then
		if echo ${LINE} | grep -F '=' &>/dev/null; then
			RUN_ID=$(echo "${LINE}" | cut -d '=' -f 1)
			RUN_ARRAY[${RUN_ID}]=$(echo "${LINE}" | cut -d '=' -f 2-)
		fi
	fi
done < ${RUNS_FILE}

#choosePipeline() {
#	return $(${GREP} -F "${SAMPLE_SHEET}" "${SAMPLE_SHEET_DB}" | cut -d '=' -f 2)
#}



MAX_DEPTH=''
TRIGGER_FILE=''
TRIGGER_EXPR=''
SAMPLESHEET=''
PROVIDER="ILLUMINA"

DATE=`date +%Y%m%d`

assignVariables() {
	#${RUN_PATH}
	# if [[ "${1}" =~ "MiniSeq" ]];then
	if [[ "${1}" =~ "MINISEQ" ]];then
		MAX_DEPTH="${MINISEQ_MAX_DEPTH}"
		TRIGGER_FILE="${MINISEQ_TRIGGER_FILE}"
		TRIGGER_EXPR="${MINISEQ_TRIGGER_EXPR}"
		SAMPLESHEET="${MINISEQ_SAMPLESHEET_PATH}"
	elif [[ "${1}" =~ "MISEQ" ]];then
		MAX_DEPTH="${MISEQ_MAX_DEPTH}"
		TRIGGER_FILE="${MISEQ_TRIGGER_FILE}"
		TRIGGER_EXPR="${MISEQ_TRIGGER_EXPR}"
		SAMPLESHEET="${MISEQ_SAMPLESHEET_PATH}"
	elif [[ "${1}" =~ "NEXTSEQ" ]];then
		MAX_DEPTH="${NEXTSEQ_MAX_DEPTH}"
		TRIGGER_FILE="${NEXTSEQ_TRIGGER_FILE}"
		#TRIGGER_EXPR="${2} ${NEXTSEQ_TRIGGER_EXPR}"
		TRIGGER_EXPR="${NEXTSEQ_TRIGGER_EXPR}"
		SAMPLESHEET="${NEXTSEQ_SAMPLESHEET_PATH}"
	elif [[ "${1}" =~ "AVITI" ]];then
		MAX_DEPTH="${AVITI_MAX_DEPTH}"
		TRIGGER_FILE="${AVITI_TRIGGER_FILE}"
		TRIGGER_EXPR="${AVITI_TRIGGER_EXPR}"
		SAMPLESHEET="${AVITI_SAMPLESHEET_PATH}"
		PROVIDER="ELEMENT"
	fi
	debug "PROVIDER: ${PROVIDER}"
	TMP_OUTPUT_DIR2="${TMP_OUTPUT_DIR}${RUN}/"
}
dos2unixIfPossible() {
	#  if [[ "${RUN_PATH}" =~ "MiniSeq" ||  "${RUN_PATH}" =~ "MiSeq" ]];then
	 if [[ "${RUN_PATH}" =~ "MINISEQ" ||  "${RUN_PATH}" =~ "MISEQ" ]];then
	 	debug "dos2unix for ${RUN_PATH}${RUN}/${SAMPLESHEET}"
		"${DOS2UNIX}" -q "${RUN_PATH}${RUN}/${SAMPLESHEET}"
		# debug "dos2unix for ${SAMPLESHEET_PATH}"
		"${DOS2UNIX}" -q "${SAMPLESHEET_PATH}"
	fi
}
#moveRunIfNecessary() {
#	if [[ "${RUN_PATH}" =~ "NEXTSEQ" ]];then
	#if [ !-w "${RUN_PATH}${RUN}/${SAMPLESHEET}" ];then
#		${RSYNC} -avq "${RUN_PATH}${RUN}" "${NEXTSEQ_RUNS_DEST_DIR}"
#		if [ $? -eq 0 ];then
#			RUN_PATH="${NEXTSEQ_RUNS_DEST_DIR}"
#		else
#			error "Error while syncing ${RUN_PATH}${RUN} to ${NEXTSEQ_RUNS_DEST_DIR}"
#		fi
#	fi
#}

modifyJson() {
	debug "WDL:${WDL} - SAMPLE:${SAMPLE} - BED:${BED} - RUN:${RUN_PATH}${RUN}"
	if [[ ${BED} =~ (hg[0-9]{2}).*\.bed$ ]];then
		debug "BED: ${BED} - BASH_REMATCH: ${BASH_REMATCH[1]}"
		GENOME=${BASH_REMATCH[1]}
	else
		GENOME=hg19
	fi
	debug "WDL:${WDL} - SAMPLE:${SAMPLE} - BED:${BED} - RUN:${RUN_PATH}${RUN} - GENOME:${GENOME}"
	MOBIDL_JSON_TEMPLATE="${MOBIDL_JSON_DIR}${WDL}_inputs_${GENOME}.json"
	# if [ "${GENOME}" != "hg19" ];then
	# 	MOBIDL_JSON_TEMPLATE="${MOBIDL_JSON_DIR}${WDL}_inputs_${GENOME}.json"
	# fi
	debug "MOBIDL_JSON_TEMPLATE: ${MOBIDL_JSON_TEMPLATE}"
	if [ ! -e "${MOBIDL_JSON_TEMPLATE}" ];then
		error "No json file for ${WDL}: ${MOBIDL_JSON_TEMPLATE}"
	else
		cp "${MOBIDL_JSON_TEMPLATE}" "${AUTODL_DIR}${RUN}/${WDL}_${SAMPLE}_inputs.json"
		chmod 755 "${AUTODL_DIR}${RUN}/${WDL}_${SAMPLE}_inputs.json"
		# cp "${MOBIDL_JSON_DIR}${WDL}_inputs.json" "${AUTODL_DIR}${RUN}/${WDL}_${SAMPLE}_inputs.json"
		JSON="${AUTODL_DIR}${RUN}/${WDL}_${SAMPLE}_inputs.json"
		SUFFIX1=$(echo "${SAMPLES[${SAMPLE}]}" | cut -d ';' -f 1)
		SUFFIX2=$(echo "${SAMPLES[${SAMPLE}]}" | cut -d ';' -f 2)
		FASTQ_DIR=$(echo "${SAMPLES[${SAMPLE}]}" | cut -d ';' -f 3)
		PROJECT=''
		if [[ "${PROVIDER}" = "ELEMENT" ]];then
			PROJECT=$(echo "${SAMPLES[${SAMPLE}]}" | cut -d ';' -f 4)
			# if [ "${PROJECT}" = "DefaultProject" ];then
			# 	PROJECT=''
			# fi
		fi
		debug "FASTQ_DIR: ${FASTQ_DIR}"
		# https://stackoverflow.com/questions/6744006/can-i-use-sed-to-manipulate-a-variable-in-bash
		# bash native character replacement
		FASTQ_SED=${FASTQ_DIR////\\/}
		debug "FASTQ_SED: ${FASTQ_SED}"
		debug "PROJECT: ${PROJECT}"
		ROI_SED=${ROI_DIR////\\/}
		# RUN_SED=${RUN_PATH////\\/}
		if [ ! -d "${TMP_OUTPUT_DIR2}" ];then
			mkdir "${TMP_OUTPUT_DIR2}"
		fi
		TMP_OUTPUT_SED="${TMP_OUTPUT_DIR2////\\/}$PROJECT"
		debug "TMP_OUTPUT_SED+PROJECT: '${TMP_OUTPUT_SED}'"
		# gene file for covreport
		if [ "${MANIFEST}" != "GenerateFastQWorkflow" ] && [ "${MANIFEST}" != "GenerateFASTQ" ]; then
			COVREPORT_GENE_FILE="$(basename $(grep ${MANIFEST%?} ${ROI_FILE} | cut -d '=' -f 2 | cut -d ',' -f 3))"
			COVREPORT_GENE_FILE_PATH="${CONF_DIR}achabGenesOfInterest/covreport_gene_dir/${COVREPORT_GENE_FILE}"
		else
			COVREPORT_GENE_FILE="$(basename $(grep ${BED} ${FASTQ_WORKFLOWS_FILE} | cut -d ',' -f 2))"
			COVREPORT_GENE_FILE_PATH="${CONF_DIR}achabGenesOfInterest/covreport_gene_dir/${COVREPORT_GENE_FILE}"
		fi
		COVREPORT_GENE_FILE_PATH_SED=${COVREPORT_GENE_FILE_PATH////\\/}
		sed -i.bak -e "s/\(  \"${WDL}.sampleID\": \"\).*/\1${SAMPLE}\",/" \
			-e "s/\(  \"${WDL}\.suffix1\": \"\).*/\1_${SUFFIX1}\",/" \
			-e "s/\(  \"${WDL}\.suffix2\": \"\).*/\1_${SUFFIX2}\",/" \
			-e "s/\(  \"${WDL}\.platform\": \"\).*/\1${PROVIDER}\",/" \
			-e "s/\(  \"${WDL}\.fastqR1\": \"\).*/\1${FASTQ_SED}\/${SAMPLE}_${SUFFIX1}\.fastq\.gz\",/" \
			-e "s/\(  \"${WDL}\.fastqR2\": \"\).*/\1${FASTQ_SED}\/${SAMPLE}_${SUFFIX2}\.fastq\.gz\",/" \
			-e "s/\(  \"${WDL}\.workflowType\": \"\).*/\1${WDL}\",/" \
			-e "s/\(  \"${WDL}\.intervalBedFile\": \"\).*/\1${ROI_SED}${BED}\",/" \
			-e "s/\(  \"${WDL}\.outDir\": \"\).*/\1${TMP_OUTPUT_SED}\",/" \
			-e "s/\(  \"${WDL}\.geneFile\": \"\).*/\1${COVREPORT_GENE_FILE_PATH_SED}\",/" \
			"${JSON}"
		rm "${JSON}.bak"
		# -e "s/\(  \"${WDL}\.bedFile\": \"\).*/\1${ROI_SED}${BED}\",/" \
		# -e "s/\(  \"${WDL}\.dvOut\": \"\).*/\1\/scratch\/tmp_output\/${RUN}\",/" "${JSON}" \
		debug "$(cat ${JSON})"
		# For MetaPanelCapture:
		# Build a JSON list by genome
		metaWDL="metaPanelCapture"
		printf "[\"${BED}\",\"${SAMPLE}\",\"${SAMPLE}_${SUFFIX1}.fastq.gz\",\"${SAMPLE}_${SUFFIX2}.fastq.gz\", \"${COVREPORT_GENE_FILE}\"]," >> "${AUTODL_DIR}${RUN}/samplesInfos_${metaWDL}.${GENOME}"
	fi
}

gatherJsonsAndLaunch() {
	# Loop on genomes:
	for aList in "${AUTODL_DIR}${RUN}"/samplesInfos_${metaWDL}.* ; do
		GENOME=$(basename "${aList}" | cut -d"." -f2)
		info "Processing all samples with genome ${GENOME}"
		firstSample=$(awk -F"," '{print $2}' "${aList}" | tr -d '"')
		MOBIDL_JSON_TEMPLATE="${AUTODL_DIR}${RUN}/${WDL}_${firstSample}_inputs.json"
		debug "Derivate 'metaPanelCapture_JSON' from JSON of 1st sample : ${MOBIDL_JSON_TEMPLATE}"
		if [ ! -e "${MOBIDL_JSON_TEMPLATE}" ];then
			error "No json file for ${WDL}: ${MOBIDL_JSON_TEMPLATE}"
		else
			JSON="${AUTODL_DIR}${RUN}/${metaWDL}_${GENOME}_inputs.json"
			# Extract info from 'samplesInfos' file(s) (created by 'modifyJson()'):
			# INFO: 'inputsLists' variable contains quotes -> complicated with sed
			#       Instead send string to file
			sed -e "s/^/{\n  \"${metaWDL}.inputsLists\": [/" -e 's/,$/],\n/' "${aList}" > "${JSON}"
			chmod 755 "${JSON}"
			# Then add parms specific to 'metaPanelCapture' workflow:
			printf "  \"${metaWDL}.roiDir\": \"${ROI_DIR}\",\n" >> "${JSON}"
			printf "  \"${metaWDL}.fastqDirname\": \"${FASTQ_DIR}\",\n" >> "${JSON}"
			printf "  \"${metaWDL}.outDir\": \"${TMP_OUTPUT_DIR2}\",\n" >> "${JSON}"
			printf "  \"${metaWDL}.geneFile\": \"${CONF_DIR}achabGenesOfInterest/covreport_gene_dir/\",\n" >> "${JSON}"
			# Add rest of params, extracted from 'panelCapture_JSON':
			grep -vE "\{|\.fastqR1|\.fastqR2|\.suffix1|\.suffix2|\.intervalBedFile|\.sampleID|\.geneFile" "${MOBIDL_JSON_TEMPLATE}" |
				sed "s/${WDL}\./${metaWDL}\./" >> "${JSON}"
			debug "$(cat ${JSON})"
			info "Launching:"
			info "${CWW} -e ${CROMWELL} -o ${CROMWELL_OPTIONS} -c ${CROMWELL_CONF} -w ${WDL_PATH}${metaWDL}.wdl -i ${JSON}"
			if [ ! -d "${TMP_OUTPUT_DIR2}Logs" ];then
				mkdir -p "${TMP_OUTPUT_DIR2}Logs"
			fi
			LOG_FILE=${TMP_OUTPUT_DIR2}Logs/${metaWDL}_${GENOME}.log
			touch "${LOG_FILE}"
			info "MobiDL ${metaWDL} log in ${LOG_FILE}"
			# actual launch and copy in the end
			source "${CONDA_ACTIVATE}" "${GATK_ENV}" || { error "Failed to activate Conda environment"; exit 1; }
			if [ "${DRY_RUN}" = true ];then
				info "WDL launching command: ${CWW} -e ${CROMWELL} -o ${CROMWELL_OPTIONS} -c ${CROMWELL_CONF} -w ${WDL_PATH}${metaWDL}.wdl -i ${JSON}"
				info "Log in ${LOG_FILE}"
			else
				"${CWW}" -e "${CROMWELL}" -o "${CROMWELL_OPTIONS}" -c "${CROMWELL_CONF}" -w "${WDL_PATH}${metaWDL}.wdl" -i "${JSON}" >> "${LOG_FILE}"
			fi
			if [ $? -eq 0 ];then
				conda deactivate
				workflowPostTreatment "${metaWDL}" "${GENOME}"
			else
				# # GATK_LEFT_ALIGN_INDEL_ERROR=$(grep 'the range cannot contain negative indices' "${TMP_OUTPUT_DIR2}Logs/${SAMPLE}_${WDL}.log")
				# # david 20210215 replace with below because of cromwell change does not report errors in main logs anymore
				# GATK_LEFT_ALIGN_INDEL_ERROR=$(egrep 'Job panelCapture.gatkLeftAlignIndels:....? exited with return code 3' "${TMP_OUTPUT_DIR2}Logs/${SAMPLE}_${WDL}.log")
				# # search for an error with gatk LAI - if found relaunch without this step
				# # cannot explain this error - maybe a gatk bug?
				# if [ "${GATK_LEFT_ALIGN_INDEL_ERROR}" != '' ];then
				# 	info "GATK LeftAlignIndel Error occured - relaunching MobiDL without this step"
				# 	"${CWW}" -e "${CROMWELL}" -o "${CROMWELL_OPTIONS}" -c "${CROMWELL_CONF}" -w "${WDL_PATH}${WDL}_noGatkLai.wdl" -i "${JSON}" >> "${TMP_OUTPUT_DIR2}Logs/${SAMPLE}_${WDL}_noGatkLai.log"
				# 	conda deactivate
				# 	if [ $? -eq 0 ];then
				# 		workflowPostTreatment "${WDL}_noGatkLai"
				# 	else
				# 		error "Error while executing ${WDL}_noGatkLai for ${SAMPLE} in run ${RUN_PATH}${RUN}"
				# 	fi
				# else
				error "Error while executing ${metaWDL} for ${GENOME} in run ${RUN_PATH}${RUN}"
				# fi
			fi
		fi
	done
}

workflowPostTreatment() {
	# if [[ "${RUN_PATH}" =~ "NEXTSEQ" ]];then
	# 	RUN_PATH="${NEXTSEQ_RUNS_DEST_DIR}"
	# elif [[ "${RUN_PATH}" =~ "MISEQ" ]];then
	# 	RUN_PATH="${MISEQ_RUNS_DEST_DIR}"
	# fi
	# copy to final destination
	if [ "${DRY_RUN}" = true ];then
		info "syncing log data command: /usr/bin/srun -N1 -c1 -pprod -JautoDL_rsync_log ${RSYNC} -aq --no-g --chmod=ugo=rwX --remove-source-files ${TMP_OUTPUT_DIR2}Logs/${1}_${2}.log ${TMP_OUTPUT_DIR2}"
		info "syncing data command: /usr/bin/srun -N1 -c1 -pprod -JautoDL_rsync_sample ${RSYNC} -aqz --no-g --chmod=ugo=rwX ${TMP_OUTPUT_DIR2}/* ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/"
	else
		/usr/bin/srun -N1 -c1 -pprod -JautoDL_rsync_log "${RSYNC}" -aq --no-g --chmod=ugo=rwX --remove-source-files "${TMP_OUTPUT_DIR2}Logs/${1}_${2}.log" "${TMP_OUTPUT_DIR2}"
		rm -r "${TMP_OUTPUT_DIR2}Logs/"  # Remove, otherwise 'Logs' dir copied to FINAL_DIR
		info "Moving MobiDL results to ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/"
		/usr/bin/srun -N1 -c1 -pprod -JautoDL_rsync_sample "${RSYNC}" -aqz --no-g --chmod=ugo=rwX "${TMP_OUTPUT_DIR2}"/* "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/"
		if [ $? -eq 0 ];then
			chmod -R 777 "${TMP_OUTPUT_DIR2}"
			rm -r "${TMP_OUTPUT_DIR2}"
		else
			error "Error while syncing ${1} in run ${OUTPUT_PATH}${RUN}"
		fi
		# remove cromwell data
		WORKFLOW_ID=$(grep "${CROMWELL_ID_EXP}" "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${1}_${2}.log" | rev | cut -d ' ' -f 1 | rev)
		if [[ -n "${WORKFLOW_ID}" ]]; then
			# test récupérer le path courant
			rm -r "./cromwell-executions/${1}/${WORKFLOW_ID}"
			info "removed cromwell data for ${WORKFLOW_ID}"
		fi
	fi
}


setvariables() {
	ACHAB=captainAchab
	ACHAB_TODO_DIR_SED=${ACHAB_TODO_DIR////\\/}
	GENE_FILE_SED=${GENE_FILE////\\/}
	RUN_PATH_SED=${RUN_PATH////\\/}
	# OUTPUT_PATH_SED_TMP=${OUTPUT_PATH/\/RS_IURC\/data/\/mnt\/140}
	OUTPUT_PATH_SED_TMP1=${OUTPUT_PATH/RS_IURC/mnt}
	OUTPUT_PATH_SED_TMP=${OUTPUT_PATH_SED_TMP1/data/data140}
	OUTPUT_PATH_SED=${OUTPUT_PATH_SED_TMP////\\/}
	ROI_DIR_SED=${ROI_DIR////\\/}
	BASE_DIR_CLUSTER_SED=${BASE_DIR_CLUSTER////\\/}
}


setjsonvariables() {
	chmod 777 "${1}"
	sed -i -e "s/\(  \"${ACHAB}\.sampleID\": \"\).*/\1${SAMPLE}\",/" \
		-e "s/\(  \"${ACHAB}\.affected\": \"\).*/\1${SAMPLE}\",/" \
		-e "s/\(  \"${ACHAB}\.inputVcf\": \"\).*/\1${BASE_DIR_CLUSTER_SED}${ACHAB_TODO_DIR_SED}${SAMPLE}\/${SAMPLE}\.vcf\",/" \
		-e "s/\(  \"${ACHAB}\.diseaseFile\": \"\).*/\1${BASE_DIR_CLUSTER_SED}${ACHAB_TODO_DIR_SED}${SAMPLE}\/disease.txt\",/" \
		-e "s/\(  \"${ACHAB}\.genesOfInterest\": \"\).*/\1${GENE_FILE_SED}\",/" \
		-e "s/\(  \"${ACHAB}\.outDir\": \"\).*/\1${OUTPUT_PATH_SED}${RUN}\/MobiDL\/${DATE}\/${SAMPLE}\/${ACHAB_DIR}\/\",/" \
		"${1}"
}


modifyAchabJson() {
	ACHAB_DIR=CaptainAchab
	if ([ "${MANIFEST}" = "GenerateFastQWorkflow" ] || [ "${MANIFEST}" = "GenerateFASTQ" ]) && ([ "${JSON_SUFFIX}" == "CFScreening_hg38" ] || [ "${JSON_SUFFIX}" == "CFScreening" ]); then
		ACHAB_DIR=CaptainAchabCFScreening
	fi
	chmod -R 777 "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/"
	setjsonvariables "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/captainAchab_inputs.json"
	if [ "${DRY_RUN}" = true ];then
		info "Moving achab dir commad: cp -R ${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/ ${BASE_DIR}${ACHAB_TODO_DIR}"
	else
		if [ -f "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/${SAMPLE}.vcf" ] && [ -f "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/disease.txt" ] && [ -f "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/captainAchab_inputs.json" ];then
			# move achab input folder in todo folder for autoachab
			cp -R "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/" "${BASE_DIR}${ACHAB_TODO_DIR}"
		fi
	fi
	ACHAB_DIR=CaptainAchab
}


prepareAchab() {
	# function to prepare dirs for autoachab execution
	SUBPATH="${DATE}"
	if [[ "${PROVIDER}" = "ELEMENT" ]];then
		SUBPATH="${DATE}/${SAMPLE_ROI_TYPE}"
	fi
	if [ ! -d "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/" ];then
		mkdir -p "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/"
	fi

	# disease and genes of interest files
	debug "Manifest file: ${MANIFEST}"
	debug "BED file: ${BED}"
	unset DISEASE_FILE
	unset GENE_FILE
	unset JSON_SUFFIX
	if [ "${MANIFEST}" != "GenerateFastQWorkflow" ] && [ "${MANIFEST}" != "GenerateFASTQ" ]; then
		DISEASE_FILE=$(grep "${MANIFEST%?}" "${ROI_FILE}" | cut -d '=' -f 2 | cut -d ',' -f 4)
		# GENE_FILE=$(grep "${MANIFEST%?}" "${ROI_FILE}" | cut -d '=' -f 2 | cut -d ',' -f 3)
		GENE_FILE="${CONF_DIR}$(grep ${MANIFEST%?} ${ROI_FILE} | cut -d '=' -f 2 | cut -d ',' -f 3)"
		JSON_SUFFIX=$(grep "${MANIFEST%?}" "${ROI_FILE}" | cut -d '=' -f 2 | cut -d ',' -f 5)
	else
		debug "FASTQ workflows file: ${FASTQ_WORKFLOWS_FILE}"
		DISEASE_FILE=$(grep "${BED}" "${FASTQ_WORKFLOWS_FILE}" | cut -d ',' -f 3)
		# GENE_FILE=$(grep "${BED}" "${FASTQ_WORKFLOWS_FILE}" | cut -d ',' -f 2)
		GENE_FILE="${CONF_DIR}$(grep ${BED} ${FASTQ_WORKFLOWS_FILE} | cut -d ',' -f 2)"
		JSON_SUFFIX=$(grep "${BED}" "${FASTQ_WORKFLOWS_FILE}" | cut -d ',' -f 4)
	fi
	# deprecated david 20250818
	# we keep on filling the example conf file for merge_multisample
	# if [ -z "${FAMILY_FILE_CREATED}" ];then
	# if [ "${FAMILY_FILE_CREATED}" -eq 0 ];then
	# 	if [ -z "${FAMILY_FILE_CONFIG}" ];then
	# 		# we need to redefine the file path - can happen with MiniSeq when the fastqs are imported manually (thks LRM2)
	# 		FAMILY_FILE_CONFIG="${NAS_CHU}WDL/Families/${RUN}/Example_file_config.txt"
	# 	fi
	# 	# debug "Family config file: ${FAMILY_FILE_CONFIG}"
	# 	echo "BASE_JSON=${MOBIDL_JSON_DIR}captainAchab_inputs_${JSON_SUFFIX}.json" >> "${FAMILY_FILE_CONFIG}"
	# 	echo "DISEASE_FILE=${DISEASE_ACHAB_DIR}${DISEASE_FILE}" >> "${FAMILY_FILE_CONFIG}"
	# 	echo "GENES_OF_INTEREST=${GENE_FILE}" >> "${FAMILY_FILE_CONFIG}"
	# 	echo "ACHAB_TODO=/mnt/chu-ngs/Labos/Transversal/captainAchab/Todo/" >> "${FAMILY_FILE_CONFIG}"
	# 	echo "##### FIN ne pas modifier si analyse auto" >> "${FAMILY_FILE_CONFIG}"
	# 	echo "NUM_FAM=" >> "${FAMILY_FILE_CONFIG}"
	# 	echo "TRIO=" >> "${FAMILY_FILE_CONFIG}"
	# 	echo "# si oui" >> "${FAMILY_FILE_CONFIG}"
	# 	echo "CI=" >> "${FAMILY_FILE_CONFIG}"
	# 	echo "FATHER=" >> "${FAMILY_FILE_CONFIG}"
	# 	echo "MOTHER=" >> "${FAMILY_FILE_CONFIG}"
	# 	echo "AFFECTED=" >> "${FAMILY_FILE_CONFIG}"
	# 	echo "# si non" >> "${FAMILY_FILE_CONFIG}"
	# 	echo "HEALTHY=" >> "${FAMILY_FILE_CONFIG}"
	# 	FAMILY_FILE_CREATED=1
	# fi
	debug "Manifest: ${MANIFEST}"
	debug "JSON Suffix: ${JSON_SUFFIX}"
	# treat VCF for CF screening => restrain to given regions
	if ([ "${MANIFEST}" = "GenerateFastQWorkflow" ] || [ "${MANIFEST}" = "GenerateFASTQ" ]) && ([ "${JSON_SUFFIX}" == "CFScreening_hg38" ] || [ "${JSON_SUFFIX}" == "CFScreening" ]);then
		# https://www.biostars.org/p/69124/
		# bedtools intersect -a myfile.vcf.gz -b myref.bed -header > output.vcf
		source "${CONDA_ACTIVATE}" "${BEDTOOLS_ENV}"
		if [ "${JSON_SUFFIX}" == "CFScreening_hg38" ];then
			/usr/bin/srun -N1 -c1 -pprod -JautoDL_bedtools_CF "${BEDTOOLS}" intersect -a "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${WDL}/${SAMPLE}.vcf.gz" -b "${ROI_DIR}CF_screening_hg38.bed" -header > "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/${SAMPLE}.vcf"
		else
			/usr/bin/srun -N1 -c1 -pprod -JautoDL_bedtools_CF "${BEDTOOLS}" intersect -a "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${WDL}/${SAMPLE}.vcf.gz" -b "${ROI_DIR}CF_screening_v2.bed" -header > "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/${SAMPLE}.vcf"
		fi
		conda deactivate
		# source ${CONDA_DEACTIVATE}
	fi
	if [ ! -f "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/${SAMPLE}.vcf" ];then
		# if not CF then just copy the VCF
		cp "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${WDL}/${SAMPLE}.vcf" "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/"
	fi


	debug "Disease file: ${DISEASE_FILE}"
	debug "Genes file: ${GENE_FILE}"
	if [ -n "${DISEASE_FILE}" ] && [ -n "${GENE_FILE}" ] && [ -n "${JSON_SUFFIX}" ] && [ "${DRY_RUN}" = false ]; then
		# cp disease file in achab input dir
		cp "${DISEASE_ACHAB_DIR}${DISEASE_FILE}" "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/disease.txt"
		# cp json file in achab input dir and modify it
		cp "${MOBIDL_JSON_DIR}captainAchab_inputs_${JSON_SUFFIX}.json" "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/captainAchab_inputs.json"
		setvariables
		modifyAchabJson
		# If CF then copy original VCF from CF_panel bed file to Achab ready dir for future analysis
		if ([ "${MANIFEST}" = "GenerateFastQWorkflow" ] || [ "${MANIFEST}" = "GenerateFASTQ" ]) && ([ "${JSON_SUFFIX}" == "CFScreening_hg38" ] || [ "${JSON_SUFFIX}" == "CFScreening" ]); then
			cp "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${WDL}/${SAMPLE}.vcf" "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/"
			if [ "${JSON_SUFFIX}" == "CFScreening_hg38" ];then
				cp "${MOBIDL_JSON_DIR}captainAchab_inputs_CFPanel_hg38.json" "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/captainAchab_inputs.json"
			else
				cp "${MOBIDL_JSON_DIR}captainAchab_inputs_CFPanel.json" "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/captainAchab_inputs.json"
			fi
			ACHAB_DIR_OLD="${ACHAB_DIR}"
			ACHAB_DIR=CaptainAchabCFPanel
			setjsonvariables "${OUTPUT_PATH}${RUN}/MobiDL/${SUBPATH}/${SAMPLE}/${SAMPLE}/captainAchab_inputs.json"
			ACHAB_DIR="${ACHAB_DIR_OLD}"
		fi
	fi
}

prepareGatkCnv() {
	cp "${AUTODL_DIR}gatk_cnv.yaml" "${1}"
	# sed -i -e "s/OUTPUT_DIR:/OUTPUT_DIR:${OUTPUT_PATH_SED}${RUN}\/MobiDL\/alignment_files\/gatk_cnv/" \
	# 	-e "s/SAMPLES_PATH:/SAMPLES_PATH:${OUTPUT_PATH_SED}${RUN}\/MobiDL\/alignment_files/" \
	# 	-e "s/BED_PATH:/BED_PATH:${ROI_DIR_SED}${BED}/" \
	# 	"${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/gatk_cnv.yaml"
	sed -i -e "s/OUTPUT_DIR:/OUTPUT_DIR: ${OUTPUT_PATH_SED}${RUN}\/MobiDL\/${DATE}\/alignment_files\/${2}gatk_cnv/" \
		-e "s/SAMPLES_PATH:/SAMPLES_PATH: ${OUTPUT_PATH_SED}${RUN}\/MobiDL\/${DATE}\/alignment_files\/${2}/" \
		-e "s/BED_PATH:/BED_PATH: ${ROI_DIR_SED}${BED}/" \
		-e "s/VCF_path:/VCF_path: ${OUTPUT_PATH_SED}${RUN}\/MobiDL\/${DATE}\/MobiCNVvcfs/" \
		"${1}gatk_cnv.yaml"
}

###############		Now we'll have a look at the content of the directories ###############################


# http://moinne.com/blog/ronald/bash/list-directory-names-in-bash-shell
# --time-style is used here to ensure awk $8 will return the right thing (dir name)
RUN_PATHS="${MINISEQ_RUNS_DIR} ${MISEQ_RUNS_DIR} ${NEXTSEQ_RUNS_DIR} ${AVITI_RUNS_DIR}"
for RUN_PATH in ${RUN_PATHS}
do
	debug "RUN_PATH:${RUN_PATH}"
	# assignVariables "${RUN_PATH}"
	OUTPUT_PATH=${RUN_PATH}
	RUNS=$(ls -l --time-style="long-iso" ${RUN_PATH} | egrep '^d' | awk '{print $8}' |  egrep '^[0-9]{6}([0-9]{2})?_')
	for RUN in ${RUNS}
	do
		###### do not look at runs set to 2 in the runs.txt file
		# debug "RUN: ${RUN}"
		# debug "RUN STATE: ${RUN}:${RUN_ARRAY[${RUN}]}"
		if [ -z "${RUN_ARRAY[${RUN}]}" ] || [ "${RUN_ARRAY[${RUN}]}" -eq 0 ]; then
			assignVariables "${RUN_PATH}"
			debug "RUN: ${RUN},SAMPLESHEET:${SAMPLESHEET},MAX_DEPTH:${MAX_DEPTH},TRIGGER_FILE:${TRIGGER_FILE},TRIGGER_EXPR:${TRIGGER_EXPR}"
			# now we must look for the AnalysisLog.txt file
			# get finished run
			# if TRIGGER_EXPR is sthg OR (TRIGGER_EXPR is "" AND TRIGGER_FILE exists)
			# if TRIGGER_EXPR is "" typically TRIGGER_FILE is CopyComplete.txt which is empty
			if [[ -n $(find "${RUN_PATH}${RUN}" -mindepth 1 -maxdepth ${MAX_DEPTH} -type f -name "${TRIGGER_FILE}" -exec egrep "${TRIGGER_EXPR}" "{}" \; -quit) || (${TRIGGER_EXPR} == "" && -n $(find "${RUN_PATH}${RUN}" -mindepth 1 -maxdepth ${MAX_DEPTH} -type f -name "${TRIGGER_FILE}")) ]]; then
				# need to determine BED ROI from samplesheet
				SAMPLESHEET_PATH="${RUN_PATH}${RUN}/${SAMPLESHEET}"
				# if [ -e ${RUN_PATH}${RUN}/${SAMPLESHEET} ];then
				# debug "SAMPLESHEET PATH TESTED:${SAMPLESHEET_PATH}"
				###### if multiple sample sheets found in the run ,if [[ -f ${SAMPLESHEET_PATH} ]] does not work!!!!
				###### we need to split get the latest - david 20210307
				if [[ ! -f ${SAMPLESHEET_PATH} ]];then
					debug "FAILED SAMPLESHEET:${SAMPLESHEET_PATH}"
					SAMPLESHEET_LIST=$(ls ${SAMPLESHEET_PATH})
					if [ $? -ne 0 ];then
						# alternative LRM path
						SAMPLESHEET_PATH="${RUN_PATH}${RUN}/${RUN}/${SAMPLESHEET}"
						SAMPLESHEET_LIST=$(ls ${SAMPLESHEET_PATH})
					fi
					debug "SAMPLESHEET_LIST:${SAMPLESHEET_LIST}"
					# https://linuxhint.com/bash_split_examples/
					IFS=' '
					readarray -t SAMPLESHEET_ARRAY <<< $(ls ${SAMPLESHEET_PATH})
					debug "LAST SAMPLESHEET:${SAMPLESHEET_ARRAY[-1]}"
					SAMPLESHEET_PATH="${SAMPLESHEET_ARRAY[-1]}"
					IFS=$'\n'
				fi
				if [[ -r ${SAMPLESHEET_PATH} ]];then
					debug "SAMPLESHEET TESTED:${SAMPLESHEET_PATH}"
					info "RUN ${RUN} found for analysis"
					dos2unixIfPossible
					TREATED=0
					unset MANIFEST
					unset BED
					unset WDL
					MANIFEST=$(grep -F -e "`cat ${ROI_FILE} | cut -d '=' -f 1`" ${SAMPLESHEET_PATH} | cut -d ',' -f 2)
					if [ -n "${MANIFEST}" ];then
						BED=$(grep "${MANIFEST%?}" "${ROI_FILE}" | cut -d '=' -f 2 | cut -d ',' -f 1)
						# Multiple library types in one single run
						# Description,MultiLibraries,,,,,,,,,
						# AVITI
						# [RunValues],
						# KeyName,Value
						# Description,MultiLibraries
						MULTIPLE=$(grep "MultiLibraries" ${SAMPLESHEET_PATH} | cut -d ',' -f 2)
						debug "MANIFEST: ${MANIFEST}"
						debug "BED: ${BED}"
						debug "MULTIPLE: ${MULTIPLE}"
						if [ ${BED} == "FASTQ" ];then
							MANIFEST="GenerateFASTQ"
						fi
						debug "MANIFEST: ${MANIFEST}"
						debug "${MANIFEST%?}:${BED}"
						info "BED file to be used for analysis of run ${RUN}:${BED}"
						if [ "${BED}" = "FASTQ" ] && [ -z "${MULTIPLE}" ];then
							# GenerateFASTQ modes
							BED=$(grep -m1 'Description,' ${SAMPLESHEET_PATH} | cut -d ',' -f 2 | cut -d '#' -f 1)
							debug "BED: ${BED} - WDL: ${WDL}"
							debug "ROI_DIR: ${ROI_DIR}${BED}"
							if [ ! -f "${ROI_DIR}${BED}" ];then
								BED=''
							fi
							# WDL=$(grep -m1 'Description,' ${SAMPLESHEET_PATH} | cut -d ',' -f 2 | cut -d '#' -f 2)
							# dos2unix fails on 140 for weird permission issue
							WDL=$(cat ${SAMPLESHEET_PATH} | sed $'s/\r//' | grep -m1 'Description,' | cut -d ',' -f 2 | cut -d '#' -f 2)
							# if [ "${PROVIDER}" = "ELEMENT" ];then
							# if we need something particular for AVITI
							debug "BED: ${BED} - WDL: ${WDL}"
							# check if BED and WDL exist otherwise continue
							if [[ ! -f "${ROI_DIR}${BED}" || ! -f "${WDL_PATH}${WDL}.wdl" ]];then
								# Create a file with non treated samples:
								mkdir -p "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}"
								echo "${RUN} not treated because either the bed or workflow specified in the sample sheet does not exist - BED: ${BED}; Workflow: ${WDL}" > "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/untreated.txt"
								# Change value on array and file to done
								if [ -z "${RUN_ARRAY[${RUN}]}" ];then
									echo ${RUN}=2 >> ${RUNS_FILE}
								elif [ "${RUN_ARRAY[${RUN}]}" -eq 0 ];then
									sed -i -e "s/${RUN}=0/${RUN}=2/g" "${RUNS_FILE}"
								fi
								RUN_ARRAY[${RUN}]=2
								continue
							fi
						# elif [ -n "${MULTIPLE}" ];then
						# 	WDL=$(grep "${MANIFEST%?}" "${ROI_FILE}" | cut -d '=' -f 2 | cut -d ',' -f 2)
						# 	BED="perSampleRoi"
						# 	WDL="perSampleWorkflow"
						# else
						# 	WDL=$(grep "${MANIFEST%?}" "${ROI_FILE}" | cut -d '=' -f 2 | cut -d ',' -f 2)
						# fi
						else
							WDL=$(grep "${MANIFEST%?}" "${ROI_FILE}" | cut -d '=' -f 2 | cut -d ',' -f 2)
							if  [ -n "${MULTIPLE}" ];then
								BED="perSampleRoi"
								WDL="perSampleWorkflow"
							fi
						fi
						if [[ ${BED} =~ (hg[0-9]{2}).*\.bed$ ]];then
							GENOME=${BASH_REMATCH[1]}
						else
							GENOME=hg19
						fi
						debug "BED: ${BED} - GENOME:${GENOME}"
						if [ -n "${MANIFEST}" ] &&  [ -n "${WDL}" ] && [ -n "${BED}" ];then
							info "MobiDL workflow to be launched for run ${RUN}:${WDL}"
							if [ -z "${RUN_ARRAY[${RUN}]}" ];then
								echo ${RUN}=1 >> ${RUNS_FILE}
								RUN_ARRAY[${RUN}]=1
							elif [ "${RUN_ARRAY[${RUN}]}" -eq 0 ];then
								# Change value on array and file to running
								sed -i -e "s/${RUN}=0/${RUN}=1/g" "${RUNS_FILE}"
								RUN_ARRAY[${RUN}]=1
							fi
							if [[ "${RUN_PATH}" =~ "MINISEQ" ]];then
								OUTPUT_PATH=${MINISEQ_RUNS_DEST_DIR}
							elif [[ "${RUN_PATH}" =~ "NEXTSEQ" ]];then
								OUTPUT_PATH=${NEXTSEQ_RUNS_DEST_DIR}
							elif [[ "${RUN_PATH}" =~ "MISEQ" ]];then
								OUTPUT_PATH=${MISEQ_RUNS_DEST_DIR}
							fi
							if [ ! -d "${OUTPUT_PATH}${RUN}" ];then
								mkdir -p "${OUTPUT_PATH}${RUN}"
							fi
							# deprecated david 20250818
							# if [ ! -d "${NAS_CHU}WDL/Families/${RUN}" ];then
							# 	# create folder meant to put family files for afterwards merging
							# 	mkdir -p "${NAS_CHU}WDL/Families/${RUN}"
							# 	chmod -R 777 "${NAS_CHU}WDL/Families/${RUN}"
							# 	# create example config file for merge_multisample.sh
							# 	# RUN_PATH=/RS_IURC/data/NextSeq/nd/2021 # ou trouver le répertoire de base qui contient le run
							# 	# BASE_JSON=/usr/local/share/refData/mobidlJson/captainAchab_inputs_ND.json # json pour achab
							# 	# DISEASE_FILE=/usr/local/share/refData/disease_achab/disease_ND.txt # fichier disease contenant les codes HPO de la famille
							# 	# GENES_OF_INTEREST=/RS_IURC/data/MobiDL/${DATE}/captainAchab/Example/nd.txt # gènes à mettre en avant dans achab
							# 	# ACHAB_TODO=/RS_IURC/data/MobiDL/${DATE}/captainAchab/
							# 	# RUN_ID=210924_NB501631_0419_AH5LHNBGXK
							# 	# NUM_FAM=
							# 	# TRIO=
							# 	# # si oui
							# 	# CI=
							# 	# FATHER=
							# 	# MOTHER=
							# 	# AFFECTED=
							# 	# # si non
							# 	# HEALTHY=
							# 	FAMILY_FILE_CONFIG="${NAS_CHU}WDL/Families/${RUN}/Example_file_config.txt"
							# 	touch "${FAMILY_FILE_CONFIG}"
							# 	chmod -R 777 "${NAS_CHU}WDL/Families/${RUN}"
							# 	echo "##### DEBUT ne pas modifier les champs ci-dessous si analyse auto" > "${FAMILY_FILE_CONFIG}"
							# 	echo "RUN_PATH=${OUTPUT_PATH}" >> "${FAMILY_FILE_CONFIG}"
							# 	echo "RUN_ID=${RUN}" >> "${FAMILY_FILE_CONFIG}"
							# 	FAMILY_FILE_CREATED=0
							# fi
							if [ "${DRY_RUN}" = false ];then
								if [ ! -d "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}" ];then
									mkdir -p "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}"
								fi
								# if [ ! -d "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVtsvs/" ];then
								# 	mkdir -p "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVtsvs"
								# fi
								# if [ ! -d "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVvcfs/" ];then
								# 	mkdir -p "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVvcfs"
								# fi
								# get Illumina InterOp
								if [ ! -d "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/interop/" ] && [ "${PROVIDER}" = "ILLUMINA" ];then
									mkdir -p "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/interop"
								fi
								if  [ "${PROVIDER}" = "ILLUMINA" ];then
									# for some reason SRUN should be called without quotes
									debug "/usr/bin/srun -N1 -c1 -pprod -JautoDL_interops ${ILLUMINAINTEROP}summary ${RUN_PATH}${RUN}  --csv=1 > ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/interop/summary"
									/usr/bin/srun -N1 -c1 -pprod -JautoDL_interops "${ILLUMINAINTEROP}summary" "${RUN_PATH}${RUN}"  --csv=1 > "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/interop/summary"
									debug "/usr/bin/srun -N1 -c1 -pprod -JautoDL_interopi ${ILLUMINAINTEROP}index-summary ${RUN_PATH}${RUN}  --csv=1 > ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/interop/index-summary"
									/usr/bin/srun -N1 -c1 -pprod -JautoDL_interopi "${ILLUMINAINTEROP}index-summary" "${RUN_PATH}${RUN}"  --csv=1 > "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/interop/index-summary"
								fi
							fi
							# now we have to identifiy samples in fastqdir (identify fastqdir,which may change depending on the Illumina workflow) then sed on json model, then launch wdl workflow
							declare -A SAMPLES
							# MEMO: If FASTQ is a symlink, 'du -L' to follow it and get original FASTQ size (and not symlink size)
							# we exclude symlinks for the time
							if [[ "${PROVIDER}" = "ILLUMINA" ]];then
								FASTQS_WITH_SIZE=$(find "${RUN_PATH}${RUN}" -mindepth 1 -maxdepth 5 -type f ! -type l -name *.fastq.gz | grep -v 'Undetermined' | sort | xargs du -bL)
							elif [[ "${PROVIDER}" = "ELEMENT" ]];then
								FASTQS_WITH_SIZE=$(find "${RUN_PATH}${RUN}" -mindepth 1 -maxdepth 2 -type f -name *.fastq.gz | grep -v 'PhiX' | grep -v 'Unassigned' | sort | xargs du -bL)
							fi
							# debug "FASTQS_WITH_SIZE: ${FASTQS_WITH_SIZE}"
							CUTOFF_SIZE_FQ=204800  # FASTQ.GZ below this size (in bytes) are excluded (=~ 200 Ko)
							FASTQS=$(echo "$FASTQS_WITH_SIZE" | awk -v cutoff_fq_size=$CUTOFF_SIZE_FQ -F"\t" '$1>cutoff_fq_size {print $2}')
							if [ "${DRY_RUN}" = false ];then
								# Create a file with excluded FASTQ:
								echo "$FASTQS_WITH_SIZE" | awk -v cutoff_fq_size=$CUTOFF_SIZE_FQ -F"\t" '$1<=cutoff_fq_size {print $2}' > "{OUTPUT_PATH}${RUN}/MobiDL/${DATE}/excluded_below_${CUTOFF_SIZE_FQ}bytes.txt"
							fi
							for FASTQ in ${FASTQS[@]};do
								FILENAME=$(basename "${FASTQ}" ".fastq.gz")
								debug "SAMPLE FILENAME:${FILENAME}"
								# REGEXP='^([a-zA-Z0-9-]+)_(.+)$'
								REGEXP='^([a-zA-Z0-9_-]+)_(S[0-9]+_L?[0-9]*_*R[0-9]_[0-9]{3})$'
								if [ "${PROVIDER}" = "ELEMENT" ];then
									# REGEXP='^([a-zA-Z0-9_-]+)_(R[12])\.?([a-zA-Z0-9_-]*)$'
									REGEXP='^([a-zA-Z0-9_-]+)_(R[12])(\.([a-zA-Z0-9_-]+))?$'
									# project => BASH_REMATCH[4]
								fi
								# REGEXP='^([a-zA-Z0-9_-]+)_(S?[0-9]*_?L?[0-9]*_?R[0-9]_?[0-9]*)$'
								if [[ ${FILENAME} =~ ${REGEXP} ]];then
									debug "BASH_REMATCH[1]: ${BASH_REMATCH[1]}"
									if [ ${SAMPLES[${BASH_REMATCH[1]}]} ];then
										if [[ "${PROVIDER}" = "ILLUMINA" ]];then
											SAMPLES[${BASH_REMATCH[1]}]="${SAMPLES[${BASH_REMATCH[1]}]};${BASH_REMATCH[2]};${FASTQ%/*}"
											debug "SAMPLE:${SAMPLES[${BASH_REMATCH[1]}]};${BASH_REMATCH[2]};${FASTQ%/*}"
										elif [[ "${PROVIDER}" = "ELEMENT" ]];then
											# we have a symlink but we want real path
											REAL_PATH=$(realpath "${FASTQ}")
											debug "REAL_PATH: ${REAL_PATH}"
											if [ "${BASH_REMATCH[4]}" = "DefaultProject" ];then
												SAMPLES[${BASH_REMATCH[1]}]="${SAMPLES[${BASH_REMATCH[1]}]};${BASH_REMATCH[2]};${REAL_PATH%/*}"
												# SAMPLES[${BASH_REMATCH[1]}]="${SAMPLES[${BASH_REMATCH[1]}]};${BASH_REMATCH[2]};${FASTQ%/*}"
											else
												SAMPLES[${BASH_REMATCH[1]}]="${SAMPLES[${BASH_REMATCH[1]}]};${BASH_REMATCH[2]};${REAL_PATH%/*};${BASH_REMATCH[4]}"
												# SAMPLES[${BASH_REMATCH[1]}]="${SAMPLES[${BASH_REMATCH[1]}]};${BASH_REMATCH[2]};${FASTQ%/*};${BASH_REMATCH[4]}"
											fi
											debug "SAMPLE:${SAMPLES[${BASH_REMATCH[1]}]};${BASH_REMATCH[2]};${REAL_PATH%/*}"
										fi
									elif [ $(grep -c "${BASH_REMATCH[1]}" "${SAMPLESHEET_PATH}") -eq 1 ];then
										SAMPLES[${BASH_REMATCH[1]}]=${BASH_REMATCH[2]}
									else
										echo "${BASH_REMATCH[1]} not treated because this sample is absent from the sample sheet" > "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/untreated.txt"
									fi
								else
									warning "SAMPLE DOES NOT MATCH REGEXP ${REGEXP}: ${FILENAME} ${RUN_PATH}${RUN}"
								fi
							done
							# ifcnv/gatk_cnv specific feature: create a folder with symbolic links to the alignment files
							# mkdir -p "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/"
							debug "Remove existing ${AUTODL_DIR}/${RUN}"
							rm -rf "${AUTODL_DIR}/${RUN}"
							mkdir "${AUTODL_DIR}/${RUN}"
							debug "1st loop on SAMPLES"
							for SAMPLE in ${!SAMPLES[@]};do
								if [[ ${MULTIPLE} != '' ]];then
									# Multiple library types in one single run
									# returns ",roi1.bed#panelCapture" => bed#wdl...
									# NEXTSEQ
									DESCRIPTION_FIELD=11
									if [[ "${RUN_PATH}" =~ "MISEQ" ]];then
										DESCRIPTION_FIELD=10
									elif [[ "${RUN_PATH}" =~ "MINISEQ" ]];then
										DESCRIPTION_FIELD=3
									elif [[ "${PROVIDER}" = "ELEMENT" ]];then
										DESCRIPTION_FIELD=5
									fi
									BED=$(grep "${SAMPLE}," "${SAMPLESHEET_PATH}" | cut -d "," -f ${DESCRIPTION_FIELD} | cut -d "#" -f 1)
									NEW_WDL=$(cat ${SAMPLESHEET_PATH} | sed $'s/\r//' | grep "${SAMPLE}," | cut -d "," -f ${DESCRIPTION_FIELD} | cut -d "#" -f 2)

									# check if BED and WDL exist otherwise continue
									if [[ ! -f "${ROI_DIR}${BED}" || ! -f "${WDL_PATH}${NEW_WDL}.wdl" ]];then
										if [ "${DRY_RUN}" = false ];then
											# Create a file with non treated FASTQ:
											echo "${SAMPLE} not treated because either the bed or workflow specified in the sample sheet does not exist - BED: ${BED}; Workflow: ${NEW_WDL}" >> "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/untreated_samples.txt"
										fi
										# remove from SAMPLES[]
										unset SAMPLES[${SAMPLE}]
										continue
									elif [ -f "${WDL_PATH}${NEW_WDL}.wdl" ];then
										WDL="${NEW_WDL}"
									fi
									# exit 0
									# check custom output PATH
									# info "MANIFEST: ${MANIFEST}"
									# if [ "${MANIFEST}" = "GenerateFastQWorkflow" ] || [ "${MANIFEST}" = "GenerateFASTQ" ];then
									# 	NEW_OUTPUT_PATH=$(grep "${BED}" "${FASTQ_WORKFLOWS_FILE}" | cut -d ',' -f 5)
									# 	if [ -n "${NEW_OUTPUT_PATH}" ];then
									# 		rm -rf "${OUTPUT_PATH}${RUN}"
									# 		info "Defining new output path for run ${RUN}: ${NEW_OUTPUT_PATH}"
									# 		OUTPUT_PATH=${NEW_OUTPUT_PATH}
									# 		mkdir -p "${OUTPUT_PATH}${RUN}"
									# 	else
									# 		info "NEW_OUTPUT_PATH: ${NEW_OUTPUT_PATH} - MANIFEST: ${MANIFEST} - BED: ${BED} - FASTQ_WORKFLOWS_FILE: ${FASTQ_WORKFLOWS_FILE}"
									# 	fi
									# fi
								fi
								modifyJson
							done
							# Exit loop, gather jsonS and run metaPipe:
							gatherJsonsAndLaunch
							# Then loop again (to prepare Achab + get ROI_TYPES for MobiCNV):
							# WARN: Some steps are done twice -> not very efficient
							debug "2nd loop on SAMPLES"
							declare -A ROI_TYPES
							for SAMPLE in ${!SAMPLES[@]};do
								if [[ ${MULTIPLE} != '' ]];then
									# Multiple library types in one single run
									# returns ",roi1.bed#panelCapture" => bed#wdl...
									# NEXTSEQ
									DESCRIPTION_FIELD=11
									if [[ "${RUN_PATH}" =~ "MISEQ" ]];then
										DESCRIPTION_FIELD=10
									elif [[ "${RUN_PATH}" =~ "MINISEQ" ]];then
										DESCRIPTION_FIELD=3
									elif [[ "${PROVIDER}" = "ELEMENT" ]];then
										DESCRIPTION_FIELD=5
									fi
									BED=$(grep "${SAMPLE}," "${SAMPLESHEET_PATH}" | cut -d "," -f ${DESCRIPTION_FIELD} | cut -d "#" -f 1)
									WDL=$(cat ${SAMPLESHEET_PATH} | sed $'s/\r//' | grep "${SAMPLE}," | cut -d "," -f ${DESCRIPTION_FIELD} | cut -d "#" -f 2)
									SAMPLE_ROI_TYPE=$(grep "${SAMPLE}," "${SAMPLESHEET_PATH}" | cut -d "," -f ${DESCRIPTION_FIELD} | cut -d "#" -f 1 | cut -d "." -f 1)
									info "MULTIPLE SAMPLE:${SAMPLE} - BED:${BED} - WDL:${WDL} - SAMPLE_ROI_TYPE:${SAMPLE_ROI_TYPE}"
									# AVITI replace SAMPLE_ROI_TYPE with Project
									if [[ "${PROVIDER}" = "ELEMENT" && -n "${PROJECT}" ]];then
										# SAMPLE_ROI_TYPE=$(echo "${SAMPLES[${SAMPLE}]}" | cut -d ';' -f 4)
										SAMPLE_ROI_TYPE=${PROJECT}
									fi
									# put ROI in a hash table with ROI as keys then loop on the hash and launch mobiCNV and multiqc
									if [ -n "${SAMPLE_ROI_TYPE}" ]; then
										ROI_TYPES["${SAMPLE_ROI_TYPE}"]=1
										# if [ "${DRY_RUN}" = false ];then
										# 	if [ ! -d "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVtsvs/${SAMPLE_ROI_TYPE}/" ];then
										# 		mkdir -p "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVtsvs/${SAMPLE_ROI_TYPE}/"
										# 	fi
										# 	if [ ! -d "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVvcfs/${SAMPLE_ROI_TYPE}/" ];then
										# 		mkdir -p "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVvcfs/${SAMPLE_ROI_TYPE}/"
										# 	fi
										# fi
									fi
								fi
								if [ "${DRY_RUN}" = false ];then
									prepareAchab
								fi
								TREATED=1
								# ifcnv/gatk_cnv specific feature: create a folder with symbolic links to the alignment files
								# if [[ ${MULTIPLE} != '' ]];then
								# 	if [ ! -d "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/${SAMPLE_ROI_TYPE}/" ];then
								# 		mkdir -p "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/${SAMPLE_ROI_TYPE}/"
								# 	fi
								# 	ln -s "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE}/${WDL}/${SAMPLE}.crumble.cram" "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/${SAMPLE_ROI_TYPE}/${SAMPLE}.crumble.cram"
								# 	ln -s "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE}/${WDL}/${SAMPLE}.crumble.cram.crai" "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/${SAMPLE_ROI_TYPE}/${SAMPLE}.crumble.cram.crai"
								# else
								# 	ln -s "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE}/${WDL}/${SAMPLE}.crumble.cram" "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/${SAMPLE}.crumble.cram"
								# 	ln -s "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE}/${WDL}/${SAMPLE}.crumble.cram.crai" "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/${SAMPLE}.crumble.cram.crai"
								# fi
								# LED specific block
								if [ "${DRY_RUN}" = false ];then
									MOBICNVVCF_DIR="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVvcfs"
									MOBICNVTSV_DIR="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVtsvs"
									SAMPLE_WDL_DIR="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE}/${WDL}"
									if [ -n "${SAMPLE_ROI_TYPE}" ];then
										if [[ "${PROVIDER}" = "ILLUMINA" ]];then
											MOBICNVVCF_DIR="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVvcfs/${SAMPLE_ROI_TYPE}"
											MOBICNVTSV_DIR="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVtsvs/${SAMPLE_ROI_TYPE}"
										elif [[ "${PROVIDER}" = "ELEMENT" ]];then
											MOBICNVVCF_DIR="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE_ROI_TYPE}/MobiCNVvcfs"
											MOBICNVTSV_DIR="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE_ROI_TYPE}/MobiCNVtsvs"
											SAMPLE_WDL_DIR="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE_ROI_TYPE}/${SAMPLE}/${WDL}"
										fi
									fi
									if [ ! -d "${MOBICNVTSV_DIR}/" ];then
										mkdir -p "${MOBICNVTSV_DIR}/"
									fi
									if [ ! -d "${MOBICNVVCF_DIR}/" ];then
										mkdir -p "${MOBICNVVCF_DIR}/"
									fi
									# LED_FILE="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVvcfs/${SAMPLE}.txt"
									LED_FILE="${MOBICNVVCF_DIR}/${SAMPLE}.txt"
									# if [ -n "${SAMPLE_ROI_TYPE}" ];then
									# 	LED_FILE="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVvcfs/${SAMPLE_ROI_TYPE}/${SAMPLE}.txt"
									# fi
									DISEASE=''
									TEAM=''
									EXPERIMENT=''
									if [[ "${SAMPLE}" =~ ^[Aa][0-9]+$ ]];then
										DISEASE="ATAXIA"
										TEAM="ATAXIA"
										EXPERIMENT="trusight_one_exp"
									elif [[ "${SAMPLE}" =~ ^[Hh][Oo][Rr]-[0-9]+$ ]];then
										DISEASE="DSD"
										TEAM="DSD"
										EXPERIMENT="twist_custom"
									elif [[ "${SAMPLE}" =~ ^[Cc][SsAa][GgDd][0-9]+$ ]];then
										DISEASE="CF"
										TEAM="MUCO"
										EXPERIMENT="agilent_custom"
									elif [[ "${SAMPLE}" =~ ^[DdIi][0-9]+-.*$ ]];then
										DISEASE="MYOPATHY"
										TEAM="NEUROMUSCULAR"
										EXPERIMENT="nimblegen_custom"
									elif [[ "${SAMPLE}" =~ ^[Ss][Uu][0-9]+$ ]];then
										DISEASE="DFNB"
										TEAM="SENSORINEURAL"
										EXPERIMENT="twist_custom"
									elif [[ "${SAMPLE}" =~ ^[Rr][0-9]+$ ]];then
										DISEASE="RP"
										TEAM="SENSORINEURAL"
										EXPERIMENT="twist_custom"
									fi
									touch "${LED_FILE}"
									echo "#patient_id	less than 15 chars" >> "${LED_FILE}"
									echo "#family_id	less than 10 chars" >> "${LED_FILE}"
									echo "#gender		m/f" >> "${LED_FILE}"
									echo "#disease_name	RP,DFNB,DFNA,USH,ATAXIA,MYOPATHY,HEALTHY,CF,CF-RD,CBAVD,OTHER,AUTISM,DSD,HYPOSP" >> "${LED_FILE}"
									echo "#team_name	SENSORINEURAL,NEUROMUSCULAR,ATAXIA,MUCO,DSD" >> "${LED_FILE}"
									echo "#visibility	0/1" >> "${LED_FILE}"
									echo "#experiment	trusight_one,exome_ss_v6,exome_ss_v5,truseq_rapid_exome,cftr_complete,medexome,nimblegen_inherited_disease,trusight_one_exp,nimblegen_custom,agilent_custom", >> "${LED_FILE}"
									echo "patient_id:${SAMPLE}" >> "${LED_FILE}"
									echo "family_id:" >> "${LED_FILE}"
									echo "gender:" >> "${LED_FILE}"
									echo "disease_name:${DISEASE}" >> "${LED_FILE}"
									echo "team_name:${TEAM}" >> "${LED_FILE}"
									echo "visibility:1" >> "${LED_FILE}"
									echo "experiment_type:${EXPERIMENT}" >> "${LED_FILE}"
									# end led specific block
									# if [[ "${PROVIDER}" = "ILLUMINA" ]];then
									# 	/usr/bin/srun -N1 -c1 -pprod -JautoDL_cp_vcf cp "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE}/${WDL}/${SAMPLE}.vcf" "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVvcfs/${SAMPLE_ROI_TYPE}"
									# 	/usr/bin/srun -N1 -c1 -pprod -JautoDL_cp_cov cp "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE}/${WDL}/coverage/${SAMPLE}_coverage.tsv" "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVtsvs/${SAMPLE_ROI_TYPE}"
									# elif [[ "${PROVIDER}" = "ELEMENT" ]];then
									# 	/usr/bin/srun -N1 -c1 -pprod -JautoDL_cp_vcf cp "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE_ROI_TYPE}/${SAMPLE}/${WDL}/${SAMPLE}.vcf" "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE_ROI_TYPE}/MobiCNVvcfs/${SAMPLE_ROI_TYPE}"
									# 	/usr/bin/srun -N1 -c1 -pprod -JautoDL_cp_cov cp "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE_ROI_TYPE}/${SAMPLE}/${WDL}/coverage/${SAMPLE}_coverage.tsv" "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}$/{SAMPLE_ROI_TYPE}/MobiCNVtsvs/${SAMPLE_ROI_TYPE}"
									# fi
									# MOBICNVVCF_DIR="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVvcfs"
									# MOBICNVTSV_DIR="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVtsvs"
									# if [ -n "${SAMPLE_ROI_TYPE}" ];then
									# 	if [[ "${PROVIDER}" = "ILLUMINA" ]];then
									# 		MOBICNVVCF_DIR="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVvcfs/${SAMPLE_ROI_TYPE}"
									# 		MOBICNVTSV_DIR="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVtsvs/${SAMPLE_ROI_TYPE}"
									# 	elif [[ "${PROVIDER}" = "ELEMENT" ]];then
									# 		MOBICNVVCF_DIR="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE_ROI_TYPE}/MobiCNVvcfs"
									# 		MOBICNVTSV_DIR="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE_ROI_TYPE}/MobiCNVtsvs"
									# 	fi
									# fi
									# if [ ! -d "${MOBICNVTSV_DIR}/" ];then
									# 	mkdir -p "${MOBICNVTSV_DIR}/"
									# fi
									# if [ ! -d "${MOBICNVVCF_DIR}/" ];then
									# 	mkdir -p "${MOBICNVVCF_DIR}/"
									# fi

									/usr/bin/srun -N1 -c1 -pprod -JautoDL_cp_vcf cp "${SAMPLE_WDL_DIR}/${SAMPLE}.vcf" "${MOBICNVVCF_DIR}"
									# /usr/bin/srun -N1 -c1 -pprod -JautoDL_cp_vcf cp "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE}/${WDL}/${SAMPLE}.vcf" "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVtsvs/${SAMPLE_ROI_TYPE}"
									/usr/bin/srun -N1 -c1 -pprod -JautoDL_cp_cov cp "${SAMPLE_WDL_DIR}/coverage/${SAMPLE}_coverage.tsv" "${MOBICNVTSV_DIR}"
									# /usr/bin/srun -N1 -c1 -pprod -JautoDL_cp_cov cp "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${SAMPLE}/${WDL}/coverage/${SAMPLE}_coverage.tsv" "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVtsvs/${SAMPLE_ROI_TYPE}"
									debug "SAMPLE(SUFFIXES):${SAMPLE}(${SAMPLES[${SAMPLE}]})"
								fi
							done
							unset SAMPLES
						fi
						if [ "${TREATED}" -eq 1 ];then
							# MobiCNV && multiqc
							# no VCF anymore fo mobicnv: -v ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVvcfs/
							if [ -n "${MULTIPLE}" ];then
								# get folders in ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVvcfs/ and loop on it and launch mobicnv
								# for LIBRARY in "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVvcfs/*"
								for LIBRARY in ${!ROI_TYPES[@]}
								do
									MOBICNVTSV_PATH="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVtsvs/${LIBRARY}/"
									PROJECT_PATH="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/"
									if [[ "${PROVIDER}" = "ELEMENT" ]];then
										MOBICNVTSV_PATH="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${LIBRARY}/MobiCNVtsvs/"
										PROJECT_PATH="${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${LIBRARY}/"
									fi
									if [ "${DRY_RUN}" = true ];then
										info "Launching MobiCNV on run ${RUN}, library ${LIBRARY}"
										info "MobiCNV launch command: /usr/bin/srun -N1 -c1 -pprod -JautoDL_mobicnv ${PYTHON} ${MOBICNV} -i ${MOBICNVTSV_PATH} -t tsv -o ${PROJECT_PATH}${RUN}_${LIBRARY}_MobiCNV.xlsx"
									else
										# check if at least 3 samples  / library => count number of tsv file in the folder
										NUMBER_OF_SAMPLE=$(ls -l ${MOBICNVTSV_PATH}*.tsv | wc -l)
										if [ ${NUMBER_OF_SAMPLE} -gt 2 ];then
											info "Launching MobiCNV on run ${RUN}, library ${LIBRARY}"
											source "${CONDA_ACTIVATE}" "${MOBICNV_ENV}"
											/usr/bin/srun -N1 -c1 -pprod -JautoDL_mobicnv "${PYTHON}" "${MOBICNV}" -i "${MOBICNVTSV_PATH}" -t tsv -o "${PROJECT_PATH}${RUN}_${LIBRARY}_MobiCNV.xlsx"
											debug "/usr/bin/srun -N1 -c1 -pprod -JautoDL_mobicnv ${PYTHON} ${MOBICNV} -i ${MOBICNVTSV_PATH} -t tsv  -o ${PROJECT_PATH}${RUN}_${LIBRARY}_MobiCNV.xlsx"
											conda deactivate
											# here prepare and launch gatk_cnv
											# sed a gatk_cnv.yaml located in ${AUTODL_DIR} file with proper paths, loads the conda env and launches snakemake
											# removed 20220420 as does not work as expected
											# prepareGatkCnv "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/${LIBRARY}/" "${LIBRARY}\/"
											# ${SNAKEMAKE} --cluster "sbatch -p prod -N 1 -J gatk-cnv --output=/dev/null" --jobs 1 -s ${GATK_SNAKEFILE} -j 8 --use-conda --configfile "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/${LIBRARY}/gatk_cnv.yaml" --resources cnv_caller=4
											# info "${SNAKEMAKE} --cluster "sbatch -p prod -N 1 -J gatk-cnv --output=/dev/null" --jobs 1 -s ${GATK_SNAKEFILE} -j 8 --use-conda --configfile ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/${LIBRARY}/gatk_cnv.yaml --resources cnv_caller=4"
											if [[ "${PROVIDER}" = "ELEMENT" ]];then
												info "Launching MultiQC on run ${RUN}/${LIBRARY}"
												source "${CONDA_ACTIVATE}" "${MULTIQC_ENV}"
												if [ "${DRY_RUN}" = true ];then
													info "MultiQC launch command: /usr/bin/srun -N1 -c1 -pprod -JautoDL_multiqc ${MULTIQC} ${PROJECT_PATH} -n ${RUN}_multiqc.html -o ${PROJECT_PATH}"
													info "MultiQC modif command: /usr/bin/srun -N1 -c1 -pprod -JautoDL_perl_multiqc ${PERL} -pi.bak -e 's/NaN/null/g' ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${RUN}/${LIBRARY}/${LIBRARY}_multiqc_data/multiqc_data.json"
												else
													/usr/bin/srun -N1 -c1 -pprod -JautoDL_multiqc "${MULTIQC}" "${PROJECT_PATH}" -n "${LIBRARY}_multiqc.html" -o "${PROJECT_PATH}"
													debug "/usr/bin/srun -N1 -c1 -pprod -JautoDL_multiqc ${MULTIQC} ${PROJECT_PATH} -n ${LIBRARY}_multiqc.html -o ${PROJECT_PATH}"
													/usr/bin/srun -N1 -c1 -pprod -JautoDL_perl_multiqc "${PERL}" -pi.bak -e 's/NaN/null/g' "${PROJECT_PATH}${LIBRARY}_multiqc_data/multiqc_data.json"
												fi
												conda deactivate
											fi
										else
											info "Not enough samples for Library ${LIBRARY} to launch MobiCNV (${NUMBER_OF_SAMPLE} samples)"
										fi
									fi
								done
							elif [ "${WDL}" != "amplicon" ];then
								info "Launching MobiCNV on run ${RUN}"
								source "${CONDA_ACTIVATE}" "${MOBICNV_ENV}"
								if [ "${DRY_RUN}" = true ];then
									info "MobiCNV launch command: /usr/bin/srun -N1 -c1 -pprod -JautoDL_mobicnv ${PYTHON} ${MOBICNV} -i ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVtsvs/ -t tsv -o ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${RUN}_MobiCNV.xlsx"
								else
									/usr/bin/srun -N1 -c1 -pprod -JautoDL_mobicnv "${PYTHON}" "${MOBICNV}" -i "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVtsvs/" -t tsv -o "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${RUN}_MobiCNV.xlsx"
									debug "/usr/bin/srun -N1 -c1 -pprod -JautoDL_mobicnv ${PYTHON} ${MOBICNV} -i ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/MobiCNVtsvs/ -t tsv  -o ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${RUN}_MobiCNV.xlsx"
								fi
								conda deactivate
								# here prepare and launch gatk_cnv
								# sed a gatk_cnv.yaml located in ${AUTODL_DIR} file with proper paths, loads the conda env and launches snakemake
								# removed 20220420 as does not work as expected
								# prepareGatkCnv "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/" ""
								# ${SNAKEMAKE} --cluster "sbatch -p prod -N 1 -J gatk-cnv --output=/dev/null" --jobs 1 -s ${GATK_SNAKEFILE} -j 8 --use-conda --configfile "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/gatk_cnv.yaml" --resources cnv_caller=4
								# debug "${SNAKEMAKE} --cluster "sbatch -p prod -N 1 -J gatk-cnv --output=/dev/null" --jobs 1 -s ${GATK_SNAKEFILE} -j 8 --use-conda --configfile ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/gatk_cnv.yaml --resources cnv_caller=4"
								# ifCNV
								# remove (temporarily? david 20240802)
								# BED_FILE_NAME=$(basename ${BED} .bed)
								# BED_IFCNV="${ROI_DIR}${BED_FILE_NAME}_ifcnv.bed"
								# if [ -e ${BED_IFCNV} ];then
								# 	info "Activating env ${IFCNV_ENV} and launching ifCNV on run ${RUN}"
								# 	# activates conda									
								# 	# eval "$(${CONDA} 'shell.bash' 'hook')"
								# 	# https://unix.stackexchange.com/questions/454957/cron-job-to-run-under-conda-virtual-environment/572951#572951
								# 	# activates ifcnv env
								# 	source "${CONDA_ACTIVATE}" "${IFCNV_ENV}"
								# 	# "${CONDA}" activate "${IFCNV_ENV}" 
								# 	debug "/usr/bin/srun -N1 -c1 -pprod -JautoDL_ifcnv ${IFCNV} -i ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/ -b ${BED_IFCNV} -o ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/ifCNV/ -r ${RUN} -sT 0 -ct 0.01"
								# 	"/usr/bin/srun -N1 -c1 -pprod -J"autoDL_ifcnv "${IFCNV}" -i "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/" -b "${BED_IFCNV}" -o "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/alignment_files/ifCNV/" -r "${RUN}" -sT 0 -ct 0.01
								# 	# deactivates conda env
								# 	conda deactivate
								# fi
							fi
							if [[ "${PROVIDER}" = "ILLUMINA" ]];then
								info "Launching MultiQC on run ${RUN}"
								source "${CONDA_ACTIVATE}" "${MULTIQC_ENV}"
								if [ "${DRY_RUN}" = true ];then
									info "MultiQC launch command: /usr/bin/srun -N1 -c1 -pprod -JautoDL_multiqc ${MULTIQC} ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/ -n ${RUN}_multiqc.html -o ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/"
									info "MultiQC modif command: /usr/bin/srun -N1 -c1 -pprod -JautoDL_perl_multiqc ${PERL} -pi.bak -e 's/NaN/null/g' ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${RUN}_multiqc_data/multiqc_data.json"
								else
									/usr/bin/srun -N1 -c1 -pprod -JautoDL_multiqc "${MULTIQC}" "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/" -n "${RUN}_multiqc.html" -o "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/"
									debug "/usr/bin/srun -N1 -c1 -pprod -JautoDL_multiqc ${MULTIQC} ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/ -n ${RUN}_multiqc.html -o ${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/"
									/usr/bin/srun -N1 -c1 -pprod -JautoDL_perl_multiqc "${PERL}" -pi.bak -e 's/NaN/null/g' "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${RUN}_multiqc_data/multiqc_data.json"
								fi
								conda deactivate
							fi
							# may not be needed anymore with NFS share TEST ME
							if [ "${DRY_RUN}" = false ];then
								chmod -R 777 "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/"
							fi
							sed -i -e "s/${RUN}=1/${RUN}=2/" "${RUNS_FILE}"
							RUN_ARRAY[${RUN}]=2
							info "RUN ${RUN} treated"
							if [ "${DRY_RUN}" = false ];then
								touch "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${WDL}Complete.txt"
								echo "[`date +'%Y-%m-%d %H:%M:%S'`] [INFO] - autoDL version : ${VERSION} - MobiDL ${WDL} complete for run ${RUN}" > "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${WDL}Complete.txt"
							fi
							# echo "[`date +'%Y-%m-%d %H:%M:%S'`] [INFO] - autoDL version : ${VERSION} - MobiDL ${WDL} complete for run ${RUN}" > "${OUTPUT_PATH}${RUN}/MobiDL/${DATE}/${WDL}Complete.txt"
							#Temp outDir already removed by 'workflowPostTreatment':
							# chmod -R 777 "${TMP_OUTPUT_DIR2}"
							# rm -r "${TMP_OUTPUT_DIR2}"
						else
							info "Nothing done for run ${RUN_PATH}${RUN}"
							if [ -z "${RUN_ARRAY[${RUN}]}" ];then
								echo ${RUN}=2 >> ${RUNS_FILE}
								RUN_ARRAY[${RUN}]=2
							elif [ "${RUN_ARRAY[${RUN}]}" -eq 0 ];then
								# Change value on array and file to done
								sed -i -e "s/${RUN}=0/${RUN}=2/g" "${RUNS_FILE}"
								RUN_ARRAY[${RUN}]=2
							fi
						fi
					else
						info "Nothing done for ${RUN}"
						if [ -z "${RUN_ARRAY[${RUN}]}" ];then
							echo ${RUN}=2 >> ${RUNS_FILE}
							RUN_ARRAY[${RUN}]=2
						elif [ "${RUN_ARRAY[${RUN}]}" -eq 0 ];then
							# Change value on array and file to done
							sed -i -e "s/${RUN}=0/${RUN}=2/g" "${RUNS_FILE}"
							RUN_ARRAY[${RUN}]=2
						fi
					fi
				fi
			fi
		fi
	done
done
