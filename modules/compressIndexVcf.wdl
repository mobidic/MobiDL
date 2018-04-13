task compressIndexVcf {
	#global variables
	String SrunLow
	String SampleID	
	String OutDir
	String WorkflowType
	String BgZipExe
	String TabixExe
	#task specific variables
	File NormVcf
	command {
		${SrunLow} ${BgZipExe} -c \
		${NormVcf} \
		> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf.gz"
		${SrunLow} ${TabixExe} -fp vcf \
		"${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf.gz"

	}
	output {
		File bgZippedVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf.gz"
		File bgZippedVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf.gz.tbi"
	}
}