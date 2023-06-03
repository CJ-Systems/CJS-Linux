#!/bin/sh
#
# Initial design by ChrisJStone https://github.com/ChrisJStone
# Code Review and major contribution by: Toby Speight https://stackexchange.com/users/6229027/toby-speight
#

. ./lib/log4sh
. ./lib/shlib_ansi

# Download single file from URL ($1) and save it to local file ($2)
downloadfile() {
	log DEBUG "${shlib_ansi_blue}Downloading $2${shlib_ansi_none}"
	wget --quiet --show-progress --no-use-server-timestamps "$1" -O "$2"
}

# true if checksum record line in $1 matches MD5 of file $2
verifyfile() {
	if awk -vfile="$2" '$2==file' "$1" | md5sum --status --check 2>/dev/null
	then
		log DEBUG "${shlib_ansi_blue}Checksum valid for $bn${shlib_ansi_none}"
		return 0
	else
		log DEBUG "${shlib_ansi_blue}Checksum invalid for $bn${shlib_ansi_none}"
		return 1
	fi
}

# Download and verify multiple files
# INPUTS:   $1 file containing list of URLS to download from. 
#               Example Line: "https://sourceware.org/pub/binutils/releases/binutils-2.40.tar.xz"
#           $2 file containing list of valid checksums and filenames
#               Example Line: "007b59bd908a737c06e5a8d3d2c737eb  binutils-2.40.tar.xz"
download()
{
	file_list=$1
	check_sums=$2
	result=true
	while read -r f
	do
		# Get name file of file to download
		bn=$(basename "$f")
		# If file not present attempt to download
		if ! [ -f "$bn" ]
		then
			log INFO "${shlib_ansi_green}Downloading $bn${shlib_ansi_none}"
			downloadfile "$f" "$bn"
		fi
		if verifyfile "$check_sums" "$bn"
		then
			log DEBUG "${shlib_ansi_blue}Verification of $bn successful${shlib_ansi_none}"
			continue;
		fi
        
		log WARN "${shlib_ansi_yellow}Verification of $bn failed. Retrying download${shlib_ansi_none}"
	        if downloadfile "$f" "$bn" && verifyfile "$check_sums" "$bn"
		then
			log DEBUG "${shlib_ansi_blue}Verification of $bn successful${shlib_ansi_none}"
			continue;
		fi

		log FATAL "${shlib_ansi_red}Failed to verify $bn download unsuccessful${shlib_ansi_none}"
		result=false
		if [ $result = "false" ]
		then
			exit
		fi
	done <"$file_list"
       
}

shlib_ansi_init auto

download "$1" "$2"