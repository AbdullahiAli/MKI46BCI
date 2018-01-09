#!/usr/bin/env python3
import sys,os
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),"../../dataAcq/buffer/python"))
sys.path.append("../signalProc")
import preproc
import bufhelp
import linear
import pickle

bufhelp.connect()

trlen_ms = 700
run = True

print ("Waiting for startPhase.cmd event.")
while run:
    e = bufhelp.waitforevent("startPhase.cmd",1000, True)
    print("Got startPhase event: %s"%e)
   
    if e is not None:
        if e.value == "calibrate":
            print("Calibration phase")
            data, events, stopevents = bufhelp.gatherdata("stimulus.hybrid",trlen_ms,("stimulus.training", "end"), milliseconds=True)
           
            pickle.dump({"events":events,"data":data}, open("subject_data", "wb"))

        elif e.value == "training":
            print("Training classifier")
         
            data = preproc.detrend(data)
            data, badch = preproc.badchannelremoval(data)
            data = preproc.spatialfilter(data)
            data = preproc.spectralfilter(data, (1, 10, 15, 25), bufhelp.fSample)
            data, events, badtrials = preproc.badtrailremoval(data, events)
            mapping = {('stimulus.hybrid', 'left'): -1, ('stimulus.hybrid', 'right'): 1}
            classifier =  linear.fit(data, events, mapping)
            bufhelp.update()
            bufhelp.sendEvent("sigproc.training","done")

        elif e.value =="contfeedback":
            print("Feedback phase")
            while True:
                test_data, test_events, stopevents = bufhelp.gatherdata("stimulus.hybrid",trlen_ms, "stimulus.hybrid", milliseconds=True)


#                if isinstance(stopevents, list):
#                    if any(["stimulus.feedback" in x.type for x in stopevents]):
#                        break
#                else:
#                    if "stimulus.sequence" in stopevents.type:
#                        break

                test_data = preproc.detrend(test_data)
                test_data, badch = preproc.badchannelremoval(test_data)
                test_data = preproc.spatialfilter(test_data)
                test_data = preproc.spectralfilter(test_data, (1, 10, 15, 25), bufhelp.fSample)
                test_data, test_events, badtrials = preproc.badtrailremoval(test_data, test_events)

                predictions = linear.predict(test_data, classifier)
                prediction = str(int(predictions[0]))
                bufhelp.sendEvent("classifier.prediction",prediction)

        elif e.value =="exit":
            run = False

        print("Waiting for startPhase.cmd event.")
