task fastqc {
	#global variables
	String SampleID
	String FatherSampleID
	String OutDir
	String WorkflowType
	String FastqcExe
	#task specific variables
	File FastqR1
	File FastqR2
	File FatherFastqR1
	File FatherFastqR2
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
		${FatherFastqR1} \
		${FatherFastqR2} \
		-o "${OutDir}${SampleID}/${WorkflowType}/FastqcDir"
	}
	output {
		File fastqcZipR1 = "${OutDir}${SampleID}/${WorkflowType}/FastqcDir/${SampleID}${Suffix1}_fastqc.zip"
		File fastqcHtmlR1 = "${OutDir}${SampleID}/${WorkflowType}/FastqcDir/${SampleID}${Suffix1}_fastqc.html"
		File fastqcZipR2 = "${OutDir}${SampleID}/${WorkflowType}/FastqcDir/${SampleID}${Suffix2}_fastqc.zip"
		File fastqcHtmlR2 = "${OutDir}${SampleID}/${WorkflowType}/FastqcDir/${SampleID}${Suffix2}_fastqc.html"
		File fastqcFatherZipR1 = "${OutDir}${SampleID}/${WorkflowType}/FastqcDir/${FatherSampleID}${Suffix1}_fastqc.zip"
		File fastqcFatherHtmlR1 = "${OutDir}${SampleID}/${WorkflowType}/FastqcDir/${FatherSampleID}${Suffix1}_fastqc.html"
		File fastqcFatherZipR2 = "${OutDir}${SampleID}/${WorkflowType}/FastqcDir/${FatherSampleID}${Suffix2}_fastqc.zip"
		File fastqcFatherHtmlR2 = "${OutDir}${SampleID}/${WorkflowType}/FastqcDir/${FatherSampleID}${Suffix2}_fastqc.html"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
