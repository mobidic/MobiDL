task bcftoolsNorm {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String BcfToolsExe
	#task specific variables
	File SortedVcf
	String VcSuffix
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${BcfToolsExe} norm -O v -m - \
		-o "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.vcf" \
		${SortedVcf}
	}
	output {
		File normVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.vcf"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
