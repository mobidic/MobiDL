task samtoolsCramIndex {
	#global variables
	String SrunLow
	String SampleID	
	String OutDir
	String WorkflowType
	String SamtoolsExe
	#task specific variables
	File CramFile 
	command {
		${SrunLow} ${SamtoolsExe} index \
		${CramFile} \
		"${OutDir}${SampleID}/${WorkflowType}/${SampleID}.cram.crai"
	}
	output {
		File cramIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.cram.crai"
	}
}
