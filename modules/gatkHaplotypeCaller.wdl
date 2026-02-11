version 1.0

task gatkHaplotypeCaller {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-05"
	}
	input {
		# global variables
		String SampleID
		String OutDir
		String WorkflowType
		String GatkExe
		File RefFasta
		File RefFai
		File RefDict
		File DbSNP
		File DbSNPIndex
		Boolean Version = false
		# task specific variables
		File GatkInterval
		String IntervalName = basename("~{GatkInterval}", ".intervals")
		File BamFile
		File BamIndex
		Int MaxMNPDist = 0
		Int MaxReadPerAlignmentStart = 50
		String SwMode
		String EmitRefConfidence
		String DisableSpanningEventGenotyping = "--disable-spanning-event-genotyping"
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		set -e  # To make task stop at 1st error
		export LANG=en_US.UTF-8
		export LC_ALL=en_US.UTF-8
		export LC_TIME=en_US.UTF-8     # ensure english date format
		~{GatkExe} HaplotypeCaller \
		-R ~{RefFasta} \
		-I ~{BamFile} \
		-L ~{GatkInterval} \
		--dbsnp ~{DbSNP} \
		--smith-waterman ~{SwMode} \
		--emit-ref-confidence ~{EmitRefConfidence} \
		--max-mnp-distance ~{MaxMNPDist} \
		--max-reads-per-alignment-start ~{MaxReadPerAlignmentStart} \
		~{DisableSpanningEventGenotyping} \
		-O "~{OutDir}~{SampleID}/~{WorkflowType}/vcfs/~{SampleID}.~{IntervalName}.hc.vcf"
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
		File hcVcf = "~{OutDir}~{SampleID}/~{WorkflowType}/vcfs/~{SampleID}.~{IntervalName}.hc.vcf"
	}
}
