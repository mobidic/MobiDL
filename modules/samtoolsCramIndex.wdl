task samtoolsCramIndex {
	#global variables
	String SampleID
 	String OutDir
	String OutDirSampleID = ""
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
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
		"${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}${CramSuffix}.cram.crai"
	}
	output {
		File cramIndex = "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}${CramSuffix}.cram.crai"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
