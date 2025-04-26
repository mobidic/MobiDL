version 1.0


import "captainAchab.wdl" as runCaptainAchab


workflow PedToVCF {
    meta {
        author: "Felix VANDERMEEREN"
        email: "felix.vandermeeren(at)chu-montpellier.fr"
        version: "0.0.7"
        date: "2025-03-11"
    }

    input {
        File pedFile
        String analysisDir  # Eg. /path/to/runID/MobiDL
        String? outputPath  # Default = send to 'AnalysisDir/byFamily/casIndex/casIndex.(merged.)vcf'

        String wdl = "panelCapture"
        String suffixVcf = ".hc.vcf"

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
        ## queues
        String defQueue = "prod"
        ##Resources
        Int cpu
        Int cpuHigh
        Int memory
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

    call pedToFam {
        input:
            PedFile = pedFile,
            CondaBin = condaBin,
            PedsEnv = pedsEnv,
            PathExe = scriptExe
    }

    scatter (aStatus in pedToFam.status) {
        String aCasIndex = aStatus[0]
        String byFamDir = if defined(outputPath) then outputPath + "/byFamily/" + aCasIndex + "/" else analysisDir + "/byFamily/" + aCasIndex + "/"
        String aFamily = aStatus[1]

        call mergeVCF {
            input:
                CasIndex = aCasIndex,
                Family = aFamily,
                PrefixPath = analysisDir,
                VcfOutPath = byFamDir,
                WDL = wdl,
                SuffixVcf = suffixVcf,
                CondaBin = condaBin,
                BcftoolsEnv = bcftoolsEnv
        }

        # Do Achab
        if (withPoorCov) {
            call findPoorCov {
                input:
                    CasIndex = aCasIndex,
                    PrefixPath = analysisDir
            }
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
                addCaseDepth = addCaseDepth,
                addCaseAB = addCaseAB,
                poorCoverageFile = findPoorCov.poorCovOut,
                genemap2File = genemap2File,
                skipCaseWT = skipCaseWT,
                hideACMG = hideACMG,
                fastaGenome = fastaGenome,
                vcSuffix = vcSuffix
        }
    }

    output {
        Array[File] mergedVCFs = mergeVCF.vcfOut
    }
}


task pedToFam {
    input {
        File PedFile
        String PythonExe = "python3"
        File PathExe = "ped_to_fam.py"

        String CondaBin
        String PedsEnv  # Any python env with 'peds' package installed
        Int Cpu = 1
        Int Memory = 768
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
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}


task mergeVCF {
    input {
        String Family  # Eg.: 'casIndex,father,mother'
        String CasIndex
        String PrefixPath  # Eg: /path/to/runID/MobiDL/
        String VcfOutPath  # Eg: /path/to/runID/MobiDL/byFam/aSample/
        String WDL = "panelCapture"
        String SuffixVcf = ".HC.vcf"

        String CondaBin
        String BcftoolsEnv
        String BcftoolsExe = "bcftools"
        Int Cpu = 1
        Int Memory = 768
    }

    String VcfOut = VcfOutPath + CasIndex + ".vcf"

    command <<<
        set -e

        if [[ ! -d ~{VcfOutPath} ]]; then
            mkdir --parents ~{VcfOutPath}
        fi

        # If family has 1 single sample -> simply copy VCF
        if [ "$(echo ~{Family} | tr "," "\n" | wc -l)" -eq "1" ] ; then
            memb=~{Family}
            cp --verbose "~{PrefixPath}/${memb}/~{WDL}/${memb}~{SuffixVcf}" "~{VcfOut}"

        else
            source ~{CondaBin}activate ~{BcftoolsEnv}

            for memb in $(echo ~{Family} | tr "," " ") ; do
                ls -d "~{PrefixPath}/${memb}/~{WDL}/${memb}~{SuffixVcf}"
            done |
                xargs ~{BcftoolsExe} merge \
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
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}


task findPoorCov {
    input {
        String CasIndex
        String PrefixPath  # Eg: /path/to/runID/MobiDL/
        String WDL = "panelCapture"
        String DirPoorCov = "coverage"
        String SuffixPoorCov = "_poor_coverage.tsv"

        Int Cpu = 1
        Int Memory = 768
    }

    String PoorCovPath = "~{PrefixPath}/~{CasIndex}/~{WDL}/~{DirPoorCov}/~{CasIndex}~{SuffixPoorCov}"

    command <<<
        set -e

        ls -d "~{PoorCovPath}"
    >>>

    output {
        File poorCovOut = PoorCovPath
    }

    runtime {
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}
