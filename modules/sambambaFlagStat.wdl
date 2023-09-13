version 1.0

task sambambaFlagStat {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-04"
	}
	input {
		# env variables	
		String CondaBin
		String SambambaEnv
		# global variables
		String SampleID
		String OutDirSampleID = ""		
		String OutDir
		String WorkflowType
		String SambambaExe
		Boolean Version = false
		# task specific variables
		File BamFile
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		source ~{CondaBin}activate ~{SambambaEnv}
		~{SambambaExe} flagstat -t ~{Cpu} \
		~{BamFile} > "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/coverage/~{SampleID}_bam_stats.txt"
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "Sambamba: v$(~{SambambaExe} --version 2>&1 | grep 'sambamba' | cut -f2 -d ' ' | uniq)" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File bamStats = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/coverage/~{SampleID}_bam_stats.txt"
	}
}
