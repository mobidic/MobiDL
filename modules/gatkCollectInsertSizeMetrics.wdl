version 1.0

task gatkCollectInsertSizeMetrics {
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
		~{GatkExe} CollectInsertSizeMetrics \
		-I ~{BamFile} \
		-H "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}_insertsize_metrics.pdf" \
		-O "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}_insertsize_metrics.txt" \
		-M 0.5
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
		File insertSizeMetricsTxt = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}_insertsize_metrics.txt"
		File insertSizeMetricsPdf = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}_insertsize_metrics.pdf"
	}
}
