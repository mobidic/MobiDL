task gatkGatherBQSRReports {
	String SrunLow
	String SampleID
	String OutDir
	String WorkflowType
	String GatkExe
	Array[File] RecalTables
	command {
		${SrunLow} ${GatkExe} GatherBQSRReports \
		-I ${sep=' -I ' RecalTables} \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.recal_table"
	}
	output {
		File gatheredRecalTable = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.recal_table"
	}
}