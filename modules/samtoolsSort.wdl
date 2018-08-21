task samtoolsSort {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String SamtoolsExe
	String BamFile
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${SamtoolsExe} sort -@ ${Cpu} -l 6 \
		-o "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.bam" \
		"${BamFile}"
		mv "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.bam" \
		"${OutDir}${SampleID}/${WorkflowType}/${SampleID}.bam"
	}
	output {
		File sortedBam = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.bam"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
