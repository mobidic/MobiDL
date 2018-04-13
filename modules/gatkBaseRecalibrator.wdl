task gatkBaseRecalibrator {
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
	File KnownSites1
	File KnownSites1Index
	File KnownSites2
	File KnownSites2Index
	File KnownSites3
	File KnownSites3Index
	String intervalName = basename("${GatkInterval}", ".intervals")
	command {
		${SrunLow} ${GatkExe} BaseRecalibrator \
		-R ${RefFasta} \
		-I ${BamFile} \
		-L ${GatkInterval} \
		--known-sites ${KnownSites1} \
		--known-sites ${KnownSites2} \
		--known-sites ${KnownSites3} \
		-O "${OutDir}${SampleID}/${WorkflowType}/recal_tables/${SampleID}.recal_table.${intervalName}.txt"
	}
	output {
		File recalTable = "${OutDir}${SampleID}/${WorkflowType}/recal_tables/${SampleID}.recal_table.${intervalName}.txt"
	}
}