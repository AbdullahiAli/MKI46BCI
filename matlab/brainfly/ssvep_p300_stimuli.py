import pygame, sys
from itertools import cycle
from time import sleep
import os

bufferpath = "../../dataAcq/buffer/python"
sigProcPath = "../signalProc"
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),sigProcPath))

sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),bufferpath))
import FieldTrip
# Connection options of fieldtrip, hostname and port of the computer running the fieldtrip buffer.
hostname='localhost'
port=1972

width, height = 1500, 1000
FPS = 60

class ScreenState():
    """
    Class that encapsulates
    screen loop variables
    """
    def __init__(self):
        self.fpsclock = pygame.time.Clock()
        self.pos = None # which shape to process
        self.shape_iterator = cycle(range(2))
        self.target = 'left'
        self.total_time, self.pause_time = 0, 0
        self.last_event = 0
    
    def tick(self):
        """
        Needs doc
        """
        time_passed = self.fpsclock.tick(FPS)
        self.last_event+= time_passed
        self.total_time += time_passed
        self.pause_time += time_passed
    
    def reset(self):
        """
        Needs doc
        """
        self.pause_time = 0
        self.last_event = 0

class Rectangle(pygame.Rect):
    def __init__(self, *args, **kwargs):
        super(Rectangle, self).__init__(*args, **kwargs)  # init Rect base class
        # define additional attributes
        self.fill = True # indicates if shape should be filled
        self.color = (255,0,0)  # color of the shape
        self.flicker_speed = 20 # Hertz
        self.ssvep = False
        self.last_flick = 0
        
    def draw(self, surface, width=0):
        if self.ssvep:
            self.color = (255, 0,0) # set middle argument to zero for only SSVEP-B
            
        elif self.fill:
            self.color = (255,0,0)
        else:
            self.color = (0,0,0)
        pygame.draw.rect(surface, self.color, self, width)
          
    def reset(self):
        """
        Method to reset shape 
        to original state
        """
        self.fill = True # indicates if shape should be filled
        self.color = (255,0,0)  # color of the shape
        self.ssvep = False
        self.last_flick = 0
        
    def set_fill(self):
        """
        Method that controls the color of the shape
        """
        if self.fill is True:
            self.fill = False
        else:
            self.fill = True
            
    def set_flicker_speed(self, flicker_speed):
        """
        Setter for the flicker_speed in Hertz of the shape
        Params: 
            flicker_speed: flicker speed of shape in Hz
        """
        self.flicker_speed = flicker_speed
        
    def get_flicker_time(self):
        flicker_time = 1000 / self.flicker_speed
        return flicker_time
    
 
    def set_ssvep(self, value):
        """
        method that controls whether the shape
        flickers or not
        
        params:
            value: boolean that indicates if shape should flicker
        """
        self.ssvep = value
    
def main():
    """
    Main loop all the initializations happen
    in here
    Params:
    shape_iterator: controls which shape should stop flickering
    fpsclock: measures time between ticks
    time_passed: time passed after last tick
    ttp: total time that has passed
    
    """
    pygame.init()
    #screen_state = ScreenState()
    fpsclock = pygame.time.Clock()
    pos = None # which shape to process
    shape_iterator = cycle(range(2))
    target = 'left'
    total_time, pause_time, time_passed = 0, 0, 0
    last_event = 0
    screen = pygame.display.set_mode((width, height))

    pygame.display.set_caption('SSVEP - P300 Stimulus')
    right_rect = Rectangle(1300,400,200,400)
    left_rect = Rectangle(0,400,200,400)
    run = False
    left_rect.set_flicker_speed(20)
    right_rect.set_flicker_speed(20)
    sendEvent("stimulus.training", "start")
    while True: # display update loop
        
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                    pygame.quit()
                    sys.exit()
            if event.type == pygame.KEYDOWN:
                run = True
                fpsclock.tick(FPS)
                
        if not run:
            left_rect.draw(screen)
            right_rect.draw(screen)
            pygame.display.update()
            
            
        if run:
            left_rect.draw(screen)
            right_rect.draw(screen)
            
            # if last event lasted more than 500 ms
            if last_event > 500 and pos != None:  
                if pos == 0:
                    left_rect.set_ssvep(False)
                else:
                    right_rect.set_ssvep(False)
                    
            # if last event was more than 2 sec ago     
            if last_event > 2000:
                pos = shape_iterator.next()
                process_event(left_rect, right_rect, pos, target)
                last_event = 0
            
            flicker_controller(left_rect, right_rect)
      
                
            pygame.display.update()
            time_passed = fpsclock.tick(FPS)
            left_rect.last_flick += time_passed
            right_rect.last_flick += time_passed
            last_event+= time_passed
            total_time += time_passed
            pause_time += time_passed
            
            if total_time > 240000:
                sendEvent("stimulus.training",  "end")
                pygame.quit()
                sys.exit()
   
            if pause_time > 60000:
                if target == 'left':
                    target = 'right'
                else:
                    target = 'left'
                run = False
                right_rect.reset()
                left_rect.reset()
                last_event = 0
                pause_time = 0
        
def process_event(left_rect, right_rect, pos, target):
    """
    needs doc
    """
    if pos == 0:
        if target == 'left':
            sendEvent("stimulus.hybrid", "target")
        else:
            sendEvent("stimulus.hybrid", "non-target")
        left_rect.set_ssvep(True)
        right_rect.set_ssvep(False)
    else:
        if target == 'right':
            sendEvent("stimulus.hybrid", "target")
        else:
            sendEvent("stimulus.hybrid", "non-target")
        right_rect.set_ssvep(True)
        left_rect.set_ssvep(False)

def flicker_controller(left_rect, right_rect):
    """
    Needs doc
    """
    if left_rect.last_flick > left_rect.get_flicker_time():
        left_rect.set_fill()
        left_rect.last_flick = 0
    
    if right_rect.last_flick > right_rect.get_flicker_time():
        right_rect.set_fill()
        right_rect.last_flick = 0
        
# Buffer interfacing functions 
def sendEvent(event_type, event_value=1, offset=0):
    e = FieldTrip.Event()
    e.type = event_type
    e.value = event_value
    if offset > 0:
        sample, bla = ftc.poll() #TODO: replace this with a clock-sync based version
        e.sample = sample + offset + 1
    ftc.putEvents(e)
        
#Connecting to Buffer
timeout=5000
ftc = FieldTrip.Client()
# Wait until the buffer connects correctly and returns a valid header
hdr = None;
while hdr is None :
    print(('Trying to connect to buffer on %s:%i ...'%(hostname,port)))
    try:
        ftc.connect(hostname, port)
        print('\nConnected - trying to read header...')
        hdr = ftc.getHeader()
    except IOError:
        pass

    if hdr is None:
        print('Invalid Header... waiting')
        sleep(1)
    else:
        print(hdr)
        print((hdr.labels))
  
fSample = hdr.fSample
main()
            
