task sambambaMarkDup {
	#global variables
	String SampleID
	String OutDirSampleID = ""
 	String OutDir
	String WorkflowType
	String SambambaExe
	#task specific variables
	File BamFile
	#runtime attributes
	Int Cpu
	Int Memory
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command {
		${SambambaExe} markdup -t ${Cpu} -l 1 \
		${BamFile} \
		"${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.dupmarked.bam"
		#mv ${BamFile} "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.dupmarked.bam"
		#samtools index "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.dupmarked.bam" "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.dupmarked.bam.bai"
	}
	output {
		File markedBam = "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.dupmarked.bam"
		File markedBamIndex = "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.dupmarked.bam.bai"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
