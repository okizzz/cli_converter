#!/usr/bin/env bash

#Исправить ошибку копирования одинакового кода из машины.
#Исправить ошибку отключения VPN (не найден PID).

set -ux
set -o pipefail

function startvpn(){

AIR_SERVERS=$(./air_servers.py | cut -d' ' -f1)
RANDOM_SERVER=$(echo ${AIR_SERVERS} | sed -e s/\ /\\n/g | shuf -n 1)
sudo gnome-terminal --geometry 80x24 --hide-menubar --zoom=0.8 --command "airvpn -cli -login='' -password='' -connect -server=${RANDOM_SERVER}"

}

function stopvpn(){

PID=$(ps aux | grep "AirVPN.exe" | grep "root" | awk '{print $2}')
sudo kill -SIGTERM $PID

}

function startvm(){

gnome-terminal --geometry 80x24 --hide-menubar --command "/opt/genymobile/genymotion/player --vm-name ${VMID}"

}

function stopvm(){

gnome-terminal --geometry 80x24 --hide-menubar --command "/opt/genymobile/genymotion/player --vm-name ${VMID} --poweroff"

}

function create_config(){

NUMBER=$(cat number.tmp)
PROFILE=$(echo ${NUMBER} | sed 's/+7/p_7/')
echo -e "${PROFILE} = {\nconfig_directory = \x22.telegram-cli/${PROFILE}\x22; #${VMID}\n};\n" >> ~/.telegram-cli/config

}

function check_session(){

adb shell monkey -p org.telegram.messenger -c android.intent.category.LAUNCHER 1
sleep 2
adb shell input tap 51.9 111.9
sleep 2
DUMP=$(dump -g  | grep "New Group")
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

function getting_number(){

#adb shell monkey -p org.telegram.messenger -c android.intent.category.LAUNCHER 1
#local EXIT1=$?
#sleep 2
#adb shell input tap 51.9 111.9
#sleep 2
DUMP=$(dump -g)
local EXIT2=$?
local EXIT1=0
while [[ ${EXIT1} -ne 0 ]] || [[ ${EXIT2} -ne 0 ]] ;
do 
    stopvm
        sleep 15
    startvm
        sleep 20
    adb shell monkey -p org.telegram.messenger -c android.intent.category.LAUNCHER 1
        local EXIT1=$?
        sleep 2
    adb shell input tap 51.9 111.9
        sleep 2
    DUMP=$(dump -g)
        local EXIT2=$?
done
if [[ ${EXIT1} -eq 0 ]] && [[ ${EXIT2} -eq 0 ]] ; 
then
    sleep 3
    NUMBER=$(echo ${DUMP} | grep "+7" | sed s/[^0-9+]//g)
    echo $NUMBER > number.tmp    
fi

}

function getting_code(){

GLOBAL_COUNT=$(cat count.tmp)
    local EXIT=$?
    if [ "${EXIT}" -eq 0 ] ; then
        echo ' '
    else  
        echo 0 > count.tmp
        GLOBAL_COUNT=$(cat count.tmp)
        echo ' '
    fi
adb shell dumpsys notification | grep --silent 'Your login code: '
NOTIFICATIONS=$?
COUNT=0
while [ ${NOTIFICATIONS} -ne 0 ] && [ ${COUNT} -lt 5 ]
do
    sleep 15
    adb shell dumpsys notification | grep --silent 'Your login code: '
    NOTIFICATIONS=$?
    COUNT=$[COUNT+1]
    RESULT_COUNT=$[GLOBAL_COUNT+COUNT]
    echo ${RESULT_COUNT} > count.tmp
done
if [ ${NOTIFICATIONS} -eq 0 ]
then
    CODE_LINE=$(adb shell dumpsys notification | grep -m1 'Your login code: ' | xargs)
    CODE_POSITION=$(echo $CODE_LINE | grep -aob "Your login code: " | cut -d':' -f1)
    CODE=$(echo ${CODE_LINE:(($CODE_POSITION + 17)):5})
    echo ${CODE} > code.tmp
    echo ${CODE}

fi

}

function execution_check(){

CODE=$(cat code.tmp)
cat log.tmp | grep --silent "code ('CALL' for phone code): ${CODE}"
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

function add_account(){


set -o pipefail
clear

NUMBER=$(cat number.tmp)

PROFILE=$(echo ${NUMBER} | sed 's/+7/p_7/')

(sleep 30; echo "${NUMBER}"; sleep 15; CODE=$(getting_code); sleep 15 ; echo ${CODE}; sleep 10; echo "quit"; sleep 5) | timeout 200 /opt/telegram-cli/telegram-cli --profile ${PROFILE} --disable-readline --disable-output --disable-colors --wait-dialog-list > log.tmp
    local EXIT1=$?
execution_check
    local EXIT2=$?
    local CHECK_COUNT=$(cat count.tmp)
if [ "${EXIT1}" -eq 0 ] && [ "${EXIT2}" -eq 0 ] ; then
    rm -rf count.tmp
    rm -rf code.tmp
    rm -rf log.tmp
    rm -rf number.tmp
    return 0
elif [ "${CHECK_COUNT}" -ge 10 ] ; then
    ls "${HOME}/.telegram-cli/${PROFILE}"
        EXIT=$?
        if "${EXIT}" -eq 0 ; then
            rm -rf "${HOME}/.telegram-cli/${PROFILE}"
        else 
            echo "failed deleted ${PROFILE}"
        fi
    rm -rf code.tmp
    rm -rf log.tmp
    rm -rf count.tmp
    rm -rf number.tmp
    cat ~/.telegram-cli/config | head --lines=-4 > ~/.telegram-cli/config.temp
    sleep 1
    rm -rf ~/.telegram-cli/config
    mv ~/.telegram-cli/config.temp ~/.telegram-cli/config
    return 10
else
    ls "${HOME}/.telegram-cli/${PROFILE}"
        EXIT=$?
        if "${EXIT}" -eq 0 ; then
            rm -rf "${HOME}/.telegram-cli/${PROFILE}"
        else 
            echo "failed deleted ${PROFILE}"
        fi
    rm -rf code.tmp
    rm -rf log.tmp
    add_account
    return 1
fi

}

date +%H:%M:%S\ %d.%m > timestart.txt

for VMID in $(cat vmlist.txt)

do

startvpn
    sleep 45
startvm
    sleep 20
check_session
    if [ $? -eq 0 ]; then
        echo "session present"
    else
    stopvm
        sleep 5
    stopvpn
        sleep 15
    continue
    fi
    sleep 10
getting_number
    sleep 5
create_config
add_account
if [ "$?" -eq 1 ] ; then
    echo ' '
elif [ "$?" -eq 10 ] ; then
    stopvm
        sleep 5
    stopvpn
        sleep 15
    continue
else
    echo "Account ready."
fi
stopvm
    sleep 5
stopvpn
    sleep 25
done

date +%H:%M:%S\ %d.%m > timestop.txt
