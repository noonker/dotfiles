#!/bin/bash


# Checks to make sure the processing folder exists
if [ ! -d /var/spool/asterisk/voicemail/default/processing/ ]
        then
                echo "Please create the /var/spool/asterisk/voicemail/default/processing folder"
                exit
fi


#Checks for new voicemail
for x in /var/spool/asterisk/voicemail/default/*/INBOX/*.wav
	do
		MDFIVE=$(md5sum $x | awk '{ print $1 }')
		FILENAME=$(basename $x)
		PROCESSING='/var/spool/asterisk/voicemail/default/processing'
		CALLER=$(echo $x | cut -d'/' -f7 )
		NAME=$( echo $FILENAME | sed -r 's/\.[[:alnum:]]+$//' )
		EMAIL=$( cat /etc/asterisk/voicemail.conf | grep $CALLER | cut -d',' -f3 )
		if grep -Fxq "$MDFIVE" /var/spool/asterisk/voicemail/default/processing/md5
			then
				echo "MD5 Collision"
			else
				echo $CALLER
				sox $x /derp/$NAME.flac rate 16k
				sox -r 8000 -c 1 $x /derp/$NAME.mp3
				curl --data-binary @/derp/$NAME.flac --header 'Content-type: audio/x-flac; rate=16000' 'https://www.google.com/speech-api/v1/recognize?xjerr=1&client=chromium&pfilter=0&maxresults=1&lang="en-US"' > /derp/message
				if grep -q '<!DOCTYPE html>' "$x"
					then
						echo "THIS EMAIL IS TOO LONG SRRY M8 CHECK UR VOICEMAIL" > /derp/text
					else
						echo "Transcript:" > /derp/text
						cat /derp/message | cut -d"," -f3 | sed 's/^.*utterance\":\"\(.*\)\"$/\1/g' >> /derp/text
						echo "" >> /derp/text
						echo "Confidence Percentage:" >> /derp/text
						cat /derp/message | cut -d"," -f4 | sed 's/^.*confidence\":0.\([0-9][0-9]\).*$/\1/g' >>/derp/text
				fi
				mutt -s "Voicemail from $CALLER" $EMAIL -a /derp/$NAME.mp3 < /derp/text
				echo $MDFIVE >> $PROCESSING/md5

		fi
	done
