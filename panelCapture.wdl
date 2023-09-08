version 1.0

import "modules/preparePanelCaptureTmpDirs.wdl" as runPreparePanelCaptureTmpDirs
import "modules/fastp.wdl" as runFastp
import "modules/bwaSamtools.wdl" as runBwaSamtools
import "modules/sambambaIndex.wdl" as runSambambaIndex
import "modules/sambambaMarkDup.wdl" as runSambambaMarkDup
import "modules/bedToGatkIntervalList.wdl" as runBedToGatkIntervalList
import "modules/gatkSplitIntervals.wdl" as runGatkSplitIntervals
import "modules/gatkBaseRecalibrator.wdl" as runGatkBaseRecalibrator
import "modules/gatkGatherBQSRReports.wdl" as runGatkGatherBQSRReports
import "modules/gatkApplyBQSR.wdl" as runGatkApplyBQSR
import "modules/gatkLeftAlignIndels.wdl" as runGatkLeftAlignIndels
import "modules/gatkGatherBamFiles.wdl" as runGatkGatherBamFiles
import "modules/samtoolsSort.wdl" as runSamtoolsSort
import "modules/samtoolsCramConvert.wdl" as runSamtoolsCramConvert
import "modules/samtoolsCramIndex.wdl" as runSamtoolsCramIndex
import "modules/crumble.wdl" as runCrumble
import "modules/sambambaFlagStat.wdl" as runSambambaFlagStat
import "modules/gatkCollectMultipleMetrics.wdl" as runGatkCollectMultipleMetrics
import "modules/gatkCollectInsertSizeMetrics.wdl" as runGatkCollectInsertSizeMetrics
import "modules/gatkBedToPicardIntervalList.wdl" as runGatkBedToPicardIntervalList
import "modules/computePoorCoverage.wdl" as runComputePoorCoverage
import "modules/samtoolsBedCov.wdl" as runSamtoolsBedCov
import "modules/computeCoverage.wdl" as runComputeCoverage
import "modules/computeCoverageClamms.wdl" as runComputeCoverageClamms
import "modules/gatkCollectHsMetrics.wdl" as runGatkCollectHsMetrics
import "modules/deepVariant.wdl" as runDeepVariant
import "modules/bcftoolsNorm.wdl" as runBcftoolsNorm
import "modules/compressIndexVcf.wdl" as runCompressIndexVcf
import "modules/jvarkitVcfPolyX.wdl" as runJvarkitVcfPolyX
import "modules/gatkSortVcf.wdl" as runGatkSortVcf
import "modules/bcftoolsStats.wdl" as runBcftoolsStats
# import "modules/gatkVariantEval.wdl" as runGatkVariantEval
import "modules/refcallFiltration.wdl" as runRefCallFiltration
import "modules/gatkVariantFiltrationDv.wdl" as runGatkVariantFiltrationDv
import "modules/gatkHaplotypeCaller.wdl" as runGatkHaplotypeCaller
import "modules/gatkGatherVcfs.wdl" as runGatkGatherVcfs
# import "modules/qualimapBamQc.wdl" as runQualimapBamQc
import "modules/gatkSplitVcfs.wdl" as runGatkSplitVcfs
import "modules/gatkVariantFiltrationSnp.wdl" as runGatkVariantFiltrationSnp
import "modules/gatkVariantFiltrationIndel.wdl" as runGatkVariantFiltrationIndel
import "modules/gatkMergeVcfs.wdl" as runGatkMergeVcfs
import "modules/anacoreUtilsMergeVCFCallers.wdl" as runAnacoreUtilsMergeVCFCallers
import "modules/gatkUpdateVCFSequenceDictionary.wdl" as runGatkUpdateVCFSequenceDictionary
import "modules/cleanUpPanelCaptureTmpDirs.wdl" as runCleanUpPanelCaptureTmpDirs
import "modules/multiqc.wdl" as runMultiqc

workflow panelCapture {
	meta {
		author: "David BAUX"
		email: "david.baux(at)chu-montpellier.fr"
		version: "1.2.0"
		date: "2023-09-01"
	}
	input {
		# variables declarations
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
		String jvarkitEnv = "jvarkitEnv"
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
		Int avxCpu
		Int memoryLow
		Int memoryHigh
		# memoryLow = scattered tasks =~ mem_per_cpu in HPC or not
		# memoryHigh = one cpu tasks => high mem ex 10Gb
		## Global
		String sampleID
		String suffix1
		String suffix2
		File fastqR1
		File fastqR2
		String genomeVersion
		File refFasta
		File refFai
		File refDict
		File intervalBedFile
		String intervalBaitBed = ""
		File intervalBaitBedFile = if intervalBaitBed == "" then intervalBedFile else intervalBaitBed
		String workflowType
		String outDir
		Boolean debug = false
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
		String referenceFasta
		String modelType
		String bedFile
		String data
		String refData
		String dvOut
		String outputMnt
		String dvExe
		String singularityExe = "singularity"
		String dvSimg
		## VcSuffix
		String dvSuffix = ".dv"
		String hcSuffix = ".hc"
	}

	# Tasks calls
	call runPreparePanelCaptureTmpDirs.preparePanelCaptureTmpDirs {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			GenomeVersion = genomeVersion
	}
	call runFastp.fastp {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			FastpEnv = fastpEnv,
			Cpu = cpuHigh,
			Memory = memoryLow,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			FastpExe = fastpExe,
			Version = true,
			NoFiltering = noFiltering,
			FastqR1 = fastqR1,
			FastqR2 = fastqR2,
			Suffix1 = suffix1,
			Suffix2 = suffix2,
			DirsPrepared = preparePanelCaptureTmpDirs.dirsPrepared
	}
###################################################################################
#
# Alignment and post-alignment processing + QC
#
###################################################################################
	call runBwaSamtools.bwaSamtools {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			BwaEnv = bwaEnv,
			Cpu = cpuHigh,
			Memory = memoryLow,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			FastqR1 = fastp.fastpR1,
			FastqR2 = fastp.fastpR2,
			SamtoolsExe = samtoolsExe,
			BwaExe = bwaExe,
			Version = true,
			Platform = platform,
			RefFasta = refFasta,
			RefAmb = refAmb,
			RefAnn = refAnn,
			RefBwt = refBwt,
			RefPac = refPac,
			RefSa = refSa
	}
	call runSambambaMarkDup.sambambaMarkDup {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			SambambaEnv = sambambaEnv,
			Cpu = cpuHigh,
			Memory = memoryLow,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			SambambaExe = sambambaExe,
			BamFile = bwaSamtools.sortedBam
	}
	call runBedToGatkIntervalList.bedToGatkIntervalList {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			IntervalBedFile = intervalBedFile,
			AwkExe = awkExe,
			DirsPrepared = preparePanelCaptureTmpDirs.dirsPrepared,
			
	}
	call runGatkSplitIntervals.gatkSplitIntervals {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			GatkExe = gatkExe,			
			RefFasta = refFasta,
			RefFai = refFai,
			RefDict = refDict,
			Version = true,
			GatkInterval = bedToGatkIntervalList.gatkIntervals,
			SubdivisionMode = subdivisionMode,
			ScatterCount = cpuHigh
	}
	scatter (interval in gatkSplitIntervals.splittedIntervals) {
		call runGatkBaseRecalibrator.gatkBaseRecalibrator {
			input:
				Queue = defQueue,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = outDir,
				WorkflowType = workflowType,
				GatkExe = gatkExe,
				RefFasta = refFasta,
				RefFai = refFai,
				RefDict = refDict,
				GatkInterval = interval,
				BamFile = sambambaMarkDup.markedBam,
				BamIndex = sambambaMarkDup.markedBamIndex,
				KnownSites1 = knownSites1,
				KnownSites1Index = knownSites1Index,
				KnownSites2 = knownSites2,
				KnownSites2Index = knownSites2Index,
				KnownSites3 = knownSites3,
				KnownSites3Index = knownSites3Index
		}
	}
	call runGatkGatherBQSRReports.gatkGatherBQSRReports {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			GatkExe = gatkExe,
			RecalTables = gatkBaseRecalibrator.recalTable
	}
	scatter (interval in gatkSplitIntervals.splittedIntervals) {
		call runGatkApplyBQSR.gatkApplyBQSR {
			input:
				Queue = defQueue,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = outDir,
				WorkflowType = workflowType,
				GatkExe = gatkExe,
				RefFasta = refFasta,
				RefFai = refFai,
				RefDict = refDict,
				GatkInterval = interval,
				BamFile = sambambaMarkDup.markedBam,
				BamIndex = sambambaMarkDup.markedBamIndex,
				GatheredRecaltable = gatkGatherBQSRReports.gatheredRecalTable
		}
		call runGatkLeftAlignIndels.gatkLeftAlignIndels {
			input:
				Queue = defQueue,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = outDir,
				WorkflowType = workflowType,
				GatkExe = gatkExe,
				RefFasta = refFasta,
				RefFai = refFai,
				RefDict = refDict,
				GatkInterval = interval,
				BamFile = gatkApplyBQSR.recalBam
		}
	}
	call runGatkGatherBamFiles.gatkGatherBamFiles {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			GatkExe = gatkExe,
			LAlignedBams = gatkLeftAlignIndels.lAlignedBam
	}
	call runSamtoolsSort.samtoolsSort {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			SamtoolsEnv = samtoolsEnv,
			Cpu = cpuHigh,
			Memory = memoryLow,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			SamtoolsExe = samtoolsExe,
			BamFile = gatkGatherBamFiles.gatheredBam
	}
	call runSambambaIndex.sambambaIndex as finalIndexing {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			SambambaEnv = sambambaEnv,
			Cpu = cpuHigh,
			Memory = memoryLow,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			SambambaExe = sambambaExe,
			Version = true,
			BamFile = samtoolsSort.sortedBam
	}
	call runSamtoolsCramConvert.samtoolsCramConvert {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			SamtoolsEnv = samtoolsEnv,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			SamtoolsExe = samtoolsExe,
			BamFile = samtoolsSort.sortedBam,
			RefFastaGz = refFastaGz,
			RefFaiGz = refFaiGz,
			RefFaiGzi = refFaiGzi
	}
	call runSamtoolsCramIndex.samtoolsCramIndex {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			SamtoolsEnv = samtoolsEnv,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			SamtoolsExe = samtoolsExe,
			CramFile = samtoolsCramConvert.cram,
			CramSuffix = ""
	}
	call runCrumble.crumble {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			CrumbleEnv = crumbleEnv,
			Cpu = cpuHigh,
			Memory = memoryLow,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			CrumbleExe = crumbleExe,
			Version = true,
			LdLibraryPath = ldLibraryPath,
			InputFile = samtoolsCramConvert.cram,
			InputFileIndex =  samtoolsCramIndex.cramIndex,
			FileType = "cram"
	}
	call runSamtoolsCramIndex.samtoolsCramIndex as crumbleIndexing {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			SamtoolsEnv = samtoolsEnv,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			SamtoolsExe = samtoolsExe,
			Version = true,
			CramFile = crumble.crumbled,
			CramSuffix = ".crumble"
	}
	call runSambambaFlagStat.sambambaFlagStat {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			SambambaEnv = sambambaEnv,
			Cpu = cpuHigh,
			Memory = memoryLow,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			SambambaExe = sambambaExe,
			BamFile = samtoolsSort.sortedBam
	}
	call runGatkCollectMultipleMetrics.gatkCollectMultipleMetrics {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			GatkExe = gatkExe,
			RefFasta = refFasta,
			BamFile = samtoolsSort.sortedBam
	}
	call runGatkCollectInsertSizeMetrics.gatkCollectInsertSizeMetrics {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			GatkExe = gatkExe,
			RefFasta = refFasta,
			BamFile = samtoolsSort.sortedBam
	}
	call runGatkBedToPicardIntervalList.gatkBedToPicardIntervalList as gatkBedToPicardIntervalListTarget {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			IntervalBedFile = intervalBedFile,
			RefDict = refDict,
			GatkExe = gatkExe,
			DirsPrepared = preparePanelCaptureTmpDirs.dirsPrepared
	}
	call runGatkBedToPicardIntervalList.gatkBedToPicardIntervalList as gatkBedToPicardIntervalListBait {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			Bait = true,
			IntervalBedFile = intervalBaitBedFile,
			RefDict = refDict,
			GatkExe = gatkExe,
			DirsPrepared = preparePanelCaptureTmpDirs.dirsPrepared
	}
	call runComputePoorCoverage.computePoorCoverage {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			BedtoolsEnv = bedtoolsEnv,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			GenomeVersion = genomeVersion,
			BedToolsExe = bedToolsExe,
			AwkExe = awkExe,
			SortExe = sortExe,
			IntervalBedFile = intervalBedFile,
			BedtoolsLowCoverage = bedtoolsLowCoverage,
			BedToolsSmallInterval = bedToolsSmallInterval,
			BamFile = samtoolsSort.sortedBam
	}
	call runSamtoolsBedCov.samtoolsBedCov {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			SamtoolsEnv = samtoolsEnv,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			SamtoolsExe = samtoolsExe,
			IntervalBedFile = intervalBedFile,
			BamFile = samtoolsSort.sortedBam,
			BamIndex = finalIndexing.bamIndex,
			MinCovBamQual = minCovBamQual
	}
	call runComputeCoverage.computeCoverage {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			AwkExe = awkExe,
			SortExe = sortExe,
			BedCovFile = samtoolsBedCov.BedCovFile
	}
	call runComputeCoverageClamms.computeCoverageClamms {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			AwkExe = awkExe,
			SortExe = sortExe,
			BedCovFile = samtoolsBedCov.BedCovFile
	}
	call runGatkCollectHsMetrics.gatkCollectHsMetrics {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			GatkExe = gatkExe,
			RefFasta = refFasta,
			RefFai = refFai,
			BamFile = samtoolsSort.sortedBam,
			BaitIntervals = gatkBedToPicardIntervalListBait.picardIntervals,
			TargetIntervals = gatkBedToPicardIntervalListTarget.picardIntervals
	}
###################################################################################
#
# Variant Calling 1: DeepVariant
#
###################################################################################
	call runDeepVariant.deepVariant {
		input:
			Queue = avxQueue,
			CondaBin = condaBin,
			SingularityEnv = singularityEnv,
			Cpu = avxCpu,
			Memory = memoryLow,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,			
			DvExe = dvExe,
			GatkExe = gatkExe,
			SingularityExe = singularityExe,
			Version = true,
			DvSimg = dvSimg,
			BamFile = samtoolsSort.sortedBam,
			BamIndex = finalIndexing.bamIndex,
			ReferenceFasta = referenceFasta,
			BedFile = bedFile,
			ModelType = modelType,
			Data = data,
			RefData = refData,
			DvOut = dvOut,
			Output = outputMnt,
			VcSuffix = dvSuffix
	}
	call runRefCallFiltration.refCallFiltration {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			VcftoolsEnv = vcftoolsEnv,
			Cpu = cpuLow,
			Memory = memoryLow,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			VcSuffix = dvSuffix,
			VcftoolsExe = vcftoolsExe,
			Version = true,
			VcfToRefCalled = deepVariant.DeepVcf
	}
	call runGatkSortVcf.gatkSortVcf as gatkSortVcfDv {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			GatkExe = gatkExe,
			VcSuffix = dvSuffix,
			UnsortedVcf = refCallFiltration.noRefCalledVcf
	}
	call runJvarkitVcfPolyX.jvarkitVcfPolyX as jvarkitVcfPolyxDv {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			RefFasta = refFasta,
			RefFai = refFai,
			RefDict = refDict,
			JavaExe = javaExe,
			VcfPolyXJar = vcfPolyXJar,
			VcSuffix = dvSuffix,
			Version = true,
			Vcf = gatkSortVcfDv.sortedVcf,
			VcfIndex = gatkSortVcfDv.sortedVcfIndex
	}
	call runGatkVariantFiltrationDv.gatkVariantFiltrationDv {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			GatkExe = gatkExe,
			RefFasta = refFasta,
			RefFai = refFai,
			RefDict = refDict,
			Vcf = jvarkitVcfPolyxDv.polyxedVcf,
			VcfIndex = jvarkitVcfPolyxDv.polyxedVcfIndex,
			VcSuffix = dvSuffix,
			LowCoverage = bedtoolsLowCoverage
	}
	call runBcftoolsNorm.bcftoolsNorm as bcftoolsNormDv {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			BcftoolsEnv = bcftoolsEnv,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			BcftoolsExe = bcftoolsExe,
			VcSuffix = dvSuffix,
			Version = true,
			SortedVcf = gatkVariantFiltrationDv.filteredVcf
	}
	call runCompressIndexVcf.compressIndexVcf as compressIndexVcfDv {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			SamtoolsEnv = samtoolsEnv,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			BgZipExe = bgZipExe,
			TabixExe = tabixExe,
			VcSuffix = dvSuffix,
			VcfFile = bcftoolsNormDv.normVcf
	}
	call runBcftoolsStats.bcftoolsStats as bcftoolsStatsDv {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			BcftoolsEnv = bcftoolsEnv,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			BcftoolsExe = bcftoolsExe,
			VcSuffix = dvSuffix,
			VcfFile = compressIndexVcfDv.bgZippedVcf,
			VcfFileIndex = compressIndexVcfDv.bgZippedVcfIndex
	}
	#not ready for production (gath 4.1.4.0) and toooooooo loooooonnnnggggg
	#call runGatkVariantEval.gatkVariantEval as gatkVariantEvalDv{
	#	input:
		#	Queue = defQueue,
		#	CondaBin = condaBin,
		#	Cpu = cpuHigh,
		#	Memory = memoryLow,
		#	SampleID = sampleID,
		#	OutDir = outDir,
		#	WorkflowType = workflowType,
		#	GatkExe = gatkExe,
		#	VariantEvalEV = variantEvalEV,
		#	VcSuffix = dvSuffix,
		#	VcfFile = bcftoolsNormDv.normVcf,
		#	RefFasta = refFasta,
		#	RefFai = refFai,
		#	RefDict = refDict,
		#	DbSNP = knownSites3,
		#	DbSNPIndex = knownSites3Index
	#}
###################################################################################
#
# Variant Calling 2: Haplotype Caller
#
###################################################################################
	scatter (interval in gatkSplitIntervals.splittedIntervals) {
		call runGatkHaplotypeCaller.gatkHaplotypeCaller {
			input:
				Queue = defQueue,
				Cpu = cpuLow,
				Memory = memoryLow,
				SampleID = sampleID,
				OutDir = outDir,
				WorkflowType = workflowType,
				GatkExe = gatkExe,
				RefFasta = refFasta,
				RefFai = refFai,
				RefDict = refDict,
				DbSNP = knownSites3,
				DbSNPIndex = knownSites3Index,
				GatkInterval = interval,
				BamFile = samtoolsSort.sortedBam,
				BamIndex = finalIndexing.bamIndex,
				SwMode = swMode,
				EmitRefConfidence = emitRefConfidence
		}
	}
	call runGatkGatherVcfs.gatkGatherVcfs {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			GatkExe = gatkExe,
			Version = true,
			HcVcfs = gatkHaplotypeCaller.hcVcf,
			VcSuffix = hcSuffix
	}
	call runJvarkitVcfPolyX.jvarkitVcfPolyX as jvarkitVcfPolyxHc {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			RefFasta = refFasta,
			RefFai = refFai,
			RefDict = refDict,
			JavaExe = javaExe,
			VcfPolyXJar = vcfPolyXJar,
			VcSuffix = hcSuffix,
			Vcf = gatkGatherVcfs.gatheredHcVcf,
			VcfIndex = gatkGatherVcfs.gatheredHcVcfIndex
	}
	call runGatkSplitVcfs.gatkSplitVcfs {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			VcSuffix = hcSuffix,
			GatkExe = gatkExe,
			Vcf = jvarkitVcfPolyxHc.polyxedVcf,
			VcfIndex = jvarkitVcfPolyxHc.polyxedVcfIndex
	}
	call runGatkVariantFiltrationSnp.gatkVariantFiltrationSnp {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			GatkExe = gatkExe,
			RefFasta = refFasta,
			RefFai = refFai,
			RefDict = refDict,
			Vcf = gatkSplitVcfs.snpVcf,
			VcfIndex = gatkSplitVcfs.snpVcfIndex,
			LowCoverage = bedtoolsLowCoverage
	}
	call runGatkVariantFiltrationIndel.gatkVariantFiltrationIndel {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			GatkExe = gatkExe,
			RefFasta = refFasta,
			RefFai = refFai,
			RefDict = refDict,
			Vcf = gatkSplitVcfs.indelVcf,
			VcfIndex = gatkSplitVcfs.indelVcfIndex,
			LowCoverage = bedtoolsLowCoverage
	}
	call runGatkMergeVcfs.gatkMergeVcfs {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			GatkExe = gatkExe,
			Vcfs = [gatkVariantFiltrationSnp.filteredSnpVcf, gatkVariantFiltrationIndel.filteredIndelVcf],
			VcSuffix = hcSuffix
	}
	call runGatkSortVcf.gatkSortVcf as gatkSortVcfHc {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			GatkExe = gatkExe,
			VcSuffix = hcSuffix,
			UnsortedVcf = gatkMergeVcfs.mergedVcf
	}
	call runBcftoolsNorm.bcftoolsNorm as bcftoolsNormHc {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			BcftoolsEnv = bcftoolsEnv,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			BcftoolsExe = bcftoolsExe,
			VcSuffix = hcSuffix,
			SortedVcf = gatkSortVcfHc.sortedVcf
	}
	# not ready for production (gath 4.1.4.0) and toooooooo loooooonnnnggggg
	# call runGatkVariantEval.gatkVariantEval as gatkVariantEvalHc{
	#	 input:
		#	 Queue = defQueue,
		#	 CondaBin = condaBin,
		#	 Cpu = cpuLow,
		#	 Memory = memoryHigh,
		#	 SampleID = sampleID,
		#	 OutDir = outDir,
		#	 WorkflowType = workflowType,
		#	 GatkExe = gatkExe,
		# 	 VariantEvalEV = variantEvalEV,
		#	 VcSuffix = hcSuffix,
		#	 VcfFile = bcftoolsNormHc.normVcf,
		#	 RefFasta = refFasta,
		#	 RefFai = refFai,
		#	 RefDict = refDict,
		#	 DbSNP = knownSites3,
		#	 DbSNPIndex = knownSites3Index
	# }
	call runCompressIndexVcf.compressIndexVcf as compressIndexVcfHc {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			SamtoolsEnv = samtoolsEnv,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			BgZipExe = bgZipExe,
			TabixExe = tabixExe,
			VcSuffix = hcSuffix,
			VcfFile = bcftoolsNormHc.normVcf
	}
	call runBcftoolsStats.bcftoolsStats as bcftoolsStatsHc {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			BcftoolsEnv = bcftoolsEnv,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			BcftoolsExe = bcftoolsExe,
			VcSuffix = hcSuffix,
			VcfFile = compressIndexVcfHc.bgZippedVcf,
			VcfFileIndex = compressIndexVcfHc.bgZippedVcfIndex
	}
	call runAnacoreUtilsMergeVCFCallers.anacoreUtilsMergeVCFCallers {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			AnacoreEnv = anacoreEnv,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			MergeVCFMobiDL = mergeVCFMobiDL,
			Vcfs = [bcftoolsNormHc.normVcf, bcftoolsNormDv.normVcf],
			Callers = ["HaplotypeCaller", "DeepVariant"]
	}
	call runGatkUpdateVCFSequenceDictionary.gatkUpdateVCFSequenceDictionary {
		input:
			Queue = defQueue,
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
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
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			BgZipExe = bgZipExe,
			TabixExe = tabixExe,
			VcSuffix = '',
			VcfFile = gatkUpdateVCFSequenceDictionary.refUpdatedVcf
	}
	if (!debug) {
		String dataPath = "~{outDir}~{sampleID}/~{workflowType}/"
		call runCleanUpPanelCaptureTmpDirs.cleanUpPanelCaptureTmpDirs {
			input:
				Queue = defQueue,
				Cpu = cpuLow,
				Memory = memoryHigh,
				SampleID = sampleID,
				OutDir = outDir,
				WorkflowType = workflowType,
				FinalFile1 = compressIndexMergedVcf.bgZippedVcf,
				FinalFile2 = crumbleIndexing.cramIndex,
				JavaExe = javaExe,
				CromwellJar = cromwellJar,
				BamArray = ["~{dataPath}" + basename(sambambaMarkDup.markedBam), "~{dataPath}" + basename(sambambaMarkDup.markedBamIndex), "~{dataPath}" + basename(gatkGatherBQSRReports.gatheredRecalTable), "~{dataPath}" + basename(gatkGatherBamFiles.gatheredBam), "~{dataPath}" + basename(samtoolsSort.sortedBam), "~{dataPath}" + basename(finalIndexing.bamIndex), "~{dataPath}" + basename(samtoolsCramConvert.cram),"~{dataPath}" + basename(samtoolsCramIndex.cramIndex)],
				VcfArray = ["~{dataPath}" + basename(refCallFiltration.noRefCalledVcf),"~{dataPath}" + basename(gatkSortVcfDv.sortedVcf),"~{dataPath}" + basename(gatkSortVcfDv.sortedVcfIndex),"~{dataPath}" + basename(jvarkitVcfPolyxDv.polyxedVcf),"~{dataPath}" + basename(jvarkitVcfPolyxDv.polyxedVcfIndex),"~{dataPath}" + basename(gatkVariantFiltrationDv.filteredVcf),"~{dataPath}" + basename(gatkVariantFiltrationDv.filteredVcfIndex), "~{dataPath}" + basename(gatkGatherVcfs.gatheredHcVcf), "~{dataPath}" + basename(gatkGatherVcfs.gatheredHcVcfIndex), "~{dataPath}" + basename(jvarkitVcfPolyxHc.polyxedVcf), "~{dataPath}" + basename(jvarkitVcfPolyxHc.polyxedVcfIndex), "~{dataPath}" + basename(gatkSplitVcfs.snpVcf), "~{dataPath}" + basename(gatkSplitVcfs.snpVcfIndex), "~{dataPath}" + basename(gatkSplitVcfs.indelVcf), "~{dataPath}" + basename(gatkSplitVcfs.indelVcfIndex), "~{dataPath}" + basename(gatkVariantFiltrationSnp.filteredSnpVcf), "~{dataPath}" + basename(gatkVariantFiltrationSnp.filteredSnpVcfIndex), "~{dataPath}" + basename(gatkVariantFiltrationIndel.filteredIndelVcf), "~{dataPath}" + basename(gatkVariantFiltrationIndel.filteredIndelVcfIndex), "~{dataPath}" + basename(gatkMergeVcfs.mergedVcf), "~{dataPath}" + basename(gatkMergeVcfs.mergedVcfIndex), "~{dataPath}" + basename(gatkSortVcfHc.sortedVcf), "~{dataPath}" + basename(gatkSortVcfHc.sortedVcfIndex), "~{dataPath}" + basename(compressIndexVcfHc.bgZippedVcf), "~{dataPath}" + basename(compressIndexVcfHc.bgZippedVcfIndex), "~{dataPath}" + basename(compressIndexVcfDv.bgZippedVcf), "~{dataPath}" + basename(compressIndexVcfDv.bgZippedVcfIndex), "~{dataPath}" + basename(anacoreUtilsMergeVCFCallers.mergedVcf)]
		}
		call runMultiqc.multiqc {
			input:
				Queue = defQueue,
				CondaBin = condaBin,
				MultiqcEnv = multiqcEnv,
				Cpu = cpuLow,
				Memory = memoryHigh,
				SampleID = sampleID,
				OutDir = outDir,
				WorkflowType = workflowType,
				MultiqcExe = multiqcExe,
				GatkExe = gatkExe,
				Version = true,
				Vcf = cleanUpPanelCaptureTmpDirs.finalFile1
		}
	}
# 	if (!debug) {
# 		call runToolVersions.toolVersions {
# 			input:
	# 			Cpu = cpuLow,
	# 			Memory = memoryHigh,
	# 			SampleID = sampleID,
	# 			OutDir = outDir,
	# 			WorkflowType = workflowType,
	# 			GenomeVersion = genomeVersion,
	# 			FastpExe = fastpExe,
	# 			BwaExe = bwaExe,
	# 			SamtoolsExe = samtoolsExe,
	# 			SambambaExe = sambambaExe,
	# 			BedToolsExe = bedToolsExe,
	# 			QualimapExe = qualimapExe,
	# 			BcftoolsExe = bcftoolsExe,
	# 			BgZipExe = bgZipExe,
	# 			CrumbleExe = crumbleExe,
	# 			TabixExe = tabixExe,
	# 			MultiqcExe = multiqcExe,
	# 			GatkExe = gatkExe,
	# 			SingularityExe = singularityExe,
	# 			DvSimg = dvSimg,
	# 			DvExe = dvExe,
	# 			JavaExe= javaExe,
	# 			VcfPolyXJar = vcfPolyXJar,
	# 			Vcf = cleanUpPanelCaptureTmpDirs.finalFile1
# 		}
# 	}
# 	if (debug) {
# 		call runToolVersions.toolVersions as toolVersionsDebug {
# 			input:
	# 			Cpu = cpuLow,
	# 			Memory = memoryHigh,
	# 			SampleID = sampleID,
	# 			OutDir = outDir,
	# 			WorkflowType = workflowType,
	# 			GenomeVersion = genomeVersion,
	# 			FastpExe = fastpExe,
	# 			BwaExe = bwaExe,
	# 			SamtoolsExe = samtoolsExe,
	# 			SambambaExe = sambambaExe,
	# 			BedToolsExe = bedToolsExe,
	# 			QualimapExe = qualimapExe,
	# 			BcftoolsExe = bcftoolsExe,
	# 			BgZipExe = bgZipExe,
	# 			CrumbleExe = crumbleExe,
	# 			TabixExe = tabixExe,
	# 			MultiqcExe = multiqcExe,
	# 			GatkExe = gatkExe,
	# 			SingularityExe = singularityExe,
	# 			DvSimg = dvSimg,
	# 			DvExe = dvExe,
	# 			JavaExe= javaExe,
	# 			VcfPolyXJar = vcfPolyXJar,
	# 			Vcf = compressIndexVcf.bgZippedVcf
# 		}
# 	}
	output {
		File? FinalVcf = cleanUpPanelCaptureTmpDirs.finalFile1
		File FinalCram = crumble.crumbled
		File FinalCramIndex = crumbleIndexing.cramIndex
		File? Qualityfile = multiqc.multiqcHtml
	}
}
