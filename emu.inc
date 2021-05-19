; initalize the emulator
align 4
proc chip8_init stdcall
; destroys: nothing, mb flags
        push    eax ecx
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
        stdcall _getseed
        stdcall _srand, eax

        stdcall _rand
        DEBUGF  DBG_INFO, "rand() = %u\n", eax
        ;stdcall _rand
        ;DEBUGF  DBG_INFO, "rand() = %u\n", eax
        ;stdcall _rand
        ;DEBUGF  DBG_INFO, "rand() = %u\n", eax
        ;stdcall _rand
        ;DEBUGF  DBG_INFO, "rand() = %u\n", eax
        ;stdcall _rand
        ;DEBUGF  DBG_INFO, "rand() = %u\n", eax

        ;mov     word [opcode], 0xBFAF
        ;movzx   eax, word [opcode]
        ;mov     eax, 0xABCDEF92
        ;stdcall unknown_opcode, eax
        ;DEBUGF  DBG_INFO, "testprint\n"
        pop     ecx eax
        ret
endp


; load game from file to memory
align 4
proc chip8_loadgame stdcall, struct_ptr: dword
; in: struct_ptr - pointer to structure for sysfn70
; out: ZF = 1 file loaded successfully
;      ZF = 0 error
; destroys: only flags
        push    eax ebx

        mov     eax, 70
        mov     ebx, [struct_ptr]
        int     0x40

        cmp     eax, 0
        je      @f
        cmp     eax, 6
        je      @f
        jmp     .load_fail
@@:
        mov     eax, 1
        jmp     .ret

.load_fail:
        xor     eax, eax
.ret:
        test    eax, eax
        pop     ebx eax
        ret
endp


; emulate one cycle
align 4
proc chip8_emulatecycle stdcall
; destroys: ?
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

        ;DEBUGF  DBG_INFO, "P_C: 0x%x Op: 0x%x\n",  [P_C],  [opcode] ; was word word
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
            movzx   eax, word [opcode]
            stdcall unknown_opcode, eax
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
            movzx   eax, word [opcode]
            stdcall unknown_opcode, eax

        .sw3_end:
        add     word [P_C], 2
        jmp     .sw1_end

.sw1_case_9000: ; TODO check; 9xy0: skip instruction if V[x] != V[y]
        movzx   ecx, byte [x]
        mov     al, byte [V + ecx]
        movzx   ecx, byte [y]
        mov     bl, byte [V + ecx]
        mov     cx, 2
        cmp     al, bl
        je      @f
        mov     cx, 4
@@:
        add     word [P_C], cx
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

.sw1_case_C000: ; TODO check; Cxkk: V[x] = random byte AND kk
        stdcall _rand
        and     al, byte [kk]
        movzx   ecx, byte [x]
        mov     byte [V + ecx], al
        jmp     .sw1_end

.sw1_case_D000: ; Dxyn: Display an n-byte sprite starting at memory location I at (Vx, Vy) on the screen, VF = collision
        ; TODO
        jmp     .sw1_end

.sw1_case_E000: ; key-pressed events
        ; TODO
        jmp     .sw1_end

.sw1_case_F000: ; misc
        ; TODO
        jmp     .sw1_end

.sw1_default:
        movzx   eax, word [opcode]
        stdcall unknown_opcode, eax

.sw1_end:
        ret
endp


; tick the timers
align 4
proc chip8_tick stdcall
        cmp     byte [delay_timer], 0
        jz      @f
        dec     byte [delay_timer]
@@:
        cmp     byte [sound_timer], 0
        jz      .ret
        dec     byte [sound_timer]
        cmp     byte [sound_timer], 0
        jnz     @f
        DEBUGF  DBG_INFO, "BEEP!\n"
@@:
.ret:
endp


; print unknown opcode error & exit
align 4
proc unknown_opcode stdcall, op:word
        DEBUGF DBG_ERR, "Error: unknown opcode 0x%x\n", [op]:4
        mov     eax, -1
        int     0x40
endp