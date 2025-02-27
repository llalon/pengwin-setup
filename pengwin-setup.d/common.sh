#!/bin/bash

declare -a CMD_MENU_OPTIONS
export CMD_MENU_OPTIONS

export LANG=en_US.utf8

function process_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --debug | -d | --verbose | -v)
                echo "Running in debug/verbose mode"
                set -x
                shift
            ;;
            -y | --yes | --assume-yes)
                echo "Skipping confirmations"
                export SKIP_CONFIMATIONS=1
                shift
            ;;
            --noupdate)
                echo "Skipping updates"
                export SKIP_UPDATES=1
                shift
            ;;
            --norebuildicons)
                echo "Skipping rebuild start menu"
                export SKIP_STARTMENU=1
                shift
            ;;
            -q | --quiet | --noninteractive)
                echo "Skipping confirmations"
                export NON_INTERACTIVE=1
                shift
            ;;
            update | upgrade)
                echo "Just update packages"
                export JUST_UPDATE=1
                export SKIP_CONFIMATIONS=1
                shift
            ;;
            autoinstall | install)
                echo "Automatically install without prompts or updates"
                export SKIP_UPDATES=1
                export NON_INTERACTIVE=1
                export SKIP_CONFIMATIONS=1
                export SKIP_STARTMENU=1
                shift
            ;;
            uninstall | remove)
                echo "Automatically uninstall without prompts or updates"
                export SKIP_UPDATES=1
                export NON_INTERACTIVE=1
                export SKIP_CONFIMATIONS=1
                export SKIP_STARTMENU=1
                CMD_MENU_OPTIONS+=("UNINSTALL")
                shift
            ;;
            startmenu)
                echo "Regenerates the start menu"
                export SKIP_UPDATES=1
                export NON_INTERACTIVE=1
                export SKIP_CONFIMATIONS=1
                CMD_MENU_OPTIONS+=("GUI")
                CMD_MENU_OPTIONS+=("STARTMENU")
                shift
            ;;
            *)
                CMD_MENU_OPTIONS+=("$1")
                shift
            ;;
        esac
    done
    
}

function createtmp() {
    echo "Saving current directory as \$CURDIR"
    CURDIR=$(pwd)
    TMPDIR=$(mktemp -d)
    echo "Going to \$TMPDIR: $TMPDIR"
    # shellcheck disable=SC2164
    cd "$TMPDIR"
}

function cleantmp() {
    echo "Returning to $CURDIR"
    # shellcheck disable=SC2164
    cd "$CURDIR"
    echo "Cleaning up $TMPDIR"
    sudo rm -r $TMPDIR # need to add sudo here because git clones leave behind write-protected files
}

function updateupgrade() {
    echo "Applying available package upgrades from repositories."
    sudo apt-get upgrade -y
    echo "Removing unnecessary packages."
    sudo apt-get autoremove -y
}

function command_check() {
    # Usage: command_check <EXPECTED PATH> <ARGS (if any)>
    # shellcheck disable=SC2155
    # shellcheck disable=SC2001
    local exec_name=$(echo "$1" | sed -e "s|^.*\/||g")
    if ("${exec_name}" "$2") >/dev/null 2>&1; then
        echo "Executable ${exec_name} in PATH"
        return 0
        elif ("$1" "$2") >/dev/null 2>&1; then
        echo "Executable '${exec_name}' at: $1"
        return 2
    else
        echo "Executable '${exec_name}' not found"
        return 1
    fi
}

function confirm() {
    
    if [[ ! ${SKIP_CONFIMATIONS} ]]; then
        
        whiptail "$@"
        
        return $?
    else
        return 0
    fi
}

function message() {
    
    if [[ ! ${NON_INTERACTIVE} ]]; then
        
        whiptail "$@"
        
        return $?
    else
        return 0
    fi
}

#######################################
# Display a menu using whiptail. Echo the option key or CANCELLED if the user has cancelled
# Globals:
#   CANCELLED
# Arguments:
#   None
# Returns:
#   None
#######################################
function menu() {
    
    local menu_choice #Splitted to preserve exit code
    
    if [[ "${#CMD_MENU_OPTIONS[*]}" == 0 ]]; then
        menu_choice=$(whiptail "$@" 3>&1 1>&2 2>&3)
    else
        menu_choice="${CMD_MENU_OPTIONS[*]}"
    fi
    
    local exit_status=$?
    
    if [[ ${exit_status} != 0 ]]; then
        echo "${CANCELLED}"
        return
    fi
    
    if [[ -z "${menu_choice}" ]]; then
        
        if (whiptail --title "None Selected" --yesno "No item selected. Would you like to return to the menu?" 8 60 3>&1 1>&2 2>&3); then
            menu "$@"
            
            return
        else
            local exit_status=$?
            echo ${CANCELLED}
            return
        fi
    fi
    
    echo "${menu_choice}"
}

function setup_env() {
    
    process_arguments "$@"
    
    # shellcheck disable=SC1003
    
    readonly CANCELLED="CANCELLED"
    export CANCELLED
    
    SetupDir="./pengwin-setup.d"
    export SetupDir
    
    readonly GOVERSION="1.15.8"
    export GOVERSION
    
}

function install_packages() {
    
    sudo apt-get install -y -q "$@"
}

function update_packages() {
    
    if [[ ${NON_INTERACTIVE} ]]; then
        sudo apt-get update -y -q "$@"
    else
        sudo debconf-apt-progress -- apt-get update -y "$@"
    fi
}

function upgrade_packages() {
    
    sudo apt-get upgrade -y -q "$@"
}

function add_fish_support() {
    echo "Also for fish."
    sudo mkdir -p "${__fish_sysconf_dir:=/etc/fish/conf.d}"
    
  sudo tee "${__fish_sysconf_dir}/$1.fish" <<EOF
#!/bin/fish

bass source /etc/profile.d/$1.sh

EOF
}

setup_env "$@"
