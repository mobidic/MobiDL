task gatkBedToPicardIntervalList {
	#https://software.broadinstitute.org/gatk/documentation/tooldocs/current/picard_util_BedToIntervalList.php
	#global variables
	String SrunLow
	String SampleID
	String OutDir
	String WorkflowType
	File IntervalBedFile
	String GatkExe
	File RefDict
	#task specific variables
	Boolean DirsPrepared
	command {
		cp ${IntervalBedFile} "${OutDir}${SampleID}/${WorkflowType}/intervals/Intervals.bed"
		${SrunLow} ${GatkExe} BedToIntervalList \
		-I ${IntervalBedFile} \
		-O "${OutDir}${SampleID}/${WorkflowType}/intervals/picard.interval_list" \
		-SD ${RefDict}
	}
	output {
		File picardIntervals = "${OutDir}${SampleID}/${WorkflowType}/intervals/picard.interval_list"
		File bedIntervals = "${OutDir}${SampleID}/${WorkflowType}/intervals/Intervals.bed"
	}
}