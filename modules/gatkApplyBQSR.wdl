task gatkApplyBQSR {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String GatkExe
 	File RefFasta
	File RefFai
	File RefDict
	#task specific variables
	File GatkInterval
	File BamFile
	File BamIndex
	String IntervalName = basename("${GatkInterval}", ".intervals")
	File GatheredRecaltable
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} ApplyBQSR \
		-R ${RefFasta} \
		-I ${BamFile} \
		--bqsr-recal-file ${GatheredRecaltable} \
		-L ${GatkInterval} \
		-O "${OutDir}${SampleID}/${WorkflowType}/recal_bams/${SampleID}.${IntervalName}.dupmarked.recal.bam" 
	}
	output {
		File recalBam = "${OutDir}${SampleID}/${WorkflowType}/recal_bams/${SampleID}.${IntervalName}.dupmarked.recal.bam"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
