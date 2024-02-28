#!/bin/bash

#######################################################################
###########################    CONFIGS    ###########################
#######################################################################
hostfile="/etc/hosts"
log_folder="$HOME/secon_logs"
supportedconnections=("ftp" "rdp"  "sftp" "ssh" "telnet" "vnc")

#1. Save IPs to your host file as below, to find it easily in while try to connect:
#       <ip>        <domain>    <connection>    <port[-comment|device type>
#       1.2.3.4     myserver    #ssh
#       1.2.3.4     myserver    #vnc            12345-Windows_10


#Tshoot configs
#2. Check output of nslookup command. Is IP in column 2 or column3 ? According to column number change thednscheck=$( nslookup $1 | awk '/'"Address"'/ {print $2}') parameter from $2 to $3  in ipaddresscheck function


#3. Install your vncviewer and RDP app and change the command for vncviewer command in the section CONNECTION [tigervnc for VNC on Mobaxterm (apt install tigervnc), xfreerdp for RDP on Mobaxterm (apt install freerdp)].


#4. Send ping to specific IP(ex:8.8.8.8). If your ping doesn't stop after 5th ICMP packet, in the test_ping function, add count for ping(ex:"ping -c 5 $ipaddress" for Fedora OS).


#5. In test_traceroute function, change the traceorute command according to your OS.


#6. In test_traceroute function, millisecond and ip address positions can be change according to your OS, please test in your system. Change the $ number in your test_treaceroute finction according to traceoutput.


#7. In the Tshoot Main, Troubleshoot is performing for 2 erros in errors array(errors=("connectiontimedout" "noroutetohost")). If you want to perform troubleshooting for more errors you can add the error output identifier without space and uppercases. As an example,if you received the following error;
 #    'ssh: connect to host 1.2.3.4 22: Connection refused'
 #you can use Connection refused as identifier and add it to errors array as errors=("connectiontimedout" "noroutetohost" "connectionrefused")
 # In addition, add the same error to case_tshoot function in Tshoot function section and define the test cases that you want to run.
 
 
#8. In this sample code, we run different test functions for different errors. If you want to run all tshoot test functions to collect data independent from error type. You can change the "case_tshoot $error" with "test_ping" and then go to "test_ping" function and at the end of funcion you can call test_route function and go to the end of test_route function add test_trace...

 
#9. You can add your tshoot test functions and improve the code.
#######################################################################
###########################    FUNCTIONS    ###########################
#######################################################################
usage(){
    echo  "Usage: ./secon.sh [-t] connection_type [-i] ipaddress|name [[-p] port] [-u] username"
}



help(){
    usage
    echo "Mutliple connection type supported in this script with its own troubleshooting."
    echo ""
    echo -e "Argument\tDescription"
    echo -e "   -t\t\tType of connection (${supportedconnections[@]})"
    echo -e "   -i\t\tIp address or Name"
    echo -e "   -u\t\tUsername"
    echo -e "   -p\t\tPort Number"
}



connectiontypecheck(){
    if [[ $( echo "${supportedconnections[@]}" | grep -wc "$1") > 0 ]]
    then
        stype=$1
    else
        echo -e "Please specify connection type first.\nExited"
        exit
    fi
}



ipv4check(){
    if [[ "$1"  =~ \s{0,}([1,2]{0,1}[0-9]{0,1}[0-9].){3}[1,2]{0,1}[0-9]{0,1}[0-9]\s{0,} ]]
    then
        IFS='.'
        local ipv4=($1)
        if [[ ${ipv4[0]} -le 255 && ${ipv4[1]} -le 255 && ${ipv4[2]} -le 255 && ${ipv4[3]} -le 255 ]]
        then
            ipv4flag=40
        else
            ipv4flag=41
        fi
    else
        ipv4flag=41
    fi
}



ipv6check(){
    if [[ "$1"  =~ ^\s{0,}^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$\s{0,}$ ]]
    then
        ipv6flag=60
    else
        ipv6flag=61
    fi
}



ipaddresscheck(){
    ipv4check $1
    ipv6check $1
    if [ "$ipv4flag" == 40 ] || [ "$ipv6flag" == 60 ]
    then
        echo IP Address check PASSED
        ipaddress=$1
    elif [[ "$1" =~ ^\s{0,}[1-9][0-9]{0,}\s{0,}$ ]]
    then
        selectedip=$( awk -v IGNORECASE=1  '/'"^$1 "'/ {print $2}' /tmp/secon.out )
        ipv4check $selectedip
        ipv6check $selectedip
        if [ "$ipv4flag" == 40 ] || [ "$ipv6flag" == 60 ]
        then
            echo IP Address check PASSED
            ipaddress=$selectedip
        else
            echo -e "$1 is invalid IP|Domain|Selection.\nExited"
            exit
        fi
    else
        echo $1
        dnscheck=$( nslookup $1 | awk '/'"Address"'/ {print $2}')
        if [[ $dnscheck == "" ]]
        then
            echo -e "$1 Please check IP address or selection. If you enter domain name, it wasn't reso
lved.\nExited"
            exit
        else
            echo Resolved IP Address:
            echo $dnscheck
            ipaddress=$1
        fi
    fi
}



hostiplistandselect(){
    echo ~~ $( echo $stype | tr [[:lower:]] [[:upper:]] ) CONNECTIONS ~~
    awk -v IGNORECASE=1 -v i=1 '/'"$stype"'/ {print i++,tolower($1),$2, $4}' $hostfile | tee /tmp/secon.out
    read -p "Please enter the selection number or IP address:" selection
    read -p "Please enter the port number or leave empty for default:" port
    if ! [[ $stype == "vnc" ]]
    then
        read -p "Please enter the username or leave empty for default:" username
    fi
}



portcheck(){
    if ! [[ $1 =~ ^\s{0,}[0-9]+\s{0,}$ ]]
    then
        echo -e "$1 Invalid port number.[0-65535]\nExited"
        exit
    fi
    if (( $1 >= 0 && $1 <= 65535 ))
    then
        echo Port check PASSED
        port=$1
    else
        echo -e "$1 Invalid port number.[0-65535]\nExited"
        exit
    fi
}



########################################################################
###########################    INITIALIZE    ###########################
########################################################################

if [ $# -eq 0 ]
then
    usage
    exit
fi


while getopts ":t:i:u:p:h:"  arguments
do
    case "$arguments" in
        t)
            stype=${OPTARG}
            stype=$(echo $stype | tr [[:upper:]] [[:lower:]])
            connectiontypecheck $stype;;
        i)
            ipaddress=${OPTARG}
            ipaddresscheck $ipaddress;;

        p)
           port=${OPTARG}
           portcheck $port;;
        u)
           username=${OPTARG};;
        ?)
           echo "Invalid  argument"
           help
           exit;;
    esac
done


if [ $# > 0 ]
then
    if [[ "$stype" == "" ]]
    then
        stype=$(echo $1 | tr [[:upper:]] [[:lower:]])
        connectiontypecheck $stype

        if [ $# -eq 1 ]
        then
            hostiplistandselect
            ipaddresscheck $selection
        fi
    fi
    if [[ "$ipaddress" == "" ]]
    then
        if [ $# > 1 ]
        then
            ipaddresscheck $2
        fi
    fi
    if [[ "$port" == "" ]]
    then
        if [ $# -eq 4 ] || [ "$stype" == "vnc" ] || [ "$stype" == "telnet" ]
        then
            if [[ $3  =~ ^\s{0,}([0-9]{1,5})$\s{0,}$ ]]
            then
                portcheck $3
            fi
        else
            case "$stype" in
                ftp)
                    port=21;;
                rdp)
                    port=3389;;
                sftp | ssh)
                    port=22;;
                telnet)
                    port=23;;
                vnc)
                    port=5900;;
            esac
        fi
    fi
    if [[ "$username" == "" ]]
    then
        if [ $# -gt 3 ]
        then
            username=$4
        elif [ $# -eq 3 ]
        then
            username=$3
        else
            username=$(echo $CURRENT_USER_NAME)
        fi
    fi
fi


log_date=$( echo $( date +%Y%m%d_%H%M%S ))
log_file=$( echo $log_folder/log_$stype\_$ipaddress\_$log_date.log )


if [ ! -d "$log_folder" ]
then
    mkdir $log_folder
fi



########################################################################
###########################    CONNECTION    ###########################
########################################################################
echo -e "$stype to $ipaddress:$port as $username on $(date)\n" | tee $log_file


case "$stype" in
    ftp)
        ftp $username@$ipaddress 2>&1 | tee -a $log_file
        ;;
    rdp)
        xfreerdp.exe /u:$username /v:$ipaddress:$port  2>&1 | tee -a $log_file
        ;;
    sftp)
        sftp $username@$ipaddress 2>&1 | tee -a $log_file
        ;;
    ssh)
        ssh -l $username $ipaddress -p $port 2>&1 | tee -a  $log_file
        ;;
    telnet)
        telnet-l $username $ipaddress $port  2>&1 | tee -a $log_file
        ;;
    vnc)
        vncviewer.exe $ipaddress:$port   2>&1 | tee -a $log_file
        ;;
esac



########################################################################
##########################    TROUBLESHOOT    ##########################
########################################################################


########## TSHOOT FUNCTIONS ##########
test_ping(){
    echo -e "\n*TEST (PING) IN PROGRESS ..."
    echo  "### TEST (PING) STARTS" > "$log_folder/tshoot/tshoot-$stype-$ipaddress-$log_date.tshoot"
    ping $ipaddress  >> "$log_folder/tshoot/tshoot-$stype-$ipaddress-$log_date.tshoot"
    sleep 8
    [[ $( tail -n 3 "$log_folder/tshoot/tshoot-$stype-$ipaddress-$log_date.tshoot" ) =~ ([0-1]{0,1}[0-9]{1,2})%.*loss ]]
    [[ ${BASH_REMATCH[0]} =~ ([0-1]{0,1}[0-9]{1,2}) ]]
    ping_percentage=$(echo " $BASH_REMATCH" )
    if [[ $ping_percentage -eq 0 ]]
    then
        echo " TEST (PING) >>> PASSED"
    elif  [[ $ping_percentage -eq 100 ]]
    then
        echo " TEST (PING) >>> FAILED --- Loss Rate:$ping_percentage%"
        echo -e "\t\tAll packets are dropped. This may cause because of:\n\t\t\t - Firewall Protection\n\t\t\t - ICMP restriction in the network\n\t\t\t - Destination may not accept ICMP packets.\n\t\t\t - Wrong IP address\n\t\t\t - Far end may be off\n"
    else
        echo " TEST (PING) >>> NEEDS TO REVIEW --- Loss Rate:$ping_percentage%"
        echo -e "\t\tThere are some drops. This may cause because of:\n\t\t\t - Physical problem\n\t\t\t - Congestion in the network\n\t\t\t"
    fi
    echo  "### TEST (PING) ENDS" >>"$log_folder/tshoot/tshoot-$stype-$ipaddress-$log_date.tshoot"
}



test_route(){
    echo -e "\n*TEST (ROUTE CHECK) IN PROGRESS ..."
    echo -e "\n### TEST (ROUTE CHECK) STARTS" >> "$log_folder/tshoot/tshoot-$stype-$ipaddress-$log_date.tshoot"
    echo "$( netstat -r )" >> $log_folder/tshoot/tshoot-$stype-$ipaddress-$log_date.tshoot
    if [ $( cat  $log_folder/tshoot/tshoot-$stype-$ipaddress-$log_date.tshoot | grep  -Ewi  "(0.0.0.0|default)" | wc -l ) -gt 0 ]
    then
        echo -e "\t\tDefault route PASSED."
    else
        echo -e "\t\tDefault route FAILED."
    fi
    ipconfig.exe  | grep -B 4 -A 2 -T $( PATHPING.EXE -n -w 1 -h 1 -q 1 $ipaddress | head -n 4 | tail -n 1 | awk '{print $2}')  >> "$log_folder/tshoot/tshoot-$stype-$ipaddress-$log_date.tshoot"
    echo -e "\t\tRouting Information:"
    echo -e "\t\t$(tail -7 $log_folder/tshoot/tshoot-$stype-$ipaddress-$log_date.tshoot)"
}



test_traceroute(){
    echo -e "\n*TEST (TRACEROUTE) IN PROGRESS ..."
    echo  -e "\n### TEST (TRACEROUTE) STARTS" >> "$log_folder/tshoot/tshoot-$stype-$ipaddress-$log_date.tshoot"
    tracert.exe $ipaddress  >> "$log_folder/tshoot/tshoot-$stype-$ipaddress-$log_date.tshoot"
    [[ $(cat "$log_folder/tshoot/tshoot-$stype-$ipaddress-$log_date.tshoot") =~ (TRACEROUTE).* ]]; echo "$BASH_REMATCH" | awk -e '$1 ~ /^[0-9]{0,1}[1-9]/ {print $0}' | awk -v max=0 -v ips="" '
    {
        count = 0
        sum = 0
        avg =0
        
        if ( $2 == "*" && $4 == "*" && $6 == "*" )
            avg = 0
        else
        {
            if ( $2 != "*" )
            {
                count+=1
                sum+=$2
            }
            if ( $4 != "*" )
            {
                count += 1
                sum += $4
            }
            if ( $6 != "*" )
            {
                count += 1
                sum += $6
            }
            if ( sum > 0 )
            {    avg = sum/count
                if ( avg > max )
                {
                    max = avg
                    ips = $8
                }
            }
        }
    } END { print "Max return average time is", max, "ms at", ips }' | tee -a "$log_folder/tshoot/tshoot-$stype-$ipaddress-$log_date.tshoot"
    echo "### TEST (TRACEROUTE) ENDS"  >> "$log_folder/tshoot/tshoot-$stype-$ipaddress-$log_date.tshoot"
    echo " Review the traceroute for which devices knows the destination IP" 
} 



case_tshoot(){
    case "$1" in
        connectiontimedout)
            test_ping
            test_route
            test_traceroute
            ;;
        noroutetohost)
            test_route
            test_traceroute
            ;;
    esac
}


 
########## TSHOOT MAIN ##########
lastlineoflog=$( tail -n 3 $log_file| tr -d ' ' | tr [:upper:] [:lower:] )
errors=("connectiontimedout" "noroutetohost")


for error in ${errors[@]}
do
    if [[ "$lastlineoflog" =~ "$error" ]]
    then
        echo -e "\n\n ERROR    >>>    $error\n"
        echo "!!!!!    !!!!!    TROUBLESHOOT INITIALIZE for $ipaddress    !!!!!    !!!!!"
        if [ ! -d "$log_folder/tshoot" ]
        then
            mkdir "$log_folder/tshoot"
        fi
        case_tshoot $error
        echo -e "\n\nTshoot file location:\n$log_folder/tshoot/tshoot-$stype-$ipaddress-$log_date.tshoot"
        break
    fi
done
