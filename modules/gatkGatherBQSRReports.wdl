task gatkGatherBQSRReports {
	String SampleID
	String OutDir
	String OutDirSampleID = ""
	String WorkflowType
	String GatkExe
	Array[File] RecalTables
	#runtime attributes
	Int Cpu
	Int Memory
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command {
		${GatkExe} GatherBQSRReports \
		-I ${sep=' -I ' RecalTables} \
		-O "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.recal_table"
	}
	output {
		File gatheredRecalTable = "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.recal_table"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
