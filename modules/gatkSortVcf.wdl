task gatkSortVcf {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String GatkExe
	#task specific variables
	File UnsortedVcf
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} SortVcf \
		-I ${UnsortedVcf} \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.vcf"
	}
	output {
		File sortedVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.vcf"
		File sortedVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.vcf.idx"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
