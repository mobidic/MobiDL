version 1.0

task gatkGatherVcfs {
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
		Boolean Version = false
		String Encoding = "UTF-8"
		# task specific variables
		Array[File] HcVcfs
		String VcSuffix
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
		~{GatkExe} GatherVcfs \
		-I ~{sep=' -I ' HcVcfs} \
		-O "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.raw.vcf"
		if [ ~{Version} = true ];then
			# fill-in tools version file
					# fill-in tools version file
			echo "GATK Haplotype Caller: $(~{GatkExe} -version | grep 'GATK' | cut -f6 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File gatheredHcVcf = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.raw.vcf"
		File gatheredHcVcfIndex = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.raw.vcf.idx"
	}
}
