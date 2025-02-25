version 1.0

task gatkCollectHsMetrics {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-04"
	}
	input {
		# https://software.broadinstitute.org/gatk/documentation/tooldocs/current/picard_analysis_directed_CollectHsMetrics.php
		# global variables
		String SampleID
		String OutDir
		String OutDirSampleID = ""
		String WorkflowType
		String GatkExe
		File RefFasta
		File RefFai
		Boolean Version = false
		# task specific variables
		File BamFile
		File BaitIntervals
		File TargetIntervals
		Int CoverageCap = 1000
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		set -e  # To make task stop at 1st error
		~{GatkExe} CollectHsMetrics \
		-R ~{RefFasta} \
		-I ~{BamFile} \
		-O "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}_hs_metrics.txt" \
		--BAIT_INTERVALS "~{BaitIntervals}" \
		--TARGET_INTERVALS "~{TargetIntervals}" \
		--COVERAGE_CAP "~{CoverageCap}"
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
		File hsMetricsTxt = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}_hs_metrics.txt"
	}
}
