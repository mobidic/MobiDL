version 1.0

task associateBams2Related {
	input {
		Array[Pair[String,Array[String]]] associateSample2Related
		Array[Pair[String, Pair[String,String]]] alignmentsFiles
	}

	command <<<

		python <<CODE
		import json

		# Function to read json
		def read_json_file(path):
			with open(path, 'r') as fd:
				data = fd.read()
				d = json.loads(data)
				return d

		# Read variable as json
		aligns = read_json_file("~{write_json(alignmentsFiles)}")
		assoc = read_json_file("~{write_json(associateSample2Related)}")

		# Init variable
		final = list()

		# Loop over associated elements (sample - parents (optional))
		for values in assoc:
			# Get sample name and parents
			sample = values["left"]
			parents = values["right"]
			# Init variable for the sample
			sampledict = dict()
			sampledict["left"] = sample
			sampledict["right"] = dict()
			sampledict["right"]["right"] = dict()
			sampledict["right"]["right"]["right"] = list()
			sampledict["right"]["right"]["left"] = list()
			# Loop over alignments files with name associated
			for align in aligns:
				if align["left"] == sample:
					# Add bam and index as Pair (compatibility for WDL)
					sampledict["right"]["left"] = align["right"]
					break

			# Loop over parents
			for p in parents:
				for align in aligns:
					if align["left"] == p:
						# Add bam & bai to array
						sampledict["right"]["right"]["left"].append(align["right"]["left"])
						sampledict["right"]["right"]["right"].append(align["right"]["right"])
			# Add sample to final array
			final.append(sampledict)

		# Print as json to WDL compatibility
		print(json.dumps(final))
		CODE

	>>>

	output {
		Array[Pair[String,Pair[Pair[String,String],Pair[Array[String],Array[String]]]]] bamsAssociated = read_json(stdout())
	}
}
