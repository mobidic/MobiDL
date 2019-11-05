task gatkCombineVariants {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String JavaExe
	String Gatk3Jar
	#task specific variables
	Array[File] VcfFiles
	File RefFasta
	File RefFai
	String GenotypeMergeOptions
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${JavaExe} -jar ${Gatk3Jar} -T CombineVariants \
		-R RefFasta \
		--variant ${sep=' --variant ' VcfFiles} \
		-genotypeMergeOptions ${GenotypeMergeOptions}
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