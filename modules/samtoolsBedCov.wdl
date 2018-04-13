task samtoolsBedCov {
	String SrunLow
	String SampleID
	String OutDir
	String WorkflowType
	String SamtoolsExe
	#task specific variables
	File IntervalBedFile
	File BamFile
	File BamIndex
	Int MinCovBamQual

	command {
		${SrunLow} ${SamtoolsExe} bedcov -Q ${MinCovBamQual} \
		${IntervalBedFile} \
		${BamFile} \
		> "${OutDir}/${SampleID}/${WorkflowType}/coverage/${SampleID}_bedcov.bed"
	}
	output {
		File BedCovFile = "${OutDir}/${SampleID}/${WorkflowType}/coverage/${SampleID}_bedcov.bed"
	}
}