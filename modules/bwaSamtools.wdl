task bwaSamtools {
	#global variables
	String SrunHigh
	Int Threads
	String SampleID	
	String OutDir
	String WorkflowType
	File FastqR1
	File FastqR2
	String SamtoolsExe
	#task specific variables
	String BwaExe
	String Platform
	File RefFasta
	File RefFai
	#index files for bwa
	File RefAmb
	File RefAnn
	File RefBwt
	File RefPac
	File RefSa
	command {
		${SrunHigh} ${BwaExe} mem -M -t ${Threads} \
		-R "@RG\tID:${SampleID}\tSM:${SampleID}\tPL:${Platform}" \
		${RefFasta} \
		${FastqR1} \
		${FastqR2} \
		| ${SamtoolsExe} sort -@ ${Threads} -l 1 \
		-o "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.bam"
	}
	output {
		File sortedBam = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.bam"
		#File sortedBamIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.bam.bai"
	}
}