; draw main window
align 4
proc draw_main_window stdcall
        mcall   12, 1       ; notify about draw beginning
        mcall   48, 3, sys_colors, sizeof.system_colors
       
        mov     edx, [sys_colors.work]         ; background color
        or      edx, 0x33000000                ; window type 3
        DEBUGF  DBG_INFO, "mainwindow w, h  = %u, %u", GFX_COLS*GFX_PIX_SIZE + 20, GFX_ROWS*GFX_PIX_SIZE + 20
        mcall 0, <50, GFX_COLS*GFX_PIX_SIZE + 20>, <50, GFX_ROWS*GFX_PIX_SIZE + 20>, , , main_window_title ; 
 
        mcall 12, 2                  ; notify about draw ending
    ret
endp