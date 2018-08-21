task bcftoolsNorm {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String BcfToolsExe
	#task specific variables
	File SortedVcf
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${BcfToolsExe} norm -O v -m - \
		-o "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf" \
		${SortedVcf}
	}
	output {
		File normVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
