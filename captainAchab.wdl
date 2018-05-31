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
  String srunLow
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
  ## From phenolyzer
  File diseaseFile
  ## From captainAchab
  Boolean newHope
  File genesOfInterest
  String fatherSample
  String caseSample
  String motherSample
  Float allelicFrequency
  String checkTrio
  String customInfo
  ## From BcftoolsSplit 
  File inputVcf
  ## From BcftoolsLeftAlign 
  File fastaGenome

  #Call section

  call runBcftoolsSplit.bcftoolsSplit {
    input: 
    SrunLow = srunLow,
    WorkflowType = workflowType, 
    IsPrepared = achabDirPreparation.isPrepared, 
    InputVcf = inputVcf, 
    BcftoolsExe = bcftoolsExe, 
    SampleID = sampleID, 
    OutDir = outDir
  }

  call runBcftoolsLeftAlign.bcftoolsLeftAlign {
    input:
    SrunLow = srunLow, 
    WorkflowType = workflowType, 
    BcftoolsExe = bcftoolsExe, 
    FastaGenome = fastaGenome, 
    SplittedVcf = bcftoolsSplit.outBcfSplit, 
    OutDir = outDir, 
    SampleID = sampleID
  }

  call runBcftoolsNorm.bcftoolsNorm {
    input: 
    SrunLow = srunLow, 
    WorkflowType = workflowType, 
    SampleID = sampleID, 
    OutDir = outDir, 
    BcfToolsExe = bcftoolsExe, 
    SortedVcf = bcftoolsLeftAlign.outBcfLeftAlign
  }

  call runGatkSortVcf.gatkSortVcf {
    input:
    SrunLow = srunLow, 
    WorkflowType = workflowType, 
    SampleID = sampleID, 
    OutDir = outDir, 
    GatkExe = gatkExe, 
    UnsortedVcf = bcftoolsNorm.normVcf
  }

  call runAchabDirPreparation.achabDirPreparation{
    input:
    WorkflowType = workflowType,
    SampleID = sampleID,
    OutDir = outDir,
    PhenolyzerExe = phenolyzerExe,
    InputVcf = inputVcf
  }

  if (!keepFiles) {

    call runAchabDirCleanUp.achabDirCleanUp{
      input:
      WorkflowType = workflowType,
      SampleID = sampleID,
      OutDir = outDir,
      PhenolyzerExe = phenolyzerExe,
      OutPhenolyzer = phenolyzer.outPhenolyzer,
      OutAchab = achab.outAchab, 
      OutAchabNewHope = achabNewHope.outAchabNewHope
    }
  }
  
  call runAnnovarForMpa.annovarForMpa {
    input:
    SrunLow = srunLow, 
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
    PerlPath = perlPath
  }

  call runMpa.mpa {
    input:
    SrunLow = srunLow, 
    WorkflowType = workflowType, 
    MpaExe = mpaExe,
    OutAnnotation = annovarForMpa.outAnnotationVcf,
    SampleID = sampleID,
    OutDir = outDir,
    PythonPath = pythonPath
  }

  call runPhenolyzer.phenolyzer {
    input:
    SrunLow = srunLow, 
    WorkflowType = workflowType, 
    IsPrepared = achabDirPreparation.isPrepared,
    DiseaseFile = diseaseFile,
    PhenolyzerExe = phenolyzerExe,
    SampleID = sampleID,
    OutDir = outDir,
    PerlPath = perlPath
  }
  call runAchabNewHope.achabNewHope {
    input:
    SrunLow = srunLow, 
    WorkflowType = workflowType, 
    AchabExe = achabExe,
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
    PerlPath = perlPath
   }

  call runAchab.achab {
     input:
     SrunLow = srunLow, 
     WorkflowType = workflowType, 
     AchabExe = achabExe,
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
     PerlPath = perlPath
  }
}
