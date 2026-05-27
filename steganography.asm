                            ; main code file
.model small
.stack 100h
.data
messageBuffer db 8,?,"$","$","$","$","$","$","$","$"
                            ; This messageBuffer is holding the input value a user might enter
                            ; We did this to hold only 8 characters
                            ; Dollar sign is the terminator
                            ; if user enters Syed and enters
                            ; the fifth character will act as terminator and stops the input before reaching 8th value
encryptedText db 9,?,"$","$","$","$","$","$","$","$","$"
                            ; this holds 9 array characters as last character will hold the terminator $ which doesnt count
extractedBuffer db 9,?,"$","$","$","$","$","$","$","$","$"
finalMessage db 9,?,"$","$","$","$","$","$","$","$","$"
                            ; this will also hold 9 array characters as last character will hold the terminator $ which doesnt count
messageLength db ?
                            ; we store message length here and db is used because we need to match register size too
;xorKey db 05h  ;
                            ;xorKey is used to encrypt the data
                            ;we might change it to perform dynamically if time remains 
; now we are making it dynamic

keyPrompt db 13,10,'Enter Password (MAX 8 CHARS): $'
                            ; prompt asking user for dynamic encryption key
keyBuffer db 9,?,9 DUP('$')
                            ; buffer to store the dynamic password array

                            ; display data added
                            ; 11th may,2026
                            ; mahrukh jamal
                            ; no editing required
caesarShift db ?

hillMatrix db 1,2,3,7

hillInvMatrix db 7,254,253,1

pixelArray db 64 dup(200)
                            ; we have 8 characters
                            ; each character has 8 bits
                            ; each bit is stored in 1 pixel
                            ; 8(pixel) x 8(characters) = 64 pixels array



                            ; display data added
                            ; 11th may,2026
                            ; mahrukh jamal
                            ; no editing required


titleMsg db 13,10,'===== SECURE MESSAGE SYSTEM =====',13,10,'$'
menuMsg db 13,10,'1. Send Cipher',13,10,'2. Receive Cipher',13,10,'3. Print Original',13,10,'4. Exit',13,10,'Choice: $'
msgOrig db 13,10,'Original Message: $'
msgEnc db 13,10,'Encrypted Message: $'
inputMsg db 13,10,'Enter Message (MAX 8 CHARS): $'
resultMsg db 13,10,'Recovered Message: $'
space db ' $'
newline db 13,10,'$'

.code  
                           ; main execution flow

main proc
                            ; initializes data and controls execution
mov ax,@data
mov ds,ax

menuStart:
                            ; loop back point for the menu
call displayMenu
                            ; al now holds the user choice (1, 2, 3, or 4)

cmp al,'1'
je optSend
                            ; if 1, jump to send cipher

cmp al,'2'
je optReceive
                            ; if 2, jump to receive cipher

cmp al,'3'
je optOriginal
                            ; if 3, jump to print original

jmp endProgram
                            ; if anything else (like 4), exit program

optSend:
call getInput
                            ; takes the original message
lea dx,keyPrompt
mov ah,09h
int 21h
                            ; prints password prompt
lea dx,keyBuffer
mov ah,0ah
int 21h
                            ; gets password from user
lea ax,keyBuffer+2
push ax
mov al,messageLength
mov ah,00h
push ax
                            ; push parameters
call xorEncrypt
                            ; encrypt the message
call hideMessage
                            ; hide in pixel array
call printArray
                            ; print the array
jmp menuStart
                            ; go back to main menu

optReceive:
call extractMessage
                            ; pull hidden bits out of array
lea dx,newline
mov ah,09h
int 21h
lea dx,msgEnc
mov ah,09h
int 21h
lea dx,extractedBuffer
mov ah,09h
int 21h
                            ; print the raw encrypted characters
lea ax,keyBuffer+2
push ax
mov al,messageLength
mov ah,00h
push ax
                            ; push parameters
call xorDecrypt
                            ; decrypt the text
lea dx,newline
mov ah,09h
int 21h
lea dx,resultMsg
mov ah,09h
int 21h
lea dx,finalMessage
mov ah,09h
int 21h
                            ; print recovered final message
jmp menuStart
                            ; go back to main menu

optOriginal:
lea dx,newline
mov ah,09h
int 21h
lea dx,msgOrig
mov ah,09h
int 21h
lea dx,messageBuffer+2
mov ah,09h
int 21h
                            ; prints the original typed message
jmp menuStart
                            ; go back to main menu

endProgram:
mov ah,4ch
                            ; DOS interrupt code to terminate program safely
int 21h
                            ; returns control to the operating system
main endp

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

; caesarEncrypt


caesarEncrypt proc

push bp
mov bp,sp

push ax
push bx
push cx
push si
push di

mov cx,[bp+4]

lea si,messageBuffer+2
lea di,encryptedText

mov bl,caesarShift

caesarEncLoop:

mov al,[si]

add al,bl

mov [di],al

inc si
inc di

loop caesarEncLoop

mov byte ptr [di],'$'

pop di
pop si
pop cx
pop bx
pop ax
pop bp

ret 2

caesarEncrypt endp


caesarDecrypt proc            ; caesarDecrypt

push bp
mov bp,sp

push ax
push bx
push cx
push si
push di

mov cx,[bp+4]

lea si,extractedBuffer
lea di,finalMessage

mov bl,caesarShift

caesarDecLoop:

mov al,[si]

sub al,bl

mov [di],al

inc si
inc di

loop caesarDecLoop

mov byte ptr [di],'$'

pop di
pop si
pop cx
pop bx
pop ax
pop bp

ret 2

caesarDecrypt endp


end main

                            ; marks end of file and sets entry point to main
