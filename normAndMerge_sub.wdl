version 1.0


# import "modules/bcftoolsNorm.wdl" as runBcftoolsNorm  # -> Cannot use, cuz does not use fasta to normalize... (-> NO inDels left alignement)
import "modules/refcallFiltration.wdl" as runRefCallFiltration
import "modules/compressIndexVcf.wdl" as runCompressIndexVcf
import "modules/anacoreUtilsMergeVCFCallers.wdl" as runAnacoreUtilsMergeVCFCallers
import "modules/gatkUpdateVCFSequenceDictionary.wdl" as runGatkUpdateVCFSequenceDictionary


workflow normAndMerge {
    meta {
        author: "Felix VANDERMEEREN"
        email: "felix.vandermeeren(at)chu-montpellier.fr"
        version: "0.2.1"
        date: "2025-07-15"
    }

    input {
		## VcSuffix
		String dvSuffix = ".deepvariant.norm"
		String hcSuffix = ".haplotypecaller.norm"
        ## envs
        String condaBin = "/mnt/Bioinfo/Softs/miniconda/bin/"
        String vcftoolsEnv = "/bioinfo/conda_envs/vcftoolsEnv"
        String bcftoolsEnv = "/bioinfo/conda_envs/bcftoolsEnv"
        String samtoolsEnv = "/bioinfo/conda_envs/samtoolsEnv"
        String anacoreEnv = "/bioinfo/conda_envs/anacoreEnv"
        ## queues
        String defQueue = "prod"
        ##Resources
		Int cpuLow = 1
		Int memoryLow = 2400
        ## Exe
        String vcftoolsExe = "vcftools"
        String bcftoolsExe = "bcftools"
        String tabixExe = "tabix"
        String bgZipExe = "bgzip"
		File mergeVCFMobiDL = "/bioinfo/softs/anacore-custom/anacoreUtils/anacoreUtilsMergeVCFCallersMobiDL.py"  # Anacore-Utils custom mergeVCF script
        String gatkExe = "gatk"
        ## Global
		String samplesList  # Same as MobiCorail '--samples' = CSG123,CAD456,CSG789
        String workflowType = ""
        ## Workflow specific
		File refFasta
		File refFai
		File refDict
        # INPUTS (assume Sarek style output):
        String inDir
        String dvDir = inDir + "/variant_calling/deepvariant/"
        String hcDir = inDir + "/variant_calling/haplotypecaller/"
        # OUTPUTS:
        String outDir = inDir
        String outDvDir = outDir + "/variant_calling/deepvariant/"
        String outHcDir = outDir + "/variant_calling/haplotypecaller/"
        String outMergeDir = outDir + "/variant_calling/merge/"
    }

	call listToArray {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryLow,
			List = samplesList,
			Separator = ","
	}
	scatter (sampleID in listToArray.samplesArray) {
        File deepVariantVcf = dvDir + sampleID + "/" + sampleID + ".deepvariant.vcf.gz"
        # MEMO: Bellow use 'filtered' HC VCF (= after 'CNNScoreVariants' to set 'FILTER' field):
        File haplotypeCallerVcf = hcDir + sampleID + "/" + sampleID + ".haplotypecaller.filtered.vcf.gz"
		# DeepVariant VCF produced by Sarek still contains 'refCall' -> remove them
		# vcftools support only VCF by default -> decompress first
		call bcftoolsDecompress {
			input:
				Queue = defQueue,
				CondaBin = condaBin,
				BcftoolsEnv = bcftoolsEnv,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = "./",
				WorkflowType = workflowType,
				BcftoolsExe = bcftoolsExe,
				VcSuffix = ".deepvariant",
				SortedVcf = deepVariantVcf
		}
		call runRefCallFiltration.refCallFiltration {
			input:
				Queue = defQueue,
				CondaBin = condaBin,
				VcftoolsEnv = vcftoolsEnv,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = outDvDir,
				WorkflowType = workflowType,
				VcSuffix = ".deepvariant",
				VcftoolsExe = vcftoolsExe,
				Version = true,
				VcfToRefCalled = bcftoolsDecompress.outVcf
		}
		#Normalize DeepVariant VCF (+ index)
		call bcftoolsNorm as bcftoolsNormDv {
			input:
				Queue = defQueue,
				CondaBin = condaBin,
				BcftoolsEnv = bcftoolsEnv,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = outDvDir,
				WorkflowType = workflowType,
				BcftoolsExe = bcftoolsExe,
				VcSuffix = dvSuffix,
				Version = true,
				SortedVcf = refCallFiltration.noRefCalledVcf,
				RefFasta = refFasta
		}
		call runCompressIndexVcf.compressIndexVcf as compressIndexVcfDv {
			input:
				Queue = defQueue,
				CondaBin = condaBin,
				SamtoolsEnv = samtoolsEnv,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = outDvDir,
				WorkflowType = workflowType,
				BgZipExe = bgZipExe,
				TabixExe = tabixExe,
				VcSuffix = dvSuffix,
				Version = true,
				VcfFile = bcftoolsNormDv.normVcf
		}
		#Normalize HaplotypeCaller VCF (+ index)
		call bcftoolsNorm as bcftoolsNormHc {
			input:
				Queue = defQueue,
				CondaBin = condaBin,
				BcftoolsEnv = bcftoolsEnv,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = outHcDir,
				WorkflowType = workflowType,
				BcftoolsExe = bcftoolsExe,
				VcSuffix = hcSuffix,
				SortedVcf = haplotypeCallerVcf,
				RefFasta = refFasta
		}
		call runCompressIndexVcf.compressIndexVcf as compressIndexVcfHc {
			input:
				Queue = defQueue,
				CondaBin = condaBin,
				SamtoolsEnv = samtoolsEnv,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = outHcDir,
				WorkflowType = workflowType,
				BgZipExe = bgZipExe,
				TabixExe = tabixExe,
				VcSuffix = hcSuffix,
				VcfFile = bcftoolsNormHc.normVcf
		}
		#Merge both HC and DV VCFs (+ index)
		# MEMO: Have to create 'merge' subdir first
		call mkMergeDir {
			input:
				Queue = defQueue,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = outMergeDir,
				WorkflowType = workflowType
		}
		call runAnacoreUtilsMergeVCFCallers.anacoreUtilsMergeVCFCallers {
			input:
				Queue = defQueue,
				CondaBin = condaBin,
				AnacoreEnv = anacoreEnv,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = "./",
				WorkflowType = workflowType,
				MergeVCFMobiDL = mergeVCFMobiDL,
				Vcfs = [bcftoolsNormHc.normVcf, bcftoolsNormDv.normVcf],
				Callers = ["HaplotypeCaller", "DeepVariant"]
		}
		call runGatkUpdateVCFSequenceDictionary.gatkUpdateVCFSequenceDictionary {
			input:
				Queue = defQueue,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = outMergeDir,
				WorkflowType = workflowType,
				GatkExe = gatkExe,
				RefFasta = refFasta,
				RefFai = refFai,
				RefDict = refDict,
				Vcf = anacoreUtilsMergeVCFCallers.mergedVcf
		}
		call runCompressIndexVcf.compressIndexVcf as compressIndexMergedVcf {
			input:
				Queue = defQueue,
				CondaBin = condaBin,
				SamtoolsEnv = samtoolsEnv,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = outMergeDir,
				WorkflowType = workflowType,
				BgZipExe = bgZipExe,
				TabixExe = tabixExe,
				VcSuffix = '',
				VcfFile = gatkUpdateVCFSequenceDictionary.refUpdatedVcf
		}
	}

    output {
        Array[File] normHcVcf = compressIndexVcfHc.bgZippedVcf
        Array[File] normDvVcf = compressIndexVcfDv.bgZippedVcf
        Array[File] mergedVcf = compressIndexMergedVcf.bgZippedVcf  # Merged VCF (HC + DV)
    }
}

task bcftoolsDecompress {
	meta {
		author: "Felix VANDERMEEREN"
		email: "felix.vandermeeren(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2025-07-01"
	}
	input {
		# env variables
		String CondaBin
		String BcftoolsEnv
		# global variables
		String SampleID
		String OutDir
		String WorkflowType
		String BcftoolsExe
		Boolean Version = false
		# task specific variables
		File SortedVcf
		String VcSuffix
		String VcfExtension = "vcf"
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutVcf = OutDir + SampleID + WorkflowType + WorkflowType + SampleID + VcSuffix + "." + VcfExtension
	command <<<
		set -e  # To make task stop at 1st error
		source ~{CondaBin}activate ~{BcftoolsEnv}
		~{BcftoolsExe} view \
			-O v -o "~{OutVcf}" \
			~{SortedVcf}
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "Bcftools: v$(~{BcftoolsExe} --version | grep bcftools | cut -f2 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt";
		fi
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File outVcf = OutVcf
	}
}

task bcftoolsNorm {
	meta {
		author: "Felix VANDERMEEREN"
		email: "felix.vandermeeren(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2025-07-01"
	}
	input {
		# env variables	
		String CondaBin
		String BcftoolsEnv
		# global variables
		String SampleID
		String OutDir
		String WorkflowType
		String BcftoolsExe
		Boolean Version = false
		# task specific variables
		File SortedVcf
		File RefFasta
		String VcSuffix
		String VcfExtension = "vcf"
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		set -e  # To make task stop at 1st error
		source ~{CondaBin}activate ~{BcftoolsEnv}
		#-f ~{RefFasta}  # Not used by MobiDL
		~{BcftoolsExe} norm \
			-m -both \
			-O v -o "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.~{VcfExtension}" \
			~{SortedVcf}
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "Bcftools: v$(~{BcftoolsExe} --version | grep bcftools | cut -f2 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt";
		fi
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File normVcf = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.~{VcfExtension}"
	}
}

task mkMergeDir {
	meta {
		author: "Felix VANDERMEEREN"
		email: "felix.vandermeeren(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2025-07-01"
	}
	input {
		# global variables
		String SampleID
		String OutDir
		String WorkflowType
		Boolean Version = false
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		set -e  # To make task stop at 1st error
		mkdir -p "~{OutDir}~{SampleID}/~{WorkflowType}/"
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		String mergeDir = "~{OutDir}~{SampleID}/~{WorkflowType}/"
	}
}

task listToArray {
	meta {
		author: "Felix VANDERMEEREN"
		email: "felix.vandermeeren(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2025-08-25"
	}
	input {
		# global variables
		String List
		String Separator
		Boolean Version = false
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		set -e  # To make task stop at 1st error
		for item in $(echo "~{List}" | tr ~{Separator} ' '); do
			echo "$item"
		done
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		Array[String] samplesArray = read_lines(stdout())
	}
}
