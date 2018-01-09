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
            self.color = (255, 0 ,0)
        elif self.colored:
            self.color = (255,0,0)
        else:
            self.color = (0,0,0)
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
    pygame.init()
    shape_iterator = cycle(range(2))
    pos = None
    run = True
    fpsclock = pygame.time.Clock()
    time_passed, last_flick_left, last_flick_right,  pause_time = 0, 0, 0, 0
    screen = pygame.display.set_mode((width, height))
    last_event = 0
   
    pygame.display.set_caption('SSVEP Stimulus')
    right_rect = Rectangle(1300,400,200,400)
    left_rect = Rectangle(0,400,200,400)
    left_rect.set_flicker_speed(14)
    right_rect.set_flicker_speed(10)
    ttp = 0
    choice = shape_iterator.next()
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
         
                    
        if run:
            left_rect.draw(screen)
            right_rect.draw(screen)
            
            if last_event > 500 and pos != None:            
                if pos == 0:
                    left_rect.set_ssvep(False)
                else:
                    right_rect.set_ssvep(False)
                    
            if last_event > 1000:
                process_ssvep_event(left_rect, right_rect, choice)
                last_event = 0
               
                
            if last_flick_left > left_rect.get_flicker_time():
                left_rect.set_color()
                last_flick_left = 0
                
            if last_flick_right > right_rect.get_flicker_time():
                right_rect.set_color()
                last_flick_right = 0
            

            time_passed = fpsclock.tick(FPS)
            last_flick_left += time_passed
            last_flick_right += time_passed
            last_event += time_passed
            pause_time += time_passed
            ttp += time_passed
            
        if ttp > 240000:
            sendEvent("stimulus.training",  "end")
            pygame.quit()
            sys.exit()
            
        if pause_time > 15000:    
            run = False
            choice = shape_iterator.next()
            right_rect = Rectangle(1300,400,200,400)
            left_rect = Rectangle(0,400,200,400)
            left_rect.set_flicker_speed(14)
            right_rect.set_flicker_speed(10)
            last_event = 0
            last_flick_left = 0
            last_flick_right = 0
            pause_time = 0
            
        pygame.display.update()
        
        
def process_ssvep_event(left_rect, right_rect, pos):
    if pos == 0:
        sendEvent("stimulus.hybrid", "left")
       
    else:
        sendEvent("stimulus.hybrid", "right")
        

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
            
