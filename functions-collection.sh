#!/bin/bash
# FUNCTIONS COLLECTION

# ENVIRONMENT VARIABLES
ACTIVE_INTERFACE=""
LOGS=""

# SYSTEM INFO
systeminfo() {
    echo -e "\e[33;01mSYSTEM INFORMATION:\e[0m"
    echo -ne "\e[33mOS: \e[0m$(uname -o)\n"
    echo -ne "\e[33mkernel: \e[0m$(uname -r)\n"
    echo -ne "\e[33mdistro: \e[0m"
    echo "$(cat /etc/*-release | grep -E '^NAME=' | cut -d'=' -f2 | tr -d '"') $(cat /etc/*-release | grep 'VERSION=' | cut -d'=' -f2 | tr -d '"')"
    echo -ne "\e[33muptime:\e[0m"
    uptime
    echo -ne "\n\e[33;01mUSERS (\e[0m\e[33monline\e[0m\e[33;01m):\e[0m\n"
    who -u
    echo
    echo -ne "\e[33mme:\e[0m $(whoami) @ "
    tty
    echo -e "\n\e[33;01mFILE SYSTEMS:\e[0m"
    lsblk -fmI 8
    # udevadm info --query=all --name=/dev/sde | grep ID_SERIAL
    echo
    echo "\e[33;01mCPU TEMPERATURE:\e[0m"
    sensors | grep -E '\+[0-9.]+°C'
    echo "\n\e[33;01mGPU TEMPERATURE:\e[0m"
    nvidia-settings -q gpucoretemp | grep Attribute | tr -d ' ' | grep -E '\:[0-9]+\.$'
    echo
    echo -e "\e[33;01mSERVICE STATUS:\e[0m"
    echo -e "\e[01mAll relevant running:\e[0m"
    sudo service --status-all | sed "s/ //g" | grep -Ei --color "\+|ssh|ufw|suricata|clam|sql|mongo|virtualbox|apache|avahi|rpcbind|minissd|nfs-common|gdomap|exim|cups|bluetooth|vpn|nginx"
    echo -ne "\n"
    echo -e "\e[33;01mNETWORK INTERFACES:\e[0m"
    netstat -i | tail -n+2 | grep "Iface\|$wire\|$wireless\|lo"
    echo "\e[33;01mLAN:\e[0m"
    /sbin/ifconfig $ACTIVE_INTERFACE | grep -E "inet |RX pack|TX pack" | sed 's/^        //g' | grep -E ' [0-9\.]+'
    echo
    echo "\e[33;01mWAN:\e[0m \e[31;01m"$(curl -s "https://www.google.com/search?q=whatsmyip" | tac | tac | head -1 | grep -E "[0-9.]+" -o | tail -1)"\e[0m"
    echo
    echo -e "\e[33;01mROUTING TABLE:\e[0m"
    sudo route -nv
    echo -e "\n\e[33;01mACTIVE CONNECTIONS ($wire):\e[0m"
    sudo ifconfig $ACTIVE_INTERFACE promisc
    sudo netstat -anp | grep -Ei --color "listen |established " | awk '{print $4" <=> "$5" ~ "$7" ~ "$6 }' | grep -Ei '[0-9\.]+[0-9\.]\:+|listen|established'
    sudo ifconfig $ACTIVE_INTERFACE -promisc
    uname -a
}

# SYSTEM UPGRADE
upgrade() {
    echo -e "\e[1;33mUPDATE REPOS\e[0m"
    sudo apt-get update -y
    echo -e "\n\e[1;33mUPGRADE PACKAGES\e[0m"
    sudo apt-get upgrade
    echo -e "\n\e[1;33mUPGRADE DISTRO\e[0m"
    sudo apt-get dist-upgrade
    sudo apt full-upgrade
    echo -e "\n\e[1;33mAUTOCLEAN PACKAGES\e[0m"
    sudo apt-get autoclean -y
    echo -e "\n\e[1;33mAUTOREMOVE PACKAGES\e[0m"
    sudo apt-get autoremove -y
    echo -e "\n\e[1;33mREMOVE UNWANTED PACKAGES\e[0m"
    sudo apt-get remove ubuntu-advantage-tools diodon
    echo -e "\n\e[1;33mFIX BROKEN DEPENDENCIES\e[0m"
    sudo apt-get install -f
    echo -e "\n\e[1;33mUPDATE ANTIVIRUS DATABASE\e[0m"
    sudo service clamav-freshclam stop
    sudo freshclam
    sudo service clamav-freshclam start
    if [ -f ~/logs/system_upgrades.log ]; then
        echo -e "$(date '+%Y-%m-%d,%H:%M:%S') - system upgraded" >> ~/logs/system_upgrades.log
    else
        touch ~/logs/system_upgrades.log
        echo -e "$(date '+%Y-%m-%d,%H:%M:%S') - system upgraded" > ~/logs/system_upgrades.log
    fi
    notify-send -i ~/color/applications/system-software-update_32.png 'System upgrade complete.'
    echo "up grade complete" | festival --tts
}

# MOON PHASE (@moongiant.com)
moon() {
	   currentmoonphase="$(curl -s "https://www.moongiant.com/phase/today/" | tac | tac | grep "todayMoonContainer" | grep -Eo "alt=\".*\"" | grep -Eo "\".*on" | sed 's/"//g' | cut -d " " -f1,2)" 
	   currentmoonphaseillumination="$(curl -s "https://www.moongiant.com/phase/today/" | grep "Illumination: <span>" | tac | tac | tail -1 | cut -d'>' -f2)" 
	   case "$currentmoonphase" in
		      ("New Moon") echo "🌑 : New Moon ($currentmoonphaseillumination)↑" ;;
		      ("Waxing Crescent") echo "🌒 : Waxing Crescent ($currentmoonphaseillumination)↑" ;;
		      ("First Quarter") echo "🌓 : First Quarter ($currentmoonphaseillumination)↑" ;;
		      ("Waxing Gibbous") echo "🌔 : Waxing Gibbous ($currentmoonphaseillumination)↑" ;;
		      ("Full Moon") echo "🌕 : Full Moon ($currentmoonphaseillumination)↓" ;;
		      ("Waning Gibbous") echo "🌖 : Waning Gibbous ($currentmoonphaseillumination)↓" ;;
		      ("Last Quarter") echo "🌗 : Last Quarter ($currentmoonphaseillumination)↓" ;;
		      ("Waning Crescent") echo "🌘 : Waning Crescent ($currentmoonphaseillumination)↓" ;;
		      (*) echo "unexpected error" ;;
	   esac
}
