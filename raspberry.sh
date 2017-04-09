#!/usr/bin/env bash

# This is an installer script for Sample App.

echo -e "\e[0m"
echo '       $$\        $$$$$$$$\   $$$$$$$$\'
echo '      $$$$\      $$$ ____$$\ $$$ ____$$\'
echo '     $$$$$$\     $$ /    $$| $$ /    $$|'
echo '    $$$--\$$\    $$ |    $$/ $$ |    $$/'
echo '   $$$    \$$\   $$ $$$$$$/  $$ $$$$$$/'
echo '  $$$$$$$$$\$$\  $$ |        $$ |'
echo ' $$$        \$$\ $$ |        $$ |'
echo '/__/         \__\|__|        |__|'
echo -e "\e[0m"

# Define the tested version of Node.js.
NODE_TESTED="v5.1.0"

# Determine which Pi is running.
ARM=$(uname -m)

BASE_NAME="autoStart-electronApp-on-raspberryPi"
CUSTOM_THEME="SampleApp"
CMDLINE="/boot/cmdline.txt"

# Check the Raspberry Pi version.
if [ "$ARM" != "armv7l" ]; then
  echo -e "\e[91mSorry, your Raspberry Pi is not supported."
  echo -e "\e[91mPlease run MagicMirror on a Raspberry Pi 2 or 3."
  exit;
fi


# Define helper methods.
function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
function command_exists () { type "$1" &> /dev/null ;}

# Update before first apt-get
echo -e "\e[96mUpdating packages ...\e[90m"
sudo apt-get update || echo -e "\e[91mUpdate failed, carrying on installation ...\e[90m"

# Installing helper tools
echo -e "\e[96mInstalling helper tools ...\e[90m"
sudo apt-get install curl wget git build-essential unzip || exit

# Check if we need to install or upgrade Node.js.
echo -e "\e[96mCheck current Node installation ...\e[0m"
NODE_INSTALL=false
if command_exists node; then
  echo -e "\e[0mNode currently installed. Checking version number.";
  NODE_CURRENT=$(node -v)
  echo -e "\e[0mMinimum Node version: \e[1m$NODE_TESTED\e[0m"
  echo -e "\e[0mInstalled Node version: \e[1m$NODE_CURRENT\e[0m"
  if version_gt $NODE_TESTED $NODE_CURRENT; then
    echo -e "\e[96mNode should be upgraded.\e[0m"
    NODE_INSTALL=true

    # Check if a node process is currenlty running.
    # If so abort installation.
    if pgrep "node" > /dev/null; then
      echo -e "\e[91mA Node process is currently running. Can't upgrade."
      echo "Please quit all Node processes and restart the installer."
      exit;
    fi

  else
    echo -e "\e[92mNo Node.js upgrade nessecery.\e[0m"
  fi

else
  echo -e "\e[93mNode.js is not installed.\e[0m";
  NODE_INSTALL=true
fi

# Install or upgrade node if necessary.
if $NODE_INSTALL; then

  echo -e "\e[96mInstalling Node.js ...\e[90m"

  NODE_STABLE_BRANCH="6.x"
  curl -sL https://deb.nodesource.com/setup_$NODE_STABLE_BRANCH | sudo -E bash -
  sudo apt-get install -y nodejs
  echo -e "\e[92mNode.js installation Done!\e[0m"
fi


# Install MagicMirror
cd ~
if [ -d "$HOME/$BASE_NAME" ] ; then
  echo -e "\e[93mIt seems like $BASE_NAME is already installed."
  echo -e "To prevent overwriting, the installer will be aborted."
  echo -e "Please rename the \e[1m~/$BASE_NAME\e[0m\e[93m folder and try again.\e[0m"
  echo ""
  echo -e "If you want to upgrade your installation run \e[1m\e[97mgit pull\e[0m from the ~/$BASE_NAME directory."
  echo ""
  exit;
fi

echo -e "\e[96mCloning $BASE_NAME ...\e[90m"
if git clone https://github.com/ganezasan/autoStart-electronApp-on-raspberryPi.git; then
  echo -e "\e[92mCloning $BASE_NAME Done!\e[0m"
else
  echo -e "\e[91mUnable to clone $BASE_NAME."
  exit;
fi

# Check if plymouth is installed (default with PIXEL desktop environment), then install custom splashscreen.
echo -e "\e[96mCheck plymouth installation ...\e[0m"
if command_exists plymouth; then
  THEME_DIR="/usr/share/plymouth/themes"
  echo -e "\e[90mSplashscreen: Checking themes directory.\e[0m"
  if [ -d $THEME_DIR ]; then
    echo -e "\e[90mSplashscreen: Create theme directory if not exists.\e[0m"
    if [ ! -d $THEME_DIR/$CUSTOM_THEME ]; then
      sudo mkdir $THEME_DIR/$CUSTOM_THEME
    fi

    if sudo cp ~/$BASE_NAME/splashscreen/splash.png $THEME_DIR/$CUSTOM_THEME/splash.png && sudo cp ~/$BASE_NAME/splashscreen/$CUSTOM_THEME.plymouth $THEME_DIR/$CUSTOM_THEME/$CUSTOM_THEME.plymouth && sudo cp ~/$BASE_NAME/splashscreen/$CUSTOM_THEME.script $THEME_DIR/$CUSTOM_THEME/$CUSTOM_THEME.script; then
      echo -e "\e[90mSplashscreen: Theme copied successfully.\e[0m"
      if sudo plymouth-set-default-theme -R $CUSTOM_THEME; then
        echo -e "\e[92mSplashscreen: Changed theme to sample $CUSTOM_THEME successfully.\e[0m"
      else
        echo -e "\e[91mSplashscreen: Couldn't change theme to $CUSTOM_THEME!\e[0m"
      fi
    else
      echo -e "\e[91mSplashscreen: Copying theme failed!\e[0m"
    fi
  else
    echo -e "\e[91mSplashscreen: Themes folder doesn't exist!\e[0m"
  fi
else
  echo -e "\e[93mplymouth is not installed.\e[0m";
fi

# Enable Splash Screen
if ! grep -q "splash" $CMDLINE ; then
  sudo sed -i $CMDLINE -e "s/$/ quiet splash plymouth.ignore-serial-consoles/"
fi
