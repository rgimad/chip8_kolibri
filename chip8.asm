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


include '../../macros.inc'
purge   mov, add, sub

include '../../debug-fdo.inc'
include '../../proc32.inc'

;=========================================

align 4
start:
        DEBUGF  DBG_INFO, "app started, args = %s\n", cmdline
        DEBUGF  DBG_INFO, "MAX_GAME_SIZE = %x = %u\n", MAX_GAME_SIZE, MAX_GAME_SIZE
if 0
        xor     ecx, ecx
@@:
        mov     al, byte [chip8_fontset + ecx]
        DEBUGF  DBG_INFO, "%x ", al
        cmp     ecx, 79
        je      @f
        inc     ecx
        jmp     @b
@@:
end if

.chip_init:
        mov     word [P_C], 0x200
        mov     word [opcode], 0
        mov     word [I], 0
        mov     word [S_P], 0

        ;DEBUGF  DBG_INFO, "ESP = %x\n", esp
        stdcall _memset, memory, 0, MEM_SIZE
        stdcall _memset, V, 0, 16
        stdcall _memset, gfx, 0, GFX_SIZE
        stdcall _memset, stackmem, 0, 2*STACK_SIZE ; 2 = sizeof(dw)
        stdcall _memset, key, 0, KEY_SIZE
        ;DEBUGF  DBG_INFO, "ESP = %x\n", esp

        xor     ecx, ecx
@@:
        cmp     ecx, 80
        jge     @f
        mov     al, byte [chip8_fontset + ecx]
        mov     byte [memory + FONTSET_ADDRESS + ecx], al
        inc     ecx
        jmp     @b
@@:
        mov     byte [chip8_draw_flag], 1
        mov     byte [delay_timer], 0
        mov     byte [sound_timer], 0
        ; TODO: srand(time(NULL)) here

.chip8_loadgame:
        mov     dword [fread_struct.filename], cmdline
        mov     eax, 70
        mov     ebx, fread_struct
        int     0x40

        cmp     eax, 0
        je      @f
        cmp     eax, 6
        je      @f
        jmp     .load_fail
@@:
        DEBUGF  DBG_INFO, "file was read. bytes: %x %x %x..", [memory + 0x200], [memory + 0x200 + 4], [memory + 0x200 + 8]
        jmp     .exit

.load_fail:
        DEBUGF  DBG_ERR, "Unable to open game file! eax = %u\n", eax

.exit:
        mov     eax, -1
        int     0x40


; note: proc that defines without stdcall, call using "call"

align 4
proc chip8_emulatecycle
        locals
          x     db ?
          y     db ?
          n     db ?
          kk    db ?
          nnn   dw ?
        endl
        ; fetch:
        movzx   ecx, word [P_C]
        movzx   ax, byte [memory + ecx]
        shl     ax, 8
        movzx   bx, byte [memory + 1 + ecx]
        or      ax, bx
        mov     word [opcode], ax

        shr     ax, 8
        and     ax, 0x000F
        mov     byte [x], al

        mov     ax, word [opcode]
        shr     ax, 4
        and     ax, 0x000F
        mov     byte [y], al

        mov     ax, word [opcode]
        and     ax, 0x000F
        mov     byte [n], al

        mov     ax, word [opcode]
        and     ax, 0x00FF
        mov     byte [kk], al

        mov     ax, word [opcode]
        and     ax, 0x0FFF
        mov     word [nnn], ax

        DEBUGF  DBG_INFO, "P_C: 0x%x Op: 0x%x\n", word [P_C], word [opcode]
        ; TODO test this and watch values of x, y, n, kk, nnn

        ; decode & execute
        ; sw1
        mov     ax, word [opcode]
        and     ax, 0xF000

        cmp     ax, 0x0000
        je      .sw1_case_0000

        cmp     ax, 0x1000
        je      .sw1_case_1000

        cmp     ax, 0x2000
        je      .sw1_case_2000

        cmp     ax, 0x3000
        je      .sw1_case_3000

        cmp     ax, 0x4000
        je      .sw1_case_4000

        cmp     ax, 0x5000
        je      .sw1_case_5000

        cmp     ax, 0x6000
        je      .sw1_case_6000

        cmp     ax, 0x7000
        je      .sw1_case_7000

        cmp     ax, 0x8000
        je      .sw1_case_8000

        cmp     ax, 0x9000
        je      .sw1_case_9000

        cmp     ax, 0xA000
        je      .sw1_case_A000

        cmp     ax, 0xB000
        je      .sw1_case_B000

        cmp     ax, 0xC000
        je      .sw1_case_C000

        cmp     ax, 0xD000
        je      .sw1_case_D000

        cmp     ax, 0xE000
        je      .sw1_case_E000

        cmp     ax, 0xF000
        je      .sw1_case_F000

        jmp     .sw1_default

.sw1_case_0000:
        ; sw2
        cmp    byte [kk], 0xE0 
        je     .sw2_case_E0

        cmp    byte [kk], 0xEE
        je     .sw2_case_EE

        jmp    .sw2_default

        .sw2_case_E0: ; clear the screen
            stdcall _memset, gfx, 0, GFX_SIZE
            mov     byte [chip8_draw_flag], 1
            add     word [P_C], 2
            jmp     .sw2_end

        .sw2_case_EE: ; ret
            dec     word [S_P]
            movzx   ecx, word [S_P]
            mov     ax, word [stackmem + ecx*2]
            mov     word [P_C], ax
            jmp     .sw2_end

        .sw2_default:
            ; unknown opcode !
        .sw2_end:
        jmp     .sw1_end

.sw1_case_1000: ; 1nnn: jump to address nnn
        mov     ax, word [nnn]
        mov     word [P_C], ax
        jmp     .sw1_end

.sw1_case_2000: ; 2nnn: call address nnn
        mov     ax, word [P_C]
        add     ax, 2
        movzx   ecx, word [S_P]
        mov     word [stackmem + ecx*2], ax
        inc     word [S_P]
        mov     ax, word [nnn]
        mov     word [P_C], ax
        jmp     .sw1_end

.sw1_case_3000: ; 3xkk: skip next instr if V[x] = kk
        movzx   ecx, byte [x]
        mov     al, byte [V + ecx]
        mov     bl, byte [kk]
        mov     cx, 2
        cmp     al, bl
        jne     @f
        mov     cx, 4
@@:
        add     word [P_C], cx
        jmp     .sw1_end

.sw1_case_4000: ; 4xkk: skip next instr if V[x] != kk
        movzx   ecx, byte [x]
        mov     al, byte [V + ecx]
        mov     bl, byte [kk]
        mov     cx, 2
        cmp     al, bl
        je     @f
        mov     cx, 4
@@:
        add     word [P_C], cx
        jmp     .sw1_end

.sw1_case_5000: ; 5xy0: skip next instr if V[x] == V[y]
        movzx   ecx, byte [x]
        mov     al, byte [V + ecx]
        movzx   ecx, byte [y]
        mov     bl, byte [V + ecx]
        mov     cx, 2
        cmp     al, bl
        jne     @f
        mov     cx, 4
@@:
        add     word [P_C], cx
        jmp     .sw1_end

.sw1_case_6000: ; 6xkk: set V[x] = kk
        movzx   ecx, byte [x]
        mov     bl, byte [kk]
        mov     byte [V + ecx], bl
        add     word [P_C], 2
        jmp     .sw1_end

.sw1_case_7000: ; 7xkk: set V[x] = V[x] + kk
        movzx   ecx, byte [x]
        mov     bl, byte [kk]
        add     byte [V + ecx], bl
        add     word [P_C], 2
        jmp     .sw1_end

.sw1_case_8000: ; 8xyn: Arithmetic stuff
        ; sw3
        cmp     byte [n], 0x0
        je      .sw3_case_0

        cmp     byte [n], 0x1
        je      .sw3_case_1

        cmp     byte [n], 0x2
        je      .sw3_case_2

        cmp     byte [n], 0x3
        je      .sw3_case_3

        cmp     byte [n], 0x4
        je      .sw3_case_4

        cmp     byte [n], 0x5
        je      .sw3_case_5

        cmp     byte [n], 0x6
        je      .sw3_case_6

        cmp     byte [n], 0x7
        je      .sw3_case_7

        cmp     byte [n], 0xE
        je      .sw3_case_E

        jmp     .sw3_default

        .sw3_case_0: ; V[x] = V[y]
            movzx   ecx, byte [x]
            movzx   edx, byte [y]
            mov     al, byte [V + edx]
            mov     byte [V + ecx], al
            jmp     .sw3_end

        .sw3_case_1: ; V[x] = V[x] | V[y]
            movzx   ecx, byte [x]
            movzx   edx, byte [y]
            mov     al, byte [V + ecx]
            or      al, byte [V + edx]
            mov     byte [V + ecx], al
            jmp     .sw3_end

        .sw3_case_2: ; V[x] = V[x] & V[y]
            movzx   ecx, byte [x]
            movzx   edx, byte [y]
            mov     al, byte [V + ecx]
            and      al, byte [V + edx]
            mov     byte [V + ecx], al
            jmp     .sw3_end

        .sw3_case_3: ; V[x] = V[x] ^ V[y]
            movzx   ecx, byte [x]
            movzx   edx, byte [y]
            mov     al, byte [V + ecx]
            xor     al, byte [V + edx]
            mov     byte [V + ecx], al
            jmp     .sw3_end

        .sw3_case_4: ; V[x] = V[x] + V[y]; if carry, move 1 to V[0xF]
            movzx   ecx, byte [x]
            movzx   edx, byte [y]
            movzx   ax, byte [V + ecx]
            movzx   bx, byte [V + edx]
            add     ax, bx
            mov     byte [V + ecx], al

            xor     cl, cl 
            cmp     ax, 255
            jbe     @f
            inc     cl
        @@:
            mov     byte [V + 0xF], cl 
            jmp     .sw3_end

        .sw3_case_5: ;TODO check; V[x] = V[x] - V[y]; if no borrow, move 1 to V[0xF]
            movzx   ecx, byte [x]
            movzx   edx, byte [y]
            mov     al, byte [V + ecx]
            mov     bl, byte [V + edx]
            sub     al, bl
            mov     byte [V + ecx], al

            xor     cl, cl
            cmp     al, bl
            jbe     @f
            inc     cl
        @@:
            mov     byte [V + 0xF], cl
            jmp     .sw3_end

        .sw3_case_6: ; TODO check; V[x] = V[x] SHR 1 ; V[0xF] = least-significant bit of V[x] before shift
            movzx   ecx, byte [x]
            mov     al, byte [V + ecx]
            and     al, 0x01
            mov     byte [V + 0xF], al
            shr     byte [V + ecx], 1
            jmp     .sw3_end

        .sw3_case_7: ; TODO check; V[x] = V[y] - V[x]; if no borrow, move 1 to V[0xF]
            movzx   ecx, byte [y]
            movzx   edx, byte [x]
            mov     al, byte [V + ecx]
            mov     bl, byte [V + edx]
            sub     al, bl
            mov     byte [V + ecx], al

            xor     cl, cl
            cmp     al, bl
            jbe     @f
            inc     cl
        @@:
            mov     byte [V + 0xF], cl
            jmp     .sw3_end

        .sw3_case_E: ; TODO check; V[0xF] = most-significant bit of V[x] before shift
            movzx   ecx, byte [x]
            mov     al, byte [V + ecx]
            shr     al, 7
            and     al, 0x01
            mov     byte [V + 0xF], al
            shl     byte [V + ecx], 1
            jmp     .sw3_end

        .sw3_default:
            ; unknown opcode !

        .sw3_end:
        add     word [P_C], 2
        jmp     .sw1_end

.sw1_case_9000: ; 9xy0: skip instruction if V[x] != V[y]
        ;
        jmp     .sw1_end

.sw1_case_A000: ; Annn: set I to address nnn
        mov     ax, word [nnn]
        mov     word [I], ax
        add     word [P_C], 2
        jmp     .sw1_end

.sw1_case_B000: ; Bnnn: jump to location nnn + V[0]
        mov     ax, word [nnn]
        movzx   bx, byte [V]
        add     ax, bx
        mov     word [P_C], ax
        jmp     .sw1_end

.sw1_case_C000: ; Cxkk: V[x] = random byte AND kk
        ;
        jmp     .sw1_end

.sw1_case_D000:
        ;
        jmp     .sw1_end

.sw1_case_E000:
        ;
        jmp     .sw1_end

.sw1_case_F000:
        ;
        jmp     .sw1_end

.sw1_default:
        ; unknown opcode !

.sw1_end:
        ret
endp

align 4
proc _memset stdcall, dest:dword, val:byte, cnt:dword
        ;DEBUGF  DBG_INFO, "memset(%x, %u, %u)\n", [dest], [val], [cnt]
        push    edi
        mov     edi, [dest]
        mov     al,  [val]
        mov     ecx, [cnt]
        rep     stosb   
        pop     edi
        ret 
endp

;=========================================
; initialized data
        include_debug_strings ; for debug-fdo

        chip8_fontset db  \
            0xF0, 0x90, 0x90, 0x90, 0xF0, \  ; 0
            0x20, 0x60, 0x20, 0x20, 0x70, \  ; 1
            0xF0, 0x10, 0xF0, 0x80, 0xF0, \  ; 2
            0xF0, 0x10, 0xF0, 0x10, 0xF0, \  ; 3
            0x90, 0x90, 0xF0, 0x10, 0x10, \  ; 4
            0xF0, 0x80, 0xF0, 0x10, 0xF0, \  ; 5
            0xF0, 0x80, 0xF0, 0x90, 0xF0, \  ; 6
            0xF0, 0x10, 0x20, 0x40, 0x40, \  ; 7
            0xF0, 0x90, 0xF0, 0x90, 0xF0, \  ; 8
            0xF0, 0x90, 0xF0, 0x10, 0xF0, \  ; 9
            0xF0, 0x90, 0xF0, 0x90, 0x90, \  ; A
            0xE0, 0x90, 0xE0, 0x90, 0xE0, \  ; B
            0xF0, 0x80, 0x80, 0x80, 0xF0, \  ; C
            0xE0, 0x90, 0x90, 0x90, 0xE0, \  ; D
            0xF0, 0x80, 0xF0, 0x80, 0xF0, \  ; E
            0xF0, 0x80, 0xF0, 0x80, 0x80     ; F 

        opcode  dw 0          ; operation code
        V       db 16 dup(0)  ; 16 8-bit registers
        I       dw 0          ; additional register (usually used for storing addresses)
        P_C     dw 0          ; program counter
        S_P     dw 0          ; stack pointer
        delay_timer db 0
        sound_timer db 0
        stackmem    dw STACK_SIZE dup(0)  ; stack memory
        key         db KEY_SIZE dup (0) ; keyboard
        chip8_draw_flag db 0

        align 4
        fread_struct:
            .subfunction    dd 0
            .offset_low     dd 0
            .offset_high    dd 0
            .size           dd MAX_GAME_SIZE
            .buffer         dd memory + 0x200
                            db 0
            .filename:      dd 0


;=========================================
align 16
_i_end:
; uninitialized data
        cmdline rb 1024 ; reserve for command line arguments

        memory  rb MEM_SIZE
        gfx     rb GFX_SIZE


        rb      4096 ; reserve for stack
align 16
_stacktop:


_mem:
