task gatkHaplotypeCaller {
	#global variables
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
	String IntervalName = basename("${GatkInterval}", ".intervals")
	File BamFile
	File BamIndex
	#when callcaching on, seem to keep Bam and index in the same directory for HC execution
	#does not work in fine...
	#Pair[File, File] Bam = (BamFile, BamIndex)
	String SwMode
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} HaplotypeCaller \
		-R ${RefFasta} \
		-I ${BamFile} \
		-L ${GatkInterval} \
		--dbsnp ${DbSNP} \
		--smith-waterman ${SwMode} \
		-O "${OutDir}${SampleID}/${WorkflowType}/vcfs/${SampleID}.${IntervalName}.vcf"
	}
	output {
		File hcVcf = "${OutDir}${SampleID}/${WorkflowType}/vcfs/${SampleID}.${IntervalName}.vcf"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
