version 1.0

task achab {
	meta {
		author: "Felix VANDERMEEREN"
		email: "felix.vandermeeren(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2025-04-16"
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
		String NewHope = ""
		String AchabExe = "wwwachab.pl"
		File OutMpa
		File? OutPhenolyzer
		String? CustomVCF
		String? CnvGeneList
		String FilterList = "PASS"
		String? GenesOfInterest
		String? FatherSample
		String? CaseSample
		String? MotherSample
		Float AllelicFrequency = 0.01
		Float MozaicRate = 0.2
		Float MozaicDP = 5
		String CheckTrio
		String? CustomInfo
		String IdSnp
		String PerlPath = "perl"
		String? Affected
		String MdApiKey
		String? FavouriteGeneRef
		String? FilterCustomVCF
		String? FilterCustomVCFRegex
		String? GnomadExomeFields
		String? GnomadGenomeFields
		Boolean AddCustomVCFRegex = false
		String? PooledSamples
		Boolean AddCaseDepth = false
		Boolean AddCaseAB = false
		File? PoorCoverageFile
		File? Genemap2File
		Boolean SkipCaseWT = false
		Boolean HideACMG = false
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}

	String Case = if defined(CaseSample) then CaseSample else SampleID
	String Dad = if defined(FatherSample) then "--dad \"~{FatherSample}\" " else ""
	String Mum = if defined(MotherSample) then "--mum \"~{MotherSample}\" " else ""
	String affected = if defined(Affected) then "--affected ~{Affected}" else ""
	String candidates = if defined(GenesOfInterest) then "--candidates ~{GenesOfInterest} " else ""
	String cngGL = if defined(CnvGeneList) then "--cnvGeneList ~{CnvGeneList} " else ""
	String newHopeSuffix = if NewHope == "" then "" else "_newHope"
	String customVcf = if defined(CustomVCF) then "--customVCF ~{CustomVCF} " else ""
	String customInfoList = if defined(CustomInfo) then "--customInfoList ~{CustomInfo} " else ""
	String favGenRef = if defined(FavouriteGeneRef) then "--favouriteGeneRef ~{FavouriteGeneRef} " else ""
	String filtCustVcf = if defined(FilterCustomVCF) then "--filterCustomVCF ~{FilterCustomVCF} " else ""
	String filtCustVcfReg = if defined(FilterCustomVCFRegex) then "--filterCustomVCFRegex ~{FilterCustomVCFRegex} " else ""
	String addCustVCFRegex = if AddCustomVCFRegex then "--addCustomVCFRegex " else ""
	String poolSample = if defined(PooledSamples) then "--pooledSamples ~{PooledSamples}" else ""
	String addCasDep = if AddCaseDepth then "--addCaseDepth " else ""
	String addCasab = if AddCaseAB then "--addCaseAB " else ""
	String poorCov = if (defined(PoorCoverageFile) && defined(Genemap2File)) then "--poorCoverageFile ~{PoorCoverageFile} --genemap2File ~{Genemap2File} " else ""
	String SkipCase = if SkipCaseWT then "--skipCaseWT " else ""
	String Pheno = if defined(OutPhenolyzer) then "--phenolyzerFile ~{OutPhenolyzer} " else ""
	String HideAcmg = if HideACMG then "--hideACMG " else ""
	String idSNP = if defined(IdSnp) then "--IDSNP ~{IdSnp}" else ""

	command <<<
		set -e

		source ~{CondaBin}activate ~{AchabEnv}

		set -x

		if [[ ! -d ~{OutDir} ]]; then
			mkdir -p ~{OutDir}
		fi

		~{PerlPath} "~{AchabExe}" \
		--vcf "~{OutMpa}" \
		--outDir "~{OutDir}~{SampleID}/~{WorkflowType}/achab_excel/" \
		--outPrefix "~{SampleID}" \
		--case "~{Case}" \
		~{Dad} \
		~{Mum} \
		~{candidates} \
		~{Pheno} \
		--popFreqThr "~{AllelicFrequency}" \
		--filterList "~{FilterList}" \
		~{NewHope} \
		~{cngGL} \
		~{customVcf} \
		--mozaicRate "~{MozaicRate}" \
		--mozaicDP "~{MozaicDP}" \
		~{customInfoList} \
		~{affected} \
		--MDAPIkey "~{MdApiKey}" \
		~{favGenRef} \
		~{filtCustVcf} \
		~{filtCustVcfReg} \
		~{idSNP} \
		~{"--gnomadExome " + GnomadExomeFields} \
		~{"--gnomadGenome " + GnomadGenomeFields} \
		~{addCustVCFRegex} \
		~{poolSample} \
		~{addCasDep} \
		~{addCasab} \
		~{poorCov} \
		~{SkipCase} \
		~{HideAcmg}

		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "captainAchab: v$(~{PerlPath} ~{AchabExe} -v | cut -f2 -d ':')" >>	"~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt";
		fi
		conda deactivate
	>>>

	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File outAchab = "~{OutDir}~{SampleID}/~{WorkflowType}/achab_excel/~{SampleID}_achab_catch~{newHopeSuffix}.xlsx"
		File outAchabHtml = "~{OutDir}~{SampleID}/~{WorkflowType}/achab_excel/~{SampleID}~{newHopeSuffix}_achab.html"
		File? outAchabPoorCov = "~{OutDir}~{SampleID}/~{WorkflowType}/achab_excel/~{SampleID}_poorCoverage.xlsx"
	}
}
