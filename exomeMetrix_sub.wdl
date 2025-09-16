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
        version: "0.3.0"
        date: "2025-05-26"
    }

    input {
        # Tasks specific
        String samplesList
        String analysisDir
        String wdlBAM = "preprocessing/markduplicates"
        String suffixBAM = ".md.cram"
        String bamExt = ".cram"
        File intervalBedFile
        File fastaGenome
        File somalierSites  = "/mnt/chu-ngs/refData/igenomes/Homo_sapiens/GATK/GRCh37/Annotation/Somalier/sites.GRCh37.vcf.gz"
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

    # First find all BAM
    call findFile as findBAM {
        input:
            Family = samplesList,
            PrefixPath = analysisDir,
            WDL = wdlBAM,
            SuffixFile = suffixBAM,
            Queue = defQueue,
            Cpu = cpuLow,
            Memory = memoryLow
    }

    # Then process them in parallel
    scatter (aBam in findBAM.filesList) {
        # WARN: Bellow 'bamExt' is rather a 'suffix' to remove ('.md.cram' in 'sample.md.cram')
        String sampleID = basename (aBam, bamExt)

        # 'somalier and 'samtools bedcov' requires indexed BAM
        call toIndexedBAM {
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
                FastaGenome = fastaGenome,
                BamFile = aBam
        }

        call filterBAM {
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
                MinCovBamQual = minCovBamQual,
                BamFile = aBam
        }

        # Somalier extract
        call runSomalier.extract as somalierExtract {
            input :
                refFasta = fastaGenome,
                sites = somalierSites,
                bamFile = toIndexedBAM.sortedBam,
                BamIndex = toIndexedBAM.bamIdx,
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
                BamFile = toIndexedBAM.sortedBam,
                BamIndex = toIndexedBAM.bamIdx,
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

        # call runComputeCoverageClamms.computeCoverageClamms {
        #     input:
        #         Queue = defQueue,
        #         Cpu = cpuLow,
        #         Memory = memoryHigh,
        #         SampleID = sampleID,
        #         OutDir = outDir,
        #         OutDirSampleID = "/",
        #         WorkflowType = workflowType,
        #         AwkExe = awkExe,
        #         SortExe = sortExe,
        #         BedCovFile = samtoolsBedCov.BedCovFile
        # }

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
                BamFile = filterBAM.sortedBam
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
    }

    output {
        Array[File] somalierExtracted = somalierExtract.file
        Array[File] outCoverage = computeCoverage.TsvCoverageFile
        Array[File] outBedCov = samtoolsBedCov.BedCovFile
        # Array[File outBedCovClamms = computeCoverageClamms.ClammsCoverageFile
        Array[File] outPoorCoverage = computePoorCoverage.poorCoverageFile
        Array[File?] outPoorCovExtended = computePoorCovExtended.poorCoverageFile
    }
}


# TASKS
task findFile {
    input {
        String Family  # Eg.: 'casIndex,father,mother'
        String PrefixPath  # Eg: /path/to/runID/MobiDL/
        String WDL = "panelCapture"
        String SuffixFile = ".crumble.cram"

        # runtime attributes
        String Queue
        Int Cpu
        Int Memory
    }
    command <<<
        set -e
        set -x
        # Should work also if 1 member in family ?
        for memb in $(echo ~{Family} | tr "," " ") ; do
            # WARN: No quotes around 'WDL' bellow, to correctly expand possible '*' (a bit dirty)
            foundFile=$(find "~{PrefixPath}"/~{WDL}/ -type f -name "${memb}~{SuffixFile}")
            if [ -z "$foundFile" ] || [ "$(echo "$foundFile" | wc -l)" -ne 1 ] ; then
                echo "ERROR: 1 file by sample is expected (found 0 or more than 1 for '$memb')"
                exit 1
            fi
            echo "$foundFile"
        done
    >>>

    output {
        Array[File] filesList = read_lines(stdout())
    }

    runtime {
        queue: "~{Queue}"
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}

# Take any CRAM/BAM and output a 'sample.bam' (+ index)
task toIndexedBAM {
    input {
        # Env variables
        String CondaBin
        String SamtoolsExe
        String SamtoolsEnv
        # task specific variables
        File BamFile
        File FastaGenome
        # global variables
        String SampleID
        String OutDir
        String WorkflowType
        # runtime attributes
        String Queue
        Int Cpu
        Int Memory
    }
    String outBam = "./" + SampleID + ".bam"
    String outBamIdx = "./" + SampleID + ".bam.bai"
    command <<<
        set -e
        source ~{CondaBin}activate ~{SamtoolsEnv}
        ~{SamtoolsExe} view -T ~{FastaGenome} -h -O BAM -o ~{outBam} ~{BamFile}
        ~{SamtoolsExe} index -o ~{outBamIdx} ~{outBam}
        conda deactivate
    >>>

    output {
        File sortedBam = outBam
        File bamIdx = outBamIdx
    }

    runtime {
        queue: "~{Queue}"
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}

task filterBAM {
    input {
        # Env variables
        String CondaBin
        String SamtoolsExe
        String SamtoolsEnv
        # task specific variables
        File BamFile
        Int MinCovBamQual = 0  # Default = no filter
        # global variables
        String SampleID
        String OutDir
        String WorkflowType
        # runtime attributes
        String Queue
        Int Cpu
        Int Memory
    }
    String outBam = "./" + SampleID + ".bam"
    String outBamIdx = "./" + SampleID + ".bam.bai"
    command <<<
        set -e
        source ~{CondaBin}activate ~{SamtoolsEnv}
        ~{SamtoolsExe} view -q ~{MinCovBamQual} -h -O BAM -o ~{outBam} ~{BamFile}
        ~{SamtoolsExe} index -o ~{outBamIdx} ~{outBam}
        conda deactivate
    >>>

    output {
        File sortedBam = outBam
        File bamIdx = outBamIdx
    }

    runtime {
        queue: "~{Queue}"
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}
