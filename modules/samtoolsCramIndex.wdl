task samtoolsCramIndex {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String SamtoolsExe
	#task specific variables
	File CramFile
	#runtime attributes
	Int Cpu
	Int Memory
 	command {
		${SamtoolsExe} index \
		${CramFile} \
		"${OutDir}${SampleID}/${WorkflowType}/${SampleID}.cram.crai"
	}
	output {
		File cramIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.cram.crai"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
