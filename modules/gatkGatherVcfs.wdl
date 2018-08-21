task gatkGatherVcfs {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String GatkExe
	#task specific variables
	Array[File] HcVcfs
	String VcfSuffix
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} GatherVcfs \
		-I ${sep=' -I ' HcVcfs} \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcfSuffix}.vcf"
	}
	output {
		File gatheredHcVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcfSuffix}.vcf"
		File gatheredHcVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcfSuffix}.vcf.idx"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
