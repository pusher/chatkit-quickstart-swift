#!/bin/sh
# This script clones the Chatkit quick start swift project and sets it up
#
# Prerequisites
# git, CocoaPods and Xcode

# Color function taken from
# https://github.com/ohmyzsh/ohmyzsh/blob/master/tools/install.sh that only
# uses colors if connected to a terminal
setup_color() {
  if [ -t 1 ]; then
    RED=$(printf '\033[31m')
    GREEN=$(printf '\033[32m')
    YELLOW=$(printf '\033[33m')
    BLUE=$(printf '\033[34m')
    PURPLE=$(printf '\033[35m')
    BOLD=$(printf '\033[1m')
    RESET=$(printf '\033[m')
  else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    RESET=""
  fi
}
setup_color

# Set locator from args and extract the cluster and instance ID
locator=$0
array=(${locator//:/ })
cluster=(${array[1]})
instanceId=(${array[2]})

# Jazzy banner at the top for fun
printf "$PURPLE"
cat <<-'EOF'
  ____            _
 |  _ \ _   _ ___| |__   ___ _ __
 | |_) | | | / __| '_ \ / _ \ '__|
 |  __/| |_| \__ \ | | |  __/ |
 |_|    \__,_|___/_| |_|\___|_|

EOF
printf "$RESET"

# Check if instance locator was supplied as argument
if [ $0 == v* ]; then
  echo "${RED}${BOLD}Error:${RESET} ${RED}Chatkit instance locator must be supplied${RESET}"
  exit 2
fi

# Check if repo exists and abort if so
if [[ -d chatkit-quickstart-swift ]]
then
  echo "${RED}${BOLD}Error:${RESET} ${RED}The directory ${BOLD}chatkit-quickstart-swift${RESET} ${RED}already exists${RESET}"
  exit 2
fi

# Clone the repo
echo "🔍  ${GREEN}${BOLD}Cloning the quick start${RESET}"
git clone --branch master https://github.com/pusher/chatkit-quickstart-swift.git

# Navigate into app
cd ./chatkit-quickstart-swift

# Install dependencies with Cocapods, if it exists
echo "📦  ${GREEN}${BOLD}Installing dependencies${RESET}"
if hash pod 2>/dev/null; then
  pod install
else
  echo "${RED}${BOLD}Error:${RESET} ${RED}CocoaPods needs to be installed"
  echo "       Visit https://cocoapods.org/${RESET}"
  exit 2
fi

echo "🔑  ${GREEN}${BOLD}Adding credentials to project${RESET}"
# Inject locator
sed -e "s/YOUR_INSTANCE_LOCATOR/$locator/g" -i ./Chatkit\ Quickstart/Chatkit.plist
# Inject cluster
sed -e "s/YOUR_CLUSTER/$cluster/g" -i ./Chatkit\ Quickstart/Chatkit.plist
# Inject instance ID
sed -e "s/YOUR_INSTANCE_ID/$instanceId/g" -i ./Chatkit\ Quickstart/Chatkit.plist

# Open the project with Xcode
echo "🚀  ${GREEN}${BOLD}Chatkit quick start app ready to launch${RESET}"
open ./Chatkit\ Quickstart.xcworkspace
