version 1.0

task mpa {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-07"
	}
	input {
		# env variables
		String CondaBin
		String MpaEnv
		# global variables
		File OutAnnotation
		String WorkflowType
		String SampleID
		String OutDir
		Boolean Version = "false"
		# task specific variables
		String MpaExe
		String Genome
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		source ~{CondaBin}activate ~{MpaEnv}
		"~{MpaExe}" \
		-i "~{OutAnnotation}" -l INFO \
		-o "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.~{Genome}_multianno_MPA.vcf"
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "MPA: v$(~{MpaExe} -v)" >>  "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt";
		fi
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File outMpa = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.~{Genome}_multianno_MPA.vcf"
	}
}
