version 1.0

task crumble {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-04"
	}
	input {
		# env variables	
		String CondaBin
		String CrumbleEnv
		# global variables
		String SampleID
		String OutDir
		String OutDirSampleID = ""		
		String WorkflowType
		String CrumbleExe
		Boolean Version = false
		# task specific variables
		File InputFile
		File InputFileIndex
		String LdLibraryPath
		String FileType		
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		source ~{CondaBin}activate ~{CrumbleEnv}
		export LD_LIBRARY_PATH="~{LdLibraryPath}"
		~{CrumbleExe} \
		-O ~{FileType},nthreads=~{Cpu} ~{InputFile} "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/~{SampleID}.crumble.~{FileType}"
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "----- Compression -----" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
			echo "Crumble: v$(~{CrumbleExe} -h 2>&1 | grep 'Crumble' | cut -f3 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
		source ~{CondaBin}deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File crumbled = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/~{SampleID}.crumble.~{FileType}"
	}
}
