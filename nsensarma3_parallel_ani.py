#!/usr/bin/env python3

import os
from multiprocessing import Pool
import argparse as ap

parser = ap.ArgumentParser("Implementing Parallel Ani")
parser.add_argument("-o", required="True", type=str)
parser.add_argument("-t", required="True", type=str)
parser.add_argument("vars", nargs="*")
args = parser.parse_args()

out, t_num, files = args.o, int(args.t), args.vars

#implement a function that returns the AvgIdentity after computing the dnadiff
def func(data):
	files, output = data[0], data[1]
	os.system(f"dnadiff -p {output} {files[0]} {files[1]}")
	#rename the output file to tup[0_1] in order to distinguish the files between the multiple threads
	with open(f"{output}.report", "r") as file:
		f = [x.strip().split() for x in file.readlines()]
	os.system(f"rm -r {output}*")
	return f[18][1] #return the AvgIdentity from the 19th line of the result file


l, scores, d, temp = [], [], {}, []
#implement a nested for loop that creates a list of tuples for every file
for i in range(len(files)):
	for j in range(i+1,len(files)):
		output = out+f"{str(i)}{str(j)}"
		l.extend([[(files[i], files[j]), output]])
		temp.extend([[(i,j)]])


pool = Pool(t_num)
scores = list(pool.map(func, l))

for i in range(len(temp)):
	d[temp[i][0]] = scores[i] #(1,2):score


#matrix creation
matrix = [[0 for i in range(len(files))] for m in range(len(files))]

for i in range(len(files)):
	for j in range(len(files)):
		if i == j:
			matrix[i][j] = 100
		elif i < j:
			matrix[i][j] = d[(i,j)]
		elif i > j:
			matrix[i][j] = d[(j,i)]

out_write = open(f"{out}.out", "a+")
#print the required matrix form
list_of_files = "\t".join(files)
out_write.write(f"\t{list_of_files}\n")

for i in range(len(files)):
	strtemp = f"{files[i]}"
	l = ["\t"+str(x) for x in matrix[i]]
	out_write.write(strtemp+"".join(l))
	out_write.write("\n")
	l.clear()


out_write.close()
pool.close()
pool.join()

