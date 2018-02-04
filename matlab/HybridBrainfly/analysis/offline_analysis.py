import sys,os, glob
bufferpath = "../../../dataAcq/buffer/python"
sigProcPath = "../signalProc"
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),sigProcPath))

sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),bufferpath))
import FieldTrip

import preproc

import numpy as np
from scipy.io import loadmat
import matplotlib.pyplot as plt
from scipy.signal import resample

plt.style.use('seaborn-notebook')


fSample = 250.0 # sampling frequency of MOBITA
def reformat(data, events):
    '''
    Helper function that transforms data from .mat
    files into a format that is easier to process
    in python
    
    Parameters
    ----------
    data : a numpy array containing trials
    events : a numpy array containing the event structs
    
    Returns
    ----------
    data : a list of numpy arrays [nchannels x nepochs]
    events : a list of fieldtrip events 
    ---------
    mat_data =  loadmat('buffer_data')
    data, events = mat_data['data'], mat_data['devents']
    '''
    new_data = []
    new_ev = []
    for sample in data:
        sample = sample[0][0][0:10,:].T # Only use the first 10 channels
        if sample.shape[0] is not 0:
     
            new_data.append(sample) 
    data = new_data
    for event in events:
        e = FieldTrip.Event()
        e.type = event[0][0][0]
        e.value = event[0][1][0]
        new_ev.append(e)
    events = new_ev  

    return data, events

def preprocess(data, events, matlab=False, spectral=True):
    '''
    preprocessing pipeline for EEG data from the
    buffer
    Parameters
    ----------
    data : a list of datapoints (numpy arrays)
    events : a list of fieldtrip events or a numpy array
    spectral: Whether you want to compute a spectrogram (default False)
    matlab: Whether the data comes from a .mat file (default False)
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> data, events = preprocess(data, events)
    >>> data, events = ftc.getData(0,100)
    >>> data, events = preprocess(data, events, spectral=True)
    '''
    if matlab: 
        data, events = reformat(data, events)
    data = preproc.detrend(data, dim=0)

    data, badch = preproc.badchannelremoval(data)
    data = preproc.spatialfilter(data, type='whiten')
    if spectral:
        data = preproc.spectralfilter(data, (1,40), fSample)
   
    data, events, badtrials = preproc.badtrailremoval(data, events)

    return data, events

def analysis(data, events, side, analysis_type):
    '''
    Offline analysis pipeline of Oz and Pz for EEG data
    Parameters
    ----------
    data : a list of datapoints (numpy arrays)
    events : a list of fieldtrip events or a numpy array
    side: Event of interest, can either be 'target'/'non-target'/left'/'right'
    analysis_type: 
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> data, events = preprocess(data, events)
    >>> Oz, Pz = analysis(data, events, 'target', 'ersp')
    
    '''

    dims = data[0].shape[0]

    Oz = np.zeros((dims,1))
    Pz = np.zeros((dims,1))
    count = 0
    
    for a, event in zip(data, events):
        if event.value == side: 
            a1, a2 = np.reshape(a[:,8],(dims,1)), np.reshape(a[:,3],(dims,1))
            if analysis_type is 'ersp':
                Oz = np.add(Oz,a1)
                Pz = np.add(Pz,a2)
                count+= 1
            elif analysis_type is 'erp':
                Oz = np.add(Oz, a1)
                Pz = np.add(Pz, a2)
                count += 1

    return Oz/count, Pz/count

# spectral analysis
def spectral_analysis(data, events):
    """
    offline analysis pipeline
    for spectrum
    
    Parameters
    ----------
    subject: subject code
    condition: experimental condition tested
    date: date of the collected data (DAYMONTH)
    
    Examples
    --------
    >>> spectral_analysis('subject00', 'hybrid','1501')
    '''
    """
    data, events = preprocess(data, events, matlab=True)
    Oz1, Pz1 = analysis(data, events,'target','ersp')
    Oz2, Pz2 = analysis(data, events, 'non-target', 'ersp')
    
    plt.figure(1, figsize=(10,8))

    
    plt.suptitle("Spectogram of " + condition + " Condition")
    plt.subplot(1,2,1)
    plt.title('target')
    plt.xlabel('time (sec)')
    plt.ylabel('frequency (Hz)')
    plt.specgram(Oz1, NFFT=256, Fs=fSample)


    plt.subplot(1,2,2)
    plt.title('non-target')
    plt.xlabel('time (sec)')
    plt.ylabel('frequency (Hz)')
    plt.specgram(Oz2, NFFT=256, Fs=fSample)
    plt.show()

def erp_analysis(data, events):
    """
    offline analysis pipeline
    for ERP's
    
    Parameters
    ----------
    data : class of interest ('left' or 'right')
    subject: which subject file to load
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> erp_analysis(data, events)
    '''
    """
    
    data, events = preprocess(data, events, matlab=True, spectral=False)
    Oz1, Pz1 = analysis(data, events,'target', 'erp')
    Oz2, Pz2 = analysis(data, events, 'non-target', 'erp')
    Pz1, Pz2 = resample(Pz1, 700), resample(Pz2, 700)

    plt.figure(1, figsize=(10,5))
    Pz1, = plt.plot(Pz1, label='target')
    Pz2, = plt.plot(Pz2, label='non-target')
    plt.legend(handles=[Pz1, Pz2])


def concat_data(condition):
    """
    pools data of each subject for a specific condition
    
    Parameters
    ----------
    condition: condition for which you want to pool the data
    
    Examples
    --------
    >>> data, events = concat_data('hybrid')
    >>> erp_analysis(data, events)
    '''
    """
    os.chdir("data/")
    file_names = [name for name in glob.glob('*'+str(condition)+ '*')]
    data = loadmat(file_names.pop(0))
    data, events = data['data'], data['devents']
    for name in file_names:
        data_struct = loadmat(name)
        new_data, new_events = data_struct['data'], data_struct['devents']
        data, events = np.concatenate((data, new_data), axis=0), \
        np.concatenate((events, new_events), axis=0)
    return data, events


print("type in the condition for which you want a spectral and erp analysis (hybrid, ssvepb, ssvep)")
condition = input()
data, events = concat_data(condition)
spectral_analysis(data, events)

erp_analysis(data, events)