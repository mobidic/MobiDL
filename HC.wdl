import "modules/preparePanelCaptureTmpDirs.wdl" as runPreparePanelCaptureTmpDirs
import "modules/bedToGatkIntervalList.wdl" as runBedToGatkIntervalList
import "modules/gatkSplitIntervals.wdl" as runGatkSplitIntervals
import "modules/gatkHaplotypeCaller.wdl" as runGatkHaplotypeCaller
import "modules/gatkGatherVcfs.wdl" as runGatkGatherVcfs

#WDL to run HC alone on a given BAM

workflow HC {
	meta {
		author: "David Baux"
		email: "david.baux(at)inserm.fr"
	}
	#variables declarations
	##Resources
	Int cpuHigh
	Int cpuLow
	Int memoryLow
	Int memoryHigh
	##Global
	String sampleID
	String workflowType
	String outDir
	File refFasta
	File refFai
	File intervalBedFile
	##Standard execs
	String awkExe
	String gatkExe
	##gatk-picard
	File refDict
	File knownSites3
	File knownSites3Index
	##gatk splitintervals
	String subdivisionMode
	##haplotypeCaller
	String swMode
  File bam
  File bamIndex
  #Tasks calls
	call runPreparePanelCaptureTmpDirs.preparePanelCaptureTmpDirs {
		input:
		Cpu = cpuLow,
		Memory = memoryHigh,
		SampleID = sampleID,
		OutDir = outDir,
		WorkflowType = workflowType
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
			BamFile = bam,
			BamIndex = bamIndex,
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
		HcVcfs = hcVcfs
  }
  output {
		File Vcf = gatkGatherVcfs.gatheredHcVcf
	}
}
