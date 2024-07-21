#!/usr/bin/env bash

sigintHandler(){
	printf >&2 \
		"\n%s[!] SIGINT Signal sent to %s%s\n" \
		"${RED}" "${0##*/}" "${RESET}"

	tput cnorm
	trap - SIGINT
	kill -INT "$$"
}

userTable(){
	cat << TABLE
${BLUE}
╔══════════════════════════╗
║           User           ║
╠══════════════════════════╣
  ${1} 
╚══════════════════════════╝
╔══════════════════════════╗
║         Password         ║
╠══════════════════════════╣
  ${2}
╚══════════════════════════╝
TABLE
}

secretKeyTable(){
	cat << TABLE
${BLUE}
╔═══════════════════════════════════════╗
║        	Secret Key        	║
╠═══════════════════════════════════════╣
  ${1} 
╚═══════════════════════════════════════╝
TABLE
}

memInfoTable(){

	cat << TABLE
${BLUE}
╔══════════════════════════╗
║          MemInfo         ║
╠══════════════════════════╣
║ MemTotal -> ${1}GB
║══════════════════════════║
╠══════════════════════════╣
║ SwapTotal -> ${2}GB
║══════════════════════════║
╠══════════════════════════╣
║ Buffers -> ${3}MB
║══════════════════════════║
╠══════════════════════════╣
║ Swappiness -> ${4}
╚══════════════════════════╝
${RESET}
TABLE

}

mySQLConfigFileTable(){
	cat << TABLE
${BLUE}
╔═════════════════════════════════════════╗
║           Configuration File        	  ║	
╠═════════════════════════════════════════╣
  ${1} 
╚═════════════════════════════════════════╝ ${RESET}
TABLE
}

table(){
	cat << TABLE
	${PINK}
	    //===========================================\\
			${1}
	    \\===========================================// ${RESET}
TABLE
}

banner(){
	cat << BANNER

	${PURPLE}
        ██████╗ ██████╗ ███████╗██████╗  █████╗ ██████╗ ███████╗
        ██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝
        ██████╔╝██████╔╝█████╗  ██████╔╝███████║██████╔╝█████╗
        ██╔═══╝ ██╔══██╗██╔══╝  ██╔═══╝ ██╔══██║██╔══██╗██╔══╝
        ██║     ██║  ██║███████╗██║     ██║  ██║██║  ██║███████╗
        ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝ 
	╭━─━─━─≪✠≫─━─━─━━─━─━─≪✠≫─━─━─━━─━─━─≪✠≫─━─━─━━─━─━─≪✠≫╮
	╰━─━─━─≪✠≫─━─━─━━─━─━─≪✠≫─━─━─━━─━─━─≪✠≫─━─━─━━─━─━─≪✠≫╯ ${RESET}
BANNER
}

showHelp(){
	cat << HELP 
	${PINK}
	DESCRIPTION: --

	USAGE: ${0##*/} [-h|-c|-r] [--help|--run|--check] ${RESET}

	${PURPLE}OPTIONS:
	
		-c | --check -> ...
		-r | --run -> ...
		-h | --help -> Displays this help :) ${RESET}

HELP
}

systemdChecker(){
	local _PID1=$(cat /proc/1/comm)

	printf \
		"\n%s[+] Checking if System has been initialized with SystemD (PID 1)%s\n" \
		"${BLUE}" "${RESET}"
	
	[[ $_PID1 == systemd ]] || { printf >&2 \
					"%s[!] System initialized with %s instead of Systemd. Not supported :( %s\n\n" \
					"${RED}" "${_PID1}" "${RESET}"

				   return 1 ; }
	printf \
		"%s[+] System initialized with %s :) %s\n" \
		"${GREEN}" "${_PID1}" "${RESET}"

	return 0
}

pleskChecker(){
	local _hostname=$(hostname --fqdn)

	printf \
		"\n%s[+] Checking if Plesk Binary is installed %s\n" \
		"${BLUE}" "${RESET}"

	command -V plesk &> /dev/null || { \

		printf >&2 \
			"%s[!] Plesk Binary not installed on %s %s\n" \
			"${RED}" "${_hostname}" "${RESET}"
		return 1 ; }
	
	printf \
		"%s[+] Plesk Binary installed on %s %s\n" \
		"${GREEN}" "${_hostname}" "${RESET}"

	printf \
		"%s[+] Checking if psa.service is Active/Running...%s\n" \
		"${BLUE}" "${RESET}"

	systemctl &> /dev/null \
		--quiet \
		is-active psa.service || { \

			printf >&2 \
				"%s[!] Psa.service not Active/Running in %s %s\n" \
				"${RED}" "${_hostname}" "${RESET}"
			return 1 ; }
	printf \
		"%s[+] Psa.service is Active/Running in %s %s\n" \
		"${GREEN}" "${_hostname}" "${RESET}"

	printf \
		"\n%s[+] Testing %s:8443 Connection on %s %s\n" \
		"${BLUE}" "${_ip}" "${_hostname}" "${RESET}"

	timeout 1 bash -c \
			"echo '' > /dev/tcp/localhost/8443" &> /dev/null || {
				printf >&2 \
					"%s[+] Could not connect to localhost:8443 :(. Seems closed or filtered %s\n" \
					"${RED}" "${RESET}"
				return 1 ; }
	
	printf \
		"%s[+] Connection successfully established to localhost:8443 %s\n" \
		"${GREEN}" "${RESET}"

	return 0
}

checker1(){
	local _service=$1 _binary=$2 _hostname=$(hostname --fqdn)

	[[ -n $_binary ]] && {

		printf \
			"\n%s[+] Checking if %s Binary is installed...%s\n" \
			"${BLUE}" "${_binary}" "${RESET}" \

		command -V "${_binary}" &> /dev/null && {

			printf \
				"%s[+] %s Binary installed %s\n" \
				"${GREEN}" "${_binary}" "${RESET}"
		} || {
			printf >&2 \
				"%s[!] %s Binary not installed on %s %s\n" \
				"${RED}" "${_binary}" "${_hostname}" "${RESET}"
		}
	}

	printf \
		"%s[+] Checking if %s is active/running...%s\n" \
		"${BLUE}" "${_service}" "${RESET}"

	command -V systemctl &>/dev/null && \
	systemctl --quiet \
		  is-active \
		  2> /dev/null "${_service}" && {
	
		printf \
			"%s[+] %s is Active/Running %s\n" \
			"${GREEN}" "${_service}" "${RESET}"

	} || { printf >&2 \
			"%s[!] %s is not active or running on %s %s\n" \
			"${RED}" "${_service}" "${_hostname}" "${RESET}"
	     return 1 ; }
		
	
	return 0 # Binary installed and Service Active / Running
}

checker2(){
	local _service=$1 _binary=$2

		printf \
			"%s[+] Checking if %s Binary related to %s is installed...%s\n" \
			"${BLUE}" "${_binary}" "${_service}" "${RESET}"
		
		if command -V "${_binary}" &> /dev/null; then

			printf \
				"%s[+] %s Binary installed %s\n" \
				"${GREEN}" "${_binary}" "${RESET}"
			printf \
				"%s[+] Checking if %s is active/running...%s\n" \
				"${BLUE}" "${_service}" "${RESET}"

			grep --ignore-case \
			     --perl-regexp \
			     --quiet \
			     "${_service}" < <( systemctl list-unit-files \
							  --type=service \
							  --no-pager
					      ) && { printf \
								"%s[+] %s is Active/Running %s\n" \
								"${GREEN}" "${_service}" "${RESET}"
						     return 0
						     
					      } || { printf >&2 \
								"%s[!] %s is not active or running on %s %s\n" \
								"${RED}" "${_service}" "${_hostname}" "${RESET}"

						     return 1 ; }						# If Binary = 0 and Service != 0
		else
			printf >&2 \
				"%s[!] %s Binary not installed on %s %s \n" \
				"${RED}" "${_binary}" "${_hostname}" "${RESET}"

			return 1	 									# If Binary != 0 directly

		fi
}

checkService(){
	local _service
	local -A serviceBinary=(
		
		[sshd.service]="sshd"
		[postfix.service]="/usr/lib/postfix/sbin/master" 
		[mysqld.service]="mysqld" 				# Mariadb.service
		[dovecot.service]="dovecot"
		[nginx.service]="nginx"
		[apache2.service]="apache2"
	)

	for _service in "${!serviceBinary[@]}"; do
		
		checker1 "${_service}" "${serviceBinary[${_service}]}" && continue || return 1
	done

	return 0
}

checkTools(){
	local _tool
	local -a tools=(
		
		curl
		base64
		jq
		mail
		mailx
		apt
		fallocate
		mkswap
		swapon
	)

	printf \
		"\n%s[+] Checking if required tools (Binaries) are installed...%s\n" \
		"${BLUE}" "${RESET}"

	for _tool in "${tools[@]}"; do

		command -V "${_tool}" &> /dev/null && { printf \
								"%s[+] Binary: %s -> Status: Installed %s \n" \
								"${GREEN}" "${_tool}" "${RESET}"
							continue
		} || { printf >&2 \
				"%s[!] %s Binary is not installed %s\n" \
				"${RED}" "${_tool}" "${RESET}"

		     printf >&2 \
				"%s[!] Try to install it with your system's own package manager %s\n" \
				"${BLUE}" "${RESET}"

		     return 1 ; }
	done

	return 0
}

credsConversion(){
	local _authString=$(			# Base64 conversion from user:password format
		base64 < <( printf \
				"%s:%s" \
				"${1}" "${2}" ) # Plesk User and Password
	)

	printf \
		"%s\n" \
		"${_authString}"
}

checkPleskCreds(){
	local _apiEndpoint="https://localhost:8443/api/v2/server"	
	local _authString=$( credsConversion "${1}" "${2}" )

	local checkAuthReq=$(
		
		curl --silent \
		     --output /dev/null \
		     --write-out '%{http_code}\n' \
		     --request GET \
		     --insecure \
		     --header "Authorization: Basic ${_authString}" \
		     "${_apiEndpoint}"
	)

	printf \
		"\n%s[+] Checking Plesk Credentials provided via API REST through https://localhost:8443/api/v2/server %s\n" \
		"${BLUE}" "${RESET}"

	(( $checkAuthReq != 200 )) && { 

		printf >&2 \
			"\n%s[!] Plesk Authentication via API REST failed :( . HTTP Status Code: %s %s\n" \
			"${RED}" "${checkAuthReq}" "${RESET}"

		[[ $checkAuthReq == 4* ]] && printf >&2 \
							"%s[!] Check Plesk credentials. Maybe creds are wrong :( %s\n" \
							"${PURPLE}" "${RESET}"
		[[ $checkAuthReq == 5* ]] && printf >&2 \
							"%s[!] Check System Services related to Plesk %s \n\n" \
							"${PURPLE}" "${RESET}"

		return 1
	}

	printf \
		"%s[+] Successfully Plesk Authentication via API REST :). Hands on!! %s\n" \
		"${GREEN}" "${RESET}"

	return 0

}

generatePleskAPIKey(){
	local _authString=$( credsConversion "${1}" "${2}" )	
	local _apiEndpoint="https://localhost:8443/api/v2/auth/keys"	# Api Endpoint to generate Secret Keys

	local createKeyReq=$(

		curl --silent \
		     --write-out '%{json}' \
		     --insecure \
		     --request POST \
		     --header "Authorization: Basic ${_authString}" \
		     --header "Accept: application/json" \
		     --header "Content-Type: application/json" \
		     --data "{}" \
		     "${_apiEndpoint}"
	)

	local httpStatusCode=$( 

		{ jq .http_code | grep -vi null ; } <<< "${createKeyReq}"
	)

	printf >&2 \
		"\n%s[+] Generating Plesk API REST's Secret Key for Admin User... %s\n" \
		"${BLUE}" "${RESET}"
	
	(( $httpStatusCode != 201 )) && {

		printf >&2 \
			"\n%s[!] Error creating API REST Secret Key. HTTP Status Code: %s %s\n" \
			"${RED}" "${httpStatusCode}" "${RESET}"

		  return 1
	}

	local apiSecretKey=$(

		{ jq .key | grep -iPom 1 '\"\K[^\"]*' ; } <<< "${createKeyReq}"
	)

	[[ -n $apiSecretKey ]] && printf >&2 \
					"%s[+] Plesk API REST's Secret Key Generated correctly -> %s %s\n" \
					"${GREEN}" "${apiSecretKey}" "${RESET}"

	printf "%s\n" "${apiSecretKey}"

}

pleskEmailSecurity(){
	local _pleskSecretKey="${1}" _extensionID="email-security"
	local _hostname=$(hostname --fqdn)
	local _apiEndpointCheck="https://localhost:8443/api/v2/extensions/${_extensionID}" # Information about an Specific Plesk Extension
	local _apiEndpointInstall="https://localhost:8443/api/v2/extensions" # Plesk Extension Installation

	printf \
		"\n%s[+] Checking if Plesk Email Security Extension is installed...%s\n" \
		"${BLUE}" "${RESET}"
	
	local checkExtensionReq=$(

		curl --silent \
		     --output /dev/null \
		     --write-out '%{http_code}\n' \
		     --request GET \
		     --insecure \
		     --header "X-API-Key: ${_pleskSecretKey}" \
		     "${_apiEndpointCheck}"
	)

	(( $checkExtensionReq == 200 )) && { \
		
		printf \
			"%s[+] Plesk Email Security Plesk Extension seems already installed on %s %s\n" \
			"${GREEN}" "${_hostname}" "${RESET}"

	} || { printf >&2 \
			"%s[!] Plesk Email Security Extension not installed on %s. API REST HTTP Status Code -> %s %s \n" \
			"${RED}" "${_hostname}" "${checkExtensionReq}" "${RESET}"

	       printf \
			"%s[+] Installing Plesk Email Security...%s\n" \
			"${BLUE}" "${RESET}"
			
	       local installExtensionReq=$(

			curl --silent \
			     --output /dev/null \
			     --write-out '%{http_code}\n' \
			     --request POST \
			     --insecure \
			     --header "X-API-Key: ${_pleskSecretKey}" \
			     --header 'Accept: application/json' \
			     --header 'Content-Type: application/json' \
			     --data "{ \"id\" : \"${_extensionID}\" }" \
			     "${_apiEndpointInstall}"
			)

		(( $installExtensionReq == 200 )) && printf \
							"%s[+] Plesk Email Security Extension seems correctly installed %s\n" \
							"${GREEN}" "${RESET}"
	}

	printf \
		"%s[+] Checking if Extension was correctly installed... %s\n" \
		"${BLUE}" "${RESET}"

	local checkExtensionReq=$(

		curl --silent \
		     --output /dev/null \
		     --write-out '%{http_code}\n' \
		     --request GET \
		     --insecure \
		     --header "X-API-Key: ${_pleskSecretKey}" \
		     "${_apiEndpointCheck}"
	)

	if (( $checkExtensionReq == 200 )); then

		local _service
		local -A _serviceBinary=(
			
			[amavis.service]="amavisd"
			[spamassassin.service]="spamd"
		)

		printf \
			"%s[+] Plesk Email Security Extension successfully installed on %s %s\n" \
			"${GREEN}" "${_hostname}" "${RESET}"

		while : ; do

			printf \
				"\n%s[!] Warning !! User interaction Needed... %s\n" \
				"${PURPLE}" "${RESET}"
			
			printf \
				"%s[!] If this is First Execution, perform the following instructions. Otherwise, Press Enter directly %s\n" \
				"${PURPLE}" "${RESET}"

			printf \
				"%s[!] Log into Plesk and Select \"Install Now!\" on Extensions > My Extensions > Plesk Email Security ( Open ) %s\n" \
				"${PURPLE}" "${RESET}"

			read -p \
				"${PURPLE}[!] Press Enter when required previous actions are done ${RESET}"

			# Checking if Amavis / SpamAssassin Binary and Service are installed

			printf \
				"\n%s[+] Checking Binaries and Services installed by Plesk Email Security...%s\n" \
				"${BLUE}" "${RESET}"

			for _service in "${!_serviceBinary[@]}"; do

				local error=0

				checker2 "${_service}" "${_serviceBinary[${_service}]}" && continue || { 

					[[ $_service == "spamassassin.service" ]] && {

						checker2 "spamd.service" "spamd" && continue
					}

					[[ $_service == "amavis.service" ]] && {

						checker2 "${_service}" "amavisd-new" && continue
					}

					(( error++ )) ; break
				}
			done

			(( $error == 1 )) && { printf >&2 \
							"%s[!] Try again previous steps about Plesk Email Security on Plesk UI %s\n" \
							"${RED}" "${RESET}"
					       continue; }
			
			# Checking if Perl Binary is installed ( Required by amavis.service and spamassassin.service
			
			printf \
				"%s[!] Perl Binary is necessary as interpreter to execute Previous Binary's services...%s\n" \
				"${PURPLE}" "${RESET}"

			printf \
				"%s[+] Checking is Perl Binary is installed on %s... %s\n" \
				"${BLUE}" "${_hostname}" "${RESET}"

			if command -V perl &> /dev/null; then

				printf \
					"%s[+] Perl Binary installed on %s :) %s\n" \
					"${GREEN}" "${_hostname}" "${RESET}"
				break 												# End Loop
			else
				printf >&2 \
					"%s[!] Perl Binary not installed on %s :( . Try to install it with your system's own package manager %s\n" \
					"${RED}" "${_hostname}" "${RESET}"
				return 1
			fi

		done

		return 0
	else

		printf >&2 \
			"%s[!] Could not install Plesk Email Security Extension :( . Check this HTTP Status Code %s %s\n" \
			"${RED}" "${checkExtensionReq}" "${RESET}"

		return 1
	fi
}

amavisdSpamdChecker(){
	local _service _index _hostname=$(hostname --fqdn) _logFile=$(mktemp --suffix=log)
	local _perlLibrary="libdbd-mysql-perl" _spamdService="spamd.service"
	local -A _services=(
		
		[spamassassin.service]=""
		[amavis.service]=""
	)	

	printf \
		"\n%s[!] Warning: It may be necessary to install Amavis Perl Library ( %s ) %s\n" \
		"${PURPLE}" "${_perlLibrary}" "${RESET}"
	
	# spamassassin.service | spamd.service

	for _service in "${!_services[@]}"; do

	printf \
		"%s[+] Checking if %s is Active / Running...%s\n" \
		"${BLUE}" "${_service}" "${RESET}"

		if systemctl --quiet is-active "${_service}" 2> /dev/null; then

			printf \
				"%s[+] %s is Active / Running on %s %s\n" \
				"${GREEN}" "${_service}" "${_hostname}" "${RESET}"
		else
			printf >&2 \
				"%s[!] %s is not Active / Running on %s %s\n" \
				"${RED}" "${_service}" "${_hostname}" "${RESET}"

			[[ $_service == "spamassassin.service" ]] && {

				printf \
					"%s[+] Checking if %s exists on %s instead of %s...%s\n" \
					"${BLUE}" "${_spamdService}" "${_hostname}" "${_service}" "${RESET}"

				grep --quiet \
				     --ignore-case \
				     --perl-regexp \
				     ".*${_spamdService}.*" <( systemctl list-unit-files \
				     				         --all \
				     				         --type=service \
								         --no-pager \
								         --no-legend 
							     )
				(( $? == 0 )) && {

					unset _services["${_service}"] && _services["${_spamdService}"]=""
					_service="${_spamdService}"

					printf \
						"%s[+] %s is installed on %s %s\n" \
						"${GREEN}" "${_service}" "${_hostname}" "${RESET}"

					printf \
						"%s[+] Checking if %s is Active / Running on %s...%s\n" \
						"${BLUE}" "${_service}" "${_hostname}" "${RESET}"
					
					systemctl --quiet is-active "${_service}" 2> /dev/null && {

						printf \
							"%s[+] %s is Active / Running on %s %s\n" \
							"${GREEN}" "${_service}" "${_hostname}" "${RESET}"
					} || {
						printf >&2 \
							"%s[!] %s in not Active / Running on %s %s\n" \
							"${RED}" "${_service}" "${_hostname}" "${RESET}"
					}
				} || {
					printf >&2 \
						"%s[!] %s is not installed on %s %s\n" \
						"${RED}" "${_spamdService}" "${_hostname}" "${RESET}"
				}

			}

			[[ $_service == "amavis.service" ]] && {

				printf \
					"%s[!] %s seems down due to lack of package dependencies ( %s ) %s\n" \
					"${RED}" "${_service}" "${_perlLibrary}" "${RESET}"

				printf \
					"%s[+] Trying to install %s Package... %s\n" \
					"${BLUE}" "${_perlLibrary}" "${RESET}"

				printf \
					"%s[+] Updating %s system repositories...%s\n" \
					"${BLUE}" "${_hostname}" "${RESET}"
				
				printf \
					"\n[+] APT UPDATE LOG -> \n" \
					> "${_logFile}"

				apt update &>> "${_logFile}" && { printf \
									"%s[+] APT Repositories updated correctly :) %s\n" \
									"${GREEN}" "${RESET}"

								} || { printf >&2 \
										"%s[!] Something went wrong updating repositories :( %s\n" \
										"${RED}" "${RESET}"
								       printf \
										"%s[+] Check Output on %s %s\n" \
										"${PURPLE}" "${_logFile}" "${RESET}"

								       return 1 ; }
				printf \
					"%s[+] Trying to install %s Package via APT...%s\n" \
					"${BLUE}" "${_perlLibrary}" "${RESET}"
				printf \
					"\n[+] APT INSTALL %s LOG -> \n" \
					"${_perlLibrary}" \
					>> "${_logFile}"

				apt install \
					--assume-yes \
					"${_perlLibrary}" \
					&> "${_logFile}" && { printf \
									"%s[+] %s Package installed correctly :) %s\n" \
									"${GREEN}" "${_perlLibrary}" "${RESET}"

							    } || { printf >&2 \
										"%s[!] Something went wrong installing %s Package :( %s\n" \
										"${RED}" "${_perlLibrary}" "${RESET}"
								       printf \
										"%s[+] Check Output on %s %s\n" \
										"${PURPLE}" "${_logFile}" "${RESET}"

								       return 1 ; }
			}

			printf \
				"%s[+] Trying to Run correctly %s... %s\n" \
				"${BLUE}" "${_service}" "${RESET}"

			systemctl --quiet restart "${_service}" 2> /dev/null || { printf >&2 \
											"%s[!] Could not start %s :( . Try journalctl -rxu %s %s\n" \
											"${RED}" "${_service}" "${_service}" "${RESET}"
								      		  return 1 ; } 
			printf \
				"%s[+] %s started :) %s\n" \
				"${GREEN}" "${_service}" "${RESET}"
		fi	

	done

		printf \
			"%s[+] Checking if sa-update Binary is installed on %s %s \n"\
			"${BLUE}" "${_hostname}" "${RESET}"

		if command -V sa-update &> /dev/null; then

			printf \
				"%s[+] sa-update Binary related to spamAssassin.service is installed %s\n" \
				"${GREEN}" "${RESET}"

			printf \
				"%s[+] Updating SpamAssassin's Rules Definitions %s\n" \
				"${BLUE}" "${RESET}"	

			sa-update &> /dev/null && { \

				printf \
					"%s[+] SpamAssassin's Rules Updated successfully %s\n" \
					"${GREEN}" "${RESET}"

			} || printf >&2 \
					"%s[!] Could not Update SpamAssassin's Rules :( . Try sa-update Binary on your own... %s\n" \
					"${RED}" "${RESET}"
		else
			printf >&2 \
				"%s[!] sa-update Binary related to spamAssassin.service not installed %s. Try install it manually\n" \
				"${RED}" "${RESET}"
		fi

		printf \
			"%s[+] Restarting postfix.service to apply new changes...%s \n" \
			"${BLUE}" "${RESET}"

		if systemctl --quiet restart postfix.service 2> /dev/null ; then
			
			printf \
				"%s[+] Postfix.service restarted correctly %s\n" \
				"${GREEN}" "${RESET}"
		else
			printf >&2 \
				"%s[!] Something went wrong trying to restart postfix.service. Check Journalctl's Service %s\n" \
				"${RED}" "${RESET}"
			return 1
		fi

	for _service in "${!_services[@]}"; do

		printf \
			"%s[+] Checking if %s is Enabled... %s\n" \
			"${BLUE}" "${_service}" "${RESET}"
		
		if systemctl --quiet is-enabled "${_service}" 2> /dev/null ; then

			printf \
				"%s[+] %s is Enabled on %s %s\n" \
				"${GREEN}" "${_service}" "${_hostname}" "${RESET}"

		else
			printf >&2 \
				"%s[!] %s is not Enabled on %s %s\n" \
				"${RED}" "${_service}" "${_hostname}" "${RESET}"

			printf \
				"%s[+] Trying to enable %s... %s\n" \
				"${BLUE}" "${_service}" "${RESET}"

			systemctl --quiet enable "${_service}" 2> /dev/null || { 

				printf >&2 \
					"%s[!] Could not enable %s :( . Try journalctl -rxu %s %s\n" \
					"${RED}" "${_service}" "${_service}" "${RESET}"

				return 1
		        } 

			printf \
				"%s[+] %s enabled :) %s\n" \
				"${GREEN}" "${_service}" "${RESET}"
		fi	
	done

	
	return 0
}


getMemoryInfo(){
	local _hostname=$(hostname --fqdn) _memInfoFile="/proc/meminfo"
	local _memTotal _swapTotal _buffers _swappiness=$( cat /proc/sys/vm/swappiness )
	local -A _memInfo=()


	while IFS=": " read -r key value _ ; do

		[[ -n $key ]] && _memInfo[${key}]=${value}

	done < "${_memInfoFile}"

	_memTotal=$( awk '{ printf "%.2f\n", \
			    $1 / ( $2 * $2 ) }' <<< "${_memInfo[MemTotal]} 1024" )

	_swapTotal=$( awk '{ printf "%.2f\n", \
			    $1 / ( $2 * $2 ) }' <<< "${_memInfo[SwapTotal]} 1024" )
	
	_buffers=$( awk '{ printf "%.2f\n", \
			    $1 / $2 }' <<< "${_memInfo[Buffers]} 1024" )

	memInfoTable "${_memTotal}" "${_swapTotal}" "${_buffers}" "${_swappiness}" >&2	# Print Table with Memory Values -> FD 2

	printf  >&2 \
		"%s[+] System Memory Values on %s extracted correctly...%s\n" \
		"${BLUE}" "${_hostname}" "${RESET}"

	printf "%s %s %s" "${_memTotal}" "${_swapTotal}" "${_buffers}"			# Return Memory values -> FD 1

}

setFSTabSwapFile(){
	local _swapFile=$1 _fstabFile="/etc/fstab" _swapString=( "\n${_swapFile} swap swap defaults 0 0\n" )

	printf \
		"\n%s[+] Adding Swap File's Line ( %s ) to %s...%s\n" \
		"${BLUE}" "${_swapFile}" "${_fstabFile}" "${RESET}"

	{ [[ -e $_fstabFile ]] && printf \
					"${_swapString[@]}" \
					>> "${_fstabFile}" ; }
	printf \
		"%s[+] Checking if Swap File's Line has been added correctly...%s\n" \
		"${BLUE}" "${RESET}"

	grep --quiet \
   	     --ignore-case \
	     --perl-regexp \
	     "^${_swapString[@]//\\n/}$" \
	     "${_fstabFile}"

	(( $? == 0 )) && {

		printf \
			"%s[+] Line related to Swap File %s -> ( %s ) added on %s :) %s\n" \
			"${GREEN}" "${_swapFile}" "${_swapString[@]//\\n/}" "${_fstabFile}" "${RESET}"

		return 0

	} || { 
		printf >&2 \
			"%s[!] Swap's Line could not be added to %s . Check %s File %s\n" \
			"${RED}" "${_fstabFile}" "${_fstabFile}" "${RESET}"

		printf \
		       "%s[!] Note: Remember that System is making use of a Temporary and Volatile Swap %s\n" \
		       "${PURPLE}" "${RESET}"

		return 1
	}
}

deleteFSTabSwapPartitionLines(){
	local _fstabFile="/etc/fstab"

	grep --quiet \
	     --ignore-case \
	     --perl-regexp \
	     '^(UUID\=[\w-]+|/dev/[^\s]+)\s+(none|swap|(/[^\s]+)+)\s+swap.*$' \
	     "${_fstabFile}"

	(( $? != 0 )) && {

		printf >&2 \
			"\n%s[!] Swap Partition's Line[s] not found on %s %s\n" \
			"${PURPLE}" "${_fstabFile}" "${RESET}"

		return 0
	}

	printf \
		"\n%s[+] Deleting Swap Partition Lines on %s...%s\n" \
		"${BLUE}" "${_fstabFile}" "${RESET}"

	sed --regexp-extended \
	    --in-place \
	    '/^(UUID\=[a-zA-Z0-9-]+|\/dev\/[a-zA-Z0-9\-_]+)\s+(none|swap|(\/[a-zA-Z0-9\-_]+)+)\s+swap.*$/d' \
	    "${_fstabFile}"
	    2> /dev/null

	(( $? == 0 )) && {

		grep --quiet \
		     --ignore-case \
		     --perl-regexp \
		     '^(UUID\=[\w-]+|/dev/[^\s]+)\s+(none|swap|(/[^\s]+)+)\s+swap.*$' \
		     "${_fstabFile}"

		if (( $? != 0 )) ; then

			printf \
				"%s[+] Swap Partition Lines deleted correctly on %s :) %s\n" \
				"${GREEN}" "${_fstabFile}" "${RESET}"

			return 0
		else
			printf >&2 \
				"%s[+] Could not delete previous lines mentioned :( %s\n" \
				"${RED}" "${RESET}"

			return 0
		fi

	} || {

		printf >&2 \
			"%s[!] Something went wrong trying to delete previous lines mentioned :( %s\n" \
			"${RED}" "${RESET}"

		return 1
	}
}

deleteFSTabSwapFileLines(){
	local _fstabFile="/etc/fstab"

	printf \
		"\n%s[+] Proceeding to delete Swap File's Line[s] on %s...%s\n" \
		"${BLUE}" "${_fstabFile}" "${RESET}"

	sed --regexp-extended \
	    --in-place \
	    '/^\/dev(\/[a-zA-Z0-9\-_]+)+/! { /^(\/[a-zA-Z0-9]+)\s+(swap|none)\s+swap.*$/ d }' \
	    "${_fstabFile}"
	    2> /dev/null

	if (( $? == 0 )) ; then

		printf \
			"%s[+] It seems like previous line[s] mentioned have been deleted...%s\n" \
			"${BLUE}" "${RESET}"

		printf \
			"%s[+] Checking Existence of that Line[s] on %s...%s\n" \
			"${BLUE}" "${_fstabFile}" "${RESET}"
		
		grep --quiet \
		     --ignore-case \
		     --perl-regexp \
		     '^(?!/dev)(/[^\s]+)\s+(none|swap)\s+swap.*$' \
		     "${_fstabFile}"

		(( $? != 0 )) && {

			printf \
				"%s[+] Swap File's Line[s] deleted correctly :) on %s %s\n" \
				"${GREEN}" "${_fstabFile}" "${RESET}"

			return 0

		} || {
			printf >&2 \
				"%s[+] Could not delete Swap File's Line[s] on %s :( %s\n " \
				"${RED}" "${_fstabFile}" "${RESET}"
		}

	else
		printf >&2 \
			"%s[!] Something went wrong trying to delete previous lines mentioned :( %s\n" \
			"${RED}" "${RESET}"
		
		return 1
	fi
}

createSwap(){
	local _swapSize=$1 _swapFile=$2 _mode=$3 _hostname=$(hostname --fqdn) _sysctlFile="/etc/sysctl.conf" _swappiness
	local _swappinessFile="/proc/sys/vm/swappiness" _fstabFile="/etc/fstab"

	printf \
		"\n%s[+] Creating Swap File...%s \n" \
		"${BLUE}" "${RESET}"

	fallocate -l "${_swapSize}G" "${_swapFile}" &> /dev/null && { 

		printf \
			"%s[+] SwapFile created with %sG Size as %s %s \n" \
			"${GREEN}" "${_swapSize}" "${_swapFile}" "${RESET}"

		chmod 600 "${_swapFile}" || return 1 && printf \
								"%s[+] 600 Perms assigned correctly to %s %s\n" \
								"${GREEN}" "${_swapFile}" "${RESET}"
		} || {
			printf >&2 \
				"%s[!] Error trying to create %s ( TraceBack -> Error on fallocate command ) %s \n" \
				"${RED}" "${_swapFile}" "${RESET}"

			return 1 
	       }

	printf \
		"%s[+] Preparing %s to be used as Swap...%s \n" \
		"${BLUE}" "${_swapFile}" "${RESET}"

	if mkswap "${_swapFile}" &> /dev/null ; then

		printf \
			"%s[+] %s seems prepared as Swap correctly %s \n" \
			"${GREEN}" "${_swapFile}" "${RESET}"
	else
		printf >&2 \
			"%s[!] Something went wrong preparing %s as Swap :( ( TraceBack -> Error on mkswap command )%s\n" \
			"${RED}" "${_swapFile}" "${RESET}"
		return 1
	fi

	printf \
		"%s[+] Activating Swap File...%s\n" \
		"${BLUE}" "${RESET}"

	swapon "${_swapFile}" &> /dev/null && {
		
		printf \
			"%s[+] Swap File seems enabled :) %s\n" \
			"${GREEN}" "${RESET}"
	} || { 
		printf >&2 \
			"%s[!] Could not enable Swap File :( %s\n" \
			"${RED}" "${RESET}"
	       return 1
	}

	printf \
		"\n%s[+] Checking if Swap's Line[s] related to Swap File or Partition exists on %s file...%s\n" \
		"${BLUE}" "${_fstabFile}" "${RESET}"

	grep --quiet \
	     --ignore-case \
	     --perl-regexp \
	     '^(.+\s){2}swap\s.*$' \
	     "${_fstabFile}"

	if (( $? == 0 )) ; then

		printf \
			"%s[+] Swap's Line[s] related to Swap File or Partition exist[s] %s\n" \
			"${PURPLE}" "${RESET}"

		printf \
			"%s[+] Checking if that/those line[s] correspond[s] to a Swap File...%s\n" \
			"${BLUE}" "${RESET}"

		grep --quiet \
		     --ignore-case \
		     --perl-regexp \
		     '^(?!/dev)(/[^\s]+)\s+(none|swap)\s+swap.*$' \
		     "${_fstabFile}"

		(( $? == 0 )) && {

			printf \
				"%s[+] Swap File's Line[s] found on %s %s\n" \
				"${PURPLE}" "${_fstabFile}" "${RESET}"

			[[ -n $_mode ]] && {

				(( $_mode == 3 )) && {

					printf \
						"\n%s[+] First of all, Let's delete Swap Partitions' Line[s] if they exist %s\n" \
						"${BLUE}" "${RESET}"

					deleteFSTabSwapPartitionLines || return 1
						
					deleteFSTabSwapFileLines || return 1
				}	

				setFSTabSwapFile "${_swapFile}"
			}

		} || {
			printf >&2 \
				"%s[+] Swap File's Line not found on %s %s\n" \
				"${RED}" "${_fstabFile}" "${RESET}"

			printf \
				"%s[+] Existing Swap's Line[s] on %s are related to Partitions Then%s\n" \
				"${PURPLE}" "${_fstabFile}" "${RESET}"

			[[ -n $_mode ]] && {

				(( $_mode == 3 )) && { deleteFSTabSwapPartitionLines || return 1 ; }

				setFSTabSwapFile "${_swapFile}"
			}
		}

	else
		printf >&2 \
			"%s[!] Previously mentioned Swap Line does not exist %s\n " \
			"${RED}" "${RESET}"

		setFSTabSwapFile "${_swapFile}"
	fi


	printf \
		"\n%s[+] Checking System's Swappiness Value...%s \n" \
		"${BLUE}" "${RESET}"

	[[ -e $_sysctlFile && -e $_swappinessFile ]] && { \

		grep --quiet \
	    	     --ignore-case \
	    	     --perl-regexp \
	    	     '^vm\.swappiness\=\d{1,3}' \
	    	     "${_sysctlFile}"
		
		if (( $? != 0 )) ; then

			printf >&2 \
				"%s[!] Swappiness Parameter not found on %s file %s\n" \
				"${RED}" "${_sysctlFile}" "${RESET}"
			printf \
				"%s[+] Adding Swappinness Parameter to %s file...%s\n" \
				"${BLUE}" "${_sysctlFile}" "${RESET}"
			printf \
				"\nvm.swappiness=10\n" \
				>> "${_sysctlFile}"
			
			(( $? == 0 )) && {

				sysctl --load &> /dev/null && {

					printf \
						"%s[+] Swappiness Parameter seems configured correctly %s\n" \
						"${GREEN}" "${RESET}"
				} || {
					printf >&2 \
						"%s[!] Could not configure Swappiness Parameter correctly :( . Try it manually%s\n" \
						"${RED}" "${RESET}"
				}
			}
		else
			printf \
				"%s[+] Swappiness Parameter found on %s file %s\n" \
				"${GREEN}" "${_sysctlFile}" "${RESET}"

			printf \
				"%s[+] Checking if Swappiness Parameter's Value is 10...%s\n" \
				"${BLUE}" "${RESET}"

			grep --quiet \
			     --ignore-case \
			     --perl-regexp \
			     '^vm\.swappiness=10$' \
			     "${_sysctlFile}"
			
			(( $? != 0 )) && {

				printf >&2 \
					"%s[+] Swappiness Parameter's Value is different from ideal value ( 10 ) %s\n" \
					"${RED}" "${RESET}"

				printf \
					"%s[+] Modifying Swappiness Parameter on %s...%s\n" \
					"${BLUE}" "${_sysctlFile}" "${RESET}"
				
				{ sed --regexp-extended \
				    --in-place \
				    's@(^vm\.swappiness=)[0-9]{1,3}@\110@g' \
				    "${_sysctlFile}" && \

				sysctl --load &> /dev/null ; }

				(( $? == 0 )) && { 

					printf \
						"%s[+] Seems like Swappiness Parameter was modified on %s %s \n" \
						"${GREEN}" "${_sysctlFile}" "${RESET}"

				} || {
					printf >&2 \
						"%s[!] Unable to modify Swappiness Parameter :( on %s %s\n" \
						"${RED}" "${_sysctlFile}" "${RESET}"
				}
			} || {
				printf >&2 \
					"%s[+] Swappines Parameter's Value is correct ( 10 ) on %s %s \n" \
					"${GREEN}" "${_sysctlFile}" "${RESET}"
			}

		fi
			printf \
				"%s[+] Checking System's Swappiness Value on %s...%s\n" \
				"${BLUE}" "${_hostname}" "${RESET}"
			
			_swappiness="$( cat ${_swappinessFile} )"		

			(( $_swappiness == 10 )) && { 

				printf \
					"%s[+] Swappiness value on %s -> %s %s\n" \
					"${GREEN}" "${_hostname}" "${_swappiness}" "${RESET}"

			} || printf >&2 \
					"%s[!] Changes related to Swappiness have not been applied correctly on %s %s\n" \
					"${RED}" "${_hostname}" "${RESET}"
	} || printf >&2 \
			"%s[!] Seems like %s or %s file does not exist on %s %s\n" \
			"${RED}" "${_sysctlFile}" "${_swappinessFile}" "${_hostname}" "${RESET}"

	return 0
}

getDiskUsage(){
	local _hostname=$( hostname --long )

	printf \
		"\n%s[+] Checking Disk Usage on %s... %s\n" \
		"${BLUE}" "${_hostname}" "${RESET}"

	_diskUsage=$( awk \
			'/[0-9]{1,3}%/ \
			{ gsub("%", "", $(NF-1)) ; \
			print $(NF-1) }' < <( df -P $PWD )
		    )

	if (( $? == 0 )); then

		printf \
			"%s[+] Disk Usage on %s -> %s%% %s\n" \
			"${PURPLE}" "${_hostname}" "${_diskUsage}" "${RESET}"
		
		printf >&3 "%s\n" "${_diskUsage}"

	else
		printf >&2 \
			"%s[!] An Error occurred while trying to obtain System's Disk Space %s \n" \
			"${RED}" "${RESET}"

		return 1
	fi
}

getSwapExpectedValue(){
	local _memTotal=$1 _hostname=$( hostname --long ) _swapExpectedValue

	[[ -z $_memTotal ]] && {
		
		printf >&2 \
			"%s[!] Not expected value for %s :( %s\n" \
			"${RED}" "${_memTotal}" "${RESET}"

		return 1
	}

	printf \
		"\n%s[+] Getting Swap's Expected Value based on %s's RAM and Currently Allocated Swap Memory...%s\n" \
		"${BLUE}" "${_hostname}" "${RESET}"

	awk ' { exit ( $1 <= 2 ? 0 : 1 ) } ' <<< "${_memTotal}" && {

		_swapExpectedValue=$( awk ' { printf "%.2f\n" , $1 * 2 } ' <<< "${_memTotal}" )
	}

	awk ' { exit ( $1 > 2 && $1 <= 8 ? 0 : 1 ) } ' <<< "${_memTotal}" && {

		_swapExpectedValue=$( awk ' { printf "%.2f\n" , $1 } ' <<< "${_memTotal}" )
	}

	awk ' { exit ( $1 > 8 ? 0 : 1 ) } ' <<< "${_memTotal}" && {

		_swapExpectedValue=$( awk ' { printf "%.2f\n" , 8 } ' <<< "${_memTotal}" )
	}

	printf \
		"%s[+] Swap's Expected Value -> %sG %s\n" \
		"${PURPLE}" "${_swapExpectedValue}" "${RESET}"
	
	printf >&3 "%s\n" "${_swapExpectedValue}"
}

setSwap(){
	local _memTotal=$1 _swapTotal=$2 _swapFile="/swapfile" _swapExpectedValue _diff _num _file
	local _hostname=$( hostname --long )
	local -A _deletedSwapFiles=()

	_swapExpectedValue=$( getSwapExpectedValue "${_memTotal}" 3>&1 1>&2 || return 1 )

	_diff=$( awk ' { printf "%.2f\n" , $1 - $2 } ' <<< "${_swapExpectedValue} ${_swapTotal}" )

	printf \
		"%s[+] Remaining | Excess Swap Value identified on %s -> %sG %s\n" \
		"${PURPLE}" "${_hostname}" "${_diff/-/+}" "${RESET}"

	# MODE 1
	
	awk ' { exit ( $1 >= 1 ? 0 : 1 ) } ' <<< "${_diff}" && {
		
		printf \
			"%s[!] It's Necessary to add more Swap to the existing one ( If any ) ( Necessary -> %sG ) %s\n" \
			"${PURPLE}" "${_diff}" "${RESET}"

		printf \
			"%s[+] Checking if %s exists on %s...%s\n" \
			"${BLUE}" "${_swapFile}" "${_hostname}" "${RESET}"

		[[ -e $_swapFile ]] && {

			printf \
				"%s[+] %s exists on %s %s\n" \
				"${PURPLE}" "${_swapFile}" "${_hostname}" "${RESET}"
			
			for _num in {0..5} ; do

				[[ ! -e ${_swapFile}${_num} ]] && break

				(( $_num == 5 )) && {

					printf >&2 \
						"%s[!] Could not create another Swap File on %s :( %s\n" \
						"${RED}" "${_hostname}" "${RESET}"
					printf \
						"%s[*] Try deleting the existing ones manually and Try Again %s\n" \
						"${PURPLE}" "${RESET}"

					return 1
				}
			done

			createSwap "${_diff}" "${_swapFile}${_num}" "1" && {

				printf >&3 "%s\n" "${_swapFile}${_num}"

				return 0

			} || return 1

		} || {
			printf \
				"%s[!] %s does not exists on %s %s \n" \
				"${PURPLE}" "${_swapFile}" "${_hostname}" "${RESET}"
			
			createSwap "${_diff}" "${_swapFile}" "1" && return 0 || return 1
		}
	}

	# MODE 2

	awk ' { exit ( $1 >= -1 && $1 <= 1 ? 0 : 1 ) } ' <<< "${_diff}" && {

		printf \
			"%s[+] Allocated Swap's Size is aproximately correct :) ( Diff -> %sG ) %s\n" \
			"${GREEN}" "${_diff}" "${RESET}"

		return 10
	}

	# MODE 3

	awk ' { exit ( $1 < -1 ? 0 : 1 ) } ' <<< "${_diff}" && {

		printf >&2 \
			"%s[!] Warning: Allocated Memory is above its optimal value ( %sG ) %s \n" \
			"${PURPLE}" "${_swapExpectedValue}" "${RESET}"

		printf \
			"\n%s[+] Extracting Enabled Swap Files on %s...%s\n" \
			"${BLUE}" "${_hostname}" "${RESET}"

		while read -r _file ; do

			[[ -f $_file ]] && _deletedSwapFiles["${_file}"]=""
			
		done < <(
				awk \
					' { if ( $2 == "file" ) \
					  print $1 } ' <(
								swapon --show \
								       --noheadings \
								       --raw
							)
			)

		printf \
			"%s[+] Disabling all System's Swap ( %sG )...%s\n" \
			"${BLUE}" "${_swapTotal}" "${RESET}"

		swapoff --all &> /dev/null && {

			printf \
				"%s[+] Swap on %s disabled correctly %s\n" \
				"${GREEN}" "${_hostname}" "${RESET}"

			if (( "${#_deletedSwapFiles[@]}" >= 1 )) ; then

				printf \
					"%s[+] Swap Files Found on %s -> %s %s\n" \
					"${PURPLE}" "${_hostname}" "${#_deletedSwapFiles[@]}" "${RESET}"

				for _file in "${!_deletedSwapFiles[@]}" ; do

					printf \
						"\n%s[+] Trying to delete %s...%s\n" \
						"${BLUE}" "${_file}" "${RESET}"

					rm --recursive --force "${_file}" && {

						[[ ! -e $_file ]] && {

							printf \
								"%s[+] %s deleted correctly :) %s\n" \
								"${GREEN}" "${_file}" "${RESET}"
						} || {
							printf >&2 \
								"%s[!] Could not delete %s :( . Try it manually %s\n" \
								"${RED}" "${_file}" "${RESET}"
							
							return 1
						}

					} || {
						printf >&2 \
							"%s[!] An error has occurred trying to delete %s :( . Try it manually %s\n" \
							"${RED}" "${_file}" "${RESET}"
						
						return 1
					}
				done

				cat << TABLE
${BLUE}
╔═════════════════════════════════════════╗
║           Deleted Swap File[s]          ║	
╠═════════════════════════════════════════╣ ${RESET}
TABLE

				for _file in "${!_deletedSwapFiles[@]}" ; do

					printf \
						"%s║  %s %s\n" \
					        "${BLUE}" "${_file}" "${RESET}"

					printf \
						"%s╚═════════════════════════════════════════╝%s\n" \
						"${BLUE}" "${RESET}"
				done

			else
				printf \
					"%s[+] No Swap Files were Found on %s %s\n" \
					"${PURPLE}" "${_hostname}" "${RESET}"
			fi

			createSwap "${_swapExpectedValue}" "${_swapFile}" "3" && return 0 || return 1

		} || {
			printf >&2 \
				"%s[+] Something went wrong trying to disable Swap on %s :( %s\n" \
				"${RED}" "${_hostname}" "${RESET}"

			return 1
		}
	}
}

makeSwap(){
	local _memTotal=$1 _swapTotal=$2 _buffers=$3 _setSwapStatus
	local _diskUsage _swapFile="/swapfile" _hostname=$( hostname --fqdn )
	local _swappiness=$( cat /proc/sys/vm/swappiness )

	_diskUsage=$( getDiskUsage 3>&1 1>&2 || return 1 )

	(( $_diskUsage > 85 )) && { 

		printf >&2 \
			"%s[!] Low Available Disk Space on %s to create Swap File :( . Do some cleanup First %s \n" \
			"${RED}" "${_hostname}" "${RESET}"

		return 1
	} || {
		printf \
			"%s[+] Enough Disk Space on %s for Swap Management :) %s\n" \
			"${GREEN}" "${_hostname}" "${RESET}"
	}

: << COMMENT Recommended Swap Size : 

	<= 2GB RAM -> SWAP = RAM * 2
	   2GB - 8GB RAM -> SWAP = RAM
	 > 8GB RAM -> SWAP = 8GB
COMMENT

	printf \
		"\n%s[+] Preparing Swap Testing on %s...%s\n" \
		"${BLUE}" "${_hostname}" "${RESET}"

	_swapFile=$( setSwap "${_memTotal}" "${_swapTotal}" 3>&1 1>&2 )

	_setSwapStatus=$?

	(( $_setSwapStatus == 10 )) && return 0

	(( $_setSwapStatus == 1 )) && return 1

	[[ -z $_swapFile ]] && _swapFile="/swapfile"

	printf \
		"\n%s[+] Checking if %s has been created correctly on %s...%s\n" \
		"${BLUE}" "${_swapFile}" "${_hostname}" "${RESET}"

	[[ -e $_swapFile ]] && {

		printf \
			"%s[+] %s created correctly on %s :) %s\n" \
			"${GREEN}" "${_swapFile}" "${_hostname}" "${RESET}"
	} || {
		printf >&2 \
			"%s[!] Could not create %s on %s :( %s \n" \
			"${RED}" "${_swapFile}" "${_hostname}" "${RESET}"

		return 1
	}

	read -r _ _swapValue _buffers <<< $( getMemoryInfo 2> /dev/null )

	local -A _memoryValues=(

		[MemTotal]="${_memTotal}"
		[SwapTotal]="${_swapValue}"
		[Buffers]="${_buffers}"
		[Swappiness]=""
	)

	printf \
		"\n%s[+] Generating Table Report with Updated Values related to System Memory...%s\n" \
		"${BLUE}" "${RESET}"

	_swappiness=$( cat /proc/sys/vm/swappiness )

	memInfoTable \
		"${_memoryValues[MemTotal]}" 	\
		"${_memoryValues[SwapTotal]}" 	\
		"${_memoryValues[Buffers]}" 	\
		"${_swappiness}"

	return 0
}

mysqlLsof(){
	local _tmpdirValue=$1 _hostname=$( hostname --fqdn )

	awk ' NR > 1 && \
	      $1 ~ /(mariadbd|mysqld)/ \
	      { exit 99 } ' \
              < <( lsof "${_tmpdirValue}" )

	(( $? == 99 )) && {

		printf \
			"%s[+] %s is being used as TMPDIR by mariadbd.service | mysqld.service :) %s\n" \
			"${BLUE}" "${_tmpdirValue}" "${RESET}"
		return 0

	} || { 
		printf >&2 \
			"%s[!] %s is not being used ( Opened File ) as TMPDIR by mariadbd.service | mysqld.service :( %s \n" \
			"${RED}" "${_tmpdirValue}" "${RESET}"
	}
}

getTmpdirValue(){
	local _passwdFile="/etc/psa/.psa.shadow" _passwd _tmpdirValue

	printf >&3 \
		"%s[+] Obtaining Plesk Admin User's Encrypted Password to log into MySQL...%s\n" \
		"${BLUE}" "${RESET}"

	[[ -e $_passwdFile ]] && {

		_passwd="$( cat ${_passwdFile} )"

		printf >&3 \
			"%s[+] Obtained Password -> %s %s\n" \
			"${GREEN}" "${_passwd}" "${RESET}"

	} || { printf >&3 \
			"%s[!] Could not obtain Plesk's Admin Password to log into MySQL :( %s\n" \
			"${RED}" "${RESET}"
	       return 1 ; }

	printf >&3 \
		"%s[+] Extracting MySQL's TMPDIR Parameter's value...%s\n" \
		"${BLUE}" "${RESET}"
	
	_tmpdirValue=$(
				
		awk '{ print $2 }' < <( MYSQL_PWD="${_passwd}" mysql --raw \
								     --batch \
								     --skip-column-names \
								     --user=admin \
								     --execute \
								     "SHOW GLOBAL VARIABLES LIKE 'tmpdir';" )
	)

	printf "%s\n" "${_tmpdirValue}"

	return 0
}

mySQLTmpdir(){
	local _configFile=$1 _ramdisk=$2

	grep --quiet \
	     --ignore-case \
	     --perl-regexp \
	     '^tmpdir(.*)?=\s?.*$' \
	     "${_configFile}"

	if (( $? == 0 )) ; then

		printf \
			"\n%s[+] TMPDIR Parameter's Line found on %s %s\n" \
			"${BLUE}" "${_configFile##*/}" "${RESET}"
		printf \
			"%s[+] Modifying TMPDIR Parameter's Value to %s...%s\n" \
			"${BLUE}" "${_ramdisk}" "${RESET}"

		sed --regexp-extended \
		    --in-place \
		    "s@(^tmpdir(.*)?=\s?).*@\1${_ramdisk}@g" \
		    "${_configFile}"

		(( $? == 0 )) && {

			printf \
				"%s[+] MySQL TMPDIR's value Modified correctly :) %s\n" \
				"${GREEN}" "${RESET}"

		} || { printf >&2 \
				"%s[!] Error: Could not modify TMPDIR Parameter's value on %s %s\n" \
				"${RED}" "${_configFile##*/}" "${RESET}"
		       return 1 ; }
	else
		printf \
			"\n%s[!] TMPDIR Parameter not found on %s %s\n" \
			"${PURPLE}" "${_configFile##*/}" "${RESET}"
		printf \
			"%s[+] Adding TMPDIR Parameter to %s %s...\n" \
			"${BLUE}" "${_configFile##*/}" "${RESET}"
		
		[[ ${_configFile##*/} == "50-server.cnf" ]] && {

			sed --regexp-extended \
			    --in-place \
			    '/datadir/a\tmpdir                  = /mnt/ramdisk' \
			    "${_configFile}"

	    	} || {									# [[ ${_configFile##*/} == "my.cnf" ]] && ...
			sed --regexp-extended \
			    --in-place \
			    '/\[mysqld\]/a\tmpdir = /mnt/ramdisk' \
			    "${_configFile}"
		}

		(( $? == 0 )) && {

			printf \
				"%s[+] Line related to TMPDIR Parameter with %s as value added :) %s\n" \
				"${GREEN}" "${_ramdisk}" "${RESET}"
		} || { printf >&2
				"%s[!] Error: Could not add TMPDIR Parameter's Line on %s :( %s \n" \
				"${RED}" "${_configFile##*/}" "${RESET}"
		       return 1 ; }
	fi

	printf \
		"%s[+] Restarting mariadbd.service | mysqld.service to apply TMPDIR's Value changes...%s\n" \
		"${BLUE}" "${RESET}"
	
	systemctl --quiet restart mariadb.service 2> /dev/null && {
		
		printf \
			"%s[+] Mariadb.service | mysqld.service restarted correctly %s\n" \
			"${GREEN}" "${RESET}"
	} || {
		printf >&2 \
			"%s[+] Error: Could not restart mariadb.service | mysqld.service :( . Try journactl -rxu service to get info %s\n" \
			"${ERROR}" "${RESET}"
		return 1
	}

	return 0
}

mySQLRamDisk(){
	local _hostname=$( hostname --fqdn )
	local _tmpdirValue _tmpfsCheck _lsofCheck
	local _ramdisk="/mnt/ramdisk" _mariadbdConfigFile="/etc/mysql/mariadb.conf.d/50-server.cnf" _fstab="/etc/fstab"
	local _mysqlUID _mysqlGID _FSStatus _mysqlConfigFile="/etc/mysql/my.cnf"

	printf \
		"\n%s[+] Checking if MySQL's Ramdisk is implemented on %s... %s\n" \
		"${BLUE}" "${_hostname}" "${RESET}"

	exec 3>&2
	_tmpdirValue=$( getTmpdirValue )	
	exec 3>&-

	if [[ -n $_tmpdirValue && $? -eq 0 ]] ; then

		printf \
			"%s[+] TMPDIR Parameter extracted correctly %s\n" \
			"${GREEN}" "${RESET}"
	else
		printf >&2 \
			"%s[!] Could not extract TMPDIR's value or TMPDIR Parameter is empty :( %s\n" \
			"${RED}" "${RESET}"
		return 1
	fi

	printf \
		"%s[+] Checking if TMPDIR's is configured over TMPFS...%s\n" \
		"${BLUE}" "${RESET}"

	if [[ $_tmpdirValue != "/tmp" ]] ; then

		printf \
			"%s[+] MySQL's TMPDIR VALUE is not /tmp . Seems like is on RAM-DISK %s\n" \
			"${BLUE}" "${RESET}"
		printf \
			"%s[+] TMPDIR VALUE -> %s %s \n" \
			"${PURPLE}" "${_tmpdirValue}" "${RESET}"
		printf \
			"%s[+] Checking if %s is a TMPFS...%s\n" \
			"${BLUE}" "${_tmpdirValue}" "${RESET}"
		
		_tmpfsCheck=$( awk 'NR==2' < <( df --output=fstype "${_tmpdirValue}" ) )
		
		[[ $_tmpfsCheck == "tmpfs" ]] && {

			printf \
				"%s[+] %s has been mounted as TMPFS :) %s\n" \
				"${BLUE}" "${_tmpdirValue}" "${RESET}"
			printf \
				"%s[+] Checking if %s is being used by mariadb.service | mysqld.service ( Alias )...%s\n" \
				"${BLUE}" "${_tmpdirValue}" "${RESET}"
			
			mysqlLsof "${_tmpdirValue}" && {

				printf \
					"%s[+] MYSQL's TMPDIR over RAMDISK is already configured then on %s :) %s \n" \
					"${PURPLE}" "${_hostname}" "${RESET}"

				return 0 ; }

		} || { 
			printf >&2 \
				"%s[!] %s has not been mounted as TMPFS. FSType -> %s %s \n" \
				"${RED}" "${_tmpdirValue}" "${_tmpfsCheck}" "${RESET}"
		}
	else

		printf >&2 \
			"%s[+] MySQL service on %s is configured with /tmp as tmpdir ( Default Config ) :( %s\n" \
			"${RED}" "${_hostname}" "${RESET}"

		printf \
			"%s[+] TMPDIR VALUE -> %s %s \n" \
			"${PURPLE}" "${_tmpdirValue}" "${RESET}"
	fi
		
	table "MySQL Ramdisk - Creation"

	printf \
		"\n%s[+] Proceeding to Create a TMPFS to assign it to MySQL TMPDIR's Parameter...%s\n" \
		"${BLUE}" "${RESET}"
	printf \
		"%s[+] Creating Mounting Directory on /mnt...%s\n" \
		"${BLUE}" "${RESET}"
	
	if [[ -e ${_ramdisk%/*} ]] ; then

		[[ -e $_ramdisk ]] && {
			
		      	printf >&2 \
				"%s[!] %s Already exists on %s. Rename or Remove it %s\n" \
				"${RED}" "${_ramdisk}" "${_hostname}" "${RESET}"
		      	return 1
		} || {
			mkdir "${_ramdisk}" 2> /dev/null || { printf >&2 \
									"%s[!] Error trying to create /%s Directory on %s :( %s\n" \
									"${RED}" "${_ramdisk##*/}" "${_ramdisk%/*}" "${RESET}"
							    return 1 ; }
		}
	else
		printf >&2 \
			"%s[!] /mnt Directory does not exists on %s %s\n" \
			"${RED}" \
			"$( awk 'NR==2' < <( df --human --output=source / ) )" \
			"${RESET}"

		return 1
	fi

	printf \
		"%s[+] %s Directory created successfully on %s %s\n" \
		"${GREEN}" "${_ramdisk}" "${_hostname}" "${RESET}"
	printf \
		"%s[+] Assigning Restrictive Permissions 700 on %s... %s\n" \
		"${BLUE}" "${_ramdisk}" "${RESET}"

	chmod 700 "${_ramdisk}" 2> /dev/null && { printf \
							"%s[+] 700 Perms assigned to %s %s\n" \
							"${GREEN}" "${_ramdisk}" "${RESET}"
				   } || { printf >&2 \
					   	"%s[!] Could not assign specific Perms to %s :( %s \n" \
					   	"${RED}" "${_ramdisk}" "${RESET}"
				   	return 1 ; }
	printf \
		"%s[+] Setting up Mysql:Mysql ( User:group ) Owners to %s...%s\n" \
		"${BLUE}" "${_ramdisk}" "${RESET}"

	printf \
		"%s[+] Extracting MySQL's UID and GID on %s...%s\n" \
		"${BLUE}" "${_hostname}" "${RESET}"

	{ _mysqlUID=$( id --user mysql ) _mysqlGID=$( id --group mysql ) ; }

	if (( $? == 0 )) ; then

		printf \
			"%s[+] MySQL's UID and GID extracted correctly :)%s\n" \
			"${GREEN}" "${RESET}"
		
		chown "${_mysqlUID}":"${_mysqlGID}" "${_ramdisk}" 2> /dev/null

		(( $? == 0 )) && {

			printf \
				"%s[+] Owner User and Owner Group assigned correctly on %s %s\n" \
				"${GREEN}" "${_ramdisk}" "${RESET}"
		} || { print >&2 \
				"%s[!] Could not assign mysql:mysql ownership to %s :( %s\n" \
				"${RED}" "${_ramdisk}" "${RESET}"
		       return 1 ; }
	else
		printf >&2 \
			"%s[!] Seems like Mysql User AND/OR Mysql Group does not exist :( . Try check manually /etc/passwd file %s\n" \
			"${RED}" "${RESET}"
		return 1
	fi 

	printf \
		"%s[+] Adding TMPFS related line on /etc/fstab File ( %s Automatic Mountage as TMPFS )...%s\n" \
		"${BLUE}" "${_ramdisk}" "${RESET}"
	
	[[ -e $_fstab ]] && {

		printf 2> /dev/null \
				"tmpfs   %s  tmpfs   defaults,size=4G,uid=%s,gid=%s,mode=700   0 0\n" \
				"${_ramdisk}" "${_mysqlUID}" "${_mysqlGID}" \
				>> "${_fstab}" 

		(( $? == 0 )) && {

			printf \
				"%s[+] Line added correcty on %s -> tmpfs %s tmpfs defaults,size=4G,uid=%s,gid=%s,mode=700 0 0 %s\n" \
				"${GREEN}" "${_fstab}" "${_ramdisk}" "${_mysqlUID}" "${_mysqlGID}" "${RESET}"
		} || { print >&2 \
				"%s[!] Could not add line on %s file :( %s\n" \
				"${RED}" "${_fstab}" "${RESET}"
		       return 1 ; }

	} || { printf >&2 \
			"%s[!] Seems like %s File does not exists on %s :( %s\n" \
			"${RED}" "${_fstab}" "${_hostname}" "${RESET}"
	       return 1; }
	
	printf \
		"%s[*] Remember that %s is gonna be mounted as TMPFS with a 4G Size Limit ( RAMDISK <= 4 ) %s\n" \
		"${PURPLE}" "${_ramdisk}" "${RESET}"

	printf \
		"%s[+] Mounting %s as TMPFS on %s...%s\n" \
		"${BLUE}" "${_ramdisk}" "${_hostname}" "${RESET}"

	mount --all 2> /dev/null && {

		printf \
			"%s[+] Seems like %s has been mounted...%s\n" \
			"${BLUE}" "${_ramdisk}" "${RESET}"
		printf \
			"%s[+] Checking if %s has been mounted as TMPFS...%s\n" \
			"${BLUE}" "${_ramdisk}" "${RESET}"
		
		_FSStatus=$( awk 'NR==2' < <( df --human --output=fstype "${_ramdisk}" ) )

		if [[ $_FSStatus == "tmpfs" ]] ; then

			printf \
				"%s[+] %s has been mounted successfully as TMPFS on %s :) %s\n" \
				"${GREEN}" "${_ramdisk}" "${_hostname}" "${RESET}"

			printf \
				"%s[+] Reloading Systemd to apply %s's configuration...%s\n" \
				"${BLUE}" "${_fstab}" "${RESET}"

			systemctl --quiet daemon-reload 2> /dev/null && {
				
				printf \
					"%s[+] Systemd reload correctly :) %s\n" \
					"${GREEN}" "${RESET}"
			} || {
				printf >&2 \
					"%s[!] Could not reload Systemd correctly :( %s\n" \
					"${RED}" "${RESET}"

				return 1
			}
		else
			printf >&2 \
				"%s[*] Warning: Seems like %s is mounted but not as TMPFS %s\n" \
				"${RED}" "${_ramdisk}" "${RESET}"
			return 1
		fi

	} || { printf >&2 \
			"%s[!] Error: Something went wrong trying to mounting %s or another SysFile. Check /etc/fstab Syntax %s \n" \
			"${RED}" "${_ramdisk}" "${RESET}"
	       return 1; }

	printf \
		"%s[+] Preparing to modify Mariadbd's TMPDIR Parameter Value from /tmp to %s on %s...%s\n" \
		"${BLUE}" "${_ramdisk}" "${_mariadbdConfigFile}" "${RESET}"
	
	[[ -e $_mariadbdConfigFile ]] && {

		mySQLConfigFileTable "${_mariadbdConfigFile}"
		
		mySQLTmpdir "${_mariadbdConfigFile}" "${_ramdisk}" || { printf >&2 \
										"%s[!] Error operating with %s File on %s %s\n" \
										"${RED}" "${_mariadbdConfigFile}" "${_hostname}" "${RESET}"
							  		return 1 ; }
	} || {
		printf >&2 \
			"%s[!] Seems like %s does not exists or at least is not on %s %s \n" \
			"${RED}" "${_mariadbdConfigFile##*/}" "${_mariadbdConfigFile%/*}" "${RESET}"

		if [[ -e $_mysqlConfigFile ]] ; then

			mySQLConfigFileTable "${_mysqlConfigFile}"

			mySQLTmpdir "${_mysqlConfigFile}" "${_ramdisk}" || { 

				printf >&2 \
					"%s[!] Error operating with %s File on %s %s\n" \
					"${RED}" "${_mysqlConfigFile}" "${_hostname}" "${RESET}"
				return 1
			}
		else
			printf >&2 \
				"%s[!] Error: Seems like %s does not exists neither %s \n" \
				"${RED}" "${_mysqlConfigFile##*/}" "${RESET}"
			return 1 
		fi
	}

	printf \
		"%s[+] Checking if MySQL TMPDIR Parameter's Value on %s is %s...%s\n" \
		"${BLUE}" "${_hostname}" "${_ramdisk}" "${RESET}"

	exec 3> /dev/null ; _tmpdirValue=$( getTmpdirValue ) ; exec 3>&-

	[[ $_tmpdirValue == "${_ramdisk}" ]] && {

		printf \
			"%s[+] TMPDIR's value is %s :) %s\n" \
			"${GREEN}" "${_tmpdirValue}" "${RESET}"
	} || {
		printf >&2 \
			"%s[!] Error: TMPDIR's value is not %s . Currently TMPDIR's Value -> %s %s \n" \
			"${RED}" "${_ramdisk}" "${_tmpdirValue}" "${RESET}"
		return 1
	}

	printf \
		"%s[+] Checking if %s's files are being open by mariadb process...%s\n" \
		"${BLUE}" "${_ramdisk}" "${RESET}"
	
	mysqlLsof "${_tmpdirValue}" && printf \
					"%s[+] MYSQL's TMPDIR over RAMDISK configured correctly on %s :) %s \n" \
					"${PURPLE}" "${_hostname}" "${RESET}"

	return 0
}

packageChecker(){
	local _package=$1 _hostname=$( hostname --long )

	printf \
		"%s[+] Checking if %s package is installed on %s...%s\n" \
		"${BLUE}" "${_package}" "${_hostname}" "${RESET}"

	grep --quiet \
	     '^Status: install ok installed$' \
	     < <( dpkg --status \
		       "${_package}" \
		       2> /dev/null
		)

	(( $? == 0 )) && {

		printf \
			"%s[+] %s Package is installed %s\n" \
			"${GREEN}" "${_package}" "${RESET}"
		return 0
	} || {
		printf >&2 \
			"%s[!] %s Package not installed :( %s\n" \
			"${RED}" "${_package}" "${RESET}"
		return 1
	}

}

clamAVChecker(){
	local _service _package _hostname=$( hostname --long ) _clamAVStatus=0 			# _clamAVStatus -> ClamAVSuite installed or not
	local -A _clamAVSuite=(
		
		[clamav-daemon.service]="clamd"
		[clamav-freshclam.service]="freshclam"
	)

	local -a _clamAVPackages=(

		clamav-daemon
		clamav-freshclam
	)

	printf \
		"\n%s[+] Checking if ClamAV Suite is installed on %s...%s\n" \
		"${BLUE}" "${_hostname}" "${RESET}"

	for _service in "${!_clamAVSuite[@]}"; do 

		checker1 "${_service}" "${_clamAVSuite[${_service}]}" || (( _clamAVStatus++ ))
	done

	(( $_clamAVStatus != 0 )) && {

		printf >&2 \
			"\n%s[!] Some ClamAV's Component seems to be not installed %s\n" \
			"${RED}" "${RESET}"
	} || {
		printf \
			"\n%s[+] ClamAV Suite seems to be installed correctly %s\n" \
			"${GREEN}" "${RESET}"
		return 0
	}

	printf \
		"%s[+] Perhaps ClamAV Service's are not Active | Running. Let's Check ClamAV's Packages %s\n" \
		"${BLUE}" "${RESET}"

	for _package in "${_clamAVPackages[@]}" ; do

		packageChecker "${_package}" || return 1
	done

	printf >&2 \
		"\n%s[!] There seems to be a problem with ClamAV's services %s\n" \
		"${RED}" "${RESET}"

	while : ; do

		printf \
			"%s[+] Restarting ClamAV's services on %s %s\n" \
			"${BLUE}" "${_hostname}" "${RESET}"

		for _service in "${!_clamAVSuite[@]}" ; do systemctl --quiet restart "${_service}" 2> /dev/null; done

		printf \
			"%s[+] Checking ClamAV's services status after restart...%s\n" \
			"${BLUE}" "${RESET}"

		_clamAVStatus=0

		for _service in "${!_clamAVSuite[@]}" ; do 

			if systemctl --quiet is-active "${_service}" ; then

				printf \
					"%s[+] %s is Active | Running :) %s\n" \
					"${GREEN}" "${_service}" "${RESET}"
			else

				printf >&2 \
					"%s[!] %s is Inactive | Not Running :( %s\n" \
					"${RED}" "${_service}" "${RESET}"

				(( _clamAVStatus++ ))
			fi

		done

		(( $_clamAVStatus == 0 )) && return 0

		printf \
			"%s[!] There is a problem with ClamAV's Services definitely %s \n" \
			"${PURPLE}" "${RESET}"

		read -p \
			"${PURPLE}[+] Wait 30-60 seconds and Press Enter to Restart ClamAV's Services again${RESET}"
	done
}

clamAVInstall(){
	local _package _hostname=$( hostname --long )
	local -a _clamAVPackages=(

		clamav-daemon
		clamav-freshclam
	)

	table "ClamAV Install Section"

	printf \
		"\n%s[+] ClamAV Suite related packages are gonna be installed now on %s %s\n" \
		"${BLUE}" "${_hostname}" "${RESET}"	

	printf \
		"%s[+] Updating the list of available packages in the repositories...%s\n" \
		"${BLUE}" "${RESET}"

	apt -qq update &> /dev/null

	printf \
		"%s[+] Installing ClamAV Packages ( clamav-daemon | clamav-freshclam ) on %s...%s\n" \
		"${BLUE}" "${_hostname}" "${RESET}"

	apt -qq install clamav-daemon clamav-freshclam &> /dev/null 

	printf \
		"%s[+] Previous mentioned packages seems to be installed correctly %s\n" \
		"${GREEN}" "${RESET}"
}

clamAVMailerSetup(){
	local _hostname=$( hostname --long ) _clamAVConfigDir="${HOME}/.prepare" _clamAVMailer="ClamAVMailer.sh"
	local _githubURL="https://raw.githubusercontent.com/4l3xBB/Prepare/main/ClamAV/ClamAVMailer.sh" _githubReq
	local _mailAccount="alertas@digitaldot.es"

	printf \
		"%s[+] Checking if %s Directory exists on %s...%s\n" \
		"${BLUE}" "${_clamAVConfigDir}" "${_hostname}" "${RESET}"

	[[ -e $_clamAVConfigDir ]] || {
	
		printf >&2 \
			"%s[!] %s Directory does not exist %s\n" \
			"${RED}" "${_clamAVConfigDir}" "${RESET}"

		printf \
			"%s[+] Creating ClamAV Configuration Directory as %s...%s\n" \
			"${BLUE}" "${_clamAVConfigDir}" "${RESET}"

		[[ -n $HOME ]] && mkdir "${_clamAVConfigDir}" &> /dev/null && {

			printf \
				"%s[+] %s Directory seems to have been created correctly %s\n" \
				"${GREEN}" "${_clamAVConfigDir}" "${RESET}"
		} || {
			printf >&2 \
				"%s[!] Could not create %s Directory correctly. Try it manually :( %s\n" \
				"${RED}" "${_clamAVConfigDir}" "${RESET}"
			return 1
		}
	}

	printf \
		"%s[+] %s exists on %s :) %s\n" \
		"${GREEN}" "${_clamAVConfigDir}" "${_hostname}" "${RESET}"

	printf \
		"%s[+] Downloading %s Script from %s...%s\n" \
		"${BLUE}" "${_clamAVMailer}" "${_githubURL}" "${RESET}"

	_githubReq=$(

		curl --silent \
		     --write-out '%{http_code}\n' \
		     --output "${_clamAVConfigDir}/${_clamAVMailer}" \
		     --request GET \
		     "${_githubURL}"
	)

	if (( $_githubReq == 200 )) ; then

		printf \
			"%s[+] HTTP Status Code -> %s . It seems like %s has been downloaded correctly %s\n" \
			"${GREEN}" "${_githubReq}" "${_clamAVMailer}"

		printf \
			"%s[+] Checking %s existence on %s...%s\n" \
			"${BLUE}" "${_clamAVMailer}" "${_clamAVConfigDir}" "${RESET}"

		[[ -e ${_clamAVConfigDir}/${_clamAVMailer} ]] || {

			printf >&2 \
				"%s[!] %s does not exist inside %s on %s :( . Try download it manually from above github link %s\n" \
				"${RED}" "${_clamAVMailer}" "${_clamAVConfigDir}" "${_hostname}" "${RESET}"

			return 1
		} && {
			printf \
				"%s[+] %s exists inside %s on %s :) %s\n" \
				"${GREEN}" "${_clamAVMailer}" "${_clamAVConfigDir}" "${_hostname}" "${RESET}"
		}
	else
		printf >&2 \
			"%s[!] HTTP Status Code -> %s .Something went wrong trying to download %s :( %s\n" \
			"${RED}" "${_githubReq}" "${_clamAVMailer}" "${RESET}"
		return 1
	fi

	printf \
		"%s[+] Let's Execute %s on %s to check that everything is OK in terms of Script implementation...%s\n" \
		"${PURPLE}" "${_clamAVMailer}" "${_hostname}" "${RESET}"

	printf \
		"%s[+] Analysis Test -> Executing %s to analyze /etc on %s...%s\n" \
		"${BLUE}" "${_clamAVMailer}" "${_hostname}" "${RESET}"

	bash "${_clamAVConfigDir}/${_clamAVMailer}" --recipient="${_mailAccount}" --path=/etc &> /dev/null

	(( $? == 99 || $? != 0 )) && {

		printf >&2 \
			"%s[!] Something went wrong trying to execute %s :(. %s exited with %s Code %s\n" \
			"${RED}" "${_clamAVMailer}" "${_clamAVMailer}" "${?}" "${RESET}"

		printf \
			"%[+] Try to execute %s manually and Debug Script Execution to Display / Check errors %s\n" \
			"${PURPLE}" "${_clamAVMailer}" "${RESET}"

		return 1
	} || {
		printf \
			"%s[+] It seems that %s has been executed correctly...%s\n" \
			"${GREEN}" "${_clamAVMailer}" "${RESET}"
		
		read -p \
			"${PURPLE}[*] Check ${_mailAccount} and Press Enter if ${_clamAVMailer}'s Mail has been received. If not, C-c and Try it manually${RESET}"

		return 0
	}
}

userCrontabBackup(){
	local _crontabBackupFile="$( id -un ).crontab.bk" _clamAVConfigDir="${HOME}/.prepare" _userCrontab="crontab -u $( id -un ) -l"

	printf \
		"%s[+] Backing UP %s's Crontab File as %s on %s...%s\n" \
		"${PURPLE}" "$( id -un )" "${_crontabBackupFile}" "${_clamAVConfigDir}" "${RESET}"
	
	$_userCrontab > "${_clamAVConfigDir}/${_crontabBackupFile}" 2> /dev/null

	[[ -s ${_clamAVConfigDir}/${_crontabBackupFile} ]] && {
		
		printf \
			"%s[+] %s's Crontab Backup done successfully :) %s\n" \
			"${GREEN}" "$( id -un )" "${RESET}"

		return 0
	} || {
		printf >&2 \
			"%s[!] %s's Crontab is empty. Try -> crontab -u $( id -un ) -r to create new one %s\n" \
			"${RED}" "$( id -un )" "${RESET}"
	}
}

clamAVMailerCrontab(){
	local _status=$1 _clamAVConfigDir="${HOME}/.prepare" _clamAVMailer="ClamAVMailer.sh" _mailAccount="alertas@digitaldot.es"
	local _userCrontab="crontab -u $( id -un ) -l" _userCrontabTemplate="./Assets/userCrontabTemplate.txt"
	local _clamAVMailerCmdline

	local _clamAVMailerCronLine="55\t23\t*\t*\t*\tbash ${_clamAVConfigDir}/${_clamAVMailer} --recipient ${_mailAccount} --path / &> /dev/null\n"

	(( $_status == 0 )) && {

		printf \
			"%s[+] Checking if %s's Line exists on %s's Crontab...%s\n" \
			"${BLUE}" "${_clamAVMailer}" "$( id -un )" "${RESET}"

		grep --quiet \
		     --ignore-case \
		     --perl-regexp \
		     ".*${_clamAVMailer}.*" <( ${_userCrontab} )

		(( $? == 0 )) && { 

			printf \
				"%s[+] Line related to %s is in %s's Crontab :) %s\n" \
				"${GREEN}" "${_clamAVMailer}" "$( id -un )" "${RESET}"

			_clamAVMailerCmdline=$(

				awk '/ClamAVMailer/ { \
				     for ( i=6 ; i<=NF ; i++ ) \
					     printf \
					     	   "%s%s" ,\
						   $i , ( i==NF ? "\n" : " " ) \

				     }' <( ${_userCrontab} )
			)

			printf \
				"%s[+] %s's Command on %s's Crontab -> %s\n" \
				"${BLUE}" "${_clamAVMailer}" "$( id -un )" "${RESET}"

			printf \
				"%s[*] %s %s\n" \
				"${PURPLE}" "${_clamAVMailerCmdline}" "${RESET}"

			return 0
		} || {
			printf >&2 \
				"%s[!] Line related to %s is not in %s's Crontab :( %s\n" \
				"${RED}" "${_clamAVMailer}" "$( id -un )" "${RESET}"

			userCrontabBackup || return 1	
				
			printf \
				"%s[+] Proceeding to insert that line in %s's Crontab...%s\n" \
				"${BLUE}" "$( id -un )" "${RESET}"

			crontab -u $( id -un ) - 2> /dev/null < <( ${_userCrontab} ; printf "${_clamAVMailerCronLine}" )
		}
	} || {
			
		printf \
			"%s[+] Proceeding to Create new Crontab File for %s user...%s\n" \
			"${BLUE}" "$( id -un )" "${RESET}"
		printf \
			"%s[+] Inserting %s's Line into created Crontab...%s\n" \
			"${BLUE}" "${_clamAVMailer}" "${RESET}"
		
		crontab -u $( id -un ) - 2> /dev/null < <( cat "${_userCrontabTemplate}" ; printf "${_clamAVMailerCronLine}" )
	}

	printf \
		"%s[+] Checking if %s's Line has been inserted correctly...%s\n" \
		"${BLUE}" "${_clamAVMailer}" "${RESET}"

	grep --quiet \
	     --ignore-case \
	     --perl-regexp \
	     ".*${_clamAVMailer}.*" <( ${_userCrontab} ) && { 

		printf \
			"%s[+] Line related to %s exists now :) %s\n" \
			"${GREEN}" "${_clamAVMailer}" "${RESET}"

		printf \
			"%s[+] %s's Crontab's Line -> %s\n" \
			"${BLUE}" "${_clamAVMailer}" "${RESET}"

		printf "${PURPLE}[*] ${_clamAVMailerCronLine} ${RESET}\n"

		return 0
	} || {
		printf >&2 \
			"%s[!] Could not insert %s's Line on %s's Crontab :( %s\n" \
			"${RED}" "${_clamAVMailer}" "$( id -un )" "${RESET}"

		return 1
	}
}

clamAVSetup(){
	local _clamdConfigFile="/etc/clamav/clamd.conf" _hostname=$( hostname --long )
	local _clamdservice="clamav-daemon.service" _clamAVConfigDir="${HOME}/.prepare" _clamAVMailer="ClamAVMailer.sh"
	local _userCrontab="crontab -u $( id -un ) -l"

	clamAVChecker || {

		clamAVInstall

		printf \
			"%s[+] Let's Check now if ClamAV suite has been installed and It's running correctly %s\n" \
			"${BLUE}" "${RESET}"

		clamAVChecker || { 
			
			printf >&2 \
				"%s[!] Something went wrong trying to install ClamAV Packages :(%s\n" \
				"${RED}" "${RESET}"
			printf \
				"%s[+] Try to install these packages manually and Check Installation Logs if it fails %s\n" \
				"${BLUE}" "${RESET}"

			return 1
		}
	}

	table "ClamAV Setup Section"

	printf \
		"\n%s[+] Checking Clamd's MaxDirectoryRecursion Parameter on %s...%s\n" \
		"${BLUE}" "${_clamdConfigFile}" "${RESET}"

	[[ -e $_clamdConfigFile ]] || { printf >&2 \
						"\n%s[!] %s ClamAV Configuration File does not exist on %s ( Not in default Path at least ) %s\n" \
						"${RED}" "${_hostname}" "${RESET}"

					return 1 ; }
	grep --quiet \
	     --ignore-case \
	     --perl-regexp \
	     --text \
	     '^MaxDirectoryRecursion 50$' \
	     "${_clamdConfigFile}"

	(( $? != 0 )) && {

		printf >&2 \
			"%s[!] MaxDirectoryRecursion Parameter is not set correctly %s\n" \
			"${RED}" "${RESET}"
		
		printf \
			"\n%s[+] Modifying MaxDirectoryRecursion Parameter on %s file...%s\n" \
			"${BLUE}" "${_clamdConfigFile}" "${RESET}"

		sed --regexp-extended \
		    --in-place \
		    's@(^MaxDirectoryRecursion)\s[0-9]+@\1 50@g' \
		    "${_clamdConfigFile}"

		if (( $? == 0 )) ; then

			printf \
				"%s[+] MaxDirectoryRecursion Parameter's value set to 50 correctly on %s :) %s\n" \
				"${GREEN}" "${_clamdConfigFile}" "${RESET}"
			printf \
				"%s[+] Go Check https://github.com/4l3xBB/prepare to find out why...%s\n" \
				"${PURPLE}" "${RESET}"
			printf \
				"\n%s[+] Restarting %s to apply changes...%s\n" \
				"${BLUE}" "${_clamdservice}" "${RESET}"

			systemctl --quiet restart "${_clamdservice}" &> /dev/null && {

				printf \
					"%s[+] %s restarted correctly %s\n" \
					"${GREEN}" "${_clamdservice}" "${RESET}"
			} || {
				printf >&2 \
					"%s[!] Could not restart %s correctly :( . Try check Service's Status and Logs using journalctl utility%s\n" \
					"${RED}" "${_service}" "${RESET}"

				return 1
			}

		else
			printf >&2 \
				"%s[!] Could not Set or Modify Previous Parameter on %s. Try to do it after this script %s\n" \
				"${RED}" "${_clamdConfigFile}" "${RESET}"
		fi
	} || {
		printf >&2 \
			"%s[+] MaxDirectoryRecursion Parameter is set correctly ( Value -> 50 )%s\n" \
			"${GREEN}" "${RESET}"
	}

	printf \
		"\n%s[+] Checking if %s exists on %s...%s\n" \
		"${BLUE}" "${_clamAVMailer}" "${_clamAVConfigDir}" "${RESET}"

	[[ -z $HOME ]] && {

		printf >&2 \
			"%[!] %s Global Variable is empty. Check it ( If it's empty, export value to it ) %s\n" \
			"${RED}" "${HOME}" "${RESET}"

		return 1
	}

	[[ -e $_clamAVConfigDir/${_clamAVMailer} ]] && {
		
		printf \
			"%s[+] %s exists on %s %s\n" \
			"${GREEN}" "${_clamAVMailer}" "${_clamAVConfigDir}" "${RESET}"
	} || {
		printf >&2 \
			"%s[!] %s does not exist on %s %s\n" \
			"${RED}" "${_clamAVMailer}" "${_clamAVConfigDir}" "${RESET}"
		printf \
			"%s[+] Let's set up %s on %s...%s\n" \
			"${PURPLE}" "${_clamAVMailer}" "${_hostname}" "${RESET}"

		clamAVMailerSetup || return 1
	}

	printf \
		"\n%s[+] Checking if %s's Crontab exists or not...%s\n" \
		"${BLUE}" "$( id -un )" "${RESET}"

	if $_userCrontab &> /dev/null ; then

		printf \
			"%s[+] %s's Crontab is not empty %s\n"\
			"${GREEN}" "$( id -un )" "${RESET}"

		clamAVMailerCrontab "0" || return 1
			
	else
		printf >&2 \
			"%s[!] %s's Crontab is empty %s\n" \
			"${RED}" "$( id -un )" "${RESET}"

		clamAVMailerCrontab "1" || return 1
	fi
}

extractProcessPorts(){
	local _service=$1 _servicePID _processPort _numRegex='^[0-9]+$' _port
	local -A _extractedPorts=()

	_servicePID=$(

		systemctl show \
			  --property=MainPID \
			  --value "${_service}"
	)

	[[ $_servicePID =~ $_numRegex ]] && (( $_servicePID != 0 )) && {

		_processPort=$(		
		
			awk ' NR > 1 \
			      { split ( $( NF - 1 ), a, ":" ) ; \
			      print a[2] } ' < <( 
						   lsof -p${_servicePID} \
							-a \
							-i 4TCP \
							-s TCP:listen \
							-Pn \
							2> /dev/null
						)
			2> /dev/null
		)

		if [[ -n $_processPort ]] ; then
			
			while read -r _port ; do

				_extractedPorts["${_port}"]=""	

			done <<< "${_processPort}"
		else
			return 1
		fi

	} || return 1

	printf "%s\n" "${!_extractedPorts[@]}"
}

deleteSSHPort(){
	local _sshdDeletedPort=$1 _sshdService="sshd.service" _sshdConfig="/etc/ssh/sshd_config"

	printf \
		"\n%s[+] Deleting %s Port's Parameter related to %s Port on %s...%s\n" \
		"${BLUE}" "${_sshdService}" "${_sshdDeletedPort}" "${_sshdConfig}" "${RESET}"

	sed --regexp-extended \
	    --in-place \
	    "/^#?\s*Port\s${_sshdDeletedPort}$/d" \
	    "${_sshdConfig}" \
	    2> /dev/null

	(( $? == 0 )) && {

		printf \
			"%s[+] It seems like %s Port's Line has been deleted...%s\n" \
			"${BLUE}" "${_sshdDeletedPort}" "${RESET}"

		printf \
			"%s[+] Checking it...%s\n" \
			"${BLUE}" "${RESET}"

		grep --quiet \
		     --ignore-case \
		     --perl-regexp \
		     "^#?\s*Port\s${_sshdDeletedPort}$" \
		     "${_sshdConfig}"

		if (( $? == 0 )) ; then
			
			printf >&2 \
				"%s[!] Could not delete %s Port's Line :( %s\n" \
				"${RED}" "${_sshdDeletedPort}" "${RESET}"

			return 1
		else
			printf \
				"%s[+] %s Port's Line deleted correctly :) %s\n" \
				"${GREEN}" "${_sshdDeletedPort}" "${RESET}"

			return 0
		fi

	} || {
		printf >&2 \
			"%s[!] Could not delete %s Port's Line on %s :( %s\n" \
			"${RED}" "${_sshdDeletedPort}" "${_sshdConfig}" "${RESET}"

		return 1
	}
}

checkSSHPort(){
	local _sshdPort="${1:-\\d{1,5\}}" _sshdConfig=$2
	local _displayPort="${1:-'( \d{1,5} ) Pattern'}"
	
	printf \
		"\n%s[+] Checking if %s Port's Line exists on %s...%s\n" \
		"${BLUE}" "${_sshdPort}" "${_sshdConfig}" "${RESET}"
	
	grep --quiet \
	     --ignore-case \
	     --perl-regexp \
	     "^Port\s${_sshdPort}$" \
	     "${_sshdConfig}"

	(( $? == 0 )) && {

		printf \
			"%s[+] %s Port's Line exists on %s %s\n" \
			"${GREEN}" "${_sshdPort}" "${_sshdConfig}" "${RESET}"

		return 0

	} || {
		printf >&2 \
			"%s[!] %s Port's Line does not exist on %s %s\n" \
			"${RED}" "${_sshdPort}" "${_sshdConfig}" "${RESET}"

		return 1
	}	
}

setSSHPort(){
	local _sshdPortNew=$1 _hostname=$( hostname --long ) _sshdService="sshd.service"
	local _sshdConfig="/etc/ssh/sshd_config"

	printf \
		"\n%s[+] Setting %s Port as Listening Port for %s on %s...%s\n" \
		"${BLUE}" "${_sshdPortNew}" "${_sshdService}" "${_hostname}" "${RESET}"

	sed --regexp-extended \
	    --in-place \
	    "s@^\#?(Port)\s[0-9]{1,5}@\1 ${_sshdPortNew}@g" \
	    "${_sshdConfig}" \
	    2> /dev/null

	(( $? == 0 )) && {

		printf \
			"%s[+] It seems like %s Port's Value has been modified to %s %s\n" \
			"${BLUE}" "${_sshdService}" "${_sshdPortNew}" "${RESET}"

		checkSSHPort "${_sshdPortNew}" "${_sshdConfig}" && {
			
			printf \
				"%s[+] %s Port's Value modified correctly to %s then :) %s\n" \
				"${GREEN}" "${_sshdService}" "${_sshdPortNew}" "${RESET}"

			return 0
		} || {
			printf \
				"%s[+] Check Include Directives on %s. Maybe Port's Directive is in another Config File%s\n" \
				"${PURPLE}" "${_sshdConfig}" "${RESET}"
			
			printf \
				"%s[+] Let's Insert %s Port's Directive on %s as New Line...%s\n" \
				"${BLUE}" "${_sshdPortNew}" "${_sshdConfig}" "${RESET}"

			sed --regexp-extended \
			    --in-place \
			    "/^#?\s*AddressFamily.*$/i\Port ${_sshdPortNew}" \
			    "${_sshdConfig}"

			if (( $? == 0 )) ; then

				checkSSHPort "${_sshdPortNew}" "${_sshdConfig}" && {
						
					printf \
						"%s[+] %s Port's Line related to %s inserted correctly then :) %s\n" \
						"${GREEN}" "${_sshdService}" "${_sshdPortNew}" "${RESET}"

					return 0
				} || {
					printf >&2 \
						"%s[!] Could not insert %s Port's Line on %s %s\n" \
						"${RED}" "${_sshdPortNew}" "${_sshdConfig}" "${RESET}"
					
					printf \
						"%s[+] Inserting directly previous Directive on %s's last line...%s\n" \
						"${BLUE}" "${_sshdConfig}" "${RESET}"

					printf "Port %s\n" "${_sshdPortNew}" >> "${_sshdConfig}"

					if checkSSHPort "${_sshdPortNew}" "${_sshdConfig}" ; then
					
						printf \
							"%s[+] %s Port's Line related to %s inserted correctly then :) %s\n" \
							"${GREEN}" "${_sshdService}" "${_sshdPortNew}" "${RESET}"

						return 0
						
					else
						printf >&2 \
							"%s[!] Could not insert %s Port's Line on %s :( . Try it manually %s\n" \
							"${RED}" "${_sshdService}" "${_sshdConfig}" "${RESET}"

						return 1
					fi
				}
			else
				printf >&2 \
					"%s[!] Could not set up %s Port as Listening Port on %s :( %s\n" \
					"${RED}" "${_sshdPortNew}" "${_hostname}" "${RESET}"

				return 1
			fi
		}
	} || {
		printf >&2 \
			"%s[!] Could not set up %s Port as Listening Port on %s :( %s\n" \
			"${RED}" "${_sshdPortNew}" "${_hostname}" "${RESET}"

		return 1
	}
}

# This Function involves the task of delete all Aditional Ports' Directives that are present on SSH Configuration Files != /etc/ssh/sshd_config

deleteAdditionalSSHPort(){
	local _hostname=$( hostname --long ) _sshdConfig="/etc/ssh/sshd_config" _sshdService="sshd.service" _file _line _port
	local -A _sshdPortFiles=()

	printf \
		"\n%s[+] Searching for other SSH Configuration Files which have Port's Directive on %s...%s\n" \
		"${BLUE}" "${_hostname}" "${RESET}"

	while IFS=":" read -r _file _line; do

		_sshdPortFiles["${_line}"]="${_file}"

	done < <(
		   find "${_sshdConfig%/*}" \
		     	-type f \
		     	-iname "*${_sshdConfig##*/}" \
		 	-prune \
		     	-o \
		     	-exec grep --ignore-case \
			   	   --perl-regexp \
				   '^Port\s\d{1,5}$' {} + \
		     	2> /dev/null
		)

	(( "${#_sshdPortFiles[@]}" != 0 )) && {

		printf \
			"%s[+] %s Port's Directive found in other SSH Configuration File[s] -> %s %s \n" \
			"${PURPLE}" "${_sshdService}" "${#_sshdPortFiles[@]}" "${RESET}"

		printf \
			"\n%s[+] Proceeding to delete %s Port's Line on those files...%s\n" \
			"${BLUE}" "${_sshdService}" "${RESET}"
		
		for _line in "${!_sshdPortFiles[@]}" ; do

			sed --regexp-extended \
			    --in-place \
			    "/^${_line}$/d" \
			    "${_sshdPortFiles[${_line}]}" \
			    2> /dev/null

			(( $? == 0 )) && {

				printf \
					"\n%s[+] It seems like Port's Directive ( %s ) on %s has been deleted...%s\n" \
					"${BLUE}" "${_line}" "${_sshdPortFiles[${_line}]}" "${RESET}"

				if checkSSHPort "${_line:5}" "${_sshdPortFiles[${_line}]}" ; then
				
					printf \
						"%s[+] Could not delete %s Port's Line :( %s\n" \
						"${RED}" "${_sshdService}" "${RESET}"

					return 1
				else
					printf \
						"%s[+] %s Port's Line deleted correctly then :) %s\n" \
						"${GREEN}" "${_sshdService}" "${RESET}"

					continue
				fi

			} || {
				printf >&2 \
					"%s[!] An Error occurred trying to delete Port's Directive ( %s ) on %s :( %s\n" \
					"${RED}" "${_line}" "${_sshdPortFiles[${_line}]}" "${RESET}"

				return 1
			}
		done

		printf \
			"\n%s[+] All %s Port' Lines deleted correctly on SSH Configuration Files != %s %s\n" \
			"${GREEN}" "${_sshdService}" "${_sshdConfig}" "${RESET}"

		printf \
			"\n%s[+] Restarting %s on %s to apply previous changes...%s\n" \
			"${BLUE}" "${_sshdService}" "${_hostname}" "${RESET}"

		systemctl --quiet restart "${_sshdService}" 2> /dev/null

		if (( $? == 0 )) ; then

			printf \
				"%s[+] %s restarted correctly :) %s\n" \
				"${GREEN}" "${_sshdService}" "${RESET}"
		else
			printf >&2 \
				"%s[!] Something went wrong trying to restart %s %s :(\n" \
				"${RED}" "${_sshdService}" "${RESET}"

			return 1
		fi

		# Return Ports to Delete from Listening Ports Array

		for _port in "${!_sshdPortFiles[@]}" ; do [[ $_port != "Port 12021" ]] && printf >&3 "%s\n" "${_port:5}" ; done

		return 0
	}

	printf \
		"%s[+] No File Found ( Different from %s ) on %s contaning %s Port's Directive %s\n" \
		"${PURPLE}" "${_sshdConfig}" "${_hostname}" "${_sshdService}" "${RESET}"

	return 0
}

sshdPortSetup(){
	local _hostname=$( hostname --long ) _sshdConfig="/etc/ssh/sshd_config" _sshdService="sshd.service"
	local _sshdPortNew=12021 _defaultPort=22 _port _currentPort _deleteLineStatus=0
	local -A _currentSSHdPorts=() _deletedSSHdPorts=()

	printf \
		"\n%s[+] Checking if %s Config file exists on %s...%s\n" \
		"${BLUE}" "${_sshdConfig##*/}" "${_sshdConfig%/*}" "${RESET}"

	[[ -e $_sshdConfig ]] && {

		printf \
			"%s[+] %s exists on previous Path %s\n" \
			"${GREEN}" "${_sshdConfig##*/}" "${RESET}"

		printf \
			"\n%s[+] Checking which Port[s] %s is listening on...%s\n" \
			"${BLUE}" "${_sshdService}" "${RESET}"
		
		while read -r _port ; do

			_currentSSHdPorts["${_port}"]=""

		done < <( 
				extractProcessPorts "${_sshdService}" || {

					printf >&2 \
						"%s[!] Something went wrong trying to extract which Port is %s listening on :( %s\n" \
						"${RED}" "${_sshdService}" "${RESET}"

					return 1
				}
			)

	} || {
		printf >&2 \
			"%s[!] Could not find %s on %s :( %s\n" \
			"${RED}" "${_sshdConfig##*/}" "${_sshdConfig%/*}" "${RESET}"
		
		return 1
	}

	printf \
		"%s[+] %s's Listening Port[s] on %s -> %s %s\n" \
		"${PURPLE}" "${_sshdService}" "${_hostname}" \
		"$( printf "%s " "${!_currentSSHdPorts[@]}"  )" \
		"${RESET}"

	while read -r _port; do

		_deletedSSHdPorts["${_port}"]=""

	done < <( 
			deleteAdditionalSSHPort 3>&1 1>&2 || {

				printf >&2 \
					"%s[!] Something went wrong trying to extract Ports related to deleted Ports' Lines :( %s\n" \
					"${RED}" "${RESET}"

				return 1
			}
	
		)
	
	(( "${#_deletedSSHdPorts[@]}" != 0 )) && {

		printf \
			"%s[+] %s's Deleted Port[s] on SSH Configuration Files != %s -> %s %s\n" \
			"${PURPLE}" "${_sshdService}" "${_sshdConfig}" \
			"$( printf "%s " "${!_deletedSSHdPorts[@]}"  )" \
			"${RESET}"
	}

	# PORTS CLEANUP

	# If _deletedSSHdPorts[X] == _currentSSHdPort[X] then Remove Port from _currenSSHdPort[@] -> unset _currentSSHdPort[X]

	for _port in "${!_deletedSSHdPorts[@]}" ; do

		[[ -v "_currentSSHdPorts[${_port}]" ]] && unset _currentSSHdPorts["${_port}"]
	done

	# Not Necessary, Above Logic ensures that there is no such problem ( Just in Case )

	# Several Elements ( Listen Ports > 1 ) on array

	if (( "${#_currentSSHdPorts[@]}" > 1 )) ; then

		for _currentPort in "${!_currentSSHdPorts[@]}" ; do
		
			(( $_currentPort != $_sshdPortNew )) && {
				
				deleteSSHPort "${_currentPort}" && { (( _deleteLineStatus++ )) ; continue ; } || return 1

			}
		done

		checkSSHPort "${_sshdPortNew}" "${_sshdConfig}" || setSSHPort "${_sshdPortNew}" "${_sshdConfig}" || return 1

		(( $_deleteLineStatus != 0 )) && return 10	

	# One Element ( Listen Ports == 1 ) on array

	else
		_currentPort=${!_currentSSHdPorts[@]}

		[[ -z $_currentPort ]] && {

			setSSHPort "${_sshdPortNew}" "${_sshdConfig}" && return 10 || return 1
		}

		(( $_currentPort == $_sshdPortNew )) && {

			checkSSHPort "${_currentPort}" "${_sshdConfig}" && {

				printf \
					"%s[+] It's not necessary to change %s Port's Parameter as Currently Port is %s :) %s\n" \
					"${PURPLE}" "${_sshdService}" "${_currentPort}" "${RESET}"

				return 0 

			} || {
				printf >&2 \
					"%s[+] Check Include Directives on %s. Maybe Port's Directive is in another Config File%s\n" \
					"${PURPLE}" "${_sshdConfig}" "${RESET}"

				setSSHPort "${_sshdPortNew}" "${_sshdConfig}" && return 10 || return 1
			}
		}

		(( $_currentPort == $_defaultPort )) && {
			
			checkSSHPort "${_currentPort}" "${_sshdConfig}"

			if (( $? == 0 )) ; then
				
				deleteSSHPort "${_currentPort}" && { setSSHPort "${_sshdPortNew}" && return 10 ; } || return 1
			else

				setSSHPort "${_sshdPortNew}" && return 10 || return 1
			fi
		}

		(( $_currentPort != $_sshdPortNew && $_currentPort != $_defaultPort )) && {

			setSSHPort "${_sshdPortNew}" && return 10 || return 1
		}

	fi

}

sshdRootLoginSetup(){
	local _hostname=$( hostname --long ) _sshdService="sshd.service" _sshdRootDirective="PermitRootLogin"
	local _sshdConfig="/etc/ssh/sshd_config" _defaultValueRootLogin
	local _checkRootDirective=(

		grep --ignore-case \
		     --perl-regexp \
		     "^${_sshdRootDirective}\syes$" \
		     "${_sshdConfig}"
	)

	printf \
		"\n%s[+] Checking if %s Parameter is Enabled on %s...%s\n" \
		"${BLUE}" "${_sshdRootDirective}" "${_hostname}" "${RESET}"

	"${_checkRootDirective[@]}" &> /dev/null

	(( $? == 0 )) && {

		printf \
			"%s[+] %s Parameter's Value -> Yes. Therefore means that Root login on %s is enabled %s\n" \
			"${PURPLE}" "${_sshdRootDirective}" "${_hostname}" "${RESET}"

		return 0
	}

	_defaultValueRootLogin=$(

		grep --ignore-case \
		     --perl-regexp \
		     "^\#?${_sshdRootDirective}\s.*$" \
		     "${_sshdConfig}"
	)

	printf \
		"%s[+] %s Parameter is disabled ( Default Value -> %s ) %s\n" \
		"${RED}" "${_sshdRootDirective}" "${_defaultValueRootLogin}" "${RESET}"

	printf \
		"%s[!] Warning: %s's Root Login will be enabled %s\n" \
		"${PURPLE}" "${_sshdService}" "${RESET}"

	printf \
		"\n%s[+] Enabling Root login through %s on %s %s...\n" \
		"${BLUE}" "${_sshdService}" "${_hostname}" "${RESET}"

	sed --regexp-extended \
	    --in-place \
	    "s@^\#?(${_sshdRootDirective}).*\$@\1 yes@g" \
	    "${_sshdConfig}" \
	    2> /dev/null

	if (( $? == 0 )) ; then

		printf \
			"%s[+] It seems like %s Parameter has been modified correctly on %s. Let's Check it...%s\n" \
			"${BLUE}" "${_sshdRootDirective}" "${_sshdConfig}" "${RESET}"
	else

		printf >&2 \
			"%s[!] Something went wrong trying to modify %s Parameter's Value. Try it manually %s\n" \
			"${RED}" "${_sshdRootDirective}" "${RESET}"

		return 1
	fi

	printf \
		"%s[+] Checking if %s Parameter's Value has been set to \"Yes\"...%s\n" \
		"${BLUE}" "${_sshdRootDirective}" "${RESET}"

	"${_checkRootDirective[@]}" &> /dev/null && {

		printf \
			"%s[+] %s Parameter modified successfully on %s :) %s\n" \
			"${GREEN}" "${_sshdRootDirective}" "${_sshdConfig}" "${RESET}"

		return 10
	} || {
		printf >&2 \
			"%s[!] It seems like %s Parameter has not been modified on %s :( . Try it manually %s\n" \
			"${RED}" "${_sshdRootDirective}" "${_sshdConfig}" "${RESET}"

		return 1
	}
}

sshdSetup(){
	local _hostname=$( hostname --long ) _sshdService="sshd.service" _sshdPortStatus _sshdRootLoginStatus
	local _sshdPort=12021 _sshdConfig="/etc/ssh/sshd_config"

	printf \
		"\n%s[+] sshd's Binary and Service Status already checked previously on %s %s\n" \
		"${BLUE}" "${_hostname}" "${RESET}"
		
	sshdPortSetup

	_sshdPortStatus=$?
		
	(( $_sshdPortStatus == 1 )) && return 1

	sshdRootLoginSetup

	_sshdRootLoginStatus=$?

	(( $_sshdRootLoginStatus == 1 )) && return 1

	(( $_sshdPortStatus == 10 || $_sshdRootLoginStatus == 10 )) && {

		printf \
			"\n%s[+] Restarting %s on %s to apply previous changes...%s\n" \
			"${BLUE}" "${_sshdService}" "${_hostname}" "${RESET}"

		systemctl --quiet restart "${_sshdService}" 2> /dev/null

		if (( $? == 0 )) ; then

			printf \
				"%s[+] %s restarted correctly :) %s\n" \
				"${GREEN}" "${_sshdService}" "${RESET}"
		else
			printf >&2 \
				"%s[!] Something went wrong trying to restart %s %s :(\n" \
				"${RED}" "${_sshdService}" "${RESET}"

			return 1
		fi
	}

	printf \
		"\n%s[+] Checking whether %s Port is being used by Process related to %s...%s\n" \
		"${BLUE}" "${_sshdPort}" "${_sshdService}" "${RESET}"

	lsof -i:12021 \
	     -s TCP:listen \
	     -Pn \
	     -a \
	     -c sshd \
	     &> /dev/null

	(( $? == 0 )) && {

		printf \
			"%s[+] %s Port is being used by %s on %s :) %s\n" \
			"${GREEN}" "${_sshdPort}" "${_sshdService}" "${_hostname}" "${RESET}"
	} || {
		printf >&2 \
			"%s[!] %s Port is not being used by %s on %s :( %s \n" \
			"${RED}" "${_sshdPort}" "${_sshdService}" "${_hostname}" "${RESET}"

		return 1
	}

	printf \
		"%s[*] PermitRootLogin Parameter's Value is set to \"Yes\" on %s. Try log in as Root manually %s\n" \
		"${PURPLE}" "${_sshdConfig}" "${RESET}"
}

bashRCSkel(){
	local _bashRCSkel="/etc/skel/.bashrc" _userBashRC="/root/.bashrc"
	local _bashRCSkelLine="source ${_bashRCSkel}"
	local -a _grepSkelLine=(

		grep --quiet \
		     --ignore-case \
		     --perl-regexp \
		     "^${_bashRCSkelLine}$" \
		     "${_userBashRC}"		
	)

	printf \
		"\n%s[+] Checking if Line related to %s's Directives exists on %s...%s\n" \
		"${BLUE}" "${_bashRCSkel}" "${_userBashRC}" "${RESET}"

	"${_grepSkelLine[@]}"
	
	(( $? != 0 )) && {

		printf \
			"%s[+] Mentioned line ( %s ) does not exist %s\n" \
			"${RED}" "${_bashRCSkelLine}" "${RESET}"

		printf \
			"%s[+] Inserting Previous Line on %s...%s\n" \
			"${BLUE}" "${_userBashRC}" "${RESET}"

		printf "\n%s\n" "${_bashRCSkelLine}" 2> /dev/null >> "${_userBashRC}"

		if "${_grepSkelLine[@]}" ; then

			printf \
				"%s[+] Line related to %s's Directives inserted correctly on %s :) %s\n" \
				"${GREEN}" "${_bashRCSkel}" "${_userBashRC}" "${RESET}"

			return 0
		else
			printf >&2 \
				"%s[!] Could not insert Line related to %s's Directives on %s :( %s \n" \
				"${RED}" "${_bashRCSkel}" "${_userBashRC}" "${RESET}"

			return 1
		fi
	} || {
		printf \
			"%s[+] Mentioned Line ( %s ) already exists :) %s\n" \
			"${GREEN}" "${_bashRCSkelLine}" "${RESET}"
		
		return 0
	}
}

mailAliasSetup()
{
	local _aliasFile="/etc/aliases" _hostname=$( hostname --long )
	local _mailRegex='\w+(?:[\.\_\-%\+]\w+)*@\w+(?:[\.\-]\w+)*\.\w{2,}'
	local _grepAliases=(

		grep --quiet \
		     --ignore-case \
		     --perl-regexp \
		     "^root:\s?${_mailRegex}$" \
		     "${_aliasFile}"

	)

	local _aliasBlock="$( cat << CONTENT

### MAIL ALIASES -> $( hostname --long ) ###

# See man 5 aliases for format

########################################
#####  ALIASES TO LOCAL ACCOUNTS  ######
########################################

postmaster: root
amavis: root
clamav: root

########################################
##### ALIASES TO EXTERNAL ACCOUNTS #####
########################################

root: alertas@digitaldot.es

########################################
#####  ALIASES TO EXTERNAL FILES  ######
########################################


########################################
####  ALIASES TO COMMANDS|BINARIES  ####
########################################


CONTENT
	)"

	printf >&2 \
		"\n%s[+] Creating %s File with Necessary Alias on %s...%s\n" \
		"${BLUE}" "${_aliasFile}" "${_hostname}" "${RESET}"

	printf "%s" "${_aliasBlock}" 2> /dev/null > "${_aliasFile}"

	printf \
		"%s[+] It seems like %s File has been created...%s\n" \
		"${BLUE}" "${_aliasFile}" "${RESET}"

	printf \
		"\n%s[+] Checking its Existence and Content...%s\n" \
		"${BLUE}" "${RESET}"

	[[ -s $_aliasFile ]] && "${_grepAliases[@]}" && {

		printf \
			"%s[+] All Mail Aliases Set Up Correctly on %s :) %s\n" \
			"${GREEN}" "${_hostname}" "${RESET}"

		return 0

	} || {
		printf >&2 \
			"%s[!] Something went Wrong trying to Set Up %s's Mail Aliases :( %s\n" \
			"${RED}" "${_hostname}" "${RESET}"
		
		return 1
	}
}

mailAlertSetup(){
	local _userBashRC="/root/.bashrc" _hostname=$( hostname --long ) _aliasFile="/etc/aliases"
	local _prepareDir="/root/.prepare" _backupFile
	local -a _grepMailAlertBlock=(

		grep --quiet \
		     --ignore-case \
		     --perl-regexp \
		     '.*Root Shell Access from \$\{_ip\} on \$\( hostname \) Server' \
		     "${_userBashRC}"
	)

	local _mailAlertComm="$( cat << 'COMMAND'
		
# ROOT SHELL ACCESS'S MAIL ALERT

declare -A _IPs=()
declare -a _ipAddrs=( $(
	
	awk \
	    ' NR > 2 { print ( $1 == "root" ? $3 : "" ) } ' \
	    <( w )
) )

for _ip in "${_ipAddrs[@]}"
do
	[[ -v _IPs[${_ip}] ]] || _IPs["${_ip}"]=""
done

for _ip in "${!_IPs[@]}"
do
	mailx -s \
	      "Alert: Root Shell Access from ${_ip} on $( hostname ) Server" \
	      root \
	      <<< "ALERT - Root Shell Access on $( hostname ) at $( date ) from ${_ip}"
done
		
COMMAND
	)"

	printf \
		"\n%s[+] Let\'s Check if Mail Aliases are established correctly on %s %s...\n" \
		"${BLUE}" "${_hostname}" "${RESET}"

	printf \
		"%s[+] Checking if %s File exists on %s...%s\n" \
		"${BLUE}" "${_aliasFile}" "${_hostname}" "${RESET}"

	[[ -e $_aliasFile ]] && {

		printf \
			"%s[+] %s exists on %s %s\n" \
			"${PURPLE}" "${_aliasFile}" "${_hostname}" "${RESET}"

		printf \
			"\n%s[+] Creating Current %s's Backup as %s.bk on %s...%s\n" \
			"${BLUE}" "${_aliasFile}" "${_aliasFile##*/}" "${_prepareDir}" "${RESET}"

		[[ -e $_prepareDir ]] || mkdir "${_prepareDir}" 2> /dev/null

		[[ -e ${_prepareDir}/${_aliasFile##*/}.bk ]] && {

			printf >&2 \
				"%s[*] %s.bk already exists on %s %s\n" \
				"${PURPLE}" "${_aliasFile##*/}" "${_prepareDir}" "${RESET}"

			for i in {1..5}
			do
				[[ -e ${_prepareDir}/${_aliasFile##*/}${i}.bk ]] && {

					(( $i < 5 )) && continue || {

						printf >&2 \
							"%s[!] Several %s's Backups exist on %s. Check them and delete if They're not necessary %s\n" \
							"${PURPLE}" "${_aliasFile}" "${_prepareDir}" "${RESET}"

						return 1
					}
				}
				
				_backupFile="${_aliasFile##*/}${i}.bk"
				
				cp "${_aliasFile}" "${_prepareDir}/${_backupFile}" 2> /dev/null && break
			done
		} || {
			_backupFile="${_aliasFile##*/}.bk"

			cp "${_aliasFile}" "${_prepareDir}/${_backupFile}" 2> /dev/null
		}

		(( $? == 0 )) && {

			printf \
				"%s[+] It seems like %s's Backup has been generated...%s\n" \
				"${BLUE}" "${_aliasFile}" "${RESET}"

			printf \
				"\n%s[+] Checking %s existence on %s...%s\n" \
				"${BLUE}" "${_backupFile}" "${_hostname}" "${RESET}"

			[[ -e ${_prepareDir}/${_backupFile} ]] && {

				printf \
					"%s[+] %s exists on %s. %s's Backup created successfully then :) %s\n" \
					"${GREEN}" "${_backupFile}" "${_prepareDir}" "${_aliasFile}" "${RESET}"
					
				mailAliasSetup || return 1		

			} || {
				printf >&2 \
					"%s[!] %s does not exist on %s. Could not create %s's Backup then :( %s\n" \
					"${RED}" "${_backupFile}" "${_prepareDir}" "${_aliasFile}" "${RESET}"

				return 1
			}

		} || {
			printf >&2 \
				"%s[!] Something went wrong trying to Create %s's Backup :( %s\n" \
				"${RED}" "${_aliasFile}" "${RESET}"

			return 1
		}

	} || {
		printf >&2 \
			"%s[!] %s does not exist on %s :( \n" \
			"${RED}" "${_hostname}" "${RESET}"

		mailAliasSetup || return 1
	}

	printf \
		"\n%s[+] Checking if Root Shell Access's Mail Alert Block exists on %s...%s\n" \
		"${BLUE}" "${_userBashRC}" "${RESET}"

	"${_grepMailAlertBlock[@]}"

	(( $? != 0 )) && {

		printf \
			"%s[!] Root Shell Access's Alerts are not Set Up on %s :( %s\n" \
			"${RED}" "${_hostname}" "${RESET}"

		printf \
			"%s[+] Adding Mail Alert Block to %s File...%s\n" \
			"${BLUE}" "${_userBashRC##*/}" "${RESET}"

		printf "%s" "${_mailAlertComm}" 2> /dev/null >> "${_userBashRC}" && {

			printf \
				"%s[+] It seems like Mail Alert Block has been inserted...%s\n" \
				"${BLUE}" "${RESET}"

		} || {
			printf >&2 \
				"%s[!] Something went wrong trying to insert previous line :( %s\n" \
				"${RED}" "${RESET}"

			return 1
		}

		printf \
			"\n%s[+] Checking Mail Alert Block's Adition on %s...%s\n" \
			"${BLUE}" "${_userBashRC}" "${RESET}"

		"${_grepMailAlertBlock[@]}" && {

			printf \
				"%s[+] Mail Alert Block inserted correctly :) %s\n" \
				"${GREEN}" "${RESET}"

			printf \
				"%s[+] Root Shell Access's Alerts are Set Up then on %s %s\n" \
				"${GREEN}" "${_hostname}" "${RESET}"

			return 0

		} || {
			printf >&2
				"%s[!] Could not insert Mail Alert Block :( %s\n" \
				"${RED}" "${RESET}"

			return 1
		}

	} || {
		printf \
			"%s[+] Root Shell Access's Alerts are already Set Up on %s :) %s\n" \
			"${GREEN}" "${_hostname}" "${RESET}"
		
		return 0
	}

}

bashRCSetup(){
	local _hostname=$( hostname --long ) _bashRCSkel="/etc/skel/.bashrc"
	local _bashRCSkelLine="source ${_bashRCSkel}"
	local _userBashRC="/root/.bashrc"

	[[ -e $_bashRCSkel ]] || {

		printf >&2 \
			"\n%s[!] %s does not exist on %s :( %s\n" \
			"${RED}" "${_bashRCSkel}" "${_hostname}" "${RED}"

		return 1
	}

	printf \
		"\n%s[+] Checking if %s exists on %s Path...%s\n" \
		"${BLUE}" "${_bashRCSkel##*/}" "${HOME}" "${RESET}"

	[[ ! -e $_userBashRC ]] && {
		
		printf >&2 \
			"%s[!] %s does not exist on %s %s\n" \
			"${RED}" "${_bashRCSkel##*/}" "${HOME}" "${RESET}"

		printf \
			"\n%s[+] Creating %s File and Adding Line related to %s's Directives on it...%s\n" \
			"${BLUE}" "${_userBashRC}" "${_bashRCSkel}" "${RESET}"

		printf "\n%s\n" "${_bashRCSkelLine}" 2> /dev/null >> "${_userBashRC}"

		printf \
			"%s[+] It seems like %s has been created%s\n" \
			"${BLUE}" "${_userBashRC}" "${RESET}"

		printf \
			"\n%s[+] Checking %s File creation...%s\n" \
			"${BLUE}" "${_userBashRC}" "${RESET}"

		if [[ -e $_userBashRC ]] ; then

			printf \
				"%s[+] %s File created correctly on %s :) %s\n" \
				"${GREEN}" "${_userBashRC##*/}" "${HOME}" "${RESET}"
		else
			printf >&2 \
				"%s[+] Could not create %s on %s :(\n" \
				"${RED}" "${_userBashRC##*/}" "${HOME}" "${RESET}"

			return 1
		fi

		bashRCSkel || return 1
		
	} || {
		printf \
			"%s[+] %s exists on %s %s\n" \
			"${GREEN}" "${_bashRCSkel##*/}" "${HOME}" "${RESET}"
		
		bashRCSkel || return 1
	}

	mailAlertSetup || return 1	
}

main(){
	local -A flags=()
	local -A optArgs=()
	local pleskSecretKey # Plesk's API REST Secret Key
	
	(( $# == 0 )) && {

		printf >&2 \
			"\n\t%s[!] Try -h | --help to display Info about this Script :)%s\n\n" \
			"${BLUE}" "${RESET}"
		exit 1
	}

	while (( $# > 0 )) ; do

		[[ $1 == --@(password|user)=* ]] && set -- "${1%%=*}" "${1##*=}" "${@:2}" && continue 	# --opt=arg Option Format

		case "${1}" in

			-[hrc][^-]* )		set -- "${1:0:2}" "-${1:2}" "${@:2}"			# -abc Option Format
						continue
						;; 			

			-[pu]?*	)		set -- "${1:0:2}" "${1:2}" "${@:2}"			# -aSomething Option Format
						continue
						;; 	

			-h | --help )		showHelp
						exit 0
						;;

			-u | --user )		(( flags[u]++ ))
						optArgs[user]="${2}"
						shift
						;;

			-p | --password )	(( flags[p]++ ))
						optArgs[passwd]="${2}"
						shift
						;;

			-r | --run )		(( flags[r]++ ))
						;; 

			-c | --check )		(( flags[c]++ ))
						;;

			-- )			shift ; break
						;;

			* )			printf >&2 \
							"\n\t%s[!] Unknown Option -> %s. Try -h | --help :)%s\n\n" \
							"${RED}" "${1##"${1%%[^-]*}"}" "${RESET}"
						exit 99
						;;
		esac
		shift
	done

	[[ -z "${optArgs[user]}" || -z "${optArgs[passwd]}" ]] && {
		printf >&2 \
			"\n%s[!] Plesk's Admin User and Password must be provided. Try -h | --help :) %s\n\n" \
			"${RED}" "${RESET}"

		cat << ADVISE
	${BLUE}Follow one of these formats ->

		${0##*/} -u john -p passwd
		${0##*/} -ujohn -ppasswd
		${0##*/} --user john --password passwd
		${0##*/} --user=john --password=password
	${RESET}
ADVISE
		exit 1

	}
	
	userTable "${optArgs[user]}" "${optArgs[passwd]}"

	table "General Checking Section"

	systemdChecker		|| exit 1
	checkTools		|| exit 1
	pleskChecker 		|| exit 1

	table "Plesk Auth. Section"

	checkPleskCreds "${optArgs[user]}" "${optArgs[passwd]}"	|| exit 1

	exec 3>&1
	_pleskSecretKey=$( generatePleskAPIKey "${optArgs[user]}" "${optArgs[passwd]}" 2>&3 ) || exit 1 # Explicit FD Duplication using FD(1,2,3)
	exec 3>&-

	secretKeyTable "${_pleskSecretKey}"

	table "Specific Checking Section"

	checkService || exit 1

 	table " Plesk Email Security"
 
 	pleskEmailSecurity "${_pleskSecretKey}" || exit 1
 
 	table " Amavis - SpamAssassin"
 
 	amavisdSpamdChecker || exit 1
 
 	table "     Memory - Swap"
 
 	makeSwap $( getMemoryInfo ) || exit 1	# $( Function ) : FD 1 -> Temporal Buffer -> Variable ; FD 2 -> Screen
 
 	table "MySQL Ramdisk - Checking"
 
 	mySQLRamDisk || exit 1
 
 	table "ClamAV Suite Section"
 
 	clamAVSetup || exit 1

	table "SSH Service Setup Section"

	sshdSetup || exit 1

	table ".BashRC's ${USER^} Setup Section"

	bashRCSetup || exit 1

}

RESET=$(tput sgr0)
RED=$(tput setaf 1)
PINK=$(tput setaf 219)
PURPLE=$(tput setaf 200)
BLUE=$(tput setaf 159)
GREEN=$(tput setaf 83)

trap sigintHandler SIGINT
trap 'tput cnorm' EXIT			# Recover Terminal Cursor ¡¡ Implement function Cleanup() if more actions are needed !!

banner
tput civis 				# Hide Terminal Cursor
main "${@}"
