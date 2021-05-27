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
import "modules/crumble.wdl" as runCrumble
import "modules/samtoolsCramIndex.wdl" as runSamtoolsCramIndex
import "modules/sambambaFlagStat.wdl" as runSambambaFlagStat
import "modules/gatkCollectMultipleMetrics.wdl" as runGatkCollectMultipleMetrics
import "modules/gatkCollectInsertSizeMetrics.wdl" as runGatkCollectInsertSizeMetrics
import "modules/computePoorCoverage.wdl" as runComputePoorCoverage
import "modules/samtoolsBedCov.wdl" as runSamtoolsBedCov
import "modules/computeCoverage.wdl" as runComputeCoverage
import "modules/computeCoverageClamms.wdl" as runComputeCoverageClamms
import "modules/gatkCollectHsMetrics.wdl" as runGatkCollectHsMetrics

workflow alignDNA {
  meta {
    author: "Olivier Ardouin"
    email: "o-ardouin(at)chu-montpellier.fr"
    version: "0.0.1"
    date: "2021-05-27"
  }
  ## Resources
  Int CpuHigh
  Int CpuLow
  Int memoryLow
  Int memoryHigh
  ## Global
  String sampleID
  String CIsDIR = ''
  String CIsampleDIR = if CIsDIR == "" then sampleID else CIsDIR
  File fastqR1
  File fastqR2
  File refFasta
  File refFai
  File refDict
  File intervalBedFile
  String workflowType
  String outDir
  Boolean DirsPrepared
  ## Bioinfo execs
  String bwaExe
  String samtoolsExe
  String sambambaExe
  ## Standard execs
  String awkExe
  String gatkExe
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
  ## ConvertCramtoCrumble
	String crumbleExe
	String ldLibraryPath
  ## computeCoverage
	Int minCovBamQual
  ## HSmetrix
  File BaitIntervals
  File TargetIntervals
  ###############
  # run bwa mem #
  ###############
  call runBwaSamtools.bwaSamtools {
    input:
    Cpu = CpuHigh,
    Memory = memoryLow,
    SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
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
  ##################
  # Mark Duplicate #
  ##################
  call runSambambaMarkDup.sambambaMarkDup {
    input:
    Cpu = CpuHigh,
    Memory = memoryLow,
    SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
    OutDir = outDir,
    WorkflowType = workflowType,
    SambambaExe = sambambaExe,
    BamFile = bwaSamtools.sortedBam
  }
  call runBedToGatkIntervalList.bedToGatkIntervalList {
    input:
    Cpu = CpuLow,
    Memory = memoryHigh,
    SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
    OutDir = outDir,
    WorkflowType = workflowType,
    IntervalBedFile = intervalBedFile,
    AwkExe = awkExe,
    DirsPrepared = DirsPrepared
  }
  call runGatkSplitIntervals.gatkSplitIntervals {
    input:
    Cpu = CpuLow,
    Memory = memoryHigh,
    SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
    OutDir = outDir,
    WorkflowType = workflowType,
    GatkExe = gatkExe,
    RefFasta = refFasta,
    RefFai = refFai,
    RefDict = refDict,
    GatkInterval = bedToGatkIntervalList.gatkIntervals,
    SubdivisionMode = subdivisionMode,
    ScatterCount = CpuHigh
  }
  scatter (interval in gatkSplitIntervals.splittedIntervals) {
    call runGatkBaseRecalibrator.gatkBaseRecalibrator {
      input:
      Cpu = CpuLow,
      Memory = memoryLow,
      SampleID = sampleID,
      OutDirSampleID = CIsampleDIR,
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
    Cpu = CpuLow,
    Memory = memoryHigh,
    SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
    OutDir = outDir,
    WorkflowType = workflowType,
    GatkExe = gatkExe,
    RecalTables = recalTables
  }
  scatter (interval in gatkSplitIntervals.splittedIntervals) {
    call runGatkApplyBQSR.gatkApplyBQSR {
      input:
      Cpu = CpuLow,
      Memory = memoryLow,
      SampleID = sampleID,
      OutDirSampleID = CIsampleDIR,
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
      Cpu = CpuLow,
      Memory = memoryLow,
      SampleID = sampleID,
      OutDirSampleID = CIsampleDIR,
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
    Cpu = CpuLow,
    Memory = memoryHigh,
    SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
    OutDir = outDir,
    WorkflowType = workflowType,
    GatkExe = gatkExe,
    LAlignedBams = lAlignedBams
  }
  call runSamtoolsSort.samtoolsSort {
    input:
    Cpu = CpuHigh,
    Memory = memoryLow,
    SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
    OutDir = outDir,
    WorkflowType = workflowType,
    SamtoolsExe = samtoolsExe,
    BamFile = gatkGatherBamFiles.gatheredBam
  }
  call runSambambaIndex.sambambaIndex as finalIndexing {
    input:
    Cpu = CpuHigh,
    Memory = memoryLow,
    SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
    OutDir = outDir,
    WorkflowType = workflowType,
    SambambaExe = sambambaExe,
    BamFile = samtoolsSort.sortedBam
  }
  call runSamtoolsCramConvert.samtoolsCramConvert {
		input:
		Cpu = CpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
    OutDirSampleID = CIsampleDIR,
		WorkflowType = workflowType,
		SamtoolsExe = samtoolsExe,
		BamFile = samtoolsSort.sortedBam,
		RefFastaGz = refFastaGz,
		RefFaiGz = refFaiGz,
		RefFaiGzi = refFaiGzi
	}
  call runSamtoolsCramIndex.samtoolsCramIndex {
		input:
		Cpu = CpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
    OutDirSampleID = CIsampleDIR,
		WorkflowType = workflowType,
		SamtoolsExe = samtoolsExe,
		CramFile = samtoolsCramConvert.cram,
		CramSuffix = ""
	}
  call runCrumble.crumble {
		input:
		Cpu = CpuHigh,
		Memory = memoryLow,
		SampleID = sampleID,
		OutDir = outDir,
    OutDirSampleID = CIsampleDIR,
		WorkflowType = workflowType,
		CrumbleExe = crumbleExe,
		LdLibraryPath = ldLibraryPath,
		InputFile = samtoolsCramConvert.cram,
		InputFileIndex =  samtoolsCramIndex.cramIndex,
		FileType = "cram"
	}
  call runSamtoolsCramIndex.samtoolsCramIndex as crumbleIndexing {
		input:
		Cpu = CpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
		OutDir = outDir,
		WorkflowType = workflowType,
		SamtoolsExe = samtoolsExe,
		CramFile = crumble.crumbled,
		CramSuffix = ".crumble"
	}
  call runSambambaFlagStat.sambambaFlagStat {
		input:
		Cpu = CpuHigh,
		Memory = memoryLow,
		SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
		OutDir = outDir,
		WorkflowType = workflowType,
		SambambaExe = sambambaExe,
		BamFile = samtoolsSort.sortedBam
	}
  call runGatkCollectMultipleMetrics.gatkCollectMultipleMetrics {
		input:
		Cpu = CpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
		OutDir = outDir,
		WorkflowType = workflowType,
		GatkExe = gatkExe,
		RefFasta = refFasta,
		BamFile = samtoolsSort.sortedBam
	}
  call runGatkCollectInsertSizeMetrics.gatkCollectInsertSizeMetrics {
		input:
		Cpu = CpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
		OutDir = outDir,
		WorkflowType = workflowType,
		GatkExe = gatkExe,
		RefFasta = refFasta,
		BamFile = samtoolsSort.sortedBam
	}
  call runComputePoorCoverage.computePoorCoverage {
		input:
		Cpu = CpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
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
		Cpu = CpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
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
		Cpu = CpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
		OutDir = outDir,
		WorkflowType = workflowType,
		AwkExe = awkExe,
		SortExe = sortExe,
		BedCovFile = samtoolsBedCov.BedCovFile
	}
  call runComputeCoverageClamms.computeCoverageClamms {
		input:
		Cpu = CpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
		OutDir = outDir,
		WorkflowType = workflowType,
		AwkExe = awkExe,
		SortExe = sortExe,
		BedCovFile = samtoolsBedCov.BedCovFile
	}
  call runGatkCollectHsMetrics.gatkCollectHsMetrics {
		input:
		Cpu = CpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
    OutDirSampleID = CIsampleDIR,
		OutDir = outDir,
		WorkflowType = workflowType,
		GatkExe = gatkExe,
		RefFasta = refFasta,
		RefFai = refFai,
		BamFile = samtoolsSort.sortedBam,
		BaitIntervals = BaitIntervals,
		TargetIntervals = BaitIntervals
	}
  output {
		File bam = samtoolsSort.sortedBam
		File idx = finalIndexing.bamIndex
    File Crumble = crumble.crumbled
    File CrumbleIndex = crumbleIndexing.cramIndex
	}
}
