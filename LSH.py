from ctypes import c_uint32

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
    def __init__(self, G, l = 128, k = 16, s = 16, ov_l = 2):
        self.G = G #reference genome
        self.l = l #window len
        self.k = k #k-mer len
        self.s = s #signature len
        self.ov_l = ov_l #overlaping of the k-mers
        self.sigTable = {} #our hashtable

    #shift-XOR murmur function
    def murmurFunc(self, key, len, seed):
        c1 = 0xcc9e2d51
        c2 = 0x1b873593
        r1 = 15
        r2 = 13
        m = 0x5
        n = 0xe6546b64
        Hash = seed

        i = 0
        while i < len:
            # for each four byte chunk
            if i + 4 <= len:
                fourChunk_1 = key[i] << 24
                fourChunk_2 = key[i + 1] << 16
                fourChunk_3 = key[i + 2] << 8
                fourChunk_4 = key[i + 3]
                fourByteChunk = fourChunk_1 + fourChunk_2 + fourChunk_3 + fourChunk_4

                fourByteChunk = fourByteChunk * c1
                fourByteChunk = fourByteChunk << r1
                fourByteChunk = fourByteChunk * c2

                Hash = Hash ^ fourByteChunk
                Hash = Hash << r2
                Hash = Hash * m + n

                i += 4

            else:
                # for remaining bytes
                i = len - i
                fourChunk_1 = 0
                fourChunk_2 = 0
                fourChunk_3 = 0
                while i != len:
                    remaining = i % 4
                    if (remaining == 1):
                        fourChunk_1 = key[i] << 16
                    elif (remaining == 2):
                        fourChunk_2 = key[i] << 8
                    else:
                        fourChunk_3 = key[i]
                    i += 1
                remainigBytes = fourChunk_1 + fourChunk_2 + fourChunk_3

                remainigBytes = remainigBytes * c1
                remainigBytes = remainigBytes << r1
                remainigBytes = remainigBytes * c2

                Hash = Hash ^ remainigBytes

        Hash = (Hash ^ len)

        Hash = Hash ^ (Hash >> 16)
        Hash = Hash * 0x85ebca6b
        Hash = Hash ^ (Hash >> 13)
        Hash = Hash * 0xc2b2ae35
        Hash = Hash ^ (Hash >> 16)
        return int32(Hash)

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

    def hash1Func(self, w):
        hash1Values = []
        for i in range(0, len(w) - 1, self.ov_l):
            if i + self.k < len(w):
                hash1Values.append(self.murmurFunc(bytes(w[i:i + self.k], 'UTF-8'), len(w[i:i + self.k]), 123))
            else:
                hash1Values.append(self.murmurFunc(bytes(w[i:len(w)], 'UTF-8'), len(w[i:len(w)]), 123))
        return self.smallestMValues(hash1Values)

    def hash2Func(self, w, windows, gID, sig, list):
        for j in range(min(self.s, len(sig))):
            hash2Value = self.murmurFunc(int_to_bytes(sig[j]), len(int_to_bytes(sig[j])), 123)
            list.append(hash2Value)
            if hash2Value in self.sigTable.keys():
                self.sigTable[hash2Value].append([gID, windows[w]])
            else:
                self.sigTable[hash2Value] = [[gID, windows[w]]]
    #hash every k-mer to the signaturesTAble with MurmurHash
    def hashKmers(self, windows, gID, list):
        sig = []
        for w in windows:
            sig = self.hash1Func(w)
            self.hash2Func(w, windows, gID, sig, list)

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

    #find the matching window
    def FindMaxCount(self, candidates):
        maxCount = 0
        maxCountWindow = -1
        for c in candidates.keys():  # find the segment that has max counter
            if candidates[c] > maxCount:
                maxCount = candidates[c]
                maxCountWindow = c
        if maxCount >= ((self.l/self.k)-1):
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

