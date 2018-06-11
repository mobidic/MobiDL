task samtoolsCramConvert {
	#global variables
	String SrunLow
	String SampleID	
	String OutDir
	String WorkflowType
	String SamtoolsExe
	#task specific variables  
	File BamFile
	File RefFastaGz
	File RefFaiGz
	File RefFaiGzi
	command {
		${SrunLow} ${SamtoolsExe} view \
		-T ${RefFastaGz} -C \
		-o "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.cram" \
		"${BamFile}"
	}
	output {
		File cram = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.cram"
	}
}
