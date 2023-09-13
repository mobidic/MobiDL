version 1.0

task annovarForMpa {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-07"
	}
	input {
		# env variables	
		String CondaBin
		String AchabEnv
		# global variables
		File CustomXref
		File SortedVcf
		File RefAnnotateVariation
		File RefCodingChange
		File RefConvert2Annovar
		File RefRetrieveSeqFromFasta
		File RefVariantsReduction
		File TableAnnovarExe
		String WorkflowType
		String HumanDb
		String SampleID
		String OutDir
		String PerlPath
		Boolean Version = true 
		# databases
		String Genome
		Int IntronHgvs = 80
		String Clinvar = 'clinvar_latest'
		String Dbnsfp
		String Dbscsnv
		String GnomadExome
		String GnomadGenome
		String PopFreqMax
		String Intervar
		String SpliceAI
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		OPERATION_SUFFIX=',f'
		COMMA=','
		POPFREQMAX=',~{PopFreqMax}'
		#REFGENE='refGeneWithVer'
		if [ ~{Genome} == 'hg38' ];then
			OPERATION_SUFFIX=''
			COMMA=''
			POPFREQMAX=''
			#REFGENE='refGene'
		fi
		if [[ "~{Clinvar}" == 'clinvar_latest' ]] && [[ -f "~{HumanDb}/~{Genome}_clinvar_latest.ver" ]]; then
			mkdir "~{OutDir}~{SampleID}/~{WorkflowType}/admin"
			cp "~{HumanDb}/~{Genome}_clinvar_latest.ver" "~{OutDir}~{SampleID}/~{WorkflowType}/admin/"
			cat "~{HumanDb}/~{Genome}_clinvar_latest.ver" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt";
		fi
		source ~{CondaBin}activate ~{AchabEnv}
		"~{PerlPath}" "~{TableAnnovarExe}" \
		"~{SortedVcf}" \
		"~{HumanDb}" \
		-thread "~{Cpu}" \
		-buildver "~{Genome}" \
		-out "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}" \
		-remove \
		-intronhgvs "~{IntronHgvs}" \
		-protocol refGeneWithVer,refGeneWithVer,refGeneWithVer,"~{Clinvar}","~{Dbnsfp}","~{Dbscsnv}","~{GnomadExome}","~{GnomadGenome}","~{Intervar}",regsnpintron,"~{SpliceAI}""${POPFREQMAX}" \
		-operation gx,g,g,f,f,f,f,f,f,f,f"${OPERATION_SUFFIX}" \
		-nastring . \
		-vcfinput \
		-otherinfo \
		-arg '-splicing 5','-hgvs','-memtotal ~{Memory}000',,,,,,,,"${COMMA}" \
		-xref "~{CustomXref}"
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "ANNOVAR: v$(~{PerlPath} ~{TableAnnovarExe} -h | grep Version | cut -f3 -d ':' | cut -f2 -d ' ')" >>  "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt";
		fi
		conda deactivate
 	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File outAnnotationVcf = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.~{Genome}_multianno.vcf"
		File outAnnotationAvinput = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.avinput"
		File outAnnotationTxt = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.~{Genome}_multianno.txt"
	}
}
