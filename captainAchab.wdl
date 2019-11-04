#Import section
import "modules/achabDirPreparation.wdl" as runAchabDirPreparation
import "modules/achabDirCleanUp.wdl" as runAchabDirCleanUp
import "modules/annovarForMpa.wdl" as runAnnovarForMpa
import "modules/mpa.wdl" as runMpa
import "modules/phenolyzer.wdl" as runPhenolyzer
import "modules/achab.wdl" as runAchab
import "modules/achabNewHope.wdl" as runAchabNewHope
import "modules/bcftoolsSplit.wdl" as runBcftoolsSplit
import "modules/bcftoolsLeftAlign.wdl" as runBcftoolsLeftAlign
import "modules/bcftoolsNorm.wdl" as runBcftoolsNorm
import "modules/gatkSortVcf.wdl" as runGatkSortVcf

workflow captainAchab {

  #Variable section
	##Resources
	Int cpu
	Int memory
	## Language Path
  String perlPath
  String pythonPath
  ## Exe
  File achabExe
  File mpaExe
  String phenolyzerExe
  File tableAnnovarExe
  File bcftoolsExe
  File gatkExe
  ## Global
  String workflowType
  String sampleID
  String outDir
  Boolean keepFiles
  ## From annovarForMpa
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
  ## From phenolyzer
  Boolean withPhenolyzer
  String diseaseFile
  ## From Achab
  Boolean newHope
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
  ## From BcftoolsSplit 
  File inputVcf
  ## From BcftoolsLeftAlign 
  File fastaGenome
	String vcSuffix = ""

  #Call section

  call runBcftoolsSplit.bcftoolsSplit {
    input: 
    Cpu = cpu,
		Memory = memory,
    WorkflowType = workflowType, 
    IsPrepared = achabDirPreparation.isPrepared, 
    InputVcf = inputVcf, 
    BcftoolsExe = bcftoolsExe, 
    SampleID = sampleID, 
    OutDir = outDir
  }

  call runBcftoolsLeftAlign.bcftoolsLeftAlign {
    input:
    Cpu = cpu,
		Memory = memory,
    WorkflowType = workflowType, 
    BcftoolsExe = bcftoolsExe, 
    FastaGenome = fastaGenome, 
    SplittedVcf = bcftoolsSplit.outBcfSplit, 
    OutDir = outDir, 
    SampleID = sampleID
  }

  call runBcftoolsNorm.bcftoolsNorm {
    input: 
    Cpu = cpu,
		Memory = memory,
    WorkflowType = workflowType, 
    SampleID = sampleID, 
    OutDir = outDir, 
    BcfToolsExe = bcftoolsExe, 
		VcSuffix = vcSuffix,
    SortedVcf = bcftoolsLeftAlign.outBcfLeftAlign
  }

  call runGatkSortVcf.gatkSortVcf {
    input:
    Cpu = cpu,
		Memory = memory,
    WorkflowType = workflowType, 
    SampleID = sampleID, 
    OutDir = outDir, 
    GatkExe = gatkExe,
		VcSuffix = vcSuffix,
    UnsortedVcf = bcftoolsNorm.normVcf
  }

  call runAchabDirPreparation.achabDirPreparation{
    input:
    Cpu = cpu,
		Memory = memory,
    WorkflowType = workflowType,
    SampleID = sampleID,
    OutDir = outDir,
    PhenolyzerExe = phenolyzerExe,
    InputVcf = inputVcf
  }

  if (!keepFiles) {

    call runAchabDirCleanUp.achabDirCleanUp{
      input:
			Cpu = cpu,
			Memory = memory,
      WorkflowType = workflowType,
      SampleID = sampleID,
      OutDir = outDir,
      PhenolyzerExe = phenolyzerExe,
      OutPhenolyzer = phenolyzer.outPhenolyzer,
      OutAchab = achab.outAchab, 
      OutAchabNewHope = achabNewHope.outAchabNewHope,
			Genome = genome
    }
  }
  call runAnnovarForMpa.annovarForMpa {
    input:
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
    OutDir = outDir,
    PerlPath = perlPath,
		Genome = genome
  }

  call runMpa.mpa {
    input:
		Cpu = cpu,
		Memory = memory,
    WorkflowType = workflowType, 
    MpaExe = mpaExe,
    OutAnnotation = annovarForMpa.outAnnotationVcf,
    SampleID = sampleID,
    OutDir = outDir,
    PythonPath = pythonPath,
		Genome = genome
  }

  if (withPhenolyzer) {
    call runPhenolyzer.phenolyzer {
      input:
			Cpu = cpu,
			Memory = memory,
      WorkflowType = workflowType, 
      IsPrepared = achabDirPreparation.isPrepared,
      DiseaseFile = diseaseFile,
      PhenolyzerExe = phenolyzerExe,
      SampleID = sampleID,
      OutDir = outDir,
      PerlPath = perlPath
    }

  }

  
  call runAchabNewHope.achabNewHope {
    input:
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
    OutDir = outDir,
    PerlPath = perlPath,
    CustomVCF = customVCF,
    MozaicRate = mozaicRate,
    MozaicDP = mozaicDP
   }

  call runAchab.achab {
		input:
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
    OutDir = outDir,
    PerlPath = perlPath,
    CustomVCF = customVCF,
    MozaicRate = mozaicRate,
    MozaicDP = mozaicDP
  }
}
