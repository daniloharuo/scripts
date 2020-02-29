#!/bin/bash

#################################################################################
#
# functions 
#
#################################################################################
function menu_build {
    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "   $1 "; }
    print_selected()   { printf "  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    lastrow=$(get_cursor_row)
    startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    selected=0
    while true; do
        # print options by overwriting the last lines
        idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case $(key_input) in
            enter)
                break
                ;;

            up)
                ((selected--))
                [ $selected -lt 0 ] && selected=$(($# - 1))
                ;;

            down)
                ((selected++))
                [ $selected -ge $# ] && selected=0
                ;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}

function vm_select() {
    echo "Please, select an virtual machine:"
    menu_build "${vmnamelist[@]}"
    choice=$?
    vm_start "${vmnamelist[$choice]}"
}

function vm_exists() {
    vmnameexists=$($vboxmgmt list vms | grep -c $1)
    if [ $vmnameexists -eq 0 ]; then
        echo "No VM with name '$1' was found..."
        vm_select
    else
        vm_start $1
    fi

}

function vm_start() {
    vmisrunning=$($vboxmgmt list runningvms | grep -c $1)
    if [ $vmisrunning -ne 0 ]; then
        echo "VM is running already, exiting..."
        exit
    fi

    $vboxmgmt startvm "$1" --type headless
}

#################################################################################
#
# main
#
#################################################################################

# variables
vboxmgmt=$(which VBoxManage)
vmnamelist=($($vboxmgmt list vms | cut -d '"' -f2 | xargs))

# ensure vm is selected
[ -z "$1" ] && vm_select
[ -n "$1" ] && vm_exists $1




#if [ -n "$1" ]; then
#    [ $(VBoxManage list vms | grep "$1" | wc -l) -ne 0 ] && echo "VM already exists. Leaving..." ; exit
#        VBoxManage startvm "$1" --type headless
#        VM_HOST_ONLY_IP=$(VBoxManage guestproperty get "$1" "/VirtualBox/GuestInfo/Net/1/V4/IP" | awk '{print $2}')
#        if [ -n "$VM_HOST_ONLY_IP" ]; then
#            HOSTS_ADDED=$(grep "$VM_HOST_ONLY_IP" /etc/hosts | wc -l)
#            if [ $HOSTS_ADDED -eq 0 ]; then
#                echo "$VM_HOST_ONLY_IP $1" | sudo tee -a /etc/hosts
#            else
#                echo "You alreary have this VM in /etc/hosts."
#                echo "Replacing..."
#                echo "$VM_HOST_ONLY_IP $1" | sudo tee -a /etc/hosts
#            fi
#        fi
#    else
#
#else
#  FIRST_VM=$(VBoxManage list vms | head -1 | cut -d '"' -f2)
#  #VBoxManage startvm "$FIRST_VM" --type headless
#fi
#VBoxManage --help
#VBoxManage poweroff "centos8" poweroff
#VBoxManage controlvm "centos8" poweroff
#VBoxManage clonevm "centos8" "vm3"
#VBoxManage list -l
#VBoxManage list vms
#ls
#VBoxManage snapshot
#VBoxManage snapshot  delete "vm3"
#VBoxManage clonevm "centos8" --name "vm3"
#VBoxManage clonevm
#VBoxManage clonevm "centos8" --name "vm3" --register\n
#VBoxManage --help | less
#rm -rf '/Users/haruo/VirtualBox VMs/vm3\nVBoxManage clonevm "centos8" --name "vm3" --register\n
#rm -rf '/Users/haruo/VirtualBox VMs/vm3'
#VBoxManage clonevm "centos8" --name "vm3" --register
#VBoxManage list
#VBoxManage list -l vms
#VBoxManage guestproperty enumerate "vm1"
#history| tail -n 30
#VBoxManage startvm "vm1" --type headless
#VBoxManage guestproperty enumerate vm1
#VBoxManage unregistervm --delete "vm3"
#VBoxManage unregistervm --delete "vm2"
#VBoxManage controlvm "vm1" poweroff
