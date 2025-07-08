process SAMTOOLS_STAT {
    container "ghcr.io/martinluttap/samtools:1.9"

    input:
        path bam
		path bam_index
		
    output:
        path "${bam.baseName}.samtools_stats"	, emit: output
		
    script:
        """
        samtools stats  ${bam} > ${bam.baseName}.samtools_stats
        """
        
}