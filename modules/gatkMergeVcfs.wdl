task gatkMergeVcfs {
	#global variables
	String SrunLow
	String SampleID	
	String OutDir
	String WorkflowType
	String GatkExe
	#task specific variables
	Array[File] Vcfs
	String VcfSuffix
	command {
		${SrunLow} ${GatkExe} MergeVcfs \
		-I ${sep=' -I ' Vcfs} \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcfSuffix}.vcf"
	}
	output {
		File mergedVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcfSuffix}.vcf"
		File mergedVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcfSuffix}.vcf.idx"
	}
}