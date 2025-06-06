version 1.0

task identito {
	meta {
		author: "Felix VANDERMEEREN"
		email: "felix.vandermeeren(at)chu-montpellier.fr"
		version: "0.1.1"
		date: "2025-05-21"
	}
	input {
		# env variables	
		String CondaBin
		String BcftoolsEnv
		# global variables
		String SampleID
		String OutDir
		String WorkflowType
		String CsvtkExe
		Boolean Version = false
		# task specific variables
		File VcfFile
		String IDlist
		#runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	# MEMO: If 'sampleName' in filename, MultiQC create separate tables, instead of 1 gathered
	String OutputFile = "~{OutDir}~{SampleID}/~{WorkflowType}/PicardQualityDir/Identito_mqc.tsv"
	command <<<
		set -e  # To make task stop at 1st error
		source ~{CondaBin}activate ~{BcftoolsEnv}
		# 1) Query by 'ID' field (PROS: independant from genome version)
		snpListFile=snpIDs.list
		tempFile=queried.tsv
		echo "~{IDlist}" | tr ',' '\n' > "$snpListFile"
		bcftools query \
			--include 'ID==@snpIDs.list' \
			--format '%ID[\t%GT]\n' \
			"~{VcfFile}" > "$tempFile"
		# MEMO: If NO identito found -> add at least 1 dummy row, for join at (2) to work even though
		if [[ "$(cat "$tempFile" | wc -l)" -eq "0" ]] ; then
			(echo "rsID"; bcftools query --list-samples "~{VcfFile}") |
				"~{CsvtkExe}" transpose --tabs -o "$tempFile"
		fi
		# 2) Join (on rsID) with list of expected identito SNP, to enforce 'Not found':
		debugFinal=finalDebug.tsv
		"~{CsvtkExe}" join \
			--tabs --no-header-row \
			--left-join --na "0/0" \
			--fields 1 \
			-o "$debugFinal" \
			"$snpListFile" "$tempFile"
		# 3) Add header, sort rsID (to match GeneMapper order) and transpose (to have format complient with MultiQC):
		"~{CsvtkExe}" add-header "$debugFinal" \
			--tabs \
			--names rsID,"$(bcftools query --list-samples "~{VcfFile}" | "~{CsvtkExe}" transpose)" |
			"~{CsvtkExe}" sort \
				--tabs \
				--keys rsID:u --levels rsID:"$snpListFile" |
				"~{CsvtkExe}" transpose \
					--tabs \
					-o "~{OutputFile}"
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File outIdent = OutputFile
	}
}
