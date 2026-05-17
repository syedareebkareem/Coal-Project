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
xorKey db 05h  ;
                            ;xorKey is used to encrypt the data
                            ;we might change it to perform dynamically if time remains 


                            ; display data added
                            ; 11th may,2026
                            ; mahrukh jamal
                            ; no editing required

pixelArray db 64 dup(200)
                            ; we have 8 characters
                            ; each character has 8 bits
                            ; each bit is stored in 1 pixel
                            ; 8(pixel) x 8(characters) = 64 pixels array



                            ; display data added
                            ; 11th may,2026
                            ; mahrukh jamal
                            ; no editing required

titleMsg db 13,10,'===== SECURE MESSAGE SYSTEM =====',13,10,'$'   ; title shown at program start
menuMsg db 13,10,'1. Start',13,10,'2. Exit',13,10,'Choice: $'     ; menu options shown to user
inputMsg db 13,10,'Enter yoUr Message (MAX 8 CHARS): $'
resultMsg db 13,10,'Recovered Message: $'                         ; label before showing extracted message
space db ' $'                                                     ; prints space between pixel values
newline db 13,10,'$'                                              ; moves output to next line



.code  
                            ; main execution flow
                            ; links all modules together
main proc
                            ; initializes data and controls execution
mov ax,@data
                            ; loads data segment address into ax
mov ds,ax
                            ; moves it to data segment register

call displayMenu
                            ; shows the initial menu on screen
call getInput
                            ; takes the user input and stores length
call xorEncrypt
                            ; encrypts the captured message
call hideMessage
                            ; hides the encrypted text into pixelArray
call printArray
                            ; prints the pixel values to the screen
call extractMessage
                            ; recovers hidden data from pixelArray
call xorDecrypt
                            ; reverses encryption to get final text


lea dx, newline
mov ah, 09h
int 21h                     ; prints an empty line for neatness

lea dx, resultMsg
mov ah, 09h
int 21h                     ; prints "Recovered Message: "

lea dx, finalMessage
mov ah, 09h
int 21h                     ; prints the actual decrypted word (e.g., "areeb")

lea dx, newline
mov ah, 09h
int 21h                     ; prints a final empty line
;


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
                            ; this procedure encrypts the message
                            ; reads each character from messageBuffer
                            ; XORs it with xorKey (05h)
                            ; stores encrypted character in encryptedText
                            ;
                            ; how XOR encryption works:
                            ; original char:  01000001  (letter A = 65)
                            ; XOR key:        00000101  (key = 5)
                            ; result:         01000100  (encrypted = 68)

    mov cl,messageLength
                            ; cl = number of characters to process
    mov ch,00h
                            ; ch = 0 so cx is correct for loop instruction
                            ; loop uses cx as counter

    lea si,messageBuffer+2
                            ; si points to first actual character
                            ; +2 because byte 0 = maxLen, byte 1 = actualLen
                            ; byte 2 onwards = real characters

    lea di,encryptedText
                            ; di points to where we store encrypted characters

encLoop:
                            ; loop starts here
                            ; processes one character per iteration

    mov al,[si]
                            ; al = current character from input buffer
    xor al,xorKey
                            ; al = al XOR 05h
                            ; this encrypts the character
    mov [di],al
                            ; store encrypted character into encryptedText

    inc si
                            ; move to next input character
    inc di
                            ; move to next position in encrypted buffer

    loop encLoop
                            ; cx = cx - 1
                            ; if cx is not zero go back to encLoop

    mov byte ptr [di],'$'
                            ; put dollar sign at end
                            ; so DOS knows where the string ends

    ret
                            ; return to main

xorEncrypt endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                            ; input and encryption done
                            ; mujeeb ur rehman
                            
xorDecrypt proc
                            ; this procedure decrypts the extracted message
                            ; reads each character from extractedBuffer
                            ; XORs it again with the SAME key (05h)
                            ; this reverses the encryption
                            ; stores result in finalMessage
                            ;
                            ; why XOR twice gives original:
                            ; encrypt: A XOR key = B
                            ; decrypt: B XOR key = A
                            ; XOR with same key cancels itself

    mov cl,messageLength
                            ; cl = number of characters to decrypt
    mov ch,00h
                            ; ch = 0 so cx is correct for loop

    lea si,extractedBuffer
                            ; si points to extracted encrypted characters
    lea di,finalMessage
                            ; di points to where decrypted result will go

decLoop:
                            ; loop starts here
                            ; processes one character per iteration

    mov al,[si]
                            ; al = current encrypted character
    xor al,xorKey
                            ; al = al XOR 05h
                            ; same operation as encrypt = decrypts it
    mov [di],al
                            ; store decrypted character into finalMessage

    inc si
                            ; move to next encrypted character
    inc di
                            ; move to next position in final message

    loop decLoop
                            ; cx = cx - 1
                            ; if cx is not zero go back to decLoop

    mov byte ptr [di],'$'
                            ; put dollar sign at end
                            ; so DOS knows where the string ends

    ret
                            ; return to main

xorDecrypt endp
end main
                            ; marks end of file and sets entry point to main
