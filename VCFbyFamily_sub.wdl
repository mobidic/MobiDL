version 1.0


import "captainAchab.wdl" as runCaptainAchab
import "modules/somalier.wdl" as runSomalier


workflow PedToVCF {
    meta {
        author: "Felix VANDERMEEREN"
        email: "felix.vandermeeren(at)chu-montpellier.fr"
        version: "0.1.1"
        date: "2025-03-11"
    }

    input {
        File pedFile
        String analysisDir  # Eg. /path/to/runID/MobiDL
        String? outputPath  # Default = send to 'AnalysisDir/byFamily/casIndex/casIndex.(merged.)vcf'

        String wdl = "panelCapture"
        String suffixVcf = ".vcf"
        String wdlBAM = "panelCapture"
        String suffixBAM = ".crumble.cram"

        String condaBin

        # PedToFam task:
        String pedsEnv  # Any python env with 'peds' package installed
        File? scriptExe
        # mergeVCF task:
        String bcftoolsEnv

        # CaptainAchab inputs
        ## envs
        String mpaEnv = "/bioinfo/conda_envs/mpaEnv"
        String achabEnv = "/bioinfo/conda_envs/achabEnv"
        String rsyncEnv = "/bioinfo/conda_envs/rsyncEnv"
        String samtoolsEnv = "/bioinfo/conda_envs/samtoolsEnv"
        ## queues
        String defQueue = "prod"
        ##Resources
        Int cpuLow
        Int cpuHigh
        Int memoryLow
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
        String somalierExe = "/bioinfo/softs/bin/somalier"
        # WARN: 'somalierRelatePostProcess' does not work with newer versions of csvtk
        String csvtkExe = "/bioinfo/softs/bin/csvtk-0.30.0"
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
        #String operationSuffix
        #String comma
        ## For phenolyzer
        Boolean withPhenolyzer
        String diseaseFile
        ## For Achab
        # File mdApiKeyFile
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
        Boolean addCaseDepth = false
        Boolean addCaseAB = false
        Boolean withPoorCov = false
        File? genemap2File
        Boolean skipCaseWT = false
        Boolean hideACMG = false
        ## For BcftoolsLeftAlign
        File fastaGenome
        String vcSuffix = ""
    }


    call preprocessPed {
        input:
            PedFile = pedFile,
            CsvtkExe = csvtkExe,
            Queue = defQueue,
            Cpu = cpuLow,
            Memory = memoryLow
    }

    call pedToFam {
        input:
            PedFile = preprocessPed.outputFile,
            CondaBin = condaBin,
            PedsEnv = pedsEnv,
            PathExe = scriptExe,
            Queue = defQueue,
            Cpu = cpuLow,
            Memory = memoryLow
    }

    scatter (aStatus in pedToFam.status) {
        String aCasIndex = aStatus[0]
        String byFamDir = if defined(outputPath) then outputPath + "/byFamily/" + aCasIndex + "/" else analysisDir + "/byFamily/" + aCasIndex + "/"
        String aFamily = aStatus[1]

        call findVCF {
            input:
                Family = aFamily,
                PrefixPath = analysisDir,
                WDL = wdl,
                SuffixVcf = suffixVcf,
                Queue = defQueue,
                Cpu = cpuLow,
                Memory = memoryLow,
        }
        call mergeVCF {
            input:
                CasIndex = aCasIndex,
                VCFlist = findVCF.vcfList,
                PrefixPath = analysisDir,
                VcfOutPath = byFamDir,
                WDL = wdl,
                SuffixVcf = suffixVcf,
                CondaBin = condaBin,
                BcftoolsEnv = bcftoolsEnv,
                Queue = defQueue,
                Cpu = cpuLow,
                Memory = memoryLow,
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
                cpu = cpuLowHigh,
                memory = memoryLow,
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
                caseDepth = addCaseDepth,
                caseAB = addCaseAB,
                genemap2File = genemap2File,
                skipCaseWT = skipCaseWT,
                hideACMG = hideACMG,
                fastaGenome = fastaGenome,
                vcSuffix = vcSuffix
        }

        # Metrix:
        call findBAM {
            input:
                Family = aFamily,
                PrefixPath = analysisDir,
                WDL = wdlBAM,
                SuffixBAM = suffixBAM,
                Queue = defQueue,
                Cpu = cpuLow,
                Memory = memoryLow
        }
        scatter (aBam in findBAM.bamList) {
            call runSomalier.extract as SomalierExtract {
                input :
                    refFasta = fastaGenome,
                    bamFile = aBam,
                    outputPath = byFamDir,
                    path_exe = somalierExe,
                    CondaBin = condaBin,
                    SamtoolsEnv = samtoolsEnv,
                    Queue = defQueue,
                    Cpu = cpuLow,
                    Memory = memoryLow
            }
        }
    }
    ##Somalier 'relate' on '.somalier' files generated from BAM
    call runSomalier.relate as somalierRelate {
        input :
            path_exe = somalierExe,
            ped = preprocessPed.outputFile,
            somalier_extracted_files = flatten(flatten([SomalierExtract.file])),
            outputPath = outputPath + "/byFamily/somalier_relate/",
            csvtkExe = csvtkExe,
            Queue = defQueue,
            Cpu = cpuLow,
            Memory = memoryLow      
    }

    ##Post-process 'relate' output file
    call runSomalier.relatePostprocess as somalierRelatePostprocess {
        input :
            relateSamplesFile = somalierRelate.RelateSamplesFile,
            relatePairsFile = somalierRelate.RelatePairsFile,
            ped = preprocessPed.outputFile,
            outputPath = outputPath + "/byFamily/somalier_relate/",
            csvtkExe = csvtkExe,
            Queue = defQueue,
            Cpu = cpuLow,
            Memory = memoryLow
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

task findVCF {
    input {
        String Family  # Eg.: 'casIndex,father,mother'
        String PrefixPath  # Eg: /path/to/runID/MobiDL/
        String WDL = "panelCapture"
        String SuffixVcf = ".vcf"

        # runtime attributes
        String Queue
        Int Cpu
        Int Memory
    }
    command <<<
        set -e
        # Should work also if 1 member in family ?
        for memb in $(echo ~{Family} | tr "," " ") ; do
            ls -d "~{PrefixPath}/${memb}/~{WDL}/${memb}~{SuffixVcf}"
        done
    >>>

    output {
        Array[File] vcfList = read_lines(stdout())
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
        String PrefixPath  # Eg: /path/to/runID/MobiDL/
        String VcfOutPath  # Eg: /path/to/runID/MobiDL/byFam/aSample/
        String WDL = "panelCapture"
        String SuffixVcf = ".HC.vcf"

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

task findBAM {
    input {
        String Family  # Eg.: 'casIndex,father,mother'
        String PrefixPath  # Eg: /path/to/runID/MobiDL/
        String WDL = "panelCapture"
        String SuffixBAM = ".crumble.cram"

        # runtime attributes
        String Queue
        Int Cpu
        Int Memory
    }
    command <<<
        set -e
        # Should work also if 1 member in family ?
        for memb in $(echo ~{Family} | tr "," " ") ; do
            ls -d "~{PrefixPath}/${memb}/~{WDL}/${memb}~{SuffixBAM}"
        done
    >>>

    output {
        Array[File] bamList = read_lines(stdout())
    }

    runtime {
        queue: "~{Queue}"
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}
