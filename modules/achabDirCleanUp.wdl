task achabDirCleanUp {
	String WorkflowType
	String SampleID
	String OutDir
	String PhenolyzerExe
	String? OutPhenolyzer
	File OutAchab
	File OutAchabNewHope
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		if [ -d "${OutDir}${SampleID}/${WorkflowType}/bcftools" ]; then \
			rm -rf "${OutDir}${SampleID}/${WorkflowType}/bcftools"; \
		fi   if [ -f "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.avinput" ]; then \
			rm "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.avinput"; \
		fi   if [ -f "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.hg19_multianno.txt" ]; then \
			rm "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.hg19_multianno.txt"; \
		fi   if [ -f "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.hg19_multianno.vcf" ]; then \
			rm "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.hg19_multianno.vcf"; \
		fi   if [ -f "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.vcf" ]; then \
			rm "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.vcf"; \
		fi
		if [ -f "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.vcf.idx" ]; then \
			rm "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.vcf.idx"; \
		fi
	}
	output {
		Boolean isRemoved = true
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
