import groovy.time.TimeCategory 
import groovy.time.TimeDuration

process SAMTOOLS_MPILEUP {
    container "ghcr.io/martinluttap/samtools:1.9"

    input:
        path normal_bam
        path tumor_bam
        path reference_file
    output:
        path "tn_pair.mpileup", emit: pileup_file

    script:
        """
        samtools mpileup -f ${reference_file} ${normal_bam} ${tumor_bam} > tn_pair.mpileup
        """
}

process VARSCAN_SOMATIC {
    container "ghcr.io/martinluttap/varscan:2.4.6"

    input:
        path pileup_file
        val prefix
    output:
        path "${prefix}.output.vcf.snp", emit: snp_vcf
        path "${prefix}.output.vcf.indel", emit: indel_vcf

    script:
        """
        java -jar /usr/local/bin/varscan.jar somatic ${pileup_file} ${prefix}.output.vcf --mpileup 1 --output-vcf 1
        """
}

process UPDATE_SEQ_DICT {
    container "ghcr.io/martinluttap/picard:2.26.10"

    input: 
        path vcf_file
        path dict_file
    
    output:
        path "${vcf_file.baseName}.upseqdict.vcf", emit: updated_vcf
    
    script:
        """
        java -jar /usr/local/bin/picard.jar UpdateVcfSequenceDictionary --INPUT ${vcf_file} --SEQUENCE_DICTIONARY ${dict_file} --OUTPUT ${vcf_file.baseName}.upseqdict.vcf
        """
}

Date loadStart = new Date()
println ("Data loading started ...")

/* Reference files */
REF_PATH = params.ref_dir
ref_fa = REF_PATH + '/GRCh38.d1.vd1.fa'
ref_amb = REF_PATH + '/GRCh38.d1.vd1.amb'
ref_ann = REF_PATH + '/GRCh38.d1.vd1.ann'
ref_bwt = REF_PATH + '/GRCh38.d1.vd1.bwt'
ref_fai = REF_PATH + '/GRCh38.d1.vd1.fai'
ref_pac = REF_PATH + '/GRCh38.d1.vd1.pac'
ref_sa = REF_PATH + '/GRCh38.d1.vd1.sa'
ref_dict = REF_PATH + '/GRCh38.d1.vd1.dict'
ref_known_sites = REF_PATH + '/dbsnp_144.hg38.vcf.gz'
ref_known_sites_tbi = REF_PATH + '/dbsnp_144.hg38.vcf.gz.tbi'

/* Input files */
READ_PATH = params.read_dir + "/bams/1500MB/"
tumor_bam = Channel.fromPath(READ_PATH + 'chr1.bam')
normal_bam = Channel.fromPath(READ_PATH + 'chr2.bam')

workflow {
    SAMTOOLS_MPILEUP(
        normal_bam,
        tumor_bam,
        ref_fa        
    )
    VARSCAN_SOMATIC(
        SAMTOOLS_MPILEUP.out.pileup_file,
        "varscan_somatic"
    )
    UPDATE_SEQ_DICT(
        VARSCAN_SOMATIC.out.snp_vcf,
        ref_dict
    )
}
