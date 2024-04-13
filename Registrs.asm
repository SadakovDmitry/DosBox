.286
.model tiny
.code
org 100h


;CONSTANTS:------------------------------------
video_ram	= 0b800h
change_col_mode = 1003h
stop_func       = 4c00h
grey_grey	= 88h
black_on_black  = 00h
grey_on_black   = 08h
screen_size     = 25 * 80
white_on_grey   = 87h
grey_on_yellow	= 0e8h
screen_col      = 0eeh
wide		= 40
hight		= 8
corner_x	= 30
corner_y	= 10
len_str         = 14
corner_point    = corner_x / 2 + corner_y * 80
;----------------------------------------------


;MAIN
;===============================================================================
;===============================================================================
Start:
        	mov ax, change_col_mode
		mov bl, 00h
		int 10h

		mov ax, video_ram
		mov es, ax

            	mov ax, 3509h		;--------------------------------------
            	int 21h			;>
        	mov Old09Ofs, bx	;>>
            	mov bx, es		;>>>
        	mov Old09Seg, bx	;>>>>

		cli			;>>>>>>
		xor bx, bx		;>>>>>>>>     Set_New_09Interrupt
		mov es, bx		;>>>>>>
		mov bx, 4 * 09h
		mov es:[bx], offset NewInterrupt09

		push cs			;>>>
		pop ax			;>>
		mov es:[bx + 2], ax	;--------------------------------------

		sti

        	mov ax, 3508h		;--------------------------------------
        	int 21h			;>
        	mov Old08Ofs, bx	;>>
        	mov bx, es		;>>>
        	mov Old08Seg, bx	;>>>>

		cli			;>>>>>>
		xor bx, bx		;>>>>>>>>     Set_New_08Interrupt
		mov es, bx		;>>>>>>
		mov bx, 4 * 08h
		mov es:[bx], offset NewInterrupt08

		push cs			;>>>
		pop ax			;>>
		mov es:[bx + 2], ax	;--------------------------------------

		sti

Stop:
		mov ax, 3100h
		lea dx, EOP
		shr dx, 4
		inc dx
		int 21h

;===============================================================================
;===============================================================================





;------------------------------------------------------------------------------
;IN:		None
;OUT:		None
;DAMAGED:	AX
;==============================================================================
NewInterrupt09		proc

		push ax

        	in al, 60h
        	cmp al, 36h             ;if Shift(R) set fag that should print frame
        	jne Skip

            	xor cs:Print_Frame, 1	;change frame mode

Skip:
        	pop ax

		db 0Eah
Old09Ofs	dw 0
Old09Seg	dw 0

		endp
;==============================================================================



;-------------------------------------------------------------------------------
;IN:        None
;OUT:	    Nones
;DAMAGED:   None
;===============================================================================
NewInterrupt08	proc

		cmp cs:Print_Frame, 1
		jne Skip_Frame

		push ss es ds sp bp si di dx cx bx ax

		mov bp, sp
		push cs
		pop  ds

        	mov bx, 0b800h		;||	ES = video memoty
		mov es, bx		;//

		call DrawAllFrame	;--------------------------------------
		call DrawShadow		;\\
		call PrintTitle		;>>	Print Frame
       		call PrintRegs		;--------------------------------------

        	pop ax bx cx dx di si bp sp ds es ss

Skip_Frame:

        	db 0EAh
Old08Ofs	dw 0h
Old08Seg	dw 0h

		endp
;===============================================================================





;-------------------------------------------------------------------------------
;IN:        None
;OUT:       di = corner_point
;DAMAGED:   DI
;===============================================================================
FindCorner proc
        	mov di, (80 * 8 + 56)

		ret
		endp
;===============================================================================



;-------------------------------------------------------------------------------
;IN:	  ES = video_RAM
;OUT:	  None
;DAMAGED: AX, BX, CX, DI, DS, SI
;===============================================================================
DrawAllFrame	proc
		call FindCorner
				;mov di, corner_point * 2
		add di, di

		xor ax, ax
		xor bx, bx
;Up Frame -----------------------------------------------
		lea si, Border

		lodsw		;<\
		lea bx, color	; >} ah = color , al = ASCII of sign
		mov ah, [bx]	;</
		stosw		;print left up corner

		lodsw		;<\
		lea bx, color	; >} ah = color , al = ASCII of sign
		mov ah, [bx]	;</

		lea bx, wide_t	;<\
		xor cx, cx	; >|| cx = wide - 2
		mov cl, [bx]	; >|/
		sub cx, 2	;</

		rep stosw	;print up border
		lodsw		;<\
		lea bx, color	; >} ah = color , al = ASCII of sign
		mov ah, [bx]	;</
		stosw		;print right up corner

		lea bx, wide_t	;<\
		xor ax, ax	; >|\
		mov al, [bx]	; >||| di = di + (80 - wide) * 2 (newline)
		add di, 80 * 2	; >||/
		sub di, ax	; >|/
		sub di, ax	;</

;Medium Frame -------------------------------------------
		xor dx, dx
New_Str:
		lea si, Border
		add si, 6	;return to start of massiv

		lodsw		;<\
		lea bx, color	; >} ah = color , al = ASCII of sign
		mov ah, [bx]	;</
		stosw		;print elem of left border

		lodsw		;<\
		lea bx, color	; >} ah = color , al = ASCII of sign
		mov ah, [bx]	;</

		lea bx, wide_t	;<\
		xor cx, cx	; >| cx = wide - 2
		mov cl, [bx]	; >|
		sub cx, 2	;</

		rep stosw	;fill frame
		lodsw		;<\
		lea bx, color	; >} ah = color , al = ASCII of sign
		mov ah, [bx]	;</
		stosw			;print elem of right border

		lea bx, wide_t	;<\
		xor ax, ax	; >|\
		mov al, [bx]	; >||| di = di + (80 - wide) * 2
		add di, 80 * 2	; >||/
		sub di, ax	; >|/
		sub di, ax	;</

		inc dx		; dx++

		lea bx, height_t;<\
		xor cx, cx	; >| cx = hight - 2
		mov cl, [bx]	; >|
		sub cx, 2	;</

		cmp dx, cx	; >|if cx != dx print next string
		jne New_Str	;</

;Down Frame ----------------------------------------------
		;lea si, Down_Border
		;add si, 3

		lodsw		;<\
		lea bx, color	; >} ah = color , al = ASCII of sign
		mov ah, [bx]	;</
		stosw		;print left down corner

		lodsw		;<\
		lea bx, color	; >} ah = color , al = ASCII of sign
		mov ah, [bx]	;</

		lea bx, wide_t	;<\
		xor cx, cx	; >| cx = wide - 2
		mov cl, [bx]	; >|
		sub cx, 2	;</
		rep stosw	;print down border

		lodsw		;<\
		lea bx, color	; >} ah = color , al = ASCII of sign
		mov ah, [bx]	;</
		stosw		;print down right corner

		ret
		endp
;===============================================================================


;-------------------------------------------------------------------------------
;IN:      None
;OUT:	  None
;DAMAGED: AX, CX, BX, DX, ES, SI, DI
;DESC:	  print given string with start in given point straight to VRAM
;===============================================================================
PrintTitle	proc

        	mov ax, video_ram
		mov es, ax

		call FindCorner		;-------------------------------------
		xor ax, ax		;>>
		xor cx, cx		;>>>
		xor bx, bx              ;>>>>
		add di, di		;>>>>> di = corner point
		lea si, title_len	;>>>
		mov al, [si]		;>>
		sub di, ax		;-------------------------------------

		xor ax, ax
		lea si, wide_t
		mov al, [si]
		add di, ax
		and di, not 1d
		mov cx, di
					;mov cx, (corner_point + wide / 2 - len_str / 2) * 2

		xor si, si
		lea si, title_str	;pointer to start title str

		xor ax, ax
		xor bx, bx

Next:		mov bx, si		;BX = SI (pointer to char in str)
		mov dl, [bx]		;dl = bx
		cmp dl, '$'		;compare with '$'

		je End_Str

		;---------------------------------------------

		mov bx, cx			;bx = cx

		mov byte ptr es:[bx], dl	;set ASCII cod of simbol
		lea di, color
		mov byte ptr ah, [di]
		mov byte ptr es:[bx + 1], ah	;set colour of simbol and fon

		inc cx				;cx++
		inc cx				;cx++
		inc si				;di++

		;---------------------------------------------
		jmp Next

End_str:
		ret
		endp
;===============================================================================



;-------------------------------------------------------------------------------
;IN:      SI = start str
;OUT:     CX = len_str
;DAMAGED: AX, CX, SI
;===============================================================================
StrLen	proc
		xor cx, cx

Next_Simbol:
		mov al, [si]
		cmp al, ':'		;if :
		je Return
		cmp al, '#'		;if #
		je Return
		cmp al, ';'		;if ;
		je Return
        	cmp al, '$'		;if $
		je Return

		inc si			;si++
		inc cx			;cx++

		jmp Next_Simbol

Return:
		ret
		endp
;===============================================================================


;-------------------------------------------------------------------------------
;IN:        all regs in stack
;OUT:       print all regs
;DAMAGED:   AX BX CX DX SI DI
;===============================================================================
PrintRegs        proc

        	call FindCorner		;<\
        	add di, di		; >| di = corner point
		xor ax, ax		;</
		xor bx, bx
		xor cx, cx

        	add di, 80 * 2 + 14	;skip one line
        	mov cx, di
        	and cx, not 1d

		lea si, body_text

New_Simbol:
        	mov bx, si		;BX = SI (pointer to char in str)
		mov dl, [bx]		;dl = bx
		cmp dl, '#'		;compare with '#'
		je Next_Reg         	;print next registr
		cmp dl, '$'         	;compare with '$'
		jne Print_Reg       	;stop if '$'

        	ret

Print_Reg:
		;---------------------------------------------

		mov bx, cx			;bx = cx

		mov byte ptr es:[bx], dl	;set ASCII cod of simbol
		lea di, color
		mov byte ptr ah, [di]
		mov byte ptr es:[bx + 1], ah	;set colour of simbol and fon

		inc cx				;cx++
		inc cx				;cx++
		inc si				;si++

		;---------------------------------------------
		jmp New_Simbol
Next_Reg:

        	;Print Registr Value
        	;-----------------------------------------------------
        	mov ax, ss:[bp]
        	add bp, 2

        	mov bx, ax		;-----------------------------------
        	and bx, 0F000h		;>>> Print first num in registr
        	shr bx, 12		;>>
        	call PrintNum		;-----------------------------------

        	mov bx, ax		;-----------------------------------
        	and bx, 0F00h		;>>> Print second num in registr
        	shr bx, 8		;>>
        	call PrintNum		;-----------------------------------

        	mov bx, ax		;-----------------------------------
        	and bx, 00F0h		;>>> Print third num in registr
        	shr bx, 4		;>>
        	call PrintNum		;-----------------------------------

        	mov bx, ax      	;-----------------------------------
        	and bx, 000Fh       	;>> Print fourth num in registr
        	call PrintNum       	;-----------------------------------
        	;-----------------------------------------------------
        	;end print Registr Value

       		mov ax, ss:[bp]			;return to pointer to call addres in stack
        	inc si                          ;skip #
        	add cx, 80 * 2                  ;new line
        	sub cx, 9 * 2
        	and di, not 1d			;and 000F
        	jmp New_Simbol

        	endp
;===============================================================================



;-------------------------------------------------------------------------------
;IN: 	 BX = Number in 16 sistem counting
;        CX = Place in VRAM
;OUT:	 Print Number
;DAMAGE: BX, CX
;DESC:   draw shadow near rectangle
;===============================================================================
PrintNum    	proc

        	mov dl, [bx + Nums_Letters] 	
        	mov bx, cx			;bx = cx
        	mov byte ptr es:[bx], dl	;set ASCII cod of simbol
        	mov byte ptr es:[bx + 1], 87h	;set colour white_on_gray
        	inc cx				;cx++
		inc cx				;cx++

        	ret
        	endp
;===============================================================================



;-------------------------------------------------------------------------------
;IN: 	 ES, DX
;OUT:	 None
;DAMAGE: BX, CX, DX, AX
;DESC:   draw shadow near rectangle
;===============================================================================
DrawShadow	proc

		call FindCorner
		add di, 80
		add di, di

		lea bx, wide_t		;<\
		xor ax, ax		; >} al = wide
		mov al, [bx]		;</

		mov bx, di		; bx = addres of corner

		add bx, ax
		add bx, ax
		mov si, bx

		lea bx, height_t	;<\
		xor cx, cx		; >| cx = height - 1
		mov cl, [bx]		; >|
		sub cx, 1		;</

RightShadow:
		mov byte ptr es:[si + 1], grey_on_yellow
		add si, 80 * 2

		loop RightShadow

		lea bx, wide_t
		xor cx, cx
		mov cl, [bx]


DownShadow:
		mov byte ptr es:[si + 1], grey_on_yellow
		sub si, 2

		loop DownShadow

		ret
		endp
;===============================================================================


.data

Border		dw 87c9h, 87cdh, 87bbh, 87bah, 8700h, 87bah, 87c8h, 87cdh, 87bch

title_str   	db 'Registrs$'
body_text	db 'AX = #BX = #CX = #DX = #SI = #DI = #BP = #SP = #DS = #ES = #SS = #IP = #CS = #$'
Nums_Letters 	db '0123456789ABCDEF$'
Print_Frame 	db 0
wide_t		db 20
height_t	db 15
color       	db 87h
title_len	db 8

ten		db 10
sixteen     	db 16
eightteen	db 18
two   		db 2
eighty		db 80

EOP:

end Start
