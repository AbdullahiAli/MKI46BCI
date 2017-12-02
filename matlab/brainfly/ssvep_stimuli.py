import pygame, sys


width, height = 1500, 1000
FPS = 60
class Rectangle(pygame.Rect):
    def __init__(self, *args, **kwargs):
        super(Rectangle, self).__init__(*args, **kwargs)  # init Rect base class
        # define additional attributes
        self.colored = True
        self.color = (255,0,0)
        self.flicker_speed = 20 # Hertz

    def draw(self, surface, width=0):
        if self.colored:
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
    
def main():
    pygame.init()
    fpsclock = pygame.time.Clock()
    time_passed, last_flick_left, last_flick_right = 0, 0, 0
    screen = pygame.display.set_mode((width, height))
   
    pygame.display.set_caption('SSVEP Stimulus')
    right_rect = Rectangle(1300,400,200,400)
    left_rect = Rectangle(0,400,200,400)
    left_rect.set_flicker_speed(15)
    right_rect.set_flicker_speed(20)
    while True: # display update loop
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                    pygame.quit()
                    sys.exit()
        left_rect.draw(screen)
        right_rect.draw(screen)
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
        

main()
            
