task gatkGatherBamFiles {
	String SampleID
	String OutDir
	String WorkflowType
	String GatkExe
	Array[File] LAlignedBams
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} GatherBamFiles \
		-I ${sep=' -I ' LAlignedBams} \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.gathered.bam"
	}
	output {
		File gatheredBam = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.gathered.bam"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
