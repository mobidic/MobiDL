version 1.0

task gatkUpdateVCFSequenceDictionary {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-05"
	}
	input {
		#global variables
		String SampleID
		String OutDir
		String WorkflowType
		String GatkExe
		Boolean Version = false
		#task specific variables
		File Vcf
		File RefFasta
		File RefFai
		File RefDict
		#runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		~{GatkExe} UpdateVCFSequenceDictionary \
		-R ~{RefFasta} \
		-V ~{Vcf} \
		-O "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.ref_updated.vcf"
		~{GatkExe} SortVcf \
		-I "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.ref_updated.vcf" \
		-O "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.vcf"
		rm "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.ref_updated.vcf" "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.ref_updated.vcf.idx"
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
		File refUpdatedVcf = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.vcf"
		File refUpdatedVcfIndex = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.vcf.idx"
	}
}
