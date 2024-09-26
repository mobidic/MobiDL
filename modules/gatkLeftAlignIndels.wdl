version 1.0

task gatkLeftAlignIndels {
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
		File BamFile
		# File GatkInterval		
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	# String IntervalName = basename("~{GatkInterval}", ".intervals")
		# -O "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/recal_bams/~{SampleID}.~{IntervalName}.dupmarked.recal.laligned.bam"
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		~{GatkExe} LeftAlignIndels \
		-R ~{RefFasta} \
		-I ~{BamFile} \
		-O "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/~{SampleID}.dupmarked.recal.laligned.bam"
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
		File lAlignedBam = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/~{SampleID}.dupmarked.recal.laligned.bam"
		File lAlignedBamIndex = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/recal_bams/~{SampleID}.dupmarked.recal.laligned.bai"
		# File lAlignedBam = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/recal_bams/~{SampleID}.~{IntervalName}.dupmarked.recal.laligned.bam"
		# File lAlignedBamIndex = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/recal_bams/~{SampleID}.~{IntervalName}.dupmarked.recal.laligned.bai"
	}
}
