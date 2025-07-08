process SAMTOOLS_IDXSTAT {
    container "ghcr.io/martinluttap/samtools:1.9"

    input:
        path bam
		path bam_index
		
    output:
        path "${bam.baseName}.idxstat"	, emit: output
		
    script:
        
        """
        samtools idxstats   ${bam} > ${bam.baseName}.idxstat
        """
        
}