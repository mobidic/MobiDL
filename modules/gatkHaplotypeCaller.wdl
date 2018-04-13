task gatkHaplotypeCaller {
	#global variables
	String SrunLow
	String SampleID	
	String OutDir
	String WorkflowType
	String GatkExe	
	File RefFasta
	File RefFai
	File RefDict
	File DbSNP
	File DbSNPIndex
	##task specific variables
	File GatkInterval
	String intervalName = basename("${GatkInterval}", ".intervals")
	File BamFile
	File BamIndex
	String SwMode
	command {
		${SrunLow} ${GatkExe} HaplotypeCaller \
		-R ${RefFasta} \
		-I ${BamFile} \
		-L ${GatkInterval} \
		--dbsnp ${DbSNP} \
		--smith-waterman ${SwMode} \
		-O "${OutDir}${SampleID}/${WorkflowType}/vcfs/${SampleID}.${intervalName}.vcf"
	}
	output {
		File hcVcf = "${OutDir}${SampleID}/${WorkflowType}/vcfs/${SampleID}.${intervalName}.vcf"
	}
}