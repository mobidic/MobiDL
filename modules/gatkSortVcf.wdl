task gatkSortVcf {
	#global variables
	String SrunLow
	String SampleID	
	String OutDir
	String WorkflowType
	String GatkExe
	#task specific variables
	File UnsortedVcf
	command {
		${SrunLow} ${GatkExe} SortVcf \
		-I ${UnsortedVcf} \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.vcf"
	}
	output {
		File sortedVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.vcf"
		File sortedVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.vcf.idx"
	}
}