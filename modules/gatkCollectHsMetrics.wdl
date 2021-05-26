task gatkCollectHsMetrics {
	#https://software.broadinstitute.org/gatk/documentation/tooldocs/current/picard_analysis_directed_CollectHsMetrics.php
	#global variables
	String SampleID
	String OutDir
	String OutDirSampleID = ""
	String WorkflowType
	String GatkExe
	File RefFasta
	File RefFai
	#task specific variables
 	File BamFile
	File BaitIntervals
	File TargetIntervals
	#runtime attributes
	Int Cpu
	Int Memory
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command {
		${GatkExe} CollectHsMetrics \
		-R ${RefFasta} \
		-I ${BamFile} \
		-O "${OutDir}${OutputDirSampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_hs_metrics.txt" \
		--BAIT_INTERVALS ${BaitIntervals} \
		--TARGET_INTERVALS ${TargetIntervals}
	}
	output {
		File hsMetricsTxt = "${OutDir}${OutputDirSampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_hs_metrics.txt"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
