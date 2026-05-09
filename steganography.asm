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

.code
