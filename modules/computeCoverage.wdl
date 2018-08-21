task computeCoverage {
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
		| ${AwkExe} 'BEGIN {OFS="\t"}{a=($3-$2+1);b=($7/a);print $1,$2,$3,$4,b,"+","+"}' \
		> "${OutDir}${SampleID}/${WorkflowType}/coverage/${SampleID}_coverage.tsv"
	>>>
	output {
		File TsvCoverageFile = "${OutDir}${SampleID}/${WorkflowType}/coverage/${SampleID}_coverage.tsv"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
