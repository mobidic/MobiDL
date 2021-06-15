task samtoolsBedCov {
	String SampleID
	String OutDirSampleID = ""
	String OutDir
	String WorkflowType
	String SamtoolsExe
	#task specific variables
	File IntervalBedFile
	File BamFile
	File BamIndex
	Int MinCovBamQual
	#runtime attributes
	Int Cpu
	Int Memory
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command {
		${SamtoolsExe} bedcov -Q ${MinCovBamQual} \
		${IntervalBedFile} \
		${BamFile} \
		> "${OutDir}/${OutputDirSampleID}/${WorkflowType}/coverage/${SampleID}_bedcov.bed"
	}
	output {
		File BedCovFile = "${OutDir}/${OutputDirSampleID}/${WorkflowType}/coverage/${SampleID}_bedcov.bed"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
