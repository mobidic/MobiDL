import "modules/preparePanelCaptureTmpDirs.wdl" as runPreparePanelCaptureTmpDirs
import "modules/fastqcTrio.wdl" as runFastqcTrio
import "modules/gatkBedToPicardIntervalList.wdl" as runGatkBedToPicardIntervalList
import "modules/gatkHaplotypeCallerTrio.wdl" as runGatkHaplotypeCallerTrio
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
#import "modules/deepVariant.wdl" as runDeepVariant
import "modules/refcallFiltration.wdl" as runRefCallFiltration
import "modules/gatkHardFilteringVcf.wdl" as runGatkHardFilteringVcf
import "modules/bcftoolsStats.wdl" as runBcftoolsStats
# import "modules/gatkVariantEval.wdl" as runGatkVariantEval
# import "modules/gatkCombineVariants.wdl" as runGatkCombineVariants
# import "modules/rtgMergeVcfs.wdl" as runRtgMerge
# import "modules/fixVcfHeaders.wdl" as runFixVcfHeaders
#import "modules/crumble.wdl" as runCrumble
#import "modules/anacoreUtilsMergeVCFCallers.wdl" as runAnacoreUtilsMergeVCFCallers
import "modules/gatkUpdateVCFSequenceDictionary.wdl" as runGatkUpdateVCFSequenceDictionary
import "modules/cleanUpPanelCaptureTrioTmpDirs.wdl" as runCleanUpPanelCaptureTrioTmpDirs
import "modules/multiqc.wdl" as runMultiqc
import "modules/toolVersions.wdl" as runToolVersions
import "modules/alignement.wdl" as alignDNA
workflow panelCaptureTrio {
	meta {
		author: "Olivier Ardouin"
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2021-05-26"
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
	String FatherSampleID
	String MotherSampleID
	String suffix1
	String suffix2
	File fastqR1
	File FatherFastqR1
	File MotherFastqR1
	File fastqR2
	File FatherFastqR2
	File MotherFastqR2
	String genomeVersion
	File refFasta
	File refFai
	File refDict
	File intervalBedFile
	### Amélioration a venir : add BaitIntervals
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
	String gatkExe
	## Standard execs
	String awkExe
	String sedExe
	String sortExe
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
	# RunFastqc on all FASTQs
	call runFastqcTrio.fastqc {
		input:
		Cpu = cpuHigh,
		Memory = memoryLow,
		SampleID = sampleID,
		FatherSampleID = FatherSampleID,
		MotherSampleID = MotherSampleID,
		OutDir = outDir,
		WorkflowType = workflowType,
		FastqcExe = fastqcExe,
		FastqR1 = fastqR1,
		FatherFastqR1 = FatherFastqR1,
		MotherFastqR1 = MotherFastqR1,
		FastqR2 = fastqR2,
		FatherFastqR2 = FatherFastqR2,
		MotherFastqR2 = MotherFastqR2,
		Suffix1 = suffix1,
		Suffix2 = suffix2,
		DirsPrepared = preparePanelCaptureTmpDirs.dirsPrepared
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

	#Call alignement SubWorkflow
	call alignDNA.alignDNA as alignCI {
		input:
		## Resources
  	CpuHigh = cpuHigh,
  	CpuLow = cpuLow,
  	memoryLow = memoryLow,
  	memoryHigh = memoryHigh,
    ## Global
    sampleID = sampleID,
    CIsDIR = sampleID,
  	fastqR1 = fastqR1,
  	fastqR2 = fastqR2,
		refFasta = refFasta,
  	refFai = refFai,
  	refDict = refDict,
  	intervalBedFile = intervalBedFile,
  	workflowType = workflowType,
  	outDir = outDir,
    ## Bioinfo execs,
  	bwaExe = bwaExe,
  	samtoolsExe = samtoolsExe,
  	sambambaExe = sambambaExe,
    ## Standard execs
  	awkExe = awkExe,
  	gatkExe = gatkExe,
  	## bwaSamtools
  	platform = platform,
  	refAmb = refAmb,
  	refAnn = refAnn,
  	refBwt = refBwt,
  	refPac = refPac,
  	refSa = refSa,
		# CRAM conversion
		refFastaGz = refFastaGz,
		refFaiGz = refFaiGz,
		refFaiGzi = refFaiGzi,
		#Comvert Cram to CrumbleExe
		crumbleExe = crumbleExe,
		ldLibraryPath = ldLibraryPath,
  	## sambambaIndex
  	## gatk splitintervals
  	subdivisionMode = subdivisionMode,
  	## gatk Base recal
  	knownSites1 = knownSites1,
  	knownSites1Index = knownSites1Index,
  	knownSites2 = knownSites2,
  	knownSites2Index = knownSites2Index,
  	knownSites3 = knownSites3,
  	knownSites3Index = knownSites3Index,
		DirsPrepared = preparePanelCaptureTmpDirs.dirsPrepared,
		## compute LowCoverage
		minCovBamQual = minCovBamQual,
		## Picard HSmetrix
		BaitIntervals = gatkBedToPicardIntervalList.picardIntervals,
		TargetIntervals = gatkBedToPicardIntervalList.picardIntervals
	}

	call alignDNA.alignDNA as alignFather {
		input:
		## Resources
  	CpuHigh = cpuHigh,
  	CpuLow = cpuLow,
  	memoryLow = memoryLow,
  	memoryHigh = memoryHigh,
    ## Global
    sampleID = FatherSampleID,
    CIsDIR = sampleID,
  	fastqR1 = FatherFastqR1,
  	fastqR2 = FatherFastqR2,
		refFasta = refFasta,
  	refFai = refFai,
  	refDict = refDict,
  	intervalBedFile = intervalBedFile,
  	workflowType = workflowType,
  	outDir = outDir,
    ## Bioinfo execs,
  	bwaExe = bwaExe,
  	samtoolsExe = samtoolsExe,
  	sambambaExe = sambambaExe,
    ## Standard execs
  	awkExe = awkExe,
  	gatkExe = gatkExe,
  	## bwaSamtools
  	platform = platform,
  	refAmb = refAmb,
  	refAnn = refAnn,
  	refBwt = refBwt,
  	refPac = refPac,
  	refSa = refSa,
  	## sambambaIndex
		# CRAM conversion
		refFastaGz = refFastaGz,
		refFaiGz = refFaiGz,
		refFaiGzi = refFaiGzi,
		#Comvert Cram to CrumbleExe
		crumbleExe = crumbleExe,
		ldLibraryPath = ldLibraryPath,
  	## gatk splitintervals
  	subdivisionMode = subdivisionMode,
  	## gatk Base recal
  	knownSites1 = knownSites1,
  	knownSites1Index = knownSites1Index,
  	knownSites2 = knownSites2,
  	knownSites2Index = knownSites2Index,
  	knownSites3 = knownSites3,
  	knownSites3Index = knownSites3Index,
		DirsPrepared = preparePanelCaptureTmpDirs.dirsPrepared,
		## compute LowCoverage
		minCovBamQual = minCovBamQual,
		## Picard HSmetrix
		BaitIntervals = gatkBedToPicardIntervalList.picardIntervals,
		TargetIntervals = gatkBedToPicardIntervalList.picardIntervals
	}

	call alignDNA.alignDNA as alignMother {
		input:
		## Resources
  	CpuHigh = cpuHigh,
  	CpuLow = cpuLow,
  	memoryLow = memoryLow,
  	memoryHigh = memoryHigh,
    ## Global
    sampleID = MotherSampleID,
    CIsDIR = sampleID,
  	fastqR1 = MotherFastqR1,
  	fastqR2 = MotherFastqR2,
		refFasta = refFasta,
  	refFai = refFai,
  	refDict = refDict,
  	intervalBedFile = intervalBedFile,
  	workflowType = workflowType,
  	outDir = outDir,
    ## Bioinfo execs,
  	bwaExe = bwaExe,
  	samtoolsExe = samtoolsExe,
  	sambambaExe = sambambaExe,
    ## Standard execs
  	awkExe = awkExe,
  	gatkExe = gatkExe,
  	## bwaSamtools
  	platform = platform,
  	refAmb = refAmb,
  	refAnn = refAnn,
  	refBwt = refBwt,
  	refPac = refPac,
  	refSa = refSa,
  	## sambambaIndex
		# CRAM conversion
		refFastaGz = refFastaGz,
		refFaiGz = refFaiGz,
		refFaiGzi = refFaiGzi,
		#Comvert Cram to CrumbleExe
		crumbleExe = crumbleExe,
		ldLibraryPath = ldLibraryPath,
  	## gatk splitintervals
  	subdivisionMode = subdivisionMode,
  	## gatk Base recal
  	knownSites1 = knownSites1,
  	knownSites1Index = knownSites1Index,
  	knownSites2 = knownSites2,
  	knownSites2Index = knownSites2Index,
  	knownSites3 = knownSites3,
  	knownSites3Index = knownSites3Index,
		DirsPrepared = preparePanelCaptureTmpDirs.dirsPrepared,
		## compute LowCoverage
		minCovBamQual = minCovBamQual,
		## Picard HSmetrix
		BaitIntervals = gatkBedToPicardIntervalList.picardIntervals,
		TargetIntervals = gatkBedToPicardIntervalList.picardIntervals
	}
####OK#####






##############################################HaplotypeCaller######################@
	scatter (interval in gatkSplitIntervals.splittedIntervals) {
		call runGatkHaplotypeCallerTrio.gatkHaplotypeCallerTrio {
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
			DbSNP = knownSites3,
			DbSNPIndex = knownSites3Index,
			GatkInterval = interval,
			BamFile = alignCI.sortedBam,
			BamIndex = alignCI.bamIndex,
			BamFileFather = alignFather.sortedBam,
			BamIndexFather = alignFather.bamIndex,
			BamFileMother = alignMother.sortedBam,
			BamIndexMother = alignMother.bamIndex,
			SwMode = swMode,
			EmitRefConfidence = emitRefConfidence
		}
	}
	output {
		Array[File] hcVcfs = gatkHaplotypeCallerTrio.hcVcf
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

	if (!debug) {
		String dataPath = "${outDir}${sampleID}/${workflowType}/"
		call runCleanUpPanelCaptureTrioTmpDirs.cleanUpPanelCaptureTrioTmpDirs {
			input:
			Cpu = cpuLow,
			Memory = memoryHigh,
			SampleID = sampleID,
			OutDir = outDir,
			WorkflowType = workflowType,
			FinalFile1 = compressIndexVcfHc.bgZippedVcf,
			FinalFile2 = alignCI.CrumbleIndex,
			FinalFile3 = alignFather.CrumbleIndex,
			FinalFile4 = alignMother.CrumbleIndex
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
		File? FinalVcf = cleanUpPanelCaptureTrioTmpDirs.finalFile1
		File FinalCram = alignCI.Crumble
		File FinalCramIndex = alignCI.CrumbleIndex
		File FinalCramFather = alignFather.Crumble
		File FinalCramIndexFather = alignFather.CrumbleIndex
		File FinalCramMother = alignMother.Crumble
		File FinalCramIndexMother = alignMother.CrumbleIndex
		File VersionFile = toolVersions.versionFile
	}
}
