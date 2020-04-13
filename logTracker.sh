#!/bin/bash

#help information
help="LOGTRACKER's PURPOSE:
	To monitor the specified games logs and flag logs that have stopped progressing.
        The logs will be emailed to the user. They will be sent to your spam folder, so drag them into your inbox to see the attached log.
        Logs that have already been sent will not be sent again, unless you restart this script.
	Report any issues to the SQA dev team please.

      LOGTRACKER REQUIRED FLAGS

      -p <path where logs reside> example: /sqagatorRuns/20181001135554_3D.60.WC3.X.11.1111.0.1.B.XML/assets/cj/GamesBuilt/chinawild/  

      -u <username that is part of your email. Ex: shealy> 

      -t <amount of time to wait before checking the logs again. Ex: 5 = 5seconds, 1m = 1 minute, 1h = 1hour, 1d = 1 day>

       If you enter -t 0, then the this script will not continually monitor logs.
       Ideally you would use this setting if your game's runs are fully complete and you want a final log report. 

      Here's an example of the entire command:
	./logTracker.sh -p /sqagatorRuns/20181001135554_3D.60.WC3.X.11.1111.0.1.B.XML/assets/cj/GamesBuilt/chinawild/ -u shealy -t 20"

#Flag logic
while getopts 'p:u:t:h:' option
do
case "${option}"
in
p) location=${OPTARG};;
u) username=${OPTARG};;
t) sleeptime=${OPTARG};;
h) echo "$help" >&2
   exit 0;;
esac
done

#create file for mailing log info
echo "nano email.txt"
domain="@playags.com"
subject="Subject:Logtracker Log Status Update"
subjectAttachment="Subject:LogtrackerFailedLogs"
echo "WELCOME TO LOGTRACKER! After you submit the location of your logs, i will monitor them and tell you when any log(s) are failing."
logfile=/home/qagator/scripts/logTracker.log

#Get the log location path from user -- paths vary depending on player version generally
#answer="N"
#while [ $answer != "Y" ]
#do
#echo Please enter the path where your logs are located.
#echo "17.1 3D Logs Path Example: /sqagatorRuns/20180920120113_3D.50.WS3.X.12.1111.0.1.B.XML/assets/cj/GamesBuilt/wildsurprize/"
#read location
#echo You entered $location
#echo "Is this correct? (enter Y or N)"
#read answer
#done
#echo "PATH SAVED"

#Get the user's username
#usernameanswer="N"
#while [ $usernameanswer != "Y" ]
#do
#echo "Please enter the email username where you would like the log data sent (ex: shealy). @playags.com will be appended automatically."
#read username
#echo You entered $username
#echo "Is this correct? (enter Y or N)"
#read usernameanswer
#done
#echo "USERNAME SAVED"

#write some info email.txt
echo "TO: $username$domain" > email.txt
echo $subject >> email.txt
echo "Log path: $location" >> email.txt

#sleepAnswer="N"
#ask user for interval time
#while [ $sleepAnswer != "Y" ]
#do
#echo "How often should i check your logs?"
#echo "Examples: '5' would equal 5 seconds, '1m' would equal 1 minute, '1h' is 1 hour, '1d' is 1 day"
#read sleeptime
#echo You entered $sleeptime
#echo "Is this correct? (enter Y or N)"
#read sleepAnswer
#done
#echo "SLEEP INTERVAL SET"
#write the user's sleep interval to email.txt
echo "Sleep interval: $sleeptime" >> email.txt

#create associative array to hold logs and their % complete
declare -A LOGMAP
#create associative array that holds the timestamp of the latest log % complete
declare -A LOGMAPTIME
#create associative array that holds a list of failing logs and if they have been reported via email or not
declare -A BROKELOGSTATUS

ext=*.log
tilde=~
fullPath=$tilde$location$ext
#run in a timed loop
echo "$(date "+%m%d%Y %T") : ============================LOOP STARTING================================" >> $logfile 2>&1
while true;do
#populate the array by looping through each file name and adding in the log #. Add any new logs to the array as they are created (run this section in a loop).
#for f in ~/sqagatorRuns/20180920120113_3D.50.WS3.X.12.1111.0.1.B.XML/assets/cj/GamesBuilt/wildsurprize/*.log
for f in $fullPath
do
#extract log number
echo ${f}
#resultSize=${f}
#echo ${#resultSize}
result=$(echo $f| cut -d'/' -f 10)
echo "Extraction RESULT = $result"
resultFinal=$(echo $result| cut -d'.' -f 1)
echo "Final extract result = $resultFinal"

#extract %complete from log
log=.log
#lastLine=$(sudo tac ~/sqagatorRuns/20180920120113_3D.50.WS3.X.12.1111.0.1.B.XML/assets/cj/GamesBuilt/wildsurprize/$resultFinal.log | grep -m 1 '.')
lastLine=$(sudo tac $tilde$location$resultFinal.log | grep -m 1 '.')
percentComplete=$(echo $lastLine| cut -d'o' -f 1)
echo "Percentage completed = $percentComplete"
#handle if gameplay did not begin
if [[ $percentComplete == *"%"* ]]
then
 	echo "percent complete contains a %, and made it to gameplay"
else
	echo "percent complete DOES NOT contain %, and never made it to gameplay."
	percentComplete="ERR:NOGP"
fi

#extract the last time this log was accessed/updated
#path=~/sqagatorRuns/20180920120113_3D.50.WS3.X.12.1111.0.1.B.XML/assets/cj/GamesBuilt/wildsurprize/
path=$tilde$location
lastUpdate=$(date -r $path$resultFinal$log)
echo "Last Updated: $lastUpdate"
#save log number and % complete to LOGMAP
LOGMAP[$resultFinal]=$percentComplete
#save log last access time to LOGMAPTIME array
LOGMAPTIME[$resultFinal]=$lastUpdate

#extract day of the month value from $lastUpdate
lastUpdatedDay=$(echo $lastUpdate| cut -d' ' -f 3)
echo "Day of the month last updated= $lastUpdatedDay"
#if day of the month is a single digit, prepend a zero.
if [ $lastUpdatedDay -lt 10 ]
then
        lastUpdatedDay="0$lastUpdatedDay"
        echo "Last updated day is a single digit... prepending a zero now."
else
        echo "Last updated day is a double digit number.. avoiding zero prepend."
fi

#extract year value
lastUpdatedYear=$(echo $lastUpdate| cut -d' ' -f 6)
echo "Year of last update= $lastUpdatedYear"
#extract time value
lastUpdatedTime=$(echo $lastUpdate| cut -d' ' -f 4)
echo "Time of last update= $lastUpdatedTime"
#extract month value
lastUpdatedMonth=$(echo $lastUpdate| cut -d' ' -f 2)
echo "Month of last update= $lastUpdatedMonth"

#set month to the cooresponding number
if [ $lastUpdatedMonth = "Jan" ]
then
	month=01
elif [ $lastUpdatedMonth = "Feb" ]
then
	month=02
elif [ $lastUpdatedMonth = "Mar" ]
then
        month=03
elif [ $lastUpdatedMonth = "Apr" ]
then
        month=04
elif [ $lastUpdatedMonth = "May" ]
then
        month=05
elif [ $lastUpdatedMonth = "Jun" ]
then
        month=06
elif [ $lastUpdatedMonth = "Jul" ]
then
        month=07
elif [ $lastUpdatedMonth = "Aug" ]
then
        month=08
elif [ $lastUpdatedMonth = "Sep" ]
then
        month=09
elif [ $lastUpdatedMonth = "Oct" ]
then
        month=10
elif [ $lastUpdatedMonth = "Nov" ]
then
        month=11
elif [ $lastUpdatedMonth = "Dec" ]
then
        month=12
else
	echo "ERROR:There isn't a day of the month match"
fi

echo "Last updated month number value = $month"

#dash="-"
#convert log's last updated date to comparable value
lastDateConverted=$lastUpdatedYear$month$lastUpdatedDay
echo "Logs last updated YMD after adding back together = $lastDateConverted"

#get current system date and time
CURRENTDATE=`date +"%Y-%m-%d"`
echo "Today's date is $CURRENTDATE"
CURRENTTIME=`date +"%T"`
echo "The time is now $CURRENTTIME"

daysPast=$(echo "($(date +%s)-$(date +%s -d $lastDateConverted))/86400"|bc)
echo "The number of days between last updated log date and todays date is $daysPast"
hoursPast=$(echo "($(date +%s -d $CURRENTTIME)-$(date +%s -d $lastUpdatedTime))/60/60"|bc)
echo "Difference between current time and last time log was updates = $hoursPast hours"

#determine if log is hung
#If log is not at 100% AND x time has passed, the log may have stopped progressing
if [ $percentComplete != "100.00%" ]
then
	#log not yet completed
	echo "This log has NOT completed yet. Now checking number of days passed since last log update..."
	if [ $daysPast -lt 1 ]
	then
		echo "Days passed is less than 1 day, so ill now check time passed..."
		if [ $hoursPast -gt 0 ]
		then
			echo "One or more hours have passed since this log has updated. This log is potentially hosed. Sending message to logTracker.log...."
			echo "$(date "+%m%d%Y %T") : ERROR: Log stopped progressing - Log: $result %complete: $percentComplete Last Update: $lastUpdate" >> $logfile 2>&1
			#update email.txt
			echo "$(date "+%m%d%Y %T") : ERROR: Log stopped progressing - Log: $result %complete: $percentComplete Last Update: $lastUpdate" >> email.txt
                	#does the log already exist in the array? If so, then don't resend as an attachment.
                	if [ -z ${BROKELOGSTATUS[$result]+"check"} ];then
                        	echo "This log doesnt currently exist in the broke log status array... emailing this log as attachment";
                        	echo "Adding NEW broken log to an array..."
                        	BROKELOGSTATUS[$result]="new"
                        	#send the failed log as attachment
                        	mutt -s $subjectAttachment -i email.txt -a $tilde$location$result < /dev/null -- $username$domain
                	else
				BROKELOGSTATUS[$result]="sent"
                        	echo "log exists here in the broke log array, and was most likely already emailed to the user.";
                	fi

		else
			echo "Less than an hour has passed since the log has updated. The log is potentially progressing as intended. It's allgood for now."
		fi

	else
		echo "More than 1 day has passed since this log has updated. This log is potentially hosed. Sending message to logTracker.log...."
		echo "$(date "+%m%d%Y %T") : ERROR: Log stopped progressing - Log: $result %complete: $percentComplete Last Update: $lastUpdate" >> $logfile 2>&1
		#update email.txt
		echo "$(date "+%m%d%Y %T") : ERROR: Log stopped progressing - Log: $result %complete: $percentComplete Last Update: $lastUpdate" >> email.txt

		#does the log already exist in the array? If so, then don't resend as an attachment.
		if [ -z ${BROKELOGSTATUS[$result]+"check"} ];then
			 echo "This log doesnt currently exist in the broke log status array... emailing this log as attachment";
                         echo "Adding NEW broken log to an array..."
                         BROKELOGSTATUS[$result]="new"
                         #send the failed log as attachment
                         mutt -s $subjectAttachment -i email.txt -a $tilde$location$result < /dev/null -- $username$domain
		else
			BROKELOGSTATUS[$result]="sent"
 			echo "log exists here in the broke log array, and was most likely already emailed to the user.";
		fi
	fi
else
	echo "This log has completed 100%"
fi
echo ""
echo ""
done
echo "$(date "+%m%d%Y %T") : Logs location: $location" >> $logfile 2>&1
echo "" >> $logfile 2>&1
#print out LOGMAP contents
for i in "${!LOGMAP[@]}"
do
  echo "LOG  : $i"
  echo "Percent Complete: ${LOGMAP[$i]}"
  #write %complete values to the log
  echo "$(date "+%m%d%Y %T") : Log: $i progress: ${LOGMAP[$i]}" >> $logfile 2>&1
  #write %complete values to email.txt
  echo "$(date "+%m%d%Y %T") : Log: $i progress: ${LOGMAP[$i]}" >> email.txt
done
#print out LOGMAPTIME contents
for i in "${!LOGMAPTIME[@]}"
do
  echo "LOG  : $i"
  echo "Last updated: ${LOGMAPTIME[$i]}"
done
echo "" >> email.txt
echo "HUNG LOGS (new or sent)----------------- :^(" >> email.txt
echo "" >> email.txt
#print out BROKELOGSTATUS contents
for i in "${!BROKELOGSTATUS[@]}"
do
  echo "LOG  : $i"
  echo "Status: ${BROKELOGSTATUS[$i]}"
  echo "LOG  : $i" >> email.txt
  echo "Status: ${BROKELOGSTATUS[$i]}" >> email.txt
done
  echo "" >> email.txt
  echo "END of UPDATE -----------------" >> email.txt
  echo "" >> email.txt
#email mail.txt
echo "Send log info to email..."
ssmtp $username$domain < email.txt

echo "Sleeping for $sleeptime..."
sleep $sleeptime

	#if sleeptime is 0 then don't loop through script
	if [ $sleeptime = "0" ]
	then
		echo "Ending loop because the user says so!"
		exit	
	else
		echo "Continuing loop..."
	fi
done
