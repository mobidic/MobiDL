task LeftAlignAndTrimVariants {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String GatkExe
 	File RefFasta
	File RefFai
	File RefDict
	#task specific variables
	File SortedVcf
	String VcSuffix
	String VcfExtension = "vcf"
	Int Cpu
	Int Memory
	command {
		${GatkExe} LeftAlignAndTrimVariants \
		-R ${RefFasta} \
		-V ${SortedVcf} \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.${VcfExtension}" \
		--split-multi-allelics \
		--dont-trim-alleles \
		--keep-original-ac
	}
	output {
		File normVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.${VcfExtension}"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
