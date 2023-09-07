version 1.0

task gatkSplitIntervals {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-01"
	}
	input {
		# https://software.broadinstitute.org/gatk/documentation/tooldocs/current/org_broadinstitute_hellbender_tools_walkers_SplitIntervals.php#--intervals
		# global variables
		String SampleID
		String OutDirSampleID = ""
		String OutDir
		String WorkflowType
		String GatkExe
		File RefFasta
		File RefFai
		File RefDict
		Boolean Version = false
		# task specific variables
		File GatkInterval
		String SubdivisionMode
		Int ScatterCount
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		~{GatkExe} SplitIntervals \
		-R ~{RefFasta} \
		-L ~{GatkInterval} \
		--scatter-count ~{ScatterCount} \
		--subdivision-mode ~{SubdivisionMode} \
		-O "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/splitted_intervals/"
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
		Array[File] splittedIntervals = glob("~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/splitted_intervals/*-scattered.interval*")
	}
}
