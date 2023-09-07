version 1.0

task gatkBaseRecalibrator {
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
		File RefFasta
		File RefFai
		File RefDict
		Boolean Version = false
		# task specific variables
		File GatkInterval
		File BamFile
		File BamIndex
		File KnownSites1
		File KnownSites1Index
		File KnownSites2
		File KnownSites2Index
		File KnownSites3
		File KnownSites3Index
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String IntervalName = basename("~{GatkInterval}", ".intervals")
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		~{GatkExe} BaseRecalibrator \
		-R ~{RefFasta} \
		-I ~{BamFile} \
		-L ~{GatkInterval} \
		--known-sites ~{KnownSites1} \
		--known-sites ~{KnownSites2} \
		--known-sites ~{KnownSites3} \
		-O "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/recal_tables/~{SampleID}.recal_table.~{IntervalName}.txt"
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
		File recalTable = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/recal_tables/~{SampleID}.recal_table.~{IntervalName}.txt"
	}
}
