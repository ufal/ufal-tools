#!/bin/bash

MAXWAITHOURS=72  # it will wait at most 3 days for running

HASH=$1
INDEX=$2  ## index of the GPU to hold, starting with 1
AMOUNT=$3  ## total number of GPUs (and tasks) to hold
shift
shift
shift
CMD="$@"

DIR=.$HASH

mkdir -p $DIR

JOBID=$DIR/$INDEX.$AMOUNT.jobid  ## current jobid will be stored in this file, qsubmit puts it there
# maybe it's not available in this moment!!!


echo $CUDA_VISIBLE_DEVICES > $DIR/$INDEX.$AMOUNT.gpus

LOCK=$DIR/lock

while ! lockfile $LOCK; do
	usleep $(($RANDOM%100))
done

# možná TODO: zajistit, aby všecky joby běžely na jednom stroji

WORK=yes
export CUDA_VISIBLE_DEVICES=""
for i in `seq 1 $AMOUNT`; do
	f=$DIR/$i.$AMOUNT.gpus
	[ ! -s $f ] && WORK=no && echo $f does not exist or is empty >&2 && break
	j=$DIR/$i.$AMOUNT.jobid
	[ ! -s $j ] && WORK=no && echo $j does not exist or is empty >&2 && break
	qstat -j `cat $j` >/dev/null 2>&1 | grep 'jobs do not exist' && WORK=no && echo job `cat $j` does not exist >&2 && break
	export CUDA_VISIBLE_DEVICES="$CUDA_VISIBLE_DEVICES `cat $f`"
done

echo CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES >&2
if [ "$WORK" == yes ]; then # run the command 
	$CMD
	for i in `seq 1 $AMOUNT`; do # kill waiting jobs
		j=$DIR/$i.$AMOUNT.jobid
		if [ ! $j = $JOBID ]; then
			qdel `cat $j`
		fi
	done
else  # sleep
	rm $LOCK # release the lock for others
	for i in `seq $MAXWAITHOURS`; do  # sleep 1 hour
		echo `date` sleeping... >&1
		sleep 3600
	done
fi

# Note: the directory .$HASH remains there
# together with .qsubmit-XXXXX.bash files from the waiting jobs







