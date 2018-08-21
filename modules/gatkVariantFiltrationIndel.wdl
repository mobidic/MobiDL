task gatkVariantFiltrationIndel {
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
		--filter-expression "FS > 200.0" --filter-name "FSStrandBias" \
		--filter-expression "ReadPosRankSum < -5.0" --filter-name "LowreadPosRankSum" \
		--filter-expression "SOR > 10.0" --filter-name "SORStrandBias" \
		--filter-expression "POLYX > 7.0" --filter-name "HomopolymerRegion" \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.indel.filtered.vcf"
	}
	output {
		File filteredIndelVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.indel.filtered.vcf"
		File filteredIndelVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.indel.filtered.vcf.idx"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
