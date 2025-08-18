version 1.0


import "modules/somalier.wdl" as runSomalier
import "modules/samtoolsBedCov.wdl" as runSamtoolsBedCov
import "modules/computePoorCoverage.wdl" as runComputePoorCoverage
import "modules/computeCoverage.wdl" as runComputeCoverage
import "modules/computeCoverageClamms.wdl" as runComputeCoverageClamms

workflow exomeMetrix {
    meta {
        author: "Felix VANDERMEEREN"
        email: "felix.vandermeeren(at)chu-montpellier.fr"
        version: "0.1.3"
        date: "2025-05-26"
    }

    input {
        # Tasks specific
        File sortedBam
        File? sortedBamIdx
        String bamExt
        File intervalBedFile
        File fastaGenome
        File somalierSites  = "/mnt/chu-ngs/refData/igenomes/Homo_sapiens/GATK/GRCh37/Annotation/Somalier/sites.hg19.vcf.gz"
        ## Params
        Int minCovBamQual
        Int bedtoolsLowCoverage
        Int bedToolsSmallInterval
        String poorCoverageFileFolder
        ## Standard execs
        String awkExe = "awk"
        String sedExe = "sed"
        String sortExe = "sort"
        ## Standard execs
        String bedToolsExe = "bedtools"
        String samtoolsExe = "samtools"
        String somalierExe
        ## envs
        String condaBin
        String bedtoolsEnv = "/bioinfo/conda_envs/bedtoolsEnv"
        String samtoolsEnv = "/bioinfo/conda_envs/samtoolsEnv"
        ## queues
        String defQueue = "prod"
        ##Resources
        Int cpuHigh
        Int cpuLow
        # Int avxCpu
        Int memoryLow
        Int memoryHigh
        ## Global
        String outDir
        String genomeVersion
        String workflowType
    }
    String sampleID = basename (sortedBam, bamExt)

    # 'somalier and 'samtools bedcov' requires indexed BAM
    call indexBAM {
        input:
            Queue = defQueue,
            CondaBin = condaBin,
            SamtoolsEnv = samtoolsEnv,
            Cpu = cpuLow,
            Memory = memoryLow,
            SampleID = sampleID,
            OutDir = outDir,
            WorkflowType = workflowType,
            SamtoolsExe = samtoolsExe,
            BamFile = sortedBam,
            BamExt = bamExt
    }

    # Somalier extract
    call runSomalier.extract as somalierExtract {
        input :
            refFasta = fastaGenome,
            sites = somalierSites,
            bamFile = sortedBam,
            BamIndex = indexBAM.bamIdx,
            outputPath = outDir + "/coverage/",
            path_exe = somalierExe,
            Queue = defQueue,
            Cpu = cpuLow,
            Memory = memoryLow
    }

    # 'samtools bedCov' and derived files
    call runSamtoolsBedCov.samtoolsBedCov {
        input:
            Queue = defQueue,
            CondaBin = condaBin,
            SamtoolsEnv = samtoolsEnv,
            Cpu = cpuLow,
            Memory = memoryHigh,
            SampleID = sampleID,
            OutDir = outDir,
            OutDirSampleID = "/",
            WorkflowType = workflowType,
            SamtoolsExe = samtoolsExe,
            IntervalBedFile = intervalBedFile,
            BamFile = sortedBam,
            BamIndex = indexBAM.bamIdx,
            MinCovBamQual = minCovBamQual
    }

    call runComputeCoverage.computeCoverage {
        input:
            Queue = defQueue,
            Cpu = cpuLow,
            Memory = memoryHigh,
            SampleID = sampleID,
            OutDir = outDir,
            OutDirSampleID = "/",
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
            OutDirSampleID = "/",
            WorkflowType = workflowType,
            AwkExe = awkExe,
            SortExe = sortExe,
            BedCovFile = samtoolsBedCov.BedCovFile
    }


    # TODO: Run genomeCov with 'samtools view --min-MQ 30'
    call runComputePoorCoverage.computeGenomecov {
        input:
            Queue = defQueue,
            CondaBin = condaBin,
            BedtoolsEnv = bedtoolsEnv,
            Cpu = cpuLow,
            Memory = memoryHigh,
            SampleID = sampleID,
            OutDir = outDir,
            OutDirSampleID = "/",
            WorkflowType = workflowType,
            GenomeVersion = genomeVersion,
            BedToolsExe = bedToolsExe,
            AwkExe = awkExe,
            SortExe = sortExe,
            IntervalBedFile = intervalBedFile,
            BedtoolsLowCoverage = bedtoolsLowCoverage,
            BamFile = sortedBam
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
            OutDirSampleID = "/",
            WorkflowType = workflowType,
            GenomeVersion = genomeVersion,
            BedToolsExe = bedToolsExe,
            AwkExe = awkExe,
            SortExe = sortExe,
            BedToolsSmallInterval = bedToolsSmallInterval,
            GenomecovFile = computeGenomecov.genomecovFile
    }

    call runComputePoorCoverage.computePoorCovExtended {
        input:
            Queue = defQueue,
            CondaBin = condaBin,
            BedtoolsEnv = bedtoolsEnv,
            Cpu = cpuLow,
            Memory = memoryHigh,
            Queue = defQueue,
            SampleID = sampleID,
            OutDir = outDir,
            OutDirSampleID = "/",
            WorkflowType = workflowType,
            GenomeVersion = genomeVersion,
            BedToolsExe = bedToolsExe,
            AwkExe = awkExe,
            SortExe = sortExe,
            BedToolsSmallInterval = bedToolsSmallInterval,
            GenomecovFile = computeGenomecov.genomecovFile,
            PoorCoverageFileFolder = poorCoverageFileFolder,
            CoverageFile = computeCoverage.TsvCoverageFile
    }

    output {
        File somalierExtracted = somalierExtract.file
        File outCoverage = computeCoverage.TsvCoverageFile
        File outBedCov = samtoolsBedCov.BedCovFile
        File outBedCovClamms = computeCoverageClamms.ClammsCoverageFile
        File outPoorCoverage = computePoorCoverage.poorCoverageFile
        File? outPoorCovExtended = computePoorCovExtended.poorCoverageFile
    }
}


# Re-wrote this cuz existing modules does not handle both BAM and CRAM ?
task indexBAM {
    input {
        # Env variables
        String CondaBin
        String SamtoolsExe
        String SamtoolsEnv
        # task specific variables
        File BamFile
        String BamExt
        # global variables
        String SampleID
        String OutDir
        String WorkflowType
        # runtime attributes
        String Queue
        Int Cpu
        Int Memory
    }
    String extIndx = if (BamExt == ".bam") then ".bai" else ".crai"
    String outBamIdx = BamFile + extIndx
    command <<<
        set -e
        source ~{CondaBin}activate ~{SamtoolsEnv}
        ~{SamtoolsExe} index -o ~{outBamIdx} ~{BamFile}
        conda deactivate
    >>>

    output {
        File bamIdx = outBamIdx
    }

    runtime {
        queue: "~{Queue}"
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}
