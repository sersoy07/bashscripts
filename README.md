# SECON 

**SECON** is a bash script to be used while connecting to the network device. 

  

  

## PURPOSE 

**SECON** is a script written to use pre-installed remote connection protocols (like ssh, telnet, etc.) from a single point. 

  

  

## BENEFITS 

- Engaging multiple protocols without remembering exact name. 

- You do not have to memorize which device uses which protocol by which port number by using host file. 

- If there is a problem during the connection, it initiates the Troubleshooting Procedure. 

- More troubleshooting tests can be added by users. 

- CLI connections and troubleshooting outcomes are automatically logged for the past checks. 

  

  

## INSTALLATION 

- Download the code your system name as *secon.sh*. 

- Make the *secon.sh* file executable by using *chmod 755 secon.sh* 

- Install your vncviewer and RDP app and change the command for vncviewer command in the section CONNECTION *tigervnc* for VNC (*apt install tigervnc*), *xfreerdp* for RDP (*apt install freerdp*). 

- Check output of *nslookup* command. Is IP in column 2 or column 3? According to column number change thednscheck=$( nslookup $1 | awk '/'"Address"'/ {print $2}') parameter from $2 to $3 in ipaddresscheck function 

    >nslookup google.com 

    > 

    >Name:      google.com 

    > 

    >Address 1: 142.250.187.238 lhr25s34-in-f14.1e100.net 

    > 

    >Address 2: 2a00:1450:4009:81f::200e lhr25s33-in-x0e.1e100.net 

    > 

    >In here IP is in column 3. "Address" is column 1; "1:" is column 2                                                                   

- Send ping to specific IP (ex:8.8.8.8). If your ping doesn't stop after 5th ICMP packet, in the test_ping function, add count for ping (ex: *ping -c 5 $ipaddress* for Fedora OS). 

- In test_traceroute function, change the traceorute command according to your OS. 

- In test_traceroute function, millisecond and ip address positions can be changed according to your OS, please test in your system. Change the $ number in your test_treaceroute finction according to trace output. 

- In the Tshoot Main, troubleshoot is performed for 2  erros in the errors array (errors=("connectiontimedout" "noroutetohost")). If you want to perform troubleshooting for more errors, you can add the error output identifier without space and uppercase.  

    >As an example, if you received the following error; 

        >'ssh: connect to host 1.2.3.4 22: Connection refused' 

    > 

    >you can use Connection refused as identifier and add it to errors array as errors=("connectiontimedout" "noroutetohost" "connectionrefused") 

    > 

    >In addition, add the same error to case_tshoot function in Tshoot function section and define the test cases that you want to run. 

- In this sample code, we run different test functions for different errors. If you want to run all tshoot test functions to collect data independent from error type. You can change the "case_tshoot $error" with "test_ping" and then go to "test_ping" function and at the end of funcion you can call test_route function and go to the end of test_route function add test_trace... 

- Change the host file and/or log_folder if you want. 

- Save IPs to your host file as below, to find it easily in while try to connect: 

    >\# \<ip\>      \<domain\>      \<connection\>  \<port\[-comment|device type\]\> 

    > 

    >   1.2.3.4     myserver.lab    #ssh 

    > 

    >   1.2.3.4     myserver.lab    #vnc            12345-Windows_10 

- You can add your tshoot test functions and improve the code. 

  

  

  

## HOW TO USE 

Save IP addresses to your host file as below, to find it easily in while try to connect: 

    >\# \<ip\>      \<domain\>      \<connection\>  \<port\[-comment|device type\]\> 

    > 

    >   1.2.3.4     myserver.lab    #ssh 

    > 

    >   1.2.3.4     myserver.lab    #vnc            12345-Windows_10 

``` 

[linux@localhost ~]$ cat /etc/hosts 

1.2.3.4         router.lab      #ssh-sftp       Router-GW 

2.3.4.5         myserver.lab    #rdp            Win10@12345 

2.3.4.5         myserver.lab    #ssh            fedora@12346 

2.3.4.5         myserver.lab    #vnc            ubuntu@12347 

2.3.4.5         myserver.lab    #vnc            Centos@12348 

``` 

``` 

[linux@localhost ~]$ ./secon.sh 

Usage: ./secon.sh [-t] connection_type [-i] ipaddress|name [[-p] port] [-u] username 

``` 

``` 

[linux@localhost ~]$ ./secon.sh ssh 1.2.3.4 admin 

``` 

``` 

[linux@localhost ~]$ ./secon.sh ssh 1.2.3.4  122  admin 

``` 

``` 

[linux@localhost ~]$ ./secon.sh ssh 

~~ SSH CONNECTIONS ~~ 

1 1.2.3.4 router.lab Router-GW 

2 2.3.4.5 myserver.lab fedora@12346 

Please enter the selection number or IP address:2 

Please enter the port number or leave empty for default: 12346 

Please enter the username or leave empty for default:admin 

IP Address check PASSED 

ssh to 2.3.4.5:12346 as admin on Mon 26 Feb 16:29:37 GMT 2024 

``` 

``` 

*[linux@localhost ~]$ ./secon.sh vnc 

~~ VNC CONNECTIONS ~~ 

1 2.3.4.5 myserver.lab ubuntu@12347 

2 2.3.4.5 myserver.lab Centos@12348 

Please enter the selection number or IP address:2 

Please enter the port number or leave empty for default:12348 

IP Address check PASSED 

vnc to 2.3.4.5:12348 as  on Mon 26 Feb 16:31:25 GMT 2024 

``` 

You may want to add permanent aliasing (*alias secon=<path of secon.sh($HOME/secon.sh)*> to *.bashrc*. 

 

 
