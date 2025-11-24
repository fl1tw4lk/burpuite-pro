#!/bin/bash
set -e -o pipefail

# --- Configuration & Constants ---
readonly BURP_DOWNLOAD_URL="https://portswigger-cdn.net/burp/releases/download?product=pro&version=&type=Linux"
readonly INSTALLER_FILENAME="BurpSuite_Pro.sh"
readonly PATCH_FILES=("BurpSuitePro.jar" "BurpSuitePro.vmoptions")
# Direktori instalasi default Burp Suite Pro
readonly TARGET_INSTALL_DIR="/opt/BurpSuitePro"

# --- UI Colors ---
readonly COLOR_GREEN=$(tput setaf 2)
readonly COLOR_YELLOW=$(tput setaf 3)
readonly COLOR_LOGO=$(tput setaf 65)
readonly COLOR_RED=$(tput setaf 1)
readonly COLOR_RESET=$(tput sgr0)

# --- Functions ---

# Prints the script banner
print_banner() {
    echo "${COLOR_LOGO}
███████╗██╗     ██╗████████╗██╗    ██╗██╗  ██╗██╗     ██╗  ██╗
██╔════╝██║    ███║╚══██╔══╝██║    ██║██║  ██║██║     ██║ ██╔╝
█████╗  ██║    ╚██║   ██║   ██║ █╗ ██║███████║██║     █████╔╝ 
██╔══╝  ██║     ██║   ██║   ██║███╗██║╚════██║██║     ██╔═██╗ 
██║     ███████╗██║   ██║   ╚███╔███╔╝     ██║███████╗██║  ██╗
╚═╝     ╚══════╝╚═╝   ╚═╝    ╚══╝╚══╝      ╚═╝╚══════╝╚═╝  ╚═╝                   
 ${COLOR_RESET}
Automated Burp Suite Professional Installer
"
}

# Prints a status message with a color
print_status() {
    local message="$1"
    local color="${2:-$COLOR_GREEN}" # Default to green
    echo -e "${color}[*]${COLOR_RESET} ${message}"
}

# Prints an error message and exits
print_error_and_exit() {
    local message="$1"
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} ${message}" >&2
    exit 1
}

# Checks if the script is run as root
check_root_privileges() {
    if [[ $EUID -ne 0 ]]; then
        print_error_and_exit "This script must be run as root. Try using 'sudo'."
    fi
}

# Checks if the required patch files exist in the current directory
check_patch_files() {
    print_status "Checking for required patch files..."
    for file in "${PATCH_FILES[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error_and_exit "Patch file '${file}' not found in the current directory. Please download it and place it here."
        fi
    done
    print_status "All patch files found.", "$COLOR_YELLOW"
}

# Downloads the Burp Suite Pro installer using a static URL
download_burp_installer() {
    # Peringatan ditampilkan kepada pengguna
    print_status "Attempting to download Burp Suite Pro installer...", "$COLOR_YELLOW"
   
    if wget --quiet --show-progress --output-document="$INSTALLER_FILENAME" "$BURP_DOWNLOAD_URL"; then
        print_status "Download completed successfully."
    else
        print_error_and_exit "Failed to download Burp Suite Pro. The link might be invalid or the server may have rejected the request. Please check the URL: ${BURP_DOWNLOAD_URL}"
    fi
}

# Executes the downloaded installer
install_burp() {
    if [[ ! -f "$INSTALLER_FILENAME" ]]; then
        print_error_and_exit "Installer file '${INSTALLER_FILENAME}' not found. Did the download step fail?"
    fi

    print_status "Making installer executable..."
    chmod +x "$INSTALLER_FILENAME"

    print_status "Running the installer. Please follow the GUI instructions."
    # The installer runs in the foreground. The script will wait for it to complete.
    ./"$INSTALLER_FILENAME"
}

# Copies the patch files to the installation directory
patch_burp() {
    if [[ ! -d "$TARGET_INSTALL_DIR" ]]; then
        print_error_and_exit "Installation directory not found at '${TARGET_INSTALL_DIR}'. Did the installer complete successfully?"
    fi

    print_status "Patching Burp Suite by copying loader files..."
    cp "${PATCH_FILES[@]}" "$TARGET_INSTALL_DIR/"
    print_status "Patching complete."
}

# Cleans up the downloaded installer file
cleanup() {
    print_status "Cleaning up..."
    rm -f "$INSTALLER_FILENAME"
}

# --- Main Execution Logic ---
main() {
    print_banner
    check_root_privileges
    check_patch_files
    
    download_burp_installer
    install_burp
    patch_burp
    cleanup

    echo
    print_status "Burp Suite Professional installation and patching completed successfully!", "$COLOR_GREEN"
    print_status "You can now launch Burp Suite Pro from your applications menu or by running '${TARGET_INSTALL_DIR}/BurpSuitePro'."
}

# Run the main function
main "$@"
