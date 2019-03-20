#!/usr/bin/python

#-------------------------------------------------------------------------------
# Name:        Simulation Output Comparison
# Purpose:     This script take two files as parameters and compares. The one
#              contains an ideal, error-free output and the other the output to
#              be tested. The files compared are the output files of the RTL
#              pipeline (between the Response Kernel and the MaxUDP).
#
# Author:      kimonk
#
# Created:     30/11/2012
#-------------------------------------------------------------------------------

import sys

state = 0 # State indicates how the current data word should be. 0 means idle, 1 means SOP has been found and metadata is being output, 2 that extra and value are being read and 3 that only value is being read.
operation = 0 # Differentiates between sets and gets
pktCounter = 0
valueLength = 0
packetWord = 0
noOfSOPs = 0
noOfEOPs = 0
EOP = False

def errorCheck(gLine, iLine): # This function uses information recorded during parsing to determine the issue.
    # There are several cases to differentiate from:
    # i) set or get
    # ii)
    global state, pktCounter, operation, EOP
    if (state == 1 or EOP == True):
        if (pktCounter == 0): # This is the 1st header data word (Magic, OpCode, KeyLength, Extraslength, DataType, Status)
            if(iLine[43:45] != gLine[43:45]):
                print("Error. Magic field doesn't match")
            if (iLine[41:43] != gLine[41:43]):
                print("Error. OpCode field doesn't match")
            if(iLine[37:41] != gLine[37:41]):
                print("Error. Key length doesn't match")
            if (iLine[35:37] != gLine[35:37]):
                print("Error. Extras length doesn't match")
            if(iLine[33:35] != gLine[33:35]):
                print("Error. Data type field doesn't match")
            if (iLine[31:35] != gLine[31:35]):
                print("Error. Status field doens't match")
        elif (pktCounter == 1): # This is the 2nd header data word (Length and Opaque)
            temp = iLine[29:37]
            if(iLine[38:45] != gLine[38:45]):
                print("Error. Total length field doesn't match")
            if (iLine[29:37] != gLine[29:37]):
                print("Error. Opaque value doesn't match")
        elif (pktCounter == 2): # this is the data word containing the CAS
            print("Error. CAS doesn't match")
        elif (pktCounter == 3): # This is the data word which is half extras and half value
            if (operation == 1):
                print("Error. Extras and value detected in a set response")
            elif (operation == 0):
                if(iLine[38:45] != gLine[38:45]):
                    print("Error. Extras don't match")
                if (iLine[29:37] != gLine[29:37]):
                    print("Error. Value doesn't match")
        elif (pktCounter > 3): # This includes all other value words except the one which is common with the extras
            if (operation == 1):
                print("Error. Extras and value detectes in a set response")
            elif (operation == 0):
                print("Error. Value doesn't match")

def evalState(iLine): # evaluates the state of the packet
    global noOfSOPs, noOfEOPs, state, pktCounter, operation, EOP
    if (state != 0):
        pktCounter += 1
    if (int(iLine[27:28], 16) % 2 == 1): # SOP found
        noOfSOPs += 1
        state = 1
        operation = int(iLine[41:43], 16)
        # Store the key and  value lengths
        return
    if (int(iLine[28:29], 16) >= 8): # EOP found
        if (state != 0):
            EOP = True
            noOfEOPs += 1
            state = 0
            return
        else:
            # print("Error - Line " + str(counter) + ". EOP found without coresponding SOP")
            return
    if (pktCounter == 1 and operation == 0): # if this is the 2nd packet word and the operation is a get
        valueLength = int(iLine[45:46] + iLine[44:45] + iLine[40:41] + iLine[39:40], 16) - 4

def compareLines(gLine, iLine): # compares the two lines and determines if they match
    match = False
    if (gLine == iLine): # if the lines match
        match = True # set the proper bool to true
    return match # return the proper variable

if (len(sys.argv) !=3):
	print("Error! Incorrect number of arguments passed.")
	sys.exit(2)
else:
	gFileName = sys.argv[1] # All graphs are saved as images if activated
	iFileName = sys.argv[2] # Graph output is activatedd if true
counter = 0
goldenFile = open(gFileName, 'r')
inputFile = open(iFileName, 'r')
for iLine in inputFile:
	counter += 1
	line = iLine.split()
	if (line[3] == "2"):
		#evalState(iLine)
		gLine = goldenFile.readline()
        	if (compareLines(gLine, iLine) == False):
			errorCheck(gLine, iLine)
			print("Error! Output line " + str(counter) + " not identical.")
			sys.exit(1)
	else:
		continue
	if (EOP == True):
		EOP = False
		pktCounter = 0
gLine = goldenFile.readline()   # probe the golden file for additional lines
if (gLine != ""):
	if (counter == 0):
        	print("Error! Input file is empty.")
    	else:
        	print("Error! Output not complete/missing.")
    	sys.exit(1)

#if counter == 0:
	#print("Error! Input file is empty.")
	#sys.exit(1)

print("No. of SOPS: " + str(noOfSOPs) + " - No. of EOPs: " + str(noOfEOPs))
print ("Files match 100%")
inputFile.close()
goldenFile.close()
