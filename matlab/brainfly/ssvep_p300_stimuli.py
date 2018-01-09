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

class Rectangle(pygame.Rect):
    def __init__(self, *args, **kwargs):
        super(Rectangle, self).__init__(*args, **kwargs)  # init Rect base class
        # define additional attributes
        self.colored = True
        self.color = (255,0,0)
        self.flicker_speed = 20 # Hertz
        self.ssvep = False
        
    def draw(self, surface, width=0):
        if self.ssvep:
            self.color = (255, 0,0) # set middle argument to zero for only SSVEP-B
            
        elif self.colored:
            self.color = (255,0,0)
        else:
            self.color = (0,0,0)
        pygame.draw.rect(surface, self.color, self, width)
            
        pygame.draw.rect(surface, self.color, self, width)
        
    def set_color(self):
        if self.colored == True:
            self.colored = False
        else:
            self.colored = True
            
    def set_flicker_speed(self, flicker_speed):
        self.flicker_speed = flicker_speed
        
    def get_flicker_time(self):
        flicker_time = 1000 / self.flicker_speed
        return flicker_time
    
 
    def set_ssvep(self, value):
        self.ssvep = value
    
def main():
    shape_iterator = cycle(range(2))
    pygame.init()
    fpsclock = pygame.time.Clock()
    
    ttp, pause_time, time_passed, last_flick_left, last_flick_right = 0, 0, 0, 0, 0
    last_event = 0
    screen = pygame.display.set_mode((width, height))

    pygame.display.set_caption('SSVEP - P300 Stimulus')
    right_rect = Rectangle(1300,400,200,400)
    left_rect = Rectangle(0,400,200,400)
    run = True
    left_rect.set_flicker_speed(20)
    right_rect.set_flicker_speed(20)
    pos = None
    target = 'left'
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
                process_ssvep_event(left_rect, right_rect, pos, target)
                last_event = 0
               
            if last_flick_left > left_rect.get_flicker_time():
                left_rect.set_color()
                last_flick_left = 0
            if last_flick_right > right_rect.get_flicker_time():
                right_rect.set_color()
                last_flick_right = 0
                
            pygame.display.update()
            time_passed = fpsclock.tick(FPS)
            last_flick_left += time_passed
            last_flick_right += time_passed
            last_event+= time_passed
            ttp += time_passed
            pause_time += time_passed
            if ttp > 240000:
                sendEvent("stimulus.training",  "end")
                pygame.quit()
                sys.exit()
   
            if pause_time > 60000:
                if target == 'left':
                    target = 'right'
                else:
                    target = 'left'
                run = False
                right_rect = Rectangle(1300,400,200,400)
                left_rect = Rectangle(0,400,200,400)
                left_rect.set_flicker_speed(20)
                right_rect.set_flicker_speed(20)
                last_event = 0
                last_flick_left = 0
                last_flick_right = 0
                pause_time = 0
        
            
            


def process_ssvep_event(left_rect, right_rect, pos, target):
    
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
            
