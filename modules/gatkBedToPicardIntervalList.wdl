task gatkBedToPicardIntervalList {
	#https://software.broadinstitute.org/gatk/documentation/tooldocs/current/picard_util_BedToIntervalList.php
	#global variables
	String SampleID
	String OutDir
	String WorkflowType
	Boolean Bait = false
	String BedOut = if Bait then "${OutDir}${SampleID}/${WorkflowType}/intervals/Intervals.Bait.bed" else "${OutDir}${SampleID}/${WorkflowType}/intervals/Intervals.bed"
	String OutFile = if Bait then "${OutDir}${SampleID}/${WorkflowType}/intervals/picard.Bait.interval_list" else "${OutDir}${SampleID}/${WorkflowType}/intervals/picard.interval_list"
	File IntervalBedFile
	String GatkExe
	File RefDict
	#task specific variables
	Boolean DirsPrepared
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		cp ${IntervalBedFile} ${BedOut}
		${GatkExe} BedToIntervalList \
		-I ${IntervalBedFile} \
		-O ${OutFile} \
		-SD ${RefDict}
	}
	output {
		File picardIntervals = "${OutFile}"
		File bedIntervals = "${BedOut}"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
