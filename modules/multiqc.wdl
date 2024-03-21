task multiqc {
	String SampleID
	String OutDir
	String WorkflowType
	String MultiqcExe
	String perlExe = "/usr/bin/perl"
	File Vcf
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${MultiqcExe} -o "${OutDir}${SampleID}/${WorkflowType}/" -n "${SampleID}_multiqc" "${OutDir}${SampleID}/${WorkflowType}/" -f
		${perlExe} -pi.bak -e 's/NaN/null/g' "${OutDir}${SampleID}/${WorkflowType}/${SampleID}_multiqc_data/multiqc_data.json"
	}
	output {
		File multiqcHtml = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}_multiqc.html"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
