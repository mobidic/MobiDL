task gatkCombienVariants {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String Gatk3Exe
	#task specific variables
	Array[File] VcfFiles
	File RefFasta
	File RefFai
	String GenotypeMergeOptions
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${Gatk3Exe} -T CombineVariants \
		-R RefFasta \
		-I ${sep=' --variant ' VcfFiles} \
		-genotypeMergeOptions GenotypeMergeOptions
		-o "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf"
	}
	output {
		File mergedVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf"
		File mergedVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf.idx"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}