task gatkSplitIntervals {
	#https://software.broadinstitute.org/gatk/documentation/tooldocs/current/org_broadinstitute_hellbender_tools_walkers_SplitIntervals.php#--intervals
	##global variables
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
	Int ScatterCount
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} SplitIntervals \
		-R ${RefFasta} \
		-L ${GatkInterval} \
		--scatter-count ${ScatterCount} \
		--subdivision-mode ${SubdivisionMode} \
		-O "${OutDir}${SampleID}/${WorkflowType}/splitted_intervals/"
	}
	output {
		Array[File] splittedIntervals = glob("${OutDir}${SampleID}/${WorkflowType}/splitted_intervals/*-scattered.intervals")
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
