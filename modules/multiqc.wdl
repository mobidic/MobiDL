task multiqc {
	String SampleID
	String OutDir
	String WorkflowType
	String MultiqcExe
	File Vcf
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${MultiqcExe} -o "${OutDir}${SampleID}/${WorkflowType}/" -n "${SampleID}_multiqc" "${OutDir}${SampleID}/${WorkflowType}/" -f
	}
	output {
		File multiqcHtml = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}_multiqc.html"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
