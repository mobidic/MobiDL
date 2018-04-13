task jvarkitVcfPolyX {
	#global variables
	String SrunLow
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
	command {
		${SrunLow} ${JavaExe} -jar ${VcfPolyXJar} \
		-R ${RefFasta} \
		-o "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.polyx.vcf" \
		"${Vcf}"
		#just mv index file suppose no changes
		cp ${VcfIndex} "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.polyx.vcf.idx"
	}
	output {
		File polyxedVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.polyx.vcf"
		File polyxedVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.polyx.vcf.idx"
	}
}