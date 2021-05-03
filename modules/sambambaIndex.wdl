task sambambaIndex {
	#global variables
	String SampleID
	String OutDirSampleID = ""
 	String OutDir
	String WorkflowType
	String SambambaExe
	#task specific variables
	File BamFile
	#String SuffixIndex
	#runtime attributes
	Int Cpu
	Int Memory
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command {
		${SambambaExe} index -t ${Cpu} \
		${BamFile} \
		"${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.bam.bai"
	}
	output {
		File bamIndex = "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.bam.bai"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
