#!/usr/bin/env python3

import argparse as ap
import os
import time

start_time = time.time()

parser = ap.ArgumentParser("Implementing BED File Overlap")
parser.add_argument("-i1", required="True", type=str)
parser.add_argument("-i2", required="True", type=str)
parser.add_argument("-m", required="True", type=str)
parser.add_argument("-j", action="store_true")
parser.add_argument("-o", required="True", type=str)
args = parser.parse_args()

f1, f2, m, j, o = args.i1, args.i2, int(args.m), args.j, args.o

def extract(file):
	with open(file, 'r') as f:
		return [x.strip().split() for x in f.readlines()]

def elements(list):
	return list[0], int(list[1]), int(list[2])

def overlap_bed(file1, file2, output_file, x, m):
	set1, set2, output, l = extract(file1), extract(file2), open(output_file, "a+"), []
	for i in range(len(set1)):
		ele1, start1, stop1 = elements(set1[i])
		for j in range(len(set2)):
			ele2, start2, stop2 = elements(set2[j])
			if ele1 == ele2:				
				if ele1 not in l:
					l.append(ele1)
				if start1>=stop2:
					continue
				elif start1<stop2 and stop1>start2:
					
					if start1==stop1:
						overlap = 100
					else:
						overlap = int(((min(stop1, stop2) - max(start1, start2))/(stop1-start1))*100)

					if overlap>=m:
						if x:
							output.write('\t'.join(set1[i]) + '\t' + '\t'.join(set2[j]) + '\n')
						else:							
							output.write('\t'.join(set1[i])+'\n')
							break
				else:
					break
			else:
				if ele2 not in l:
					break


overlap_bed(f1, f2, o, j, m)
#os.system(f"wc -l {o} > nsensarma3_README")

print(f"{time.time() - start_time}")
