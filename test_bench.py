import LSH
import pygal
from random import randint

myFile = open("refSeq", "r")
myGenome = ''
lines = myFile.readlines()
for line in lines:
    myGenome = myGenome + line.strip()
myFile.close()

file2 = open("bacteriaRef", "r")
Genome2 = ''
lines2 = file2.readlines()
for line in lines2:
    Genome2 = Genome2 + line.strip()
file2.close()

#tests for read len
def test1():
    minHash = LSH.MinHash(myGenome, 64, 8, 8)
    minHash.buildRefTable()
    resDict = {16 :  0, 32 : 0, 64 : 0, 128: 0, 256 : 0}

    b = [16, 32, 64, 128, 256]
    for s in b:
        a = 0
        for i in range(0,20):
            #a = randint(0, int(len(myGenome)/s)) * s
            read = myGenome[a:a+s]
            res = minHash.FindMatchingIndex(read)
            if (res != -1):
                resDict[s] += 1
            a = a + s

    hist = pygal.Bar()
    hist.title = 'read length test'
    for s in b:
        hist.add(str(s), resDict[s])
    hist.render_in_browser()

#test 3 kinds of errors starts here
readsA = {64 : [], 128 : []}
readsB = {64: [], 128: []}
for j in readsA.keys():
    for i in range(0, int(len(myGenome)/j)):
        readsA[j].append(myGenome[i * j: (i+1)*j])
for j in readsB.keys():
    for i in range(0, int(len(Genome2)/j)):
        readsB[j].append(Genome2[i * j: (i+1)*j])

#helper functions
def add_randomly(i, read):
    new_read = read
    chars = ['A', 'C', 'T', 'G']
    for j in range(0, i):
        index = randint(0, len(read) - 1)
        added = randint(0, 3)
        new_read = new_read[:index] + chars[added] + new_read[index+1:]
    return new_read

def replace_randomly(i, read):
    new_read = read
    for j in range(0, i):
        index = randint(0, len(read)-1)
        if read[len(read)-1 -j] == 'A':
            new_read = new_read[:index] + 'C' + new_read[index+1:]
        elif read[len(read)-1 -j] == 'C':
            new_read = new_read[:index] + 'A' + new_read[index+1:]
        elif read[len(read)-1 - j] == 'T':
            new_read = new_read[:index] + 'G' + new_read[index+1:]
        else:
            new_read = new_read[:index] + 'T' + new_read[index+1:]
    return new_read

def delete_randomely(i, read):
    new_read = read
    for j in range(0, i):
        index = randint(0, len(read) - 1)
        new_read = new_read[:index] + new_read[index + 1:]
    return new_read

def test_TP(mh, replacment, insertion, deletion):
    hits = 0
    for read in readsA[mh.l]:
        for e1 in range(int(replacment)):
            if(int(insertion)):
                for e2 in range(int(insertion)):
                    if(deletion != 0):
                        for e3 in range(int(deletion)):
                            new_read = ''
                            new_read = replace_randomly(e1, read)
                            new_read = add_randomly(e1, read)
                            new_read = delete_randomely(e3, read)
                            res = mh.FindMatchingIndex(new_read)
                            if res != -1:
                                hits+=1
                    else:
                        new_read = ''
                        new_read = replace_randomly(e1, read)
                        new_read = add_randomly(e1, read)
                        res = mh.FindMatchingIndex(new_read)
                        if res != -1:
                            hits += 1
            else:
                if (int(deletion) != 0):
                    for e3 in range(int(deletion)):
                        new_read = ''
                        new_read = replace_randomly(e1, read)
                        new_read = delete_randomely(e3, read)
                        res = mh.FindMatchingIndex(new_read)
                        if res != -1:
                            hits += 1
                else:
                    new_read = ''
                    new_read = replace_randomly(e1, read)
                    res = mh.FindMatchingIndex(new_read)
                    if res != -1:
                        hits += 1

    return hits

def test_FN(mh, replacment, insertion, deletion):
    misses = 0
    for read in readsA[mh.l]:
        for e1 in range(int(replacment)):
            if (int(insertion)):
                for e2 in range(int(insertion)):
                    if (deletion != 0):
                        for e3 in range(int(deletion)):
                            new_read = ''
                            new_read = replace_randomly(e1, read)
                            new_read = add_randomly(e1, read)
                            new_read = delete_randomely(e3, read)
                            res = mh.FindMatchingIndex(new_read)
                            if res == -1:
                                misses += 1
                    else:
                        new_read = ''
                        new_read = replace_randomly(e1, read)
                        new_read = add_randomly(e1, read)
                        res = mh.FindMatchingIndex(new_read)
                        if res == -1:
                            misses += 1
            else:
                if (int(deletion) != 0):
                    for e3 in range(int(deletion)):
                        new_read = ''
                        new_read = replace_randomly(e1, read)
                        new_read = delete_randomely(e3, read)
                        res = mh.FindMatchingIndex(new_read)
                        if res == -1:
                            misses += 1
                else:
                    new_read = ''
                    new_read = replace_randomly(e1, read)
                    res = mh.FindMatchingIndex(new_read)
                    if res == -1:
                        misses += 1
    return misses

def test_FP(mh, replacment, insertion, deletion):
    hits = 0
    for read in readsB[mh.l]:
        for e1 in range(int(replacment)):
            if(int(insertion)):
                for e2 in range(int(insertion)):
                    if(deletion != 0):
                        for e3 in range(int(deletion)):
                            new_read = ''
                            new_read = replace_randomly(e1, read)
                            new_read = add_randomly(e1, read)
                            new_read = delete_randomely(e3, read)
                            res = mh.FindMatchingIndex(new_read)
                            if res != -1:
                                hits+=1
                    else:
                        new_read = ''
                        new_read = replace_randomly(e1, read)
                        new_read = add_randomly(e1, read)
                        res = mh.FindMatchingIndex(new_read)
                        if res != -1:
                            hits += 1
            else:
                if (int(deletion) != 0):
                    for e3 in range(int(deletion)):
                        new_read = ''
                        new_read = replace_randomly(e1, read)
                        new_read = delete_randomely(e3, read)
                        res = mh.FindMatchingIndex(new_read)
                        if res != -1:
                            hits += 1
                else:
                    new_read = ''
                    if(len(read) == 0):
                        print('here')
                    new_read = replace_randomly(e1, read)
                    res = mh.FindMatchingIndex(new_read)
                    if res != -1:
                        hits += 1

    return hits

def test_TN(mh, replacment, insertion, deletion):
    misses = 0
    for read in readsB[mh.l]:
        for e1 in range(int(replacment)):
            if (int(insertion)):
                for e2 in range(int(insertion)):
                    if (deletion != 0):
                        for e3 in range(int(deletion)):
                            new_read = ''
                            new_read = replace_randomly(e1, read)
                            new_read = add_randomly(e1, read)
                            new_read = delete_randomely(e3, read)
                            res = mh.FindMatchingIndex(new_read)
                            if res == -1:
                                misses += 1
                    else:
                        new_read = ''
                        new_read = replace_randomly(e1, read)
                        new_read = add_randomly(e1, read)
                        res = mh.FindMatchingIndex(new_read)
                        if res == -1:
                            misses += 1
            else:
                if (int(deletion) != 0):
                    for e3 in range(int(deletion)):
                        new_read = ''
                        new_read = replace_randomly(e1, read)
                        new_read = delete_randomely(e3, read)
                        res = mh.FindMatchingIndex(new_read)
                        if res == -1:
                            misses += 1
                else:
                    new_read = ''
                    new_read = replace_randomly(e1, read)
                    res = mh.FindMatchingIndex(new_read)
                    if res == -1:
                        misses += 1
    return misses

def low_error_rate(mh_list):

    hist = pygal.Bar()
    hist.title = 'acc% per parameters set \n low error rate'

    for mh in mh_list:
        tp = test_TP(mh, 3.6/100*mh.l, 0.2/100*mh.l, 0.2/100*mh.l)
        fn = test_FN(mh, 3.6/100*mh.l, 0.2/100*mh.l, 0.2/100*mh.l)
        fp = test_FP(mh, 3.6/100*mh.l, 0.2/100*mh.l, 0.2/100*mh.l)
        tn = test_TN(mh, 3.6/100*mh.l, 0.2/100*mh.l, 0.2/100*mh.l)

        if tp+tn+fn+fp != 0 :
            acc = (tp + tn)/(tp+tn+fn+fp)
        else:
            acc = 0
        hist.add(f'({mh.l}, {mh.k}, {mh.ov_l})', acc*100)

    hist.render_in_browser()

def high_error_rate(mh_list):
    hist = pygal.Bar()
    hist.title = 'acc% per parameters set \n high error rate'

    for mh in mh_list:
        tp = test_TP(mh, 1/100 * mh.l, 7/100 * mh.l, 7/100 * mh.l)
        fn = test_FN(mh, 1/100 * mh.l, 7/100 * mh.l, 7/100 * mh.l)
        fp = test_FP(mh, 1/100 * mh.l, 7/100 * mh.l, 7/100 * mh.l)
        tn = test_TN(mh, 1/100 * mh.l, 7/100 * mh.l, 7/100 * mh.l)
        if tp + tn + fn + fp != 0:
            acc = (tp + tn) / (tp + tn + fn + fp)
        else:
            acc = 0
        hist.add(f'({mh.l}, {mh.k}, {mh.ov_l})', acc * 100)

    hist.render_in_browser()

def test2():
    minhash_list = [LSH.MinHash(myGenome, 64, 8, 8), LSH.MinHash(myGenome, 64, 16, 16), LSH.MinHash(myGenome, 128, 8, 8), LSH.MinHash(myGenome, 128, 16, 16),
                    LSH.MinHash(myGenome, 64, 8 , 8, 4), LSH.MinHash(myGenome, 128, 16, 16, 8)]
    for mh in minhash_list:
        mh.buildRefTable()

    low_error_rate(minhash_list)
    high_error_rate(minhash_list)


test1()
test2()

'''
def switch_at_end(i, read):
    new_read = read
    for j in range(0, i):
        if read[len(read)-1 -j] == 'A':
            new_read = new_read[:len(read) - 1 - j] + 'C' + new_read[len(read) - 1 - j+1:]
        elif read[len(read)-1 -j] == 'C':
            new_read = new_read[:len(read) - 1 - j] + 'A' + new_read[len(read) - 1 - j+1:]
        elif read[len(read)-1 - j] == 'T':
            new_read = new_read[:len(read) - 1 - j] + 'G' + new_read[len(read) - 1 - j+1:]
        else:
            new_read = new_read[:len(read) - 1 - j] + 'T' + new_read[len(read) - 1 - j+1:]
    return new_read

def switch_by_steps(step, i, read):
    new_read = read
    for j in range(0, i):
        if read[len(read) - 1 - j*step] == 'A':
            new_read = new_read[:len(read) - 1 - j*step] + 'C' + new_read[len(read) - 1 - j*step+1:]
        elif read[len(read) - 1 - j*step] == 'C':
            new_read = new_read[:len(read) - 1 - j*step] + 'A' + new_read[len(read) - 1 - j*step+1:]
        elif read[len(read) - 1 - j*step] == 'T':
            new_read= new_read[:len(read) - 1 - j*step] + 'G' + new_read[len(read) - 1 - j*step+1:]
        else:
            new_read= new_read[:len(read) - 1 - j*step] + 'T' + new_read[len(read) - 1 - j*step+1:]
    return new_read


def test2_aux(minHash, len):
    hist = pygal.Bar()
    hist.title = 'hits per distance' + f'{len} read (switched)'

    results = {}
    for i in range(0, 20):
        results[i] = 0

    for i in range(0, 20):
        myRead1 = switch_at_end(i, reads[len])
        res1 = minHash.FindMatchingIndex(myRead1)
        if (res1 != -1):
            if i in results:
                results[i] += 1

        step = 3
        myRead2 = switch_by_steps(step, i, reads[len])
        res2 = minHash.FindMatchingIndex(myRead2)
        if (res2 != -1):
            if i in results:
                results[i] += 1

        myRead3 = switch_randomly(i, reads[len])
        res3 = minHash.FindMatchingIndex(myRead3)
        if (res3 != -1):
            if i in results:
                results[i] += 1

        hist.add(str(i), results[i])

    hist.render_in_browser()

def test2_switched_letters():
    minHash64 = LSH.MinHash(myGenome, 64, 8, 8)
    minHash64.buildRefTable()

    minHash128 = LSH.MinHash(myGenome, 128, 16, 16)
    minHash128.buildRefTable()

    test2_aux(minHash64, 64)
    test2_aux(minHash64, 128) #not good
    test2_aux(minHash128, 64) #not good
    test2_aux(minHash128, 128)

def add_at_end(i, read):
    new_read = read
    j = i
    chars = ['A', 'C', 'T', 'G']
    for j in range(0, i):
        added = randint(0, 3)
        new_read += chars[added]
    return new_read

def test3_aux(minHash, len):
    hist = pygal.Bar()
    hist.title = 'hits per distance' + f'{len} read (added)'

    results = {}
    for i in range(0, 20):
        results[i] = 0

    for i in range(0, 20):
        myRead1 = add_at_end(i, reads[len])
        res1 = minHash.FindMatchingIndex(myRead1)
        if (res1 != -1):
            if i in results:
                results[i] += 1
        myRead3 = add_randomly(i, reads[len])
        res3 = minHash.FindMatchingIndex(myRead3)
        if (res3 != -1):
            if i in results:
                results[i] += 1

        hist.add(str(i), results[i])

    hist.render_in_browser()

def test3_added_letters():
    minHash64 = LSH.MinHash(myGenome, 64, 8, 8)
    minHash64.buildRefTable()

    minHash128 = LSH.MinHash(myGenome, 128, 16, 16)
    minHash128.buildRefTable()

    test3_aux(minHash64, 64)
    test3_aux(minHash64, 128)
    test3_aux(minHash128, 64)
    test3_aux(minHash128, 128)

#def test4_removed_letters64():

test1()
test2_switched_letters()
test3_added_letters()
'''