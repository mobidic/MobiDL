task gatkApplyBQSR {
	#global variables
	String SrunLow
	String SampleID	
	String OutDir
	String WorkflowType
	String GatkExe	
	File RefFasta
	File RefFai
	File RefDict
	##task specific variables
	File GatkInterval
	File BamFile
	File BamIndex
	String intervalName = basename("${GatkInterval}", ".intervals")
	File GatheredRecaltable
	command {
			${SrunLow} ${GatkExe} ApplyBQSR \
			-R ${RefFasta} \
			-I ${BamFile} \
			--bqsr-recal-file ${GatheredRecaltable} \
			-L ${GatkInterval} \
			-O "${OutDir}${SampleID}/${WorkflowType}/recal_bams/${SampleID}.${intervalName}.dupmarked.recal.bam"		
	}
	output {
		File recalBam = "${OutDir}${SampleID}/${WorkflowType}/recal_bams/${SampleID}.${intervalName}.dupmarked.recal.bam"
	}
}