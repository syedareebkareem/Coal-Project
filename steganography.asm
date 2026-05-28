                                                         final code
; main code file
.model small
.stack 100h

.data

;------------------------------------------------------------
; MESSAGE BUFFERS
;------------------------------------------------------------

messageBuffer   db 8,?,9 dup('$')
                            ; original message typed by user
                            ; byte 0 = max allowed chars
                            ; byte 1 = actual chars typed
                            ; byte 2+ = message itself

messageLength   db ?
                            ; actual length of user message
                            ; saved once on first input

;------------------------------------------------------------
; ENCRYPTED OUTPUT BUFFERS (one per cipher)
;------------------------------------------------------------

xorEncrypted    db 9 dup('$')
                            ; stores XOR encrypted output
                            ; filled by xorEncrypt procedure

hillEncrypted   db 9 dup('$')
                            ; stores Hill Cipher encrypted output
                            ; filled by hillEncrypt procedure

caesarEncrypted db 9 dup('$')
                            ; stores Caesar Cipher encrypted output
                            ; filled by caesarEncrypt procedure

;------------------------------------------------------------
; PIXEL ARRAYS (one per cipher, 64 pixels each)
;------------------------------------------------------------

xorPixels       db 64 dup(200)
                            ; pixel array for XOR steganography
                            ; each pixel holds 1 secret bit in LSB
                            ; 8 chars x 8 bits = 64 pixels total

hillPixels      db 64 dup(200)
                            ; pixel array for Hill Cipher steganography
                            ; same LSB structure as xorPixels

caesarPixels    db 64 dup(200)
                            ; pixel array for Caesar steganography
                            ; same LSB structure as xorPixels

;------------------------------------------------------------
; EXTRACTED BUFFERS (one per cipher)
;------------------------------------------------------------

xorExtracted    db 9 dup('$')
                            ; extracted encrypted bytes from xorPixels
                            ; fed into xorDecrypt

hillExtracted   db 9 dup('$')
                            ; extracted encrypted bytes from hillPixels
                            ; fed into hillDecrypt

caesarExtracted db 9 dup('$')
                            ; extracted encrypted bytes from caesarPixels
                            ; fed into caesarDecrypt

;------------------------------------------------------------
; FINAL DECRYPTED OUTPUT
;------------------------------------------------------------

finalMessage    db 9 dup('$')
                            ; final recovered plaintext after decryption
                            ; printed to screen on receive

;------------------------------------------------------------
; HIDDEN LENGTH TRACKERS (one per cipher)
;------------------------------------------------------------

xorHiddenLen    db ?
                            ; how many bytes are hidden in xorPixels
                            ; same as messageLength for XOR

hillHiddenLen   db ?
                            ; how many bytes are hidden in hillPixels
                            ; messageLength+1 if original length was odd

caesarHiddenLen db ?
                            ; how many bytes are hidden in caesarPixels
                            ; same as messageLength for Caesar

;------------------------------------------------------------
; CIPHER USED FLAGS
;------------------------------------------------------------

xorUsed         db 0
                            ; 0 = XOR not yet encrypted
                            ; 1 = XOR has been encrypted and hidden

hillUsed        db 0
                            ; 0 = Hill not yet encrypted
                            ; 1 = Hill has been encrypted and hidden

caesarUsed      db 0
                            ; 0 = Caesar not yet encrypted
                            ; 1 = Caesar has been encrypted and hidden

messageEntered  db 0
                            ; 0 = no message entered yet
                            ; 1 = message has been entered this session

;------------------------------------------------------------
; KEY AND SHIFT INPUTS
;------------------------------------------------------------

keyPrompt       db 13,10,'  Enter Password (MAX 8 CHARS): $'
                            ; shown before XOR password input

caesarPrompt    db 13,10,'  Enter Shift Value (1-9): $'
                            ; shown before Caesar shift input

keyBuffer       db 8,?,9 dup('$')
                            ; buffer for XOR password
                            ; DOS 0Ah format

caesarShiftBuf  db 2,?,3 dup('$')
                            ; buffer for Caesar shift digit
                            ; single digit so max 2 is enough

caesarShift     db ?
                            ; numeric shift value for Caesar
                            ; parsed from caesarShiftBuf

;------------------------------------------------------------
; HILL CIPHER MATRICES
;------------------------------------------------------------

hillMatrix      db 1,2,3,7
                            ; 2x2 encryption matrix
                            ; [1 2]
                            ; [3 7]
                            ; det = 1*7 - 2*3 = 1, inverse exists mod 256

hillInvMatrix   db 7,254,253,1
                            ; 2x2 decryption matrix (inverse mod 256)
                            ; [7  -2]  =>  [7  254]
                            ; [-3  1]  =>  [253  1]

;------------------------------------------------------------
; DISPLAY STRINGS
;------------------------------------------------------------

titleTop        db 13,10
                db '  +========================================+',13,10
                db '  |     SECURE MESSAGE SYSTEM  v2.0        |',13,10
                db '  +========================================+',13,10,'$'

mainMenuStr     db 13,10
                db '  +------ MAIN MENU ----------------------+',13,10
                db '  |  1.  Encrypt a Message                |',13,10
                db '  |  2.  Extract / Decrypt                |',13,10
                db '  |  3.  Show Original Message            |',13,10
                db '  |  4.  Exit                             |',13,10
                db '  +---------------------------------------+',13,10
                db '  Choice: $'

encMenuStr      db 13,10
                db '  +------ CHOOSE CIPHER ------------------+',13,10
                db '  |  1.  XOR Cipher                       |',13,10
                db '  |  2.  Hill Cipher                      |',13,10
                db '  |  3.  Caesar Cipher                    |',13,10
                db '  |  4.  Back to Main Menu                |',13,10
                db '  +---------------------------------------+',13,10
                db '  Choice: $'

decMenuStr      db 13,10
                db '  +------ CHOOSE CIPHER TO EXTRACT -------+',13,10
                db '  |  1.  XOR Cipher                       |',13,10
                db '  |  2.  Hill Cipher                      |',13,10
                db '  |  3.  Caesar Cipher                    |',13,10
                db '  |  4.  Back to Main Menu                |',13,10
                db '  +---------------------------------------+',13,10
                db '  Choice: $'

anotherEncStr   db 13,10,'  Encrypt another? (Y/N): $'
                            ; asked after each encryption
                            ; Y loops back to cipher menu
                            ; N returns to main menu

anotherDecStr   db 13,10,'  Extract another? (Y/N): $'
                            ; asked after each extraction
                            ; Y loops back to cipher select
                            ; N returns to main menu

msgInput        db 13,10,'  Enter Message (MAX 8 CHARS): $'
msgOrig         db 13,10,'  Original Message  : $'
msgExtracted    db 13,10,'  Extracted (Enc)   : $'
msgRecovered    db 13,10,'  Recovered Message : $'
msgPixels       db 13,10,'  Pixel Values      : $'

errNoMsg        db 13,10,'  [!] Enter a message first (use Encrypt).',13,10,'$'
errNotUsed      db 13,10,'  [!] That cipher was not used for encryption.',13,10,'$'
okDone          db 13,10,'  [OK] Done!',13,10,'$'
divider         db 13,10,'  ----------------------------------------',13,10,'$'

space           db ' $'
newline         db 13,10,'$'

;============================================================
.code
;============================================================

main proc

    mov ax,@data
    mov ds,ax
                            ; point DS to our data segment
                            ; must be done before touching any data labels

mainLoop:

    call showMainMenu
                            ; draw the main menu and read one keypress
                            ; result comes back in AL

    cmp al,'1'
    je doEncryptFlow
                            ; user wants to encrypt something

    cmp al,'2'
    je doDecryptFlow
                            ; user wants to extract and decrypt

    cmp al,'3'
    je doShowOriginal
                            ; user wants to see the original message

    cmp al,'4'
    je doExit
                            ; user wants to quit

    jmp mainLoop
                            ; unknown key, just redraw menu

;------------------------------------------------------------

doEncryptFlow:

    cmp messageEntered,1
    je encipherMenu
                            ; message already in buffer, skip input

    call getInput
                            ; ask user to type their message
                            ; fills messageBuffer and sets messageLength

    mov messageEntered,1
                            ; mark that message is now in memory

encipherMenu:

    call showEncMenu
                            ; show cipher selection menu
                            ; result in AL

    cmp al,'1'
    je runXorEncrypt
                            ; do XOR encryption

    cmp al,'2'
    je runHillEncrypt
                            ; do Hill encryption

    cmp al,'3'
    je runCaesarEncrypt
                            ; do Caesar encryption

    cmp al,'4'
    jmp mainLoop
                            ; back to main menu

    jmp encipherMenu
                            ; unknown key, redraw

runXorEncrypt:

    lea dx,keyPrompt
    mov ah,09h
    int 21h
                            ; show password prompt

    lea dx,keyBuffer
    mov ah,0Ah
    int 21h
                            ; read password into keyBuffer using DOS buffered input

    lea si,xorEncrypted
    push si
                            ; push destination buffer address

    lea ax,keyBuffer+2
    push ax
                            ; push password start address

    mov al,messageLength
    mov ah,00h
    push ax
                            ; push message length

    call xorEncrypt
                            ; encrypt messageBuffer+2 into xorEncrypted

    mov al,messageLength
    mov xorHiddenLen,al
                            ; XOR output length equals input length

    lea si,xorEncrypted
    lea di,xorPixels
    mov cl,xorHiddenLen
    call hideInPixels
                            ; store encrypted bits into xorPixels

    mov xorUsed,1
                            ; mark XOR as done

    lea dx,msgPixels
    mov ah,09h
    int 21h

    lea si,xorPixels
    mov cl,xorHiddenLen
    call printPixels
                            ; show the pixel array on screen

    lea dx,okDone
    mov ah,09h
    int 21h

    jmp askAnotherEnc

runHillEncrypt:

    mov al,messageLength
    mov hillHiddenLen,al
                            ; start with same length as message

    test al,1
    jz hillEncLenOK
                            ; even length needs no padding

    inc hillHiddenLen
                            ; odd length needs one padding byte for Hill blocks

hillEncLenOK:

    lea si,hillEncrypted
    push si
                            ; push destination buffer

    mov al,messageLength
    mov ah,00h
    push ax
                            ; push original message length

    call hillEncrypt
                            ; encrypt messageBuffer+2 into hillEncrypted

    lea si,hillEncrypted
    lea di,hillPixels
    mov cl,hillHiddenLen
    call hideInPixels
                            ; hide Hill encrypted bytes into hillPixels

    mov hillUsed,1
                            ; mark Hill as done

    lea dx,msgPixels
    mov ah,09h
    int 21h

    lea si,hillPixels
    mov cl,hillHiddenLen
    call printPixels
                            ; print hillPixels

    lea dx,okDone
    mov ah,09h
    int 21h

    jmp askAnotherEnc

runCaesarEncrypt:

    lea dx,caesarPrompt
    mov ah,09h
    int 21h
                            ; show shift prompt

    lea dx,caesarShiftBuf
    mov ah,0Ah
    int 21h
                            ; read shift digit from user

    mov al,caesarShiftBuf+2
    sub al,'0'
                            ; convert ASCII digit to number
                            ; subtract ASCII '0' to get actual digit value

    mov caesarShift,al
                            ; store numeric shift

    lea si,caesarEncrypted
    push si
                            ; push destination buffer

    mov al,messageLength
    mov ah,00h
    push ax
                            ; push message length

    call caesarEncrypt
                            ; encrypt messageBuffer+2 into caesarEncrypted

    mov al,messageLength
    mov caesarHiddenLen,al
                            ; Caesar output length equals input length

    lea si,caesarEncrypted
    lea di,caesarPixels
    mov cl,caesarHiddenLen
    call hideInPixels
                            ; hide Caesar encrypted bytes into caesarPixels

    mov caesarUsed,1
                            ; mark Caesar as done

    lea dx,msgPixels
    mov ah,09h
    int 21h

    lea si,caesarPixels
    mov cl,caesarHiddenLen
    call printPixels
                            ; print caesarPixels

    lea dx,okDone
    mov ah,09h
    int 21h

askAnotherEnc:

    lea dx,anotherEncStr
    mov ah,09h
    int 21h
                            ; ask if user wants to encrypt with another cipher

    mov ah,01h
    int 21h
                            ; read Y or N into AL

    cmp al,'Y'
    je encipherMenu

    cmp al,'y'
    je encipherMenu
                            ; lowercase y also accepted

    jmp mainLoop
                            ; anything else goes back to main

;------------------------------------------------------------

doDecryptFlow:

    cmp messageEntered,1
    je decipherMenu
                            ; message must have been entered first

    lea dx,errNoMsg
    mov ah,09h
    int 21h
                            ; print error if no message was entered yet

    jmp mainLoop

decipherMenu:

    call showDecMenu
                            ; show extraction cipher menu
                            ; result in AL

    cmp al,'1'
    je runXorDecrypt
                            ; extract and decrypt XOR

    cmp al,'2'
    je runHillDecrypt
                            ; extract and decrypt Hill

    cmp al,'3'
    je runCaesarDecrypt
                            ; extract and decrypt Caesar

    cmp al,'4'
    jmp mainLoop
                            ; back to main

    jmp decipherMenu

runXorDecrypt:

    cmp xorUsed,1
    je xorDecOK
                            ; only proceed if XOR was used for encryption

    lea dx,errNotUsed
    mov ah,09h
    int 21h
                            ; tell user XOR was not used

    jmp askAnotherDec

xorDecOK:

    lea si,xorExtracted
    lea di,xorPixels
    mov cl,xorHiddenLen
    call extractFromPixels
                            ; pull encrypted bytes out of xorPixels into xorExtracted

    lea dx,msgExtracted
    mov ah,09h
    int 21h

    lea dx,xorExtracted
    mov ah,09h
    int 21h
                            ; show the raw extracted encrypted text

    lea dx,keyPrompt
    mov ah,09h
    int 21h

    lea dx,keyBuffer
    mov ah,0Ah
    int 21h
                            ; ask for password again for decryption

    lea si,finalMessage
    push si
                            ; push output buffer

    lea ax,keyBuffer+2
    push ax
                            ; push password

    mov al,xorHiddenLen
    mov ah,00h
    push ax
                            ; push length

    lea si,xorExtracted
    push si
                            ; push extracted buffer as input source

    call xorDecrypt
                            ; decrypt xorExtracted into finalMessage

    lea dx,msgRecovered
    mov ah,09h
    int 21h

    lea dx,finalMessage
    mov ah,09h
    int 21h
                            ; show the recovered original message

    lea dx,okDone
    mov ah,09h
    int 21h

    jmp askAnotherDec

runHillDecrypt:

    cmp hillUsed,1
    je hillDecOK
                            ; only proceed if Hill was actually used

    lea dx,errNotUsed
    mov ah,09h
    int 21h

    jmp askAnotherDec

hillDecOK:

    lea si,hillExtracted
    lea di,hillPixels
    mov cl,hillHiddenLen
    call extractFromPixels
                            ; pull encrypted bytes from hillPixels into hillExtracted

    lea dx,msgExtracted
    mov ah,09h
    int 21h

    lea dx,hillExtracted
    mov ah,09h
    int 21h
                            ; show extracted encrypted text

    lea si,finalMessage
    push si
                            ; push output buffer

    mov al,hillHiddenLen
    mov ah,00h
    push ax
                            ; push length including any padding

    lea si,hillExtracted
    push si
                            ; push input source

    call hillDecrypt
                            ; decrypt hillExtracted into finalMessage

    lea dx,msgRecovered
    mov ah,09h
    int 21h

    lea dx,finalMessage
    mov ah,09h
    int 21h
                            ; show recovered message

    lea dx,okDone
    mov ah,09h
    int 21h

    jmp askAnotherDec

runCaesarDecrypt:

    cmp caesarUsed,1
    je caesarDecOK
                            ; only proceed if Caesar was actually used

    lea dx,errNotUsed
    mov ah,09h
    int 21h

    jmp askAnotherDec

caesarDecOK:

    lea si,caesarExtracted
    lea di,caesarPixels
    mov cl,caesarHiddenLen
    call extractFromPixels
                            ; pull encrypted bytes from caesarPixels into caesarExtracted

    lea dx,msgExtracted
    mov ah,09h
    int 21h

    lea dx,caesarExtracted
    mov ah,09h
    int 21h
                            ; show extracted encrypted text

    lea dx,caesarPrompt
    mov ah,09h
    int 21h

    lea dx,caesarShiftBuf
    mov ah,0Ah
    int 21h
                            ; ask for shift value again

    mov al,caesarShiftBuf+2
    sub al,'0'
                            ; parse shift digit

    mov caesarShift,al

    lea si,finalMessage
    push si
                            ; push output buffer

    mov al,caesarHiddenLen
    mov ah,00h
    push ax
                            ; push length

    lea si,caesarExtracted
    push si
                            ; push input

    call caesarDecrypt
                            ; decrypt caesarExtracted into finalMessage

    lea dx,msgRecovered
    mov ah,09h
    int 21h

    lea dx,finalMessage
    mov ah,09h
    int 21h
                            ; show recovered message

    lea dx,okDone
    mov ah,09h
    int 21h

askAnotherDec:

    lea dx,anotherDecStr
    mov ah,09h
    int 21h
                            ; ask if user wants to extract another cipher

    mov ah,01h
    int 21h
                            ; read keypress

    cmp al,'Y'
    je decipherMenu

    cmp al,'y'
    je decipherMenu
                            ; lowercase y accepted

    jmp mainLoop
                            ; anything else goes to main

;------------------------------------------------------------

doShowOriginal:

    cmp messageEntered,1
    je showOrig
                            ; only show if message was entered

    lea dx,errNoMsg
    mov ah,09h
    int 21h

    jmp mainLoop

showOrig:

    lea dx,newline
    mov ah,09h
    int 21h

    lea dx,msgOrig
    mov ah,09h
    int 21h

    lea dx,messageBuffer+2
    mov ah,09h
    int 21h
                            ; print actual message starting from byte 2 of buffer

    lea dx,newline
    mov ah,09h
    int 21h

    jmp mainLoop

;------------------------------------------------------------

doExit:

    mov ah,4Ch
    int 21h
                            ; clean DOS exit

main endp


;============================================================
; showMainMenu
; draws main menu box and reads one key
; returns: AL = key pressed
;============================================================

showMainMenu proc

    lea dx,titleTop
    mov ah,09h
    int 21h

    lea dx,mainMenuStr
    mov ah,09h
    int 21h

    mov ah,01h
    int 21h
                            ; read single keypress into AL

    ret

showMainMenu endp


;============================================================
; showEncMenu
; draws cipher selection menu for encryption
; returns: AL = key pressed
;============================================================

showEncMenu proc

    lea dx,divider
    mov ah,09h
    int 21h

    lea dx,encMenuStr
    mov ah,09h
    int 21h

    mov ah,01h
    int 21h

    ret

showEncMenu endp


;============================================================
; showDecMenu
; draws cipher selection menu for extraction
; returns: AL = key pressed
;============================================================

showDecMenu proc

    lea dx,divider
    mov ah,09h
    int 21h

    lea dx,decMenuStr
    mov ah,09h
    int 21h

    mov ah,01h
    int 21h

    ret

showDecMenu endp


;============================================================
; getInput
; prompts user to type message
; fills messageBuffer, sets messageLength
;============================================================

getInput proc

    lea dx,msgInput
    mov ah,09h
    int 21h

    lea dx,messageBuffer
    mov ah,0Ah
    int 21h
                            ; DOS buffered input
                            ; byte 1 of messageBuffer gets actual char count

    mov al,messageBuffer+1
    mov messageLength,al
                            ; save actual length to messageLength

    lea si,messageBuffer+2
    mov cl,messageLength
    mov ch,00h
    add si,cx
    mov byte ptr [si],'$'
                            ; place $ terminator after last character
                            ; needed for DOS AH=09h print

    ret

getInput endp


;============================================================
; hideInPixels
; hides encrypted bytes into a pixel array using LSB
; input: SI = source encrypted buffer
;        DI = destination pixel array
;        CL = number of bytes to hide
;============================================================

hideInPixels proc

    push ax
    push bx
    push cx
    push dx
    push si
    push di
                            ; save all registers

    mov ch,00h
                            ; CX = full byte count

hideCharLoop:

    mov bl,[si]
                            ; BL = current encrypted byte

    mov dl,8
                            ; 8 bits per character

hideBitLoop:

    mov al,[di]
                            ; AL = current pixel

    and al,11111110B
                            ; clear LSB of pixel

    mov bh,bl
    and bh,00000001B
                            ; BH = LSB of current encrypted byte

    or al,bh
                            ; insert secret bit into pixel LSB

    mov [di],al
                            ; write modified pixel back

    shr bl,1
                            ; shift encrypted byte right, next bit into LSB

    inc di
                            ; next pixel

    dec dl
    jnz hideBitLoop
                            ; repeat until all 8 bits are hidden

    inc si
                            ; next encrypted byte

    loop hideCharLoop
                            ; repeat for all bytes

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    ret

hideInPixels endp


;============================================================
; extractFromPixels
; pulls hidden bytes out of pixel array LSBs
; input: SI = destination extraction buffer
;        DI = source pixel array
;        CL = number of bytes to extract
;============================================================

extractFromPixels proc

    push ax
    push bx
    push cx
    push dx
    push si
    push di
                            ; save registers

    mov ch,00h
                            ; CX = full byte count

extCharLoop:

    mov bl,00h
                            ; BL will accumulate one recovered byte

    mov dl,8
                            ; 8 bits to extract

    mov bh,1
                            ; BH = current bit mask, starts at 00000001

extBitLoop:

    mov al,[di]
    and al,00000001B
                            ; extract LSB from current pixel

    cmp al,1
    jne bitWasZero
                            ; if bit is 0, nothing to set

    or bl,bh
                            ; set the correct bit in BL

bitWasZero:

    shl bh,1
                            ; shift mask to next bit position

    inc di
                            ; next pixel

    dec dl
    jnz extBitLoop
                            ; continue until all 8 bits are rebuilt

    mov [si],bl
                            ; store rebuilt byte into extraction buffer

    inc si
                            ; next extraction buffer slot

    loop extCharLoop
                            ; repeat for all bytes

    mov byte ptr [si],'$'
                            ; terminate extraction buffer

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    ret

extractFromPixels endp


;============================================================
; printPixels
; prints decimal values of pixels used for hiding
; input: SI = pixel array start
;        CL = number of encrypted bytes hidden (not pixels)
;============================================================

printPixels proc

    push ax
    push bx
    push cx
    push dx
    push si
                            ; save registers

    mov bl,cl
                            ; BL = number of encrypted bytes

    mov al,bl
    mov ah,00h
    mov bl,8
    mul bl
                            ; AX = total pixels = encrypted bytes x 8

    mov cx,ax
                            ; CX = pixel count for loop

pixelPrintLoop:

    mov al,[si]
                            ; AL = current pixel value

    call printByte
                            ; print 3 digit decimal

    lea dx,space
    mov ah,09h
    int 21h
                            ; space between values

    inc si

    loop pixelPrintLoop

    lea dx,newline
    mov ah,09h
    int 21h

    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    ret

printPixels endp


;============================================================
; printByte
; prints AL as a 3 digit decimal number
;============================================================

printByte proc

    push ax
    push bx
    push dx
                            ; save registers

    mov ah,0
    mov bl,100
    div bl
                            ; AL = hundreds digit, AH = remainder

    mov dl,al
    add dl,'0'
    push ax
    mov ah,02h
    int 21h
                            ; print hundreds digit

    pop ax
    mov al,ah
    mov ah,0
    mov bl,10
    div bl
                            ; AL = tens digit, AH = ones digit

    mov dl,al
    add dl,'0'
    push ax
    mov ah,02h
    int 21h
                            ; print tens digit

    pop ax
    mov dl,ah
    add dl,'0'
    mov ah,02h
    int 21h
                            ; print ones digit

    pop dx
    pop bx
    pop ax

    ret

printByte endp


;============================================================
; xorEncrypt
; stack params: [encrypted buffer addr] [password addr] [length]
; output: result in the buffer passed on stack
;============================================================

xorEncrypt proc

    push bp
    mov bp,sp

    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov di,[bp+8]
                            ; DI = destination encrypted buffer address

    mov bx,[bp+6]
                            ; BX = password address

    mov cx,[bp+4]
                            ; CX = message length

    lea si,messageBuffer+2
                            ; SI = source message

xorEncLoop:

    mov al,[si]
                            ; AL = current plaintext character

    mov dl,[bx]
                            ; DL = current password character

    xor al,dl
                            ; XOR encryption: al = plaintext XOR password

    mov [di],al
                            ; store into destination buffer

    inc si
    inc bx
    inc di

    loop xorEncLoop

    mov byte ptr [di],'$'
                            ; terminate encrypted buffer

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp

    ret 6
                            ; remove 3 word params from stack

xorEncrypt endp


;============================================================
; xorDecrypt
; stack params: [input buffer addr] [password addr] [length] [output buf addr]
; output: result in finalMessage
;============================================================

xorDecrypt proc

    push bp
    mov bp,sp

    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov di,[bp+10]
                            ; DI = output buffer (finalMessage)

    mov bx,[bp+8]
                            ; BX = password address

    mov cx,[bp+6]
                            ; CX = length

    mov si,[bp+4]
                            ; SI = input encrypted buffer (xorExtracted)

xorDecLoop:

    mov al,[si]
                            ; AL = current encrypted character

    mov dl,[bx]
                            ; DL = password character

    xor al,dl
                            ; XOR again to recover original

    mov [di],al
                            ; store in output buffer

    inc si
    inc bx
    inc di

    loop xorDecLoop

    mov byte ptr [di],'$'
                            ; terminate output

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp

    ret 8
                            ; remove 4 word params

xorDecrypt endp


;============================================================
; hillEncrypt
; stack params: [output buffer addr] [message length]
; reads from messageBuffer+2
; writes to output buffer
;============================================================

hillEncrypt proc

    push bp
    mov bp,sp

    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov di,[bp+6]
                            ; DI = destination buffer for Hill encrypted output

    mov cx,[bp+4]
                            ; CX = original message length

    lea si,messageBuffer+2
                            ; SI = plaintext source

hillEncLoop:

    cmp cx,0
    je hillEncDone

    mov al,[si]
                            ; AL = first character of pair, p1

    inc si
    dec cx

    mov bl,0
                            ; BL = second character, default 0 for padding

    cmp cx,0
    je hillEncPairReady

    mov bl,[si]
                            ; BL = second character p2

    inc si
    dec cx

hillEncPairReady:

    push cx
                            ; save remaining count before using CX as temp

    mov cl,al
    mov ch,bl
                            ; CL = p1, CH = p2

    mov al,1
    mul cl
    mov dl,al
                            ; DL = p1 * 1

    mov al,3
    mul ch
    add dl,al
                            ; DL = c1 = 1*p1 + 3*p2

    mov al,2
    mul cl
    mov dh,al
                            ; DH = p1 * 2

    mov al,7
    mul ch
    add dh,al
                            ; DH = c2 = 2*p1 + 7*p2

    mov [di],dl
                            ; store c1 into output

    inc di

    mov [di],dh
                            ; store c2 into output

    inc di

    pop cx
                            ; restore remaining count

    jmp hillEncLoop

hillEncDone:

    mov byte ptr [di],'$'
                            ; terminate output buffer

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp

    ret 4
                            ; remove 2 word params

hillEncrypt endp


;============================================================
; hillDecrypt
; stack params: [input buffer addr] [hidden length] [output buffer addr]
; inverse matrix [7 254 / 253 1] mod 256
;============================================================

hillDecrypt proc

    push bp
    mov bp,sp

    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov di,[bp+8]
                            ; DI = output buffer (finalMessage)

    mov cx,[bp+6]
                            ; CX = hidden length (may include padding)

    mov si,[bp+4]
                            ; SI = input encrypted buffer

hillDecLoop:

    cmp cx,0
    je hillDecDone

    mov al,[si]
                            ; AL = c1 first encrypted byte

    inc si
    dec cx

    mov bl,[si]
                            ; BL = c2 second encrypted byte

    inc si
    dec cx

    push cx

    mov cl,al
    mov ch,bl
                            ; CL = c1, CH = c2

    mov al,7
    mul cl
    mov dl,al
                            ; DL = c1 * 7

    mov al,253
    mul ch
    add dl,al
                            ; DL = p1 = 7*c1 + 253*c2  (mod 256 auto)

    mov al,254
    mul cl
    mov dh,al
                            ; DH = c1 * 254

    mov al,1
    mul ch
    add dh,al
                            ; DH = p2 = 254*c1 + 1*c2  (mod 256 auto)

    mov [di],dl
                            ; store recovered p1

    inc di

    mov [di],dh
                            ; store recovered p2

    inc di

    pop cx

    jmp hillDecLoop

hillDecDone:

    lea di,finalMessage
    mov cl,messageLength
    mov ch,00h
    add di,cx
    mov byte ptr [di],'$'
                            ; trim $ to original length to strip padding char

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp

    ret 6
                            ; remove 3 word params

hillDecrypt endp


;============================================================
; caesarEncrypt
; stack params: [output buffer addr] [message length]
; shift value read from caesarShift
;============================================================
