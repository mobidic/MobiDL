#!/bin/bash

###########################################################################
#########																												###########
#########		AutoDL																							###########
######### @uthor : D Baux	david.baux<at>inserm.fr								###########
######### Date : 27/10/2021																			###########
#########																												###########
###########################################################################

###########################################################################
###########
########### 	Script to automate the launch of merge_multisample.sh
########### 	to treat family data
###########
###########################################################################


####	This script is meant to be croned
####	must check the  Families directory, identify new runs
####	and launch the merge_multisample.sh script


##############		If any option is given, print help message	##################################
VERSION=1.0
USAGE="
Program: AutoDL
Version: ${VERSION}
Contact: Baux David <david.baux@inserm.fr>

Usage: This script is meant to be croned
	Should be executed twice per hour

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

VERBOSITY=2
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
		echoerr "[`date +'%Y-%m-%d %H:%M:%S'`] $2 - launchMerge version : ${VERSION} - $3"
	fi
}


###############		Get options from conf file			##################################
# CONFIG_FILE='./autoDL.conf'
CONFIG_FILE='/RS_IURC/data/MobiDL/panelCapture/conf/launchMerge.conf'
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

RM_VALUE=0
############### get new runs #################
RUNS=$(ls -l --time-style="long-iso" "${FAMILY_BASE_DIR}" | egrep '^d' | awk '{print $8}' |  egrep '^[0-9]{6}_')
for RUN in ${RUNS}
do
	# GENERAL_LOG="${FAMILY_BASE_DIR}launch_merge_log.txt"
	# RUN_LOG="${FAMILY_BASE_DIR}${RUN}/log.txt"
	# if [ ! -e "${GENERAL_LOG}" ];then
	# 	touch "${GENERAL_LOG}"
	# fi
	# if [ ! -e "${RUN_LOG}" ];then
	# 	touch "${RUN_LOG}"
	# fi
	info "Checking RUN:${RUN}"
	READY_FILE=$(ls -l "${FAMILY_BASE_DIR}${RUN}" | grep "ready.txt")
	if [ -n "${READY_FILE}" ];then
		info "RUN:${RUN} contains a ready.txt file"
		RM_VALUE=1
		# launch merge_multisample Script
		CONF_FILES=$(ls "${FAMILY_BASE_DIR}${RUN}/"*_file_config.txt | grep -v "Example")
		for CONF_FILE in ${CONF_FILES}
		do
			debug "CONF_FILE:${CONF_FILE}"
			# FAMILY_ID=$(basename "${CONF_FILE%.*}")
			# Check if the run has finished being analysed
			source ${CONF_FILE}
			# RUN_PATH from autoDLML.sh comes with a / in the end - remove it
			RUN_PATH=${RUN_PATH%\/}
			debug "panelCaptureComplete path: ${RUN_PATH}/${RUN_ID}/MobiDL/panelCaptureComplete.txt"
			if [ -f "${RUN_PATH}/${RUN_ID}/MobiDL/panelCaptureComplete.txt" ];then
				info "Launching merge_multisample script"
				info "bash merge_multisample.sh -f ${CONF_FILE} -t 4 -s -v 4"
				MERGE_LOG=$(bash merge_multisample.sh -f ${CONF_FILE} -t 4 -v 4)
				if [ $? -eq 0 ];then
					info "File ${CONF_FILE} properly treated"
				else
					# ERROR_LOG="${FAMILY_BASE_DIR}${RUN}/error_log.txt"
					# if [ ! -e "${ERROR_LOG}" ];then
					# 	touch "${ERROR_LOG}"
					# fi
					# mv "${RUN_LOG}" "${FAMILY_BASE_DIR}${RUN}/error_log.txt"
					# RUN_LOG="${FAMILY_BASE_DIR}${RUN}/error_log.txt"
					warning "File ${CONF_FILE} UNproperly treated"
					warning "${MERGE_LOG}"
				fi
			else
				info "RUN ${RUN_PATH}/${RUN_ID} not ready for merging"
				RM_VALUE=0
				break
			fi
		done
	else
		RM_VALUE=0
	fi
	if [ "${RM_VALUE}" -eq 1 ];then
		rm "${FAMILY_BASE_DIR}${RUN}/ready.txt"
	fi
done
