################# Dr. Mario ###################
#
# Dr. Mario Game in MIPS Assembly
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       2
# - Unit height in pixels:      2
# - Display width in pixels:    64
# - Display height in pixels:   64
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
grid:
  .space 1408 # bottle space 16 * 22 * 4 bytes  1 byte per grid spot storing color index
  # 16 columns, 20 rows (+1 additional row for spawn row) , each grid spot stores one of the values from the following: 
  # - Color array [0, 1, 2, 3]
  # 0 is Red
  # 1 is Yellow
  # 2 is Blue
  # 3 is Black
  # 4 is White
 

viruses: # the viruses array
  .space 144    # Store up to 12 viruses (x, y, color) -> 12 * 3 * 4 bytes
                # Every 4 bytes stores x, y, color (different shade to differentiate)
                # next virus is 12 bytes away
    
##############################################################################
# Immutable Data
##############################################################################

# The address of the bitmap display. 
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. 
ADDR_KBRD:
    .word 0xffff0000

COLORS: # Red, Yellow and Blue
    .word 0xFF0000, 0xFFFF00, 0x0000FF

INITIAL_CAPSULE_LOCATION:
    .data 800
COLOR_WHITE: 
    .word 0xFFFFFF

VIRUS_COLORS:
    .word 0xAA0000, 0xAAAA00, 0x0000AA

##############################################################################
# Mutable Data
##############################################################################
# ASCII values for characters:                                    
# 'q' = 113 (quit)
# 'a' = 97 (left)
# 'd' = 100 (right)
# 's' = 115 (down)
# 'w' = 119 (toggle orientation)
##############################################################################

capsule:
  .word 0, 0 # X & Y coordinate values of capsule n
  .word 0 # Orientation of capsule (0 to 3)
  .word 0, 0 # Color indices for the two pills (0 to 2 decides color)
  .word 0, # Status (0 = inactive, 1 = active)

# Theme SONG
sound_timer: #NOT USED
    .word 0    # Counter for timing between notes
sound_step:
    .word 0    # Current position in the melody sequence

# Fever Theme Notes - Guitar, Organ
fever_guitar:
    .word 104, 88, 77, 100, 101, 108, 92, 78, 73, 75, 63, 74, 65, 67, 66, 67, 64, 63, 62, 64, 75, 71, 77, 78, 65, 64, 67, 62, 68, 68, 60, 82, 61, 63, 69, 82, 69, 67, 84, 62, 70, 64, 83, 63, 71, 62,
    81, 65, 62, 60, 63, 80, 62, 63, 78, 63, 61, 78, 61, 62, 81, 60, 66, 79, 62, 69, 64, 80, 62, 69, 84, 68, 84, 64, 71, 81, 69, 61, 82, 60, 69, 61, 80, 64, 62, 79, 62, 62, 79, 65, 61, 62, 68,
    61, 69, 97, 102, 91, 92, 108, 75, 71, 64, 67, 66, 70, 72, 62, 68, 63, 67, 99, 62, 67, 60, 82, 64, 65, 65, 85, 65, 70, 68, 82, 61, 71, 65, 84, 62, 65, 80, 66, 60, 79, 64, 61, 80, 62, 77, 64

fever_organ:
    .word 52, 53, 56, 51, 56, 52, 62, 59, 58, 55, 62, 58, 60, 59, 61, 58, 58, 52, 60, 58, 59, 48, 52, 59, 55, 54, 58, 56, 52, 62, 58, 52, 60, 51, 60, 61, 61, 55, 57, 58, 59, 54, 56, 56, 62, 58, 61, 58,
    59, 62, 59, 60, 52, 61, 51, 58, 58, 52, 53, 56, 51, 53, 56, 51, 54, 53, 50, 60, 59, 61, 59, 62, 57, 61, 57, 52

fever_guitar_count:
    .word 138  # Number of guitar notes

fever_organ_count:
    .word 74  # Number of organ notes

##############################################################################
# Code
##############################################################################

    .text 

    # Run the game.
main:
    # Initialize the game
    li $s6, 0 # gravity frame counter 
    li $s7, 25 # gravity threshhold

    jal init_grid
    
    jal draw_bottle

    jal draw_dr_mario

    jal draw_virus_hardcode
    
    jal generate_viruses
    
    jal initialise_capsule

    jal draw_capsule

    jal sleep
    
    
game_loop:
    # 1a. Check if key has been pressed
    
    jal play_theme_song
    
    jal check_keyboard_input
    
    jal check_game_over_condition

    


    # beq $s3, 0, idle # no key was pressed, normal gravity
    
    # $s3 now stores the keyboard value, quit check done already in check_keyboard_input
    li $v0, 1
    move $a0, $s3
    syscall # debugger, prints to console keyboard value
    
    
    # 1b. Check which key has been pressed, erase and redraw
    
    beq $s3, 97, redraw_left

    beq $s3, 115, redraw_down

    beq $s3, 100, redraw_right

    beq $s3, 119, rotate_capsule

    beq $s3, 114, reset_game
    
    beq $s3, 112, pause_game

    beq $s3, 0, gravity # automatically drops capsule if no key is pressed
    
    # 2. & 3. Checking for collisions occurs when redraw_down is called (since gravity calls it)
    
    # 4. Sleep
    jal sleep
    # 5. Go back to Step 1
    
    j game_loop
    


# CHECK IF THE FIRST ROW OF GRID IS POPULATED, THEN TRIGGER THE GAME OVER CONDITION
check_game_over_condition:

  addi $sp, $sp, -20
  sw $t0, 0($sp)
  sw $t1, 4($sp)
  sw $t2, 8($sp)
  sw $t3, 12($sp)
  sw $t4, 16($sp)

  la $t0, grid # Load the address of the grid 
  li $t1, 3
  li $t2, 3
  li $t3, 3
  li $t4, 3
  
  
  lw $t1, 88($t0) #Check color of (7,10) 
  lw $t2, 92($t0) #Check color of (8,10) 
  lw $t3, 96($t0) #Check color of (9,10) 
  lw $t4, 100($t0) #Check color of (10,10) 

  bne $t1, 3, finish_game
  bne $t2, 3, finish_game
  bne $t3, 3, finish_game
  bne $t4, 3, finish_game

 
  lw $t0, 0($sp)
  lw $t1, 4($sp)
  lw $t2, 8($sp)
  lw $t3, 12($sp)
  lw $t4, 16($sp)
  addi $sp, $sp, 20
  

  jr $ra

#Initialise the grid struct such that very value is populated with color 3 (black)
init_grid:
    addi $sp, $sp, -12
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
  
    li   $t0, 3          # value to store (3)
    la   $t1, grid       # base address of grid
    li   $t2, 352        # loop counter (number of words)

init_grid_loop:
    sw   $t0, 0($t1)     # store 3 at grid[i]
    addi $t1, $t1, 4     # move to next word (4 bytes ahead)
    addi $t2, $t2, -1    # decrement counter
    bgtz $t2, init_grid_loop  # loop if t2 > 0


    #Populate the first row to make it full (prevents reading over the white lines)

    li $t0, 4            # value to store
    la $t1, grid         # base address of grid

    sw $t0, 0($t1)       #store 4 at (1,9)
    sw $t0, 4($t1)
    sw $t0, 8($t1)
    sw $t0, 12($t1)
    sw $t0, 16($t1)
    sw $t0, 20($t1)

    sw $t0, 40($t1)
    sw $t0, 44($t1)
    sw $t0, 48($t1)
    sw $t0, 52($t1)
    sw $t0, 56($t1)
    sw $t0, 60($t1)

    lw $t0, 0($sp)
    lw $t1, 4($sp)
    lw $t2, 8($sp)
    addi $sp, $sp, 12

    jr $ra

reset_game:
  jal reset_viruses #Resets all the viruses
  # NEED TO CLEAR ALL CAPSULES WHEN WE IMPLEMENT IT.
  jal clear_board 
  j main

reset_viruses:
    la $t0, viruses         # load address of viruses
    li $t1, 36              # number of fields (36 words)
    li $t2, 0              # value to store (zero)

clear_virus_loop:
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $t2, 0($t0)         # store 0
    addiu $t0, $t0, 4      # move to next word
    addiu $t1, $t1, -1     # decrement counter
    bgtz $t1, clear_virus_loop
    jal end_motion
    lw $t2, 4($sp)
    lw $ra, 0($sp)
    addi, $sp, $sp, 8
    jr $ra


clear_board:

    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $s0, 4($sp)

    lw $s0, ADDR_DSPL # load the value of s0
    
    #clearing first line of bottle
    addi $a0, $zero, 1 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0x000000 #set the color of the line
    jal line_draw_vertical #draw a vertical black line of length 20 starting from $a0,$a1

    #clearing first line of bottle
    addi $a0, $zero, 2 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0x000000 #set the color of the line
    jal line_draw_vertical #draw a vertical black line of length 20 starting from $a0,$a1
    
    addi $a0, $zero, 3 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the linedwa
    addi $a3, $zero, 0x000000 #set the color of the line
    jal line_draw_vertical #draw a vertical black line of length 20 starting from $a0,$a1

    addi $a0, $zero, 4 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0x000000 #set the color of the line
    jal line_draw_vertical #draw a vertical black line of length 20 starting from $a0,$a1

    addi $a0, $zero, 5 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0x000000 #set the color of the line
    jal line_draw_vertical #draw a vertical black line of length 20 starting from $a0,$a1

    addi $a0, $zero, 6 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0x000000 #set the color of the line
    jal line_draw_vertical #draw a vertical black line of length 20 starting from $a0,$a1

    addi $a0, $zero, 7 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0x000000 #set the color of the line
    jal line_draw_vertical #draw a vertical black line of length 20 starting from $a0,$a1

    addi $a0, $zero, 8 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0x000000 #set the color of the line
    jal line_draw_vertical #draw a vertical black line of length 20 starting from $a0,$a1

    addi $a0, $zero, 9 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0x000000 #set the color of the line
    jal line_draw_vertical #draw a vertical black line of length 20 starting from $a0,$a1

    addi $a0, $zero, 10 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0x000000 #set the color of the line
    jal line_draw_vertical #draw a vertical black line of length 20 starting from $a0,$a1

    addi $a0, $zero, 11 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0x000000 #set the color of the line
    jal line_draw_vertical #draw a vertical black line of length 20 starting from $a0,$a1

    addi $a0, $zero, 12 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0x000000 #set the color of the line
    jal line_draw_vertical #draw a vertical black line of length 20 starting from $a0,$a1

    addi $a0, $zero, 13 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0x000000 #set the color of the line
    jal line_draw_vertical #draw a vertical black line of length 20 starting from $a0,$a1

    addi $a0, $zero, 14 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0x000000 #set the color of the line
    jal line_draw_vertical #draw a vertical black line of length 20 starting from $a0,$a1

    addi $a0, $zero, 15 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0x000000 #set the color of the line
    jal line_draw_vertical #draw a vertical black line of length 20 starting from $a0,$a1

    addi $a0, $zero, 16 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0x000000 #set the color of the line
    jal line_draw_vertical #draw a vertical black line of length 20 starting from $a0,$a1

    lw $ra, 0($sp)
    lw $s0, 4($sp)

    addi $sp, $sp, 8

    jr $ra
 
gravity:

   addi $s6, $s6, 1 # increment frame gravity_frame_counter
   blt $s6, $s7, draw_screen # draws screen until gravity takes effect
   beq $s6, $s7, increase_speed

   # now gravity takes place $s5 = $s7 (frame counter = threshhold)
   jal clear_capsule # erases the capsule to drop it due to gravity
   jal redraw_down # moves down the capsule
   li $s6, 0 # resetting the frame counter
    
   j draw_screen

increase_speed:
  
  subi $s7, $s7, 1 # reduce threshhold
  jal draw_capsule # updates capsule
  li $v0, 32
  li $a0, 35
  syscall
  # jumps back to game
  j game_loop
  
draw_screen:
  
jal draw_capsule # updates capsule

# sleeps for 30 milliseconds
li $v0, 32
li $a0, 35 # adjust for speed
syscall
# jumps back to game
j game_loop

draw_bottle:
  addi $sp, $sp, -4 # emptying the stakc pointer
  sw $ra, 0($sp) # storing the return address of the call from the main function
  lw $s0, ADDR_DSPL # load the value of s0
  lw $t1, COLOR_WHITE # $t1 = white
  #drawing left bottle roof
  addi $a0, $zero, 0 # set the X coordinate for this line
  addi $a1, $zero, 9 # set the Y coordinate for this line
  addi $a2, $zero, 7, #set the length of the line
  addi $a3, $zero, 0x00ffffff #set the color of the line
  jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1
  
  #drawing right bottle roof
  addi $a0, $zero, 11 # set the X coordinate for this line
  addi $a1, $zero, 9 # set the Y coordinate for this line
  addi $a2, $zero, 7, #set the length of the line
  addi $a3, $zero, 0x00ffffff #set the color of the line
  jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1
  
  #drawing bottom of capsule
  addi $a0, $zero, 0 # set the X coordinate for this line
  addi $a1, $zero, 31 # set the Y coordinate for this line
  addi $a2, $zero, 18 #set the length of the line
  addi $a3, $zero, 0x00ffffff #set the color of the line
  jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1
  
  #drawing left wall
  addi $a0, $zero, 0 # set the X coordinate for this line
  addi $a1, $zero, 9 # set the Y coordinate for this line
  addi $a2, $zero, 22, #set the length of the line
  addi $a3, $zero, 0x00ffffff #set the color of the line
  jal line_draw_vertical #draw a VERTICAL line of length $a2 at $a0, $a1
  
  #drawing right wall
  addi $a0, $zero, 17 # set the X coordinate for this line
  addi $a1, $zero, 9 # set the Y coordinate for this line
  addi $a2, $zero, 22, #set the length of the line
  addi $a3, $zero, 0x00ffffff #set the color of the line
  jal line_draw_vertical #draw a VERTICAL line of length $a2 at $a0,$a1
  
  #drawing left neck
  addi $a0, $zero, 6 # set the X coordinate for this line
  addi $a1, $zero, 6 # set the Y coordinate for this line
  addi $a2, $zero, 3, #set the length of the line
  addi $a3, $zero, 0x00ffffff #set the color of the line
  jal line_draw_vertical #draw a VERTICAL line of length $a2 at $a0,$a1
  
  #drawing right neck
  addi $a0, $zero, 11 # set the X coordinate for this line
  addi $a1, $zero, 6 # set the Y coordinate for this line
  addi $a2, $zero, 3, #set the length of the line
  addi $a3, $zero, 0x00ffffff #set the color of the line
  jal line_draw_vertical #draw a VERTICAL line of length $a2 at $a0,$a1

  lw $ra, 0($sp) # restoring the call from main
  addi $sp, $sp, 4
  jr $ra




# The function that draws a horizontal line
# Input parameters:
# - $a0: X coordinate of the top left corner of the line
# - #a1: Y coordinate of the top left corner of the line
# - $a2: Length of the line
# - $a3: Color of the line 
line_draw_horizontal:
  
  add $t5, $zero, $zero       # initialize the loop variable $t5 to zero
  sll $a0, $a0, 2             # calculate the horizontal offset 
  add $t7, $s0, $a0           # add the horizontal offset to $s0
  sll $a1, $a1, 7             # calculate the vertical offset 
  add $t7, $t7, $a1           # add the vertical offset to $t7

pixel_draw_horizontal:
    sw $a3, 0($t7) # paint the current location with the color of $a3
    addi $t5, $t5, 1 #increment loop variable
    add $t7, $t7, 4 #move to next pixel on the right
    beq $t5, $a2, pixel_draw_horizontal_end #if loop variable equals length of line, go to stop condition
    j pixel_draw_horizontal #jump to top of loop
  pixel_draw_horizontal_end:
    
line_draw_horizontal_end:
  jr $ra #return to calling program
    


# The function that draws a vertical line
# Input parameters:
# - $a0: X coordinate of the top left corner of the line
# - #a1: Y coordinate of the top left corner of the line
# - $a2: Length of the line
# - $a3: Color of the line 
line_draw_vertical:
  add $t5, $zero, $zero       # initialize the loop variable $t5 to zero
  sll $a0, $a0, 2             # calculate the horizontal offset 
  add $t7, $s0, $a0           # add the horizontal offset to $s0
  sll $a1, $a1, 7             # calculate the vertical offset 
  add $t7, $t7, $a1           # add the vertical offset to $t7

  pixel_draw_vertical:
    sw $a3, 0($t7) # paint the current location with the color of $a3
    addi $t5, $t5, 1 #increment loop variable
    add $t7, $t7, 128 #move to next pixel below
    beq $t5, $a2, pixel_draw_vertical_end #if loop variable equals length of line, go to stop condition
    j pixel_draw_vertical #jump to top of loop
  pixel_draw_vertical_end:
line_draw_vertical_end:
  jr $ra #return to calling program


####################################################################################
# Sound effects
####################################################################################

play_move_sound:

    #PUSH TO SP

    addi $sp, $sp, -20
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    sw $a3, 12($sp)
    sw $v0, 16($sp)
    
    li $a0, 100    # Pitch (adjust as needed)
    li $a1, 50     # Duration (adjust as needed)
    li $a2, 2      # Instrument (e.g., triangle wave)
    li $a3, 50     # Volume
    li $v0, 31     # Syscall for sound
    syscall

    
    lw $a0, 0($sp)
    lw $a1, 4($sp)
    lw $a2, 8($sp)
    lw $a3, 12($sp)
    lw $v0, 16($sp)
    addi $sp, $sp, 20
    
    jr $ra


play_rotation_sound:

    addi $sp, $sp, -20
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    sw $a3, 12($sp)
    sw $v0, 16($sp)

    li $a0, 100    # Pitch (adjust as needed)
    li $a1, 50     # Duration (adjust as needed)
    li $a2, 1      # Instrument (e.g., triangle wave)
    li $a3, 50     # Volume
    li $v0, 31     # Syscall for sound
    syscall

    lw $a0, 0($sp)
    lw $a1, 4($sp)
    lw $a2, 8($sp)
    lw $a3, 12($sp)
    lw $v0, 16($sp)
    addi $sp, $sp, 20
    
    jr $ra

####################################################################################
# Capsule logic
####################################################################################

initialise_capsule: # initialises an active capsule at the bottleneck

  addi $sp, $sp, -4
  sw $ra, 0($sp)
  

  # Set the capsule to active
  la $t0, capsule
  li $t1, 1
  sw $t1, 20($t0)  # Store status (1 = active) at offset 20
  li $t1, 8 
  sw $t1, 0($t0)  # Store x = 8 at offset 0
  li $t1, 9
  sw $t1, 4($t0)  # Store y = 9 at offset 4
  li $t1, 0 
  sw $t1, 8($t0)  # Store orientation = 0 at offset 8
  li $t1, 0 
  sw $t1, 12($t0)  # Store color = 0 for pill 1 at offset 12
  li $t1, 0 
  sw $t1, 16($t0)  # Store color = 0 for pill 2 at offset 16
  
  
  
  # Generate and store random colors in the correct location of the capsule struct
  jal generate_random_num
  sw $a0, 12($t0)

  jal generate_random_num   
  sw $a0, 16($t0)          

  lw $ra, 0($sp)
  addi, $sp, $sp, 4
  jr $ra

generate_random_num: #generate a random number from 0 to 2. returns value in $a0
  li $v0, 42
  li $a0, 0
  li $a1, 3
  syscall
  jr $ra

draw_capsule:

  
  la $t0, capsule
  lw $t1, 0($t0)   # x coordinate
  lw $t2, 4($t0)   # y coordinate
  lw $t3, 8($t0)   # orientation of the capsule
  lw $t4, 12($t0)  # first pill color index in $t4
  lw $t5, 16($t0)  # second pill color index in $t5

    
  lw $t9, ADDR_DSPL

  addi $sp, $sp, -4 # storing orientation on the stack as the $t3 register will be overwritten
  sw $t3, 0($sp)
  
  la $t7, COLORS
  sll $t4, $t4, 2     # byte offset of color addres
  add $t8, $t7, $t4  # $t8 has address of the color
  lw $t7, 0($t8)      # Load actual color value into $t7

  #check for orientation then draw based on orientation ()
  # Calculate memory address for first half of the capsule
  sll $t3, $t2, 7  # vertical offset in $t3
  add $t9, $t3, $t9   # Add vertical offset to base display address
  sll $t3, $t1, 2     # horizontal offset
  add $t9, $t9, $t3   # Final address for second half of the pill

  sw $t7, 0($t9)
  
  #DRAW SECOND HALF WITH ORIENTATION 0 - 3

  lw $t9, ADDR_DSPL # reset the base address display
  la $t7, COLORS # reset colors array index in $t7 to the start
  add $t8, $t7, $t5 # storing second pill color index in $t8
  sll $t8, $t5, 2 # storing the byte offset (4 * index)
  add $t7, $t7, $t8 # $t7 stores address of the color
  lw $t7, 0($t7) # $t7 stores value of color

  lw $t3, 0($sp) # restore orientation and draw based on the value
  addi $sp, $sp, 4
  
  beq $t3, 0, draw_orientation0
  beq $t3, 1, draw_orientation1
  beq $t3, 2, draw_orientation2
  beq $t3, 3, draw_orientation3
  
 
  
# default horizontal orientation
draw_orientation0:
  sll $t3, $t2, 7    # vertical offset in $t3
  add $t9, $t3, $t9   # Add vertical offset to base display address
  sll $t3, $t1, 2     # horizontal offset
  addi $t3, $t3, 4   # moving to the next pixel
  add $t9, $t9, $t3   # Final address for second half of the pill
  
  sw $t7, 0($t9)

  jr $ra

# vertical orientation
draw_orientation1:
  
  sll $t3, $t2, 7    # vertical offset in $t3
  add $t9, $t3, $t9   # Add vertical offset to base display address
  sll $t3, $t1, 2     # horizontal offset
  addi $t3, $t3, 128   # moving one row down to draw second half below
  add $t9, $t9, $t3   # Final address for second half of the pill
  
  sw $t7, 0($t9)

  jr $ra
  
# reverse horizontal orientation
draw_orientation2:
  
  sll $t3, $t2, 7    # vertical offset in $t3
  add $t9, $t3, $t9   # Add vertical offset to base display address
  sll $t3, $t1, 2     # horizontal offset
  addi $t3, $t3, -4   # moving one column left to draw second half to the left
  add $t9, $t9, $t3   # Final address for second half of the pill
  
  sw $t7, 0($t9)

  jr $ra
 
# reverse vertical orientation
draw_orientation3:
  
  sll $t3, $t2, 7    # vertical offset in $t3
  add $t9, $t3, $t9   # Add vertical offset to base display address
  sll $t3, $t1, 2     # horizontal offset
  addi $t3, $t3, -128   # moving one row above to draw second half above
  add $t9, $t9, $t3   # Final address for second half of the pill
  
  sw $t7, 0($t9)

  jr $ra
  
####################################################################################
# VIRUS CREATION
####################################################################################

# Returns the random number in $t7
random_num:
  # Generate a random number
  li $a0, 0        
  move $a1, $t9        # Upper bound (exclusive) - to get numbers 0-2
  li $v0, 42       # System call for random int range
  syscall
  
  # $a0 now contains a random number between 0 and 2
  move $t7, $a0    # Store the random value in $t7
  
  jr $ra


generate_viruses: #generate a random number of viruses
    addi $sp, $sp, -4
    sw $ra, 0($sp) #Save the return address in stack pointer
    li $t6, 0 #Set $t6 to zero. $t6 will store number of viruses
  
    # Generate random number of viruses (3-18)
    li $t9, 10       # Upper bound of number generated is 9
    jal random_num
    addi $t6, $t7, 3  # Add 3 as the virus count must be between 3-12
  
    la $t0, viruses   # Virus storage location
    li $t1, 0         # Counter for init_viruses




#initialise all x number of viruses from function generate_viruses

#t0 stores the VIRUSES storage location
#t1 stores the counter of the loop
#t2 will store the VIRUSES_COLORS
#t6 stores number of viruses

#t3 will store random x-coordinate
#t4 will store random y-coordinate
#t5 will store color

init_viruses: 
    beq $t1, $t6, init_viruses_end
    li $t3, 0 #initialise $t3 to 0
    li $t4, 0 #initialise $t4 to 0
    li $t5, 0 #initialise $t5 to 0

    #Generate a random x coordinate for a given virus
    li $t9, 16 #Upper bound for x-coordinate (grid is 16 units wide)
    jal random_num
    addi $t3, $t7, 1 # Add 1 as the x coordinate must be between 1-16
    
    #Generate a random y co-ordinate for a given virus
    li $t9, 16 #Upper bound for y-coordinate (grid is 20 units in height)
    jal random_num
    addi $t4, $t7, 15 # Add 11 as the y coordinate must be between 11-30    
  
    #Generate a random color for a given virus
    li $t9, 3 #Upper bound for color (between 0-2)
    jal random_num
    move $t5, $t7    # Store the random value in $t5


    #WE ALSO NEED TO STORE THE VIRUS COLOR IN THE GRID STRUCT

      #Find the offset in the grid struct
      #store the color number in that position

      #WHAT DO WE NEED: x (t3), y (t4), color as a number(t5)

      #USE STACK POINTERS to store t3, t4, v0

      addi $sp, $sp, -12
      sw $t3, 0($sp) #store $t3 (x coord) in stack
      sw $t4, 4($sp) #store $t4 (y coord) in stack
      sw $v0, 8($sp) #store $v0 (color as 0-2) in stack
      

      la $v0, grid #load adress of grid into $v0

      #need to calcuate our offset 
      addi $t3, $t3, -1
      mul $t3, $t3, 4 #calculate horizontal offset

      addi $t4, $t4, -9
      mul $t4, $t4, 64 #calculae vertical offset

      add $v0, $v0, $t3 #add the horizontal offset of virus to the grid address
      add $v0, $v0, $t4 #add the vertical offset of virus to the grid address
      sw $t5, 0($v0) #Store the color (0,1,2) of the virus in the grid struct at its pixel offset

      #pop the stack pointer

      lw $t3, 0($sp) #pop $t3 (x coord) in stack
      lw $t4, 4($sp) #pop $t4 (y coord) in stack
      lw $v0, 8($sp) #pop $v0 (color) in stack
      addi $sp, $sp, 12

    
    la $t2, VIRUS_COLORS #load address of virus colors into $t2
    mul $t5, $t5, 4 #calculate the offset we need to do for the virus color
    add $t5, $t2, $t5 #$t5 stores the address of the color of this virus
    lw $t5, 0($t5) #$t5 stores the color of the virus

    # Store virus (x, y, color) in virus struct
    sw $t3, 0($t0) #store x
    sw $t4, 4($t0) #store y
    sw $t5, 8($t0) #store color in hex
    addi $t0, $t0, 12  # Move to next virus slot


    # Draw the virus
    move $a0, $t3  # x
    move $a1, $t4  # y
    move $a2, $t5  # color
    jal draw_virus #draw the virus
    
    addi $t1, $t1, 1 #increment counter
    j init_viruses


draw_virus:

    la $s0, ADDR_DSPL #store 0,0 in $t3
    lw $t3, 0($s0)
    mul $a0, $a0, 4 #find the horizontal offset of virus from ADDR_DSPL
    add $t3, $t3, $a0 #add horizontall offset to the lcoation
    mul $a1, $a1, 128 #find the vertical offset of virus from ADDR_DSPL
    add $t3, $t3, $a1 #stores the position of the virus

    sw $a2, 0($t3) #paint the position of the virus with the color
    jr $ra

init_viruses_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

####################################################################################
# Keyboard Movement
##################################################################################

check_keyboard_input:

  lw $s0, ADDR_KBRD               # reads keyboard status, 1 if pressed 0 if not, $s0 = base address for keyboard
  lw $t8, 0($s0)                  # Load first word from keyboard (either 1 or 0)
  beq $t8, 0, input_dealt_with         # If first word 1, key is pressed, return to the loop
  
  lw $s3, 4($s0) # save the ASCII value in $s3
   
  # Check for 'q' to quit
  beq $s3, 113, finish_game

  
input_dealt_with:
  jr $ra
  

finish_game:
  jal draw_white_end_box
  li $v0, 10          # terminates the program gracefully 
  syscall 

sleep:
  li $v0, 32
  li $a0, 100
  syscall
  jr $ra


redraw_left:
  
  addi $sp, $sp, -8  # storing main call return address
  sw $ra, 0($sp)
  la $t0, capsule
  lw $t1, 0($t0) 
  lw $t6, 8($t0) # storing orientation in $t6 to check boundary 
  beq $t1,1, end_motion
 
    
  sw $t1, 4($sp)


  jal play_move_sound

  addi $sp, $sp, -36 # storing return address on stack for redraw down
  sw $ra, 0($sp)
  sw $t0, 4($sp)
  sw $t1, 8($sp)
  sw $t2, 12($sp)
  sw $t3, 16($sp)
  sw $t4, 20($sp)
  sw $t5, 24($sp)
  sw $t6, 28($sp)
  sw $t7, 32($sp)

  jal check_collision_left # checks collision on the left based on orientation

  
  lw $ra, 0($sp)
  lw $t0, 4($sp)
  lw $t1, 8($sp)
  lw $t2, 12($sp)
  lw $t3, 16($sp)
  lw $t4, 20($sp)
  lw $t5, 24($sp)
  lw $t6, 28($sp)
  lw $t7, 32($sp)
  addi $sp, $sp, 36 # storing return address on stack for redraw down


  #CHECK IF $s2 is 0 (No, collision) or 1 (collision)

  beq $s2, 1, redraw_left_end #This prevents capsule going left if there is something to the left
  
  # First, erase the current capsule
  jal clear_capsule          # Call function to erase the current capsule
  lw $t1, 4($sp)
  # Update positions
  addi $t1, $t1, -1          # Move left
  sw $t1, 0($t0)             # Store new x back to capsule
  
  # Draw the capsule at new position
  
  jal draw_capsule

  redraw_left_end:
  
  lw $ra, 0($sp) # restore main call return address
  addi $sp, $sp, 8
  
  j end_motion 

check_left_orientation_2: # do the same as above but with a different boundary check
  beq $t1, 2, end_motion # check if its at boundary
   sw $t1, 4($sp)
  # First, erase the current capsule
  jal clear_capsule          # Call function to erase the current capsule
  lw $t1, 4($sp)
  # Update positions
  addi $t1, $t1, -1          # Move left
  sw $t1, 0($t0)             # Store new x back to capsule
  
  # Draw the capsule at new position
  
  jal draw_capsule
  
  lw $ra, 0($sp) # restore main call return address
  addi $sp, $sp, 8
  j end_motion 
  
redraw_down:
  
  addi $sp, $sp, -8  # storing main call return address
  sw $ra, 0($sp)
  la $t0, capsule
  lw $t2, 4($t0)             # Load current y-coordinate
  lw $t6, 8($t0) # load the orientation of the capsules
  
  
  
  jal play_move_sound
  addi $sp, $sp, -36 # storing return address on stack for redraw down
  sw $ra, 0($sp)
  sw $t0, 4($sp)
  sw $t1, 8($sp)
  sw $t2, 12($sp)
  sw $t3, 16($sp)
  sw $t4, 20($sp)
  sw $t5, 24($sp)
  sw $t6, 28($sp)
  sw $t7, 32($sp)

  jal check_collision_down # checks collision based on orientation with a bottom wall check

  
  lw $ra, 0($sp)
  lw $t0, 4($sp)
  lw $t1, 8($sp)
  lw $t2, 12($sp)
  lw $t3, 16($sp)
  lw $t4, 20($sp)
  lw $t5, 24($sp)
  lw $t6, 28($sp)
  lw $t7, 32($sp)
  addi $sp, $sp, 36 # storing return address on stack for redraw down

  
  # First, erase the current capsule
  sw $t2, 4($sp) 
  jal clear_capsule 

  lw $t2, 4($sp)
  # Update positions


  #CHECK STATUS OF CAPSULE. IF ACTIVE MOVE DOWN. IF INACTIVE SAME PLACE

  lw $t3, 20($t0) #$t3 stores active status 

  beq $t3, 1, IF_INCREMENT_Y
  j END_IF_INCREMENT_Y

  IF_INCREMENT_Y:
  addi $t2, $t2, 1         # Move down

  END_IF_INCREMENT_Y:
  sw $t2, 4($t0) # don't move dow, its inactive, draw it where it is (a collision was detected)
  
  jal draw_capsule

  

  #CHECK IF CAPSULE IS INACTIVE... IF IT IS THEN INITIALISE A NEW CAPSULE
 
  
  la $t0, capsule
  lw $t1, 20($t0) # load active status

  beq $t1, 0, check_and_initialise # inactive, initialise new capsule and check for 4 in a row
  j no_collision
  
  check_and_initialise:
  jal initialise_new_capsule

  no_collision:
  lw $ra, 0($sp) # restore main call return addrss
  addi $sp, $sp, 8
  j end_motion
 


redraw_right:
addi $sp, $sp, -8         # allocate 8 bytes on stack
sw $ra, 4($sp)            # store return address at higher offset
sw $t1, 0($sp)            # store x-coordinate

la $t0, capsule
lw $t1, 0($t0)            # Load current x-coordinate
lw $t6, 8($t0) # loading orientation



jal play_move_sound

addi $sp, $sp, -36 # storing return address on stack for redraw right
  sw $ra, 0($sp)
  sw $t0, 4($sp)
  sw $t1, 8($sp)
  sw $t2, 12($sp)
  sw $t3, 16($sp)
  sw $t4, 20($sp)
  sw $t5, 24($sp)
  sw $t6, 28($sp)
  sw $t7, 32($sp)

  jal check_collision_right # checks collision on the right based on orientation, also checks for walls

  
  lw $ra, 0($sp)
  lw $t0, 4($sp)
  lw $t1, 8($sp)
  lw $t2, 12($sp)
  lw $t3, 16($sp)
  lw $t4, 20($sp)
  lw $t5, 24($sp)
  lw $t6, 28($sp)
  lw $t7, 32($sp)
  addi $sp, $sp, 36 # storing return address on stack for redraw right


  #CHECK IF $s2 is 0 (No, collision) or 1 (collision)

  beq $s2, 1, redraw_right_end #This prevents capsule going right if there is something to the right


jal clear_capsule         # Erase current capsule

lw $t1, 0($sp)            # Restore x-coordinate
addi $t1, $t1, 1          # Move right
sw $t1, 0($t0)            # Store updated x

jal draw_capsule          # Draw updated capsule

redraw_right_end:
lw $ra, 4($sp)            # Restore return address
addi $sp, $sp, 8          # Free the stack space

j end_motion


rotate_capsule:
  
# first store return address 
addi $sp, $sp, -4
sw $ra, 0($sp)


la $t0, capsule 
lw $t1, 0($t0) # loading x-coordinate
lw $t2, 4($t0) # loading y-coordinate
lw $t6, 8($t0) # loading orientation
# blocking rotation occurs in all orientation positions
beq $t6, 0, rotate_orientation0 # blocks on collision with boundary or item in grid 
beq $t6, 1, rotate_orientation1 # blocks on collision with boundary or item in grid 
beq $t6, 2, rotate_orientation2 # blocks on collision with boundary or item in grid 
beq $t6, 3, rotate_orientation3 # blocks on collision with boundary or item in grid 


# clear the capsule based on the orientation it has
jal clear_capsule

lw $t3, 8($t0) # store orientation (safety)
addi $t3, $t3, 1 # increment orientation
beq $t3, 4, THEN # wrap around to 0 if orientation reached 4
j END_IF 


THEN: 
addi $t3, $t3, -4


END_IF:
jal play_rotation_sound
sw $t3, 8($t0)
jal draw_capsule
lw $ra, 0($sp)
addi $sp, $sp, 4
j end_motion



rotate_orientation0: # checks for collisions in general
beq $t2, 30, end_motion # checks for the bottom of the wall


la $t5, grid # loading the grid struct

  # calculate position of capsule

  addi $t1, $t1, -1
  mul $t1, $t1, 4 #calculate horizontal offset of capsule in grid

  addi $t2, $t2, -9
  mul $t2, $t2, 64  #calculate vertical offset of capsule in grid

  add $t5, $t5, $t1 # add the horizontal offset of the virus to grid address
  add $t5, $t5, $t2 # add the vertical offset of the virus to grid address

lw $t4, 64($t5), # loading grid position 1 coordinate below the capsule's first half and blocking if there is an item (destination of rotation)
bne $t4, 3, end_motion 
jal clear_capsule



lw $t3, 8($t0) # store orientation (safety)
addi $t3, $t3, 1 # increment orientation
beq $t3, 4, THEN # wrap around to 0 if orientation reached 4
j END_IF



rotate_orientation1: # checks any collision
beq $t1, 1, end_motion # checks for left wall

la $t5, grid # loading the grid struct

  # calculate position of capsule

  addi $t1, $t1, -1
  mul $t1, $t1, 4 #calculate horizontal offset of capsule in grid

  addi $t2, $t2, -9
  mul $t2, $t2, 64  #calculate vertical offset of capsule in grid

  add $t5, $t5, $t1 # add the horizontal offset of the virus to grid address
  add $t5, $t5, $t2 # add the vertical offset of the virus to grid address

lw $t4, -4($t5), # loading grid position to the left of the capsule's first half and blocking if there is an item
bne $t4, 3, end_motion # this includes the top left bottle neck



jal clear_capsule

lw $t3, 8($t0) # store orientation (safety)
addi $t3, $t3, 1 # increment orientation
beq $t3, 4, THEN # wrap around to 0 if orientation reached 4
j END_IF 

rotate_orientation2: # if at top of the wall block orientation
beq $t2, 10, end_motion
jal clear_capsule

la $t5, grid # loading the grid struct

  # calculate position of capsule

  addi $t1, $t1, -1
  mul $t1, $t1, 4 #calculate horizontal offset of capsule in grid

  addi $t2, $t2, -9
  mul $t2, $t2, 64  #calculate vertical offset of capsule in grid

  add $t5, $t5, $t1 # add the horizontal offset of the virus to grid address
  add $t5, $t5, $t2 # add the vertical offset of the virus to grid address

lw $t4, -64($t5), # loading grid position 1 coordinate above the capsule's first half and blocking if there is an item
bne $t4, 3, end_motion 


lw $t3, 8($t0) # store orientation (safety)
addi $t3, $t3, 1 # increment orientation
beq $t3, 4, THEN # wrap around to 0 if orientation reached 4
j END_IF


rotate_orientation3: # same as above but blocks rotation at right boundary for orient. 3
beq $t1, 16, end_motion # checks at boundarys

la $t5, grid # loading the grid struct

  # calculate position of capsule

  addi $t1, $t1, -1
  mul $t1, $t1, 4 #calculate horizontal offset of capsule in grid

  addi $t2, $t2, -9
  mul $t2, $t2, 64 #calculate vertical offset of capsule in grid

  add $t5, $t5, $t1 # add the horizontal offset of the virus to grid address
  add $t5, $t5, $t2 # add the vertical offset of the virus to grid address

lw $t4, 4($t5), # loading grid position to the right of the capsule's first half and blocking if there is an item
bne $t4, 3, end_motion 

jal clear_capsule

lw $t3, 8($t0) # store orientation (safety)
addi $t3, $t3, 1 # increment orientation
beq $t3, 4, THEN # wrap around to 0 if orientation reached 4
j END_IF 



clear_capsule:
  
  la $t0, capsule
  lw $t1, 0($t0)   # x
  lw $t2, 4($t0)   # y
  lw $t3, 8($t0)   # orientation

  li $t7, 0x000000 # black (background color)
  lw $t9, ADDR_DSPL

  sll $t1, $t1, 2
  # storing location of capsule in offset
  add $t9, $t9, $t1 # adding horizontal offset
  sll $t6, $t2, 7
  add $t9, $t9, $t6 # adding vertical offset

  sw $t7, 0($t9)

  #check orientation and erase based on it
  beq $t3, 0, clear_orientation0
  beq $t3, 1, clear_orientation1
  beq $t3, 2, clear_orientation2
  beq $t3, 3, clear_orientation3

  jr $ra

clear_orientation0:
  
  sw $t7, 4($t9) # remove the pixel after (paint with black)
  jr $ra

clear_orientation1:
  
  sw $t7, 128($t9) # remove pixel under
  jr $ra
  
clear_orientation2:
  sw $t7, -4($t9) # remove pixel to the left
  jr $ra
  
clear_orientation3:
  sw $t7, -128($t9) # remove pixel above it
  jr $ra

end_motion:
  li $s3, 0  #reset keyboard input
  jr $ra  # jump back to main loop

pause_game:

  addi $sp, $sp, -12
  sw $ra, 0($sp) #store the return adresss to game loop in stack pointer
  sw $t0, 4($sp) #store the $t0 in stack pointer as we will modify it
  sw $s6, 8($sp) #store the $s6 in stack pointer as we will modify it

  
  jal end_motion #stop the key press so it doesnt keep looping (trivial)


  lw $t0, ADDR_DSPL
  addi $s6, $zero, 0xD3D3D3


  #DRAWING THE PAUSE IN LIGHT GREY
  sw $s6, 140($t0)
  sw $s6, 268($t0)
  sw $s6, 396($t0)

  sw $s6, 132($t0)
  sw $s6, 260($t0)
  sw $s6, 388($t0)

  #check if we have clicked p again
  pause_game_loop:
    jal check_keyboard_input
  
        # $s3 now stores the keyboard value, quit check done already in check_keyboard_input
    li $v0, 1
    move $a0, $s3
    syscall # debugger

    beq $s3, 112, pause_game_end
  
    jal sleep

    j pause_game_loop


#only come here if we have received another click of 'p'
pause_game_end:  
  jal end_motion

  #GETTING RID OF THE PAUSE
  sw $zero, 140($t0)
  sw $zero, 268($t0)
  sw $zero, 396($t0)

  sw $zero, 132($t0)
  sw $zero, 260($t0)
  sw $zero, 388($t0)

  lw $s6, 8($sp) #pop the $s6 to game_loop from $sp
  lw $t0, 4($sp) #pop the $t0 to game_loop from $sp
  lw $ra, 0($sp) #pop the $ra to game_loop from $sp
  addi $sp, $sp, 4 # move sp back
  jr $ra #return to game_loopp

####################################################################################
# Collision detection
####################################################################################

check_collision_down: # only checks collision below

  la $t0, capsule
  lw $t1, 0($t0) # loading x-coordinate
  lw $t2, 4($t0) # loading y-coordinate
  lw $t3, 8($t0) # loading the orientation of capsule
  lw $t6, 12($t0) # load color of main pill
  lw $t7, 16($t0) # load color of secondary pill
   
  la $t5, grid # loading the grid struct

  # calculate position of capsule

  addi $t1, $t1, -1
  mul $t1, $t1, 4 #calculate horizontal offset of capsule in grid

  addi $t2, $t2, -9
  mul $t2, $t2, 64 #calculate vertical offset of capsule in grid

  add $t5, $t5, $t1 # add the horizontal offset of the virus to grid address
  add $t5, $t5, $t2 # add the vertical offset of the virus to grid address
  
  
  # $t5 is at the address of the capsule in the grid 
  beq $t3, 0, check_collision_orient0
  beq $t3, 1, check_collision_orient1
  beq $t3, 2, check_collision_orient2
  beq $t3, 3, check_collision_orient3

  
check_collision_orient0: # checking collision based on orientation 0
  
  lw $t4,  64($t5) #checking the color of the pixel below main pill
  bne $t4, 3, collision_found_orient0

  lw $t4,  68($t5) #checking the color of the pixel below main pill
  bne $t4, 3, collision_found_orient0
  
  jr $ra # jumps back to redraw down
  #need to implemenet for the piexel below secondary pill


collision_found_orient0:
  
  sw $t6, 0($t5) #store main pill color in grid struct
  sw $t7, 4($t5) #store secondary pill color in grid struct
  sw $zero, 20($t0) # making the capsule inactive

  
  
  jr $ra


check_collision_orient1: # checking collision based on orientation 1
  
  lw $t4,  128($t5) #checking the color of the pixel 2 below main pill
  bne $t4, 3, collision_found_orient1
  
  jr $ra # jumps back to redraw down
  


collision_found_orient1:
  
  sw $t6, 0($t5) #store main pill color in grid struct
  sw $t7, 64($t5) #store secondary pill color in grid struct
  sw $zero, 20($t0) # making the capsule inactive

  jr $ra
  
check_collision_orient2: # checking collision based on orientation 2
  
  lw $t4,  64($t5) # checking the color of the pixel below main pill
  bne $t4, 3, collision_found_orient2

  lw $t4,  60($t5) # checking the color of the pixel below main pill
  bne $t4, 3, collision_found_orient2
  
  jr $ra # jumps back to redraw down
  #need to implemenet for the piexel below secondary pill


collision_found_orient2:
  
  sw $t6, 0($t5) #store main pill color in grid struct
  sw $t7, -4($t5) #store secondary pill color in grid struct
  sw $zero, 20($t0) # making the capsule inactive

  jr $ra

check_collision_orient3: # checking collision based on orientation 3
  
  lw $t4,  64($t5) #checking the color of the pixel 2 below main pill
  bne $t4, 3, collision_found_orient3
  
  jr $ra # jumps back to redraw down
  


collision_found_orient3:
  
  sw $t6, 0($t5) #store main pill color in grid struct
  sw $t7, -64($t5) #store secondary pill color in grid struct
  sw $zero, 20($t0) # making the capsule inactive

  jr $ra

check_collision_left: # only checks collision on the left

  la $t0, capsule
  lw $t1, 0($t0) # loading x-coordinate
  lw $t2, 4($t0) # loading y-coordinate
  lw $t3, 8($t0) # loading the orientation of capsule
  lw $t6, 12($t0) # load color of main pill
  lw $t7, 16($t0) # load color of secondary pill
   
  la $t5, grid # loading the grid struct

  # calculate position of capsule

  addi $t1, $t1, -1
  mul $t1, $t1, 4 #calculate horizontal offset of capsule in grid

  addi $t2, $t2, -9
  mul $t2, $t2, 64 #calculate vertical offset of capsule in grid

  add $t5, $t5, $t1 # add the horizontal offset of the virus to grid address
  add $t5, $t5, $t2 # add the vertical offset of the virus to grid address
  
  
  # $t5 is at the address of the capsule in the grid 
  beq $t3, 0, check_collision_left_orient0
  beq $t3, 1, check_collision_left_orient1
  beq $t3, 2, check_collision_left_orient2
  beq $t3, 3, check_collision_left_orient3


check_collision_left_orient0: # checking collision based on orientation 0
  
  lw $t4,  -4($t5) #checking the color of the pixel left of main pill
  bne $t4, 3, collision_found
  li $s2, 0
  
  jr $ra # jumps back to redraw down
  #need to implemenet for the piexel below secondary pill


check_collision_left_orient1: # checking collision based on orientation 1

  lw $t4,  -4($t5) #checking the color of the pixel left of main pill
  bne $t4, 3, collision_found

  lw $t4,  60($t5) #checking the color of the pixel left of seconary pill
  bne $t4, 3, collision_found
  
  li $s2, 0 # otherwise no collision detected
  
  jr $ra # jumps back to redraw down
  #need to implemenet for the piexel below secondary pill

check_collision_left_orient2:

  lw $t4, -8($t5)
  bne $t4, 3, collision_found

  la $t0, capsule
  lw $t1, 0($t0) # loading x-coordinate
  beq $t1, 2, collision_found

  li $s2, 0
 
  jr $ra

check_collision_left_orient3:
  lw $t4, -4($t5)
  bne $t4, 3, collision_found

  lw $t4, -68($t5)
  bne $t4, 3, collision_found

  li $s2, 0

  jr $ra


collision_found:

  li $s2, 1 # collision detected
  jr $ra # return to redraw function




check_collision_right: # checks for collision when moving right
la $t0, capsule
  lw $t1, 0($t0) # loading x-coordinate
  lw $t2, 4($t0) # loading y-coordinate
  lw $t3, 8($t0) # loading the orientation of capsule
  lw $t6, 12($t0) # load color of main pill
  lw $t7, 16($t0) # load color of secondary pill
   
  la $t5, grid # loading the grid struct

  # calculate position of capsule

  addi $t1, $t1, -1
  mul $t1, $t1, 4 #calculate horizontal offset of capsule in grid

  addi $t2, $t2, -9
  mul $t2, $t2, 64 #calculate vertical offset of capsule in grid

  add $t5, $t5, $t1 # add the horizontal offset of the virus to grid address
  add $t5, $t5, $t2 # add the vertical offset of the virus to grid address
  
  
  # $t5 is at the address of the capsule in the grid 
  beq $t3, 0, check_collision_right_orient0
  beq $t3, 1, check_collision_right_orient1
  beq $t3, 2, check_collision_right_orient2
  beq $t3, 3, check_collision_right_orient3

check_collision_right_orient0:
  lw $t4, 8($t5) # checking value of grid two bytes to the right of the capsule in standard orientation
  bne $t4, 3, collision_found # collision found if not black

  lw $t1, 0($t0) # loading x-coordinate
  beq $t1, 15, collision_found # collision on right wall for standard orientation
  
  li $s2, 0 # no collision detected
  jr $ra # otherwise return to redraw right



check_collision_right_orient1:
  lw $t4, 4($t5) # checking value of grid one byte to the right of first half
  bne $t4, 3, collision_found # collision found

  lw $t4, 68($t5) # checking value of grid on the right of second half of capsule
  bne $t4, 3, collision_found # collision on right wall for first orientation

  lw $t1, 0($t0) # loading x-coordinate
  beq $t1, 16, collision_found # checking right wall  
  li $s2, 0 # no collision detected
  jr $ra # otherwise return to redraw right


check_collision_right_orient2:
  lw $t4, 4($t5) # checking value of grid one byte to the right of first half
  bne $t4, 3, collision_found

  lw $t1, 0($t0) # loading x-coordinate
  beq $t1, 16, collision_found # checking right wall 
  li $s2, 0 # no collision detected
  jr $ra # otherwise return to redraw right


check_collision_right_orient3:
  lw $t4, 4($t5) # checking to the right of first half
  bne $t4, 3, collision_found

  lw $t4, -60($t5) # checking to the right of second .half
  bne $t4, 3, collision_found

  lw $t1, 0($t0) # loading x-coordinate
  beq $t1, 16, collision_found

  li $s2, 0 # no collision detected
  jr $ra
  
  
initialise_new_capsule:
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  
  # Set the capsule to active
  la $t0, capsule
  li $t1, 1
  sw $t1, 20($t0)  # Store status (1 = active) at offset 20
  li $t1, 8 
  sw $t1, 0($t0)  # Store x = 8 at offset 0
  li $t1, 9
  sw $t1, 4($t0)  # Store y = 9 at offset 4
  li $t1, 0 
  sw $t1, 8($t0)  # Store orientation = 0 at offset 8
  li $t1, 0 
  sw $t1, 12($t0)  # Store color = 0 for pill 1 at offset 12
  li $t1, 0 
  sw $t1, 16($t0)  # Store color = 0 for pill 2 at offset 16
  
  # Generate and store random colors in the correct location of the capsule struct
  jal generate_random_num
  sw $a0, 12($t0)

  jal generate_random_num   
  sw $a0, 16($t0)          

  # Check for four in a row and eliminate them
  jal four_in_a_row_horizontal
  jal four_in_a_row_vertical
  
  

  lw $ra, 0($sp)
  addi, $sp, $sp, 4
  li $s6, 0 # reset gravity counter and threshhold
  li $s7, 25 # reset gravity threshhold
  jr $ra

########################################################
# GAME OVER SCREEN
##################################################################################
  

#DRAW THE WHITE BOX TO WRITE GAME OVER ON TOP

  draw_white_end_box:
    
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $s0, 4($sp)

    lw $s0, ADDR_DSPL # load the value of s0

    
    #drawing first line of box
    addi $a0, $zero, 5 # set the X coordinate for this line
    addi $a1, $zero, 9 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0xD3D3D3 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    
    #drawing second line of box
    addi $a0, $zero, 5 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0xD3D3D3 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    #drawing third line of box
    addi $a0, $zero, 5 # set the X coordinate for this line
    addi $a1, $zero, 11 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0xD3D3D3 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

  
    addi $a0, $zero, 5 # set the X coordinate for this line
    addi $a1, $zero, 12 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0xD3D3D3 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

   
    addi $a0, $zero, 5 # set the X coordinate for this line
    addi $a1, $zero, 13 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0xD3D3D3 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

 
    addi $a0, $zero, 5 # set the X coordinate for this line
    addi $a1, $zero, 14 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0xD3D3D3 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

  
    addi $a0, $zero, 5 # set the X coordinate for this line
    addi $a1, $zero, 15 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0xD3D3D3 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1


    addi $a0, $zero, 5 # set the X coordinate for this line
    addi $a1, $zero, 16 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0xD3D3D3 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1


    addi $a0, $zero, 5 # set the X coordinate for this line
    addi $a1, $zero, 17 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0xD3D3D3 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

  
    addi $a0, $zero, 5 # set the X coordinate for this line
    addi $a1, $zero, 18 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0xD3D3D3 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

  
    addi $a0, $zero, 5 # set the X coordinate for this line
    addi $a1, $zero, 19 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0xD3D3D3 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    #drawing 3rd last line of box
    addi $a0, $zero, 5 # set the X coordinate for this line
    addi $a1, $zero, 20 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0xD3D3D3 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    #drawing 2nd last line of box
    addi $a0, $zero, 5 # set the X coordinate for this line
    addi $a1, $zero, 21 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0xD3D3D3 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    #drawing last line of box
    addi $a0, $zero, 5 # set the X coordinate for this line
    addi $a1, $zero, 22 # set the Y coordinate for this line
    addi $a2, $zero, 21, #set the length of the line
    addi $a3, $zero, 0xD3D3D3 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1


    #drawing the G

    addi $a0, $zero, 6 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 5, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 6 # set the X coordinate for this line
    addi $a1, $zero, 14 # set the Y coordinate for this line
    addi $a2, $zero, 4, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 8 # set the X coordinate for this line
    addi $a1, $zero, 12 # set the Y coordinate for this line
    addi $a2, $zero, 3, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 6 # set the X coordinate for this line
    addi $a1, $zero, 11 # set the Y coordinate for this line
    addi $a2, $zero, 3, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_vertical #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 9 # set the X coordinate for this line
    addi $a1, $zero, 12 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_vertical #draw a HORIZONTAL line of length $a2 at $a0,$a1


    #drawing the A

    addi $a0, $zero, 12 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 5, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_vertical #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 14 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 5, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_vertical #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 13 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_vertical #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 13 # set the X coordinate for this line
    addi $a1, $zero, 12 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_vertical #draw a HORIZONTAL line of length $a2 at $a0,$a1


    #drawing the M

    addi $a0, $zero, 16 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 5, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_vertical #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 18 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 4, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_vertical #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 20 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 5, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_vertical #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 16 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 5, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    #drawing the E

    addi $a0, $zero, 22 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 5, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_vertical #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 22 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 3, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 22 # set the X coordinate for this line
    addi $a1, $zero, 12 # set the Y coordinate for this line
    addi $a2, $zero, 3, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 22 # set the X coordinate for this line
    addi $a1, $zero, 14 # set the Y coordinate for this line
    addi $a2, $zero, 3, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1


    #drawing the O

    addi $a0, $zero, 6 # set the X coordinate for this line
    addi $a1, $zero, 17 # set the Y coordinate for this line
    addi $a2, $zero, 5, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_vertical #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 9 # set the X coordinate for this line
    addi $a1, $zero, 17 # set the Y coordinate for this line
    addi $a2, $zero, 5, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_vertical #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 7 # set the X coordinate for this line
    addi $a1, $zero, 17 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 7 # set the X coordinate for this line
    addi $a1, $zero, 21 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1


    #drawing the V 

    addi $a0, $zero, 12 # set the X coordinate for this line
    addi $a1, $zero, 17 # set the Y coordinate for this line
    addi $a2, $zero, 4, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_vertical #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 14 # set the X coordinate for this line
    addi $a1, $zero, 17 # set the Y coordinate for this line
    addi $a2, $zero, 4, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_vertical #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 13 # set the X coordinate for this line
    addi $a1, $zero, 21 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    
    #drawing the E

    addi $a0, $zero, 16 # set the X coordinate for this line
    addi $a1, $zero, 17 # set the Y coordinate for this line
    addi $a2, $zero, 5, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_vertical #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 16 # set the X coordinate for this line
    addi $a1, $zero, 17 # set the Y coordinate for this line
    addi $a2, $zero, 3, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 16 # set the X coordinate for this line
    addi $a1, $zero, 19 # set the Y coordinate for this line
    addi $a2, $zero, 3, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 16 # set the X coordinate for this line
    addi $a1, $zero, 21 # set the Y coordinate for this line
    addi $a2, $zero, 3, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1


    #drawing the R

    addi $a0, $zero, 21 # set the X coordinate for this line
    addi $a1, $zero, 17 # set the Y coordinate for this line
    addi $a2, $zero, 5, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_vertical #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 22 # set the X coordinate for this line
    addi $a1, $zero, 17 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0xFF0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1


    lw $ra, 0($sp)
    lw $s0, 4($sp)

    addi $sp, $sp, 8


    
    jr $ra


####################################################################################
# DR MARIO 
##################################################################################

draw_dr_mario:
  #SAVING REGISTERS ON THE STACK 
  addi $sp, $sp, -20
  sw $ra, 0($sp)
  sw $a0, 4($sp)
  sw $a1, 8($sp)
  sw $a2, 12($sp)
  sw $a3, 16($sp)



    #Drawing the sthetoscope 

    addi $a0, $zero, 24 # set the X coordinate for this line
    addi $a1, $zero, 18 # set the Y coordinate for this line
    addi $a2, $zero, 4, #set the length of the line
    addi $a3, $zero, 0x283C82 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 28 # set the X coordinate for this line
    addi $a1, $zero, 18 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0x646464 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

  #Drawing the face 

    addi $a0, $zero, 24 # set the X coordinate for this line
    addi $a1, $zero, 19 # set the Y coordinate for this line
    addi $a2, $zero, 6, #set the length of the line
    addi $a3, $zero, 0xE6BE96 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1


    addi $a0, $zero, 28 # set the X coordinate for this line
    addi $a1, $zero, 19 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0x2D2D2D #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 24 # set the X coordinate for this line
    addi $a1, $zero, 19 # set the Y coordinate for this line
    addi $a2, $zero, 3, #set the length of the line
    addi $a3, $zero, 0x5A3214 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 25 # set the X coordinate for this line
    addi $a1, $zero, 19 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0x5A3214 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1


  
  #Drawing the face 

    addi $a0, $zero, 24 # set the X coordinate for this line
    addi $a1, $zero, 20 # set the Y coordinate for this line
    addi $a2, $zero, 7, #set the length of the line
    addi $a3, $zero, 0xE6BE96 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1



    addi $a0, $zero, 23 # set the X coordinate for this line
    addi $a1, $zero, 20 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0x5A3214 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 25 # set the X coordinate for this line
    addi $a1, $zero, 20 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0x5A3214 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

  #Drawing the face 

    addi $a0, $zero, 25 # set the X coordinate for this line
    addi $a1, $zero, 21 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0xE6BE96 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 27 # set the X coordinate for this line
    addi $a1, $zero, 21 # set the Y coordinate for this line
    addi $a2, $zero, 3, #set the length of the line
    addi $a3, $zero, 0x2D2D2D #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 23 # set the X coordinate for this line
    addi $a1, $zero, 21 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0x5A3214 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1


  
  #Drawing the face 

    addi $a0, $zero, 25 # set the X coordinate for this line
    addi $a1, $zero, 22 # set the Y coordinate for this line
    addi $a2, $zero, 4, #set the length of the line
    addi $a3, $zero, 0xE6BE96 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

  #Drawing the suit 

    addi $a0, $zero, 25 # set the X coordinate for this line
    addi $a1, $zero, 23 # set the Y coordinate for this line
    addi $a2, $zero, 4, #set the length of the line
    addi $a3, $zero, 0xEBEBEB #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1


    addi $a0, $zero, 26 # set the X coordinate for this line
    addi $a1, $zero, 23 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0xFF00000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1
  
  #Drawing the suit 

    addi $a0, $zero, 24 # set the X coordinate for this line
    addi $a1, $zero, 24 # set the Y coordinate for this line
    addi $a2, $zero, 6, #set the length of the line
    addi $a3, $zero, 0xEBEBEB #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 25 # set the X coordinate for this line
    addi $a1, $zero, 24 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0x465064 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 26 # set the X coordinate for this line
    addi $a1, $zero, 24 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0xFF00000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1
  
  #Drawing the suit 

    addi $a0, $zero, 23 # set the X coordinate for this line
    addi $a1, $zero, 25 # set the Y coordinate for this line
    addi $a2, $zero, 8, #set the length of the line
    addi $a3, $zero, 0xEBEBEB #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 26 # set the X coordinate for this line
    addi $a1, $zero, 25 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0x465064 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

  #Drawing the suit 

    addi $a0, $zero, 24 # set the X coordinate for this line
    addi $a1, $zero, 26 # set the Y coordinate for this line
    addi $a2, $zero, 6, #set the length of the line
    addi $a3, $zero, 0xEBEBEB #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 23 # set the X coordinate for this line
    addi $a1, $zero, 26 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0x465064 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 30 # set the X coordinate for this line
    addi $a1, $zero, 26 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0x465064 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 26 # set the X coordinate for this line
    addi $a1, $zero, 26 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0x465064 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    
  #Drawing the suit 

    addi $a0, $zero, 24 # set the X coordinate for this line
    addi $a1, $zero, 27 # set the Y coordinate for this line
    addi $a2, $zero, 6, #set the length of the line
    addi $a3, $zero, 0xEBEBEB #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 23 # set the X coordinate for this line
    addi $a1, $zero, 27 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0x646464 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 29 # set the X coordinate for this line
    addi $a1, $zero, 27 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0x646464 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

  #Drawing the suit 

    addi $a0, $zero, 24 # set the X coordinate for this line
    addi $a1, $zero, 28 # set the Y coordinate for this line
    addi $a2, $zero, 6, #set the length of the line
    addi $a3, $zero, 0xEBEBEB #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 23 # set the X coordinate for this line
    addi $a1, $zero, 28 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0x646464 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 30 # set the X coordinate for this line
    addi $a1, $zero, 28 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0x646464 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1
  
  #Drawing the pants 

    addi $a0, $zero, 24 # set the X coordinate for this line
    addi $a1, $zero, 29 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0x283C82 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 28 # set the X coordinate for this line
    addi $a1, $zero, 29 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0x283C82 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

  
  #Drawing the feet 

    addi $a0, $zero, 24 # set the X coordinate for this line
    addi $a1, $zero, 30 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0xD28C64 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 28 # set the X coordinate for this line
    addi $a1, $zero, 30 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0xD28C64 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

  #Drawing the feet 

    addi $a0, $zero, 23 # set the X coordinate for this line
    addi $a1, $zero, 31 # set the Y coordinate for this line
    addi $a2, $zero, 3, #set the length of the line
    addi $a3, $zero, 0xD28C64 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 28 # set the X coordinate for this line
    addi $a1, $zero, 31 # set the Y coordinate for this line
    addi $a2, $zero, 3, #set the length of the line
    addi $a3, $zero, 0xD28C64 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1


  #POP FROM STACK POINTER
  
  lw $ra, 0($sp)
  lw $a0, 4($sp)
  lw $a1, 8($sp)
  lw $a2, 12($sp)
  lw $a3, 16($sp)
  addi $sp, $sp, 20
  jr $ra


####################################################################################
# VIRUS
##################################################################################

draw_virus_hardcode:
  #USE THE STACK POINTER
  addi $sp, $sp, -20
  sw $ra, 0($sp)
  sw $a0, 4($sp)
  sw $a1, 8($sp)
  sw $a2, 12($sp)
  sw $a3, 16($sp)


  #Drawing the red virus  

    addi $a0, $zero, 28 # set the X coordinate for this line
    addi $a1, $zero, 13 # set the Y coordinate for this line
    addi $a2, $zero, 3, #set the length of the line
    addi $a3, $zero, 0xAA0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 28 # set the X coordinate for this line
    addi $a1, $zero, 14 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0xAA0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 30 # set the X coordinate for this line
    addi $a1, $zero, 14 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0xAA0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 27 # set the X coordinate for this line
    addi $a1, $zero, 15 # set the Y coordinate for this line
    addi $a2, $zero, 5, #set the length of the line
    addi $a3, $zero, 0xAA0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 27 # set the X coordinate for this line
    addi $a1, $zero, 15 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0xAA0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1
    

    addi $a0, $zero, 27 # set the X coordinate for this line
    addi $a1, $zero, 16 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0xAA0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 30 # set the X coordinate for this line
    addi $a1, $zero, 16 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0xAA0000 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1



    #Drawing the YELLOW virus  

    addi $a0, $zero, 22 # set the X coordinate for this line
    addi $a1, $zero, 13 # set the Y coordinate for this line
    addi $a2, $zero, 3 #set the length of the line
    addi $a3, $zero, 0xAAAA00 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 22 # set the X coordinate for this line
    addi $a1, $zero, 14 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0xAAAA00 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 24 # set the X coordinate for this line
    addi $a1, $zero, 14 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0xAAAA00 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 21 # set the X coordinate for this line
    addi $a1, $zero, 15 # set the Y coordinate for this line
    addi $a2, $zero, 5, #set the length of the line
    addi $a3, $zero, 0xAAAA00 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 21 # set the X coordinate for this line
    addi $a1, $zero, 15 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0xAAAA00 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1
    

    addi $a0, $zero, 21 # set the X coordinate for this line
    addi $a1, $zero, 16 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0xAAAA00 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 24 # set the X coordinate for this line
    addi $a1, $zero, 16 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0xAAAA00 #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1


    #Drawing the BLUE virus  

    addi $a0, $zero, 25 # set the X coordinate for this line
    addi $a1, $zero, 8 # set the Y coordinate for this line
    addi $a2, $zero, 3, #set the length of the line
    addi $a3, $zero, 0x0000AA #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 25 # set the X coordinate for this line
    addi $a1, $zero, 9 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0x0000AA #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 27 # set the X coordinate for this line
    addi $a1, $zero, 9 # set the Y coordinate for this line
    addi $a2, $zero, 1, #set the length of the line
    addi $a3, $zero, 0x0000AA #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 24 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 5, #set the length of the line
    addi $a3, $zero, 0x0000AA #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 24 # set the X coordinate for this line
    addi $a1, $zero, 10 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0x0000AA #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1
    

    addi $a0, $zero, 24 # set the X coordinate for this line
    addi $a1, $zero, 11 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0x0000AA #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1

    addi $a0, $zero, 27 # set the X coordinate for this line
    addi $a1, $zero, 11 # set the Y coordinate for this line
    addi $a2, $zero, 2, #set the length of the line
    addi $a3, $zero, 0x0000AA #set the color of the line
    jal line_draw_horizontal #draw a HORIZONTAL line of length $a2 at $a0,$a1



  #POP FROM STACK 
  
  lw $ra, 0($sp)
  lw $a0, 4($sp)
  lw $a1, 8($sp)
  lw $a2, 12($sp)
  lw $a3, 16($sp)
  addi $sp, $sp, 20
  jr $ra
  

####################################################################################
# CHECKING 4 IN A ROW HORIZONTAL
##################################################################################

four_in_a_row_horizontal:
  #USE STACK POINTERS
  addi $sp, $sp, -48
  sw $t0, 0($sp)
  sw $t1, 4($sp)
  sw $t2, 8($sp)
  sw $t3, 12($sp)
  sw $t4, 16($sp)
  sw $t5, 20($sp)
  sw $t6, 24($sp)
  sw $t7, 28($sp)
  sw $a0, 32($sp)
  sw $a1, 36($sp)
  sw $a2, 40($sp)
  sw $a3, 44($sp)

  li $t0, 1 # Loop counter for inner loop (X)
  li $t1, 9 # Loop counter for outer loop (Y)
  li $t2, 13 # Max inner loop value
  li $t3, 30 # Max outer loop value
  la $t4, grid #t4 stores address of the grid
  # t5 stores the horizontal offset
  # t6 stores the vertical offset
  # t7 stores the address of the current pixel
  # v0 stores the color 3 (black) in fourin arow found
  # a0 stores current pixel color
  # a1 stores current pixel + 1 color
  # a2 stores current pixel + 2 color
  # a3 stores current pixel + 3 color


  four_in_a_row_outer_horizontal_loop: #iterate thru each row
    
    four_in_a_row_inner_horizontal_loop: #iterate thru each element from x = 1 to x= 13

          
      # calculate address of pixel in grid at $t7
    
      addi $t5, $t0, -1
      mul $t5, $t5, 4 #calculate horizontal offset of capsule in grid
    
      addi $t6, $t1, -9
      mul $t6, $t6, 64 #calculate vertical offset of capsule in grid
    
      add $t7, $t5, $t4 # add the horizontal offset of the pixel to grid address
      add $t7, $t7, $t6 # add the vertical offset of the pixel to grid address

      
      
      lw $a0, 0($t7) #load the color of the current pixel 
      lw $a1, 4($t7) #load the color of the current pixel + 1
      lw $a2, 8($t7) #load the color of the current pixel + 2
      lw $a3, 12($t7) #load the color of the current pixel + 3

      beq $a0, 3, four_in_a_row_not_found #the color is black so no four in a row
      beq $a0, 4, four_in_a_row_not_found #the color is white so no four in a row
      bne $a0, $a1, four_in_a_row_not_found
      bne $a1, $a2, four_in_a_row_not_found
      bne $a2, $a3, four_in_a_row_not_found

      #FOUR IN A ROW FOUND

      j four_in_a_row_found


      four_in_a_row_not_found:
        addi $t0, $t0, 1 #incrememnt the inner counter
        ble $t0, $t2, four_in_a_row_inner_horizontal_loop #check if the inner counter is equal to the max value


      # WE HAVE ITERATED THRU THE INNER LOOP A MAX AMOUNT OF TIMES NOW WE INCRWMWNT OUTER LOOP

      addi $t1, $t1, 1 #increment the outer counter
      li $t0, 1 #reset $t0 (X)
      ble $t1, $t3, four_in_a_row_inner_horizontal_loop #check if the inner counter is equal to the max value

      
      lw $t0, 0($sp)
      lw $t1, 4($sp)
      lw $t2, 8($sp)
      lw $t3, 12($sp)
      lw $t4, 16($sp)
      lw $t5, 20($sp)
      lw $t6, 24($sp)
      lw $t7, 28($sp)
      lw $a0, 32($sp)
      lw $a1, 36($sp)
      lw $a2, 40($sp)
      lw $a3, 44($sp)
      addi $sp, $sp, 48

      jr $ra # return to game_loop

      
      
 
four_in_a_row_found: #NEED TO PAINT THE 4 THAT WE FOUND
                       # NEED TO SET THE GRID VALUES TO 3

      #The four we have found starts at ($t0, $t1) so paint a horizontal line of 4 starting from there with the color of the pixel


      #SET THE GRID FOR THESE FOUR BLOCKS TO 4
      
      li $v0, 3
      sw $v0, 0($t7) #set the color of the current pixel to 3 (black)
      sw $v0, 4($t7) #load the color of the current pixel + 1
      sw $v0, 8($t7) #load the color of the current pixel + 2
      sw $v0, 12($t7) #load the color of the current pixel + 3 
      
      
      move $a0, $t0 # set the x-coordinate of the line to draw
      move $a1, $t1 # set the y-coordinate of the line to draw
      li $a2, 4# set the length of the line to draw
      li $a3, 0x000000 # set the color of the line to draw
      lw $s0, ADDR_DSPL


      addi $sp, $sp, -4
      sw $ra, 0($sp)
      
      jal line_draw_horizontal
      jal drop_unsupported_capsules

      lw $ra, 0($sp)
      addi $sp, $sp, 4

      
      
      

      lw $t0, 0($sp)
      lw $t1, 4($sp)
      lw $t2, 8($sp)
      lw $t3, 12($sp)
      lw $t4, 16($sp)
      lw $t5, 20($sp)
      lw $t6, 24($sp)
      lw $t7, 28($sp)
      lw $a0, 32($sp)
      lw $a1, 36($sp)
      lw $a2, 40($sp)
      lw $a3, 44($sp)
      addi $sp, $sp, 48

      jr $ra #return to game_loop




####################################################################################
# CHECKING 4 IN A ROW VERTICAL
##################################################################################
    
  four_in_a_row_vertical:
  #USE STACK POINTERS
  addi $sp, $sp, -48
  sw $t0, 0($sp)
  sw $t1, 4($sp)
  sw $t2, 8($sp)
  sw $t3, 12($sp)
  sw $t4, 16($sp)
  sw $t5, 20($sp)
  sw $t6, 24($sp)
  sw $t7, 28($sp)
  sw $a0, 32($sp)
  sw $a1, 36($sp)
  sw $a2, 40($sp)
  sw $a3, 44($sp)

  li $t0, 9 # Loop counter for inner loop (Y)
  li $t1, 1 # Loop counter for outer loop (X)
  li $t2, 27 # Max inner loop value (Y)
  li $t3, 16 # Max outer loop value (X)
  la $t4, grid #t4 stores address of the grid
  # t5 stores the horizontal offset
  # t6 stores the vertical offset
  # t7 stores the address of the current pixel
  # v0 stores the color 3 (black) in fourin arow found
  # a0 stores current pixel color
  # a1 stores current pixel + 1 color
  # a2 stores current pixel + 2 color
  # a3 stores current pixel + 3 color


  four_in_a_row_outer_vertical_loop: #iterate thru each row
    
    four_in_a_row_inner_vertical_loop: #iterate thru each element from x = 1 to x= 13

          
      # calculate address of pixel in grid at $t7
    
      addi $t5, $t1, -1
      mul $t5, $t5, 4 #calculate horizontal offset of capsule in grid
    
      addi $t6, $t0, -9
      mul $t6, $t6, 64 #calculate vertical offset of capsule in grid
    
      add $t7, $t5, $t4 # add the horizontal offset of the pixel to grid address
      add $t7, $t7, $t6 # add the vertical offset of the pixel to grid address

      
      
      lw $a0, 0($t7) #load the color of the current pixel 
      lw $a1, 64($t7) #load the color of the current pixel + 1 below
      lw $a2, 128($t7) #load the color of the current pixel + 2 below
      lw $a3, 192($t7) #load the color of the current pixel + 3 below

      beq $a0, 3, four_in_a_row_not_found_vertical #the color is black so no four in a row
      beq $a0, 4, four_in_a_row_not_found_vertical #the color is white so no four in a row
      bne $a0, $a1, four_in_a_row_not_found_vertical
      bne $a1, $a2, four_in_a_row_not_found_vertical
      bne $a2, $a3, four_in_a_row_not_found_vertical

      #FOUR IN A ROW FOUND

      j four_in_a_row_found_vertical


      four_in_a_row_not_found_vertical:
        addi $t0, $t0, 1 #incrememnt the inner counter
        ble $t0, $t2, four_in_a_row_inner_vertical_loop #check if the inner counter is equal to the max value


      # WE HAVE ITERATED THRU THE INNER LOOP A MAX AMOUNT OF TIMES NOW WE INCRWMWNT OUTER LOOP

      addi $t1, $t1, 1 #increment the outer counter
      li $t0, 9 #reset $t0 (Y)
      ble $t1, $t3, four_in_a_row_inner_vertical_loop #check if the inner counter is equal to the max value

      
      lw $t0, 0($sp)
      lw $t1, 4($sp)
      lw $t2, 8($sp)
      lw $t3, 12($sp)
      lw $t4, 16($sp)
      lw $t5, 20($sp)
      lw $t6, 24($sp)
      lw $t7, 28($sp)
      lw $a0, 32($sp)
      lw $a1, 36($sp)
      lw $a2, 40($sp)
      lw $a3, 44($sp)
      addi $sp, $sp, 48

      jr $ra #return to game_loop

      
      #HAVE TO RETURN SOMEWHERE
  





      
four_in_a_row_found_vertical: #NEED TO PAINT THE 4 THAT WE FOUND
                       # NEED TO SET THE GRID VALUES TO 3

      #The four we have found starts at ($t0, $t1) so paint a horizontal line of 4 starting from there with the color of the pixel


      #SET THE GRID FOR THESE FOUR BLOCKS TO 4
      
      li $v0, 3
      sw $v0, 0($t7) #set the color of the current pixel to 3 (black)
      sw $v0, 64($t7) #load the color of the current pixel + 1 below
      sw $v0, 128($t7) #load the color of the current pixel + 2 below
      sw $v0, 192($t7) #load the color of the current pixel + 3 below
      
      
      move $a0, $t1 # set the x-coordinate of the line to draw
      move $a1, $t0 # set the y-coordinate of the line to draw
      li $a2, 4# set the length of the line to draw
      li $a3, 0x000000 # set the color of the line to draw
      lw $s0, ADDR_DSPL


      addi $sp, $sp, -4
      sw $ra, 0($sp)
      
      jal line_draw_vertical

      jal drop_unsupported_capsules

      lw $ra, 0($sp)
      addi $sp, $sp, 4


      

      
      
      
      lw $t0, 0($sp)
      lw $t1, 4($sp)
      lw $t2, 8($sp)
      lw $t3, 12($sp)
      lw $t4, 16($sp)
      lw $t5, 20($sp)
      lw $t6, 24($sp)
      lw $t7, 28($sp)
      lw $a0, 32($sp)
      lw $a1, 36($sp)
      lw $a2, 40($sp)
      lw $a3, 44($sp)
      addi $sp, $sp, 48
      

      jr $ra #return to game_loop  
    

####################################################################################
# Dr. Mario Theme Song
####################################################################################

play_theme_song:
    #using stack pointers
    addi $sp, $sp, -36
    sw $ra, 0($sp)
    sw $t0, 4($sp)
    sw $t1, 8($sp)
    sw $t2, 12($sp)
    sw $v0, 16($sp)
    sw $a0, 20($sp)
    sw $a1, 24($sp)
    sw $a2, 28($sp)
    sw $a3, 32($sp)
  

    # Load current step in guitar
    la $t0, sound_step
    lw $t1, 0($t0)

    # Play Guitar
    la $t0, fever_guitar # t0 is the address of the guitar
    mul $t2, $t1, 4 # calculates the offset of our current 'step' in guitar
    add $t0, $t0, $t2 # t0 stores the address of the pitch of our current step 
    lw $t2, 0($t0) # t2 stores the value of the pitch of our current step

    move $a0, $t2   # Pitch
    li $a1, 200     # Duration
    li $a2, 5       # Instrument (Guitar)
    li $a3, 2      # Volume
    li $v0, 31
    syscall

    # Play Organ
    la $t0, fever_organ # t0 is the address of our organ
    div $t1, $t2  # $t1 / $t2
    mul $t2, $t1, 4 # calculates the offset of our current 'step' in organ
    add $t0, $t0, $t2 # t0 stores the address of the pitch of our current step
    lw $t2, 0($t0) # t2 stores the value of the pitch of our current step

    move $a0, $t2   
    li $a1, 200     
    li $a2, 2       # Instrument (Organ)
    li $a3, 2      
    li $v0, 31
    syscall


    # increment to next step in the melody
    la $t0, sound_step
    lw $t1, 0($t0)
    addi $t1, $t1, 1

    # Check if we've reached the end of the melody
    la $t0, fever_guitar_count
    lw $t2, 0($t0) 
    blt $t1, $t2, save_step #if our current step is less than the total guitar notes then we increment our step. if not we reset the melody

    # Reset to beginning of melody
    li $t1, 0

save_step:
    la $t0, sound_step
    sw $t1, 0($t0) #update our current 'step'

end_play_theme:
    
    lw $ra, 0($sp)
    lw $t0, 4($sp)
    lw $t1, 8($sp)
    lw $t2, 12($sp)
    lw $v0, 16($sp)
    lw $a0, 20($sp)
    lw $a1, 24($sp)
    lw $a2, 28($sp)
    lw $a3, 32($sp)
    
    addi $sp, $sp, 36
    jr $ra


####################################################################################
 # CAPSULE DROPPING LOGIC
####################################################################################

drop_unsupported_capsules:
  # SAVING REGISTERS ON STACK
  addi $sp, $sp, -28
  sw $ra, 0($sp)
  sw $s0, 4($sp)
  sw $s1, 8($sp)
  sw $s2, 12($sp)
  sw $s3, 16($sp)
  sw $s4, 20($sp)
  sw $s5, 24($sp)
  
  li $s5, 5  # Max iterations
  li $s4, 1  # $s4 stores if capsule dropped in current iteration
  li $s3, 0  # iteration count
  
iteration_loop:
  beq $s3, $s5, drop_done  # end loop if max iterations
  beqz $s4, drop_done      # end loop if flag empty for this iteration
  
  li $s4, 0  # Resetting flag for this iteration
  addi $s3, $s3, 1  # i++
  
  
  li $s0, 29  # start from bottom of bottle
  
row_check:
  blt $s0, 10, end_of_check  # stop at top of bottle 
  li $s1, 1  # start from left side
  
column_check:
  bgt $s1, 16, next_row_check  # move to next row if end of columns
  
  la $s2, grid
  
  #horizontal offset
  addi $t0, $s1, -1
  mul $t0, $t0, 4
  add $s2, $s2, $t0
  
  # vertical offset
  addi $t0, $s0, -9
  mul $t0, $t0, 64
  add $s2, $s2, $t0
  
 
  lw $t0, 0($s2)
  
  # Skip if empty (3), wall (4) or not a piece
  beq $t0, 3, next_column_check
  beq $t0, 4, next_column_check
  

  jal check_for_virus 
  bnez $v0, next_column_check  # viruses don't drop so skip
  
  jal check_piece_support
  
  bnez $v0, next_column_check  
  
  # otherwise, find how far to drop
  jal find_drop_distance
  
  # If drop distance > 0, drop the piece
  beqz $v0, next_column_check
  
  # $v0 contains drop distance
  # $s2 contains current position address
  
  # Store original color
  move $t8, $t0
  
  # Calculate new position
  mul $t1, $v0, 64  
  add $t2, $s2, $t1  
  
  
  sw $t8, 0($t2) # move the piece
  li $t3, 3
  sw $t3, 0($s2)  # clear original cell
  
  # Update display and clear the old cell
  jal clear_display_at_position
  
  add $t4, $s0, $v0  # New row = old row + drop distance
  move $a0, $s1
  move $a1, $t4
  move $a2, $t8
  jal draw_at_position
  
  li $s4, 1  # Set change flag to true
  
next_column_check:
  addi $s1, $s1, 1  # Move to next column
  j column_check
  
next_row_check:
  addi $s0, $s0, -1  # Move to row above
  j row_check
  
end_of_check:
  # changes were made, so another iteration
  bgtz $s4, iteration_loop
  
drop_done:
  # Check for matches formed after dropping pieces
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  jal four_in_a_row_horizontal
  jal four_in_a_row_vertical
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  
  # Restore registers
  lw $ra, 0($sp)
  lw $s0, 4($sp)
  lw $s1, 8($sp)
  lw $s2, 12($sp)
  lw $s3, 16($sp)
  lw $s4, 20($sp)
  lw $s5, 24($sp)
  addi $sp, $sp, 28
  
  jr $ra

# Helper function: check if current position contains a virus
# Inputs are: $s0 = row, $s1 = column
# Output: $v0 = 1 if virus, 0 if not
check_for_virus:
  addi $sp, $sp, -16
  sw $t0, 0($sp)
  sw $t1, 4($sp)
  sw $t2, 8($sp)
  sw $ra, 12($sp)
  
  li $v0, 0  # Default: not a virus
  
  la $t0, viruses  # Virus array
  li $t1, 0  # Counter
  li $t2, 12  # Max viruses

# iterate until max viruses
virus_check_loop:
  beq $t1, $t2, virus_check_done
  
  # Get virus coordinates
  mul $t3, $t1, 12  # virus is 12 bytes
  add $t3, $t0, $t3
  
  lw $t4, 0($t3)  # Virus X
  lw $t5, 4($t3)  # Virus Y
  
  # Check if coordinates match
  bne $t4, $s1, next_virus_check
  bne $t5, $s0, next_virus_check
  
  # match found, it's a virus
  li $v0, 1
  j virus_check_done
  
next_virus_check:
  addi $t1, $t1, 1
  j virus_check_loop
  
virus_check_done:
  lw $t0, 0($sp)
  lw $t1, 4($sp)
  lw $t2, 8($sp)
  lw $ra, 12($sp)
  addi $sp, $sp, 16
  
  jr $ra

# Helper function: check if a piece has support
# Input: $s2 = piece address in grid, $s1 = column, $s0 = row
# Output: $v0 = 1 if has support, 0 if not
check_piece_support:
  addi $sp, $sp, -12
  sw $t0, 0($sp)
  sw $t1, 4($sp)
  sw $ra, 8($sp)
  
  # Check direct support below
  lw $t0, 64($s2)  # Load what's below
  bne $t0, 3, piece_has_support  # If not empty, support below

  # reached here means we need to check right and left support
  # check right side
  lw $t0, 4($s2)  
  beq $t0, 3, check_left_support  # If empty, check left
  beq $t0, 4, check_left_support  # If wall, check left
  
  # otehrwise, check if right has support
  lw $t1, 68($s2)  
  bne $t1, 3, piece_has_support  # piece is supported by right's support

# no right and bottom support so check left
check_left_support:
  lw $t0, -4($s2)  
  beq $t0, 3, no_support  # empty, no support
  beq $t0, 4, no_support  # wall, no support
  
  # otherwise there's something to the left so check if the left has support
  lw $t1, 60($s2)  
  bne $t1, 3, piece_has_support  # piece's left pixel is supported, so piece is supported 
  
no_support:
  li $v0, 0  # No support found
  j check_support_done
  
piece_has_support:
  li $v0, 1  # Support found
  
check_support_done:
  lw $t0, 0($sp)
  lw $t1, 4($sp)
  lw $ra, 8($sp)
  addi $sp, $sp, 12
  
  jr $ra

# Helper function: find how far a piece can drop
# Input: $s2 = piece address in grid, $s0 = current row
# Output: $v0 = drop distance (0 if can't drop)
find_drop_distance:
  addi $sp, $sp, -12
  sw $t0, 0($sp)
  sw $t1, 4($sp)
  sw $ra, 8($sp)
  
  li $v0, 0  # Default: can't drop
  li $t0, 1  # Initial drop distance to check
  
drop_distance_loop:
  add $t1, $s0, $t0  # Row to check = current row + drop distance
  bgt $t1, 30, drop_distance_done
  
  mul $t2, $t0, 64  
  add $t3, $s2, $t2  # Address to check piece
  
  lw $t4, 0($t3)  
  bne $t4, 3, drop_distance_done  # Stop if collision detected
  
  move $v0, $t0  # Update drop distance
  addi $t0, $t0, 1  # i++
  j drop_distance_loop
  
drop_distance_done:
  lw $t0, 0($sp)
  lw $t1, 4($sp)
  lw $ra, 8($sp)
  addi $sp, $sp, 12
  
  jr $ra

# Helper function: clear display at current position
# Input: $s1 = column, $s0 = row
clear_display_at_position:
  addi $sp, $sp, -12
  sw $t0, 0($sp)
  sw $t1, 4($sp)
  sw $ra, 8($sp)
  
  lw $t0, ADDR_DSPL
  
  sll $t1, $s1, 2  # Calculate horizontal offset
  add $t0, $t0, $t1
  
  sll $t1, $s0, 7  # Calculate vertical offset
  add $t0, $t0, $t1
  
  li $t1, 0x000000  # draw it black to clear
  sw $t1, 0($t0)
  
  lw $t0, 0($sp)
  lw $t1, 4($sp)
  lw $ra, 8($sp)
  addi $sp, $sp, 12
  
  # restore registers
  
  jr $ra

# Helper function: draw pixel at given position
# Input: $a0 = column, $a1 = row, $a2 = color index
draw_at_position:
  addi $sp, $sp, -16
  sw $t0, 0($sp)
  sw $t1, 4($sp)
  sw $t2, 8($sp)
  sw $ra, 12($sp)
  
  lw $t0, ADDR_DSPL
  
  sll $t1, $a0, 2  #  horizontal offset
  add $t0, $t0, $t1
  
  sll $t1, $a1, 7  # vertical offset
  add $t0, $t0, $t1
  
  # drawing pixel with color based on index
  li $t2, 0xFF0000  # Red
  beq $a2, 0, draw_pixel
  
  li $t2, 0xFFFF00  # Yellow
  beq $a2, 1, draw_pixel
  
  li $t2, 0x0000FF  # Blue
  beq $a2, 2, draw_pixel
  
draw_pixel:
  sw $t2, 0($t0)  # Draw the pixel
  
  lw $t0, 0($sp)
  lw $t1, 4($sp)
  lw $t2, 8($sp)
  lw $ra, 12($sp)
  addi $sp, $sp, 16
  
  # RESTORING REGISTERS
  
  jr $ra

##############################################################################
# End of Code
##############################################################################
