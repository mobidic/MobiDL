import "modules/preparePanelCaptureTmpDirs.wdl" as runPreparePanelCaptureTmpDirs
import "modules/fastqc.wdl" as runFastqc
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
import "modules/sambambaFlagStat.wdl" as runSambambaFlagStat
import "modules/gatkCollectMultipleMetrics.wdl" as runGatkCollectMultipleMetrics
import "modules/gatkCollectInsertSizeMetrics.wdl" as runGatkCollectInsertSizeMetrics
import "modules/gatkBedToPicardIntervalList.wdl" as runGatkBedToPicardIntervalList
import "modules/computePoorCoverage.wdl" as runComputePoorCoverage
import "modules/samtoolsBedCov.wdl" as runSamtoolsBedCov
import "modules/computeCoverage.wdl" as runComputeCoverage
import "modules/computeCoverageClamms.wdl" as runComputeCoverageClamms
import "modules/gatkCollectHsMetrics.wdl" as runGatkCollectHsMetrics
import "modules/gatkHaplotypeCaller.wdl" as runGatkHaplotypeCaller
import "modules/gatkGatherVcfs.wdl" as runGatkGatherVcfs
import "modules/qualimapBamQc.wdl" as runQualimapBamQc
import "modules/jvarkitVcfPolyX.wdl" as runJvarkitVcfPolyX
import "modules/gatkSplitVcfs.wdl" as runGatkSplitVcfs
import "modules/gatkVariantFiltrationSnp.wdl" as runGatkVariantFiltrationSnp
import "modules/gatkVariantFiltrationIndel.wdl" as runGatkVariantFiltrationIndel
import "modules/gatkMergeVcfs.wdl" as runGatkMergeVcfs
import "modules/gatkSortVcf.wdl" as runGatkSortVcf
import "modules/bcftoolsNorm.wdl" as runBcftoolsNorm
import "modules/compressIndexVcf.wdl" as runCompressIndexVcf
import "modules/deepVariant.wdl" as runDeepVariant
import "modules/refcallFiltration.wdl" as runRefCallFiltration
import "modules/gatkHardFilteringVcf.wdl" as runGatkHardFilteringVcf
import "modules/bcftoolsStats.wdl" as runBcftoolsStats
# import "modules/gatkVariantEval.wdl" as runGatkVariantEval
# import "modules/gatkCombineVariants.wdl" as runGatkCombineVariants
# import "modules/rtgMergeVcfs.wdl" as runRtgMerge
# import "modules/fixVcfHeaders.wdl" as runFixVcfHeaders
import "modules/crumble.wdl" as runCrumble
import "modules/anacoreUtilsMergeVCFCallers.wdl" as runAnacoreUtilsMergeVCFCallers
import "modules/gatkUpdateVCFSequenceDictionary.wdl" as runGatkUpdateVCFSequenceDictionary
import "modules/cleanUpPanelCaptureTmpDirs.wdl" as runCleanUpPanelCaptureTmpDirs
import "modules/multiqc.wdl" as runMultiqc
import "modules/toolVersions.wdl" as runToolVersions
workflow panelCapture {
	meta {
		author: "David Baux, Djenaba Barry"
		email: "david.baux(at)inserm.fr"
	}
	# variables declarations
	## Resources
	Int cpuHigh
	Int cpuLow
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
	String workflowType
	String outDir
	Boolean debug = false
	## Bioinfo execs
	String fastqcExe
	String bwaExe
	String samtoolsExe
	String sambambaExe
	String bedToolsExe
	String qualimapExe
	String bcfToolsExe
	String bgZipExe
	String tabixExe
	String multiqcExe
	## Standard execs
	String awkExe
	String sedExe
	String sortExe
	String gatkExe
	String javaExe
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
	## jvarkit
	String vcfPolyXJar
	## ConvertCramtoCrumble
	String crumbleExe
	String ldLibraryPath
	## DeepVariant
	String referenceFasta
	String modelType
	String bedFile
	String data
	String refData
	String dvOut
	String outputMnt
	String deepExe
	String singularity
	String singularityImg
	## RefCallFiltration
	String vcftoolsExe
	## VcSuffix
	String dvSuffix = ".dv"
	String hcSuffix = ".hc"
	## Anacore-Utils mcustom mergeVCF script
	File mergeVCFMobiDL


	# Tasks calls
	call runPreparePanelCaptureTmpDirs.preparePanelCaptureTmpDirs {
		input:
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType
	}
	#if (preparePanelCaptureTmpDirs.dirsPrepared) {
	call runFastqc.fastqc {
		input:
		Cpu = cpuHigh,
		Memory = memoryLow,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		FastqcExe = fastqcExe,
		FastqR1 = fastqR1,
		FastqR2 = fastqR2,
		Suffix1 = suffix1,
		Suffix2 = suffix2,
		DirsPrepared = preparePanelCaptureTmpDirs.dirsPrepared
	}
	#}
	call runBwaSamtools.bwaSamtools {
		input:
		Cpu = cpuHigh,
		Memory = memoryLow,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		FastqR1 = fastqR1,
		FastqR2 = fastqR2,
		SamtoolsExe = samtoolsExe,
		BwaExe = bwaExe,
		Platform = platform,
		RefFasta = refFasta,
		RefAmb = refAmb,
		RefAnn = refAnn,
		RefBwt = refBwt,
		RefPac = refPac,
		RefSa = refSa
	}
	#call runSambambaIndex.sambambaIndex {
	#	input:
	#	Cpu = cpuHigh,
	#	Memory = memoryLow,
	#	SampleID = sampleID,
	#	OutDir = outDir,
	#	WorkflowType = workflowType,
	#	SambambaExe = sambambaExe,
	#	BamFile = bwaSamtools.sortedBam
	#}
	call runSambambaMarkDup.sambambaMarkDup {
		input:
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
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		IntervalBedFile = intervalBedFile,
		AwkExe = awkExe,
		DirsPrepared = preparePanelCaptureTmpDirs.dirsPrepared
	}
	call runGatkSplitIntervals.gatkSplitIntervals {
		input:
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		GatkExe = gatkExe,
		RefFasta = refFasta,
		RefFai = refFai,
		RefDict = refDict,
		GatkInterval = bedToGatkIntervalList.gatkIntervals,
		SubdivisionMode = subdivisionMode,
		ScatterCount = cpuHigh
	}
	scatter (interval in gatkSplitIntervals.splittedIntervals) {
		call runGatkBaseRecalibrator.gatkBaseRecalibrator {
			input:
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
	output {
			Array[File] recalTables = gatkBaseRecalibrator.recalTable
	}
	call runGatkGatherBQSRReports.gatkGatherBQSRReports {
		input:
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		GatkExe = gatkExe,
		RecalTables = recalTables
	}
	scatter (interval in gatkSplitIntervals.splittedIntervals) {
		call runGatkApplyBQSR.gatkApplyBQSR {
			input:
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
	output {
		Array[File] lAlignedBams = gatkLeftAlignIndels.lAlignedBam
	}
	call runGatkGatherBamFiles.gatkGatherBamFiles {
		input:
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		GatkExe = gatkExe,
		LAlignedBams = lAlignedBams
	}
	call runSamtoolsSort.samtoolsSort {
		input:
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
		Cpu = cpuHigh,
		Memory = memoryLow,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		SambambaExe = sambambaExe,
		BamFile = samtoolsSort.sortedBam
	}
	call runSamtoolsCramConvert.samtoolsCramConvert {
		input:
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
		Cpu = cpuHigh,
		Memory = memoryLow,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		CrumbleExe = crumbleExe,
		LdLibraryPath = ldLibraryPath,
		InputFile = samtoolsCramConvert.cram,
		InputFileIndex =  samtoolsCramIndex.cramIndex,
		FileType = "cram"
	}
	call runSamtoolsCramIndex.samtoolsCramIndex as crumbleIndexing {
		input:
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		SamtoolsExe = samtoolsExe,
		CramFile = crumble.crumbled,
		CramSuffix = ".crumble"
	}
	call runSambambaFlagStat.sambambaFlagStat {
		input:
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
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		GatkExe = gatkExe,
		RefFasta = refFasta,
		BamFile = samtoolsSort.sortedBam
	}
	call runQualimapBamQc.qualimapBamQc {
		input:
		Cpu = cpuHigh,
		Memory = memoryLow,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		QualimapExe = qualimapExe,
		BamFile = samtoolsSort.sortedBam,
		IntervalBedFile = intervalBedFile,
	}
	call runGatkBedToPicardIntervalList.gatkBedToPicardIntervalList {
		input:
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
	call runComputePoorCoverage.computePoorCoverage {
		input:
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
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		GatkExe = gatkExe,
		RefFasta = refFasta,
		RefFai = refFai,
		BamFile = samtoolsSort.sortedBam,
		BaitIntervals = gatkBedToPicardIntervalList.picardIntervals,
		TargetIntervals = gatkBedToPicardIntervalList.picardIntervals
	}
##################################################Deep#################################
	call runDeepVariant.deepVariant{
		input:
		Cpu = cpuHigh,
		Memory = memoryLow,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		BamFile = samtoolsSort.sortedBam,
		BamIndex = finalIndexing.bamIndex,
		ReferenceFasta = referenceFasta,
		BedFile = bedFile,
		ModelType = modelType,
		Data = data,
		RefData = refData,
		DvOut = dvOut,
		Output = outputMnt,
		VcSuffix = dvSuffix,
		DeepExe = deepExe,
		GatkExe = gatkExe,
		Singularity = singularity,
		SingularityImg = singularityImg
	}
	call runRefCallFiltration.refCallFiltration{
		input:
		Cpu = cpuLow,
		Memory = memoryLow,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		VcSuffix = dvSuffix,
		VcftoolsExe = vcftoolsExe,
		VcfToRefCalled = deepVariant.DeepVcf
	}
	call runGatkSortVcf.gatkSortVcf as gatkSortVcfDv {
		input:
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
		Vcf = gatkSortVcfDv.sortedVcf,
		VcfIndex = gatkSortVcfDv.sortedVcfIndex
	}
	call runGatkHardFilteringVcf.gatkHardFiltering {
		input:
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
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		BcfToolsExe = bcfToolsExe,
		VcSuffix = dvSuffix,
		SortedVcf = gatkHardFiltering.HardFilteredVcf
	}
	call runCompressIndexVcf.compressIndexVcf as compressIndexVcfDv {
		input:
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
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		BcfToolsExe = bcfToolsExe,
		VcSuffix = dvSuffix,
		VcfFile = compressIndexVcfDv.bgZippedVcf,
		VcfFileIndex = compressIndexVcfDv.bgZippedVcfIndex
	}
	#not ready for production (gath 4.1.4.0) and toooooooo loooooonnnnggggg
	#call runGatkVariantEval.gatkVariantEval as gatkVariantEvalDv{
	#	input:
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
##############################################HaplotypeCaller######################@
	scatter (interval in gatkSplitIntervals.splittedIntervals) {
		call runGatkHaplotypeCaller.gatkHaplotypeCaller {
			input:
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
	output {
		Array[File] hcVcfs = gatkHaplotypeCaller.hcVcf
	}
	call runGatkGatherVcfs.gatkGatherVcfs {
		input:
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		GatkExe = gatkExe,
		HcVcfs = hcVcfs,
		VcSuffix = hcSuffix
	}
	call runJvarkitVcfPolyX.jvarkitVcfPolyX as jvarkitVcfPolyxHc {
		input:
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
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		BcfToolsExe = bcfToolsExe,
		VcSuffix = hcSuffix,
		SortedVcf = gatkSortVcfHc.sortedVcf
	}
	# not ready for production (gath 4.1.4.0) and toooooooo loooooonnnnggggg
	# call runGatkVariantEval.gatkVariantEval as gatkVariantEvalHc{
	#	 input:
	#	 Cpu = cpuLow,
	#	 Memory = memoryHigh,
	#	 SampleID = sampleID,
	#	 OutDir = outDir,
	#	 WorkflowType = workflowType,
	#	 GatkExe = gatkExe,
	# 	VariantEvalEV = variantEvalEV,
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
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		BgZipExe = bgZipExe,
		TabixExe = tabixExe,
		VcSuffix = hcSuffix,
		# NormVcf = bcftoolsNormHc.normVcf
		VcfFile = gatkSortVcfHc.sortedVcf
	}
#	call runRtgMerge.rtgMerge{
#		input:
#		Cpu = cpuLow,
#		Memory = memoryHigh,
#		SampleID = sampleID,
#		OutDir = outDir,
#		WorkflowType = workflowType,
#		VcfSuffix = vcfSISuffix,
#		RtgExe = rtgExe,
#		VcfFiles= [compressIndexVcfHc.bgZippedVcf, compressIndexVcfDv.bgZippedVcf],
#		VcfFilesIndex = [compressIndexVcfHc.bgZippedVcfIndex, compressIndexVcfDv.bgZippedVcfIndex]
#	}
#	call runGatkCombineVariants.gatkCombineVariants{
#		input:
#		Cpu = cpuLow,
#		Memory = memoryHigh,
#		SampleID = sampleID,
#		OutDir = outDir,
#		WorkflowType = workflowType,
#		JavaExe = javaExe,
#		Gatk3Jar = gatk3Jar,
#		RefFasta = refFasta,
#		RefFai = refFai,
#		RefDict = refDict,
#		VcfSuffix = vcfSISuffix,
#		VcfFiles = [bcftoolsNormHc.normVcf, bcftoolsNormDv.normVcf],
#		GenotypeMergeOptions = genotypeMergeOptions,
#		FilteredRecordsMergeType = filteredRecordsMergeType
		#VcfFilesIndex = [compressIndexVcfHc.bgZippedVcfIndex, compressIndexVcfDv.bgZippedVcfIndex]
#	}
#	call runGatkSortVcf.gatkSortVcf as gatkSortVcfEnd {
#		input:
#		Cpu = cpuLow,
#		Memory = memoryHigh,
#		SampleID = sampleID,
#		OutDir = outDir,
#		WorkflowType = workflowType,
#		GatkExe = gatkExe,
#		VcSuffix = finalSuffix,
#		UnsortedVcf  = rtgMerge.rtgMergedVcf
#	}
#	call runFixVcfHeaders.fixVcfHeaders {
#		input:
#		Cpu = cpuLow,
#		Memory = memoryHigh,
#		SampleID = sampleID,
#		OutDir = outDir,
#		WorkflowType = workflowType,
#		SedExe = sedExe,
#		VcfFile = gatkCombineVariants.mergedVcf,
#		VcfIndex = gatkCombineVariants.mergedVcfIndex,
#		VcfSuffix = vcfSISuffix
#	}
#	call runBcftoolsNorm.bcftoolsNorm as bcftoolsNormEnd {
#		input:
#		Cpu = cpuLow,
#		Memory = memoryHigh,
#		SampleID = sampleID,
#		OutDir = outDir,
#		WorkflowType = workflowType,
#		BcfToolsExe = bcfToolsExe,
#		VcSuffix = finalSuffix,
#		SortedVcf = fixVcfHeaders.finalVcf
#	}
#	call runCompressIndexVcf.compressIndexVcf as compressIndexVcfHc {
#		input:
#		Cpu = cpuLow,
#		Memory = memoryHigh,
#		SampleID = sampleID,
#		OutDir = outDir,
#		WorkflowType = workflowType,
#		BgZipExe = bgZipExe,
#		TabixExe = tabixExe,
#		VcSuffix = hcSuffix,
#		VcfFile = bcftoolsNormHc.normVcf
#	}
	call runBcftoolsStats.bcftoolsStats as bcftoolsStatsHc {
		input:
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		BcfToolsExe = bcfToolsExe,
		VcSuffix = hcSuffix,
		VcfFile = compressIndexVcfHc.bgZippedVcf,
		VcfFileIndex = compressIndexVcfHc.bgZippedVcfIndex
	}
	call runAnacoreUtilsMergeVCFCallers.anacoreUtilsMergeVCFCallers {
		input:
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
	call runCompressIndexVcf.compressIndexVcf {
		input:
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
		String dataPath = "${outDir}${sampleID}/${workflowType}/"
		call runCleanUpPanelCaptureTmpDirs.cleanUpPanelCaptureTmpDirs {
			input:
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			FinalFile1 = compressIndexVcf.bgZippedVcf,
			FinalFile2 = crumbleIndexing.cramIndex,
			BamArray = ["${dataPath}" + basename(sambambaMarkDup.markedBam), "${dataPath}" + basename(sambambaMarkDup.markedBamIndex), "${dataPath}" + basename(gatkGatherBQSRReports.gatheredRecalTable), "${dataPath}" + basename(gatkGatherBamFiles.gatheredBam), "${dataPath}" + basename(samtoolsSort.sortedBam), "${dataPath}" + basename(finalIndexing.bamIndex), "${dataPath}" + basename(samtoolsCramConvert.cram),"${dataPath}" + basename(samtoolsCramIndex.cramIndex)],
			VcfArray = ["${dataPath}" + basename(refCallFiltration.noRefCalledVcf),"${dataPath}" + basename(gatkSortVcfDv.sortedVcf),"${dataPath}" + basename(gatkSortVcfDv.sortedVcfIndex),"${dataPath}" + basename(jvarkitVcfPolyxDv.polyxedVcf),"${dataPath}" + basename(jvarkitVcfPolyxDv.polyxedVcfIndex),"${dataPath}" + basename(gatkHardFiltering.HardFilteredVcf),"${dataPath}" + basename(gatkHardFiltering.HardFilteredVcfIndex), "${dataPath}" + basename(gatkGatherVcfs.gatheredHcVcf), "${dataPath}" + basename(gatkGatherVcfs.gatheredHcVcfIndex), "${dataPath}" + basename(jvarkitVcfPolyxHc.polyxedVcf), "${dataPath}" + basename(jvarkitVcfPolyxHc.polyxedVcfIndex), "${dataPath}" + basename(gatkSplitVcfs.snpVcf), "${dataPath}" + basename(gatkSplitVcfs.snpVcfIndex), "${dataPath}" + basename(gatkSplitVcfs.indelVcf), "${dataPath}" + basename(gatkSplitVcfs.indelVcfIndex), "${dataPath}" + basename(gatkVariantFiltrationSnp.filteredSnpVcf), "${dataPath}" + basename(gatkVariantFiltrationSnp.filteredSnpVcfIndex), "${dataPath}" + basename(gatkVariantFiltrationIndel.filteredIndelVcf), "${dataPath}" + basename(gatkVariantFiltrationIndel.filteredIndelVcfIndex), "${dataPath}" + basename(gatkMergeVcfs.mergedVcf), "${dataPath}" + basename(gatkMergeVcfs.mergedVcfIndex), "${dataPath}" + basename(gatkSortVcfHc.sortedVcf), "${dataPath}" + basename(gatkSortVcfHc.sortedVcfIndex), "${dataPath}" + basename(compressIndexVcfHc.bgZippedVcf), "${dataPath}" + basename(compressIndexVcfHc.bgZippedVcfIndex), "${dataPath}" + basename(compressIndexVcfDv.bgZippedVcf), "${dataPath}" + basename(compressIndexVcfDv.bgZippedVcfIndex), "${dataPath}" + basename(anacoreUtilsMergeVCFCallers.mergedVcf)]
			#"${dataPath}" + basename(deepVariant.DeepVcf), "${dataPath}" + basename(bcftoolsNormHc.normVcf), "${dataPath}" + basename(bcftoolsNormDv.normVcf)
			#"${dataPath}" + basename(deepVariant.DeepVcf), "${dataPath}" + basename(refCallFiltration.noRefCalledVcf),"${dataPath}" + basename(gatkSortVcfDv.sortedVcf),"${dataPath}" + basename(gatkSortVcfDv.sortedVcfIndex),"${dataPath}" + basename(jvarkitVcfPolyxDv.polyxedVcf),"${dataPath}" + basename(jvarkitVcfPolyxDv.polyxedVcfIndex),"${dataPath}" + basename(gatkHardFiltering.HardFilteredVcf),"${dataPath}" + basename(gatkHardFiltering.HardFilteredVcfIndex), "${dataPath}" + basename(bcftoolsNormEnd.normVcf)
		}

		call runMultiqc.multiqc {
			input:
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			MultiqcExe = multiqcExe,
			Vcf = cleanUpPanelCaptureTmpDirs.finalFile1
		}
	}
	call runToolVersions.toolVersions {
		input:
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		GenomeVersion = genomeVersion,
    FastqcExe = fastqcExe,
    BwaExe = bwaExe,
    SamtoolsExe = samtoolsExe,
    SambambaExe = sambambaExe,
    BedToolsExe = bedToolsExe,
    QualimapExe = qualimapExe,
    BcfToolsExe = bcfToolsExe,
    BgZipExe = bgZipExe,
    CrumbleExe = crumbleExe,
    TabixExe = tabixExe,
    MultiqcExe = multiqcExe,
    GatkExe = gatkExe,
    JavaExe= javaExe,
    VcfPolyXJar = vcfPolyXJar,
		Vcf = cleanUpPanelCaptureTmpDirs.finalFile1
    }
	output {
		File? FinalVcf = cleanUpPanelCaptureTmpDirs.finalFile1
		File FinalCram = crumble.crumbled
		File FinalCramIndex = crumbleIndexing.cramIndex
		File VersionFile = toolVersions.versionFile
	}
}
