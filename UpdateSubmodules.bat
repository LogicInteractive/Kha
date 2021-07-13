git submodule update --recursive
git submodule foreach --recursive git fetch
::git submodule foreach git merge origin master