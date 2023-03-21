#!/bin/bash

##### KONFIGURACJA #####

tempdir=".";
output="";
threshold="7200"; ## Wartość progu predykcji, domyslnie 7200 (30minut)

##### KONFIGURACJA #####

now=`date +%s`;
disks=`df | grep -E "^\/dev\/" | grep -v "loop" | awk '{print $1 " " $3}'`;
prev=`cat $tempdir/data.tmp`;

LastCheckTime=`echo "$prev" | head -n 1`;
SinceLastCheck=`echo "$now - $LastCheckTime" | bc`;

echo "Ostatnie sprawdzenie: $SinceLastCheck s temu";

#############
IFS=$'\n'
#############

for i in `echo "$prev" | sed 1,1d`; do
        disk=`echo $i | awk '{print $1}'`;
        diskSpacePrev=`echo $i | awk '{print $2}'`;
        diskSpaceNow=`df | grep "\`echo $disk\`" | awk '{print $3}'`;
	wynik=`echo "$diskSpaceNow - $diskSpacePrev" | bc`;
	freeSpace=`df | grep "$disk" | awk '{print $4}'`;

        if [ "$wynik" == "0" ] ; then
		estimate=`echo "bez zmian"`;
        elif [ `echo "$wynik" | grep -Ec "^\-"` == "1" ] ; then
		estimate=`echo "tendencja spadkowa"`;
	else
		estimate=`echo "( $freeSpace / $wynik ) * $SinceLastCheck" | bc`;
	fi

	case $estimate in
	    	''|*[!0-9]*) printf "" ;;
		    *) if [ "$estimate" -lt "$threshold" ] ; then output+=`echo "$disk:$estimate "`; fi ;;
	esac

        echo "$disk:  $wynik";
        echo "Estimate: $estimate";
done

echo $output > $tempdir/result

#############
unset IFS
#############

echo $now > $tempdir/data.tmp
echo "$disks"  >> $tempdir/data.tmp

