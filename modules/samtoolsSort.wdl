task samtoolsSort {
	#global variables
	String SampleID
	String OutDirSampleID = ""
 	String OutDir
	String WorkflowType
	String SamtoolsExe
	String BamFile
	#runtime attributes
	Int Cpu
	Int Memory
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command {
		${SamtoolsExe} sort -@ ${Cpu} -l 6 \
		-o "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.sorted.bam" \
		"${BamFile}"
		mv "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.sorted.bam" \
		"${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.bam"
	}
	output {
		File sortedBam = "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.bam"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
