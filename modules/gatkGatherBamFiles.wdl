task gatkGatherBamFiles {
	String SrunLow
	String SampleID
	String OutDir
	String WorkflowType
	String GatkExe
	Array[File] LAlignedBams
	command {
		${SrunLow} ${GatkExe} GatherBamFiles \
		-I ${sep=' -I ' LAlignedBams} \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.gathered.bam"
	}
	output {
		File gatheredBam = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.gathered.bam"
	}
}