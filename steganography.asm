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

finalMessage db 9,?,"$","$","$","$","$","$","$","$","$"
; this will also hold 9 array characters as last character will hold the terminator $ which doesnt count

messageLength db ?
; we store message length here and db is used because we need to match register size too

xorKey db 05h  ;
;xorKey is used to encrypt the data
;we might change it to perform dynamically if time remains 

pixelArray db 64 dup(200)
; we have 8 characters
; each character has 8 bits
; each bit is stored in 1 pixel
; 8(pixel) x 8(characters) = 64 pixels array 
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
