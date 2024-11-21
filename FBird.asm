IDEAL

; programer name :   base.asm by yossi

MODEL small

STACK 100h
SCREEN_WIDTH = 320  
 

 
 



BACKGROUND_IMAGE_NAME_IN equ 'back2.bmp'


DATASEG

	ScrLine 	db SCREEN_WIDTH dup (0)  ; One Color line read buffer
	Background_Color db 0
	Bird_Y dw 100
	Alive db 1
	RndCurrentPos dw  0
	;save the location for tower1
	Poll1 dw 0
	Poll2 dw 182
	;save the location for tower2
	Poll3 dw 0
	Poll4 dw 182
	Poll1_Loacation dw 310
	Poll2_Loacation dw 160
	Poll1_Loacation_2 dw 320
	Poll2_Loacation_2 dw 170
	Velocity dw 1
	cnt db 0
	Score dw 0
	bool_Reset db 0
	bool_Check_overlapping db 0
	;BMP File data
	Background_Image 	db BACKGROUND_IMAGE_NAME_IN ,0
 
	FileHandle	dw ?
	Header 	    db 54 dup(0)
	Palette 	db 400h dup (0)
	
	SmallBird db 'Bird.bmp',0
	ExitGame_Pic db 'exit.bmp',0
	Start_Icon db 'Start.bmp',0
	Start_Page db 'StartP.bmp',0
	Ground_Pic db 'ground.bmp',0
	
	BmpFileErrorMsg    	db 'Error At Opening Bmp File ',BACKGROUND_IMAGE_NAME_IN, 0dh, 0ah,'$'
	ErrorFile           db 0
    BB db "BB..",'$'


	BmpLeft dw ?
	BmpTop dw ?
	BmpWidth dw ?
	BmpHeight dw ?
CODESEG

    
start: 
	mov ax, @data
	mov ds,ax
	
	call SetGraphic
	call DrawAll
	call ShowScore
	
@@Play:
	
	call CheckSpaceForJump
	
	call update_graphics
	call AddToScore
	call _20MiliSecDelay ; around 50 fps
	
	cmp [cnt],4
	jnz @@Finish
	inc [Velocity] ; apllies gravity
	mov [cnt],0
@@Finish:
	inc [cnt]
	cmp [Alive],1
	jz @@Play
	
	call DrawExitPage
	;wait till got clicked on restart or exit game
	mov ax,81
	push ax
	mov ax,91
	push ax
	mov ax,54
	push ax
	mov ax,61
	push ax
	mov ax,182
	push ax
	mov ax,91
	push ax
	mov ax,54
	push ax
	mov ax,61
	push ax
	call WaitTillGotClickOn2PointYouChoose
	cmp [bool_Reset],0
	jnz exit
	call Reset
	jmp @@Play
exit:
	mov dx, offset BB
	mov ah,9
	;int 21h
	mov ah,0
	int 16h
	
	mov ax,2
	int 10h
	
	mov ax, 4c00h
	int 21h

proc _20MiliSecDelay
    push cx

    mov cx ,100
@@Self1:

    push cx
    mov cx,600 

@@Self2:
    loop @@Self2

    pop cx
    loop @@Self1

    pop cx
    ret
endp _20MiliSecDelay

proc DrawExitPage
	;for background
	mov dx, offset ExitGame_Pic
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpWidth], 320
	mov [BmpHeight] ,200
	
	call OpenShowBmp
	;check if eror
	cmp [ErrorFile],1
	je @@exitError
	jmp @@Exit
	
@@exitError:
    mov dx, offset BmpFileErrorMsg
	mov ah,9
	int 21h
@@Exit:
	call ShowScoreEnd
	ret
endp DrawExitPage

proc DrawGround
	mov dx, offset Ground_Pic
	mov [BmpLeft],51
	mov [BmpTop],183
	mov [BmpWidth], 22
	mov [BmpHeight] ,7
	
	call OpenShowBmp
	;check if eror
	cmp [ErrorFile],1
	jne @@ExitLoop
@@exitError:
    mov dx, offset BmpFileErrorMsg
	mov ah,9
	int 21h
@@ExitLoop:
	ret
endp DrawGround

proc DrawBackground
	mov dx, offset Background_Image
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpWidth], 320
	mov [BmpHeight] ,200
	
	call OpenShowBmp
	;check if eror
	cmp [ErrorFile],1
	jne @@ExitLoop
@@exitError:
    mov dx, offset BmpFileErrorMsg
	mov ah,9
	int 21h
@@ExitLoop:
	ret
endp DrawBackground

proc DrawStartPage
	;for background
	mov dx, offset Start_Page
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpWidth], 320
	mov [BmpHeight] ,200
	
	call OpenShowBmp
	;check if eror
	cmp [ErrorFile],1
	je @@exitError
	
	;for start icon
	mov dx, offset Start_Icon
	mov [BmpLeft],100
	mov [BmpTop],130
	mov [BmpWidth], 110
	mov [BmpHeight] ,48
	
	call OpenShowBmp
	;check if eror
	cmp [ErrorFile],1
	je @@exitError
	
	;wait till got clicked on start
	mov ax,100
	push ax
	mov ax,130
	push ax
	mov ax,110
	push ax
	mov ax,48
	push ax
	call WaitTillGotClickOnPointYouChoose

	
	;check if eror
	cmp [ErrorFile],1
	jne @@ExitLoop
	
@@exitError:
    mov dx, offset BmpFileErrorMsg
	mov ah,9
	int 21h
@@ExitLoop:
	ret
endp DrawStartPage


proc DrawBird
	push ax 
	mov [BmpLeft],51
	mov ax,[Bird_Y]
	mov [BmpTop],ax
	mov [BmpWidth], 21
	mov [BmpHeight] ,18
	mov dx,offset SmallBird
	call OpenShowBmp 
	cmp [ErrorFile],1
	je @@exitError
	jmp @@exit
@@exitError:
    mov dx, offset BmpFileErrorMsg
	mov ah,9
	int 21h
@@exit:
	pop ax 
	ret
endp DrawBird




proc MovePolls
	cmp [Poll1_Loacation],0
	jz @@PutZero1
	dec [Poll1_Loacation]
@@Continue1:
	cmp [Poll2_Loacation],0
	jz @@PutZero2
	dec [Poll2_Loacation]
	jmp @@end
@@PutZero1:
	mov [Poll1_Loacation],0
	jmp @@Continue1
@@PutZero2:
	mov [Poll2_Loacation],0
@@end:
	dec [Poll1_Loacation_2]
	dec [Poll2_Loacation_2]
	ret
endp MovePolls

proc CheckoverlappingPoll1
	;push reqtengel bird
	mov ax,51
	push ax
	push [Bird_Y]
	mov ax,72
	push ax
	mov ax,[Bird_Y]
	add ax,17
	push ax
	;push for poll1
	push [Poll1_Loacation]
	mov ax,0
	push ax
	push [Poll1_Loacation_2]
	push [Poll1]
	call aabb
	cmp ax,1
	jnz @@end
	mov [bool_Check_overlapping],1
@@end:
	ret
endp CheckoverlappingPoll1

proc CheckoverlappingPoll2
	;push reqtengel bird
	mov ax,51
	push ax
	push [Bird_Y]
	mov ax,72
	push ax
	mov ax,[Bird_Y]
	add ax,17
	push ax
	;push for poll2
	push [Poll1_Loacation]
	mov ax,182
	sub ax,[Poll2]
	push ax
	push [Poll1_Loacation_2]
	mov ax,182
	push ax
	call aabb
	cmp ax,1
	jnz @@end
	mov [bool_Check_overlapping],1
@@end:
	ret
endp CheckoverlappingPoll2



proc CheckoverlappingPoll3
	;push reqtengel bird
	mov ax,51
	push ax
	push [Bird_Y]
	mov ax,72
	push ax
	mov ax,[Bird_Y]
	add ax,17
	push ax
	;push for poll3
	push [Poll2_Loacation]
	mov ax,0
	push ax
	push [Poll2_Loacation_2]
	push [Poll3]
	call aabb
	cmp ax,1
	jnz @@end
	mov [bool_Check_overlapping],1
@@end:
	ret
endp CheckoverlappingPoll3

proc CheckoverlappingPoll4
	;push reqtengel bird
	mov ax,51
	push ax
	push [Bird_Y]
	mov ax,72
	push ax
	mov ax,[Bird_Y]
	add ax,17
	push ax
	;push for poll4
	push [Poll2_Loacation]
	mov ax,182
	sub ax,[Poll4]
	push ax
	push [Poll2_Loacation_2]
	mov ax,182
	push ax
	call aabb
	cmp ax,1
	jnz @@end
	mov [bool_Check_overlapping],1
@@end:
	ret
endp CheckoverlappingPoll4

proc CheckIfDead
	call CheckoverlappingPoll1
	call CheckoverlappingPoll2
	call CheckoverlappingPoll3
	call CheckoverlappingPoll4
	cmp [bool_Check_overlapping],1
	jnz @@end
@@Kill:
	mov [Alive],0
@@end:
	
	ret
endp CheckIfDead

;-----------------------------------------------------------------------
; Check whether 2 rectangels are overlapping   
; input on stack for 2 items  x1 y1 x2 y2 
; Output: ax = 1 it is true ax=0 it is not
; Reg Use : Ax
;if (rect1.x2 < rect2.x1 OR
;    rect2.x2 < rect1.x1 OR
;    rect1.y2 < rect2.y1 OR
;    rect2.y2 < rect1.y1 
;     not collision !
;}

;-----------------------------------------------------------------------
ParamAX1 equ   [word bp+18]
ParamAY1 equ   [word bp+16]
ParamAX2 equ   [word bp+14]
ParamAY2 equ   [word bp+12]

ParamBX1 equ   [word bp+10]
ParamBY1 equ   [word bp+8]
ParamBX2 equ   [word bp+6]
ParamBY2 equ   [word bp+4]

proc aabb 
	
	push bp     ; save bp
	mov bp,sp   ; parameters and locals pointer
	
	push dx
	 
	
	mov ax ,1
	
	mov dx , ParamAX2
	cmp dx, ParamBX1
	jb @@NotCollision
	
	mov dx , ParamBX2
	cmp dx, ParamAX1
	jb @@NotCollision
	
	mov dx , ParamAY2
	cmp dx, ParamBY1
	jb @@NotCollision
	
	mov dx , ParamBY2
	cmp dx, ParamAY1
	jb @@NotCollision
	jmp @@ret
@@NotCollision:
	mov ax ,0

@@ret:
	pop dx 
	pop bp     
	ret 16
endp aabb



proc Draw1Edge
	push 0a000h
    pop es
	mov di,[Poll1_Loacation]
    mov cx,[Poll1]
@@UpPoll:
    mov [byte ptr es:di],2
    add di,320
    loop @@UpPoll
    mov di,182*320
    add di,[Poll1_Loacation]
    mov cx,[Poll2]
@@DownPoll:
    mov [byte ptr es:di],2
    sub di,320
    loop @@DownPoll
	ret
endp Draw1Edge

proc Draw2Edge
	push 0a000h
    pop es
	mov di,[Poll2_Loacation]
    mov cx,[Poll3]
@@UpPoll:
    mov [byte ptr es:di],2
    add di,320
    loop @@UpPoll
    mov di,182*320
    add di,[Poll2_Loacation]
    mov cx,[Poll4]
@@DownPoll:
    mov [byte ptr es:di],2
    sub di,320
    loop @@DownPoll
	ret
endp Draw2Edge




proc DrawPoll_1
	;for setting the poll size
    call Random_Number
    mov [Poll1],ax
    mov [Poll2],182
    sub [Poll2],ax
    sub [Poll2],70
 
@@Continue:

    push 0a000h
    pop es
    xor bx,bx
    mov cx,10

@@loopPoll1:
    push cx
    mov di,310
    add di,bx
    mov cx,[Poll1]

@@UpPoll:
    mov [byte ptr es:di],2
    add di,320
    loop @@UpPoll
	mov di,182*320
    add di,310
    add di,bx
    mov cx,[Poll2]
@@DownPoll:
    mov [byte ptr es:di],2
    sub di,320
    loop @@DownPoll
    inc bx
    pop cx
    loop @@loopPoll1
    ret
endp DrawPoll_1



proc DrawPoll_2

    ;for setting the poll size
    call Random_Number 
    mov [Poll3],ax
    mov [Poll4],182
    sub [Poll4],ax
    sub [Poll4],70

@@Continue:

    push 0a000h
    pop es
    xor bx,bx
    mov cx,10

@@loopPoll1:
    push cx
    mov di,310
    add di,bx
    mov cx,[Poll3]

@@UpPoll:
    mov [byte ptr es:di],2
    add di,320
    loop @@UpPoll
	mov di,182*320
    add di,310
    add di,bx
    mov cx,[Poll4]
@@DownPoll:
    mov [byte ptr es:di],2
    sub di,320
    loop @@DownPoll
    inc bx
    pop cx
    loop @@loopPoll1
    ret
endp DrawPoll_2

proc DrawPoll2Start
	;for setting the poll size
	call Random_Number 
    mov [Poll3],ax
    mov [Poll4],182
    sub [Poll4],ax
    sub [Poll4],70

@@Continue:

    push 0a000h
    pop es
    xor bx,bx
    mov cx,10

@@loopPoll1:
    push cx
    mov di,160
    add di,bx
    mov cx,[Poll3]

@@UpPoll:
    mov [byte ptr es:di],2
    add di,320
    loop @@UpPoll
	mov di,182*320
    add di,160
    add di,bx
    mov cx,[Poll4]
@@DownPoll:
    mov [byte ptr es:di],2
    sub di,320
    loop @@DownPoll
    inc bx
    pop cx
    loop @@loopPoll1
	ret
endp DrawPoll2Start


proc Get_Background_Color
	;get background color
	push ax
	xor ax,ax
	mov ah,0dh
	mov bh,0
	mov cx,0
	mov dx,0
	int 10h
	mov [Background_Color],al
	pop ax
	ret
endp Get_Background_Color

proc AddToScore
	;check if the bird crossed poll1
	;if yes add to score 1
	cmp [Poll1_Loacation],51
	jnz @@Check2
	inc [Score]
	call ShowScore
@@Check2:
	;check if the bird crossed poll2
	cmp [Poll2_Loacation],51
	jnz @@end
	inc [Score]
	call ShowScore
@@end:
	ret
endp AddToScore

proc DeletePoll_1
    mov al,[Background_Color]
@@loopPoll1:
    mov di,[Poll1_Loacation_2]
    mov cx,[Poll1]
@@UpPoll:
    mov [byte ptr es:di],al
    add di,320
    loop @@UpPoll
	
    mov di,182*320 
    add di,[Poll1_Loacation_2]
    mov cx,[Poll2]
@@DownPoll:
    mov [byte ptr es:di],al
    sub di,320
    loop @@DownPoll

    ret
endp DeletePoll_1


proc DeletePoll_2
    mov al,[Background_Color]
@@loopPoll1:
    mov di,[Poll2_Loacation_2]
    mov cx,[Poll3]
@@UpPoll:
    mov [byte ptr es:di],al
    add di,320
    loop @@UpPoll
	
    mov di,182*320 
	add di,[Poll2_Loacation_2]
    mov cx,[Poll4]
@@DownPoll:
    mov [byte ptr es:di],al
    sub di,320
    loop @@DownPoll

    ret
endp DeletePoll_2

;Description:Draw the background color on the trail the bird dose while jumping or falling

proc DeleteBird 
	push 0a000h
    pop es
	;check if the bird is jumping or falling
	cmp [Velocity],0
	jg @@con2
	;if bird is jumping
@@con1:
	mov ax,[Bird_Y]
	add ax,18
	mov si,ax
	add ax,10
	;ax=bird y bottom + 10(jumping)
	mov cx,ax
	sub cx,si
	mov ax,320
	mul si
	mov di,ax
	add di,51
	
@@loop1:
	push cx
	mov al,[Background_Color]
	mov cx,22
@@loop2:
	mov [byte ptr es:di],al
    inc di
	loop @@loop2
	sub di,22
	add di,320
	pop cx
	loop @@loop1
	jmp @@end
@@con2:
	;if bird is Falling
	mov cx,[Velocity]
	mov ax,320
	mov si,[Bird_Y]
	sub si,[Velocity]
	mul si
	mov di,ax
	add di,51
	
@@loop3:
	push cx
	mov al,[Background_Color]
	mov cx,22
@@loop4:
	mov [byte ptr es:di],al
    inc di
	loop @@loop4
	sub di,22
	add di,320
	pop cx
	loop @@loop3
@@end:
	ret
endp DeleteBird



proc CheckSpaceForJump
	;keyboard sets
	mov ah,1
	int 16h
	jz @@End
	
	mov ah,0
	int 16h
	
	;check if pressed space
	;39h=space
	cmp ah,39h
	jnz @@CheckIfExit
	mov [Velocity],-4
	jmp @@End
@@CheckIfExit:
	cmp ah,1h
	jnz @@End
	mov [Alive],0
	jmp @@End

@@End:
	ret
	 
endp CheckSpaceForJump


proc update_graphics
	;update for bird
	call MoveBird
	call DeleteBird
	call DrawBird
	
	call DrawGround
	;update for polls
	call DeletePoll_1
	call DeletePoll_2
	cmp [Poll1_Loacation_2],0
	jz @@check1
	cmp [Poll2_Loacation_2],0
	jz @@check2
	call MovePolls
	call CheckIfDead
	call Draw1Edge
	call Draw2Edge
	jmp @@end
	
	
@@check1:
	;draw poll1 from the start
	mov [Poll1_Loacation],310
	mov [Poll1_Loacation_2],320
	call DrawPoll_1
	jmp @@end
@@check2:
	;draw poll2 from the start
	mov [Poll2_Loacation],310
	mov [Poll2_Loacation_2],320
	call DrawPoll_2
@@end:
	ret
endp update_graphics


proc DrawAll
	call DrawStartPage
	call DrawBackground
	call Get_Background_Color
	call DrawBird
	call DrawPoll_1
	call DrawPoll2Start
	ret
endp DrawAll

proc Reset
	mov [Poll1_Loacation],310
	mov [Poll1_Loacation_2],320
	mov [Poll2_Loacation],160
	mov [Poll2_Loacation_2],170
	mov [Bird_Y],100
	mov [Alive],1
	mov [cnt],0
	mov [Velocity],1
	mov [Score],0
	mov [bool_Check_overlapping],0
	call DrawBackground
	call Get_Background_Color
	call DrawBird
	call DrawPoll_1
	call DrawPoll2Start
	call ShowScore
	ret
endp Reset


proc MoveBird
	push ax 
	push cx

	
	mov ax,[Velocity]
	add [Bird_Y],ax
	
	;check if touched the ceiling
	cmp [Bird_Y],0
	jle @@Kill
	
	;check if touched the ground
	cmp [Bird_Y],167
	jge @@Kill 

	jmp @@Exit
	
@@Kill:
	mov [Alive],0	
	
@@Exit:
	pop cx
	pop ax 
	ret
endp MoveBird




proc Random_Number
	;random number between 1-5
	mov bl,1
	mov bh,5
	call RandomByCs
	mov bl,20
	mul bl
	ret
endp Random_Number

; Description  : get RND between any bl and bh includs (max 0 -255)
; Input        : 1. Bl = min (from 0) , BH , Max (till 255)
; 			     2. RndCurrentPos a  word variable,   help to get good rnd number
; 				 	Declre it at DATASEG :  RndCurrentPos dw ,0
;				 3. EndOfCsLbl: is label at the end of the program one line above END start		
; Output:        Al - rnd num from bl to bh  (example 50 - 150)
; More Info:
; 	Bl must be less than Bh 
; 	in order to get good random value again and agin the Code segment size should be 
; 	at least the number of times the procedure called at the same second ... 
; 	for example - if you call to this proc 50 times at the same second  - 
; 	Make sure the cs size is 50 bytes or more 
; 	(if not, make it to be more) 
proc RandomByCs
    push es
	push si
	push di
	
	mov ax, 40h
	mov	es, ax
	
	sub bh,bl  ; we will make rnd number between 0 to the delta between bl and bh
			   ; Now bh holds only the delta
	cmp bh,0
	jz @@ExitP
 
	mov di, [word RndCurrentPos]
	call MakeMask ; will put in si the right mask according the delta (bh) (example for 28 will put 31)
	
RandLoop: ;  generate random number 
	mov ax, [es:06ch] ; read timer counter
	mov ah, [byte cs:di] ; read one byte from memory (from semi random byte at cs)
	xor al, ah ; xor memory and counter
	
	; Now inc di in order to get a different number next time
	inc di
	cmp di,(EndOfCsLbl - start - 1)
	jb @@Continue
	mov di, offset start
@@Continue:
	mov [word RndCurrentPos], di
	
	and ax, si ; filter result between 0 and si (the nask)
	cmp al,bh    ;do again if  above the delta
	ja RandLoop
	
	add al,bl  ; add the lower limit to the rnd num
		 
@@ExitP:	
	pop di
	pop si
	pop es
	ret
endp RandomByCs

; make mask acording to bh size 
; output Si = mask put 1 in all bh range
; example  if bh 4 or 5 or 6 or 7 si will be 7
; 		   if Bh 64 till 127 si will be 127
Proc MakeMask    
    push bx

	mov si,1
    
@@again:
	shr bh,1
	cmp bh,0
	jz @@EndProc
	
	shl si,1 ; add 1 to si at right
	inc si
	
	jmp @@again
	
@@EndProc:
    pop bx
	ret
endp  MakeMask






proc OpenShowBmp near
	
	 
	call OpenBmpFile
	cmp [ErrorFile],1
	je @@ExitProc
	
	call ReadBmpHeader
	
	call ReadBmpPalette
	
	call CopyBmpPalette
	
	call ShowBMP
	
	 
	call CloseBmpFile

@@ExitProc:
	ret
endp OpenShowBmp

 

	
; input dx filename to open
proc OpenBmpFile	near						 
	mov ah, 3Dh
	xor al, al
	int 21h
	jc @@ErrorAtOpen
	mov [FileHandle], ax
	jmp @@ExitProc
	
@@ErrorAtOpen:
	mov [ErrorFile],1
@@ExitProc:	
	ret
endp OpenBmpFile
 
 
 



proc CloseBmpFile near
	mov ah,3Eh
	mov bx, [FileHandle]
	int 21h
	ret
endp CloseBmpFile




; Read 54 bytes the Header
proc ReadBmpHeader	near					
	push cx
	push dx
	
	mov ah,3fh
	mov bx, [FileHandle]
	mov cx,54
	mov dx,offset Header
	int 21h
	
	pop dx
	pop cx
	ret
endp ReadBmpHeader



proc ReadBmpPalette near ; Read BMP file color palette, 256 colors * 4 bytes (400h)
						 ; 4 bytes for each color BGR + null)			
	push cx
	push dx
	
	mov ah,3fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
	
	pop dx
	pop cx
	
	ret
endp ReadBmpPalette


; Will move out to screen memory the colors
; video ports are 3C8h for number of first color
; and 3C9h for all rest
proc CopyBmpPalette		near					
										
	push cx
	push dx
	
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0  ; black first							
	out dx,al ;3C8h
	inc dx	  ;3C9h
CopyNextColor:
	mov al,[si+2] 		; Red				
	shr al,2 			; divide by 4 Max (cos max is 63 and we have here max 255 ) (loosing color resolution).				
	out dx,al 						
	mov al,[si+1] 		; Green.				
	shr al,2            
	out dx,al 							
	mov al,[si] 		; Blue.				
	shr al,2            
	out dx,al 							
	add si,4 			; Point to next color.  (4 bytes for each color BGR + null)				
								
	loop CopyNextColor
	
	pop dx
	pop cx
	
	ret
endp CopyBmpPalette

proc ShowBMP
; BMP graphics are saved upside-down.
; Read the graphic line by line (BmpHeight lines in VGA format),
; displaying the lines from bottom to top.
	push cx
	
	mov ax, 0A000h
	mov es, ax
	
 
	mov ax,[BmpWidth] ; row size must dived by 4 so if it less we must calculate the extra padding bytes
	mov bp, 0
	and ax, 3
	jz @@row_ok
	mov bp,4
	sub bp,ax

@@row_ok:	
	mov cx,[BmpHeight]
    dec cx
	add cx,[BmpTop] ; add the Y on entire screen
	; next 5 lines  di will be  = cx*320 + dx , point to the correct screen line
	mov di,cx
	shl cx,6
	shl di,8
	add di,cx
	add di,[BmpLeft]
	cld ; Clear direction flag, for movsb forward
	
	mov cx, [BmpHeight]
@@NextLine:
	push cx
 
	; small Read one line
	mov ah,3fh
	mov cx,[BmpWidth]  
	add cx,bp  ; extra  bytes to each row must be divided by 4
	mov dx,offset ScrLine
	int 21h
	; Copy one line into video memory es:di
	mov cx,[BmpWidth]  
	mov si,offset ScrLine
	rep movsb ; Copy line to the screen

	
		
	
	
	sub di,[BmpWidth]            ; return to left bmp
	sub di,SCREEN_WIDTH  ; jump one screen line up
	
	pop cx
	loop @@NextLine
	
	pop cx
	ret
endp ShowBMP


 proc ShowAxDecimal
       push ax
	   push bx
	   push cx
	   push dx
	   
	   ; check if negative
	   test ax,08000h
	   jz PositiveAx
			
	   ;  put '-' on the screen
	   push ax
	   mov dl,'-'
	   mov ah,2
	   int 21h
	   pop ax

	   neg ax ; make it positive
PositiveAx:
       mov cx,0   ; will count how many time we did push 
       mov bx,10  ; the divider
   
put_mode_to_stack:
       xor dx,dx
       div bx
       add dl,30h
	   ; dl is the current LSB digit 
	   ; we cant push only dl so we push all dx
       push dx    
       inc cx
       cmp ax,9   ; check if it is the last time to div
       jg put_mode_to_stack

	   cmp ax,0
	   jz pop_next  ; jump if ax was totally 0
       add al,30h  
	   mov dl, al    
  	   mov ah, 2h
	   int 21h        ; show first digit MSB
	       
pop_next: 
       pop ax    ; remove all rest LIFO (reverse) (MSB to LSB)
	   mov dl, al
       mov ah, 2h
	   int 21h        ; show all rest digits
       loop pop_next
		

   
	   pop dx
	   pop cx
	   pop bx
	   pop ax
	   
	   ret
endp ShowAxDecimal
 
proc ShowScore
	;set new location for ShowAxDecimal
	mov ah,2h
	mov bh,0
	mov dh,23
	mov dl,196
	int 10h
	mov ax,[Score]
	call ShowAxDecimal
    ret
endp ShowScore

proc ShowScoreEnd
	;set new location for ShowAxDecimal
	mov ah,2h
	mov bh,0
	mov dh,2
	mov dl,2
	int 10h
	mov ax,[Score]
	call ShowAxDecimal
	ret
endp ShowScoreEnd



proc  SetGraphic
	mov ax,13h   ; 320 X 200 
				 ;Mode 13h is an IBM VGA BIOS mode. It is the specific standard 256-color mode 
	int 10h
	ret
endp 	SetGraphic





X equ [word ptr bp+10]
Y equ [word ptr bp+8]
BmpWidthh equ [word ptr bp+6]
BmpHeightt equ [word ptr bp+4]
proc WaitTillGotClickOnPointYouChoose
	push bp
	mov bp,sp
	
	push si
	push ax
	push bx
	push cx
	push dx
	
	mov ax,1
	int 33h
	
	
@@ClickWaitWithDelay:
	mov cx,1000
@@ag:	
	loop @@ag
@@WaitTillPressOnPoint:

	mov ax,5h
	mov bx,0 ; quary the left b
	int 33h
	
	
	cmp bx,00h
	jna @@ClickWaitWithDelay  ; mouse wasn't pressed
	and ax,0001h
	jz @@ClickWaitWithDelay   ; left wasn't pressed

 	mov ax,3h
	int 33h
	mov ax,X
	Add ax,BmpWidthh
	shl ax,1
	cmp cx,ax
	ja @@ClickWaitWithDelay
	
	
	mov bx,Y
	add bx,BmpHeightt
	cmp dx,bx
	ja @@ClickWaitWithDelay
	
@@CheckX:
	mov ax,X
	shl ax,1
	cmp cx,ax
	jl @@ClickWaitWithDelay
	
@@CheckY:
	cmp dx,Y
	jl @@ClickWaitWithDelay

	mov ax,2
	int 33h
	
	pop dx
	pop cx
	pop bx
	pop ax
	pop si
	
	pop bp
	ret 8
endp WaitTillGotClickOnPointYouChoose


X equ [word ptr bp+10]
Y equ [word ptr bp+8]
BmpWidthh equ [word ptr bp+6]
BmpHeightt equ [word ptr bp+4]
X2 equ [word ptr bp+18]
Y2 equ [word ptr bp+16]
BmpWidthh2 equ [word ptr bp+14]
BmpHeightt2 equ [word ptr bp+12]
proc WaitTillGotClickOn2PointYouChoose
	push bp
	mov bp,sp
	
	push si
	push ax
	push bx
	push cx
	push dx
	
	mov ax,1
	int 33h
	
	
@@ClickWaitWithDelay:
	mov cx,1000
@@ag:	
	loop @@ag
@@WaitTillPressOnPoint:

	mov ax,5h
	mov bx,0 ; quary the left b
	int 33h
	
	
	cmp bx,00h
	jna @@ClickWaitWithDelay  ; mouse wasn't pressed
	and ax,0001h
	jz @@ClickWaitWithDelay   ; left wasn't pressed

 	mov ax,3h
	int 33h
	mov ax,X
	Add ax,BmpWidthh
	shl ax,1
	cmp cx,ax
	ja @@SecondCheck
	mov bx,Y
	add bx,BmpHeightt
	cmp dx,bx
	ja @@SecondCheck
	
@@CheckX:
	mov ax,X
	shl ax,1
	cmp cx,ax
	jl @@SecondCheck
	
@@CheckY:
	cmp dx,Y
	jl @@SecondCheck
	mov [bool_Reset],1
	jmp @@end
@@SecondCheck:	
	mov ax,3h
	int 33h
	mov ax,X2
	Add ax,BmpWidthh2
	shl ax,1
	cmp cx,ax
	ja @@ClickWaitWithDelay
    mov bx,Y2
	add bx,BmpHeightt2
	cmp dx,bx
	ja @@ClickWaitWithDelay
	
@@CheckX2:
	mov ax,X2
	shl ax,1
	cmp cx,ax
	jl @@ClickWaitWithDelay
	
@@CheckY2:
	cmp dx,Y2
	jl @@ClickWaitWithDelay
	mov [bool_Reset],0
@@end:
	mov ax,2
	int 33h
	
	pop dx
	pop cx
	pop bx
	pop ax
	pop si
	
	pop bp
	ret 16
endp WaitTillGotClickOn2PointYouChoose





EndOfCsLbl:
END start