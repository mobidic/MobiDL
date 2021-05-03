task gatkBaseRecalibrator {
	#global variables
	String SampleID
	String OutDir
	String OutDirSampleID = ""
	String WorkflowType
	String GatkExe
	File RefFasta
	File RefFai
	File RefDict
	#task specific variables
	File GatkInterval
	File BamFile
	File BamIndex
	File KnownSites1
	File KnownSites1Index
	File KnownSites2
	File KnownSites2Index
	File KnownSites3
	File KnownSites3Index
	String IntervalName = basename("${GatkInterval}", ".intervals")
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} BaseRecalibrator \
		-R ${RefFasta} \
		-I ${BamFile} \
		-L ${GatkInterval} \
		--known-sites ${KnownSites1} \
		--known-sites ${KnownSites2} \
		--known-sites ${KnownSites3} \
		-O "${OutDir}${OutputDirSampleID}/${WorkflowType}/recal_tables/${SampleID}.recal_table.${IntervalName}.txt"
	}
	output {
		File recalTable = "${OutDir}${OutputDirSampleID}/${WorkflowType}/recal_tables/${SampleID}.recal_table.${IntervalName}.txt"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
