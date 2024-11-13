import groovy.time.TimeCategory 
import groovy.time.TimeDuration

TOOL_PATH = params.tool_dir  + "gatk_applybqsr.nf"

include { GATK4_APPLYBQSR as APPLYBQSR_DEF1 } from TOOL_PATH
include { GATK4_APPLYBQSR_SPARK_NO_LIMIT as APPLYBQSR_SPARK1 } from TOOL_PATH

Date loadStart = new Date()
println ("Data loading started ...")

REF_PATH = params.ref_dir
ref_known_sites = Channel.fromPath(REF_PATH + '/*.vcf.gz')
ref_known_sites_tbi = Channel.fromPath(REF_PATH + '/*.vcf.gz.tbi')
ref_fa = Channel.fromPath(REF_PATH + '/*.fa')
ref_amb = Channel.fromPath(REF_PATH + '/*.amb')
ref_ann = Channel.fromPath(REF_PATH + '/*.ann')
ref_bwt = Channel.fromPath(REF_PATH + '/*.bwt')
ref_fai = Channel.fromPath(REF_PATH + '/*.fai')
ref_pac = Channel.fromPath(REF_PATH + '/*.pac')
ref_sa = Channel.fromPath(REF_PATH + '/*.sa')
ref_dict = Channel.fromPath(REF_PATH + '/*.dict')

BAM_PATH = params.read_dir + "/bams/1500MB"
bam_file = Channel.fromPath(BAM_PATH + '/chr1to4.bam')

workflow {
    bam_file.view {
        "Input files: ${it}, num_files=${it.size()}"
    }.subscribe {
        Date loadEnd = new Date()

        TimeDuration td = TimeCategory.minus(loadEnd, loadStart)

        def logFile = new File("LoadDuration.txt")
        logFile.delete()
        logFile.append(td)
        println ("Loading done! Took " + td)
    }
    APPLYBQSR_DEF1(
        bam_file, bai_file, bqsr_recal_file
    )
}