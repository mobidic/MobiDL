task gatkSplitIntervals {
	#https://software.broadinstitute.org/gatk/documentation/tooldocs/current/org_broadinstitute_hellbender_tools_walkers_SplitIntervals.php#--intervals
	##global variables
	String SrunLow
	Int Threads
	String SampleID
	String OutDir
	String WorkflowType
	String GatkExe
	File RefFasta
	File RefFai
	File RefDict
	#task specific variables
	File GatkInterval
	String SubdivisionMode
	command {
		${SrunLow} ${GatkExe} SplitIntervals \
		-R ${RefFasta} \
		-L ${GatkInterval} \
		--scatter-count ${Threads} \
		--subdivision-mode ${SubdivisionMode} \
		-O "${OutDir}${SampleID}/${WorkflowType}/splitted_intervals/"
	}
	output {
		Array[File] splittedIntervals = glob("${OutDir}${SampleID}/${WorkflowType}/splitted_intervals/*-scattered.intervals")
	}
}