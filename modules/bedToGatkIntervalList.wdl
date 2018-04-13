task bedToGatkIntervalList {
	#https://gist.github.com/beboche/b70c57c7dfe58d4abaed367574bd4f01
	#global variables
	String SrunLow
	String SampleID	
	String OutDir
	String WorkflowType
	#task specific variabless
	String AwkExe
	File IntervalBedFile
	Boolean DirsPrepared
	command <<<
		${SrunLow} ${AwkExe} 'BEGIN {OFS=""} {if ($1 !~ /track/) {print $1,":",$2+1,"-",$3}}' \
		${IntervalBedFile} \
		> "${OutDir}${SampleID}/${WorkflowType}/intervals/gatkIntervals.list"
	>>>
	output {
		File gatkIntervals = "${OutDir}${SampleID}/${WorkflowType}/intervals/gatkIntervals.list"
	}
}