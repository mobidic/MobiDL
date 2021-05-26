task computeCoverage {
	String SampleID
	String OutDirSampleID = ""
	String OutDir
	String WorkflowType
	String AwkExe
	String SortExe
	#task specific variables
	File BedCovFile
	#runtime attributes
	Int Cpu
	Int Memory
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		${SortExe} -k1,1 -k2,2n -k3,3n ${BedCovFile} \
		| ${AwkExe} 'BEGIN {OFS="\t"}{a=($3-$2+1);b=($7/a);print $1,$2,$3,$4,b,"+","+"}' \
		> "${OutDir}${OutputDirSampleID}/${WorkflowType}/coverage/${SampleID}_coverage.tsv"
	>>>
	output {
		File TsvCoverageFile = "${OutDir}${OutputDirSampleID}/${WorkflowType}/coverage/${SampleID}_coverage.tsv"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
