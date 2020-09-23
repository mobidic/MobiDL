task gatkHardFiltering {
	#https://gatkforums.broadinstitute.org/gatk/discussion/2806/howto-apply-hard-filters-to-a-call-set
	#https://software.broadinstitute.org/gatk/documentation/article?id=11069
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String GatkExe
	File RefFasta
	File RefFai
	File RefDict

	#task specific variables
	File Vcf  #takes as input the compressed and indexed file because Wdl need index
	File VcfIndex
	String VcSuffix
	Int LowCoverage
	#runtime attributes
	Int Cpu
	Int Memory
	#	--filter-expression "POLYX > 7.0" --filter-name "HomopolymerRegion" \
	command {
		${GatkExe} VariantFiltration \
		-R ${RefFasta} \
		-V ${Vcf} \
		--filter-expression "DP < ${LowCoverage}" --filter-name "LowCoverage" \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.filtered.vcf"
	}
	output {
		File HardFilteredVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.filtered.vcf"
		File HardFilteredVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.filtered.vcf.idx"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
