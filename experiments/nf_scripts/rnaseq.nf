import groovy.time.TimeCategory 
import groovy.time.TimeDuration

include { FASTQC_NO_LIMIT as FASTQC } from params.tool_dir + "/fastqc.nf"
include { TRIMMOMATIC_LIMIT_16c as TRIMMOMATIC } from params.tool_dir + "/trimmomatic.nf"
include { PICARD_COLLECTRNAMETRICS as PICARD_COLLECTRNAMETRICS } from params.tool_dir + "/picard_collectrnametrics.nf"
include { SAMTOOLS_IDXSTAT as SAMTOOLS_IDXSTAT } from params.tool_dir + "/samtools_idxstat.nf"
include { SAMTOOLS_FLAGSTAT as SAMTOOLS_FLAGSTAT } from params.tool_dir + "/samtools_flagstat.nf"
include { SAMTOOLS_STAT as SAMTOOLS_STAT } from params.tool_dir + "/samtools_stat.nf"
include { SAMTOOLS_SAM2BAM as SAMTOOLS_SAM2BAM } from params.tool_dir + "/samtools_sam2bam.nf"
include { SAMTOOLS_SORT_NO_LIMIT as SAMTOOLS_SORT } from params.tool_dir + "/samtools_sort.nf"
include { SAMTOOLS_INDEX_NO_LIMIT as SAMTOOLS_INDEX } from params.tool_dir + "/samtools_index.nf"
include { STAR_NO_LIMIT_SIMPLE as STAR } from params.tool_dir + "/star.nf"

Date loadStart = new Date()
println ("Data loading started ...")

/* Reference files */
REF_PATH = params.ref_dir
ref_fa = Channel.fromPath(REF_PATH + '/*.fa')
ref_amb = Channel.fromPath(REF_PATH + '/*.amb')
ref_ann = Channel.fromPath(REF_PATH + '/*.ann')
ref_bwt = Channel.fromPath(REF_PATH + '/*.bwt')
ref_fai = Channel.fromPath(REF_PATH + '/*.fai')
ref_pac = Channel.fromPath(REF_PATH + '/*.pac')
ref_sa = Channel.fromPath(REF_PATH + '/*.sa')
ref_dict = Channel.fromPath(REF_PATH + '/*.dict')
genome_dir = Channel.fromPath(REF_PATH + '/star-2.7.5c_GRCh38.d1.vd1_gencode.v36')
gene_info = Channel.fromPath(REF_PATH + '/gencode.v36.by-gene_exon_lengthsums.tsv')
ref_flat = Channel.fromPath(REF_PATH + '/gencode.v36.annotation.refFlat')
ribosome_intervals = Channel.fromPath(REF_PATH + '/gencode.v36.annotation.ribosomal_ranges')


/* Config */
READ_PATH = params.read_dir + "/star/"
meta_id = Channel.of(READ_PATH.tokenize('/')[-1])
/* Input files */
fastq_pair = Channel.fromFilePairs(
                    READ_PATH + '/SRR*_{1,2}.{1,2}.fastq', flat: true)
                    // .splitFastq(by: 3000000, limit:3000000, pe:true, file: true)

/* Per application runtime parameters */
/* ... */
sam2bam_threads = 16
ssort_threads = 16
sindex_threads = 16

workflow {
    fastq_pair.view {
        "Input files: ${it}, num_files=${it.size()}"
    }.subscribe {
        Date loadEnd = new Date()

        TimeDuration td = TimeCategory.minus(loadEnd, loadStart)

        def logFile = new File("LoadDuration.txt")
        logFile.delete()
        logFile.append(td)
        println ("Loading done! Took " + td)
    }
    FASTQC(
        fastq_pair
    )
    TRIMMOMATIC(
        fastq_pair
    )

    STAR(
        TRIMMOMATIC.out.OUTPUT_PAIRED, genome_dir
    )

    SAMTOOLS_SAM2BAM(
        STAR.out.genomic_sam,
        sam2bam_threads
    )

    SAMTOOLS_SORT(
        SAMTOOLS_SAM2BAM.out.bam,
        ssort_threads
    )

    SAMTOOLS_INDEX(
        SAMTOOLS_SORT.out.sorted_bam,
        sindex_threads
    )

    SAMTOOLS_IDXSTAT(
        SAMTOOLS_SORT.out.sorted_bam,
        SAMTOOLS_INDEX.out.bam_index
    )

    SAMTOOLS_STAT(
        SAMTOOLS_SORT.out.sorted_bam,
        SAMTOOLS_INDEX.out.bam_index,
    )

    SAMTOOLS_FLAGSTAT(
        SAMTOOLS_SORT.out.sorted_bam,
    )

    PICARD_COLLECTRNAMETRICS(
        SAMTOOLS_SORT.out.sorted_bam,
        SAMTOOLS_INDEX.out.bam_index,
        ref_flat,
        ribosome_intervals
    )



}