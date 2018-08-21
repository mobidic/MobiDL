task sambambaFlagStat {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String SambambaExe
	#task specific variables
	File BamFile
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${SambambaExe} flagstat -t ${Cpu} \
		${BamFile} > "${OutDir}${SampleID}/${WorkflowType}/coverage/${SampleID}_bam_stats.txt"
	}
	output {
		File bamStats = "${OutDir}${SampleID}/${WorkflowType}/coverage/${SampleID}_bam_stats.txt"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
