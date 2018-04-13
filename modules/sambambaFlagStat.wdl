task sambambaFlagStat {
	#global variables
	String SrunHigh
	Int Threads
	String SampleID	
	String OutDir
	String WorkflowType
	String SambambaExe
	#task specific variables
	File BamFile
	command {
		${SrunHigh} ${SambambaExe} flagstat -t ${Threads} \
		${BamFile} > "${OutDir}${SampleID}/${WorkflowType}/coverage/${SampleID}_bam_stats.txt"
	}
	output {
		File bamStats = "${OutDir}${SampleID}/${WorkflowType}/coverage/${SampleID}_bam_stats.txt"
	}
}