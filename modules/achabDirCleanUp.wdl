version 1.0

task achabDirCleanUp {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-07"
	}
	input {
		# global variables
		String WorkflowType
		String SampleID
		String OutDir
		# task specific variables
		String CopiedAchabVersion
		# String? OutPhenolyzer
		# File OutAchab
		# File OutAchabNewHope
		String Genome
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		if [ -d "~{OutDir}/bcftools" ]; then \
			rm -rf "~{OutDir}/bcftools"; \
		fi
		if [ -d "~{OutDir}/disease" ]; then \
			rm -rf "~{OutDir}/disease"; \
		fi
		if [ -f "~{OutDir}/~{SampleID}.avinput" ]; then \
			rm "~{OutDir}/~{SampleID}.avinput"; \
		fi
		if [ -f "~{OutDir}/~{SampleID}.~{Genome}_multianno.txt" ]; then \
			rm "~{OutDir}/~{SampleID}.~{Genome}_multianno.txt"; \
		fi
		if [ -f "~{OutDir}/~{SampleID}.~{Genome}_multianno.vcf" ]; then \
			rm "~{OutDir}/~{SampleID}.~{Genome}_multianno.vcf"; \
		fi
		if [ -f "~{OutDir}/~{SampleID}.sorted.vcf" ]; then \
			rm "~{OutDir}/~{SampleID}.sorted.vcf"; \
		fi
		if [ -f "~{OutDir}/~{SampleID}.sorted.vcf.idx" ]; then \
			rm "~{OutDir}/~{SampleID}.sorted.vcf.idx"; \
		fi
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		Boolean isRemoved = true
	}
}
