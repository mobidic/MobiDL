version 1.0


import "modules/refcallFiltration.wdl" as runRefCallFiltration
import "modules/bcftoolsNorm.wdl" as runBcftoolsNorm
import "modules/compressIndexVcf.wdl" as runCompressIndexVcf
import "modules/anacoreUtilsMergeVCFCallers.wdl" as runAnacoreUtilsMergeVCFCallers
import "modules/gatkUpdateVCFSequenceDictionary.wdl" as runGatkUpdateVCFSequenceDictionary
import "modules/identito.wdl" as runIdentito


workflow normAndMerge {
    meta {
        author: "Felix VANDERMEEREN"
        email: "felix.vandermeeren(at)chu-montpellier.fr"
        version: "0.4.3"
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
		Boolean keepFiles = false
        ## Workflow specific
		File fasta
		File fasta_fai
		File dict
        # INPUTS (assume Sarek style output):
        String inDir
        String dvDir = inDir + "/variant_calling/deepvariant/"
        String hcDir = inDir + "/variant_calling/haplotypecaller/"
        # OUTPUTS:
        String outDir = inDir
        String outDvDir = outDir + "/variant_calling/deepvariant/"
        String outHcDir = outDir + "/variant_calling/haplotypecaller/"
        String outMergeDir = outDir + "/variant_calling/merge/"
        ## Identito (default = SNPXplex. rsIDs order here will be maintained)
        String idList = "rs11702450,rs843345,rs1058018,rs8017,rs3738494,rs1065483,rs2839181,rs11059924,rs2075144,rs6795772,rs456261,rs1131620,rs2231926,rs352169,rs3739160"
		String csvtkExe = "/bioinfo/softs/bin/csvtk"
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
		call bcftoolsDecompress as bcftoolsDecompressDv {
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
				VcfToRefCalled = bcftoolsDecompressDv.outVcf
		}
		#Normalize DeepVariant VCF (+ index)
		call runBcftoolsNorm.bcftoolsNorm as bcftoolsNormDv {
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
				SortedVcf = refCallFiltration.noRefCalledVcf
		}
		## MEMO: First have to rename Sarek style 'sample_sample -> sample'
		call renameVCFsample as renameVcfDv {
			input:
				Queue = defQueue,
				CondaBin = condaBin,
				BcftoolsEnv = bcftoolsEnv,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = "./",
				VcfFile = bcftoolsNormDv.normVcf
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
				VcfFile = renameVcfDv.renamedVCF
		}
		#Normalize HaplotypeCaller VCF (+ index)
		call runBcftoolsNorm.bcftoolsNorm as bcftoolsNormHc {
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
				SortedVcf = haplotypeCallerVcf
		}
		## MEMO: First have to rename Sarek style 'sample_sample -> sample'
		call renameVCFsample as renameVcfHc {
			input:
				Queue = defQueue,
				CondaBin = condaBin,
				BcftoolsEnv = bcftoolsEnv,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = "./",
				VcfFile = bcftoolsNormHc.normVcf
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
				VcfFile = renameVcfHc.renamedVCF
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
				OutDir = outMergeDir,
				WorkflowType = workflowType,
				MergeVCFMobiDL = mergeVCFMobiDL,
				Vcfs = [renameVcfHc.renamedVCF, renameVcfDv.renamedVCF],
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
				RefFasta = fasta,
				RefFai = fasta_fai,
				RefDict = dict,
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

		# Get identito SNP (on HC vcf because rsID properly annotated)
		call runIdentito.identito as identito {
			input:
				Queue = defQueue,
				CondaBin = condaBin,
				BcftoolsEnv = bcftoolsEnv,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = outHcDir,
				WorkflowType = "",
				QualDir = "",
				CsvtkExe = csvtkExe,
				VcfFile = compressIndexVcfHc.bgZippedVcf,
				IDlist = idList
		}

		if (!keepFiles) {
			call cleanUp {
				input:
					Queue = defQueue,
					Cpu = cpuLow,
					Memory = memoryLow,
					TaskOuput = [compressIndexMergedVcf.bgZippedVcf],
					ListToRm = [
								refCallFiltration.noRefCalledVcf,
								bcftoolsNormHc.normVcf,
								bcftoolsNormDv.normVcf,
								anacoreUtilsMergeVCFCallers.mergedVcf,
								gatkUpdateVCFSequenceDictionary.refUpdatedVcf,
								gatkUpdateVCFSequenceDictionary.refUpdatedVcfIndex
							]
			}
		}
	}

    output {
        Array[File] mergedVcf = compressIndexMergedVcf.bgZippedVcf  # Merged VCF (HC + DV)
        Array[File] identitoFile = identito.outIdent
    }
}


# TASKS
task renameVCFsample {
	input {
		File VcfFile
		String SampleID
		String OutDir

		String CondaBin
		String BcftoolsEnv
		String BcftoolsExe = "bcftools"
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
    }
	String OutVCF = OutDir + "/" + SampleID + ".renamed.vcf"
	command <<<
		set -e
		source ~{CondaBin}activate ~{BcftoolsEnv}
		set -x
		# MEMO: '-s' expect a FILE
		~{BcftoolsExe} reheader -s <(echo ~{SampleID}) -o ~{OutVCF} ~{VcfFile}
	>>>

	output {
		File renamedVCF = OutVCF
	}

    runtime {
        queue: "~{Queue}"
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}

task cleanUp {
	meta {
		author: "Felix VANDERMEEREN"
		email: "felix.vandermeeren(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2025-08-31"
	}
	input {
		# global variables
		Array[File] ListToRm
		Boolean Version = false
		# runtime attributes
		Array[File]? TaskOuput  # To enforce serial execution
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		set -e  # To make task stop at 1st error
		set -x
		# MEMO: Cwl outfiles are symlinks to real file -> readlink required
		for aFile in ~{sep=" " ListToRm}; do
			rm "$(readlink "$aFile")"
		done
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
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
