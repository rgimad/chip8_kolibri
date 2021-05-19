#### High priority:
- implement all commands marked as TODO
- manually check their correctness
- ~~add unknown_opcode(x) function~~
- ~~add rand() simple implementation~~
- ~~add chip8_tick() function~~
- ~~add main cycle\
  using sysfn 23 wait event with timeout 0.05 sec,\
  check which event,\
  if event none, then check how much time passed since the previous tick,\
  if passed >= CLOCK_MS then make tick and redraw if redraw flag is up (if so, redraw and set flag down after redraw) (?)~~
- ~~add drawing procedure, which renders gfx array to the actual scren~~
- add missing opcodes implementation !!!
- add keyboard processing:\
  in main cycle process also keyboard events: keydown and keyup\
  on keydown mark key with 1 in array, on keyup mark with 0

#### Low priority:
- in commands 5xy0, 9xy0 need to check if last digit is 0 or not
- add debug output for each command
- add more comments
