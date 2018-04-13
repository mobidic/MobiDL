task sambambaMarkDup {
	#global variables
	String SrunHigh
	Int Threads
	String SampleID	
	String OutDir
	String WorkflowType
	String SambambaExe
	#task specific variables
	File BamFile
	command {
		${SrunHigh} ${SambambaExe} markdup -t ${Threads} -l 1 \
		${BamFile} \
		"${OutDir}${SampleID}/${WorkflowType}/${SampleID}.dupmarked.bam"
	}
	output {
		File markedBam = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.dupmarked.bam"
		File markedBamIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.dupmarked.bam.bai"
	}
}