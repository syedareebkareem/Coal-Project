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
resultMsg db 13,10,'Recovered Message: $'                         ; label before showing extracted message
space db ' $'                                                     ; prints space between pixel values
newline db 13,10,'$'                                              ; moves output to next line



.code  
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extractMessage proc
lea si,[extractedBuffer]
                            ; this will be used to hold the original message
lea di,[pixelArray]
                            ; decrypted pixel array


mov cl,messageLength
mov ch,00h
                            ; for looping of characters
mov bl,00h
                            ; has the bit sequence extracted
characterLoop:
mov dl,8
                            ; counts the bits of one character
mov bh,1
                            ; for masking and shl purpose
bitLoop:
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
jnz bitLoop
                            ; checks whether 8 chracters are done or not
mov [si],bl
                            ; replace the current byte of si with extracted bits
inc si
                            ; increament si so we move one byte right in si
loop characterLoop
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
