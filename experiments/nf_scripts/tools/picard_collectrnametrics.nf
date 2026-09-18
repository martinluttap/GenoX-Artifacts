process PICARD_COLLECTRNAMETRICS {
    container "ghcr.io/martinluttap/picard:2.26.10"

    input:
		path input
        path input_secondary_files
		path ref_flat
		path ribosome_intervals
		
    output:
	    path "${input.baseName}.metrics"	, emit: metrics_output
	
    script:
        """
        java -jar /usr/local/bin/picard.jar  CollectRnaSeqMetrics INPUT=${input} OUTPUT=${input.baseName}.metrics REF_FLAT=${ref_flat} RIBOSOMAL_INTERVALS=${ribosome_intervals} METRIC_ACCUMULATION_LEVEL=ALL_READS MINIMUM_LENGTH=500 RRNA_FRAGMENT_PERCENTAGE=0.8 STOP_AFTER=0 STRAND_SPECIFICITY=NONE TMP_DIR='.' ASSUME_SORTED=true """
}