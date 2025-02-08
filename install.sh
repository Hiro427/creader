#!/bin/env bash

CREADER_DIR="$HOME/.config/creader/"
ADD_TO_USER_PATH="/usr/local/bin"

echo "Cloning repo"
git clone "https://github.com/Hiro427/creader.git"

cd "creader" || exit

echo " "
echo "Starting Installation..."

echo "Checking Dependencies..."
dependencies=(chafa gum awk cut sed file find grep tput tr jq sort)
not_installed=()
for d in "${dependencies[@]}"; do 
    if command -v "$d" >/dev/null 2>&1; then 
        continue
    else 
        not_installed+=("$d")
    fi 
done 

if [[ ${#not_installed[@]} -eq 0 ]]; then 
    echo "All Dependencies Install"
else 
    printf "\n%s\n%s\n" "Following programs not installed" "${not_installed[@]}"
    exit 0
fi

echo "Making Directories"

if [[ -e "$CREADER_DIR" ]]; then 
    echo "The PATH: $CREADER_DIR already exists"
    echo "Skipping installation"
else
    mkdir -p "$CREADER_DIR"
    mkdir "${CREADER_DIR}active/"
    mdkir "${CREADER_DIR}sessions/"
    mkdir "${CREADER_DIR}tmp/"
    cp "header.txt" "${CREADER_DIR}"

fi 


echo "Add creader to path"
sudo cp "./creader.sh" "$ADD_TO_USER_PATH/creader"

echo "Installation Complete"
