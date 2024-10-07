version 1.0

task computeCoverage {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-04"
	}
	input {
		# global variables
		String SampleID
		String OutDirSampleID = ""
		String OutDir
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
		| ~{AwkExe} 'BEGIN {OFS="\t"}{a=($3-$2+1);b=($NF/a);print $1,$2,$3,$4,b,"+","+"}' \
		> "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/coverage/~{SampleID}_coverage.tsv"
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File TsvCoverageFile = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/coverage/~{SampleID}_coverage.tsv"
	}
}
