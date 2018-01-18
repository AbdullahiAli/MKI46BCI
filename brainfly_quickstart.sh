#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
buffdir=`dirname $0`

# Reading passed arguments
dataacq='mobita';
if [ $# -gt 0 ]; then dataacq=$1; fi
sigproc=0;
if [ $# -gt 1 ]; then sigproc=$2; fi
stimuli='hybrid';
if [ $# -gt 2 ]; then stimuli=$3; fi

# Code to start java buffer server
echo Starting the java buffer server \(background\)
dataAcq/startJavaBuffer.sh &
bufferpid=$!
echo buffpid=$bufferpid
sleep 5

# Code to start data acquisition device
echo Starting the data acquisation device $dataacq \(background\)
if [ $dataacq == 'mobita' ]; then
  dataAcq/startMobita.sh localhost 2 &
elif [ $dataacq == 'biosemi' ]; then
  dataAcq/startBiosemi.sh &
else
  echo Dont recognise the eeg device type!
fi
dataacqpid=$!
echo dataacqpid=$dataacqpid

# Code to start a procesbuffer
if [ $sigproc -eq 1 ]; then
  echo Starting the default signal processing function \(background\)
  matlab/signalProc/startSigProcBuffer.sh &
  sigprocpid=$!
fi

# code to start the eventviewer
echo Starting the event viewer
dataAcq/startJavaEventViewer.sh
viewerpid=$!
echo viewerpid=$viewerpid

# code to start the stimuli screen
echo Starting the stimuli screen
if [ $stimuli == 'hybrid' ]; then
  matlab/brainfly/ssvep_p300_stimuli.py &
elif [ $stimuli == 'ssvep' ]; then
  matlab/brainfly/ssvep_stimuli.py &
else
  echo Dont recognise the eeg device type!
fi
stimulipid=$!
echo stimulipid=$stimulipid

# code to start brainfly
echo Starting brainfly
matlab/brainfly/runBrainfly.sh 
brainflypid = $!
echo brainflypid=$brainflypid

# Code to kill all started processes
kill $bufferpid
kill $dataacqpid
kill $sigprocpid
kill $viewerpid
kill $stimulipid
kill $brainflypid