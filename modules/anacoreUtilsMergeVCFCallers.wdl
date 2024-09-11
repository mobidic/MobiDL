version 1.0

task anacoreUtilsMergeVCFCallers {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-05"
	}
	input {
		# env variables
		String CondaBin
		String AnacoreEnv
		# global variables
		String SampleID
		String OutDir
		String WorkflowType
		# task specific variables
		File MergeVCFMobiDL
		Array[File] Vcfs
		Array[String] Callers
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		source ~{CondaBin}activate ~{AnacoreEnv}
		# anacoreUtilsMergeVCFCallersMobiDL.py must be in PATH
		# and anacore-utils installed
		# https://github.com/bialimed/AnaCore-utils
		python ~{MergeVCFMobiDL} \
		-c ~{sep=' ' Callers} \
		-i ~{sep=' ' Vcfs} \
		-o "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.merged.vcf"
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File mergedVcf = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.merged.vcf"
	}
}
