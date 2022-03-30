#!/bin/bash

v=0   #set a versbose flag=0 which will initialise our verbose mode when the -v option is invoked
realign=0    #declare a read alignment flag
index=0	#declare an indexing flag
gunzip=0	#declare a gunzip flag

while getopts ":a:b:r:o:ef:zvih" args; do
	case $args in
		a)reads1=$OPTARG;;
		b)reads2=$OPTARG;;
		r)ref=$OPTARG;;
		o)output=$OPTARG;;
		e)realign=1;;
		f)millsFile=$OPTARG;;
		z)gunzip=1;;
		v)v=1;;
		i)index=1;;
		h)printf "HELP SECTION!\n1. -a expects the first FQ Read file.\n2. -b expects the second FQ Read file.\n3. -r Expects the Reference Genome.\n4. -o expects the name of the output file.\n5. -e expects the Realign option to be activated.\n6. -f expects the Mills File.\n7. -z flag expects the Gunzip option to be activated.\n8. -v is the verbose mode.\n9. -i expects the Indexing option using Samtools to be activated!";;
	esac
done

#---------FILE CHECKING------------------------------------------

#input read FQ file check

if [ $v -eq 1 ]; then
	echo "Checking if the first FQ Read file exists or not"
fi

if test  -f "$reads1";then
	echo "The first FQ Read file exists! :)"
else
	echo "The first FQ Read file does not exist :("
	exit
fi

if [ $v -eq 1 ]; then
	echo "Checking if the second FQ Read file exists or not"
fi

if test -f "$reads2"; then
	echo "The second FQ Read file also exists! :)"
else
	echo "The second FQ Read File doesnt exist :("
	exit
fi

#Ref Genome file check

if [ $v -eq 1 ]; then
	echo "Checking if the Reference Genome exists or not"
fi

if test -f "$ref"; then
	echo "The Reference Genome provided exists!"
else
	echo "The Reference Genome Doesnt Exist :("
	exit
fi

#Check if Output VCF File already exists or not

if test -f "$output.vcf.gz"; then
	echo "The file already exists. Do you want to overwrite it? (0 or 1)"
	read num
else
	echo "The Output VCF File will be created!"
fi

#-----------------------------------------------------------------------------

#-----------------INDEXING WITH BWA-------------------------------------------

if [ $v -eq 1 ]; then
	echo "Indexing using the bwa index command"
fi

if [ $index -eq 1 ]; then
	bwa index $ref
fi

#-------------------------------------------------------------------------------

#-----------------MAPPING WITH BWA MEM------------------------------------------

if [ $v -eq 1 ]; then
	echo "Mapping with BWA MEM"
fi

bwa mem -R '@RG\tID:foo\tSM:bar\tLB:library1' $ref $reads1 $reads2 > lane.sam

#--------------------------------------------------------------------------------

#---------------CLEANING UP USING FIXMATE FOR READS INFORMATION AND FLAGS--------

if [ $v -eq 1 ]; then
	echo "Cleaning up of weird information and flags using samtools fixmate"
fi

samtools fixmate -O bam lane.sam lane_fixmate.sam

#--------------------------------------------------------------------------------

#-----------------SORTING--------------------------------------------------------

if [ $v -eq 1 ]; then
	echo "Sorting the fixed BAM file using Samtools"
fi

mkdir -p ~/temp/lane_temp

samtools sort -O bam -o lane_sorted.bam -T ~/temp/lane_temp lane_fixmate.sam

#--------------------------------------------------------------------------------

#----------------INDEXING THE SORTED BAM FILE USING SAMTOOLS INDEX---------------

if [ $v -eq 1 ]; then
	echo "Indexing the Sorted BAM using Samtools Index command"
fi

samtools index lane_sorted.bam

#--------------------------------------------------------------------------------

#----------------CREATE THE SEQUENCE DICTIONARY----------------------------------

if [ $v -eq 1 ]; then
	echo "Creating the sequence dictionary of Reference Genome"
fi

samtools dict $ref -o chr17.dict

#-------------------------------------------------------------------------------

#-----------------CREATE FAI FILE FOR THE REFERENCE GENOME----------------------

if [ $v -eq 1 ]; then
	echo "Creation of FAI FILE OF THE REFERENCE GENOME"
fi

samtools faidx $ref -o chr17.fa


#----------------RUN THE JAVA REALIGNER TARGET CREATOR OF GATK-------------------

if [ $v -eq 1 ]; then
	echo "Running the Java Realigner Target Creator of GATK"
fi

if [ $realign -eq 1 ]; then
	java -Xmx2g -jar GenomeAnalysisTK.jar -T RealignerTargetCreator -R $ref -I lane_sorted.bam -o lane.intervals --known $millsFile 2>> nsensarma3.log
fi

#--------------------------------------------------------------------------------

#---------------RUN THE JAVA INDELREALIGNER--------------------------------------

if [ $v -eq 1 ]; then
	echo"Running the Java IndelRealigner"
fi

java -Xmx4g -jar GenomeAnalysisTK.jar -T IndelRealigner -R $ref -I lane_sorted.bam -targetIntervals lane.intervals -o lane_realigned.bam 2>> nsensarma3.log

#-------------------------------------------------------------------------------

#--------------INDEXING REALIGNED FILE------------------------------------------

if [ $v -eq 1 ]; then
	echo "Indexing the Realigned File obtained after IndelRealigner"
fi

samtools index lane_realigned.bam

#--------------------------------------------------------------------------------

#--------------RUN SAMTOOLS BCFTOOLS---------------------------------------------

if [ $v -eq 1 ]; then
	echo "Running the bcftools to produce a VCF file that contains all the genomic regions"
fi

bcftools mpileup -Ou -f $ref lane_realigned.bam | bcftools call -vmO z -o $output.vcf.gz

#-------------------------------------------------------------------------------

#---------------GUNZIP THE OUTPUT VCF FILE OBTAINED-----------------------------

if [ $v -eq 1 ]; then
	echo "Gunzipping the Output VFC file"
fi

if [ $gunzip -eq 1 ]; then
	gzip -dk $output.vcf.gz
fi

#--------------------------------------------------------------------------------

if [ $v -eq 1 ]; then
	echo "VCF FILE SUCCESSFULLY CREATED"
fi
