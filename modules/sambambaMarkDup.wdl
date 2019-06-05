task sambambaMarkDup {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String SambambaExe
	#task specific variables
	File BamFile
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${SambambaExe} markdup -t ${Cpu} -l 1 \
		${BamFile} \
		"${OutDir}${SampleID}/${WorkflowType}/${SampleID}.dupmarked.bam"
		#mv ${BamFile} "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.dupmarked.bam"
		#samtools index "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.dupmarked.bam" "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.dupmarked.bam.bai"
	}
	output {
		File markedBam = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.dupmarked.bam"
		File markedBamIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.dupmarked.bam.bai"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
