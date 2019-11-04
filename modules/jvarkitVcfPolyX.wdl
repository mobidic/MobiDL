task jvarkitVcfPolyX {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String JavaExe
	String VcfPolyXJar
	File RefFasta
	File RefFai
	File RefDict
	#task specific variables
	File Vcf
	File VcfIndex
	String VcSuffix
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${JavaExe} -jar ${VcfPolyXJar} \
		-R ${RefFasta} \
		-o "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.polyx.vcf" \
		"${Vcf}"
		#just cp index file suppose no changes
		cp ${VcfIndex} "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.polyx.vcf.idx"
	}
	output {
		File polyxedVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.polyx.vcf"
		File polyxedVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.polyx.vcf.idx"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
