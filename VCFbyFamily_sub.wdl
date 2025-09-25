version 1.0


import "exomeMetrix_sub.wdl" as runExomeMetrix
import "captainAchab.wdl" as runCaptainAchab
import "modules/achabPostProcess.wdl" as runAchabPostProcess
import "modules/somalier.wdl" as runSomalier
import "modules/multiqc.wdl" as runMultiqc


workflow PedToVCF {
    meta {
        author: "Felix VANDERMEEREN"
        email: "felix.vandermeeren(at)chu-montpellier.fr"
        version: "0.5.9"
        date: "2025-03-11"
    }

    input {
        File pedFile
        String analysisDir  # Eg. /path/to/runID/MobiDL
        String? outputPath  # Default = send to 'AnalysisDir/byFamily/casIndex/casIndex.(merged.)vcf'

        String wdl = "variant_calling/merge"
        String suffixVcf = ".vcf.gz"  # VCF merged HC + DV
        String wdlBAM = "preprocessing/markduplicates"
        String suffixBAM = ".md.cram"
        File intervalBedFile
        File somalierSites = "/mnt/chu-ngs/refData/igenomes/Homo_sapiens/GATK/GRCh37/Annotation/Somalier/sites.GRCh37.vcf.gz"

        # PedToFam task:
        String pedsEnv  # Any python env with 'peds' package installed
        File? scriptExe

        # CaptainAchab inputs
        ## envs
        String condaBin
        String mpaEnv = "/bioinfo/conda_envs/mpaEnv"
        String achabEnv = "/bioinfo/conda_envs/achabEnv"
        String rsyncEnv = "/bioinfo/conda_envs/rsyncEnv"
        String samtoolsEnv = "/bioinfo/conda_envs/samtoolsEnv"
        String bcftoolsEnv = "/bioinfo/conda_envs/bcftoolsEnv"
        String multiqcEnv = "/bioinfo/conda_envs/multiqcEnv"
        ## queues
        String defQueue = "prod"
        ##Resources
        Int cpu
        Int cpuHigh
        Int memory = 4000
        Int memoryHigh = 16000
        ## Language Path
        String perlPath = "perl"
        ## Exe
        File achabExe
        String mpaExe = "mpa"
        String phenolyzerExe
        File tableAnnovarExe
        String bcftoolsExe = "bcftools"
        String gatkExe = "gatk"
        String rsyncExe = "rsync"
        String multiqcExe = "multiqc"
        # WARN: 'somalierRelatePostProcess' does not work with newer versions of csvtk
        String csvtkExe = "/bioinfo/softs/bin/csvtk-0.30.0"
        String somalierExe = "/bioinfo/softs/bin/somalier"
        ## Global
        String workflowType
        String outTmpDir = "/scratch/tmp_output/"
        Boolean keepFiles
        ## For annovarForMpa
        File customXref
        File refAnnotateVariation
        File refCodingChange
        File refConvert2Annovar
        File refRetrieveSeqFromFasta
        File refVariantsReduction
        String humanDb
        String genome
        String gnomadExome
        String gnomadGenome
        String dbnsfp
        String dbscsnv
        String intervar
        String popFreqMax
        String spliceAI
        String? clinvar
        String? intronHgvs
        ## For phenolyzer
        Boolean withPhenolyzer
        String diseaseFile
        ## For Achab
        String genesOfInterest
        String customVCF
        Float allelicFrequency
        Float mozaicRate
        Float mozaicDP
        String checkTrio
        String customInfo
        String cnvGeneList
        String filterList
        String mdApiKey = ''
        String favouriteGeneRef
        String filterCustomVCF
        String filterCustomVCFRegex
        String idSnp = ''
        String gnomadExomeFields = "gnomAD_exome_ALL,gnomAD_exome_AFR,gnomAD_exome_AMR,gnomAD_exome_ASJ,gnomAD_exome_EAS,gnomAD_exome_FIN,gnomAD_exome_NFE,gnomAD_exome_OTH,gnomAD_exome_SAS"
        String gnomadGenomeFields = "gnomAD_genome_ALL,gnomAD_genome_AFR,gnomAD_genome_AMR,gnomAD_genome_ASJ,gnomAD_genome_EAS,gnomAD_genome_FIN,gnomAD_genome_NFE,gnomAD_genome_OTH"
        Boolean addCustomVCFRegex = false
        Boolean pooledParents = false
        Boolean caseDepth = false
        Boolean caseAB = false
        File? genemap2File
        Boolean skipCaseWT = false
        Boolean hideACMG = false
        Boolean penalizeAffected = false
        ## For BcftoolsLeftAlign
        File fastaGenome
        String vcSuffix = ""
        ## For runCovMetrix
        String genomeVersion = "hg19"
        Int minCovBamQual = 30
        Int bedtoolsLowCoverage = 10  # Value used in exome -> different from MobiDL
        Int bedToolsSmallInterval = 5  # Value used in exome -> different from MobiDL
        String poorCoverageFileFolder = ""
        ## For custom MultiQC
        File customMQCconfig = "/mnt/chu-ngs/refData/multiQC_conf/exome_hg38_mqc.yaml"
    }
    String OutDir = if defined(outputPath) then outputPath + "/byFamily/" else analysisDir + "/byFamily/"

    call preprocessPed {
        input:
            PedFile = pedFile,
            CsvtkExe = csvtkExe,
            Queue = defQueue,
            Cpu = cpu,
            Memory = memory
    }
    call pedToFam {
        input:
            PedFile = preprocessPed.outputFile,
            CondaBin = condaBin,
            PedsEnv = pedsEnv,
            PathExe = scriptExe,
            Queue = defQueue,
            Cpu = cpu,
            Memory = memory
    }

    scatter (aStatus in pedToFam.status) {
        String aCasIndex = aStatus[0]
        String byFamDir = OutDir + aCasIndex + "/"
        String aFamily = aStatus[1]
        String OutMetrix = byFamDir + "coverage/"

        ## Always re-run metrix (coverage + 'somalier extract')

        call runExomeMetrix.exomeMetrix {
            input:
                samplesList = aFamily,
                analysisDir = analysisDir,
                wdlBAM = wdlBAM,
                suffixBAM = suffixBAM,
                intervals = intervalBedFile,
                somalierSites = somalierSites,
                poorCoverageFileFolder = poorCoverageFileFolder,
                runMobiCNV = false,
                outDir = byFamDir,
                fasta = fastaGenome,
                genomeVersion = genomeVersion,
                minCovBamQual = minCovBamQual,
                genomeCovMinMAPQ = minCovBamQual,
                bedtoolsLowCoverage = bedtoolsLowCoverage,
                bedToolsSmallInterval = bedToolsSmallInterval,
                cpuHigh = cpuHigh,
                memoryHigh = memoryHigh,
                cpuLow = cpu,
                memoryLow = memory,
                defQueue = defQueue,
                workflowType = "",
                somalierExe = somalierExe,
                condaBin = condaBin
        }

        # Gather all VCF of family + Achab
        call findVCF {
            input:
                Family = aFamily,
                PrefixPath = analysisDir,
                WDL = wdl,
                SuffixFile = suffixVcf,
                CondaBin = condaBin,
                BcftoolsEnv = bcftoolsEnv,
                Queue = defQueue,
                Cpu = cpu,
                Memory = memory,
        }
        call mergeVCF {
            input:
                CasIndex = aCasIndex,
                VCFlist = findVCF.filesList,
                VcfOutPath = byFamDir,
                CondaBin = condaBin,
                BcftoolsEnv = bcftoolsEnv,
                Queue = defQueue,
                Cpu = cpu,
                Memory = memory,
        }
        # MEMO: PooledSamples are either whole family or only casIndex
        #       Apply same logic as for Exome.wdl
        String pooledSamples = if (pooledParents) then aFamily else aCasIndex

        call runCaptainAchab.captainAchab {
            input:
                inputVcf = mergeVCF.vcfOut,
                caseSample = aCasIndex,
                sampleID = aCasIndex,
                fatherSample = aStatus[2],
                motherSample = aStatus[3],
                affected = aStatus[4],
                outDir = byFamDir + "/CaptainAchab/",
                condaBin = condaBin,
                bcftoolsEnv = bcftoolsEnv,
                mpaEnv = mpaEnv,
                achabEnv = achabEnv,
                rsyncEnv = rsyncEnv,
                defQueue = defQueue,
                cpu = cpu,
                cpuHigh = cpuHigh,
                memory = memory,
                perlPath = perlPath,
                achabExe = achabExe,
                mpaExe = mpaExe,
                phenolyzerExe = phenolyzerExe,
                tableAnnovarExe = tableAnnovarExe,
                bcftoolsExe = bcftoolsExe,
                gatkExe = gatkExe,
                rsyncExe = rsyncExe,
                workflowType = workflowType,
                outTmpDir = outTmpDir,
                keepFiles = keepFiles,
                customXref = customXref,
                refAnnotateVariation = refAnnotateVariation,
                refCodingChange = refCodingChange,
                refConvert2Annovar = refConvert2Annovar,
                refRetrieveSeqFromFasta = refRetrieveSeqFromFasta,
                refVariantsReduction = refVariantsReduction,
                humanDb = humanDb,
                genome = genome,
                gnomadExome = gnomadExome,
                gnomadGenome = gnomadGenome,
                dbnsfp = dbnsfp,
                dbscsnv = dbscsnv,
                intervar = intervar,
                popFreqMax = popFreqMax,
                spliceAI = spliceAI,
                clinvar = clinvar,
                intronHgvs = intronHgvs,
                withPhenolyzer = withPhenolyzer,
                diseaseFile = diseaseFile,
                genesOfInterest = genesOfInterest,
                customVCF = customVCF,
                allelicFrequency = allelicFrequency,
                mozaicRate = mozaicRate,
                mozaicDP = mozaicDP,
                checkTrio = checkTrio,
                customInfo = customInfo,
                cnvGeneList = cnvGeneList,
                filterList = filterList,
                mdApiKey = mdApiKey,
                favouriteGeneRef = favouriteGeneRef,
                filterCustomVCF = filterCustomVCF,
                filterCustomVCFRegex = filterCustomVCFRegex,
                idSnp = idSnp,
                gnomadExomeFields = gnomadExomeFields,
                gnomadGenomeFields = gnomadGenomeFields,
                addCustomVCFRegex = addCustomVCFRegex,
                pooledSamples = pooledSamples,
                caseDepth = caseDepth,
                caseAB = caseAB,
                poorCoverageFile = exomeMetrix.outPoorCovExtended[0],
                genemap2File = genemap2File,
                skipCaseWT = skipCaseWT,
                hideACMG = hideACMG,
                penalizeAffected = penalizeAffected,
                fastaGenome = fastaGenome,
                vcSuffix = vcSuffix
        }

        # Achab metrix + 'somalier relate' + custom MultiQC
        ## Post-process Achab 'newHope' results
        call runAchabPostProcess.postProcess as achabCINewHopePost {
            input :
                OutAchab = captainAchab.achabNewHopeExcel,
                OutAchabHTML = captainAchab.achabNewHopeHtml,
                OutAchabPoorCov = captainAchab.achabPoorCov,
                OutDir = OutMetrix,
                csvtkExe = csvtkExe,
                Queue = defQueue,
                Cpu = cpu,
                Memory = memory,
                TaskOut = captainAchab.achabNewHopeHtml
        }
    }

    ### Somalier 'relate' on '.somalier' files generated from BAM
    call runSomalier.relate as somalierRelate {
        input:
            path_exe = somalierExe,
            ped = preprocessPed.outputFile,
            somalier_extracted_files = select_all(flatten(flatten([exomeMetrix.somalierExtracted]))),
            outputPath = OutDir + "/somalier_relate/",
            csvtkExe = csvtkExe,
            Queue = defQueue,
            Cpu = cpu,
            Memory = memory
    }
    ### Post-process 'relate' output file
    call runSomalier.relatePostprocess as somalierRelatePostprocess {
        input:
            relateSamplesFile = somalierRelate.RelateSamplesFile,
            relatePairsFile = somalierRelate.RelatePairsFile,
            ped = preprocessPed.outputFile,
            outputPath = OutDir + "/somalier_relate/",
            csvtkExe = csvtkExe,
            Queue = defQueue,
            Cpu = cpu,
            Memory = memory
    }

    # Custom MQC
    call runMultiqc.multiqc as multiQC_custom {
        input:
            Queue = defQueue,
            CondaBin = condaBin,
            MultiqcEnv = multiqcEnv,
            Cpu = cpu,
            Memory = 16000,
            SampleID = "",
            Name = "custom",
            OutDir = OutDir,
            WorkflowType = "",
            MultiqcExe = multiqcExe,
            GatkExe = gatkExe,
            Version = true,
            configFile = customMQCconfig,
            TaskOut = flatten([
                select_all([somalierRelatePostprocess.CustomSamplesFile, somalierRelatePostprocess.RelateFilteredPairs]),
                achabCINewHopePost.outAchabMetrix
            ])
    }

    output {
        Array[File] mergedVCFs = mergeVCF.vcfOut
    }
}


task preprocessPed {
    input {
        File PedFile
        String CsvtkExe = "csvtk"

        # runtime attributes
        String Queue
        Int Cpu
        Int Memory
    }

    command <<<
        set -e

        # Remove rows starting with '0':
        # And ones starting with '#REF!' (= REF cell deleted in Excel)
        "~{CsvtkExe}" grep \
                            --comment-char '$' --tabs \
                            --fields 1 \
                            --pattern "0" --invert \
                            "~{PedFile}" |
            "~{CsvtkExe}" grep \
                                --comment-char '$' --tabs \
                                --fields 1 \
                                --pattern "#REF!" --invert
    >>>

    output {
        File outputFile = stdout()
    }

    runtime {
        queue: "~{Queue}"
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}

task pedToFam {
    input {
        File PedFile
        String PythonExe = "python3"
        File PathExe = "ped_to_fam.py"

        String CondaBin
        String PedsEnv  # Any python env with 'peds' package installed
        # runtime attributes
        String Queue
        Int Cpu
        Int Memory
    }

    command <<<
        set -e

        source ~{CondaBin}activate ~{PedsEnv}
        "~{PythonExe}" "~{PathExe}" "~{PedFile}"
        conda deactivate
    >>>

    output {
        Array[Array[String]] status = read_json("status.json")  # [casIndex, membersList, father, mother, affectedList]
    }

    runtime {
        queue: "~{Queue}"
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}

task mergeVCF {
    input {
        Array[File] VCFlist  # Eg.: [/path/to/casIndex.vcf, /path/to/father.vcf, /path/to/mother.vcf]
        String CasIndex
        String VcfOutPath  # Eg: /path/to/runID/MobiDL/byFam/aSample/

        String CondaBin
        String BcftoolsEnv
        String BcftoolsExe = "bcftools"
        # runtime attributes
        String Queue
        Int Cpu
        Int Memory
    }

    String VcfOut = VcfOutPath + CasIndex + ".vcf"
    Int nbSamples = length(VCFlist)

    command <<<
        set -e

        if [[ ! -d ~{VcfOutPath} ]]; then
            mkdir --parents ~{VcfOutPath}
        fi

        # If family has 1 single sample -> simply copy VCF
        if [ "~{nbSamples}" -eq "1" ] ; then
            cp --verbose ~{VCFlist[0]} "~{VcfOut}" 

        else
            source ~{CondaBin}activate ~{BcftoolsEnv}
            ~{BcftoolsExe} merge ~{sep=" " VCFlist} \
                --merge none \
                --missing-to-ref \
                --no-index \
                -Ov -o "~{VcfOut}"
            conda deactivate
        fi
    >>>

    output {
        File vcfOut = VcfOut
    }

    runtime {
        queue: "~{Queue}"
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}

task findVCF {
    input {
        String Family  # Eg.: 'casIndex,father,mother'
        String PrefixPath  # Eg: /path/to/runID/MobiDL/
        String WDL = "panelCapture"
        String SuffixFile = ".crumble.cram"

        String CondaBin
        String BcftoolsEnv
        String BcftoolsExe = "bcftools"
        # runtime attributes
        String Queue
        Int Cpu
        Int Memory
    }
    command <<<
        set -e
        source ~{CondaBin}activate ~{BcftoolsEnv}
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
