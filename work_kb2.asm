.286
.model tiny
.code
org 100h


Start:
		mov ax, 3509h
        int 21h
        mov Old09Ofs, bx
        mov bx, es
        mov Old09Seg, bx

		cli
		xor bx, bx
		mov es, bx
		mov bx, 4 * 09h
		mov es:[bx], offset NewInterrupt09

		push cs
		pop ax
		;mov al, 'A'
		mov es:[bx + 2], ax

		sti

Stop:
		mov ax, 3100h
		lea dx, EOP
		shr dx, 4
		inc dx
		int 21h


;------------------------------------------------------------------------------
;IN:		None
;OUT:		None
;DAMAGED:	BX, AX, ES
;==============================================================================
NewInterrupt09		proc

		push ax bx es

		mov bx, 0b800h
		mov es, bx

        mov bx, cs:PrintOfs
        mov ah, 4eh

        in al, 60h
		;mov al, 'A'
        mov es:[bx], ax
        add bx, 2
        and bx, 0fffh

        mov cs:PrintOfs, bx

        pop es bx ax

        cmp al, 1ch
        je Stop

						db 0Eah
		Old09Ofs		dw 0
		Old09Seg		dw 0

        PrintOfs        dw (80d * 4d + 40) * 2

		;iret
		endp
;==============================================================================

EOP:

end 		Start
