task gatkLeftAlignIndels {
	#global variables
	String SrunLow
	String SampleID	
	String OutDir
	String WorkflowType
	String GatkExe	
	File RefFasta
	File RefFai
	File RefDict
	#task specific variables
	File BamFile
	File GatkInterval
	String intervalName = basename("${GatkInterval}", ".intervals")
	command {
			${SrunLow} ${GatkExe} LeftAlignIndels \
			-R ${RefFasta} \
			-I ${BamFile} \
			--OUTPUT "${OutDir}${SampleID}/${WorkflowType}/recal_bams/${SampleID}.${intervalName}.dupmarked.recal.laligned.bam"		
	}
	output {
		File lAlignedBam = "${OutDir}${SampleID}/${WorkflowType}/recal_bams/${SampleID}.${intervalName}.dupmarked.recal.laligned.bam"
		File lAlignedBamIndex = "${OutDir}${SampleID}/${WorkflowType}/recal_bams/${SampleID}.${intervalName}.dupmarked.recal.laligned.bai"
	}
}