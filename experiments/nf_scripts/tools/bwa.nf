process BWA_PE_LIMIT_NUMTHREADS {
    container "ghcr.io/martinluttap/bwa:0.7.15-554c2eb"

    input:
        tuple val(meta), path(forward_fastq), path(reverse_fastq)
        path ref_fa
        path ref_amb
        path ref_ann
        path ref_bwt
        path ref_fai
        path ref_pac
        path ref_sa
        path ref_dict
        val num_threads

    output:
        path "*.bam", emit: bam

    script: 
        METADATA = "\"@RG\\tID:SRR24039108\\tPL:ILLUMINA\\tSM:Sample\""
        """
        bwa mem -t ${num_threads} -T 0 ${ref_fa} ${forward_fastq} ${reverse_fastq} | samtools view -Shb -o SRR24039108.bam -
        """
}

process BWA_SE_LIMIT_NUMTHREADS {
    container "ghcr.io/martinluttap/bwa:0.7.15-554c2eb"

    input:
        path fastq
        path ref_fa
        path ref_amb
        path ref_ann
        path ref_bwt
        path ref_fai
        path ref_pac
        path ref_sa
        path ref_dict
        val num_threads

    output:
        path "*.bam", emit: bam

    script: 
        """
        bwa aln -I -t ${num_threads} ${ref_fa} ${fastq} > aln.sai && bwa samse -n 3 ${ref_fa} aln.sai ${fastq} | samtools view -Shb -o out.bam -
        """
}