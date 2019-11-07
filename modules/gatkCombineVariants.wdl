task gatkCombineVariants {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String JavaExe
	String Gatk3Jar
	#task specific variables
	Array[File] VcfFiles
	String VcfSuffix
	File RefFasta
	File RefFai
	File RefDict
	String GenotypeMergeOptions
	String FilteredRecordsMergeType
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${JavaExe} -jar ${Gatk3Jar} -T CombineVariants \
		-R ${RefFasta} \
		--variant ${sep=' --variant ' VcfFiles} \
		-genotypeMergeOptions ${GenotypeMergeOptions} \
		-filteredRecordsMergeType ${FilteredRecordsMergeType} \
		-nt "${Cpu}" \
		-o "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcfSuffix}.vcf"
	}
	output {
		File mergedVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcfSuffix}.vcf"
		File mergedVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcfSuffix}.vcf.idx"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}