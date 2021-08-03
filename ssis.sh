#!/bin/bash
# ssis : Simple System Information Script
# Copyright (C) 2021 StudioChew/roope
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
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
	printf " --help : Show usage\\n"
	printf " --version : Show version\\n"
	printf " --makeman : Generate a manpage for ssis\\n"
	printf " -l : Lame mode/disable fortune & cowsay\\n"
	printf " -f : Enable figlet text banner\\n"
	printf " -p : Show the public IP\\n"
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
				help2man --name="Simple System Information Script" --section=1 --no-info --output=./ssis.1 ./ssis.sh
				exit
			;;
			"-l" ) vars="$vars lame," ;;
			"-f" ) vars="$vars figlet," ;;
			"-p" ) vars="$vars publicip," ;;
		esac
		shift
	done
}
get_args "$@"

# Get the variables from /etc/os-release. We only use $PRETTY_NAME.
source /etc/os-release

# Get the Public IP.
if [[ $vars == *"publicip"* ]]; then
	pubip="$(curl -s ifconfig.me)"
fi

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

	if [[ $vars == *"publicip"* ]] &> /dev/null; then
		printf "Public IP: %s \\n" "$pubip"
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

	if [ -e /var/log/auth.log ]; then
		printf "Authentication log:\\n"
		tail -n 10 /var/log/auth.log
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
