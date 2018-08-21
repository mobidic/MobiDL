task gatkVariantFiltrationSnp {
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
	File Vcf
	File VcfIndex
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} VariantFiltration \
		-R ${RefFasta} \
		-V ${Vcf} \
		--filter-expression "QD < 2.0" --filter-name "LowQualByDepth" \
		--filter-expression "FS > 60.0" --filter-name "FSStrandBias" \
		--filter-expression "MQ < 40.0" --filter-name "LowMappingQuality" \
		--filter-expression "MQRankSum < -3.0" --filter-name "LowMappingQualityRankSum" \
		--filter-expression "ReadPosRankSum < -4.0" --filter-name "LowreadPosRankSum" \
		--filter-expression "SOR > 3.0" --filter-name "SORStrandBias" \
		--filter-expression "POLYX > 7.0" --filter-name "HomopolymerRegion" \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.snp.filtered.vcf"
	}
	output {
		File filteredSnpVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.snp.filtered.vcf"
		File filteredSnpVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.snp.filtered.vcf.idx"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
