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
    }


    call pedToFam {
        input:
            pedFile = PedFile
    }

    scatter (FamilyInfos in pedToFam.familiesInfos) {
        call stringToArray {
            input:
                aString = FamilyInfos[0]
        }

        call mergeVCF {
            input:
                membersList = stringToArray.outArray,
                prefixPath = AnalysisDir
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


task stringToArray {
    input {
        String aString  # Eg: "casIndex,father,mother"
        String aSep = ","

        Int Cpu = 1
        Int Memory = 768
    }

    command <<<
        set -euo pipefail

        echo "~{aString}" | sed "s/$/~{aSep}/" | tr "~{aSep}" "\n"
    >>>

    output {
        Array[String] outArray = read_lines(stdout())  # Gives: [casIndex, father, mother]
    }

    runtime {
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}


task mergeVCF {
    input {
        Array[String] membersList    # Eg: [casIndex, father, mother]
        String prefixPath  # Eg: /path/to/runID/MobiDL
        String WDL = "panelCapture"
        String suffixVcf = ".HC.vcf"
        String bcftoolsExe = "bcftools"
        String? outputPath

        Int Cpu = 1
        Int Memory = 768
    }

    String VcfOutPath = if defined(outputPath) then outputPath + "/BY_FAMILY/" + membersList[0] + "/" else prefixPath + "/BY_FAMILY/" + membersList[0] + "/"
    String VcfOut = VcfOutPath + membersList[0] + ".vcf"

    command <<<
        set -euo pipefail

        if [[ ! -d ~{VcfOutPath} ]]; then
            mkdir --parents ~{VcfOutPath}
        fi

        for memb in ~{sep=" " membersList} ; do
            ls -d "~{prefixPath}/${memb}/~{WDL}/${memb}~{suffixVcf}"
        done |
            xargs ~{bcftoolsExe} merge \
                                        --merge none \
                                        --missing-to-ref \
                                        --no-index \
                                        -Ov -o "~{VcfOut}"
    >>>

    output {
        File vcfOut = VcfOut
    }

    runtime {
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}
