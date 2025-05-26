version 1.0


import "modules/computePoorCoverage.wdl" as runComputePoorCoverage


workflow ExomeMetrix {
    meta {
        author: "Felix VANDERMEEREN"
        email: "felix.vandermeeren(at)chu-montpellier.fr"
        version: "0.0.1"
        date: "2025-05-26"
    }

    input {
        # Tasks specific
        ## PoorCovExtended task
		Int bedtoolsLowCoverage
		Int bedToolsSmallInterval
        String poorCoverageFileFolder = "/mnt/chu-ngs/refData/Annotations/PoorCoverageExtented/"
        ## SomalierExtract task
        String suffixBam = ".crumble.cram"
        String somalierExe = "/bioinfo/softs/bin/somalier"
        ## AchabMetrix task
        String csvtkExe = "/bioinfo/softs/bin/csvtk"
		## Standard execs
		String awkExe = "awk"
		String sedExe = "sed"
		String sortExe = "sort"
		## Standard execs
		String bedToolsExe = "bedtools"
        ## envs
        String condaBin
        String bedtoolsEnv = "/bioinfo/conda_envs/bedtoolsEnv"
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
        String analysisDir  # Eg. /path/to/runID/MobiDL
        String outDir
		String genomeVersion
        String workflowType
    }

    # For 'poorCov_extended' + 'somalier extract'
    call findFile as findBam {
        input:
            SampleID = sampleID,
            PrefixPath = analysisDir,
            WDL = "panelCapture",
            SuffixFile = ".crumble.cram"
    }
    call findFile as findGenomecov {
        input:
            SampleID = sampleID,
            PrefixPath = analysisDir,
            WDL = "/panelCapture/coverage",
            SuffixFile = "_genomecov.tsv"
    }
    call findFile as findCoverage {
        input:
            SampleID = sampleID,
            PrefixPath = analysisDir,
            WDL = "/panelCapture/coverage",
            SuffixFile = "_coverage.tsv"
    }

    # call findAchab {
    #     input:
    #         PedFile = preprocessPed.outputFile,
    #         CondaBin = condaBin,
    #         PedsEnv = pedsEnv,
    #         PathExe = scriptExe
    # }

    # call findVCF {
    #     input:
    #         PedFile = preprocessPed.outputFile,
    #         CondaBin = condaBin,
    #         PedsEnv = pedsEnv,
    #         PathExe = scriptExe
    # }
    # output {
    #     Array[File] mergedVCFs = mergeVCF.vcfOut
    # }

    call runComputePoorCoverage.computePoorCovExtended {
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
            GenomecovFile = findGenomecov.foundFile,
            PoorCoverageFileFolder = poorCoverageFileFolder,
            CoverageFile = findCoverage.foundFile
    }
}

task findFile {
    input {
        String SampleID
        String PrefixPath  # Eg: /path/to/runID/MobiDL/
        String WDL
        String SuffixFile

        Int Cpu = 1
        Int Memory = 768
    }

    command <<<
        set -e

        ls -d "~{PrefixPath}/~{SampleID}/~{WDL}/~{SampleID}~{SuffixFile}"
    >>>

    output {
        File foundFile = read_string(stdout())
    }

    runtime {
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}
