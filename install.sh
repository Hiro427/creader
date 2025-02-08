#!/bin/env bash

CREADER_DIR="$HOME/.config/creader/"
ADD_TO_USER_PATH="/usr/local/bin"

printf "%s\n" "Cloning Repo..."
git clone "https://github.com/Hiro427/creader.git"

cd "creader" || exit

printf "\n%s\n" "Starting Installation..."

printf "%s\n" "Checking Dependencies..."
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
    printf "%s\n" "All Dependencies Installed"
else 
    printf "\n%s\n%s\n" "Following Dependencies not installed" "${not_installed[@]}"
    echo "Exiting..."
    exit 0
fi

printf "%s\n" "Making Directories..."

if [[ -e "$CREADER_DIR" ]]; then 
    echo "The PATH: $CREADER_DIR already exists"
    echo "Exiting..."
    exit 0
else
    mkdir -p "$CREADER_DIR"
    mkdir "${CREADER_DIR}active/"
    mkdir "${CREADER_DIR}sessions/"
    mkdir "${CREADER_DIR}tmp/"
    cp "header.txt" "${CREADER_DIR}"

fi 


echo "Add creader to path"
echo "Command to be run: sudo cp ./creader.sh /usr/local/bin/creader"

gum confirm "Add to Path?" && sudo cp "./creader.sh" "$ADD_TO_USER_PATH/creader" || echo "Not added to PATH"

printf "%s\n%s\n" "Installation Complete" "Feel free to delete the cloned directory"

echo "NOTE: If script was not added to PATH, you won't be able to run it globally"
