task compressIndexVcf {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String BgZipExe
	String TabixExe
	#task specific variables
	File NormVcf
	String VcSuffix
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${BgZipExe} -c \
		${NormVcf} \
		> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.${VcSuffix}.vcf.gz"
		${TabixExe} -fp vcf \
		"${OutDir}${SampleID}/${WorkflowType}/${SampleID}.${VcSuffix}.vcf.gz"
	}
	output {
		File bgZippedVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.${VcSuffix}.vcf.gz"
		File bgZippedVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.${VcSuffix}.vcf.gz.tbi"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
