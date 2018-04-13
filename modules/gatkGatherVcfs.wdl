task gatkGatherVcfs {
	#global variables
	String SrunLow
	String SampleID	
	String OutDir
	String WorkflowType
	String GatkExe
	#task specific variables
	Array[File] HcVcfs
	String VcfSuffix
	command {
		${SrunLow} ${GatkExe} GatherVcfs \
		-I ${sep=' -I ' HcVcfs} \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcfSuffix}.vcf"
	}
	output {
		File gatheredHcVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcfSuffix}.vcf"
		File gatheredHcVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcfSuffix}.vcf.idx"
	}
}