version 1.0

#Import section
import "modules/bcftoolsSplit.wdl" as runBcftoolsSplit
import "modules/bcftoolsLeftAlign.wdl" as runBcftoolsLeftAlign
import "modules/bcftoolsNorm.wdl" as runBcftoolsNorm
import "modules/gatkSortVcf.wdl" as runGatkSortVcf
import "modules/achabDirPreparation.wdl" as runAchabDirPreparation
import "modules/achabDirCleanUp.wdl" as runAchabDirCleanUp
import "modules/annovarForMpa.wdl" as runAnnovarForMpa
import "modules/mpa.wdl" as runMpa
import "modules/phenolyzer.wdl" as runPhenolyzer
import "modules/achab.wdl" as runAchab
import "modules/achabFinalCopy.wdl" as runAchabFinalCopy
# import "modules/achabNewHope.wdl" as runAchabNewHope

workflow captainAchab {
	meta {
		author: "David BAUX"
		email: "david.baux(at)chu-montpellier.fr"
		version: "1.2.0"
		date: "2023-09-07"
	}
	input {
		#Variable section
		## conda
		String condaBin
		## envs
		String bcftoolsEnv = "bcftoolsEnv"
		String mpaEnv = "mpaEnv"
		String achabEnv = "achabEnv"
		String rsyncEnv = "rsyncEnv"
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
		String sampleID
		String outTmpDir = "/scratch/tmp_output/"
		String outDir
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
		#String operationSuffix
		#String comma
		## For phenolyzer
		Boolean withPhenolyzer
		String diseaseFile
		## For Achab
		# File mdApiKeyFile
		String genesOfInterest
		String customVCF
		String fatherSample
		String caseSample
		String motherSample
		Float allelicFrequency
		Float mozaicRate
		Float mozaicDP
		String checkTrio
		String customInfo
		String cnvGeneList
		String filterList
		String affected
		String mdApiKey = ''
		String favouriteGeneRef
		String filterCustomVCF
		String filterCustomVCFRegex
		String idSnp = ''
		String gnomadExomeFields = "gnomAD_exome_ALL,gnomAD_exome_AFR,gnomAD_exome_AMR,gnomAD_exome_ASJ,gnomAD_exome_EAS,gnomAD_exome_FIN,gnomAD_exome_NFE,gnomAD_exome_OTH,gnomAD_exome_SAS"
		String gnomadGenomeFields = "gnomAD_genome_ALL,gnomAD_genome_AFR,gnomAD_genome_AMR,gnomAD_genome_ASJ,gnomAD_genome_EAS,gnomAD_genome_FIN,gnomAD_genome_NFE,gnomAD_genome_OTH"
		## For BcftoolsSplit 
		File inputVcf
		## For BcftoolsLeftAlign 
		File fastaGenome
		String vcSuffix = ""
	}
	# Call section
	call runBcftoolsSplit.bcftoolsSplit {
		input: 
			Queue = defQueue,
			CondaBin = condaBin,
			BcftoolsEnv = bcftoolsEnv,
			Cpu = cpu,
			Memory = memory,
			WorkflowType = workflowType, 
			IsPrepared = achabDirPreparation.isPrepared,
			InputVcf = inputVcf,
			BcftoolsExe = bcftoolsExe,
			Version = true,
			SampleID = sampleID,
			OutDir = outTmpDir
	}
	call runBcftoolsLeftAlign.bcftoolsLeftAlign {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			BcftoolsEnv = bcftoolsEnv,
			Cpu = cpu,
			Memory = memory,
			WorkflowType = workflowType,
			BcftoolsExe = bcftoolsExe,
			FastaGenome = fastaGenome,
			SplittedVcf = bcftoolsSplit.outBcfSplit,
			OutDir = outTmpDir,
			SampleID = sampleID
	}
	call runBcftoolsNorm.bcftoolsNorm {
		input:
			Queue = defQueue,
			CondaBin = condaBin,
			BcftoolsEnv = bcftoolsEnv,
			Cpu = cpu,
			Memory = memory,
			WorkflowType = workflowType,
			SampleID = sampleID,
			OutDir = outTmpDir,
			BcftoolsExe = bcftoolsExe,
			VcSuffix = vcSuffix,
			SortedVcf = bcftoolsLeftAlign.outBcfLeftAlign
	}
	call runGatkSortVcf.gatkSortVcf {
		input:
			Queue = defQueue,
			Cpu = cpu,
			Memory = memory,
			WorkflowType = workflowType,
			SampleID = sampleID,
			OutDir = outTmpDir,
			GatkExe = gatkExe,
			Version = true,
			VcSuffix = vcSuffix,
			UnsortedVcf = bcftoolsNorm.normVcf
	}
	call runAchabDirPreparation.achabDirPreparation{
		input:
			Queue = defQueue,
			Cpu = cpu,
			Memory = memory,
			WorkflowType = workflowType,
			SampleID = sampleID,
			OutDir = outTmpDir,
			Version = true,
			InputVcf = inputVcf
	}
	if (!keepFiles) {
		call runAchabDirCleanUp.achabDirCleanUp{
			input:
				Queue = defQueue,
				Cpu = cpu,
				Memory = memory,
				WorkflowType = workflowType,
				SampleID = sampleID,
				OutDir = outDir,
				CopiedAchabVersion = rsyncAchabFiles.copiedAchabVersion,
				# OutPhenolyzer = phenolyzer.outPhenolyzer,
				# OutAchab = achab.outAchabHtml, 
				# OutAchabNewHope = achabNewHope.outAchabHtml,
				Genome = genome
		}
	}
	call runAnnovarForMpa.annovarForMpa {
		input:
			CondaBin = condaBin,
			AchabEnv = achabEnv,
			Queue = defQueue,
			Cpu = cpuHigh,
			Memory = memory,
			WorkflowType = workflowType,
			CustomXref = customXref,
			SortedVcf = gatkSortVcf.sortedVcf,
			RefAnnotateVariation = refAnnotateVariation,
			RefCodingChange = refCodingChange,
			RefConvert2Annovar = refConvert2Annovar,
			RefRetrieveSeqFromFasta = refRetrieveSeqFromFasta,
			RefVariantsReduction = refVariantsReduction,
			TableAnnovarExe = tableAnnovarExe,
			HumanDb = humanDb,
			SampleID = sampleID,
			OutDir = outTmpDir,
			Version = true,
			PerlPath = perlPath,
			Genome = genome
	}
	call runMpa.mpa {
		input:
			CondaBin = condaBin,
			MpaEnv = mpaEnv,
			Queue = defQueue,
			Cpu = cpu,
			Memory = memory,
			WorkflowType = workflowType,
			Version = true,
			MpaExe = mpaExe,
			OutAnnotation = annovarForMpa.outAnnotationVcf,
			SampleID = sampleID,
			OutDir = outTmpDir,
			Genome = genome
	}
	if (withPhenolyzer) {
		call runPhenolyzer.phenolyzer {
			input:
				CondaBin = condaBin,
				AchabEnv = achabEnv,
				Queue = defQueue,
				Cpu = cpu,
				Memory = memory,
				WorkflowType = workflowType,
				Version = true,
				IsPrepared = achabDirPreparation.isPrepared,
				DiseaseFile = diseaseFile,
				PhenolyzerExe = phenolyzerExe,
				SampleID = sampleID,
				OutDir = outTmpDir,
				PerlPath = perlPath
		}
	}	
	call runAchab.achab as achabNewHope {
		input:
			CondaBin = condaBin,
			AchabEnv = achabEnv,
			Queue = defQueue,
			Cpu = cpu,
			Memory = memory,
			WorkflowType = workflowType,
			Version = true,
			AchabExe = achabExe,
			NewHope = "--newHope",
			CnvGeneList = cnvGeneList,
			FilterList = filterList,
			GenesOfInterest = genesOfInterest,
			FatherSample = fatherSample,
			CaseSample = caseSample,
			MotherSample = motherSample,
			OutMpa = mpa.outMpa,
			OutPhenolyzer = phenolyzer.outPhenolyzer,
			AllelicFrequency = allelicFrequency,
			CheckTrio = checkTrio,
			CustomInfo = customInfo,
			SampleID = sampleID,
			OutDir = outTmpDir,
			PerlPath = perlPath,
			CustomVCF = customVCF,
			MozaicRate = mozaicRate,
			MozaicDP = mozaicDP,
			Affected = affected,
			MdApiKey = mdApiKey,
			FavouriteGeneRef = favouriteGeneRef,
			FilterCustomVCF = filterCustomVCF,
			FilterCustomVCFRegex = filterCustomVCFRegex,
			IdSnp = idSnp,
			GnomadExomeFields = gnomadExomeFields,
			GnomadGenomeFields = gnomadGenomeFields
	}
	call runAchab.achab as achab {
		input:
			CondaBin = condaBin,
			AchabEnv = achabEnv,
			Queue = defQueue,
			Cpu = cpu,
			Memory = memory,
			WorkflowType = workflowType,
			AchabExe = achabExe,
			CnvGeneList = cnvGeneList,
			FilterList = filterList,
			GenesOfInterest = genesOfInterest, 
			FatherSample = fatherSample,
			CaseSample = caseSample,
			MotherSample = motherSample,
			OutMpa = mpa.outMpa,
			OutPhenolyzer = phenolyzer.outPhenolyzer,
			AllelicFrequency = allelicFrequency,
			CheckTrio = checkTrio,
			CustomInfo = customInfo,
			SampleID = sampleID,
			OutDir = outTmpDir,
			PerlPath = perlPath,
			CustomVCF = customVCF,
			MozaicRate = mozaicRate,
			MozaicDP = mozaicDP,
			Affected = affected,
			MdApiKey = mdApiKey,
			FavouriteGeneRef = favouriteGeneRef,
			FilterCustomVCF = filterCustomVCF,
			FilterCustomVCFRegex = filterCustomVCFRegex,
			IdSnp = idSnp,
			GnomadExomeFields = gnomadExomeFields,
			GnomadGenomeFields = gnomadGenomeFields
	}
	call runAchabFinalCopy.rsyncAchabFiles as rsyncAchabFiles {
		input:
			CondaBin = condaBin,
			RsyncEnv = rsyncEnv,
			Queue = defQueue,
			Cpu = cpu,
			Memory = memory,
			WorkflowType = workflowType,
			SampleID = sampleID,
			Version = true,
			RsyncExe = rsyncExe,
			OutTmpDir = outTmpDir,
			OutDir = outDir,
			OutPhenolyzer = phenolyzer.outPhenolyzer,
			OutAchab = achab.outAchabHtml, 
			OutAchabNewHope = achabNewHope.outAchabHtml
	}
	output {
		File achabHtml = achab.outAchabHtml
		File achabNewHopeHtml = achabNewHope.outAchabHtml
	}
}
