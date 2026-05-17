Secure Message System README

Overview

This Assembly language program encrypts a message of up to 8 characters using a dynamic XOR password. It then hides the resulting encrypted text within a 64 byte simulated pixel array using Least Significant Bit steganography. It is designed for a 16 bit DOS environment.

Features

Menu driven interface
Dynamic XOR password encryption and decryption
Data hiding in an array using bit masking
Hex to ASCII conversion for array visualization
Safe program termination

Requirements

DOSBox or compatible DOS emulator
MASM or TASM assembler

Authors

Syed Areeb Kareem
Mahrukh Jamal
Mujeeb ur Rehman

## Instructions

1. Assemble the source file into an object file
2. Link the object file to create an executable
3. Run the executable in your DOS emulator
4. Press 1 to input a message and a password
5. Press 2 to extract the hidden bits and decrypt the message
6. Press 3 to view the originally typed text
7. Press 4 to safely exit the system