process SAMTOOLS_INDEX_NO_LIMIT {
    container "ghcr.io/martinluttap/samtools:1.9"

    input:
      path input_bam
      val num_threads 

    output:
      path "${input_bam.getBaseName()}.bai", emit: bam_index

    script:
      """
      samtools index  -@ ${num_threads} ${input_bam} > ${input_bam.getBaseName()}.bai
      """
}
