#!/bin/sh

## A basic shell script to run command 'jpegtran -optimize' recursively – with any of its available options set – on one of the following:
	# a) the current directory
	# b) the last occurrence of a directory in the argument list

VERSION="1.0"

function argHasAValue () {
	if test -n "$1"; then
		return 0
	else
		return 1
	fi
}

function printHelp () {
	# look into printf usage
	HELP_MSG="================================================================\n"
	HELP_MSG+="jpegopt usage: jpegopt [directory] [options] [jpegtran:switches]\n"
	HELP_MSG+="================================================================\n"
	HELP_MSG+="* Directory:\n"
	HELP_MSG+="A valid relative or absolute directory path (default = current working directory)\n"
	HELP_MSG+="\n"
	HELP_MSG+="* Options:\n"
	HELP_MSG+=" -help|-h 	 Print this help menu\n"
	HELP_MSG+=" -maxdepth|-md N Set maximum directory depth for jpeg file search (default = 1)\n"
	HELP_MSG+=" -overwrite off Save outfile as .optmzd and leave original untouched\n"
	HELP_MSG+=" -overwrite bk 	 Back-up then overwrite original with optimized file (default)\n"
	HELP_MSG+=" -overwrite dx 	 Destructively overwrite original with optimized file\n"
	HELP_MSG+=" -dryrun|-dry 	 Perform a dry run without making any changes\n"
	HELP_MSG+=" -debug 	 Print the jpegtran command\n"
	HELP_MSG+="\n"
	HELP_MSG+="* jpegtran Switches (all jpegtran switches can be set as options of jpegopt):\n"
	HELP_MSG+=" -copy 		 Defaults to 'none'. Override with any valid value; disable with '-copy off'\n"
	HELP_MSG+=" -optimize 	 Enabled by default; disable with '-optimize off'\n"
	HELP_MSG+="\n"
	HELP_MSG+="================================================================\n"

	printf "$HELP_MSG\n"
}

function argIsDirectory () {
	if test -d "$1"; then
		return 0
	else
		return 1
	fi
}

function argIsEmpty () {
	if test -z "$1"; then
		return 0
	else
		return 1
	fi
}

function printErr () {
	case "$1" in
		( "overwriteArgIsInvalid" ) ERR_MSG="'$2' is not a valid argument of option '-overwrite'. This option takes one of values 'off', 'bk' or 'dx'." ;;
		( "argNotPositiveInteger" ) ERR_MSG="'$2' is not a positive integer." ;;
		( "argIsOption" ) ERR_MSG="'$2' is not a valid argument for an option. Option arguments should not begin with a hyphen." ;;
		( "argMissing" ) ERR_MSG="jpegtran switch '$2' requires a valid argument, none given." ;;
	esac
	echo "Error: $ERR_MSG"
}

function argIsPositiveInteger () {
	re='^[0-9]+$'
	if ! [[ $1 =~ $re ]]; then
	   return 1
	else
		return 0
	fi
}

function argResemblesOption () {
	case "$1" in
		( "-"* ) return 0 ;; # argument begins with a hyphen - i.e. looks like an option
		( * ) return 1 ;;
	esac
}

function argArrayContainsValue () {
	ARRAY=( `echo "$1"` )
	case "${ARRAY[@]}" in 
		( *"$2"* ) return 0 ;;
		( * ) return 1 ;;
	esac
}

function filesAreFound () {
	if test -n "$(find -E "$1" -maxdepth "$2" -type f -iregex "$3")"; then
		return 0
	else
		return 1
	fi
}

function findThenExecute () {
	find -E "$1" -maxdepth "$2" -type f -iregex "$3" -exec sh -c "$4" \;
}

# jpegopt defaults
MODE=""
OVRWRT_MODE="bk"
OVRWRT_ARGS=("off" "bk" "dx")
MAX_DEPTH=1
JPEG_IREGX=".*\.(jpg|jpeg)"

# jpegtran defaults
COPY_SWITCH="-copy none"
OPT_SWITCH="-optimize"
SWITCHES=""

# parse script arguments
while (argHasAValue "$1") ; do

	if test "${1}" = "-version" || test "${1}" = "-v"; then
		echo "jpegopt.sh version: $VERSION"
		exit

	elif test "${1}" = "-help" || test "${1}" = "-h"; then
		printHelp
		sh -c "jpegtran -h"
		exit

	elif ( argIsDirectory "${1}" ); then
		DIR="${1}"

	elif test "${1}" = "-maxdepth" || test "${1}" = "-md"; then
		# replace MAX_DEPTH default with subsequent arg (value); perform additional shift
		if ( argIsEmpty "${2}" ); then
			printErr "argMissing" "${1}"
			exit
		elif ( argIsPositiveInteger "${2}" ); then
			MAX_DEPTH=${2}
			shift # additional shift
		else
			printErr "argNotPositiveInteger" "${2}"
			exit
		fi

	elif test "${1}" = "-overwrite"; then
		if ( ! argResemblesOption "${2}" ) then
			if ( argArrayContainsValue "`echo ${OVRWRT_ARGS[@]}`" "${2}" ); then
				# replace OVRWRT_MODE default with subsequent arg (value); peform aditional shift
				OVRWRT_MODE="${2}"
				shift # additional shift
			else
				printErr "overwriteArgIsInvalid" "${2}"
				exit
			fi
		else
			printErr "argIsOption" "${2}"
			exit
		fi

	elif test "${1}" = "-dryrun" || test "${1}" = "-dry"; then
		MODE="dryrun"

	elif test "${1}" = "-debug"; then
		MODE="debug"

	elif test "${1}" = "-copy"; then
		if ( argIsEmpty "${2}" ); then
			printErr "argMissing" "${1}"
			exit
		elif test "${2}" = "off"; then
			COPY_SWITCH=""
			shift # additional shift
		else
			if ( argResemblesOption "${2}" ); then
				printErr "argIsOption" "${2}"
				exit
			else
				# replace COPY_SWITCH default with args 1 and 2 (key and value)
				COPY_SWITCH="${1} ${2}"
				shift # additional shift
			fi
		fi
	
	elif test "${1}" = "-optimize"; then
		if test "${2}" = "off"; then
			# -optimize only accepts 'off' as an argument
			OPT_SWITCH=""
			shift # additional shift
		else
			if ( ! argResemblesOption "${2}"); then
				# ignore arguments following '-optimize' that don't look like an option
				shift # additional shift
			fi
		fi

	else		
		if ( argResemblesOption ${1} ); then
			# build any remaining jpegtran switches
			if ( ! argResemblesOption ${2} ); then
				SWITCHES+="${1} ${2} "
				shift # additional shift
			else
				SWITCHES+="${1} "
			fi
		fi

	fi

	shift # main shift

done

if (argIsEmpty "$DIR"); then # is $DIR is a zero-length string?
	# DIR was not passed in the arguments list, so we'll assign pwd
	DIR="$PWD"
fi

if (filesAreFound "$DIR" "$MAX_DEPTH" "$JPEG_IREGX"); then

	# the purpose of this script is to optimize jpeg files, so -optimize switch is hardcoded
	CMD="jpegtran $COPY_SWITCH $OPT_SWITCH $SWITCHES -outfile '{}'.optmzd '{}'"

	case "$MODE" in
		( "debug" ) JTRAN_STATEMENT="echo $CMD" ;; # echo the jpegtran statement
		( "dryrun" ) JTRAN_STATEMENT="echo ' --> {}'" ;; # echo file(s) to be optimized
		( * ) JTRAN_STATEMENT="$CMD; echo ' --> {}'" ;; # run $CMD and echo the optimized file(s)
	esac
	# find all jpeg files in DIR, to a given max depth, run each one through jpegtran
	findThenExecute "$DIR" "$MAX_DEPTH" "$JPEG_IREGX" "$JTRAN_STATEMENT"

	if test OVRWRT_MODE != "off" && \
		(filesAreFound "$DIR" "$MAX_DEPTH" "$JPEG_IREGX\.optmzd"); then

		case "$OVRWRT_MODE" in
			( "bk" ) OVRWRT_STATEMENT="mv '{}' '{}'~; mv '{}'.optmzd '{}'" ;;
			( "dx" ) OVRWRT_STATEMENT="mv '{}'.optmzd '{}'" ;;
		esac
		# move optimized files to original file name, with or without backup
		findThenExecute "$DIR" "$MAX_DEPTH" "$JPEG_IREGX" "$OVRWRT_STATEMENT"
	fi

else
	echo "jpegopt: No files found"
fi
