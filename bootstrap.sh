#!/usr/bin/env bash






################################################################################
# Default Options
################################################################################

FORCE=false
SCRIPTS=true
SHOW_HELP=false
SOURCEABLES=true
SYMLINKABLES=true





################################################################################
# Parse command line arguments
################################################################################

for i in "$@"; do
  case $i in
    -h|--help|-\?)
      SHOW_HELP=true
      ;;
    -f|--force)
      FORCE=true
      shift
      ;;
    --no-scripts)
      SCRIPTS=false
      shift
      ;;
    --no-sourceables)
      SOURCEABLES=false
      shift
      ;;
    --no-symlinkables)
      SYMLINKABLES=false
      shift
      ;;
    *)
      echo "Unrecognized option: $i"
      shift
      ;;
  esac
done





################################################################################
# Create all of our functions
################################################################################

function addSourceablesToBashrc() {
  # Source all the files in /sourceable from .bash_profile
  for i in $(ls -pA ./sourceable | grep -v /); do
    SOURCE_PATH=$(realpath "./sourceable/$i")
    SOURCE_LINE="source $SOURCE_PATH"

    if [[ ! $(grep -q "$SOURCE_LINE" ~/.bash_profile) ]]; then
      echo "$SOURCE_LINE" >> ~/.bash_profile
    fi
  done
}





function createBashProfile() {
  # Create a .bash_profile
  touch ~/.bash_profile
  SEPARATOR=""

  i=0
  while [[ $i -lt 80 ]]; do
    SEPARATOR=$SEPARATOR"#"
    let i=i+1
  done

  echo "$SEPARATOR" >> ~/.bash_profile
  echo "# Dotfiles!" >> ~/.bash_profile
  echo "$SEPARATOR" >> ~/.bash_profile
}





function createFolders() {
  # Create required directories
  for i in '.environments'; do
    mkdir -p "$HOME/$i"
  done
}





function createSymlinks() {
  # Create symlinks from ~ to each file in /symlinkable
  for i in $(ls -A ./symlinkable); do
    SYMLINK_PATH=$(realpath "./symlinkable/$i")

    if [[ ! -e ~/$i ]]; then
      ln -s $SYMLINK_PATH ~
    fi
  done
}





function realpath() {
  echo $(cd "$(dirname "$1")" && pwd)/$(basename "$1");
}





function runSetupScripts() {
  RECORD_PATH=~/.dotfiles

  # Create the dotfile record if we haven't already
  touch $RECORD_PATH

  # Loop through all the files in /scripts
  for i in $(ls -pA ./scripts | grep -v /); do
    SOURCE_PATH=$(realpath "./scripts/$i")
    LAST_MODIFIED=$(date -r $SOURCE_PATH)
    PREVIOUS_RECORD=$(grep -F "$i" $RECORD_PATH)

    PREVIOUS_LAST_MODIFIED=${PREVIOUS_RECORD#$i }

    if [[ $PREVIOUS_LAST_MODIFIED != $LAST_MODIFIED ]]; then
      if [[ $PREVIOUS_RECORD != "" ]]; then
        sed -i "s/$PREVIOUS_RECORD/$i $LAST_MODIFIED/" $RECORD_PATH
      else
        echo "$i $LAST_MODIFIED" >> $RECORD_PATH
      fi

      # source $SOURCE_PATH
    fi
  done
}





function showHelp() {
  echo "
$(basename "$0") -- Bootstrap to set up all of the dotfiles

where:
  -h, --help          show this help text
  -f, --force         don't show warning about overwriting files in the home directory
  --no-scripts        don't run scripts
  --no-sourceables    don't add sourceables to .bash_profile
  --no-symlinkables   don't symlink anything in the symlink folder"
  
  exit 0;
}




################################################################################
# Do all the things
################################################################################

if [[ $SHOW_HELP = true ]]; then
  echo 'Showing help';
  showHelp;
fi

cd "$(dirname "${BASH_SOURCE}")";

echo -n "Updating script... "
git pull origin master &> /dev/null;
echo "Done."

if [[ $FORCE = false ]]; then
  read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
  echo "";

  if [[ $REPLY =~ ^(?![Yy])$ ]]; then
    exit 0
  fi;
fi;

createFolders;

if [[ $SYMLINKABLES = true ]]; then
  createSymlinks;
fi

if [[ ! -e ~/.bash_profile ]]; then
  createBashProfile;
fi

if [[ $SOURCEABLES = true ]]; then
  addSourceablesToBashrc;
fi

if [[ $SCRIPTS = true ]]; then
  runSetupScripts;
fi

source ~/.bash_profile;




################################################################################
# Unset all of our functions so that we don't accidentally break anything else
################################################################################

unset addSourceablesToBashrc;
unset createBashProfile;
unset createFolders;
unset createSymlinks;
unset parseArguments;
unset realpath;
unset runSetupScripts;
unset showHelp;





exit 0;

