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
        version: "0.4.0"
        date: "2025-05-26"
    }

    input {
        # Tasks specific
        String samplesList
        String analysisDir
        File intervals
        File fasta
        ## Global
        String outDir
        String genomeVersion
        String workflowType = ""
        ## Optional
        String wdlBAM = "preprocessing/markduplicates"
        String suffixBAM = ".md.cram"
        File? somalierSites
        ## Params
        Int minCovBamQual = 30
        Int genomeCovMinMAPQ = 0  # Default = do not filter
        Int bedtoolsLowCoverage = 20
        Int bedToolsSmallInterval = 20
        String poorCoverageFileFolder = ""  # Disabled by default
        Boolean runMobiCNV = true
        ## Standard execs
        String awkExe = "awk"
        String sedExe = "sed"
        String sortExe = "sort"
        ## Standard execs
        String bedToolsExe = "bedtools"
        String samtoolsExe = "samtools"
        String somalierExe = "/bioinfo/softs/bin/somalier"
        String mobicnvExe = "/bioinfo/softs/MobiCNV/MobiCNV.py"
        ## envs
        String condaBin = "/mnt/Bioinfo/Softs/miniconda/bin/"
        String bedtoolsEnv = "/bioinfo/conda_envs/bedtoolsEnv"
        String samtoolsEnv = "/bioinfo/conda_envs/samtoolsEnv"
        String mobicnvEnv = "/bioinfo/conda_envs/mobicnvEnv"
        ## queues
        String defQueue = "prod"
        ##Resources
        Int cpuLow = 1
        Int cpuHigh = 24
        # Int avxCpu
        Int memoryLow = 4000
        Int memoryHigh = 16000
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
        String sampleID = basename(aBam, suffixBAM)

        # WARN: Implicit outDir is 'coverage' subdir
        #       -> Create it otherwise error
        call mkdirCov {
            input:
                Queue = defQueue,
                Cpu = cpuLow,
                Memory = memoryLow,
                OutDir = outDir
        }

        # 'somalier and 'samtools bedcov' requires indexed BAM
        call toIndexedBAM {
            input:
                Queue = defQueue,
                CondaBin = condaBin,
                SamtoolsEnv = samtoolsEnv,
                Cpu = cpuLow,
                Memory = memoryLow,
                SampleID = sampleID,
                OutDir = mkdirCov.outDir,
                WorkflowType = workflowType,
                SamtoolsExe = samtoolsExe,
                fasta = fasta,
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
                OutDir = mkdirCov.outDir,
                WorkflowType = workflowType,
                SamtoolsExe = samtoolsExe,
                MinCovBamQual = genomeCovMinMAPQ,
                BamFile = aBam
        }

        if (defined(somalierSites)) {
            # Somalier extract
            call runSomalier.extract as somalierExtract {
                input :
                    refFasta = fasta,
                    sites = somalierSites,
                    bamFile = toIndexedBAM.sortedBam,
                    BamIndex = toIndexedBAM.bamIdx,
                    outputPath = mkdirCov.outDir + "/coverage/",
                    path_exe = somalierExe,
                    Queue = defQueue,
                    Cpu = cpuLow,
                    Memory = memoryLow
            }
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
                OutDir = mkdirCov.outDir,
                OutDirSampleID = "/",
                WorkflowType = workflowType,
                SamtoolsExe = samtoolsExe,
                IntervalBedFile = intervals,
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
                OutDir = mkdirCov.outDir,
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
        #         OutDir = mkdirCov.outDir,
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
                OutDir = mkdirCov.outDir,
                OutDirSampleID = "/",
                WorkflowType = workflowType,
                GenomeVersion = genomeVersion,
                BedToolsExe = bedToolsExe,
                AwkExe = awkExe,
                SortExe = sortExe,
                IntervalBedFile = intervals,
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
                OutDir = mkdirCov.outDir,
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
                OutDir = mkdirCov.outDir,
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

    if (runMobiCNV) {
        # Run MobiCNV
        call runMobiCNV {
            input:
                Queue = defQueue,
                CondaBin = condaBin,
                MobicnvEnv = mobicnvEnv,
                Cpu = cpuLow,
                Memory = memoryHigh,
                OutDir = outDir,
                WorkflowType = workflowType,
                MobicnvExe = mobicnvExe,
                IntervalBedFile = intervals,
                CovTsvFiles = computeCoverage.TsvCoverageFile
        }
    }

    output {
        Array[File?] somalierExtracted = somalierExtract.file
        Array[File] outCoverage = computeCoverage.TsvCoverageFile
        Array[File] outBedCov = samtoolsBedCov.BedCovFile
        # Array[File outBedCovClamms = computeCoverageClamms.ClammsCoverageFile
        Array[File] outPoorCoverage = computePoorCoverage.poorCoverageFile
        Array[File?] outPoorCovExtended = computePoorCovExtended.poorCoverageFile
    }
}


# TASKS
task mkdirCov {
    input {
        String OutDir

        # runtime attributes
        String Queue
        Int Cpu
        Int Memory
    }
    command <<<
        set -e
        mkdir -p ~{OutDir}/coverage
    >>>

    output {
        String outDir = OutDir
    }

    runtime {
        queue: "~{Queue}"
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}

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
        File fasta
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
        ~{SamtoolsExe} view -T ~{fasta} -h -O BAM -o ~{outBam} ~{BamFile}
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

task runMobiCNV {
    input {
        # Env variables
        String CondaBin
        String MobicnvExe
        String MobicnvEnv
        String PythonExe = "python"
        # task specific variables
        Array[File] CovTsvFiles  # /path/to/MobiCNVtsvs/${aBED}/
        File IntervalBedFile
        # global variables
        String OutDir
        String WorkflowType
        # runtime attributes
        String Queue
        Int Cpu
        Int Memory
    }
    String OutMobiCNVxl = OutDir + "/MobiCNV.xlsx"
    String OutMobiCNVerror = OutDir + "/MobiCNV.skipped.txt"
    String LIBRARY = basename(IntervalBedFile, ".bed")
    Int NUMBER_OF_SAMPLE = length(CovTsvFiles)
    command <<<
        set -e
        # check if at least 3 samples / library => otherwise exit without error
        if [ ~{NUMBER_OF_SAMPLE} -lt 3 ];then
            echo "Not enough samples for Library ~{LIBRARY} to launch MobiCNV (~{NUMBER_OF_SAMPLE} samples)" > ~{OutMobiCNVerror}
            exit
        fi
        # Create 'MobiCNVtsvs' dir
        MobiCNVdir=~{OutDir}/MobiCNVtsvs/
        mkdir -v -p ${MobiCNVdir}
        for aTsv in ~{sep=" " CovTsvFiles}; do
            cp -v ${aTsv} ${MobiCNVdir}
        done
        # Then run MobiCNV on it
        source ~{CondaBin}activate ~{MobicnvEnv}
        "~{PythonExe}" "~{MobicnvExe}" -i "${MobiCNVdir}/" -t tsv -o ~{OutMobiCNVxl}
        conda deactivate
    >>>

    # Simpler to NOT define output:
    # output {
    # }

    runtime {
        queue: "~{Queue}"
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}
