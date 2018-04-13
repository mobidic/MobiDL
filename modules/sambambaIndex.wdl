task sambambaIndex {
	#global variables
	String SrunHigh
	Int Threads
	String SampleID	
	String OutDir
	String WorkflowType
	String SambambaExe
	#task specific variables
	File BamFile
	String SuffixIndex
	command {
		${SrunHigh} ${SambambaExe} index -t ${Threads} \
		${BamFile} \
		"${OutDir}${SampleID}/${WorkflowType}/${SampleID}${SuffixIndex}.bam.bai"
	}
	output {
		File bamIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${SuffixIndex}.bam.bai"
	}
}