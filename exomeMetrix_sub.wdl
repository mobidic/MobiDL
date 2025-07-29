version 1.0


import "modules/computePoorCoverage.wdl" as runComputePoorCoverage
import "modules/samtoolsBedCov.wdl" as runSamtoolsBedCov
import "modules/computeCoverage.wdl" as runComputeCoverage
import "modules/computeCoverageClamms.wdl" as runComputeCoverageClamms

workflow exomeMetrix {
    meta {
        author: "Felix VANDERMEEREN"
        email: "felix.vandermeeren(at)chu-montpellier.fr"
        version: "0.1.0"
        date: "2025-05-26"
    }

    input {
        # Tasks specific
        File sortedBam
        File sortedBamIdx
        File intervalBedFile
        ## Params
        Int minCovBamQual
        Int bedtoolsLowCoverage
        Int bedToolsSmallInterval
        String? poorCoverageFileFolder
        ## Standard execs
        String awkExe = "awk"
        String sedExe = "sed"
        String sortExe = "sort"
        ## Standard execs
        String bedToolsExe = "bedtools"
        String samtoolsExe = "samtools"
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
        String sampleID
        String outDir
        String genomeVersion
        String workflowType
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
            WorkflowType = workflowType,
            GenomeVersion = genomeVersion,
            BedToolsExe = bedToolsExe,
            AwkExe = awkExe,
            SortExe = sortExe,
            BedToolsSmallInterval = bedToolsSmallInterval,
            GenomecovFile = computeGenomecov.genomecovFile
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
            BamFile = sortedBam,
            BamIndex = sortedBamIdx,
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

    if (defined(poorCoverageFileFolder)) {
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
    }

    output {
        File outCoverage = computeCoverage.TsvCoverageFile
        File outBedCov = samtoolsBedCov.BedCovFile
        File outBedCovClamms = computeCoverageClamms.ClammsCoverageFile
        File outPoorCoverage = computePoorCoverage.poorCoverageFile
        File? outPoorCovExtended = computePoorCovExtended.poorCoverageFile
    }
}
