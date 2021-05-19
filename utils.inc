; note: proc that defines without stdcall, call using "call"
; note: by stdcall convention callee is responsible for cleaning up the stack,
; arguments are pushed onto the stack in right-to-left order
align 4
proc _memset stdcall, dest:dword, val:byte, cnt:dword ; doesnt clobber any registers
        ;DEBUGF  DBG_INFO, "memset(%x, %u, %u)\n", [dest], [val], [cnt]
        push    eax ecx edi
        mov     edi, dword [dest]
        mov     al,  byte [val]
        mov     ecx, dword [cnt]
        rep     stosb   
        pop     edi ecx eax
        ret 
endp

align 4
proc _srand stdcall, seed:dword
        push    eax
        ;DEBUGF  DBG_INFO, "_srand: next_rand = %u\n", [next_rand]
        mov     eax, dword [seed]
        mov     dword [next_rand], eax
        pop     eax
        ret
endp

align 4
proc _rand stdcall
        push    ebx edx
        ;DEBUGF  DBG_INFO, "_rand: next_rand = %u\n", [next_rand]
        mov     eax, dword [next_rand]
        mov     ebx, 214013
        mul     ebx
        add     eax, 2531011
        mov     dword [next_rand], eax
        shr     eax, 16
        and     eax, 0x7fff
        pop     edx ebx
        ret
endp

align 4
proc _getseed stdcall
        push    edx
        rdtsc
        xor     eax, edx
        pop     edx
        ret
endp
