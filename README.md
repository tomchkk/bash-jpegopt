JPEGOPT
=======

Optimise multiple JPEGs with jpegtran
-------------------------------------

jpegopt is a small shell script made to enable use of the [libjpeg jpegtran utility][1] recursively—to optimise mulitiple JPEG files, including those located in sub-directories—rather than have to laboriously enter jpegtran commands for each file to be optimzed.

jpegopt was built and tested using jpegtran version 8d and the Bourne shell, on Mac OS X. It may work with other jpegran versions, in other shells, and on other unix-like systems – though this is untested.

This script was a learning exercise, [inspired by][2], and [owing much][3] to these answers on stackoverflow. It was also my first attempt at shell scripting, so much reference was made to this [Shell Scripting Primer][4] and this [Advanced Bash-Scripting Guide][5]. It is almost certainly overkill, but I enjoyed making it and intend to put it to good use.

[1]: http://ijg.org
[2]: http://stackoverflow.com/questions/5579183/jpegtran-optimize-without-changing-filename/12066282#12066282
[3]: http://stackoverflow.com/questions/12831293/how-to-recursivly-use-jpegtran-command-line-to-optimise-all-files-in-subdirs
[4]: https://developer.apple.com/library/mac/documentation/OpenSource/Conceptual/ShellScripting
[5]: http://www.faqs.org/docs/abs/HTML/index.html

### Installation

- clone the directory from git
  + **_HOW?_**
  + `https://github.com/lickyourlips/script-jpegopt.git`
- modify file permissions:
  + `sudo chmod 755 jpegopt.sh`
- copy the file to /usr/local/bin:
  + `sudo cp jpegopt.sh /usr/local/bin/jpegopt.sh`

### Usage

- ##### jpegopt Help

	To print help menus for both jpegopt and jpegtran, enter the following at the command prompt:

		jpegopt.sh -h

- ##### jpegopt Arguments

	jpegopt accepts multiple arguments— in no particular order—though by convention they are listed as follows: `directory`, `options` and `jpegtran:switches`.

	+ `directory` – the directory in which to search for JPEG files. If omitted, the script will default to the current working directory.

	+ `options` – jpegopt's own options.

	+ `jpegtran:switches` – valid jpegtran switches.

- ##### jpegopt Options

    As well as accepting all of jpegtran's switches, jpegopt also has it's own options:

    + `-maxdepth` sets the maximum directory depth at which to search for JPEG files. `-maxdepth` defaults to 1, which would limit the search to the directory given as the directory argument (or the current working directory, if the argument is omitted). This option passed as `-maxdepth 2` would search the given directory and any immediate child directories, and so on...
    
    + `-overwrite` sets the method by which jpegopt handles any original files to be optimized. The default setting, `-overwrite bk`, takes a back-up of the original file and replaces it with the optimized file. Passing this option as `-overwrite dx` will destructively replace the orginal file with the optimized one. `-overwrite off` disables this feature altogether, resulting in two files: _original.jpg_ and _original.jpg.optmzd_.
    
    + `-dryrun` enables the dry-run mode, giving a list of files found that would be optimized, according to the given options.
    
    + `-debug` enables a debug mode, printing the jpegtran command that would be used, according to the given options.

- ##### jpegtrans Switches

	Since the purpose of jpegopt is to optimize JPEG files, certain of jpegtran's switches are enabled by default, as detailed below. All other valid jpegtran switches can be passed as arguments to jpegopt.

	+ `-copy` – the value of this switch defaults to `none`. This value can be over-ridden with any other valid value. The switch can be disabled by passing `-copy off` as an argument to jpegopt.

	+ `-optimize` – this switch is enabled by default, but can be disabled by passing `-optimize off` as an argument to jpegopt.

	**N.B.** jpegtran already handles non-existent switches and invalid argument values gracefully, so jpegopt is purposefully unaware of all available jpegtran switches.

### Unit Testing

From the cloned source directory, jpegopt can be tested using the following command:

- `./tests/jpegopt.test.sh`

### Disclaimer

This was a weekend(ish) project. Feel free to make use of the utility or the source as you wish, but you do so entirely **_at your own risk_**.