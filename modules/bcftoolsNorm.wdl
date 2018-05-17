task bcftoolsNorm {
	#global variables
	String SrunLow
	String SampleID	
	String OutDir
	String WorkflowType
	String BcfToolsExe
	#task specific variables
	File SortedVcf
	command {
		${SrunLow} ${BcfToolsExe} norm -O v -m - \
		-o "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf" \
		${SortedVcf}
	}
	output {
		File normVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf"
	}
}
