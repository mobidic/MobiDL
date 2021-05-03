task gatkLeftAlignIndels {
	#global variables
	String SampleID
	String OutDirSampleID = ""
 	String OutDir
	String WorkflowType
	String GatkExe
 	File RefFasta
	File RefFai
	File RefDict
	#task specific variables
	File BamFile
	File GatkInterval
	String IntervalName = basename("${GatkInterval}", ".intervals")
	#runtime attributes
	Int Cpu
	Int Memory
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command {
		${GatkExe} LeftAlignIndels \
		-R ${RefFasta} \
		-I ${BamFile} \
		-O "${OutDir}${OutputDirSampleID}/${WorkflowType}/recal_bams/${SampleID}.${IntervalName}.dupmarked.recal.laligned.bam"
	}
	output {
		File lAlignedBam = "${OutDir}${OutputDirSampleID}/${WorkflowType}/recal_bams/${SampleID}.${IntervalName}.dupmarked.recal.laligned.bam"
		File lAlignedBamIndex = "${OutDir}${OutputDirSampleID}/${WorkflowType}/recal_bams/${SampleID}.${IntervalName}.dupmarked.recal.laligned.bai"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
