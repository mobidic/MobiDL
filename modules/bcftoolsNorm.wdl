task bcftoolsNorm {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String BcfToolsExe
	#task specific variables
	File SortedVcf
	String VcSuffix
	String VcfExtension = "vcf"
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${BcfToolsExe} norm -O v -m -both \
		-o "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.${VcfExtension}" \
		${SortedVcf}
	}
	output {
		File normVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.${VcfExtension}"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
