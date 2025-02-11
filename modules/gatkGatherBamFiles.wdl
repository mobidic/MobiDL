version 1.0

task gatkGatherBamFiles {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-01"
	}
	input {
		# global variables
		String SampleID
		String OutDirSampleID = ""
		String OutDir
		String WorkflowType
		String GatkExe
		Boolean Version = false
		# task specific variables
		Array[File] LAlignedBams
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		set -e  # To make task stop at 1st error
		~{GatkExe} GatherBamFiles \
		-I ~{sep=' -I ' LAlignedBams} \
		-O "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/~{SampleID}.gathered.bam"
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
		File gatheredBam = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/~{SampleID}.gathered.bam"
	}
}
