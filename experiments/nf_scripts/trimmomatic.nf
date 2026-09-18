import groovy.time.TimeCategory 
import groovy.time.TimeDuration


TOOL_PATH = params.tool_dir + "trimmomatic.nf"

include { TRIMMOMATIC_NO_LIMIT as TRIMMOMATIC1 } from TOOL_PATH


Date loadStart = new Date()
println ("Data loading started ...")

/* REFERENCE FILES */
REF_PATH = params.home_dir + "/reference-files"
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

READ_PATH = params.home_dir + "/read-files/star/"
meta_id = Channel.of(READ_PATH.tokenize('/')[-1])
fastq_pair = Channel.fromFilePairs(READ_PATH + '/SRR*_{1,2}.{1,2}.fastq', flat: true)
//                     .splitFastq(by: 800000000, limit:800000000, pe:true, file: true)

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
    TRIMMOMATIC1(
        fastq_pair
    )
}