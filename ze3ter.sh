echo "
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
 ########  ########  :#####:      ##     ########  ##    ###"



echo "1) privilege escalation" 
echo "2) Detecting vulnerabilities"
 
read -p "what is your choice (1/2) : " $choice 
if [ $choice==1 ]
then 
bash Detecting-vulnerabilities.sh
fi
	exit
if [ $choice==2 ]
then 
bash privilege-escalation.sh
fi
