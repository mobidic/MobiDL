task gatkSplitVcfs {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String GatkExe
 	#task specific variables
	File Vcf
	File VcfIndex
	String VcSuffix
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} SplitVcfs \
		-I ${Vcf} \
		--SNP_OUTPUT "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.snp.vcf" \
		--INDEL_OUTPUT "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.indel.vcf" \
		--STRICT false
	}
	output {
		File snpVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.snp.vcf"
		File snpVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.snp.vcf.idx"
		File indelVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.indel.vcf"
		File indelVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.indel.vcf.idx"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
