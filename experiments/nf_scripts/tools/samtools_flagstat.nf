process SAMTOOLS_FLAGSTAT {
    container "ghcr.io/martinluttap/samtools:1.9"

    input:
        path bam
		
    output:
        path "${bam.baseName}.flagstat"	, emit: output
		
    script:
        
        """
        samtools flagstat   ${bam} > ${bam.baseName}.flagstat
        """
        
}