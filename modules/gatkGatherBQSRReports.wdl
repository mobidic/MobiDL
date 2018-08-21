task gatkGatherBQSRReports {
	String SampleID
	String OutDir
	String WorkflowType
	String GatkExe
	Array[File] RecalTables
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} GatherBQSRReports \
		-I ${sep=' -I ' RecalTables} \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.recal_table"
	}
	output {
		File gatheredRecalTable = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.recal_table"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
