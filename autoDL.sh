#!/bin/bash

###########################################################################
#########														###########
#########		AutoDL											###########
######### @uthor : D Baux	david.baux<at>inserm.fr				###########
######### Date : 14/09/2018										###########
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

#choosePipeline() {
#	return $(${GREP} -F "${SAMPLE_SHEET}" "${SAMPLE_SHEET_DB}" | cut -d '=' -f 2)	
#}



MAX_DEPTH=''
TRIGGER_FILE=''
TRIGGER_EXPR=''
SAMPLESHEET=''

assignVariables() {
	#${RUN_PATH}
	if [[ "${1}" =~ "MiniSeq" ]];then
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
	fi
	TMP_OUTPUT_DIR2="${TMP_OUTPUT_DIR}${RUN}/"
}
dos2unixIfPossible() {
	 if [[ "${RUN_PATH}" =~ "MiniSeq" ||  "${RUN_PATH}" =~ "MiSeq" ]];then
	 #if [ -w ${RUN_PATH}${RUN}/${SAMPLESHEET} ];then
		 "${DOS2UNIX}" "${RUN_PATH}${RUN}/${SAMPLESHEET}" >/dev/null 2>&1
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
	if [ ! -d "${TMP_OUTPUT_DIR2}" ];then
		mkdir "${TMP_OUTPUT_DIR2}"
	fi
	TMP_OUTPUT_SED=${TMP_OUTPUT_DIR2////\\/}
	sed -i.bak -e "s/\(  \"${WDL}.sampleID\": \"\).*/\1${SAMPLE}\",/" \
		-e "s/\(  \"${WDL}\.suffix1\": \"\).*/\1_${SUFFIX1}\",/" \
		-e "s/\(  \"${WDL}\.suffix2\": \"\).*/\1_${SUFFIX2}\",/" \
		-e "s/\(  \"${WDL}\.fastqR1\": \"\).*/\1${FASTQ_SED}\/${SAMPLE}_${SUFFIX1}\.fastq\.gz\",/" \
		-e "s/\(  \"${WDL}\.fastqR2\": \"\).*/\1${FASTQ_SED}\/${SAMPLE}_${SUFFIX2}\.fastq\.gz\",/" \
		-e "s/\(  \"${WDL}\.workflowType\": \"\).*/\1${WDL}\",/" \
		-e "s/\(  \"${WDL}\.intervalBedFile\": \"\).*/\1${ROI_SED}${BED}\",/" \
		-e "s/\(  \"${WDL}\.bedFile\": \"\).*/\1\/dv2\/refData\/intervals\/${BED}\",/" \
		-e "s/\(  \"${WDL}\.outDir\": \"\).*/\1${TMP_OUTPUT_SED}\",/" \
		-e "s/\(  \"${WDL}\.dvOut\": \"\).*/\1\/dv2\/tmp_output\/${RUN}\"/" "${JSON}"
	#if [ "${MANIFEST}" != "GenerateFastQWorkflow" ] && [ "${MANIFEST}" != "GenerateFASTQ" ]; then
	#	JSON_SUFFIX=$(grep "${MANIFEST%?}" "${ROI_FILE}" | cut -d '=' -f 2 | cut -d ',' -f 5)
	#	if [ "${JSON_SUFFIX}" == "CFScreening" ];then
	#		sed -i.bak -e "s/\(  \"${WDL}.intervalBedFileCnv\": \"\).*/\1\/usr\/local\/share\/refData\/intervals\/CF_panel_20201203.bed\",/" "${JSON}"
	#	fi
	#fi
	if [ "${GENOME}" != "hg19" ];then
		sed "s/hg19/${GENOME}/g" "${JSON}"
	fi
	rm "${JSON}.bak"
	debug "$(cat ${JSON})"
	info "${RUN} - ${SAMPLE} ready for ${WDL}"
	info "Launching:"
	info "sh ${CWW} -e ${CROMWELL} -o ${CROMWELL_OPTIONS} -c ${CROMWELL_CONF} -w ${WDL}.wdl -i ${JSON}"
	#actual launch and copy in the end
	if [ ! -d "${TMP_OUTPUT_DIR2}Logs" ];then
		mkdir "${TMP_OUTPUT_DIR2}Logs"
	fi
	touch "${TMP_OUTPUT_DIR2}Logs/${SAMPLE}_${WDL}.log"
	info "MobiDL ${WDL} log for ${SAMPLE} in ${TMP_OUTPUT_DIR2}Logs/${SAMPLE}_${WDL}.log" 
	#actual launch and copy in the end
	sh "${CWW}" -e "${CROMWELL}" -o "${CROMWELL_OPTIONS}" -c "${CROMWELL_CONF}" -w "${WDL}.wdl" -i "${JSON}" >> "${TMP_OUTPUT_DIR2}Logs/${SAMPLE}_${WDL}.log"
	if [ $? -eq 0 ];then
		workflowPostTreatment "${WDL}"
		#if [[ "${RUN_PATH}" =~ "NEXTSEQ" ]];then
		#	RUN_PATH="${NEXTSEQ_RUNS_DEST_DIR}"
		#elif [[ "${RUN_PATH}" =~ "MISEQ" ]];then
		#	RUN_PATH="${MISEQ_RUNS_DEST_DIR}"
		#fi
		#${RSYNC} -avq -remove-source-files "${TMP_OUTPUT_DIR2}Logs/${SAMPLE}_${WDL}.log" "${TMP_OUTPUT_DIR2}${SAMPLE}"
		#info "Moving MobiDL sample ${SAMPLE} to ${RUN_PATH}${RUN}/MobiDL/" 
		#${RSYNC} -avq -remove-source-files "${TMP_OUTPUT_DIR2}${SAMPLE}" "${RUN_PATH}${RUN}/MobiDL/"
		#if [ $? -eq 0 ];then
		#	rm -r "${TMP_OUTPUT_DIR2}${SAMPLE}"
		#else
		#	error "Error while syncing ${WDL} for ${SAMPLE} in run ${RUN_PATH}${RUN}"
		#fi
	else
		GATK_LEFT_ALIGN_INDEL_ERROR=$(grep 'the range cannot contain negative indices' "${TMP_OUTPUT_DIR2}Logs/${SAMPLE}_${WDL}.log")
		#search for an error with gatk LAI - if found relaunch without this step
		# cannot explain this error - maybe a gatk bug?
		if [ "${GATK_LEFT_ALIGN_INDEL_ERROR}" != '' ];then
			sh "${CWW}" -e "${CROMWELL}" -o "${CROMWELL_OPTIONS}" -c "${CROMWELL_CONF}" -w "${WDL}_noGatkLai.wdl" -i "${JSON}" >> "${TMP_OUTPUT_DIR2}Logs/${SAMPLE}_${WDL}_noGatkLai.log"
			if [ $? -eq 0 ];then
				info "GATK LeftAlignIndel Error occured - relaunching MobiDL without this step"
				workflowPostTreatment "${WDL}_noGatkLai"
				#if [[ "${RUN_PATH}" =~ "NEXTSEQ" ]];then
				#	RUN_PATH="${NEXTSEQ_RUNS_DEST_DIR}"
				#elif [[ "${RUN_PATH}" =~ "MISEQ" ]];then
				#	RUN_PATH="${MISEQ_RUNS_DEST_DIR}"
				#fi
				#${RSYNC} -avq -remove-source-files "${TMP_OUTPUT_DIR2}Logs/${SAMPLE}_${WDL}_noGatkLai.log" "${TMP_OUTPUT_DIR2}${SAMPLE}"
				#info "Moving MobiDL sample ${SAMPLE} to ${RUN_PATH}${RUN}/MobiDL/" 
				#${RSYNC} -avq -remove-source-files "${TMP_OUTPUT_DIR2}${SAMPLE}" "${RUN_PATH}${RUN}/MobiDL/"
				#if [ $? -eq 0 ];then
				#	rm -r "${TMP_OUTPUT_DIR2}${SAMPLE}"
				#else
				#	error "Error while syncing ${WDL} for ${SAMPLE} in run ${RUN_PATH}${RUN}"
				#fi
			else
				error "Error while executing ${WDL}_noGatkLai for ${SAMPLE} in run ${RUN_PATH}${RUN}"
			fi
		else
			error "Error while executing ${WDL} for ${SAMPLE} in run ${RUN_PATH}${RUN}"
		fi
	fi
}

workflowPostTreatment() {
	if [[ "${RUN_PATH}" =~ "NEXTSEQ" ]];then
		RUN_PATH="${NEXTSEQ_RUNS_DEST_DIR}"
	elif [[ "${RUN_PATH}" =~ "MISEQ" ]];then
		RUN_PATH="${MISEQ_RUNS_DEST_DIR}"
	fi
	${RSYNC} -avq -remove-source-files "${TMP_OUTPUT_DIR2}Logs/${SAMPLE}_${1}.log" "${TMP_OUTPUT_DIR2}${SAMPLE}"
	info "Moving MobiDL sample ${SAMPLE} to ${RUN_PATH}${RUN}/MobiDL/" 
	${RSYNC} -avq -remove-source-files "${TMP_OUTPUT_DIR2}${SAMPLE}" "${RUN_PATH}${RUN}/MobiDL/"
	if [ $? -eq 0 ];then
		rm -r "${TMP_OUTPUT_DIR2}${SAMPLE}"
	else
		error "Error while syncing ${1} for ${SAMPLE} in run ${RUN_PATH}${RUN}"
	fi
}

modifyAchabJson() {
	ACHAB_DIR=CaptainAchab
	ACHAB=captainAchab
	ACHAB_TODO_DIR_SED=${ACHAB_TODO_DIR////\\/}
	GENE_FILE_SED=${GENE_FILE////\\/}
	RUN_PATH_SED=${RUN_PATH////\\/}
	if [ ! -d "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${ACHAB_DIR}" ];then
		mkdir -p "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${ACHAB_DIR}"
	fi
	sed -i.bak -e "s/\(  \"${ACHAB}\.sampleID\": \"\).*/\1${SAMPLE}\.${1}\",/" \
		-e "s/\(  \"${ACHAB}\.affected\": \"\).*/\1${SAMPLE}\.${1}\",/" \
		-e "s/\(  \"${ACHAB}\.inputVcf\": \"\).*/\1${ACHAB_TODO_DIR_SED}${SAMPLE}\.${1}\/${SAMPLE}\.${1}\.vcf\",/" \
		-e "s/\(  \"${ACHAB}\.diseaseFile\": \"\).*/\1${ACHAB_TODO_DIR_SED}${SAMPLE}\.${1}\/disease.txt\",/" \
		-e "s/\(  \"${ACHAB}\.genesOfInterest\": \"\).*/\1${GENE_FILE_SED}\",/" \
		-e "s/\(  \"${ACHAB}\.outDir\": \"\).*/\1${RUN_PATH_SED}${RUN}\/MobiDL\/${SAMPLE}\/${ACHAB_DIR}\/\",/" \
		"${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${SAMPLE}.${1}/captainAchab_inputs.json"
	rm "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${SAMPLE}.${1}/captainAchab_inputs.json.bak"
	# move achah binput folder in todo folder for autoachab
	cp -R "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${SAMPLE}.${1}/" "${ACHAB_TODO_DIR}"
}


prepareAchab() {
	# function to prepare dirs for autoachab execution
	if [ ! -d "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${SAMPLE}.dv/" ];then
		mkdir "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${SAMPLE}.dv/"
	fi
	cp "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/panelCapture/${SAMPLE}.dv.vcf" "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${SAMPLE}.dv/"
	if [ ! -d "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${SAMPLE}.hc/" ];then
		mkdir "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${SAMPLE}.hc/"
	fi
	cp "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/panelCapture/${SAMPLE}.hc.vcf" "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${SAMPLE}.hc/"
	# disease and genes of interest files
	debug "Manifest file: ${MANIFEST}"
	debug "BED file: ${BED}"
	unset DISEASE_FILE
	unset GENE_FILE
	unset JSON_SUFFIX
	if [ "${MANIFEST}" != "GenerateFastQWorkflow" ] && [ "${MANIFEST}" != "GenerateFASTQ" ]; then
		DISEASE_FILE=$(grep "${MANIFEST%?}" "${ROI_FILE}" | cut -d '=' -f 2 | cut -d ',' -f 4)
		GENE_FILE=$(grep "${MANIFEST%?}" "${ROI_FILE}" | cut -d '=' -f 2 | cut -d ',' -f 3)
		JSON_SUFFIX=$(grep "${MANIFEST%?}" "${ROI_FILE}" | cut -d '=' -f 2 | cut -d ',' -f 5)
	else
		debug "FASTQ workflows file: ${FASTQ_WORKFLOWS_FILE}"
		DISEASE_FILE=$(grep "${BED}" "${FASTQ_WORKFLOWS_FILE}" | cut -d ',' -f 3)
		GENE_FILE=$(grep "${BED}" "${FASTQ_WORKFLOWS_FILE}" | cut -d ',' -f 2)
		JSON_SUFFIX=$(grep "${BED}" "${FASTQ_WORKFLOWS_FILE}" | cut -d ',' -f 4)
	fi
	debug "Disease file: ${DISEASE_FILE}"
	debug "Genes file: ${GENE_FILE}"
	if [ -n "${DISEASE_FILE}" ] && [ -n "${GENE_FILE}" ] && [ -n "${JSON_SUFFIX}" ]; then
		# cp disease file in achab input dir
		cp "${DISEASE_ACHAB_DIR}${DISEASE_FILE}" "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${SAMPLE}.hc/disease.txt"
		cp "${DISEASE_ACHAB_DIR}${DISEASE_FILE}" "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${SAMPLE}.dv/disease.txt"
		# cp json file in achab input dir and modify it		
		cp "${MOBIDL_JSON_DIR}captainAchab_inputs_${JSON_SUFFIX}.json" "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${SAMPLE}.hc/captainAchab_inputs.json"
		cp "${MOBIDL_JSON_DIR}captainAchab_inputs_${JSON_SUFFIX}.json" "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${SAMPLE}.dv/captainAchab_inputs.json"
		modifyAchabJson "dv"
		modifyAchabJson "hc"
	fi
}




###############		Now we'll have a look at the content of the directories ###############################


# http://moinne.com/blog/ronald/bash/list-directory-names-in-bash-shell
# --time-style is used here to ensure awk $8 will return the right thing (dir name)
RUN_PATHS="${MINISEQ_RUNS_DIR} ${MISEQ_RUNS_DIR} ${NEXTSEQ_RUNS_DIR}"
for RUN_PATH in ${RUN_PATHS}
do
	debug "RUN_PATH:${RUN_PATH}"
	# assignVariables "${RUN_PATH}"
	OUTPUT_PATH=${RUN_PATH}
	RUNS=$(ls -l --time-style="long-iso" ${RUN_PATH} | egrep '^d' | awk '{print $8}' |  egrep '^[0-9]{6}_')
	for RUN in ${RUNS}
	do
		###### do not look at runs set to 2 in the runs.txt file
		if [ -z "${RUN_ARRAY[${RUN}]}" ] || [ "${RUN_ARRAY[${RUN}]}" -eq 0 ]; then
			assignVariables "${RUN_PATH}"
			debug "SAMPLESHEET:${SAMPLESHEET},MAX_DEPTH:${MAX_DEPTH},TRIGGER_FILE:${TRIGGER_FILE},TRIGGER_EXPR:${TRIGGER_EXPR}"
			# now we must look for the AnalysisLog.txt file
			# get finished run
			if [ -n $(find ${RUN_PATH}${RUN} -mindepth 1 -maxdepth ${MAX_DEPTH} -type f -name '${TRIGGER_FILE}' -exec egrep '${TRIGGER_EXPR}' '{}' \; -quit) ]; then
				# need to determine BED ROI from samplesheet
				SAMPLESHEET_PATH="${RUN_PATH}${RUN}/${SAMPLESHEET}"
				# if [ -e ${RUN_PATH}${RUN}/${SAMPLESHEET} ];then 
				debug "SAMPLESHEET PATH TESTED:${SAMPLESHEET_PATH}"
				if [ -f ${SAMPLESHEET_PATH} ];then 
					debug "SAMPLESHEET TESTED:${SAMPLESHEET_PATH}"
					info "RUN ${RUN} found for analysis"
					dos2unixIfPossible
					TREATED=0
					unset MANIFEST
					unset BED
					unset WDL
					MANIFEST=$(grep -F -e "`cat ${ROI_FILE} | cut -d '=' -f 1`" ${SAMPLESHEET_PATH} | cut -d ',' -f 2)
					if [[ "${MANIFEST}" != '' ]];then
						BED=$(grep "${MANIFEST%?}" "${ROI_FILE}" | cut -d '=' -f 2 | cut -d ',' -f 1)
						debug "MANIFEST:${MANIFEST}"
						debug "BED:${BED}"
						if [[ ${BED} =~ '(hg[0-9]{2})\.bed' ]];then
							GENOME=${BASH_REMATCH[1]}
						else
							GENOME=hg19
						fi
						debug "${MANIFEST%?}:${BED}"
						info "BED file to be used for analysis of run ${RUN}:${BED}"
						if [ "${BED}" = "FASTQ" ];then
							# NEXTSEQ
							BED=$(grep 'Description,' "${SAMPLESHEET_PATH}" | cut -d ',' -f 2 | cut -d '#' -f 1)
							if [ ! -f "${BED_DIR}${BED}" ];then
								BED=''
							fi
							WDL=$(grep 'Description,' "${SAMPLESHEET_PATH}" | cut -d ',' -f 2 | cut -d '#' -f 2)
							debug "BED:${BED} - WDL:${WDL}"
							# info "MobiDL workflow to be launched for run ${RUN}:${WDL}"
						else
							WDL=$(grep "${MANIFEST%?}" "${ROI_FILE}" | cut -d '=' -f 2 | cut -d ',' -f 2)
						fi
						if [ -n "${MANIFEST}" ] &&  [ -n "${WDL}" ] && [ -n "${BED}" ];then
							info "MobiDL workflow to be launched for run ${RUN}:${WDL}"
							if [ -z "${RUN_ARRAY[${RUN}]}" ];then
								echo ${RUN}=1 >> ${RUNS_FILE}
								RUN_ARRAY[${RUN}]=1
							elif [ "${RUN_ARRAY[${RUN}]}" -eq 0 ];then
								#Change value on array and file to running
								sed -i -e "s/${RUN}=0/${RUN}=1/g" "${RUNS_FILE}"
								RUN_ARRAY[${RUN}]=1
							fi
							if [[ "${RUN_PATH}" =~ "NEXTSEQ" ]];then
								OUTPUT_PATH=${NEXTSEQ_RUNS_DEST_DIR}
								if [ ! -d "${OUTPUT_PATH}${RUN}" ];then
									mkdir "${OUTPUT_PATH}${RUN}"
								fi
							elif [[ "${RUN_PATH}" =~ "MISEQ" ]];then
								OUTPUT_PATH=${MISEQ_RUNS_DEST_DIR}
								if [ ! -d "${OUTPUT_PATH}${RUN}" ];then
									mkdir "${OUTPUT_PATH}${RUN}"
								fi
							fi
							if [ ! -d "${OUTPUT_PATH}${RUN}/MobiDL" ];then
								mkdir "${OUTPUT_PATH}${RUN}/MobiDL"
							fi
							if [ ! -d "${OUTPUT_PATH}${RUN}/MobiDL/MobiCNVtsvs/" ];then
								mkdir "${OUTPUT_PATH}${RUN}/MobiDL/MobiCNVtsvs/"
							fi
							if [ ! -d "${OUTPUT_PATH}${RUN}/MobiDL/MobiCNVvcfs/" ];then
								mkdir "${OUTPUT_PATH}${RUN}/MobiDL/MobiCNVvcfs/"
							fi
							# now we have to identifiy samples in fastqdir (identify fastqdir,which may change depending on the Illumina workflow) then sed on json model, then launch wdl workflow
							declare -A SAMPLES
							FASTQS=$(find ${RUN_PATH}${RUN} -mindepth 1 -maxdepth 4 -type f -name *.fastq.gz | grep -v 'Undetermined' | sort)
							for FASTQ in ${FASTQS[@]};do
								FILENAME=$(basename "${FASTQ}" ".fastq.gz")
								debug "SAMPLE FILENAME:${FILENAME}"
								REGEXP='^([a-zA-Z0-9-]+)_(.+)$'
								if [[ ${FILENAME} =~ ${REGEXP} ]];then
									if [ ${SAMPLES["${BASH_REMATCH[1]}"]} ];then
										SAMPLES["${BASH_REMATCH[1]}"]="${SAMPLES[${BASH_REMATCH[1]}]};${BASH_REMATCH[2]};${FASTQ%/*}"
										debug "SAMPLE:${SAMPLES[${BASH_REMATCH[1]}]};${BASH_REMATCH[2]};${FASTQ%/*}"
									else
										SAMPLES["${BASH_REMATCH[1]}"]=${BASH_REMATCH[2]}
									fi
								else
									warning "SAMPLE DOES NOT MATCH REGEXP ${REGEXP}: ${FILENAME} ${RUN_PATH}${RUN}"
								fi
							done
							for SAMPLE in ${!SAMPLES[@]};do
								modifyJsonAndLaunch
								prepareAchab
								TREATED=1
								cp "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${WDL}/${SAMPLE}.hc.vcf.gz" "${OUTPUT_PATH}${RUN}/MobiDL/MobiCNVvcfs/"
								cp "${OUTPUT_PATH}${RUN}/MobiDL/${SAMPLE}/${WDL}/coverage/${SAMPLE}_coverage.tsv" "${OUTPUT_PATH}${RUN}/MobiDL/MobiCNVtsvs/"
								debug "SAMPLE(SUFFIXES):${SAMPLE}(${SAMPLES[${SAMPLE}]})"
							done
							unset SAMPLES
						fi
						if [ "${TREATED}" -eq 1 ];then
							# MobiCNV && multiqc
							# no VCF anymore fo mobicnv: -v ${OUTPUT_PATH}${RUN}/MobiDL/MobiCNVvcfs/
							info "Launching MobiCNV on run ${RUN}"
							"${PYTHON}" "${MOBICNV}" -i "${OUTPUT_PATH}${RUN}/MobiDL/MobiCNVtsvs/" -t tsv -o "${OUTPUT_PATH}${RUN}/MobiDL/${RUN}_MobiCNV.xlsx"
							debug "${PYTHON} ${MOBICNV} -i ${OUTPUT_PATH}${RUN}/MobiDL/MobiCNVtsvs/ -t tsv  -o ${OUTPUT_PATH}${RUN}/MobiDL/${RUN}_MobiCNV.xlsx"
							info "Launching MultiQC on run ${RUN}"
							"${MULTIQC}" "${OUTPUT_PATH}${RUN}/MobiDL/" -n "${RUN}_multiqc.html" -o "${OUTPUT_PATH}${RUN}/MobiDL/"
							debug "${MULTIQC} ${OUTPUT_PATH}${RUN}/MobiDL/ -n ${RUN}_multiqc.html -o ${OUTPUT_PATH}${RUN}/MobiDL/"
							chmod -R 777 "${OUTPUT_PATH}${RUN}/MobiDL/"
							sed -i -e "s/${RUN}=1/${RUN}=2/" "${RUNS_FILE}"
							RUN_ARRAY[${RUN}]=2
							info "RUN ${RUN} treated"
							touch "${OUTPUT_PATH}${RUN}/MobiDL/panelCaptureComplete.txt"
							echo "[`date +'%Y-%m-%d %H:%M:%S'`] [INFO] - autoDL version : ${VERSION} - MobiDL panelCapture complete for run ${RUN}" > "${OUTPUT_PATH}${RUN}/MobiDL/panelCaptureComplete.txt"
						else
							info "Nothing done for run ${RUN_PATH}${RUN}"
							if [ -z "${RUN_ARRAY[${RUN}]}" ];then
								echo ${RUN}=2 >> ${RUNS_FILE}
								RUN_ARRAY[${RUN}]=2
							fi
						fi
					else
						info "Nothing done for ${RUN}"
						if [ -z "${RUN_ARRAY[${RUN}]}" ];then
							echo ${RUN}=2 >> ${RUNS_FILE}
							RUN_ARRAY[${RUN}]=2
						elif [ "${RUN_ARRAY[${RUN}]}" -eq 0 ];then
							# Change value on array and file to running
							sed -i -e "s/${RUN}=0/${RUN}=2/g" "${RUNS_FILE}"
							RUN_ARRAY[${RUN}]=2
						fi
					fi
				fi
			fi
		fi
	done
done
