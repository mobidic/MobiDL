task computeCoverageClamms {
	String SampleID
	String OutDir
	String WorkflowType
	String AwkExe
	String SortExe
	#task specific variables
	File BedCovFile
	#runtime attributes
	Int Cpu
	Int Memory

	command <<<
		${SortExe} -k1,1 -k2,2n -k3,3n ${BedCovFile} \
		| awk '{ printf "%s\t%d\t%d\t%.6g\n", $1, $2, $3, $NF/($3-$2); }' \
		> "${OutDir}${SampleID}/${WorkflowType}/coverage/${SampleID}_coverage.bed"
	>>>
	output {
		File ClammsCoverageFile = "${OutDir}${SampleID}/${WorkflowType}/coverage/${SampleID}_coverage.bed"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
