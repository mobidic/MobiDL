version 1.0

task gatkCollectMultipleMetrics {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-01"
	}
	input {
		# https://software.broadinstitute.org/gatk/documentation/tooldocs/current/picard_analysis_CollectMultipleMetrics.php
		# global variables
		String SampleID
		String OutDirSampleID = ""
		String OutDir
		String WorkflowType
		String GatkExe
		File RefFasta
		Boolean Version = false
		# task specific variables
		File BamFile
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		~{GatkExe} CollectMultipleMetrics \
		-I ~{BamFile} \
		-R ~{RefFasta} \
		-O "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}_multiple_metrics" \
		--PROGRAM CollectAlignmentSummaryMetrics \
		--PROGRAM CollectBaseDistributionByCycle \
		--PROGRAM CollectInsertSizeMetrics \
		--PROGRAM MeanQualityByCycle \
		--PROGRAM QualityScoreDistribution
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "GATK: $(~{GatkExe} -version | grep 'GATK' | cut -f6 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File alignmentSummaryMetricsTxt = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}_multiple_metrics.alignment_summary_metrics"
		File baseDistributionByCycleMetricsTxt = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}_multiple_metrics.base_distribution_by_cycle_metrics"
		File baseDistributionByCycleMetricsPdf = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}_multiple_metrics.base_distribution_by_cycle.pdf"
		File insertSizeMetricsTxt = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}_multiple_metrics.insert_size_metrics"
		File insertSizeMetricsPdf = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}_multiple_metrics.insert_size_histogram.pdf"
		File qualityByCycleMetricsTxt = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}_multiple_metrics.quality_by_cycle_metrics"
		File qualityByCycleMetricsPdf = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}_multiple_metrics.quality_by_cycle.pdf"
		File qualityDistributionMetricsTxt = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}_multiple_metrics.quality_distribution_metrics"
		File qualityDistributionMetricsPdf = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}_multiple_metrics.quality_distribution.pdf"
	}
}
