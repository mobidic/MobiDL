version 1.0

task achabNewHope {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-08"
	}
	input {
		# env variables	
		String CondaBin
		String AchabEnv
		# global variables
		String SampleID
		String OutDir
		String WorkflowType
		Boolean Version = false
		# task specific variables
		File AchabExe
		File OutMpa
		String? OutPhenolyzer
		String CustomVCF
		String CnvGeneList
		String FilterList
		String GenesOfInterest
		String FatherSample
		String CaseSample
		String MotherSample
		Float AllelicFrequency
		Float MozaicRate
		Float MozaicDP		
		String CheckTrio
		String CustomInfo
		String PerlPath
		String Affected
		String FavouriteGeneRef
		String FilterCustomVCF
		String FilterCustomVCFRegex
		String GnomadExomeFields
		String GnomadGenomeFields
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		source ~{CondaBin}activate ~{AchabEnv}
		~{PerlPath} "~{AchabExe}" \
		--vcf "~{OutMpa}" \
		--outDir "~{OutDir}~{SampleID}/~{WorkflowType}/achab_excel/" \
		--outPrefix "~{SampleID}" \
		--case "~{CaseSample}" \
		--dad "~{FatherSample}" \
		--mum "~{MotherSample}" \
		~{CheckTrio} \
		--candidates "~{GenesOfInterest}" \
		--phenolyzerFile "~{OutPhenolyzer}" \
		--popFreqThr "~{AllelicFrequency}" \
		--newHope \
		--filterList "~{FilterList}" \
		--cnvGeneList "~{CnvGeneList}" \
		--customVCF "~{CustomVCF}" \
		--mozaicRate "~{MozaicRate}" \
		--mozaicDP "~{MozaicDP}" \
		--customInfoList "~{CustomInfo}" \
		--affected "~{Affected}" \
		--favouriteGeneRef "~{FavouriteGeneRef}" \
		--filterCustomVCF "~{FilterCustomVCF}" \
		--filterCustomVCFRegex "~{FilterCustomVCFRegex}" \
		--gnomadExome  "~{GnomadExomeFields}" \
		--gnomadGenome "~{GnomadGenomeFields}" \
		--addCustomVCFRegex
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "captainAchab: v$(~{PerlPath} ~{AchabExe} -v | cut -f2 -d ':')" >>  "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt";
		fi
		source ~{CondaBin}deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File outAchabNewHope = "~{OutDir}~{SampleID}/~{WorkflowType}/achab_excel/~{SampleID}_achab_catch_newHope.xlsx"
	}
}
