.model small                ;main code file
.stack 100h

.data


messageBuffer   db 8,?,9 dup('$')
                            ; original message typed by user
                            ; byte 0 = max allowed chars
                            ; byte 1 = actual chars typed
                            ; byte 2+ = message itself

messageLength   db ?
                            ; actual length of user message
                            ; saved once on first input



xorEncrypted    db 9 dup('$')
                            ; stores XOR encrypted output
                            ; filled by xorEncrypt procedure

hillEncrypted   db 9 dup('$')
                            ; stores Hill Cipher encrypted output
                            ; filled by hillEncrypt procedure

caesarEncrypted db 9 dup('$')
                            ; stores Caesar Cipher encrypted output
                            ; filled by caesarEncrypt procedure



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



xorExtracted    db 9 dup('$')
                            ; extracted encrypted bytes from xorPixels
                            ; fed into xorDecrypt

hillExtracted   db 9 dup('$')
                            ; extracted encrypted bytes from hillPixels
                            ; fed into hillDecrypt

caesarExtracted db 9 dup('$')
                            ; extracted encrypted bytes from caesarPixels
                            ; fed into caesarDecrypt

finalMessage    db 9 dup('$')
                            ; final recovered plaintext after decryption
                            ; printed to screen on receive

xorHiddenLen    db ?
                            ; how many bytes are hidden in xorPixels
                            ; same as messageLength for XOR

hillHiddenLen   db ?
                            ; how many bytes are hidden in hillPixels
                            ; messageLength+1 if original length was odd

caesarHiddenLen db ?
                            ; how many bytes are hidden in caesarPixels
                            ; same as messageLength for Caesar


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


hillMatrix      db 1,2,3,7
                            ; 2x2 encryption matrix
                            ; [1 2]
                            ; [3 7]
                            ; det = 1*7 - 2*3 = 1, inverse exists mod 256

hillInvMatrix   db 7,254,253,1
                            ; 2x2 decryption matrix (inverse mod 256)
                            ; [7  -2]  =>  [7  254]
                            ; [-3  1]  =>  [253  1]


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



.code
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                            ; hide message done 
                            ; 9th may,2026
                            ; syedareebkareem
                            ; don't edit 
hideMessage proc
                            ; hides the message in the array
  LEA si,encryptedText
                            ; si is pointing towards encrytedText's first character.  
  LEA di,pixelArray
                            ; di is pointing to pixelArray's first value (200).
  MOV cl,messageLength
                            ; for instance message length is 4, loop will iterate to
  MOV Ch,00h
                            ; making sure cl works fine and not infected by this ch in looping
characterLoop:
                            ; loops each 8bit character
mov bl,[si]
                            ; moves si which holds first character of 8 bit into the bl
mov dl,8
                            ; this holds the total bit
                            ; acts as counter
bitLoop:
                            ;inside each character there are 8 bits and each one should be looped to place each
                            ;inside the one exact pixel
mov al,[di]
                            ; first pixel selected                          
                            ; so now we have al that has first pixel
                            ; dl has total bit length
                            ; bl has first charcater
AND al,11111110B
                            ; no matter what the last bit is it will be zero
                            ; no matter what the other 7 bits are they will retain their states
mov bh,bl
                            ; now bh has the first character of 8 bits
                            ; bl will be needed for shr in future 
and bh,00000001
                            ; retains the last bit of that character

or al,bh
                            ; makes sure that al is unchanged but the last bit is replaced with bh's last bit

mov [di],al
                            ; makes sure the new 8 bit is made and replaces the current pixel array element with encrypted character's last bit.
                            ; now we move on to the next bit of the current character
shr bl,1
                            ; since we used the last bit now moving to second last bit to be placed in new array element
                            ; we move the whole 8 bits to right, dropping the last bit 
inc di
                            ; points to next (200) element 
dec dl
                            ; this counts the character left to embed
jnz bitLoop
inc si
                            ; if all bits are done we point to next character of encrypted text
loop characterLoop
                            ; cl decrements and cycle repeats
ret
hideMessage endp

extractMessage proc
lea si,[extractedBuffer]
                            ; this will be used to hold the original message
lea di,[pixelArray]
                            ; decrypted pixel array


mov cl,messageLength
mov ch,00h
                            ; for looping of characters

extCharLoop:
                            ; RENAMED: was characterLoop
mov bl,00h
                            ; has the bit sequence extracted

mov dl,8
                            ; counts the bits of one character
mov bh,1
                            ; for masking and shl purpose
extBitLoop:
                            ; RENAMED: was bitLoop
mov al,[di]
                            ; holds the first pixel element

and al,00000001b
                            ; retains the last bit only
cmp al,1
                            ; if last bit is 1 add it to bl 
                            ; otherwise add 0 by default
jnz defaultZero
or bl,bh
defaultZero:
shl bh,1
                            ; moving the bh to left
                            ; so mask can be second last bit now
inc di
                            ; moves one byte or next array element in pixelArray
dec dl
                            ; makes sure 8 bits are counted 
jnz extBitLoop
                            ; RENAMED: jumps back to extBitLoop
                            ; checks whether 8 chracters are done or not
mov [si],bl
                            ; replace the current byte of si with extracted bits
inc si
                            ; increament si so we move one byte right in si
loop extCharLoop
                            ; RENAMED: loops back to extCharLoop
mov byte ptr [si],'$'
                            ; making sure termination is not overwritten by my program
extractMessage endp

                  ; display menu done
                  ; 11th may,2026
                  ; mahrukh jamal
                           
displayMenu proc           

    lea dx,titleMsg          ; dx points to title message
    mov ah,09h               ; DOS function to display string
    int 21h                  ; prints titlle on screen

    lea dx,menuMsg           ; dx points to menu options
    mov ah,09h               ; DOS function to display string
    int 21h                  ; prints menu on screen

    mov ah,01h               ; DOS function for single character input
    int 21h                  ; reads user choice and stores it in AL

    ret                      ; returns to main program

displayMenu endp 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; display pixel array
; 15th may,2026
; mahrukh jamal
; no editing required
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

printArray proc

    lea si,pixelArray
                            ; si points to first pixel

    mov al,messageLength
                            ; total characters

    mov bl,8
                            ; each character has 8 bits

    mul bl
                            ; total used pixels

    mov cx,ax
                            ; cx used for loop

printLoop:

    mov al,[si]
                            ; current pixel value

    call printNumber
                            ; print pixel number

    lea dx,space
    mov ah,09h
    int 21h
                            ; prints space

    inc si
                            ; next pixel

    loop printLoop

    lea dx,newline
    mov ah,09h
    int 21h
                            ; move to next line

    ret

printArray endp

                            ; print 3-digit number logic
                            ; converts 8-bit hex to ascii
printNumber proc
                            ; takes value in AL and prints it
mov ah,0
                            ; clears ah for division
mov bl,100
                            ; sets divisor to extract hundreds digit
div bl
                            ; ax divided by bl (al=quotient, ah=remainder)

mov dl,al
                            ; moves hundreds digit to dl
add dl,48
                            ; converts numeric value to ASCII character
push ax
                            ; saves the remainder (ah) for next step
mov ah,02h
                            ; DOS function to print a single character
int 21h
                            ; prints the hundreds digit
pop ax
                            ; restores the remainder into ax

mov al,ah
                            ; moves remainder into al for next division
mov ah,0
                            ; clears ah again
mov bl,10
                            ; sets divisor to extract tens digit
div bl
                            ; ax divided by bl (al=quotient, ah=remainder)

mov dl,al
                            ; moves tens digit to dl
add dl,48
                            ; converts numeric value to ASCII character
push ax
                            ; saves the final remainder (ones digit)
mov ah,02h
                            ; DOS function to print a single character
int 21h
                            ; prints the tens digit
pop ax
                            ; restores the ones digit

mov dl,ah
                            ; moves the final ones digit to dl
add dl,48
                            ; converts numeric value to ASCII character
mov ah,02h
                            ; DOS function to print a single character
int 21h
                            ; prints the ones digit

ret
                            ; returns back to printArray loop
printNumber endp

;MUJEEB PART

; input and encryption done
                            ; 17th may, 2026
                            ; mujeeb ur rehman
                           

getInput proc
                            ; this procedure takes input from user
                            ; stores it in messageBuffer
                            ; also saves the length in messageLength

    lea dx,inputMsg
                            ; dx points to the input prompt message
    mov ah,09h
                            ; DOS function to display string
    int 21h
                            ; prints the prompt on screen

    lea dx,messageBuffer
                            ; dx points to messageBuffer
                            ; messageBuffer structure:
                            ; byte 0 = max allowed characters (8)
                            ; byte 1 = actual characters typed (filled by DOS)
                            ; byte 2 onwards = the actual characters typed
    mov ah,0ah
                            ; DOS function for buffered keyboard input
    int 21h
                            ; user types here, DOS fills the buffer

    mov al,messageBuffer+1
                            ; byte at position 1 holds actual length typed
    mov messageLength,al
                            ; store it in messageLength for later use

    ret
                            ; return to main

getInput endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                            ; input and encryption done
                            ; mujeeb ur rehman
                           
xorEncrypt proc
push bp
                            ; save old value of bp
mov bp,sp
                            ; make bp our reference point for stack
push ax
push bx
push cx
push dx
push si
push di
                            ; back up all registers so we dont destroy them

mov bx,[bp+6]
                            ; STACK MAGIC: load password array address from stack into bx
mov cx,[bp+4]
                            ; STACK MAGIC: load count of elements from stack into cx

lea si,messageBuffer+2
                            ; si points to first actual character of message
lea di,encryptedText
                            ; di points to where we store encrypted characters

encLoop:
                            ; loops each character
mov al,[si]
                            ; load one character from message buffer
mov dl,[bx]
                            ; load one character from the dynamic password
xor al,dl
                            ; encrypt message character with password character
mov [di],al
                            ; store encrypted character into encryptedText

inc si
                            ; move to next message character
inc di
                            ; move to next position in encrypted buffer
inc bx
                            ; move to next password character
loop encLoop
                            ; cx decrements and cycle repeats

mov byte ptr [di],'$'
                            ; put dollar sign at end of string

pop di
pop si
pop dx
pop cx
pop bx
pop ax
                            ; restore backed up registers in reverse order
pop bp
                            ; restore old value of bp
ret 4
                            ; go back and discard 4 bytes (2 parameters)
xorEncrypt endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                            ; input and encryption done
                            ; mujeeb ur rehman


                            
xorDecrypt proc
push bp
                            ; save old value of bp
mov bp,sp
                            ; make bp our reference point for stack
push ax
push bx
push cx
push dx
push si
push di
                            ; back up all registers so we dont destroy them

mov bx,[bp+6]
                            ; STACK MAGIC: load password array address from stack into bx
mov cx,[bp+4]
                            ; STACK MAGIC: load count of elements from stack into cx

lea si,extractedBuffer
                            ; si points to extracted encrypted characters
lea di,finalMessage
                            ; di points to where decrypted result will go

decLoop:
                            ; loops each character
mov al,[si]
                            ; load current encrypted character
mov dl,[bx]
                            ; load one character from the dynamic password
xor al,dl
                            ; decrypt character using the same password character
mov [di],al
                            ; store decrypted character into finalMessage

inc si
                            ; move to next encrypted character
inc di
                            ; move to next position in final message
inc bx
                            ; move to next password character
loop decLoop
                            ; cx decrements and cycle repeats

mov byte ptr [di],'$'
                            ; put dollar sign at end of string

pop di
pop si
pop dx
pop cx
pop bx
pop ax
                            ; restore backed up registers in reverse order
pop bp
                            ; restore old value of bp
ret 4
                            ; go back and discard 4 bytes (2 parameters)
xorDecrypt endp

hillEncrypt proc             ; hillEncrypt

push bp
mov bp,sp

push ax
push bx
push cx
push dx
push si
push di

mov cx,[bp+4]

lea si,messageBuffer+2
lea di,encryptedText

hillEncLoop:

cmp cx,0
je hillEncDone

mov al,[si]

inc si
dec cx

mov bl,0

cmp cx,0
je hillPairReady

mov bl,[si]

inc si
dec cx

hillPairReady:

push cx

mov cl,al
mov ch,bl

mov al,1
mul cl
mov dl,al

mov al,3
mul ch
add dl,al

mov al,2
mul cl
mov dh,al

mov al,7
mul ch
add dh,al

mov [di],dl
inc di

mov [di],dh
inc di

pop cx

jmp hillEncLoop

hillEncDone:

mov byte ptr [di],'$'

pop di
pop si
pop dx
pop cx
pop bx
pop ax
pop bp

ret 2

hillEncrypt endp



; hillDecrypt


hillDecrypt proc

push bp
mov bp,sp

push ax
push bx
push cx
push dx
push si
push di

mov cx,[bp+4]

lea si,extractedBuffer
lea di,finalMessage

hillDecLoop:

cmp cx,0
je hillDecDone

mov al,[si]

inc si
dec cx

mov bl,[si]

inc si
dec cx

push cx

mov cl,al
mov ch,bl

mov al,7
mul cl
mov dl,al

mov al,253
mul ch
add dl,al

mov al,254
mul cl
mov dh,al

mov al,1
mul ch
add dh,al

mov [di],dl
inc di

mov [di],dh
inc di

pop cx

jmp hillDecLoop

hillDecDone:

mov byte ptr [di],'$'

pop di
pop si
pop dx
pop cx
pop bx
pop ax
pop bp

ret 2

hillDecrypt endp       

end main

                            ; marks end of file and sets entry point to main
