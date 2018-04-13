task gatkSplitVcfs {
	#global variables
	String SrunLow
	String SampleID	
	String OutDir
	String WorkflowType
	String GatkExe	
	#task specific variables
	File Vcf
	File VcfIndex
	command {
		${SrunLow} ${GatkExe} SplitVcfs \
		-I ${Vcf} \
		--SNP_OUTPUT "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.snp.vcf" \
		--INDEL_OUTPUT "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.indel.vcf" \
		--STRICT=false
	}
	output {
		File snpVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.snp.vcf"
		File snpVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.snp.vcf.idx"
		File indelVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.indel.vcf"
		File indelVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.indel.vcf.idx"
	}
}