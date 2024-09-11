version 1.0

task refCallFiltration {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-04"
	}
	input {
		# env variables
		String CondaBin
		String VcftoolsEnv
		# global variables
		String SampleID
		String OutDir
		String WorkflowType
		String VcftoolsExe
		Boolean Version = false
		# task specific variables
		String VcSuffix
		File VcfToRefCalled
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		source ~{CondaBin}activate ~{VcftoolsEnv}
		~{VcftoolsExe} --vcf ~{VcfToRefCalled} \
		--remove-filtered "RefCall" \
		--recode --out "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}"
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "VCFTools: $(~{VcftoolsExe} --version | cut -f2 -d ' ' | cut -f2 -d '(' | cut -f1 -d ')')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File noRefCalledVcf = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.recode.vcf"
	}
}
