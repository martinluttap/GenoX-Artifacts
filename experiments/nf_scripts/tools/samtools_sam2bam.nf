process SAMTOOLS_SAM2BAM {
    container "ghcr.io/martinluttap/samtools:1.9"

    input:
        path input_sam
		val threads
		
    output:
        path "${input_sam.getBaseName()}.bam"	, emit: bam

    script:
        
        """
        samtools view -b  ${input_sam} -@ ${threads} -o ${input_sam.getBaseName()}.bam 
        """
}