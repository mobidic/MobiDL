task samtoolsSort {
	#global variables
	String SrunHigh
	Int Threads
	String SampleID	
	String OutDir
	String WorkflowType
	String SamtoolsExe
	String BamFile
	command {
		${SrunHigh} ${SamtoolsExe} sort -@ ${Threads} -l 6 \
		-o "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.bam" \
		"${BamFile}"
		mv "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.bam" \
		"${OutDir}${SampleID}/${WorkflowType}/${SampleID}.bam"
	}
	output {
		File sortedBam = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.bam"
	}
}