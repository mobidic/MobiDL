version 1.0

task gatkBedToPicardIntervalList {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-04"
	}
	input {
		# https://software.broadinstitute.org/gatk/documentation/tooldocs/current/picard_util_BedToIntervalList.php
		# global variables
		String SampleID
		String OutDir
		String WorkflowType		
		String GatkExe
		File RefDict
		Boolean Version = false
		# task specific variables
		File IntervalBedFile
		Boolean Bait = false
		Boolean DirsPrepared
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String BedOut = if Bait then "~{OutDir}~{SampleID}/~{WorkflowType}/intervals/Intervals.Bait.bed" else "~{OutDir}~{SampleID}/~{WorkflowType}/intervals/Intervals.bed"
	String OutFile = if Bait then "~{OutDir}~{SampleID}/~{WorkflowType}/intervals/picard.Bait.interval_list" else "~{OutDir}~{SampleID}/~{WorkflowType}/intervals/picard.interval_list"
	command <<<
		cp ~{IntervalBedFile} ~{BedOut}
		~{GatkExe} BedToIntervalList \
		-I ~{IntervalBedFile} \
		-O ~{OutFile} \
		-SD ~{RefDict}
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
		File picardIntervals = "~{OutFile}"
		File bedIntervals = "~{BedOut}"
	}
}
