task computeCoverage {
	String SrunLow
	String SampleID
	String OutDir
	String WorkflowType
	String AwkExe
	String SortExe
	#task specific variables
	File BedCovFile

	command <<<
		${SortExe} -k1,1 -k2,2n -k3,3n ${BedCovFile} \
		| ${AwkExe}  'BEGIN {OFS="\t"}{a=($3-$2+1);b=($7/a);print $1,$2,$3,$4,b,"+","+"}' \
		> "${OutDir}${SampleID}/${WorkflowType}/coverage/${SampleID}_coverage.tsv"
	>>>
	output {
		File TsvCoverageFile = "${OutDir}${SampleID}/${WorkflowType}/coverage/${SampleID}_coverage.tsv"
	}
}
