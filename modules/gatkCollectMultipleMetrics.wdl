task gatkCollectMultipleMetrics {
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
		${GatkExe} CollectMultipleMetrics \
		-I ${BamFile} \
		-R ${RefFasta} \
		-O "${OutDir}${OutputDirSampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics" \
		--PROGRAM CollectAlignmentSummaryMetrics \
		--PROGRAM CollectBaseDistributionByCycle \
		--PROGRAM CollectInsertSizeMetrics \
		--PROGRAM MeanQualityByCycle \
		--PROGRAM QualityScoreDistribution
	}
	output {
		File alignmentSummaryMetricsTxt = "${OutDir}${OutputDirSampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.alignment_summary_metrics"
		File baseDistributionByCycleMetricsTxt = "${OutDir}${OutputDirSampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.base_distribution_by_cycle_metrics"
		File baseDistributionByCycleMetricsPdf = "${OutDir}${OutputDirSampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.base_distribution_by_cycle.pdf"
		File insertSizeMetricsTxt = "${OutDir}${OutputDirSampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.insert_size_metrics"
		File insertSizeMetricsPdf = "${OutDir}${OutputDirSampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.insert_size_histogram.pdf"
		File qualityByCycleMetricsTxt = "${OutDir}${OutputDirSampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.quality_by_cycle_metrics"
		File qualityByCycleMetricsPdf = "${OutDir}${OutputDirSampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.quality_by_cycle.pdf"
		File qualityDistributionMetricsTxt = "${OutDir}${OutputDirSampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.quality_distribution_metrics"
		File qualityDistributionMetricsPdf = "${OutDir}${OutputDirSampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.quality_distribution.pdf"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
