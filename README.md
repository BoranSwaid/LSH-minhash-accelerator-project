# LSH Minhash hardware accelerator for DNA classification project by: Boran Swaid & Dima Ali-Saleh.

We propose a novel LSH-Minhash accelerator a novel hardware for read classification using the big data technique minhashing.
Our approach performs context-aware classification of reads by computing representative subsamples of k-mers within both, 
probed reads and their reversed reads and locally constrained regions of the reference genomes.

# Folder description:

* software directory:
  - LSH.py: The project algorithm implementation with explicit implemntaion of murmur hash function.
  - LSH2.py:  The project algorithm implementation with using murmur 3 hash function by importing mmh3 library.
  - test_bench.py: includes the tests that research the algorithm parameters.
* SystemVerilog_files: contains the hardware implementation.
* Documentation:
  - The project book: [LSH_book.pdf](Documentation/LSH_book.pdf)
  - The project presentation: [presentation.pptx](Documentation/presentation.pptx)
  
# Details about the project:

In our project, we have developed a classification scheme that is finely tuned to classify reads considering the reverse read
based on the number of matching k-mers they have with a reference genome window of a similar size to the read.
This approach has proven effective and has allowed us to optimize various parameters to create a hardware accelerator for LSH-MinHash.


**Project definition and its goals:**

DNA pre-alignment is a process used in DNA genome analysis pipeline to filter our reads which do not belong to a DNA reference.
In this project we will design a hardware accelerator for DNA pre-alignment used to detect and classify DNA reads.
The main goals of this project are:

  1. Design a novel accelerator for genomic applications.
  2. Gain speedup over commercial software-based tools.
  3. To learn digital VLSI design tools and flow such as Innovus and Synopsys using Systemverilog language.

**Algorithm:**

The algorithm can be divided into two sections: offline that contains the database construction process and online 
that contains the classification process.
* Offline:
  1. Pick 3 reference genomes (the code can be updated for more).
  2. For each reference genome, place it in memory as follows:
     1) Divide ref genome into windows of length 128 byte.
     2) Divide every window into k-mers of length 16 byte with overlap of 8 byte.
     3) For every window, find its signature using murmur function.
     4) Hash the smallest 4 signature values using murmur function into the table that represents the memory.

  ![image](https://github.com/BoranSwaid/LSH-minhash-accelerator-project/assets/75131035/ce3154e0-2f36-4105-8f1b-f80e6e635438)

* Online:
  1. Input: read of length 128 byte.
  2. Create an empty list called hash2_values.
  3. Hash the read into memory as described before in the offline section and save its hash values in hash2_values list.
  4. Find candidate pairs by going on the hash2_values list and for each value go over the list of windows that matches
     this value and increment the counter of this window and this genome id.
  5. Do the same steps as before but for the reversed read.
  6. Return the window index and genome id which has the highest count of hits from both the read and the reversed read,
     if there isn’t, return (-1, -1).
     
  ![image](https://github.com/BoranSwaid/LSH-minhash-accelerator-project/assets/75131035/e4001db1-7bf9-4111-b8fd-055cedf9d5d1)

  **Architecture:**
  
  ![image](https://github.com/BoranSwaid/LSH-minhash-accelerator-project/assets/75131035/280604e6-893a-40b2-8dda-2a1251dabed7)

  **Chip Layout:**
  
  ![image](https://github.com/BoranSwaid/LSH-minhash-accelerator-project/assets/75131035/84313122-1403-4d80-8c98-eed962c48078)

  **Results:**
  
  We gained 78x speedup over our software tool, 8x over Kraken, 9x over MetaCache and 11x over CLARK.
  This indicates the efficiency and effectiveness of our hardware accelerator in speeding up the process of read classification.

  ![image](https://github.com/BoranSwaid/LSH-minhash-accelerator-project/assets/75131035/49ef9cf2-33e1-49eb-b5cf-83f38701ce64)


  









