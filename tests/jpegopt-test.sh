#!/bin/sh

function testCase() {
	local TEST_INPUT="$(sh -c "$1")"
	local EXPECTED="$2"

	if test "$TEST_INPUT" = "$EXPECTED"; then
		printf "."
		return 0
	else
		echo "Error:"
		echo "* Actual (-)"
		echo " - $TEST_INPUT"
		echo "* Expected (+)"
		echo " + $EXPECTED"
		return 1
	fi
}


function basicFunctionalityTests () {
	# a debug of the script's current directory finds no jpegs
	testCase "./jpegopt.sh -debug" "jpegopt: No files found"

	# a debug in tests gives expected default jpegtran command for a test jpeg
	testCase "./jpegopt.sh -debug tests" "jpegtran -copy none -optimize -outfile tests/test-img.jpg.optmzd tests/test-img.jpg"

	# a dry run of the script's current directory finds no jpegs
	testCase "./jpegopt.sh -dryrun" "jpegopt: No files found"

	# a dry run in tests finds a test jpeg
	testCase "./jpegopt.sh -dryrun tests" " --> tests/test-img.jpg"
}

function directoryOptionsTests () {
	# include absolute directory as initial argument
	testCase "./jpegopt.sh $PWD/tests -debug -progressive" "jpegtran -copy none -optimize -progressive -outfile $PWD/tests/test-img.jpg.optmzd $PWD/tests/test-img.jpg"

	# include absolute directory as secondary argument
	testCase "./jpegopt.sh -debug $PWD/tests -trim" "jpegtran -copy none -optimize -trim -outfile $PWD/tests/test-img.jpg.optmzd $PWD/tests/test-img.jpg"

	# include absolute directory as final argument
	testCase "./jpegopt.sh -debug $PWD/tests" "jpegtran -copy none -optimize -outfile $PWD/tests/test-img.jpg.optmzd $PWD/tests/test-img.jpg"

	# relative directories are also handled
	testCase "./jpegopt.sh -debug tests" "jpegtran -copy none -optimize -outfile tests/test-img.jpg.optmzd tests/test-img.jpg"

	# non-existent directories are ignored
	testCase "./jpegopt.sh -debug foo/" "jpegopt: No files found"

	# arguments resembling directories are ignored
	testCase "./jpegopt.sh -debug -md 2 foo/" "jpegtran -copy none -optimize -outfile $PWD/tests/test-img.jpg.optmzd $PWD/tests/test-img.jpg"

	# non-existent arguments resembling directories are ignored whatever their position
	testCase "./jpegopt.sh -debug foo -md 2" "jpegtran -copy none -optimize -outfile $PWD/tests/test-img.jpg.optmzd $PWD/tests/test-img.jpg"
}

function maxdepthOptionTests () {
	# search in the current dir and up to a maximum of one child dir
	testCase "./jpegopt.sh -dryrun -maxdepth 2" " --> $PWD/tests/test-img.jpg"

	# -maxdepth must be given an argument
	testCase "./jpegopt.sh -dryrun -maxdepth" "Error: Option '-maxdepth' requires a valid argument, none given."

	# -maxdepth won't accept an argument that is not a number
	testCase "./jpegopt.sh -dryrun -maxdepth foo" "Error: 'foo' is not a valid argument of option '-maxdepth'."

	# -maxdepth won't accept a float as an argument
	testCase "./jpegopt.sh -dryrun -maxdepth 1.1" "Error: '1.1' is not a valid argument of option '-maxdepth'."
}

function overwriteOptionTests () {
	# -overwrite only accepts defined arguments
	testCase "./jpegopt.sh -dryrun tests -overwrite kdjlf" "Error: 'kdjlf' is not a valid argument of option '-overwrite'."

	# -overwrite must be given an argument
	testCase "./jpegopt.sh -dryrun -overwrite" "Error: Option '-overwrite' requires a valid argument, none given."

	# -overwrite accepts arguments 'off', 'bk' or 'dx' (the final occurrence is used)
	testCase "./jpegopt.sh -dryrun tests -overwrite off -overwrite bk -overwrite dx" " --> tests/test-img.jpg"

	# -overwrite can't receive an option as an argument
	testCase "./jpegopt.sh -dryrun tests -overwrite -test" "Error: '-test' is not a valid argument for an option. Option arguments should not begin with a hyphen."
}

function jpegtranDefaultsTests () {
	# jpegtran comman defaults to '-copy none' and '-optimize' switches
	testCase "./jpegopt.sh -debug tests" "jpegtran -copy none -optimize -outfile tests/test-img.jpg.optmzd tests/test-img.jpg"
}

function jpegtranCopyTests () {
	# '-copy off' disables -copy switch
	testCase "./jpegopt.sh -debug tests -copy off" "jpegtran -optimize -outfile tests/test-img.jpg.optmzd tests/test-img.jpg"

	# '-copy all' overwrites default -copy switch value
	testCase "./jpegopt.sh -debug -maxdepth 2 -copy all" "jpegtran -copy all -optimize -outfile $PWD/tests/test-img.jpg.optmzd $PWD/tests/test-img.jpg"

	# -copy switch value cannot be omitted
	testCase "./jpegopt.sh -debug -copy" "Error: Option '-copy' requires a valid argument, none given."

	# -copy switch value cannot be another option
	testCase "./jpegopt.sh -debug -copy -foo" "Error: '-foo' is not a valid argument for an option. Option arguments should not begin with a hyphen."
}

function jpegtranOptimizeTests () {
	# '-optimize off' disables -optimize switch
	testCase "./jpegopt.sh -debug tests -optimize off" "jpegtran -copy none -outfile tests/test-img.jpg.optmzd tests/test-img.jpg"

	# -optimize switch ignores invalid arguments
	testCase "./jpegopt.sh -debug tests -optimize blaa" "jpegtran -copy none -optimize -outfile tests/test-img.jpg.optmzd tests/test-img.jpg"

	# -optimize switch doesn't ignore following directories
	testCase "./jpegopt.sh -debug -optimize tests" "jpegtran -copy none -optimize -outfile tests/test-img.jpg.optmzd tests/test-img.jpg"

	# -optimize switch can be followed by another option
	testCase "./jpegopt.sh -debug tests -optimize -trim" "jpegtran -copy none -optimize -trim -outfile tests/test-img.jpg.optmzd tests/test-img.jpg"
}

function jpegtranKeyOnlySwitchesTests () {
	# -progressive switch is included
	testCase "./jpegopt.sh -debug -maxdepth 2 -progressive" "jpegtran -copy none -optimize -progressive -outfile $PWD/tests/test-img.jpg.optmzd $PWD/tests/test-img.jpg"

	# -progressive and -transverse switches are included
	testCase "./jpegopt.sh -debug -maxdepth 2 -progressive -transverse" "jpegtran -copy none -optimize -progressive -transverse -outfile $PWD/tests/test-img.jpg.optmzd $PWD/tests/test-img.jpg"

	# -perfect switch are included
	testCase "./jpegopt.sh -debug -maxdepth 2 -perfect" "jpegtran -copy none -optimize -perfect -outfile $PWD/tests/test-img.jpg.optmzd $PWD/tests/test-img.jpg"
}

function jpegtranKeyValueSwitchesTests () {
	# -crop switch retains its arguments
	testCase "./jpegopt.sh -debug -md 2 -crop 23x45+800+600" "jpegtran -copy none -optimize -crop 23x45+800+600 -outfile $PWD/tests/test-img.jpg.optmzd $PWD/tests/test-img.jpg"

	# multiple key–value switches are retained
	testCase "./jpegopt.sh -debug -md 2 -rotate 90 -scale 1/4 -scans script.sh" "jpegtran -copy none -optimize -rotate 90 -scale 1/4 -scans script.sh -outfile $PWD/tests/test-img.jpg.optmzd $PWD/tests/test-img.jpg"

	# multiple key–value and key-only switches are retained
	testCase "./jpegopt.sh -debug -md 2 -rotate 90 -arithmetic -scale 1/4" "jpegtran -copy none -optimize -rotate 90 -arithmetic -scale 1/4 -outfile $PWD/tests/test-img.jpg.optmzd $PWD/tests/test-img.jpg"

	# multiple key–value and key-only switches are retained
	testCase "./jpegopt.sh -debug -md 2 -rotate 90 foo -arithmetic -scale 1/4 foobar" "jpegtran -copy none -optimize -rotate 90 -arithmetic -scale 1/4 -outfile $PWD/tests/test-img.jpg.optmzd $PWD/tests/test-img.jpg"
}

basicFunctionalityTests
directoryOptionsTests
maxDepthOptionTests
overwriteOptionTests
jpegtranDefaultsTests
jpegtranCopyTests
jpegtranOptimizeTests
jpegtranKeyOnlySwitchesTests
jpegtranKeyValueSwitchesTests
echo



