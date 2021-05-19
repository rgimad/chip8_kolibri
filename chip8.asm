; Author: rgimad (2021)
; License: ?

format binary as ""
use32
org     0
db      'MENUET01'    ; signature
dd      1             ; header version
dd      start         ; entry point
dd      _i_end         ; end of image
dd      _mem          ; required memory size
dd      _stacktop      ; address of stack top
dd      cmdline       ; buffer for command line arguments
dd      0             ; buffer for path

;=========================================
; constants for formatted debug
__DEBUG__       = 1             ; 0 - disable debug output / 1 - enable debug output
__DEBUG_LEVEL__ = DBG_ALL       ; set the debug level
 
DBG_ALL       = 0  ; all messages
DBG_INFO      = 1  ; info and errors
DBG_ERR       = 2  ; only errors

; emulator constants
MAX_GAME_SIZE = 0x1000 - 0x200
FONTSET_ADDRESS = 0x00
FONTSET_BYTES_PER_CHAR = 5
MEM_SIZE = 4096
STACK_SIZE = 16
KEY_SIZE = 16
GFX_ROWS = 32
GFX_COLS = 64
GFX_SIZE = GFX_ROWS * GFX_COLS
GFX_PIX_SIZE = 10


include '../../macros.inc'
purge   mov, add, sub

include '../../debug-fdo.inc'
include '../../proc32.inc'

;=========================================

; application's entry point
align 4
start:
        ; init application heap:
        mov     eax, 68
        mov     ebx, 11
        int     0x40

        ; TODO set keyboard mode (which?)
        ; maybe to chip8_init

        DEBUGF  DBG_INFO, "app started, args = %s\n", cmdline
        DEBUGF  DBG_INFO, "MAX_GAME_SIZE = %x = %u\n", MAX_GAME_SIZE, MAX_GAME_SIZE

;        xor     ecx, ecx
; @@:
;        mov     al, byte [chip8_fontset + ecx]
;        DEBUGF  DBG_INFO, "%x ", al
;        cmp     ecx, 79
;        je      @f
;        inc     ecx
;        jmp     @b
; @@:

        mov     dword [fread_struct.filename], cmdline
        stdcall chip8_loadgame, fread_struct
        jz      .file_not_found

        DEBUGF  DBG_INFO, "file was read. bytes: %x %x %x..", [memory + 0x200], [memory + 0x200 + 4], [memory + 0x200 + 8]
        
        ; allocate memory for emulation thread
        mov     eax, 68
        mov     ebx, 12
        mov     ecx, 4096
        int     0x40
        mov     [emulation_thread_stack_bottom], eax

        ; run emulation in new thread
        mov     eax, 51
        mov     ebx, 1
        mov     ecx, emulation_thread
        mov     edx, [emulation_thread_stack_bottom]
        add     edx, 4092 ; now edx is stack top
        int     0x40

.event_loop:
        mcall   10 ; wait for event

        cmp     eax, 1
        je      .event_redraw

        jmp     .event_other

        .event_redraw:
                stdcall draw_main_window
                jmp     .event_loop

        .event_other:
                ; for other events

        jmp     .event_loop
        

.file_not_found:
        DEBUGF  DBG_ERR, "Unable to open game file! eax = %u\n", eax
        jmp     .exit

.exit:
        mov     eax, -1
        int     0x40

;;;;;;;;;;;;;;;;;;;;;;;


emulation_thread:
        ; TODO: struct timeval clock_now; gettimeofday(&clock_now, NULL);

        stdcall chip8_emulatecycle

        ; TODO: if (chip8_draw_flag) {  draw(); chip8_draw_flag = false; } }

        ; TODO: if (timediff_ms(&clock_now, &clock_prev) >= CLOCK_RATE_MS) { chip8_tick(); clock_prev = clock_now; }

        jmp     emulation_thread

include 'gui.inc'

include 'emu.inc'

include 'utils.inc'

include 'data.inc'
        rb      4096 ; reserve for main thread stack
align 16
_stacktop:

_mem:
