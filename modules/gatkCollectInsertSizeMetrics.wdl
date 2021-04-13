task gatkCollectInsertSizeMetrics {
	#https://software.broadinstitute.org/gatk/documentation/tooldocs/current/picard_analysis_CollectMultipleMetrics.php
	#global variables
	String SampleID
	String OutDirSampleID = ""
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
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
		${GatkExe} CollectInsertSizeMetrics \
		-I ${BamFile} \
		-H "${OutDir}${OutputDirSampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_insertsize_metrics.pdf" \
		-O "${OutDir}${OutputDirSampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_insertsize_metrics.txt" \
		-M 0.5
	}
	output {
		File insertSizeMetricsTxt = "${OutDir}${OutputDirSampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_insertsize_metrics.txt"
		File insertSizeMetricsPdf = "${OutDir}${OutputDirSampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_insertsize_metrics.pdf"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
