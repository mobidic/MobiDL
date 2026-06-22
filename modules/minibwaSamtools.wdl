version 1.0

task bwaSamtools {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-01"
	}
	input {
		# env variables - BwaEnv includes samtools	
		String CondaBin	
		String minibwaEnv
		# global variables
		String SampleID
		String OutDirSampleID = ""
		String OutDir
		String WorkflowType
		File FastqR1
		File FastqR2
		String SamtoolsExe
		Boolean Version = false
		# task specific variables
		String minibwaExe
		String Platform
		File RefFasta		
		# index files for minibwa
		File Refl2b = RefFasta + "l2b"
		File Refmbw = RefFasta + "mbw"
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		set -e  # To make task stop at 1st error
		source ~{CondaBin}activate ~{minibwaEnv}
		~{minibwaExe} map -t~{Cpu} \
		-R "@RG\tID:~{SampleID}\tSM:~{SampleID}\tPL:~{Platform}" \
		~{RefFasta} \
		~{FastqR1} \
		~{FastqR2} \
		| ~{SamtoolsExe} sort -@ ~{Cpu} -l 1 \
		-o "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/~{SampleID}.bam"
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "----- Alignment -----" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
			echo "minibwa: v$(~{minibwaExe})" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
			echo "Samtools: v$(~{SamtoolsExe} --version | grep 'samtools' | cut -f2 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
		conda deactivate
	>>>
	output {
		File sortedBam = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/~{SampleID}.bam"
	}
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
}
