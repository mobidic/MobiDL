task fastp {
	#global variables
	String SampleID
	String OutDirSampleID = ""
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
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command {
		${FastpExe} -w ${Cpu} ${NoFiltering} \
		-i ${FastqR1} \
		-I ${FastqR2} \
		-o "${OutDir}${OutputDirSampleID}/${WorkflowType}/FastpDir/${SampleID}${Suffix1}.fastp.fq.gz" \
		-O "${OutDir}${OutputDirSampleID}/${WorkflowType}/FastpDir/${SampleID}${Suffix2}.fastp.fq.gz" \
		-R "${SampleID}" \
		-j "${OutDir}${OutputDirSampleID}/${WorkflowType}/FastpDir/${SampleID}_fastp.json" \
		-h "${OutDir}${OutputDirSampleID}/${WorkflowType}/FastpDir/${SampleID}_fastp.html"
	}
	output {
		File fastpR1 = "${OutDir}${OutputDirSampleID}/${WorkflowType}/FastpDir/${SampleID}${Suffix1}.fastp.fq.gz"
		File fastpR2 = "${OutDir}${OutputDirSampleID}/${WorkflowType}/FastpDir/${SampleID}${Suffix2}.fastp.fq.gz"
		File fastpJson = "${OutDir}${OutputDirSampleID}/${WorkflowType}/FastpDir/${SampleID}_fastp.json"
		File fastpHtml = "${OutDir}${OutputDirSampleID}/${WorkflowType}/FastpDir/${SampleID}_fastp.html"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
