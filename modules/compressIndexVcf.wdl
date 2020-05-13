task compressIndexVcf {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String BgZipExe
	String TabixExe
	#task specific variables
	File VcfFile
	String VcSuffix
	String VcfExtension = "vcf"
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${BgZipExe} -c \
		${VcfFile} \
		> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.${VcfExtension}.gz"
		${TabixExe} -fp vcf \
		"${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.${VcfExtension}.gz"
	}
	output {
		File bgZippedVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.${VcfExtension}.gz"
		File bgZippedVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.${VcfExtension}.gz.tbi"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
