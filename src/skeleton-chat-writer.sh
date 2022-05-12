#!/bin/bash 
#
# Regards, the Alveare Solutions #!/Society -x
#

# Hot parameters
CONF_FILE_PATH="$1"

# Cold parameters
USER_ALIAS="Ghost"
MESSAGE_FILE="/tmp/.sklc"
DTA_DIR='data'
GETS_TO_CLEANUP=0
MSG_FILE_GROUPS='pi'
MSG_FILE_PERMS=770
SESSION_FILE="${DTA_DIR}/.sklc-session"

if [ -f "${CONF_FILE_PATH}" ]; then
	source "$CONF_FILE_PATH"
fi

function cleanup() { 
	rm -f "${MESSAGE_FILE}"
	return $?
}

function setup() {
	local FAILURES=0
	touch "${MESSAGE_FILE}" &> /dev/null
	if [ $? -ne 0 ]; then
		echo "[ ERROR ]: Could not access file! (${MESSAGE_FILE})"
		local FAILURES=$((FAILURES+1))
		return $FAILURES
	fi
	chmod ${MSG_FILE_PERMS} "${MESSAGE_FILE}" &> /dev/null
	if [ $? -ne 0 ]; then
		local FAILURES=$((FAILURES + 1))
		echo "[ WARNING ]: Could not set file permissions! (${MSG_FILE_PERMS})"

	fi
	for group in `echo ${MSG_FILE_GROUPS} | tr ',' ' '`; do
		chgrp "${group}" "${MESSAGE_FILE}" &> /dev/null
		if [ $? -ne 0 ]; then
			local FAILURES=$((FAILURES + 1))
			echo "[ WARNING ]: Could not allow file access to group! (${group})"
		fi
	done
	return $FAILURES
}

function preconditions() {
	local EXIT_CODE=0
	set_alias
	if [ $? -ne 0 ]; then
		echo "[ WARNING ]: Could not set user alias! Defaulting to (${USER_ALIAS})"
		local EXIT_CODE=1
	fi
	if [ ! -f "${MESSAGE_FILE}" ]; then
		GETS_TO_CLEANUP=1
		setup
		local EXIT_CODE=$?
	fi
	return ${EXIT_CODE}
}

function set_alias() {
	echo "[ INFO ]: Setting non-persistent user alias, leave blank for default values"
 	while :; do
		read -p '[ Q/A ]: Who do you want to be? [Default: Ghost]> ' NEW_ALIAS
		if [ -z "${NEW_ALIAS}" ]; then
			break
		fi
		read -p "${NEW_ALIAS}, are you sure about this? [Yy/Nn]> " ANSWER
		if [[ ${ANSWER} == '.exit' || ${ANSWER} == '.back' ]]; then
			break	
		elif [[ ${ANSWER} =~ ^[Nn]$ || -z "${ANSWER}" ]]; then
			echo; continue
		elif [[ ! ${ANSWER} =~ ^[YyNn]$ ]]; then
			echo "[ WARNING ]: Invalid answer (${ANSWER})"
			continue
		fi
		USER_ALIAS="${NEW_ALIAS}"
		break
	done
	return 0
}

function format_message() {
	USER_PROMPT="[ ${USER_ALIAS} ]: "
	read -p "${USER_PROMPT}" USER_MSG
	if [ -z "${USER_MSG}" ]; then
		return 1
	fi
	echo "${USER_PROMPT}${USER_MSG}"
	return 0
}

function issue_message() {
	local MSG2SEND="$@"
	if [ ! -f "${MESSAGE_FILE}" ]; then
		GETS_TO_CLEANUP=1
	fi
	echo "${MSG2SEND}" >> "${MESSAGE_FILE}"
	return $?
}

function skeleton_emitter() {
	while :; do
		MESSAGE=`format_message`
		SANITIZED_MSG=`echo ${MESSAGE} | cut -d ':' -f 2 | xargs 2> /dev/null`
		if [ -z "${MESSAGE}" ]; then
			continue
		elif [[ "${SANITIZED_MSG}" == '.exit' || "${SANITIZED_MSG}" == '.back' ]]; then
			break
		fi
		issue_message "${MESSAGE}"
		if [ $? -ne 0 ]; then
			echo "[ WARNING ]: Something went wrong! Message not sent."
		fi
	done
	return 0
}

# MISCELLANEOUS

preconditions
skeleton_emitter
EXIT_CODE=$?

if [ ${GETS_TO_CLEANUP} -eq 1 ]; then
	echo "[ INFO ]: Cleaning up file system..."
	cleanup
	if [ $? -ne 0 ]; then
		echo "[ WARNING ]: Could not cleanup message file! (${MESSAGE_FILE})"
	fi
fi

echo "[ DONE ]: Terminating!"
sleep 0.2
tmux kill-session -t `cat ${SESSION_FILE}` &> /dev/null

exit $EXIT_CODE

