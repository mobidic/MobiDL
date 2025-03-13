version 1.0


workflow PedToVCF {
    meta {
        author: "Felix VANDERMEEREN"
        email: "felix.vandermeeren(at)chu-montpellier.fr"
        version: "0.0.5"
        date: "2025-03-11"
    }

    input {
        File PedFile
        String AnalysisDir  # Eg. /path/to/runID/MobiDL
        String OutputPath = AnalysisDir
    }


    call pedToFam {
        input:
            pedFile = PedFile
    }

    scatter (FamilyInfos in pedToFam.familiesInfos) {
        call membListToVCF {
            input:
                aString = FamilyInfos[0],
                prefixPath = AnalysisDir
        }

        call mergeVCF {
            input:
                membersVCF = membListToVCF.VCFarray,
                outputPath = OutputPath
        }
    }

    output{
        Array[File] mergedVCFs = mergeVCF.vcfOut
    }
}


task pedToFam {
    input {
        File pedFile
        String pythonExe = "python3"
        String pathExe = "ped_to_fam.py"

        Int Cpu = 1
        Int Memory = 768
    }

    command <<<
        set -euo pipefail

        "~{pythonExe}" "~{pathExe}" "~{pedFile}"
    >>>

    output {
        Array[Array[String]] familiesInfos = read_json("status.json")  # [members_list, casIndex, father, mother, affected_list]
    }

    runtime {
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}


task membListToVCF {
    input {
        String aString  # Eg: "casIndex,father,mother"
        String aSep = ','
        String prefixPath  # Eg: /path/to/runID/MobiDL
        String WDL = "panelCapture"
        String suffixVcf = ".HC.vcf"

        Int Cpu = 1
        Int Memory = 768
    }

    command <<<
        set -euo pipefail

        for memb in $(echo "~{aString}" | tr "~{aSep}" " ") ; do
            ls -d "~{prefixPath}/${memb}/~{WDL}/${memb}~{suffixVcf}"
        done
    >>>

    output {
        Array[String] VCFarray = read_lines(stdout())  # Gives: [/path/to/casIndex.vcf, /path/to/father.vcf, /path/to/mother.vcf]
    }

    runtime {
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}


task mergeVCF {
    # ENH: Use Exome.wdl's task 'bcftools merge' instead ?
    input {
        Array[File] membersVCF    # Eg: [/path/to/casIndex.vcf, /path/to/father.vcf, /path/to/mother.vcf]
        String bcftoolsExe = "bcftools"
        String? outputPath

        Int Cpu = 1
        Int Memory = 768
    }

    String subString = "\.(vcf|bcf)(\.gz)?$"
    String subStringReplace = ""
    String baseName = sub(basename(membersVCF[0]),subString,subStringReplace)
    String VcfOutPath = if defined(outputPath) then outputPath + "/BY_FAMILY/" + baseName + "/" else "./BY_FAMILY/" + baseName
    String VcfOut = VcfOutPath + "/" + baseName + ".vcf"

    command <<<
        set -euo pipefail

        if [[ ! -d ~{VcfOutPath} ]]; then
            mkdir --parents ~{VcfOutPath}
        fi

        ~{bcftoolsExe} merge \
                             --merge none \
                             --missing-to-ref \
                             --no-index \
                             -Ov -o "~{VcfOut}" \
                             ~{sep=" " membersVCF}
    >>>

    output {
        File vcfOut = VcfOut
    }

    runtime {
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}
