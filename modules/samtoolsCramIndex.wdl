task samtoolsCramIndex {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String SamtoolsExe
	#task specific variables
	File CramFile
	String CramSuffix
	#runtime attributes
	Int Cpu
	Int Memory
 	command {
		${SamtoolsExe} index \
		${CramFile} \
		"${OutDir}${SampleID}/${WorkflowType}/${SampleID}${CramSuffix}.cram.crai"
	}
	output {
		File cramIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${CramSuffix}.cram.crai"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
