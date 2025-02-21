version 1.0

task gatkGatherBQSRReports {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-01"
	}
	input {
		# global variables
		String SampleID
		String OutDir
		String OutDirSampleID = ""
		String WorkflowType
		String GatkExe
		Boolean Version = false
		# task specific variabless
		Array[File] RecalTables
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		set -e  # To make task stop at 1st error
		~{GatkExe} GatherBQSRReports \
		-I ~{sep=' -I ' RecalTables} \
		-O "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/~{SampleID}.recal_table"
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
		File gatheredRecalTable = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/~{SampleID}.recal_table"
	}
}
