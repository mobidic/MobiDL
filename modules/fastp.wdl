task fastp {
	#global variables
	String SampleID
	String OutDir
	String WorkflowType
	String FastpExe
	#task specific variables
	File FastqR1
	File FastqR2
	String Suffix1
	String Suffix2
	Boolean DirsPrepared
	String NoFiltering
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${FastpExe} -w ${Cpu} ${NoFiltering} \
		-i ${FastqR1} \
		-I ${FastqR2} \
		-o "${OutDir}${SampleID}/${WorkflowType}/FastpDir/${SampleID}${Suffix1}.fastp.fq.gz" \
		-O "${OutDir}${SampleID}/${WorkflowType}/FastpDir/${SampleID}${Suffix2}.fastp.fq.gz" \
		-R "${SampleID}" \
		-j "${OutDir}${SampleID}/${WorkflowType}/FastpDir/${SampleID}_fastp.json" \
		-h "${OutDir}${SampleID}/${WorkflowType}/FastpDir/${SampleID}_fastp.html"
	}
	output {
		File fastpR1 = "${OutDir}${SampleID}/${WorkflowType}/FastpDir/${SampleID}${Suffix1}.fastp.fq.gz"
		File fastpR2 = "${OutDir}${SampleID}/${WorkflowType}/FastpDir/${SampleID}${Suffix2}.fastp.fq.gz"
		File fastpJson = "${OutDir}${SampleID}/${WorkflowType}/FastpDir/${SampleID}_fastp.json"
		File fastpHtml = "${OutDir}${SampleID}/${WorkflowType}/FastpDir/${SampleID}_fastp.html"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
