task gatkUpdateVCFSequenceDictionary {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String GatkExe
  #task specific variables
	File Vcf
  File RefFasta
	File RefFai
	File RefDict
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} UpdateVCFSequenceDictionary \
    -R ${RefFasta} \
		-V ${Vcf} \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.ref_updated.vcf"
    ${GatkExe} SortVcf \
    -I "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.ref_updated.vcf" \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf"
    rm "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf.idx"
	}
	output {
		File refUpdatedVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf"
		File refUpdatedVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf.idx"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
