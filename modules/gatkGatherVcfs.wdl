task gatkGatherVcfs {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String GatkExe
	#task specific variables
	Array[File] HcVcfs
	String VcSuffix
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} GatherVcfs \
		-I ${sep=' -I ' HcVcfs} \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.raw.vcf"
	}
	output {
		File gatheredHcVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.raw.vcf"
		File gatheredHcVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.raw.vcf.idx"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
