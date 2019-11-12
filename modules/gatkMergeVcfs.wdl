task gatkMergeVcfs {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String GatkExe
	#task specific variables
	Array[File] Vcfs
	String VcSuffix
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} MergeVcfs \
		-I ${sep=' -I ' Vcfs} \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.merged.vcf"
	}
	output {
		File mergedVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.merged.vcf"
		File mergedVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.merged.vcf.idx"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
