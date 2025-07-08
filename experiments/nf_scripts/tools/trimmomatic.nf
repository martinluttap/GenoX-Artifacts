process TRIMMOMATIC_NO_LIMIT {
    container "ghcr.io/martinluttap/trimmomatic:0.38"

    input:
        tuple val(meta), path(forward_fastq), path(reverse_fastq)
		
    script:
        """
        java -Xmx32G -jar /bin/trimmomatic.jar PE -threads 96 ${forward_fastq} ${reverse_fastq} -baseout ${forward_fastq.getBaseName()}.out TOPHRED33
        """        
}

process TRIMMOMATIC_LIMIT_16c {
    container "ghcr.io/martinluttap/trimmomatic:0.38"

    input:
        tuple val(meta), path(forward_fastq), path(reverse_fastq)
		
    output:
        tuple val(meta), path("*.out_1P"), path ("*.out_2P"), emit: OUTPUT_PAIRED

    script:
        """
        java -Xmx32G -jar /bin/trimmomatic.jar PE -threads 16 ${forward_fastq} ${reverse_fastq} -baseout ${forward_fastq.getBaseName()}.out TOPHRED33
        """        
}