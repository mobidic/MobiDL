task samtoolsCramConvert {
	#global variables
	String SampleID
	String OutDirSampleID = ""
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
 	String OutDir
	String WorkflowType
	String SamtoolsExe
	#task specific variables
	File BamFile
	File RefFastaGz
	File RefFaiGz
	File RefFaiGzi
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${SamtoolsExe} view \
		-T ${RefFastaGz} -C \
		-o "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.cram" \
		"${BamFile}"
	}
	output {
		File cram = "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.cram"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
