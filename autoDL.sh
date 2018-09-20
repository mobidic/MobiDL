#!/bin/bash

###########################################################################
#########							###########
#########		AutoDL				###########
######### @uthor : D Baux	david.baux<at>inserm.fr		###########
######### Date : 14/09/2018					###########
#########							###########
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
VERSION=1.0
USAGE="
Program: AutoDL
Version: ${VERSION}
Contact: Baux David <david.baux@inserm.fr>

Usage: This script is meant to be croned
	Should be executed once per 10 minutes

"


if [ $# -ne 0 ]; then
	echo "${USAGE}"
	echo "Error Message : Arguments provided"
	echo ""
	exit 1
fi

RED='\033[0;31m'
LIGHTRED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
# -- Script log 

VERBOSITY=4
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
		echoerr "[`date +'%Y-%m-%d %H:%M:%S'`] $2 - autoDL version : ${VERSION} - $3"
	fi
}


###############		Get options from conf file			##################################

CONFIG_FILE='./autoDL.conf'

#we check params against regexp

UNKNOWN=$(cat  ${CONFIG_FILE} | grep -Evi "^(#.*|[A-Z0-9_]*=[a-z0-9_ \"\.\/\$\{\}\*]*)$")
if [ -n "${UNKNOWN}" ]; then
	error "Error in config file. Not allowed lines:"
	error ${UNKNOWN}
	exit 1
fi

source ${CONFIG_FILE}

###############		1st check whether another instance of the script is running	##################

RESULT=$(ps x | grep -v grep | grep -c ${SERVICE})
debug "${SERVICE} pids: $(ps x | grep -v grep |grep -c ${SERVICE})"

if [ "${RESULT}" -gt 3 ]; then
	exit 0
fi

###############		Get run info file				 ##################################

# the file contains the run id and a code
# 0 => not treated => to do - used to retreat a run in case ex of error
# 1 => nenufaar is running -in case the security above does not work
# 2 => run treated - ignore directory
# the file is stored in an array and modified by the script

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

choosePipeline() {
	return $(${GREP} -F "${SAMPLE_SHEET}" "${SAMPLE_SHEET_DB}" | cut -d '=' -f 2)	
}



MAX_DEPTH=''
TRIGGER_FILE=''
TRIGGER_EXPR=''
SAMPLESHEET=''

assignVariables() {
	if [[ "${RUN_PATH}" =~ "MiniSeq" ]];then
		MAX_DEPTH="${MINISEQ_MAX_DEPTH}"
		TRIGGER_FILE="${MINISEQ_TRIGGER_FILE}"
		TRIGGER_EXPR="${MINISEQ_TRIGGER_EXPR}"
		SAMPLESHEET="${MINISEQ_SAMPLESHEET_PATH}"
	elif [[ "${RUN_PATH}" =~ "MiSeq" ]];then
		MAX_DEPTH="${MISEQ_MAX_DEPTH}"
		TRIGGER_FILE="${MISEQ_TRIGGER_FILE}"
		TRIGGER_EXPR="${MISEQ_TRIGGER_EXPR}"
		SAMPLESHEET="${MISEQ_SAMPLESHEET_PATH}"
	elif [[ "${RUN_PATH}" =~ "NEXTSEQ" ]];then
		MAX_DEPTH="${NEXTSEQ_MAX_DEPTH}"
		TRIGGER_FILE="${NEXTSEQ_TRIGGER_FILE}"
		TRIGGER_EXPR="${NEXTSEQ_TRIGGER_EXPR}"
		SAMPLESHEET="${NEXTSEQ_SAMPLESHEET_PATH}"
	fi
}

modifyJsonAndLaunch() {
	debug "WDL:${WDL} - SAMPLE:${SAMPLE} - BED:${BED} - RUN:${RUN_PATH}${RUN}"
	if [ ! -d "${AUTODL_DIR}/${RUN}" ];then
		mkdir "${AUTODL_DIR}/${RUN}"
	fi
	if [ ! -e "${MOBIDL_JSON_DIR}${WDL}_inputs.json" ];then
		error "No json file for ${WDL}"
	fi		
	cp "${MOBIDL_JSON_DIR}${WDL}_inputs.json" "${AUTODL_DIR}${RUN}/${WDL}_${SAMPLE}_inputs.json"
	JSON="${AUTODL_DIR}${RUN}/${WDL}_${SAMPLE}_inputs.json"
	SUFFIX1=$(echo "${SAMPLES[${SAMPLE}]}" | cut -d ';' -f 1)
	SUFFIX2=$(echo "${SAMPLES[${SAMPLE}]}" | cut -d ';' -f 2)
	FASTQ_DIR=$(echo "${SAMPLES[${SAMPLE}]}" | cut -d ';' -f 3)
	#https://stackoverflow.com/questions/6744006/can-i-use-sed-to-manipulate-a-variable-in-bash
	#bash native character replacement
	FASTQ_SED=${FASTQ_DIR////\\/}
	ROI_SED=${ROI_DIR////\\/}
	#RUN_SED=${RUN_PATH////\\/}
	TMP_OUTPUT_SED=${TMP_OUTPUT_DIR////\\/}
	sed -i.bak -e "s/\(  \"${WDL}.sampleID\": \"\).*/\1${SAMPLE}\",/" \
		-e "s/\(  \"${WDL}.suffix1\": \"\).*/\1_${SUFFIX1}\",/" \
		-e "s/\(  \"${WDL}.suffix2\": \"\).*/\1_${SUFFIX2}\",/" \
		-e "s/\(  \"${WDL}.fastqR1\": \"\).*/\1${FASTQ_SED}\/${SAMPLE}_${SUFFIX1}.fastq.gz\",/" \
		-e "s/\(  \"${WDL}.fastqR2\": \"\).*/\1${FASTQ_SED}\/${SAMPLE}_${SUFFIX2}.fastq.gz\",/" \
		-e "s/\(  \"${WDL}.workflowType\": \"\).*/\1${WDL}\",/" \
		-e "s/\(  \"${WDL}.intervalBedFile\": \"\).*/\1${ROI_SED}${BED}\",/" \
		-e "s/\(  \"${WDL}.outDir\": \"\).*/\1${TMP_OUTPUT_SED}\",/" "${JSON}"
	if [ "${GENOME}" != "hg19" ];then
		sed "s/hg19/${GENOME}/g" "${JSON}"
	fi
	rm "${JSON}.bak"
	debug "$(cat ${JSON})"
	info "${RUN} - ${SAMPLE} ready for ${WDL}"
	info "Launching:"
	info "sh ${CWW} -e ${CROMWELL} -o ${CROMWELL_OPTIONS} -c ${CROMWELL_CONF} -w ${WDL}.wdl -i ${JSON}"
	#actual launch and copy in the end
	#sh "${CWW}" -e "${CROMWELL}" -o "${CROMWELL_OPTIONS}" -c "${CROMWELL_CONF}" -w "${WDL}.wdl" -i "${JSON}"
	#if [ $? -eq 0 ];then
	#	${RSYNC} -az --delete "{TMP_OUTPUT_SED}/${SAMPLE}" "${RUN_PATH}${RUN}/MobiDL/"
	#else
	#	error "Error while executing ${WDL} for ${SAMPLE} in run ${RUN_PATH}${RUN}"
	#fi	
}


###############		Now we'll have a look at the content of the directories ###############################


#http://moinne.com/blog/ronald/bash/list-directory-names-in-bash-shell
#--time-style is used here to ensure awk $8 will return the right thing (dir name)
RUN_PATHS="${MINISEQ_RUNS_DIR} ${MISEQ_RUNS_DIR} ${NEXTSEQ_RUNS_DIR}"
for RUN_PATH in ${RUN_PATHS}
do
	debug "RUN_PATH:${RUN_PATH}"
	assignVariables "${RUN_PATH}"
	RUNS=$(ls -l --time-style="long-iso" ${RUN_PATH} | egrep '^d' | awk '{print $8}' |  egrep '^[0-9]{6}_')
	for RUN in ${RUNS}
	do
		######do not look at runs set to 2 in the runs.txt file
		if [ -z "${RUN_ARRAY[${RUN}]}" ] || [ "${RUN_ARRAY[${RUN}]}" -eq 0 ]; then
			debug "SAMPLESHEET:${SAMPLESHEET},MAX_DEPTH:${MAX_DEPTH},TRIGGER_FILE:${TRIGGER_FILE},TRIGGER_EXPR:${TRIGGER_EXPR}"
			#now we must look for the AnalysisLog.txt file
			#get finished run
			if [ -n $(find ${RUN_PATH}${RUN} -mindepth 1 -maxdepth ${MAX_DEPTH} -type f -name '${TRIGGER_FILE}' -exec egrep '${TRIGGER_EXPR}' '{}' \; -quit) ]; then
				#need to determine BED ROI from samplsheet
				if [ -e ${RUN_PATH}${RUN}/${SAMPLESHEET} ];then 
					debug "SAMPLESHEET TESTED:${RUN_PATH}${RUN}/${SAMPLESHEET}"
					info "RUN ${RUN} found for analysis"
					if [ !-d "${RUN_PATH}${RUN}/MobiDL" ];then
						mkdir "${RUN_PATH}${RUN}/MobiDL"
					fi
					if [ !-d "${RUN_PATH}${RUN}/MobiDL/MobiCNVtsvs/" ];then
						mkdir "${RUN_PATH}${RUN}/MobiDL/MobiCNVtsvs/"
					fi
					if [ !-d "${RUN_PATH}${RUN}/MobiDL/MobiCNVvcfs/" ];then
						mkdir "${RUN_PATH}${RUN}/MobiDL/MobiCNVvcfs/"
					fi
					unset MANIFEST
					unset BED
					MANIFEST=$(grep -F -e "`cat ${ROI_FILE} | cut -d '=' -f 1`" ${RUN_PATH}${RUN}/${SAMPLESHEET} | cut -d ',' -f 2)
					BED=$(grep "${MANIFEST%?}" "${ROI_FILE}" | cut -d '=' -f 2 | cut -d ',' -f 1)
					if [[ ${BED} =~ '(hg[0-9]{2})\.bed' ]];then
						GENOME=${BASH_REMATCH[1]}
					else
						GENOME=hg19
					fi
					debug "${MANIFEST%?}:${BED}"
					info "BED file to be used for analysis of run ${RUN}:${BED}"
					if [ ${BED} == "FASTQ" ];then
						#look for samplesheet Description field
						DESC=$(grep 'Description,' "${RUN_PATH}${RUN}/${SAMPLESHEET}" | cut -d ',' -f 2)
						debug "Description:${DESC}"
						#here we'll have to determine WDL adn BED depending on description fiels
						#...
					else
						WDL=$(grep "${MANIFEST%?}" "${ROI_FILE}" | cut -d '=' -f 2 | cut -d ',' -f 2)
						info "MobiDL workflow to be launched for run ${RUN}:${WDL}"
						#now we have to identifiy samples in fastqdir (identify fastqdir,which may change depending on the Illumina workflow) then sed on json model, then launch wdl workflow
						declare -A SAMPLES
						FASTQS=$(find ${RUN_PATH}${RUN} -mindepth 1 -maxdepth 4 -type f -name *.fastq.gz | grep -v 'Undetermined' | sort)
						for FASTQ in ${FASTQS[@]};do
							FILENAME=$(basename "${FASTQ}" ".fastq.gz")
							debug "SAMPLE FILENAME:${FILENAME}"
							REGEXP='^([a-zA-Z0-9]+)_(.+)$'
							if [[ ${FILENAME} =~ ${REGEXP} ]];then
								if [ ${SAMPLES["${BASH_REMATCH[1]}"]} ];then
									SAMPLES["${BASH_REMATCH[1]}"]="${SAMPLES[${BASH_REMATCH[1]}]};${BASH_REMATCH[2]};${FASTQ%/*}"
								else
									SAMPLES["${BASH_REMATCH[1]}"]=${BASH_REMATCH[2]}
								fi
							else
								warning "SAMPLE DOES NOT MATCH REGEXP ${REGEXP}: ${FILENAME} ${RUN_PATH}${RUN}"
							fi
						done
						for SAMPLE in ${!SAMPLES[@]};do
							modifyJsonAndLaunch
							ln -s "${RUN_PATH}${RUN}/MobiDL/${SAMPLE}/${WDL}/${SAMPLE}.vcf" "${RUN_PATH}${RUN}/MobiDL/MobiCNVvcfs/"
							ln -s "${RUN_PATH}${RUN}/MobiDL/${SAMPLE}/${WDL}/coverage/${SAMPLE}_coverage.tsv" "${RUN_PATH}${RUN}/MobiDL/MobiCNVtsvs/"
							debug "SAMPLE(SUFFIXES):${SAMPLE}(${SAMPLES[${SAMPLE}]})"
						done 
					fi
					#MobiCNV && multiqc
					info "launching MobiCNV on run ${RUN}"
					#"${PYTHON}" "${MOBICNV}" -i "${RUN_PATH}${RUN}/MobiDL/MobiCNVtsvs/" -t tsv -v "${RUN_PATH}${RUN}/MobiDL/MobiCNVvcfs/" -o "${RUN_PATH}${RUN}/MobiDL/${RUN}_MobiCNV.xlsx"
					debug "${PYTHON} ${MOBICNV} -i ${RUN_PATH}${RUN}/MobiDL/MobiCNVtsvs/ -t tsv -v ${RUN_PATH}${RUN}/MobiDL/MobiCNVvcfs/ -o ${RUN_PATH}${RUN}/MobiDL/${RUN}_MobiCNV.xlsx"
					info "Launching MultiQC on run ${RUN}"
					#"${MULTIQC}" "${RUN_PATH}${RUN}/MobiDL/" -n "${RUN}_multiqc.html" -o "${RUN_PATH}${RUN}/MobiDL/"
					debug "${MULTIQC} ${RUN_PATH}${RUN}/MobiDL/ -n ${RUN}_multiqc.html -o ${RUN_PATH}${RUN}/MobiDL/"
					info "RUN ${RUN} treated"
				fi
			fi
		fi
	done
done
