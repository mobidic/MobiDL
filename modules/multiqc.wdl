task multiqc {
	String SrunLow
	String SampleID
	String OutDir
	String WorkflowType
	String MultiqcExe
	File Vcf
	command {
		${SrunLow} ${MultiqcExe} -o "${OutDir}${SampleID}/${WorkflowType}/" -n "${SampleID}_multiqc" "${OutDir}${SampleID}/${WorkflowType}/"
	}
	output {
		File multiqcHtml = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}_multiqc.html"
	}
}