# A shell-script to generate PDF diffs of LaTeX repositories

# What it does

* `git diff --name-only` is called to get all changed files
* all files with endings ".tex" are selected
	* a diff of the master-document is generated
	* a diff of all chapters that changed is generated
	* an `\includeonly{chapterX}` is added to the master-diff-document 
	  so that only chapters that have changed are compiled
	* the master-diff is compiled 
	* the generated pdf is moved to the main folder
	* all files required to compile the diff are removed
	* original files are kept as-is !  


# What it does (currently) not do

* include changes to files other than .tex files
  (e.g. if an image changed but it's name did not, this will not show up)
* if no ".tex" file changed, no message is returned and nothing happens


# Usage

* install a perl-distribution (like strawberry-perl) (required for latexdiff)
* install latexdiff (e.g. via MikTeX console)

* update "ldiff.sh"
	* update the path to "perl.exe" (`perl_exec`) 
		* this is required to avoid issues with git's own perl-distribution
	* update the path to the "latexdiff" perl-script (`latexdiffpath`)
	* update the name of the Master-document (`MASTER`)

* add the following lines to the git config file located here:
	```
	[alias]
		ldiff = difftool -t latex 
	[difftool.latex]
		cmd = "  >>>  PATH TO ldiff.sh  <<<  " "$LOCAL" "$REMOTE"
	```
* READY, now simply use it via:
	```
	git ldiff
	```

