#!/usr/bin/env bash

sigint_handler(){
	printf >&2 \
		"\n%s[!] SIGINT Signal sent to %s. Exiting...%s\n" \
		"${RED}" "${0##*/}" "${RESET}"

	tput cnorm
	trap - SIGINT
	kill -SIGINT "$$"
}

cleanup(){
	rm -rf ./clamdScan.txt
	tput cnorm
	echo -e "\n"
}

banner(){
	cat << BANNER

	${PURPLE}
	 ██████╗██╗      █████╗ ███╗   ███╗ █████╗ ██╗   ██╗
	██╔════╝██║     ██╔══██╗████╗ ████║██╔══██╗██║   ██║
	██║     ██║     ███████║██╔████╔██║███████║██║   ██║
	██║     ██║     ██╔══██║██║╚██╔╝██║██╔══██║╚██╗ ██╔╝
	╚██████╗███████╗██║  ██║██║ ╚═╝ ██║██║  ██║ ╚████╔╝ 
	 ╚═════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝  ╚═══╝  
	   ███╗   ███╗ █████╗ ██╗██╗     ███████╗██████╗ 
	   ████╗ ████║██╔══██╗██║██║     ██╔════╝██╔══██╗
	   ██╔████╔██║███████║██║██║     █████╗  ██████╔╝
	   ██║╚██╔╝██║██╔══██║██║██║     ██╔══╝  ██╔══██╗
	   ██║ ╚═╝ ██║██║  ██║██║███████╗███████╗██║  ██║
	   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═╝  ╚═╝
      ╭━─━─━─≪✠≫─━─━─━━─━─━─≪✠≫─━─━─━━─━─━─≪✠≫─━─━─━━─━─━─≪✠≫╮
      ╰━─━─━─≪✠≫─━─━─━━─━─━─≪✠≫─━─━─━━─━─━─≪✠≫─━─━─━━─━─━─≪✠≫╯ ${RESET}
BANNER
}

showHelp(){
	cat << HELP
	${PINK}
	DESCRIPTION: --

	USAGE: ${0##*/} [-h|-r] [--help|--recipient] ${RESET}

	${PURPLE}OPTIONS:

		-r | --recipient -> Specifies a Recipient Email Account
		-h | --help 	 -> Displays this help :) ${RESET}
HELP
}

checker(){
	local _package=$1 _binary=$2 _hostname=$( hostname --long )

	grep --quiet \
	     --ignore-case \
	     --perl-regexp \
	     '^Status: install ok installed$' \
	     < <( dpkg --status \
	     	       "${_package}" \
		       2> /dev/null
		)
	
	(( $? != 0 )) && {

		printf >&2 \
			"\n%s[!] %s package is not installed on %s %s\n" \
			"${RED}" "${_package}" "${_hostname}" "${RESET}"

		return 1
	}

	command -V "${_binary}" &> /dev/null || {
		
		printf >&2 \
			"\n%s[!] %s Binary not found on %s %s\n" \
			"${RED}" "${_binary}" "${_hostname}" "${RESET}"

		return 1
	}

	return 0
}

checkMailDeps(){
	local _package
	local -A _mailDeps=(

		[mailutils]="mail"
		[bsd-mailx]="mailx"
	)
	
	for _package in "${!_mailDeps[@]}" ; do

		checker "${_package}" "${_mailDeps[${_package}]}" && {

			(( _binaryFlags["${_mailDeps[${_package}]}"]++ )) && return 0
		}

	done

	return 1
}

sendMail(){
	local _binary=$1 _recipient=$2 _clamdConfigFile="/etc/clamav/clamd.conf"
	local _hostname=$( hostname --long )
	local _maillog="/var/log/maillog" _clamdScanFile="./clamdScan.txt"

	printf \
		"\n%s[+] Performing Clamd Scanning from / on %s...%s\n" \
		"${BLUE}" "${_hostname}" "${RESET}"

	{ grep --ignore-case \
	       --invert-match \
	       --perl-regexp \
	       --text \
	       ".*(Can\'t read file ERROR)\
               |(Failed to open file)\
	       |(Failed to determine real)\
	       |(Quarantine of the file).*" < <( clamdscan --multiscan \
							   --fdpass \
						           --allmatch \
						           --infected \
							   --config-file="${_clamdConfigFile}" \
						           --exclude-dir="^/sys" \
							   --verbose -- \
							   /etc \
							   2>/dev/null ) ; } > "${_clamdScanFile}"
	if [[ -s $_clamdScanFile ]] ; then
		
		printf \
			"\n%s[+] ClamAV Scan completed correctly :) %s\n" \
			"${GREEN}" "${RESET}"
	else
		printf >&2 \
			"\n%s[!] Something went wrong during ClamAV Scan Execution. \
			Try it manually and Debug Errors" \
			"${RED}" "${RESET}"

		return 1
	fi

	"${_binary}" --subject "ClamAV Analysis" "${_recipient}" < "${_clamdScanFile}"

	(( $? == 0 )) && { 

		printf \
			"\n%s[+] %s Process exited with status code %s. Check %s %s" \
			"${BLUE}" "${_binary}" "${?}" "${_maillog}" "${RESET}"
	} || {
		printf >&2 \
			"\n%s[!] Something went wrong trying to send ClamAV Email to %s :( %s" \
			"${RED}" "${_recipient}" "${RESET}"

		return 1
	}
}

main(){
	local -A _flags=()
	local -A _optArgs=()
	declare -A _binaryFlags=()

	(( $# == 0 )) && {

		printf >&2 \
			"\n\t%s[!] Try -h | --help to display Info about this Script :) %s" \
			"${BLUE}" "${RESET}"
		exit 99
	}

	while (( $# > 0 )) ; do 

		[[ $1 == -@(-recipient|r)=* ]] && set -- "${1%=*}" "${1#*=}" "${@:2}" && continue   # -r|--recipient=recipient Format

		case $1 in

			-r | --recipient )	(( _flags[r]++ ))
						_optArgs[recipient]="${2?Recipient is null or empty}"
						shift
						;;

			-h | --help )		showHelp ; exit 0
						;;

			-- )			shift ; break
						;;

			* ) 			printf >&2 \
							"\n\t%s[!] Unknown Option: %s . \
							Try -h | --help to Display Help Panel :) %s" \
							"${BLUE}" "${1}" "${RESET}"
						exit 99
						;;
		esac
		shift
	done

	[[ -z $_flags[r] || -z $_optArgs[recipient] ]] && {

		printf >&2 \
			"\n%s[+] Recipient Email Account must be provided. \
			Try -h | --help to display Help Panel %s" \
			"${RED}" "${RESET}"

		exit 99
	}
	
	checkMailDeps

	for _binary in "${!_binaryFlags[@]}" ;  do

		(( _binaryFlags["${_binary}"] == 1 )) && sendMail "${_binary}" "${_optArgs[recipient]}" || exit 99
		
	done
}

RED=$( tput setaf 1 )
BLUE=$( tput setaf 159 )
RESET=$( tput sgr0 )
PURPLE=$( tput setaf 200 )
PINK=$( tput setaf 219 )
GREEN=$( tput setaf 83 )
	
trap sigint_handler SIGINT
trap cleanup EXIT

banner
tput civis
main "${@}"
