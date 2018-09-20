task sambambaIndex {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String SambambaExe
	#task specific variables
	File BamFile
	#String SuffixIndex
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${SambambaExe} index -t ${Cpu} \
		${BamFile} \
		"${OutDir}${SampleID}/${WorkflowType}/${SampleID}.bam.bai"
	}
	output {
		File bamIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.bam.bai"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
