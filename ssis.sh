#!/bin/bash
# ssis : Simple System Information Script
# Run "man ssis" for details.

# shellcheck source=/dev/null

version="1.0"

vars=""

# Load the configuration file.
source ~/.ssisrc 2> /dev/null || ~/.config/ssis/ssisrc 2> /dev/null


usage() {
	printf "Usage:\\n"
	# printf doesn't let me add a "-" to the beginning of a string
	# thanks printf /s
	printf " --help      Show usage\\n"
	printf " --version   Show version\\n"
	printf " -l          Lame mode/disable fortune & cowsay\\n"
	printf " -f          Enable figlet text banner\\n"
	exit
}

date() {
	# 'man strftime'
	printf "%($1)T\\n" "-1"
}

# pretty much completely copied from
# https://www.github.com/dylanaraps/neofetch
get_args() {
	while [[ "$1" ]]; do
		case $1 in
			"--help" ) usage ;;
			"--version" )
				printf "ssis %s \\n" "$version"
				exit
			;;
            # This argument is not in --help, because this is only meant to be used by developers, not users.
			"--makeman" )
				help2man --name "Simple System Information Script" --no-info --output ./ssis.1 --include ./ssis.sh
			;;
			"-l" ) vars="$vars lame," ;;
			"-f" ) vars="$vars figlet," ;;
		esac
		shift
	done
}
get_args "$@"

# Get the variables from /etc/os-release. We only use $PRETTY_NAME.
source /etc/os-release

while true; do
	clear

	# Display a text banner if -f argument is used.
	if [[ $vars == *"figlet"* ]]; then
		figlet -w 1000 System Information
	else
		printf "System Information:\\n\\n"
	fi

	if command -v uname &> /dev/null; then
		printf "OS: %s \\n" "$PRETTY_NAME"
		uname -a
	fi

	if command -v uptime &> /dev/null; then
		printf "Uptime: "
		uptime -p
	fi

	if command -v who &> /dev/null; then
		printf "Logged in users:\\n"
		who
	fi

	if command -v ip &> /dev/null; then
		printf "IP address: %s \\n" "$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')"
	fi

	printf "Date: "
	date "%d-%m-%Y %H:%M:%S"

	if command -v free &> /dev/null; then
		printf "Memory:\\n"
		free -h
	fi

	if command -v ps &> /dev/null; then
		printf "Top Processes:\\n"
		ps all | head -n 10
	fi

	if command -v df &> /dev/null; then
		printf "Disk Space:\\n"
		df -h
	fi

	if [[ $vars != *"lame"* ]]; then
		fortune -s | cowsay -W 50 -f tux
	fi

	printf "\\nRefreshing in 15 seconds.\\n"

	# "sleep" is not a bash command, so we use "read".
	# https://www.github.com/dylanaraps/pure-bash-bible
	# Actually, a lot of things are from there. Huge thanks.
	exec {sleep_fd}<> <(:)
	read -r -t 15 -u $sleep_fd
done
