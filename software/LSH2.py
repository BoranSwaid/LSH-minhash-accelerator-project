from ctypes import c_uint32
import mmh3

#function that convert int to 32-bit unsignedint
def int32(val):
    return c_uint32(val).value

#function that convert int into bytes
def int_to_bytes(x: int) -> bytes:
    return x.to_bytes((x.bit_length() + 7) // 8, 'big')

def int_from_bytes(xbytes: bytes) -> int:
    return int.from_bytes(xbytes, 'big')

#returns the opposite RNA
def oppositeRNA(read):
    newRead = ''
    for s in read:
        if(s == 'A'):
            newRead += 'T'
        elif(s == 'T'):
            newRead += 'A'
        elif(s == 'C'):
            newRead += 'G'
        else:
            newRead += 'C'

    return newRead

class MinHash:
    def __init__(self, G, l = 128, k = 16, s = 16):
        self.G = G #reference genome
        self.l = l #window len
        self.k = k #k-mer len
        self.s = s #signature len
        self.sigTable = {} #our hashtable

    #find smallest s values for the signature
    def smallestMValues(self, list):
        list.sort()
        return list[0:self.s]

    #cut genome into windows of legnth l and cut every window into k-mers
    def buildWindows(self, g):
        windows = {}
        for i in range(0, len(g) - 1, self.l):
            if i + self.l > len(g) -1 :
                windows[g[i: len(g)]] = [i, len(g) - 1] #the key is the genome sequence and value is the window edges
                break
            else:
                windows[g[i: i + self.l]] = [i, i + self.l - 1]
        return windows

    #wrapper function that biuld windows and hash the k-mers
    def buildRefTable(self):
        windows = {}
        windows = self.buildWindows(self.G)
        list = []
        self.hashKmers(windows, 1, list)

    #hash every k-mer to the signaturesTAble with MurmurHash
    def hashKmers(self, windows, gID, list):
        hash1Values = []
        for w in windows:
            for i in range(0, len(w) - 1 , self.k):
                if i + self.k < len(w):
                    hash1Values.append(mmh3.hash(w[i:i+self.k], 123, False))
                else:
                    hash1Values.append(mmh3.hash(w[i:len(w)], 123, False))
            sig = self.smallestMValues(hash1Values) #get the signature
            hash1Values = []
            for j in range(min(self.s, len(sig))):
                hash2Value = mmh3.hash(int_to_bytes(sig[j]), 123, False)
                if list != None : #this list is used to save the values of the read input
                    list.append(hash2Value)
                if hash2Value in self.sigTable.keys():
                    self.sigTable[hash2Value].append([gID, windows[w]])
                else:
                    self.sigTable[hash2Value]= [[gID, windows[w]]]

    #wrapper function to hash the read
    def hashRead(self, read):
        windows = self.buildWindows(read)
        myList = [] #this list is used to save the values of the read input
        self.hashKmers(windows, 2, myList)
        return myList

    #find the candidate pairs for the read
    def findCandidatePairs(self, read):
        myList = self.hashRead(read)
        candidatePairs = {}
        for x in myList: #for every value of the sub-vector of signature
            for val in self.sigTable[x]: #for every segment in the list
                if val[0] == 1: #if the segment is in reference (ID = 1)
                    if val[1][0] in candidatePairs.keys(): #if the segment added to candidate pairs
                        candidatePairs[val[1][0]]+=1 #add the counter of this segment
                    else:
                        candidatePairs[val[1][0]] = 1 #counter = 1
        return candidatePairs

    def FindMaxCount(self, candidates):
        maxCount = 0
        maxCountWindow = -1
        for c in candidates.keys():  # find the segment that has max counter
            if candidates[c] > maxCount:
                maxCount = candidates[c]
                maxCountWindow = c
        if maxCount >= 7: #distance condition
            return maxCountWindow
        return -1

    #find the matching window
    def FindMatchingIndex(self, read):
        candidates = self.findCandidatePairs(read)
        res = self.FindMaxCount(candidates)
        if(res == -1):
            candidates = self.findCandidatePairs(oppositeRNA(read))
            res = self.FindMaxCount(candidates)

        return res


myFile = open("refSeq", "r")
myGenome = ''
lines = myFile.readlines()
for line in lines:
    myGenome = myGenome + line.strip()
print(myGenome)
minHash = MinHash(myGenome, 64, 8, 8)
minHash.buildRefTable()
res = minHash.FindMatchingIndex('AGAGGCACGTCAACATCTTAAAGATGGCACTTGTGGCTTAGTAGAAGTTGAAAAATTATGGGGT')
for k in minHash.sigTable.keys():
    print(k, ':', minHash.sigTable[k])
print(res)  # returns the left edge of the segment