version 1.0

import "panelCapture.wdl" as runPanelCapture

workflow metaPanelCapture {
	meta {
		author: "Felix VANDERMEEREN"
		email: "felix.vandermeeren(at)chu-montpellier.fr"
		version: "0.3.1"
		date: "2026-01-19"
	}
	input {
		# variables declarations
		## Global
		Array[Array[String]] inputsLists  # [["BEDbasename_A","sample1","FASTQbasename_R1","FASTQbasename_R2","ListeGenes_A.txt","group_A"],["BEDbasename_B", "sample2","FASTQbasename_R1","FASTQbasename_R2","ListeGenes_B.txt","group_B"]] groups are optional
		String roiDir  # WARN: Assume all BEDs are in same dir
		String fastqDirname  # WARN: Assume all FASTQ are in same dir
		String suffix1 = "_S1_R1_001"
		String suffix2 = "_S1_R2_001"
		String genomeVersion
		File refFasta
		File refFai
		File refDict
		String intervalBaitBed = ""
		String workflowType
		String outDir
		Boolean debug = false
		## conda
		String condaBin
		## envs
		String fastpEnv = "fastpEnv"
		String bwaEnv = "bwaEnv"
		String samtoolsEnv = "samtoolsEnv"
		String vcftoolsEnv = "vcftoolsEnv"	
		String sambambaEnv = "sambambaEnv"
		String bedtoolsEnv = "bedtoolsEnv"
		String crumbleEnv = "crumbleEnv"
		String bcftoolsEnv = "bcftoolsEnv"
		String multiqcEnv = "multiqcEnv"
		String singularityEnv = "singularityEnv"
		String anacoreEnv = "anacoreEnv"
		## queues
		String defQueue = "prod"
		String avxQueue = "avx"
		## resources
		Int cpuHigh
		Int cpuLow
		# Int avxCpu
		Int memoryLow
		Int memoryHigh
		# memoryLow = scattered tasks =~ mem_per_cpu in HPC or not
		# memoryHigh = one cpu tasks => high mem ex 10Gb
		## Bioinfo execs
		String fastpExe = "fastp"
		String bwaExe = "bwa"
		String samtoolsExe = "samtools"
		String sambambaExe = "sambamba"
		String bedToolsExe = "bedtools"
		String bcftoolsExe = "bcftools"
		String bgZipExe = "bgzip"
		String tabixExe = "tabix"
		String multiqcExe = "multiqc"
		String vcftoolsExe = "vcftools"
		String crumbleExe = "crumble"
		String gatkExe = "gatk"
		String ldLibraryPath
		String vcfPolyXJar
		## Anacore-Utils custom mergeVCF script
		File mergeVCFMobiDL
		## Standard execs
		String awkExe = "awk"
		String sedExe = "sed"
		String sortExe = "sort"		
		String javaExe = "java"
		String cromwellJar
		## fastp
		String noFiltering = ""
		## bwaSamtools
		String platform
		File refAmb
		File refAnn
		File refBwt
		File refPac
		File refSa
		## sambambaIndex
		## gatk splitintervals
		String subdivisionMode
		## gatk Base recal
		File knownSites1
		File knownSites1Index
		File knownSites2
		File knownSites2Index
		File knownSites3
		File knownSites3Index
		## cram conversion
		File refFastaGz
		File refFaiGz
		File refFaiGzi
		## crumble
		Boolean doCrumble = true
		## gatk-picard
		String variantEvalEV = "MetricsCollection"
		## computePoorCoverage
		Int bedtoolsLowCoverage
		Int bedToolsSmallInterval
		## computeCoverage
		Int minCovBamQual
		## haplotypeCaller
		String swMode
		String emitRefConfidence = "NONE"
		## DeepVariant
		# String referenceFasta
		String modelType
		# String bedFile
		String data
		String refData
		# String dvOut
		String outputMnt
		String dvExe
		String singularityExe = "singularity"
		String dvSimg
		## VcSuffix
		String dvSuffix = ".dv"
		String hcSuffix = ".hc"
		## covreport
		String covReportDir
		String covReportJar
		File geneFile
	}
	scatter (inputs in inputsLists) {
		String fastqLocR1 = if defined(inputs[5]) then "~{fastqDirname}/~{inputs[5]}/inputs[2]" else "~{fastqDirname}/~{inputs[2]}"
		String fastqLocR2 = if defined(inputs[5]) then "~{fastqDirname}/~{inputs[5]}/inputs[3]" else "~{fastqDirname}/~{inputs[3]}"
		String modifiedOutDir = if defined(inputs[5]) then "~{outDir}/~{inputs[5]}/" else "~{outDir}"
		call runPanelCapture.panelCapture {
			input:
				sampleID = inputs[1],
				suffix1 = suffix1,
				suffix2 = suffix2,
				# fastqR2 = fastqDirname + "/" + inputs[3],
				# fastqR1 = fastqDirname + "/" + inputs[2],
				fastqR1 = fastqLocR1,
				fastqR2 = fastqLocR2,
				genomeVersion = genomeVersion,
				refFasta = refFasta,
				refFai = refFai,
				refDict = refDict,
				intervalBedFile = roiDir + "/" + inputs[0],
				intervalBaitBed = intervalBaitBed,
				workflowType = workflowType,
				# outDir = outDir + "/" + inputs[5] + "/",
				outDir = modifiedOutDir,
				debug = debug,
				condaBin = condaBin,
				fastpEnv = fastpEnv,
				bwaEnv = bwaEnv,
				samtoolsEnv = samtoolsEnv,
				vcftoolsEnv = vcftoolsEnv,
				sambambaEnv = sambambaEnv,
				bedtoolsEnv = bedtoolsEnv,
				crumbleEnv = crumbleEnv,
				bcftoolsEnv = bcftoolsEnv,
				multiqcEnv = multiqcEnv,
				singularityEnv = singularityEnv,
				anacoreEnv = anacoreEnv,
				defQueue = defQueue,
				avxQueue = avxQueue,
				cpuHigh = cpuHigh,
				cpuLow = cpuLow,
				memoryLow = memoryLow,
				memoryHigh = memoryHigh,
				fastpExe = fastpExe,
				bwaExe = bwaExe,
				samtoolsExe = samtoolsExe,
				sambambaExe = sambambaExe,
				bedToolsExe = bedToolsExe,
				bcftoolsExe = bcftoolsExe,
				bgZipExe = bgZipExe,
				tabixExe = tabixExe,
				multiqcExe = multiqcExe,
				vcftoolsExe = vcftoolsExe,
				crumbleExe = crumbleExe,
				gatkExe = gatkExe,
				ldLibraryPath = ldLibraryPath,
				vcfPolyXJar = vcfPolyXJar,
				mergeVCFMobiDL = mergeVCFMobiDL,
				awkExe = awkExe,
				sedExe = sedExe,
				sortExe = sortExe,
				javaExe = javaExe,
				cromwellJar = cromwellJar,
				noFiltering = noFiltering,
				platform = platform,
				refAmb = refAmb,
				refAnn = refAnn,
				refBwt = refBwt,
				refPac = refPac,
				refSa = refSa,
				subdivisionMode = subdivisionMode,
				knownSites1 = knownSites1,
				knownSites1Index = knownSites1Index,
				knownSites2 = knownSites2,
				knownSites2Index = knownSites2Index,
				knownSites3 = knownSites3,
				knownSites3Index = knownSites3Index,
				refFastaGz = refFastaGz,
				refFaiGz = refFaiGz,
				refFaiGzi = refFaiGzi,
				doCrumble = doCrumble,
				variantEvalEV = variantEvalEV,
				bedtoolsLowCoverage = bedtoolsLowCoverage,
				bedToolsSmallInterval = bedToolsSmallInterval,
				minCovBamQual = minCovBamQual,
				swMode = swMode,
				emitRefConfidence = emitRefConfidence,
				modelType = modelType,
				data = data,
				refData = refData,
				outputMnt = outputMnt,
				dvExe = dvExe,
				singularityExe = singularityExe,
				dvSimg = dvSimg,
				dvSuffix = dvSuffix,
				hcSuffix = hcSuffix,
				covReportDir = covReportDir,
				covReportJar = covReportJar,
				geneFile = geneFile + "/" + inputs[4]
		}
	} 
}
