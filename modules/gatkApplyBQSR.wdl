version 1.0

task gatkApplyBQSR {
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
		File RefFasta
		File RefFai
		File RefDict
		Boolean Version = false
		# task specific variables
		File GatkInterval
		File BamFile
		File BamIndex
		File GatheredRecaltable
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String IntervalName = basename("~{GatkInterval}", ".intervals")
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		~{GatkExe} ApplyBQSR \
		-R ~{RefFasta} \
		-I ~{BamFile} \
		--bqsr-recal-file ~{GatheredRecaltable} \
		-L ~{GatkInterval} \
		-O "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/recal_bams/~{SampleID}.~{IntervalName}.dupmarked.recal.bam"
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
		File recalBam = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/recal_bams/~{SampleID}.~{IntervalName}.dupmarked.recal.bam"
	}
}
