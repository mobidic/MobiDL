task gatkCollectMultipleMetrics {
	#https://software.broadinstitute.org/gatk/documentation/tooldocs/current/picard_analysis_CollectMultipleMetrics.php
	#global variables
	String SrunLow
	String SampleID
	String OutDir
	String WorkflowType
	String GatkExe
	File RefFasta
	#task specific variables
	File BamFile
	command {
		${SrunLow} ${GatkExe} CollectMultipleMetrics \
		-I ${BamFile} \
		-R ${RefFasta} \
		-O "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics" \
		--PROGRAM CollectAlignmentSummaryMetrics \
		--PROGRAM CollectBaseDistributionByCycle \
		--PROGRAM CollectInsertSizeMetrics \
		--PROGRAM MeanQualityByCycle \
		--PROGRAM QualityScoreDistribution
	}
	output {
		File alignmentSummaryMetricsTxt = "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.alignment_summary_metrics"
		File baseDistributionByCycleMetricsTxt = "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.base_distribution_by_cycle_metrics"
		File baseDistributionByCycleMetricsPdf = "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.base_distribution_by_cycle.pdf"
		File insertSizeMetricsTxt = "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.insert_size_metrics"
		File insertSizeMetricsPdf = "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.insert_size_histogram.pdf"
		File qualityByCycleMetricsTxt = "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.quality_by_cycle_metrics"
		File qualityByCycleMetricsPdf = "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.quality_by_cycle.pdf"
		File qualityDistributionMetricsTxt = "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.quality_distribution_metrics"
		File qualityDistributionMetricsPdf = "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_multiple_metrics.quality_distribution.pdf"
	}
}