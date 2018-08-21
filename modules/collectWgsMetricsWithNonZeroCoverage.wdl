task collectWgsMetricsWithNonZeroCoverage {
	#https://software.broadinstitute.org/gatk/documentation/tooldocs/current/picard_analysis_CollectWgsMetricsWithNonZeroCoverage.php
	#TOOOOOOO LOOONNNGGG
	#global variables
	String SampleID
	String OutDir
	String WorkflowType
	String GatkExe
	File RefFasta
	#task specific variables
	File BamFile
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} CollectWgsMetricsWithNonZeroCoverage \
		-I ${BamFile} \
		-R ${RefFasta} \
		-O "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_wgs_metrics.txt" \
		--USE_FAST_ALGORITHM
	}
	output {
		File wgsMetricsTxt = "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_wgs_metrics.txt"
		File wgsMetricsPdf = "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_wgs_metrics.pdf"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
 }
}

 #--CHART "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_wgs_metrics.pdf" \
