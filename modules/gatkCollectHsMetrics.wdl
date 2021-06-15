task gatkCollectHsMetrics {
	#https://software.broadinstitute.org/gatk/documentation/tooldocs/current/picard_analysis_directed_CollectHsMetrics.php
	#global variables
	String SampleID
	String OutDir
	String WorkflowType
	String GatkExe
	File RefFasta
	File RefFai
	#task specific variables
 	File BamFile
	File BaitIntervals
	File TargetIntervals
	Int CoverageCap = 1000
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} CollectHsMetrics \
		-R ${RefFasta} \
		-I ${BamFile} \
		-O "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_hs_metrics.txt" \
		--BAIT_INTERVALS "${BaitIntervals}" \
		--TARGET_INTERVALS "${TargetIntervals}" \
		--COVERAGE_CAP "${CoverageCap}"
	}
	output {
		File hsMetricsTxt = "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_hs_metrics.txt"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
