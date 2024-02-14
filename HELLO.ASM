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
Start:		mov ax, change_col_mode
		mov bl, 00h
		int 10h

			;mov dx, offset str_HW
			;mov si, dx

		mov ax, video_ram
		mov es, ax

		;call CleanScreen
		call ReadArgs
		call DrawAllFrame
		call DrawShadow

		;lea dx, str_HW
		;mov si, dx

		call PrintStr

Stop:		mov ax, stop_func
		int 21h
;===============================================================================
;===============================================================================


;-------------------------------------------------------------------------------
;IN:	  None
;OUT:	  None
;DAMAGED: AX, CX, DX
;===============================================================================
ReadArgs	proc

		mov si, 0082h

		;call ReadNum
		;lea di, num_args
		;mov [di], al
		;mov cx, [di]
		;inc si

;Read_Next_Arg:

		call ReadNum
		lea di, wide_t				;di = addres wide_t
		mov [di], al
		inc si

		call ReadNum
		lea di, height_t 			;di = addres height_t
		mov [di], al
		inc si

		call ReadColor
		lea di, color 				;di = addres color
		mov [di], al

		inc si

		mov ax, ds
		mov es, ax
		xor ax, ax
		mov al, [si]
		cmp al, '*'
		je Read_Border

		lea di, Border				;spot for copy
		sub al, '0'
		mul eightteen
		mov si, di					;si  = from where copy
		add si, ax

		mov cx, 9
		rep movsw

		mov ax, video_ram
		mov es, ax
		jmp Skip

Read_Border:
		inc si
		call ReadBorder

Skip:
		mov ax, video_ram
		mov es, ax
		;loop Read_Next_Arg

		;call ReadStr

		lea di, title
		mov [di], si

		ret
		endp
;===============================================================================



;-------------------------------------------------------------------------------
;IN:  SI
;OUT: pointer to str
;DAMAGED: AX, CX, SI, DI
;===============================================================================
ReadStr proc

		ret
		endp
;===============================================================================



;-------------------------------------------------------------------------------
;IN:  SI
;OUT: Border massiv
;DAMAGED: AX, CX, SI, DI
;===============================================================================
ReadBorder	proc

		mov cx, 9
		lea di, Border			;di = Border massiv

New_Sign:
		xor ax, ax
		mov al, [si]
		mov [di], al
		inc si
		add di, 2

		loop New_Sign

			ret
			endp
;===============================================================================



;-------------------------------------------------------------------------------
;IN:  SI
;	  DI = start new arg
;OUT: arg
;DAMAGED: AX, BX, SI, DI
;===============================================================================
ReadNum	proc


		xor ax, ax				;ax = 0
NewEter:	mov dl, [si]		;dl = value SI

		cmp dl, '0'				;compare with ' '
		jb End_Num

		cmp dl, '9'
		ja End_Num

		;---------------------------------------------
		sub dl, '0'				; do number
		mul ten					;10 * previous num
		add al, dl				;add next number
		inc si					;si++
		;---------------------------------------------

		jmp NewEter				;new etaration of loop
End_Num:
		ret
		endp
;===============================================================================



;-------------------------------------------------------------------------------
;IN:  SI
;	  DI = start new arg
;OUT: arg
;DAMAGED: AX, BX, SI, DI
;===============================================================================
ReadColor	proc

		xor ax, ax				;ax = 0
New_Simbol:	mov dl, [si]		;dl = value SI

		cmp dl, '0'				;compare with ' '
		jb End_Color
		cmp dl, 'f'
		ja End_Color

		;---------------------------------------------
		sub dl, '0'				; do number
		mul sixteen				;10 * previous num
		add al, dl				;add next number
		inc si					;si++
		;---------------------------------------------

		jmp New_Simbol				;new etaration of loop
End_Color:
		ret
		endp
;===============================================================================



;-------------------------------------------------------------------------------
;IN:	  ES
;OUT:	  None
;DAMAGED: AX, BX, CX, DI, DS, SI
;===============================================================================
DrawAllFrame	proc

		mov di, corner_point * 2

		xor bx, bx
;Up Frame ---------------------------------------------
		lea si, Border

		lodsw			;ax = 87c9h
		lea bx, color
		mov ah, [bx]
		stosw			;print left up corner
		lodsw			;ax = 87cdh
		lea bx, color
		mov ah, [bx]

		lea bx, wide_t
		xor cx, cx
		mov cl, [bx]
		sub cx, 2

		rep stosw		;print up border
		lodsw
		lea bx, color
		mov ah, [bx]
		stosw			;print right up corner

		lea bx, wide_t
		xor ax, ax
		mov al, [bx]
		add di, 160
		sub di, ax
		sub di, ax

;Medium Frame -------------------------------------------
		xor dx, dx
New_Str:
		lea si, Border
		add si, 6

		lodsw			;ax = 87bah
		lea bx, color
		mov ah, [bx]
		stosw			;print elem of left border
		lodsw			;al = ' '
		lea bx, color
		mov ah, [bx]

		lea bx, wide_t
		xor cx, cx
		mov cl, [bx]
		sub cx, 2

		rep stosw		;fill frame
		lodsw			;ax = 87bah
		lea bx, color
		mov ah, [bx]
		stosw			;print elem of right border

		lea bx, wide_t
		xor ax, ax
		mov al, [bx]
		add di, 160
		sub di, ax
		sub di, ax

		inc dx			; dx++

		lea bx, height_t
		xor cx, cx
		mov cl, [bx]
		sub cx, 2

		;sub si, 3

		cmp dx, cx
		jne New_Str

;Down Frame ----------------------------------------------
		;lea si, Down_Border
		;add si, 3

		lodsw			;ax = 87c8h
		lea bx, color
		mov ah, [bx]
		stosw			;print left down corner
		lodsw			;ax = 87cdh
		lea bx, color
		mov ah, [bx]

		lea bx, wide_t
		xor dx, dx
		mov dl, [bx]
		sub dx, 2
		mov cx, dx

		rep stosw		;print down border
		lodsw			;ax = 87bch
		lea bx, color
		mov ah, [bx]
		stosw			;print down right corner

		ret
		endp
;===============================================================================



;-------------------------------------------------------------------------------
;IN:	  ES, DI
;OUT:	  CX = len
;DAMAGED: AX, CX, DI, ES, SI
;===============================================================================
Strlen		proc

		mov al, '$'
		mov cx, 100
		mov es, si
		mov di, 0

		scasb
		xor al, al
		repne scasb

		sub cx, 100
		ret
		endp
;===============================================================================


;-------------------------------------------------------------------------------
;IN:      ES, SI
;OUT:	  None
;DAMAGED: AX, CX, BX, DX, ES, SI, DI
;DESC:	  print given string with start in given point straight to VRAM
;===============================================================================
PrintStr	proc

		mov cx, (corner_point + wide / 2 - len_str / 2) * 2
		lea si, title
		mov si, [si]
		;start of str in VRAM

Next:	mov bx, si			;BX = SI (pointer to char in str)
		mov dl, [bx]		;dl = bx
		cmp dl, ':'			;compare with

		je End_Str

		;---------------------------------------------

		mov bx, cx			;bx = cx

		mov byte ptr es:[bx], dl		;set ASCII cod of simbol
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
;IN:      ES
;OUT:	  None
;DAMAGED: AX, BX, CX, DX
;DEST:    draw rect and frame with animation
;===============================================================================
Animation	proc

		mov dx, 1			;start wide of Rect

DrawNextRect:
		call DrawRect
		call DrawFrame
		call DrawShadow

		inc dx
		cmp dx, wide
		jne DrawNextRect

		ret
		endp
;===============================================================================



;-------------------------------------------------------------------------------
;IN:      ES, DX
;OUT:     None
;DAMAGED: AX, BX, CX
;DESC:	  draw rectangle with given colour and size
;===============================================================================
DrawRect	proc
		mov cx, hight				;CX = hight of table
		mov bx, (corner_point) * 2    		;bx = left corner of table

		Y:
			mov ax, 0
			X:
				mov byte ptr es:[bx + 1], grey_grey
				add bx, 2

				inc ax
				cmp ax, wide		;if ax != wide jmp to X
				jne X

			add bx, (80 - wide) * 2
		loop Y

		ret
		endp
;===============================================================================



;-------------------------------------------------------------------------------
;IN: 	  ES, DX
;OUT:	  None
;DAMAGED: CX, BX
;DESC:	  draw frame with given wight and hight
;===============================================================================
DrawFrame 	proc

		mov cx, wide					;CX = wide
		;mov al, hight 					;al = hight
		mov bx, corner_point * 2
LRBorder:							;draw right and left border
		mov byte ptr es:[bx], 0cdh
		mov byte ptr es:[bx + 1], white_on_grey

		;mul 160
		;add ax, bx
		mov byte ptr es:[bx + hight * 80 * 2], 0cdh
		mov byte ptr es:[bx + hight * 80 * 2 + 1], white_on_grey
		;sub bx, hight * 160 - 2

		add bx, 2

		loop LRBorder;

		mov bx, corner_point * 2
		mov cx, hight

UDBorder:							;draw up and down border
		mov byte ptr es:[bx], 0bah
		mov byte ptr es:[bx + 1], white_on_grey

		mov byte ptr es:[bx + wide * 2], 0bah
		mov byte ptr es:[bx + wide * 2 + 1], white_on_grey

		add bx, 80 * 2

		loop UDBorder

		mov bx, corner_point * 2

;Set corners
;-------------------------------------------------------------------------------
		mov byte ptr es:[bx], 0c9h
		mov byte ptr es:[bx + 1], white_on_grey

		mov byte ptr es:[bx + wide * 2], 0bbh
		mov byte ptr es:[bx + wide * 2 + 1], white_on_grey

		mov byte ptr es:[bx + hight * 80 * 2], 0c8h
		mov byte ptr es:[bx + hight * 80 * 2 + 1], white_on_grey

		mov byte ptr es:[bx + hight * 80 * 2 + wide * 2], 0bch
		mov byte ptr es:[bx + hight * 80 * 2 + wide * 2 + 1], white_on_grey
;-------------------------------------------------------------------------------
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

		lea bx, wide_t
		xor ax, ax
		mov al, [bx]
		mov bx, (corner_x / 2 + (corner_y + 1) * 80) * 2
		add bx, ax
		add bx, ax
		mov si, bx

		lea bx, height_t
		xor cx, cx
		mov cl, [bx]
		sub cx, 1
				;mov cx, hight - 1

RightShadow:
		mov byte ptr es:[si + 1], grey_on_yellow
		add si, 80 * 2

		loop RightShadow

		lea bx, wide_t
		xor cx, cx
		mov cl, [bx]
				;mov cx, wide

DownShadow:
		mov byte ptr es:[si + 1], grey_on_yellow
		sub si, 2

		loop DownShadow

		ret
		endp
;===============================================================================


;-------------------------------------------------------------------------------
;IN:      ES
;OUT:     None
;DAMAGED: BX, CX
;DESC:    clean all screen
;===============================================================================
CleanScreen	proc

		mov cx, screen_size
		mov bx, 0

		clean:
			mov byte ptr es:[bx + 1], screen_col
			add bx, 2
		loop clean

		ret
		endp
;===============================================================================

.data

Up_Border       dw 87c9h, 87cdh, 87bbh
Medium_Border   dw 87bah, 8700h, 87bah
Down_Border     dw 87c8h, 87cdh, 87bch

Border			dw 87c9h, 87cdh, 87bbh, 87bah, 8700h, 87bah, 87c8h, 87cdh, 87bch
Border_1		dw 6e23h, 6e23h, 6e23h, 6e23h, 6e00h, 6e23h, 6e23h, 6e23h, 6e23h
Border_2		dw 7403h, 7403h, 7403h, 7403h, 7400h, 7403h, 7403h, 7403h, 7403h

str_HW		db ' Hello world! $'
title       dw 0
wide_t		db 0
height_t	db 0
color       db 87h
num_args	db 0
ten			db 10
sixteen     db 16
eightteen	db 18

end 		Start
