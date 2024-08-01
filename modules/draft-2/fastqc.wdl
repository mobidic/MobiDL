task fastqc {
	#global variables
	String SampleID
	String OutDir
	String WorkflowType
	String FastqcExe
	#task specific variables
	File FastqR1
	File FastqR2
	String Suffix1
	String Suffix2
	Boolean DirsPrepared
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${FastqcExe} --threads ${Cpu} \
		${FastqR1} \
		${FastqR2} \
		-o "${OutDir}${SampleID}/${WorkflowType}/FastqcDir"
	}
	output {
		File fastqcZipR1 = "${OutDir}${SampleID}/${WorkflowType}/FastqcDir/${SampleID}${Suffix1}_fastqc.zip"
		File fastqcHtmlR1 = "${OutDir}${SampleID}/${WorkflowType}/FastqcDir/${SampleID}${Suffix1}_fastqc.html"
		File fastqcZipR2 = "${OutDir}${SampleID}/${WorkflowType}/FastqcDir/${SampleID}${Suffix2}_fastqc.zip"
		File fastqcHtmlR2 = "${OutDir}${SampleID}/${WorkflowType}/FastqcDir/${SampleID}${Suffix2}_fastqc.html"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
