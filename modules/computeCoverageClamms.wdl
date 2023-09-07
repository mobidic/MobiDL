version 1.0

task computeCoverageClamms {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-04"
	}
	input {
		# global variables
		String SampleID
		String OutDir
		String OutDirSampleID = ""
		String WorkflowType
		String AwkExe
		String SortExe
		# task specific variables
		File BedCovFile
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		~{SortExe} -k1,1 -k2,2n -k3,3n ~{BedCovFile} \
		| awk '{ printf "%s\t%d\t%d\t%.6g\n", $1, $2, $3, $NF/($3-$2); }' \
		> "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/coverage/~{SampleID}_coverage.bed"
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File ClammsCoverageFile = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/coverage/~{SampleID}_coverage.bed"
	}
}
