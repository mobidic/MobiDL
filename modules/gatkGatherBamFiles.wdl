task gatkGatherBamFiles {
	String SampleID
	String OutDirSampleID = ""
	String OutDir
	String WorkflowType
	String GatkExe
	Array[File] LAlignedBams
	#runtime attributes
	Int Cpu
	Int Memory
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command {
		${GatkExe} GatherBamFiles \
		-I ${sep=' -I ' LAlignedBams} \
		-O "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.gathered.bam"
	}
	output {
		File gatheredBam = "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.gathered.bam"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
