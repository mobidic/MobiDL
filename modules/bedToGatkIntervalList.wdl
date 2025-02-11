version 1.0

task bedToGatkIntervalList {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-01"
	}
	input {
		# https://gist.github.com/beboche/b70c57c7dfe58d4abaed367574bd4f01
		# global variables
		String SampleID
		String OutDirSampleID = ""
		String OutDir
		String WorkflowType
		# task specific variabless
		String AwkExe
		File IntervalBedFile
		Boolean DirsPrepared
		 #runtime attributes
		String Queue
		Int Cpu
		Int Memory
		# Bed files are 0-based
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		set -e  # To make task stop at 1st error
		~{AwkExe} 'BEGIN {OFS=""} {if ($1 !~ /track/) {if ($3 == $2) {print $1,":",$2+1,"-",$3+1}else{print $1,":",$2+1,"-",$3}}}' \
		~{IntervalBedFile} \
		> "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/intervals/gatkIntervals.list"
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File gatkIntervals = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/intervals/gatkIntervals.list"
	}
}
