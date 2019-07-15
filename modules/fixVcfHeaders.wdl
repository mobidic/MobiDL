task fixVcfHeaders {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	File VcfFile
	File VcfIndex
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		sed -e "s/##INFO=<ID=AC,Number=A,/##INFO=<ID=AC,Number=.,/" \
		-e "s/##INFO=<ID=AF,Number=A,/##INFO=<ID=AF,Number=.,/" \
		-e "s/##INFO=<ID=MLEAC,Number=A,/##INFO=<ID=MLEAC,Number=.,/" \ 
		-e "s/##INFO=<ID=MLEAF,Number=A,/##INFO=<ID=MLEAF,Number=.,/" \ 
		${VcfFile}" > "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf"
		mv "${VcfIndex}" "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf.idx"
	}
	output {
		File finalVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf" 
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
