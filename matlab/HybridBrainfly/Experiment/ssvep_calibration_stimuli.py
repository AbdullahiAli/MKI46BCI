import pygame, sys
from itertools import cycle
import os
from time import sleep


bufferpath = "../../dataAcq/buffer/matlab"
sigProcPath = "../signalProc"
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),sigProcPath))

sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)),bufferpath))
import FieldTrip
# Connection options of fieldtrip, hostname and port of the computer running the fieldtrip buffer.
hostname='localhost'
port=1972
width, height = 1820, 1080
FPS = 60

class ScreenState():
    """
    Class that encapsulates
    screen loop variables
    """
    def __init__(self):
        """
        Initialization of main loop parameters
        
        Params:
            fpsclock: keeps track of the time passed in milliseconds
            target: rectangle the subject is currently attending to
            total_time: time passed since start of calibration
            pause_time: time passed since last pause
            last_event: time passed since last stop event
        """
        self.fpsclock = pygame.time.Clock()
        self.target = 'left' # We start with the left rectagnle
        self.total_time, self.pause_time = 0, 0
        self.last_event = 0 # time_passed since last stop event
    
    def tick(self):
        """
        Method that controls the amount of time passed
        """
        time_passed = self.fpsclock.tick(FPS)
        self.last_event+= time_passed
        self.total_time += time_passed
        self.pause_time += time_passed
        return time_passed
    
    def reset(self):
        """
        Resets time variables that control 
        """
        self.pause_time = 0
        self.last_event = 0
    
    def skip_pause(self):
        """
        skip the time waited during pause
        """
        self.fpsclock.tick()

class Rectangle(pygame.Rect):
    def __init__(self, *args, **kwargs):
        super(Rectangle, self).__init__(*args, **kwargs)  # init Rect base class
        # define additional attributes
        self.fill = True # indicates if shape should be filled
        self.color = (255,0,0)  # color of the shape
        self.flicker_speed = 20 # Hertz
        self.event = False
        self.last_flick = 0
        self.colored = True
        
    def draw(self, surface, width=0):
        if self.fill:
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
        self.event = False
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
    
 
    def set_color(self):
        if self.colored == True:
            self.colored = False
        else:
            self.colored = True 

def main():
    """
    Main loop all the initializations happen
    in here
    Params:
    shape_iterator: controls which shape should stop flickering
    pos: position of the shape (0: left, 1: right)
    fpsclock: measures time between ticks
    screen_state: controls the state of the main_loop variables
    
    """
    pygame.init()
    screen_state = ScreenState()
    pos = None # which shape to process
    screen = pygame.display.set_mode((width, height))

    pygame.display.set_caption('SSVEP Calibration Stimulus')
    right_rect = Rectangle(1620,450,200,200)
    left_rect = Rectangle(0,450,200,200)
    run = False
    left_rect.set_flicker_speed(14)
    right_rect.set_flicker_speed(10)
    sendEvent("stimulus.training", "start")
    while True: # display update loop
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                    pygame.quit()
                    sys.exit()
            if event.type == pygame.KEYDOWN:
                run = True
                screen_state.skip_pause()
        if not run:
            left_rect.draw(screen)
            right_rect.draw(screen)
            pygame.display.update()
            
        if run:
            left_rect.draw(screen)
            right_rect.draw(screen)
            
                    
            if screen_state.last_event > 1000:
                process_ssvep_event(left_rect, right_rect, pos)
                screen_state.last_event = 0
         
            
            flicker_controller(left_rect, right_rect)
      
                
            pygame.display.update()
            time_passed = screen_state.tick()
            left_rect.last_flick += time_passed
            right_rect.last_flick += time_passed
            
            if screen_state.total_time > 240000:
                sendEvent("stimulus.training",  "end")
                pygame.quit()
                sys.exit()
   
            if screen_state.pause_time > 15000:
                if screen_state.target == 'left':
                    screen_state.target = 'right'
                else:
                    screen_state.target = 'left'
                run = False
                right_rect.reset()
                left_rect.reset()
                screen_state.reset()        
        
def process_ssvep_event(left_rect, right_rect, pos):
    if pos == 0:
        sendEvent("stimulus.hybrid", "left")
       
    else:
        sendEvent("stimulus.hybrid", "right")
        
def flicker_controller(left_rect, right_rect):
    """
    Method that controls the flickering of the shapes.
    
    Params:
        left_rect: left rectangle
        right_rect: right rectangle
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
            
