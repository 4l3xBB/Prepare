

sigintHandler(){
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
	printf "\n"
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
	DESCRIPTION: Performs Clamd Scan on Target Directory and Sent Report to Email Account

	USAGE: ${0##*/} [ -h | -r | -p ] [ --help | --recipient | --path ] ${RESET}

	${BLUE}OPTIONS:

		-r | --recipient -> Recipient Email Account ( REQUIRED )

		-p | --path 	 -> ClamAV Scan Target Directory. If not specified, Default Value is / ( OPTIONAL )

		-h | --help 	 -> Displays this help :) ${RESET}

	${PINK}EXAMPLES:

		${0##*/}    -r john.doe@test.com 	     -p /var
		${0##*/}    -r=john.doe@test.com 	     -p=/etc/
		${0##*/}    --recipient john.doe@test.com    --path /var
		${0##*/}    --recipient=john.doe@test.com    --path=./lib ${RESET}
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
	}

	command -V "${_binary}" &> /dev/null || {
		
		printf >&2 \
			"%s[!] %s Binary not found on %s %s\n" \
			"${RED}" "${_binary}" "${_hostname}" "${RESET}"

		return 1
	}

	return 0
}

systemdChecker(){
	local _PID1Cmd=$( cat /proc/1/comm ) _hostname=$( hostname --long )

	[[ $_PID1Cmd != systemd ]] && {

		printf >&2 \
			"\n%s[!] %s has not been initialized by Systemd :( %s\n" \
			"${RED}" "${_hostname}" "${RESET}"

		return 1
	}
	
	return 0
}

checkClamAVDeps(){
	local _package _clamAVService="clamav-daemon.service" _hostname=$( hostname --long )
	local -A _clamAVSuite=(
		
		[clamav-daemon]="clamd"
		[clamav-freshclam]="freshclam"
	)

	for _package in "${!_clamAVSuite[@]}" ; do

		checker "${_package}" "${_clamAVSuite[${_package}]}" || return 1
	done

	printf \
		"\n%s[+] Checking if %s is installed on %s...%s\n" \
		"${BLUE}" "${_clamAVService}" "${_hostname}" "${RESET}"

	grep --quiet \
	     --ignore-case \
	     --perl-regexp \
	     "^${_clamAVService}.*" < <( systemctl list-unit-files \
						      --type=service \
						      --all \
						      --no-legend \
						      --no-pager
					  )
	(( $? != 0 )) && {

		printf >&2 \
			"\n%s[!] Seems like %s unit has not been created on %s...%s\n" \
			"${RED}" "${_clamAVService}" "${_hostname}" "${RESET}"

		return 1
	}

	if ! systemctl --quiet is-active "${_clamAVService}" &> /dev/null ; then

		printf >&2 \
			"\n%s[!] %s is not Active / Running on %s :( %s\n" \
			"${RED}" "${_clamAVService}" "${_hostname}" "${RESET}"

		return 1
	fi
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
	local _binary=$1 _recipient=$2 _path="${3:-/**}"
	local _hostname=$( hostname --long )
	local _maillog="/var/log/maillog" _clamdScanFile="./clamdScan.txt" _clamdConfigFile="/etc/clamav/clamd.conf"

	[[ $_path != '/**' ]] && _path="${_path}/**"

	printf \
		"\n%s[+] Performing Clamd Scanning from %s on %s...%s\n" \
		"${BLUE}" "${_path}" "${_hostname}" "${RESET}"

	( 
	  shopt -sq globstar dotglob

	  grep --ignore-case \
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
							   ${_path} \
							   2>/dev/null 

						) 2> /dev/null
	) > "${_clamdScanFile}"

	if [[ -s $_clamdScanFile ]] ; then
		
		printf \
			"\n%s[+] ClamAV Scan completed correctly :) %s\n" \
			"${GREEN}" "${RESET}"
	else
		printf >&2 \
			"\n%s[!] Something went wrong during ClamAV Scan Execution. Try it manually and Debug Errors %s\n" \
			"${RED}" "${RESET}"

		return 1
	fi

	"${_binary}" -s "ClamAV Analysis" "${_recipient}" 2> /dev/null < "${_clamdScanFile}" 			# -s -> Mail Subject

	(( $? == 0 )) && { 

		printf \
			"\n%s[+] %s Process exited with status code %s. Check %s %s\n" \
			"${BLUE}" "${_binary}" "${?}" "${_maillog}" "${RESET}"
	} || {
		printf >&2 \
			"\n%s[!] Something went wrong trying to send ClamAV Email to %s :( %s\n" \
			"${RED}" "${_recipient}" "${RESET}"

		return 1
	}
}

main(){
	local -A _flags=()
	local -A _optArgs=()

	declare -A _binaryFlags=()
	local _emailRegex="^[a-zA-Z0-9.!#$%&\\*+/=?^_\`{|}~-]+@[a-zA-Z0-9-]+\.[a-zA-Z]{2,63}$"

	(( $# == 0 )) && {

		printf >&2 \
			"\n\t%s[!] Try -h | --help to display Info about this Script :) %s\n" \
			"${BLUE}" "${RESET}"
		exit 99
	}

	while (( $# > 0 )) ; do 

		[[ $1 == -@(-recipient|r)=* ]] && set -- "${1%=*}" "${1#*=}" "${@:2}" && continue   # -r|--recipient=recipient Format

		[[ $1 == -@(-path|p)=* ]] && set -- "${1%=*}" "${1#*=}" "${@:2}" && continue   # -p|--path=path Format

		case $1 in

			-r | --recipient )	(( _flags[r]++ ))
						_optArgs[recipient]="${2}"
						shift
						;;

			-p | --path )		(( _flags[p]++ ))
						_optArgs[path]="${2%/}"
						shift
						;;

			-h | --help )		showHelp ; exit 0
						;;

			-- )			shift ; break
						;;

			* ) 			printf >&2 \
							"\n\t%s[!] Unknown Option: %s . Try -h | --help to Display Help Panel :) %s\n" \
							"${BLUE}" "${1}" "${RESET}"
						exit 99
						;;
		esac
		shift
	done

	[[ -z "${_flags[r]}" || -z "${_optArgs[recipient]}" ]] && {

		printf >&2 \
			"\n%s[+] Recipient Email Account must be provided. Try -h | --help to display Help Panel %s\n" \
			"${RED}" "${RESET}"

		exit 99
	}
	
	[[ "${_optArgs[recipient]}" =~ $_emailRegex ]] || {
		
		printf >&2 \
			"\n%s[!] Recipient specified is not a Valid Email Account. Invalid Format :( %s\n" \
			"${RED}" "${RESET}"

		exit 99
	}

	[[ -n "${_optArgs[path]}" ]] && { 

		[[ -d "${_optArgs[path]}" ]] || {

			if [[ -f "${_optArgs[path]}" ]] ; then

				printf >&2 \
					"\n%s[!] Path specified cannot be a regular file. Must be a Directory %s\n" \
					"${RED}" "${RESET}"
			else
				printf >&2 \
					"\n%s[!] Invalid System Path. Please provide a valid one :)%s\n" \
					"${RED}" "${RESET}"
			fi
			
			exit 99
		}
	}

	systemdChecker || exit 99

	checkClamAVDeps || exit 99

	checkMailDeps

	for _binary in "${!_binaryFlags[@]}" ;  do

		(( _binaryFlags["${_binary}"] == 1 )) && {

			sendMail "${_binary}" "${_optArgs[recipient]}" "${_optArgs[path]}" && return 0 || exit 99
		}	
	done
}

RED=$( tput setaf 1 )
BLUE=$( tput setaf 159 )
RESET=$( tput sgr0 )
PURPLE=$( tput setaf 200 )
PINK=$( tput setaf 219 )
GREEN=$( tput setaf 83 )
	
trap sigintHandler SIGINT
trap cleanup EXIT

banner
tput civis
main "${@}"
tput cnorm
