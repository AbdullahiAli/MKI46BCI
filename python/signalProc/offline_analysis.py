import sys,os
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),"../../dataAcq/buffer/python"))
sys.path.append("../signalProc")
import preproc
import bufhelp
import numpy as np
import FieldTrip
from scipy.io import loadmat
import matplotlib.pyplot as plt


plt.style.use('seaborn-notebook')

bufhelp.connect()
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

def preprocess(data, events, classification=False, matlab=False):
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
    data, badch = preproc.badchannelremoval(data)
    data = preproc.detrend(data, dim=0)
    data, events, badtrials = preproc.badtrailremoval(data, events)
    data = preproc.spatialfilter(data)
    
    data = preproc.spectralfilter(data, (1,40), fSample)
    
    return data, events

def analysis(data, events, side, analysis_type):
    '''
    Offline analysis pipeline of Oz and Pz for EEG data
    Parameters
    ----------
    data : a list of datapoints (numpy arrays)
    events : a list of fieldtrip events or a numpy array
    side: Event of interest, can either be 'left' or 'right'
    analysis_type: 
    
    Examples
    --------
    >>> data, events = ftc.getData(0,100)
    >>> data, events = preprocess(data, events)
    >>> Oz, Pz = analysis(data, events, 'left', 'ersp')
    
    '''
    if analysis_type is 'ersp':
        data = preproc.fouriertransform(data,fSample)

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
def spectral_analysis(subject, condition, date):
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
  
    raw_data =  loadmat(subject+ '_' + condition + '_' + date)
    data, events = raw_data['data'], raw_data['devents']
    
    data, events = preprocess(data, events, matlab=True)
    Oz1, Pz1 = analysis(data, events,'target','ersp')
    
    
    data, events = raw_data['data'], raw_data['devents']
    data, events = preprocess(data, events, matlab=True)
    Oz2, Pz2 = analysis(data, events, 'non-target', 'ersp')
    plt.figure(1, figsize=(8,6))
    
    plt.subplot(1,2,1)
    plt.title('target')
    plt.specgram(Oz1, NFFT=256, Fs=fSample)


 
    plt.subplot(1,2,2)
    plt.title('non-target')
    plt.specgram(Oz2, NFFT=256, Fs=fSample)
    plt.show()

def erp_analysis(subject, condition, date):
    """
    offline analysis pipeline
    for ERP's
    
    Parameters
    ----------
    label : class of interest ('left' or 'right')
    subject: which subject file to load
    
    Examples
    --------
    >>> erp_analysis('left', 'right','subject00')
    '''
    """
    
    data =  loadmat(subject+ '_' + condition + '_' + date)
    data, events = data['data'], data['devents']
    data, events = preprocess(data, events, matlab=True)
    data = preproc.spectralfilter(data, (1, 10), fSample)
    
    Oz1, Pz1 = analysis(data, events,'target', 'erp')
    Oz2, Pz2 = analysis(data, events, 'non-target', 'erp')
    
    plt.figure(1, figsize=(10,5))
    Pz1, = plt.plot(Pz1, label='target')
    Pz2, = plt.plot(Pz2, label='non-target')
    plt.legend(handles=[Pz1, Pz2])


subject, condition, date = 'appie', 'hybrid', '1501'
spectral_analysis(subject, condition, date)

