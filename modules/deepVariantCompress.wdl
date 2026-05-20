version 1.0

task deepVariant {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-04"
	}
	input {
		# env variables	
		String CondaBin
		String SingularityEnv
		# global variables
		String SampleID
		String OutDir
		String WorkflowType
		String RefFastaGz
		String SingularityExe
		String DvSimg
		String DvExe
		Boolean Version = false
		# task specific variables
		File BamFile
		File BamIndex
		String IntervalBedFile
		String ModelType
		String Data
		String RefData
		String OutDir
		String Output
		String VcSuffix
		# runtime attributes
		String Queue
		# String? Node
		Int Cpu
		Int Memory
	}
	# OutPath differs if modules called from dvIdentito or panelCapture
	String OutPath = if WorkflowType == "" then "~{OutDir}" else "~{OutDir}/~{SampleID}/~{WorkflowType}"
	command <<<
		set -e # To make task stop at 1st error
		source ~{CondaBin}activate ~{SingularityEnv}
		TMPDIR=/scratch/tmp
		APPTAINER_TMPDIR=/scratch/tmp
		APPTAINER_CACHEDIR=/scratch/tmp
		SINGULARITY_TMPDIR=/scratch/tmp
		SINGULARITY_CACHEDIR=/scratch/tmp
		~{SingularityExe} run \
		--bind "~{Output}" \
		--bind "~{RefData}" \
		--bind "~{Data}" \
		~{DvSimg} ~{DvExe} \
		--model_type="~{ModelType}" \
		--ref="~{RefFastaGz}" \
		--reads="~{BamFile}" \
		--regions="~{IntervalBedFile}" \
		--num_shards="~{Cpu}" \
		--output_vcf="~{OutPath}/~{SampleID}.~{VcSuffix}.vcf.gz"

		if [ ~{Version} = true ];then
			# fill-in tools version file			
			echo "DeepVariant: v$(~{SingularityExe} run ~{DvSimg} ~{DvExe} --version 2>/dev/null | grep 'DeepVariant' | cut -f3 -d ' ')" >> "~{OutPath}/~{SampleID}.versions.txt"
		fi
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
		# node: "~{Node}"
	}
	output{
		 File DeepVcf = "~{OutPath}/~{SampleID}.~{VcSuffix}.vcf.gz"
	}
}
