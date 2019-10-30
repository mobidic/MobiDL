task bedToGatkIntervalList {
	#https://gist.github.com/beboche/b70c57c7dfe58d4abaed367574bd4f01
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	#task specific variabless
	String AwkExe
	File IntervalBedFile
	Boolean DirsPrepared
	#runtime attributes
	Int Cpu
	Int Memory
	#Bed files are 0-based
	command <<<
		${AwkExe} 'BEGIN {OFS=""} {if ($1 !~ /track/) {if ($3 == $2) {print $1,":",$2+1,"-",$3+1}else{print $1,":",$2+1,"-",$3}}}' \
		${IntervalBedFile} \
		> "${OutDir}${SampleID}/${WorkflowType}/intervals/gatkIntervals.list"
	>>>
	output {
		File gatkIntervals = "${OutDir}${SampleID}/${WorkflowType}/intervals/gatkIntervals.list"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
