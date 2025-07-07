import groovy.time.TimeCategory 
import groovy.time.TimeDuration

include { BWA_LIMIT_NUMTHREADS as BWA_PE } from params.tool_dir + "/bwa.nf"
include { FASTQC_NO_LIMIT as FASTQC } from params.tool_dir + "/fastqc.nf"
include { GATK4_APPLYBQSR as GATK_APPLYBQSR } from params.tool_dir + "/gatk_applybqsr.nf"
include { GATK4_BASERECAL_SPARK_16c as GATK_BASERECAL } from params.tool_dir + "/gatk_baserecal.nf"
include { PICARD_COLLECTWGSMETRICS as PICARD_COLLECTWGSMETRICS } from params.tool_dir + "/picard_collectwgsmetrics.nf"
include { PICARD_COLLECT0XOGMETRICS as PICARD_COLLECT0XOGMETRICS } from params.tool_dir + "/picard_collect0xogmetrics.nf"
include { PICARD_MARKDUPLICATES as PICARD_MARKDUPLICATES } from params.tool_dir + "/picard_markduplicates.nf"
include { PICARD_VALIDATESAMFILE as PICARD_VALIDATESAMFILE } from params.tool_dir + "/picard_validatesamfile.nf"
include { SAMTOOLS_INDEX_NO_LIMIT as SAMTOOLS_INDEX } from params.tool_dir + "/samtools_index.nf"
include { SAMTOOLS_SORT_NO_LIMIT as SAMTOOLS_SORT } from params.tool_dir + "/samtools_sort.nf"



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
ref_known_sites = Channel.fromPath(REF_PATH + '/*.vcf.gz')
ref_known_sites_tbi = Channel.fromPath(REF_PATH + '/*.vcf.gz.tbi')

/* Input files */
READ_PATH = params.read_dir + "/SRR24039108/SRR24039108_1.fastq.split"
// fastq_files = Channel.fromFilePairs(READ_PATH + '/SRR*_{1,2}.part_001.fastq', flat:true)
fastq_files = Channel.fromFilePairs(READ_PATH + '/SRR24039108_{1,2}.part_001.fastq', flat:true)
fastq_files_bulk = fastq_files.collect()
// fastq_files_bulk = Channel.fromPath(READ_PATH + '/SRR*_1.part_{001,002,003,004,005,006,007,008,009,010,011,012,013,014,015,016,017,018,019,020,021,022,023,024,025,026,027,028,029,030,031,032,033,034,035,036,037,038,039,040,041,042,043,044,045,046,047,048,049,050,051,055,053,054,055,056,057,058,059,060,061,062,063}.fastq').collect()

/* Per application runtime parameters */
/* ... */
bwa_numthreads = 16
ssort_numthreads = 16
sindex_numthreads = 16

workflow {
    fastq_files.view {
        "Input files: ${it}, num_files=${it.size()}"
    }.subscribe {
        Date loadEnd = new Date()

        TimeDuration td = TimeCategory.minus(loadEnd, loadStart)

        def logFile = new File("LoadDuration.txt")
        logFile.delete()
        logFile.append(td)
        println ("Loading done! Took " + td)
    }

    // FASTQ_CLEANER()

    FASTQC(
        fastq_files_bulk
    )
    BWA_PE(
        fastq_files_bulk, 
        ref_fa, ref_amb, ref_ann, ref_bwt, ref_fai, ref_pac, ref_sa, ref_dict,
        bwa_numthreads
    )
    PICARD_MARKDUPLICATES(
        BWA_PE.out.bam
    )
    SAMTOOLS_SORT(
        PICARD_MARKDUPLICATES.out.outbam,
        ssort_numthreads
    )
    SAMTOOLS_INDEX(
        SAMTOOLS_SORT.out.sorted_bam,
        sindex_numthreads
    )
    GATK_BASERECAL(
        SAMTOOLS_SORT.out.sorted_bam,
        // SAMTOOLS_INDEX.out.bam_index,
        ref_known_sites, ref_known_sites_tbi, ref_fa, ref_amb, ref_ann, ref_bwt, ref_fai, ref_pac, ref_sa, ref_dict
    )
    GATK_APPLYBQSR(
        SAMTOOLS_SORT.out.sorted_bam,
        SAMTOOLS_INDEX.out.bam_index,
        GATK_BASERECAL.out.output_grp
    )
    PICARD_VALIDATESAMFILE(
        GATK_APPLYBQSR.out.out_bam,
        SAMTOOLS_INDEX.out.bam_index
    )
    PICARD_COLLECTWGSMETRICS(
        GATK_APPLYBQSR.out.out_bam,
        SAMTOOLS_INDEX.out.bam_index,
        ref_fa, ref_amb, ref_ann, ref_bwt, ref_fai, ref_pac, ref_sa, ref_dict
    )
    PICARD_COLLECT0XOGMETRICS(
        GATK_APPLYBQSR.out.out_bam,
        SAMTOOLS_INDEX.out.bam_index,
        ref_known_sites, ref_known_sites_tbi,
        ref_fa, ref_amb, ref_ann, ref_bwt, ref_fai, ref_pac, ref_sa, ref_dict
    )
}