#!/bin/bash

BIN_DIR=$(dirname $(readlink -f $0))
HTTPD_DIR=$(dirname ${BIN_DIR})


#启动检查
ENV_CHECK=0
if [[ -f ${HTTPD_DIR}/opbin/self_check.sh ]]; then
	#statements
	source ${HTTPD_DIR}/opbin/self_check.sh
	if [[ $? -ne 0 ]]; then
		#statements
		echo "[FATAL] can't load ../opbin/self_monitor"
		exit 1
	fi
	ENV_CHECK=1
fi

#usage
function lamp_help(){
	echo "Usage: ${0} <start|stop|restart|reload|rotate>"
	exit 1
}


function lamp_start(){


}

function lamp_stop(){

}

function lamp_reload(){


}

function rotate(){

	
}

case "${1}" in
    start|stop|restart|reload|rotate)
        "lamp_${1}"
        ;;
    *)
        lamp_help
        ;;
esac
	
if [ $? -ne 0 ]; then
    echo "[FAIL] ${1}" 1>&2
    exit 1
fi