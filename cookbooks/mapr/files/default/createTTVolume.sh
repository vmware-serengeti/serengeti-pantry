#!/bin/bash
# Copyright (c) 2009 & onwards. MapR Tech, Inc., All rights reserved

#
#  usage: createTTVolumes.sh hostname vol-mnt-point
#

#
# Return codes
#
SUCCESS=0
INTERNAL_ERROR_C1=201
INTERNAL_ERROR_C2=202
COMMAND_FAILURE=203
CMDLOG_CREATION_FAILURE=204
CMDLOG_PERMISSION_FAILURE=205
LOG_CREATION_FAILURE=206
LOG_PERMISSION_FAILURE=207
VOLUME_REMOVAL_FAILED=208
MAPRFS_MOVE_FAILED=209
VOLUME_NOT_HEALTHY=210
UNKNOWN_VOLUME_MOUNTED=211
BAD_USAGE=212

function usage() {
  echo >&2 "usage: $0 <hostname> <volume mountpoint> <full directory path for TT dir>"
  echo >&2 "Example:"
  echo >&2 "$0 `hostname -f` /var/mapr/local/`hostname -f`/mapred/ /var/mapr/local/`hostname -f`/mapred/taskTracker/"
  exit $BAD_USAGE
}


#
# usage: runCommandWithTimeout <exit on error> <maxTime> <maxAttempts> <command>
#
# This function runs the specified command in the background, directing its output to a log file.
# If the command does not return with $commandTimeOut seconds, then a kill -9 will be issued against it.
# When a command attempt fails or is killed, it will be retried up to $maxAttempts times as long as $maxTime seconds has not elapsed since the first attempt
# If $maxTime elapses or the command has failed $maxAttempts times then the function will either exit or return $COMMAND_FAILURE
# If exitOnError is set to 1, a FATAL level message will be logged, the command output will be saved permanently and the script will exit
# If exitOnError is set to 0, a DEBUG level message will be logged and the function will return
#
function runCommandWithTimeout()
{
    # Parse the arguments to the funciton
    local command=`echo $@ | cut -f 5- -d " "`
    local exitOnError=$1
    local maxWaitSeconds=$2
    local maxAttempts=$3
    local sleepBetweenAttempts=$4

    if [ "n$sleepBetweenAttempts" = "n" ]; then
	sleepBetweenAttempts=0
    fi

    # Initialize some variables
    local oTime=`date +%s`
    local tElapsed=0
    local success=0
    local totalAttempts=0
    local commandTimeOut=60

    # Check that the function is called with acceptable arguments
    if [ $maxWaitSeconds -le 0 ]; then
	echo `date +"%Y-%m-%d %T"` FATAL max wait time was set \> 0 >> $logFile
	exit $INTERNAL_ERROR_C1
    elif [ $maxAttempts -le 0 ]; then
	echo `date +"%Y-%m-%d %T"` FATAL max attempts must be \> 0 >> $logFile
	exit $INTERNAL_ERROR_C2
    fi
    if [ $maxWaitSeconds -lt $commandTimeOut ]; then
        echo `date +"%Y-%m-%d %T"` DEBUG The max wait time of $maxWaitSeconds seconds is less than the individual command timeout of $commandTimeOut seconds, adjusting the individual command timeout to match the max wait seconds >> $logFile
        commandTimeOut=$maxWaitSeconds
    fi

    echo `date +"%Y-%m-%d %T"` DEBUG Will launch command \"$command\" with a command attempt timeout of $commandTimeOut seconds a maximum of $maxAttempts attempts and a sleep time of $sleepBetweenAttempts seconds between failed command attempts >> $logFile

    # Loop while the total elapsed time is less than the maximum amount of wait time and the command has not returned 0 in any previous attempt
    while [ $tElapsed -lt $maxWaitSeconds -a $totalAttempts -lt $maxAttempts -a $success -eq 0 ] 
    do
        # Increment the attempt number/total
	totalAttempts=$(( $totalAttempts + 1 ))

        # Launch the command, save the PID of child, record the time the command was launched and the time the command should be killed if it is still running
	echo `date +"%Y-%m-%d %T"` DEBUG Launching \"$command\" >> $logFile
	$command > $commandOutputFile 2>&1 &
	pid=$!
        sTime=`date +%s`
        eTime=$(( $sTime + $commandTimeOut ))

        # Sleep until the command has returned or until it has been running for the maximum allowed amount of time
        while [ -d /proc/$pid -a $eTime -gt `date +%s` ]; do
                sleep 1
        done

        # If the command is still running, kill it and note that the command did not exit on its own by setting wasKilled=1
        if [ -d /proc/$pid ]; then
                echo `date +"%Y-%m-%d %T"` DEBUG Command did not complete within $commandTimeOut seconds, issuing \"kill -9 $pid\" >> $logFile
                wasKilled=1
                kill -9 $pid
                ret=$?
                if [ $ret != 0 ]; then
                        echo `date +"%Y-%m-%d %T"` WARN kill exited with error, return code was $ret >> $logFile
                else
                        echo `date +"%Y-%m-%d %T"` DEBUG Successfully killed process >> $logFile
                fi
        else
                wasKilled=0
        fi

        # Retrieve the return code of the command
        wait $pid
        ret=$?

        cElapsed=`date +%s`
        cElapsed=$(( $cElapsed - $sTime ))

        # Log the results of the command attempt
        if [ $wasKilled -eq 0 ]; then
                if [ $ret -eq 0 ]; then
                        echo `date +"%Y-%m-%d %T"` DEBUG Command attempt $totalAttempts completed successfully in $cElapsed seconds >> $logFile
                        success=1
                else
                        echo `date +"%Y-%m-%d %T"` DEBUG Command attempt $totalAttempts failed with return code $ret after $cElapsed seconds, sleeping for $sleepBetweenAttempts seconds >> $logFile
			sleep $sleepBetweenAttempts > /dev/null 2> /dev/null
                fi
        else
                echo `date +"%Y-%m-%d %T"` DEBUG Command attempt $totalAttempts failed to return within $commandTimeOut seconds, it was killed and returned code $ret, exiting >> $logFile
        fi

        # Calculate how much time has elapsed since the first command attempt was launched
        tElapsed=`date +%s`
        tElapsed=$(( $tElapsed - $oTime ))
    done

    # Determine what should be done now that we have the results of the command attempts
    # If the command completed succesfully then log success
    if [ $success -eq 1 ]; then
        echo `date +"%Y-%m-%d %T"` DEBUG Command completed successfully after $totalAttempts attempts and after $tElapsed seconds >> $logFile
    #If the command did not complete successfully during any attempt
    else
        # Exit with $COMMAND_FAILURE if the script should exit if the command fails
	if [ $exitOnError -eq 1 ]; then
		echo `date +"%Y-%m-%d %T"` FATAL Command did not complete successfully after $totalAttempts attempts and after $tElapsed seconds. >> $logFile
		echo `date +"%Y-%m-%d %T"` INFO The command run was: >> $logFile
		echo "$command" >> $logFile
		echo >> $logFile
		echo `date +"%Y-%m-%d %T"` INFO The output of the last failed command attempt: >> $logFile
		cat $commandOutputFile >> $logFile
		exit $COMMAND_FAILURE
	# Otherwise, log that the command failed
	else
		echo `date +"%Y-%m-%d %T"` DEBUG Command did not complete successfully after $totalAttempts attempts and after $tElapsed seconds >> $logFile
                return $COMMAND_FAILURE
	fi
    fi
    return 0
}


#################
#  main
#################

# Initialize some global variables
server=$(dirname $0) # is most likely /opt/mapr/server
INSTALL_DIR=$(cd "$server/../"; pwd)
logFile="${INSTALL_DIR}/logs/createTTVolume.`id -u`.log"
commandOutputFile="${INSTALL_DIR}/logs/createTTVolume.`id -u`.cmd.out"
. $INSTALL_DIR/server/scripts-common.sh
exitForUsage=0

# Parse arguments to script
hostname=$1
mountpath=`echo $2 | sed  's/\/*$//'`  # remove trailing slashes
fullpath=$3

# Check arguments to script
if [ $# -ne 3 ]; then
  echo >&2 "ERROR Did not detect the expected number of arguments"
  exitForUsage=1
fi
if [ "n$hostname" == "n" ]; then
  echo >&2 "ERROR Empty hostname"
  exitForUsage=1
fi
if [ "n$mountpath" == "n" ]; then
  echo >&2 "ERROR Empty Mount Point"
  exitForUsage=1
fi
if [ "n$fullpath" == "n" ]; then
  echo >&2 "ERROR Empty full path"
  exitForUsage=1
fi
if [ $exitForUsage -eq 1 ]; then
  usage
  exit $BAD_USAGE
fi

#Detect the MFS port
mfsconf=$INSTALL_DIR/conf/mfs.conf
mfsport=$(awk -F= '/^mfs.server.port/ {print $2}' $mfsconf)
if [ "$mfsport" == "" ]; then
  echo >&2 "INFO mfs port not present in $mfsconf, using default setting of 5660" 
  mfsport=5660
fi

# create parent of mountpath
#
vol="mapr.$hostname.local.mapred"
parentpath=${mountpath%/*}  #  dirname of $mountpath
volumeOK=0
touch $logFile
if [ $? -ne 0 ]; then
        echo Failed to create file:$commandOutputFile
        exit $LOG_CREATION_FAILURE
fi
chmod 744 $logFile
if [ $? -ne 0 ]; then
        echo Failed to set permissions on file:$commandOutputFile to 700
        exit $LOG_PERMISSION_FAILURE
fi
touch $commandOutputFile
if [ $? -ne 0 ]; then
	echo Failed to create file:$commandOutputFile
	exit $CMDLOG_CREATION_FAILURE
fi
chmod 700 $commandOutputFile
if [ $? -ne 0 ]; then
	echo Failed to set permissions on file:$commandOutputFile to 700
	exit $CMDLOG_PERMISSION_FAILURE
fi
echo > $commandOutputFile
echo `date +"%Y-%m-%d %T"` INFO This script was called with the arguments: $@ >> $logFile
echo `date +"%Y-%m-%d %T"` INFO Checking if MapRFS is online >> $logFile
runCommandWithTimeout 1 600 1000 1 "hadoop fs -stat /"
runCommandWithTimeout 1 60 1000 1 "hadoop fs -stat $parentpath"
echo `date +"%Y-%m-%d %T"` INFO MapRFS is online.  Checking whether MFS on this node is online >> $logFile
runCommandWithTimeout 1 300 60 3 "$server/mrconfig -p $mfsport info fsstate"
echo `date +"%Y-%m-%d %T"` INFO MFS on this node is online >> $logFile
echo `date +"%Y-%m-%d %T"` INFO Checking for a volume already mounted at the specified mount path >> $logFile
runCommandWithTimeout 0 60 1 1 "maprcli volume list -filter [p==$mountpath]and[mt==1] -columns volumename,mounted,mountdir"  
if [ $? -eq 0 ]; then
	volumeMountedAtPath=`cat $commandOutputFile | tr -s '  ' ' ' | grep "^$mountpath 1 " | wc -l`
	if [ $volumeMountedAtPath -eq 0 ]; then
		echo `date +"%Y-%m-%d %T"` INFO The mount path is not currently being used as the primary mount path of any existing volume >> $logFile
	elif [ $volumeMountedAtPath -eq 1 ]; then
		nameOfVolumeAtMountPath="`cat  $commandOutputFile | tr -s '  ' ' ' | grep "^$mountpath 1 " | cut -f 3 -d " "`"
		if [ "n$nameOfVolumeAtMountPath" != "n$vol" ]; then
			echo `date +"%Y-%m-%d %T"` INFO The volume \"$nameOfVolumeAtMountPath\" is already mounted at the mount point, unmounting it >> $logFile
			runCommandWithTimeout 1 60 3 1 maprcli volume unmount -name $nameOfVolumeAtMountPath
		fi
	else
		echo `date +"%Y-%m-%d %T"` WARN Could not determine whether a volume was mounted at the mount path.  Command output: >> $logFile
		cat $commandOutputFile >> $logFile
	fi
fi
echo `date +"%Y-%m-%d %T"` INFO Checking for a pre-existing TaskTracker volume >> $logFile
runCommandWithTimeout 0 60 1 1 "maprcli volume info -name $vol -json"  
if [ $? -eq 0 ]; then 
	echo `date +"%Y-%m-%d %T"` INFO TaskTracker volume already exists, checking on the volume status >> $logFile
	repfactor=`grep \"numreplicas\":\"1\" $commandOutputFile | wc -l`
	rackpath=$(grep \"rackpath\":\" $commandOutputFile | grep /`hostname -f`\",$ $commandOutputFile | wc -l)
	readonly=`grep \"readonly\":\"0\", $commandOutputFile | wc -l`
	mountdir=`grep \"mountdir\": $commandOutputFile | cut -f 4 -d \"`
	mounted=`grep \"mounted\": $commandOutputFile | cut -f 2 -d : | cut -f 1 -d ,`
	
	#Because of bug 9031, I am listing all alarms then grepping that output instead of listing alarms just for the volume in question, once bug 9031 is fixed, this should be updated
	#runCommandWithTimeout 1 360 10 maprcli alarm list -type VOLUME -entity $vol"
	runCommandWithTimeout 1 180 3 1 "maprcli alarm list -type VOLUME"
	dataAlarmRaised=`grep $vol $commandOutputFile | grep -e DATA_UNDER_REPLICATED -e DATA_UNAVAILABLE | wc -l`

	if [ $repfactor -eq 1 -a $rackpath -eq 1 -a $readonly -eq 1 -a $mounted -eq 1 -a "n$mountdir" = "n$mountpath" -a $dataAlarmRaised -eq 0 ]; then
		echo `date +"%Y-%m-%d %T"` INFO Pre-existing volume is healthy and mounted at the correct path >> $logFile
		volumeOK=1
	else
		if [ $mounted -eq 0 ]; then
			echo `date +"%Y-%m-%d %T"` INFO Pre-existing volume is not mounted >> $logFile
		fi
		if [ "n$mountdir" != "n$mountpath" ]; then
			echo `date +"%Y-%m-%d %T"` INFO Pre-existing volume does not have the expected mountpath, mountpath was $mountdir >> $logFile
		fi
		if [ $dataAlarmRaised -ne 0 ]; then
			echo `date +"%Y-%m-%d %T"` INFO Pre-existing volume has data alarms raised  >> $logFile
			grep $vol $commandOutputFile | grep -e DATA_UNDER_REPLICATED -e DATA_UNAVAILABLE >> $logFile
		fi
		if [ $repfactor -ne 1 ]; then
        	        echo `date +"%Y-%m-%d %T"` INFO Pre-existing volume does not have the expected replication factor >>$logFile   
		fi
		if [ $rackpath -ne 1 ]; then
			echo `date +"%Y-%m-%d %T"` INFO Pre-existing volume does not have the expected rackpath >> $logFile
		fi
		if [ $readonly -ne 1 ]; then
			echo `date +"%Y-%m-%d %T"` INFO Pre-existing volume is set to read-only >> $logFile
		fi
		echo `date +"%Y-%m-%d %T"` INFO Pre-existing volume does not have the expected state, removing it >> $logFile
		runCommandWithTimeout 0 60 1 1 "maprcli volume unmount -force 1 -name $vol"
		runCommandWithTimeout 0 60 1 1 "maprcli volume remove -force true -name $vol"
		runCommandWithTimeout 0 60 1 1 "maprcli volume link remove -path $mountpath"
		runCommandWithTimeout 0 60 1 1 "maprcli volume info -name $vol"
		if [ $? -eq 0 ]; then 
			echo `date +"%Y-%m-%d %T"` FATAL Issued volume remove API but the volume still exists, exiting >> $logFile
			exit $VOLUME_REMOVAL_FAILED
		fi
		echo `date +"%Y-%m-%d %T"` INFO Removed the pre-existing volume  >> $logFile
		runCommandWithTimeout 1 180 3 1 "hadoop mfs -ls $parentpath"
		pathPresent=`grep $mountpath$ $commandOutputFile | wc -l`
		isVolume=`grep $mountpath$ $commandOutputFile | grep ^v | wc -l`
		if [ $pathPresent -ne 0 -a $isVolume -eq 0 ]; then
			echo `date +"%Y-%m-%d %T"` WARN A directory already exists at the same path where the TaskTracker volume should be mounted, the directory will be removed. >> $logFile
			runCommandWithTimeout 0 60 1 1 "hadoop fs -stat $parentpath/old.mapred"
			if [ $? -ne 0 ]; then 
				runCommandWithTimeout 1 360 3 1 "hadoop fs -mkdir $parentpath/old.mapred"
			fi
			runCommandWithTimeout 0 60 1 1 "hadoop fs -mv $mountpath $parentpath/old.mapred/`date +%s`"
			runCommandWithTimeout 0 60 1 1 "hadoop fs -stat $mountpath"
			if [ $? -eq 0 ]; then
				echo `date +"%Y-%m-%d %T"` FATAL Failed to move the existing directory at the mountpath $mountpath to the old.mapred directory at $parentpath/old.mapred for deletion >> $logFile
				exit $MAPRFS_MOVE_FAILED
			fi
			nohup hadoop fs -rmr $parentpath/old.mapred > /dev/null 2> /dev/null &	
			echo `date +"%Y-%m-%d %T"` INFO The pre-existing directory is being deleted in the background by process $!  >> $logFile
			echo `date +"%Y-%m-%d %T"` INFO A new TaskTracker volume will be created.  >> $logFile
			runCommandWithTimeout 1 180 3 1 "maprcli volume create -name $vol -path $mountpath -replication 1 -localvolumehost $hostname -localvolumeport $mfsport -shufflevolume true"
			runCommandWithTimeout 1 180 3 1 "maprcli volume info -name $vol -json"
			mountdir=`grep \"mountdir\": $commandOutputFile | cut -f 4 -d \"`
			mounted=`grep \"mounted\": $commandOutputFile | cut -f 2 -d : | cut -f 1 -d ,`
			#Because of bug 9031, I am listing all alarms then grepping that output instead of listing alarms just for the volume in question, once bug 9031 is fixed, this should be updated
			runCommandWithTimeout 1 180 3 1 "maprcli alarm list -type VOLUME"
			dataAlarmRaised=`grep $vol $commandOutputFile | grep -e DATA_UNDER_REPLICATED -e DATA_UNAVAILABLE | wc -l`
			if [ $mounted -eq 1 -a "n$mountdir" = "n$mountpath" -a $dataAlarmRaised -eq 0 ]; then
				echo `date +"%Y-%m-%d %T"` INFO Successfully created new volume and verified it is healthy >> $logFile
				volumeOK=1
			else
				echo `date +"%Y-%m-%d %T"` FATAL Created a new volume but it is not healthy >> $logFile
				exit $VOLUME_NOT_HEALTHY
			fi
		elif [ $pathPresent -ne 0 -a $isVolume -ne 0 ]; then
			echo `date +"%Y-%m-%d %T"` FATAL A volume is already mounted at the mountpath for the TaskTracker volume but it is not the expected volume, hadoop mfs -ls output follows >> $logFile
			cat $commandOutputFile >> $logFile
			exit $UNKNOWN_VOLUME_MOUNTED
		elif [ $pathPresent -eq 0 ]; then
			echo `date +"%Y-%m-%d %T"` INFO A new TaskTracker volume will be created.  >> $logFile
			runCommandWithTimeout 1 180 3 1 "maprcli volume create -name $vol -path $mountpath -replication 1 -localvolumehost $hostname -localvolumeport $mfsport -shufflevolume true"
			runCommandWithTimeout 1 180 3 1 "maprcli volume info -name $vol -json"
			mountdir=`grep \"mountdir\": $commandOutputFile | cut -f 4 -d \"`
                        mounted=`grep \"mounted\": $commandOutputFile | cut -f 2 -d : | cut -f 1 -d ,`
                        #Because of bug 9031, I am listing all alarms then grepping that output instead of listing alarms just for the volume in question, once bug 9031 is fixed, this should be updated 
			runCommandWithTimeout 1 180 3 1 "maprcli alarm list -type VOLUME"
                        dataAlarmRaised=`grep $vol $commandOutputFile | grep -e DATA_UNDER_REPLICATED -e DATA_UNAVAILABLE | wc -l`
			if [ $mounted -eq 1 -a "n$mountdir" = "n$mountpath" -a $dataAlarmRaised -eq 0 ]; then
                                echo `date +"%Y-%m-%d %T"` INFO Successfully created new volume and checked that it is healthy >> $logFile
                                volumeOK=1
                        else
                                echo `date +"%Y-%m-%d %T"` FATAL Created a new volume but it is not healthy >> $logFile
                                exit $VOLUME_NOT_HEALTHY
                        fi
		fi

	fi
else
	echo `date +"%Y-%m-%d %T"` INFO A pre-existing TaskTracker volume could not be found, will try to create one.  >> $logFile
                runCommandWithTimeout 1 180 3 1 "hadoop mfs -ls $parentpath"
                pathPresent=`grep $mountpath$ $commandOutputFile | wc -l`
                isVolume=`grep $mountpath$ $commandOutputFile | grep ^v | wc -l`
                if [ $pathPresent -ne 0 -a $isVolume -eq 0 ]; then
                        echo `date +"%Y-%m-%d %T"` WARN A directory already exists at the same path where the TaskTracker volume should be mounted, the directory will be removed. >> $logFile
			runCommandWithTimeout 0 60 1 1 "hadoop fs -stat $parentpath/old.mapred"
                        if [ $? -ne 0 ]; then
                                runCommandWithTimeout 1 360 3 1 "hadoop fs -mkdir $parentpath/old.mapred"
                        fi
                        runCommandWithTimeout 0 60 1 1 "hadoop fs -mv $mountpath $parentpath/old.mapred/`date +%s`"
                        runCommandWithTimeout 0 60 1 1 "hadoop fs -stat $mountpath"
                        if [ $? -eq 0 ]; then
                                echo `date +"%Y-%m-%d %T"` FATAL Failed to move the existing directory at the mountpath $mountpath to the old.mapred directory at $parentpath/old.mapred for deletion >> $logFile
                                exit $MAPRFS_MOVE_FAILED
                        fi
                        nohup hadoop fs -rmr $parentpath/old.mapred > /dev/null 2> /dev/null &
                        echo `date +"%Y-%m-%d %T"` INFO The pre-existing directory is being deleted in the background by process $!  >> $logFile
                        echo `date +"%Y-%m-%d %T"` INFO A new TaskTracker volume will be created.  >> $logFile
			runCommandWithTimeout 1 180 3 1 "maprcli volume create -name $vol -path $mountpath -replication 1 -localvolumehost $hostname -localvolumeport $mfsport -shufflevolume true"
                        runCommandWithTimeout 1 180 3 1 "maprcli volume info -name $vol -json"
                        mountdir=`grep \"mountdir\": $commandOutputFile | cut -f 4 -d \"`
                        mounted=`grep \"mounted\": $commandOutputFile | cut -f 2 -d : | cut -f 1 -d ,`
                        #Because of bug 9031, I am listing all alarms then grepping that output instead of listing alarms just for the volume in question, once bug 9031 is fixed, this should be updated
                        runCommandWithTimeout 1 180 3 1 "maprcli alarm list -type VOLUME"
                        dataAlarmRaised=`grep $vol $commandOutputFile | grep -e DATA_UNDER_REPLICATED -e DATA_UNAVAILABLE | wc -l`
                        if [ $mounted -eq 1 -a "n$mountdir" = "n$mountpath" -a $dataAlarmRaised -eq 0 ]; then
                                echo `date +"%Y-%m-%d %T"` INFO Successfully created new volume and checked that it is healthy >> $logFile
                                volumeOK=1
                        else
                                echo `date +"%Y-%m-%d %T"` FATAL Created a new volume but it is not healthy >> $logFile
                                exit $VOLUME_NOT_HEALTHY
                        fi
                elif [ $pathPresent -ne 0 -a $isVolume -ne 0 ]; then
                        echo `date +"%Y-%m-%d %T"` FATAL A volume is already mounted at the mountpath for the TaskTracker volume but it is not the expected volume, hadoop mfs -ls output follows >> $logFile
                        cat $commandOutputFile >> $logFile
                        exit $UNKNOWN_VOLUME_MOUNTED
                elif [ $pathPresent -eq 0 ]; then
                        echo `date +"%Y-%m-%d %T"` INFO A new TaskTracker volume will be created.  >> $logFile
			runCommandWithTimeout 1 180 3 1 "maprcli volume create -name $vol -path $mountpath -replication 1 -localvolumehost $hostname -localvolumeport $mfsport -shufflevolume true"
                        runCommandWithTimeout 1 180 3 1 "maprcli volume info -name $vol -json"
                        mountdir=`grep \"mountdir\": $commandOutputFile | cut -f 4 -d \"`
                        mounted=`grep \"mounted\": $commandOutputFile | cut -f 2 -d : | cut -f 1 -d ,`
                        #Because of bug 9031, I am listing all alarms then grepping that output instead of listing alarms just for the volume in question, once bug 9031 is fixed, this should be updated 
                        runCommandWithTimeout 1 180 3 1 "maprcli alarm list -type VOLUME"
                        dataAlarmRaised=`grep $vol $commandOutputFile | grep -e DATA_UNDER_REPLICATED -e DATA_UNAVAILABLE | wc -l`
                        if [ $mounted -eq 1 -a "n$mountdir" = "n$mountpath" -a $dataAlarmRaised -eq 0 ]; then
                                echo `date +"%Y-%m-%d %T"` INFO Successfully created new volume and checked that it is healthy >> $logFile
                                volumeOK=1
                        else
                                echo `date +"%Y-%m-%d %T"` FATAL Created a new volume but it is not healthy >> $logFile
                                exit $VOLUME_NOT_HEALTHY
                        fi
                fi
fi

#At this point, the volume exists and is mounted at the expected path

:
date=`date +%s`
echo `date +"%Y-%m-%d %T"` INFO Checking for pre-existing content in the TaskTracker volume >> $logFile
runCommandWithTimeout 0 60 1 1 "hadoop fs -stat $fullpath"
if [ $? -eq 0  ]; then
	echo `date +"%Y-%m-%d %T"` INFO There is pre-existing content in the TaskTracker volume, removing it. >> $logFile
	runCommandWithTimeout 1 180 3 1 "hadoop fs -mv $fullpath $mountpath/old.$date"
	nohup hadoop fs -rmr $mountpath/old.* > /dev/null 2> /dev/null &
	echo `date +"%Y-%m-%d %T"` INFO The pre-existing content is being deleted in the background by process $!  >> $logFile
fi

echo `date +"%Y-%m-%d %T"` INFO Creating directories in the TaskTracker volume that will be needed by the TaskTracker process >> $logFile
runCommandWithTimeout 1 30 30 15 "hadoop fs -mkdir $fullpath"
runCommandWithTimeout 1 180 3 1 "hadoop mfs -setcompression on $fullpath"
runCommandWithTimeout 1 180 3 1 "hadoop fs -mkdir $fullpath/spill"
runCommandWithTimeout 1 180 3 1 "hadoop fs -mkdir $fullpath/output"
runCommandWithTimeout 1 180 3 1 "hadoop fs -mkdir $fullpath/spill.U"
runCommandWithTimeout 1 180 3 1 "hadoop fs -mkdir $fullpath/output.U"
runCommandWithTimeout 1 180 3 1 "hadoop mfs -setcompression off $fullpath/spill.U"
runCommandWithTimeout 1 180 3 1 "hadoop mfs -setcompression off $fullpath/output.U"
echo `date +"%Y-%m-%d %T"` INFO The TaskTracker local volume has been setup successfully. >> $logFile
exit $SUCCESS
