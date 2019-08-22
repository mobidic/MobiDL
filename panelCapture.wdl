import "/softs/MobiDL/modules/preparePanelCaptureTmpDirs.wdl" as runPreparePanelCaptureTmpDirs
import "/softs/MobiDL/modules/fastqc.wdl" as runFastqc
import "/softs/MobiDL/modules/bwaSamtools.wdl" as runBwaSamtools
import "/softs/MobiDL/modules/sambambaIndex.wdl" as runSambambaIndex
import "/softs/MobiDL/modules/sambambaMarkDup.wdl" as runSambambaMarkDup
import "/softs/MobiDL/modules/bedToGatkIntervalList.wdl" as runBedToGatkIntervalList
import "/softs/MobiDL/modules/gatkSplitIntervals.wdl" as runGatkSplitIntervals
import "/softs/MobiDL/modules/gatkBaseRecalibrator.wdl" as runGatkBaseRecalibrator
import "/softs/MobiDL/modules/gatkGatherBQSRReports.wdl" as runGatkGatherBQSRReports
import "/softs/MobiDL/modules/gatkApplyBQSR.wdl" as runGatkApplyBQSR
import "/softs/MobiDL/modules/gatkLeftAlignIndels.wdl" as runGatkLeftAlignIndels
import "/softs/MobiDL/modules/gatkGatherBamFiles.wdl" as runGatkGatherBamFiles
import "/softs/MobiDL/modules/samtoolsSort.wdl" as runSamtoolsSort
import "/softs/MobiDL/modules/samtoolsCramConvert.wdl" as runSamtoolsCramConvert
import "/softs/MobiDL/modules/samtoolsCramIndex.wdl" as runSamtoolsCramIndex
import "/softs/MobiDL/modules/sambambaFlagStat.wdl" as runSambambaFlagStat
import "/softs/MobiDL/modules/gatkCollectMultipleMetrics.wdl" as runGatkCollectMultipleMetrics
import "/softs/MobiDL/modules/gatkCollectInsertSizeMetrics.wdl" as runGatkCollectInsertSizeMetrics
import "/softs/MobiDL/modules/gatkBedToPicardIntervalList.wdl" as runGatkBedToPicardIntervalList
import "/softs/MobiDL/modules/computePoorCoverage.wdl" as runComputePoorCoverage
import "/softs/MobiDL/modules/samtoolsBedCov.wdl" as runSamtoolsBedCov
import "/softs/MobiDL/modules/computeCoverage.wdl" as runComputeCoverage
import "/softs/MobiDL/modules/computeCoverageClamms.wdl" as runComputeCoverageClamms
import "/softs/MobiDL/modules/gatkCollectHsMetrics.wdl" as runGatkCollectHsMetrics
import "/softs/MobiDL/modules/gatkHaplotypeCaller.wdl" as runGatkHaplotypeCaller
import "/softs/MobiDL/modules/gatkGatherVcfs.wdl" as runGatkGatherVcfs
import "/softs/MobiDL/modules/qualimapBamQc.wdl" as runQualimapBamQc
import "/softs/MobiDL/modules/jvarkitVcfPolyX.wdl" as runJvarkitVcfPolyX
import "/softs/MobiDL/modules/gatkSplitVcfs.wdl" as runGatkSplitVcfs
import "/softs/MobiDL/modules/gatkVariantFiltrationSnp.wdl" as runGatkVariantFiltrationSnp
import "/softs/MobiDL/modules/gatkVariantFiltrationIndel.wdl" as runGatkVariantFiltrationIndel
import "/softs/MobiDL/modules/gatkMergeVcfs.wdl" as runGatkMergeVcfs
import "/softs/MobiDL/modules/gatkSortVcf.wdl" as runGatkSortVcf
import "/softs/MobiDL/modules/bcftoolsNorm.wdl" as runBcftoolsNorm
import "/softs/MobiDL/modules/compressIndexVcf.wdl" as runCompressIndexVcf
import "/softs/MobiDL/modules/cleanUpPanelCaptureTmpDirs.wdl" as runCleanUpPanelCaptureTmpDirs
import "/softs/MobiDL/modules/multiqc.wdl" as runMultiqc
import "/softs/MobiDL/modules/deepVariant.wdl" as runDeepVariant
import "/softs/MobiDL/modules/refcallFiltration.wdl" as runRefCallFiltration
import "/softs/MobiDL/modules/gatkHardFilteringVcf.wdl" as runGatkHardFilteringVcf
import "/softs/MobiDL/modules/rtgMergeVcfs.wdl" as runRtgMerge
import "/softs/MobiDL/modules/fixVcfHeaders.wdl" as runFixVcfHeaders 
import "/softs/MobiDL/modules/crumble.wdl" as runCrumble 
workflow panelCapture {
	meta {
		author: "David Baux, Djenaba Barry"
		email: "david.baux(at)inserm.fr"
	}
	#variables declarations
	##Resources
	Int cpuHigh
	Int cpuLow
	Int memoryLow
	Int memoryHigh
	#memoryLow = scattered tasks =~ mem_per_cpu in HPC or not
	#memoryHigh = one cpu tasks => high mem ex 10Gb
	##Global
	String sampleID
	String suffix1
	String suffix2
	File fastqR1
	File fastqR2
	String genomeVersion
	File refFasta
	File refFai
	File intervalBedFile
	String workflowType
	String outDir
	##Bioinfo execs
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
	##Standard execs
	String awkExe
	String sedExe
	String sortExe
	String gatkExe
	String javaExe
	##bwaSamtools	
	String platform
	File refAmb
	File refAnn
	File refBwt
	File refPac
	File refSa
	##sambambaIndex
	#String suffixIndex
	#String suffixIndex2
	##gatk splitintervals
	String subdivisionMode
	##gatk Base recal
	File knownSites1
	File knownSites1Index
	File knownSites2
	File knownSites2Index
	File knownSites3
	File knownSites3Index
	##cram conversion
	File refFastaGz
	File refFaiGz
	File refFaiGzi
	##gatherVcfs
	String vcfHcSuffix = ".raw"
	String vcfSISuffix = ".merged"
	##gatk-picard
	File refDict
	##computePoorCoverage
	Int bedtoolsLowCoverage
	Int bedToolsSmallInterval
	##computeCoverage
	Int minCovBamQual
	##haplotypeCaller
	String swMode
	##jvarkit
	String vcfPolyXJar
	##ConvertCramtoCrumble
	String crumbleExe
	String ldLibraryPath
	##DeepVariant
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
	##RefCallFiltration
	String vcftoolsExe
	##VcSuffix
	String dvSuffix = ".dv"
	String hcSuffix = ".hc"
	String finalSuffix = ".final"
	##RtgMerge
	String rtgExe
	
	
	#Tasks calls
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
		DeepExe = deepExe,
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
	call runCompressIndexVcf.compressIndexVcf as compressIndexVcfDv{
		input:
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		BgZipExe = bgZipExe,
		TabixExe = tabixExe,
		VcSuffix = dvSuffix,
		NormVcf = bcftoolsNormDv.normVcf
	}                       
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
			SwMode = swMode
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
		VcfSuffix = vcfHcSuffix
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
		GatkExe = gatkExe,
		Vcf=jvarkitVcfPolyxHc.polyxedVcf,
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
		VcfSuffix = vcfSISuffix
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
		NormVcf = bcftoolsNormHc.normVcf
	}
	call runRtgMerge.rtgMerge{
		input:
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		VcfSuffix = vcfSISuffix,
		RtgExe = rtgExe,
		VcfFiles= [compressIndexVcfHc.bgZippedVcf, compressIndexVcfDv.bgZippedVcf],
		VcfFilesIndex = [compressIndexVcfHc.bgZippedVcfIndex, compressIndexVcfDv.bgZippedVcfIndex]
	}
	call runGatkSortVcf.gatkSortVcf as gatkSortVcfEnd {
		input: 
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		GatkExe = gatkExe,	
		VcSuffix = finalSuffix,
		UnsortedVcf  = rtgMerge.rtgMergedVcf
	}       
	call runFixVcfHeaders.fixVcfHeaders {
		input:
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		SedExe = sedExe,
		VcfFile = gatkSortVcfEnd.sortedVcf,
		VcfIndex = gatkSortVcfEnd.sortedVcfIndex
	}
	call runCompressIndexVcf.compressIndexVcf as finalCompressIndex {
		input:
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		BgZipExe = bgZipExe,
		TabixExe = tabixExe,
		VcSuffix = "",
		NormVcf = fixVcfHeaders.finalVcf
	}
	String dataPath = "${outDir}${sampleID}/${workflowType}/"
	call runCleanUpPanelCaptureTmpDirs.cleanUpPanelCaptureTmpDirs {
		input:
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		FinalFile1 = fixVcfHeaders.finalVcf,
		FinalFile2 = crumbleIndexing.cramIndex,
		BamArray = ["${dataPath}" + basename(sambambaMarkDup.markedBam), "${dataPath}" + basename(sambambaMarkDup.markedBamIndex), "${dataPath}" + basename(gatkGatherBQSRReports.gatheredRecalTable), "${dataPath}" + basename(gatkGatherBamFiles.gatheredBam), "${dataPath}" + basename(samtoolsSort.sortedBam), "${dataPath}" + basename(finalIndexing.bamIndex), "${dataPath}" + basename(samtoolsCramConvert.cram),"${dataPath}" + basename(samtoolsCramIndex.cramIndex)],
		 VcfArray = ["${dataPath}" + basename(refCallFiltration.noRefCalledVcf),"${dataPath}" + basename(gatkSortVcfDv.sortedVcf),"${dataPath}" + basename(gatkSortVcfDv.sortedVcfIndex),"${dataPath}" + basename(jvarkitVcfPolyxDv.polyxedVcf),"${dataPath}" + basename(jvarkitVcfPolyxDv.polyxedVcfIndex),"${dataPath}" + basename(gatkHardFiltering.HardFilteredVcf),"${dataPath}" + basename(gatkHardFiltering.HardFilteredVcfIndex),"${dataPath}" + basename(bcftoolsNormDv.normVcf),"${dataPath}" + basename(compressIndexVcfDv.bgZippedVcf),"${dataPath}" + basename(compressIndexVcfDv.bgZippedVcfIndex),"${dataPath}" + basename(gatkGatherVcfs.gatheredHcVcf), "${dataPath}" + basename(gatkGatherVcfs.gatheredHcVcfIndex), "${dataPath}" + basename(jvarkitVcfPolyxHc.polyxedVcf), "${dataPath}" + basename(jvarkitVcfPolyxHc.polyxedVcfIndex), "${dataPath}" + basename(gatkSplitVcfs.snpVcf), "${dataPath}" + basename(gatkSplitVcfs.snpVcfIndex), "${dataPath}" + basename(gatkSplitVcfs.indelVcf), "${dataPath}" + basename(gatkSplitVcfs.indelVcfIndex), "${dataPath}" + basename(gatkVariantFiltrationSnp.filteredSnpVcf), "${dataPath}" + basename(gatkVariantFiltrationSnp.filteredSnpVcfIndex), "${dataPath}" + basename(gatkVariantFiltrationIndel.filteredIndelVcf), "${dataPath}" + basename(gatkVariantFiltrationIndel.filteredIndelVcfIndex), "${dataPath}" + basename(gatkMergeVcfs.mergedVcf), "${dataPath}" + basename(gatkMergeVcfs.mergedVcfIndex), "${dataPath}" + basename(gatkSortVcfHc.sortedVcf), "${dataPath}" + basename(gatkSortVcfHc.sortedVcfIndex), "${dataPath}" + basename(bcftoolsNormHc.normVcf),"${dataPath}" + basename(compressIndexVcfHc.bgZippedVcf),"${dataPath}" + basename(compressIndexVcfHc.bgZippedVcfIndex),"${dataPath}" + basename(rtgMerge.rtgMergedVcf),"${dataPath}" + basename(rtgMerge.rtgMergedVcfIndex), "${dataPath}" + basename(gatkSortVcfEnd.sortedVcf)]
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
	output {
		File FinalVcf = cleanUpPanelCaptureTmpDirs.finalFile1
		File FinalCram = crumble.crumbled
		File FinalCramIndex = crumbleIndexing.cramIndex 
	}
}
